#!/bin/bash

# Script automatizado: Solicitud de Cuota Azure (con retry automático)
# Proyecto: POC AVD Pix4Dmatic
# Fecha: 22 de Octubre de 2025

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
SUBSCRIPTION_ID="36a06bba-6ca7-46f8-a1a8-4abbbebeee86"
REGION="spaincentral"
WAIT_TIME=600  # 10 minutos en segundos

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Solicitud Automática de Cuota - Spain Central (con espera anti-throttle) ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar autenticación
echo -e "${YELLOW}[1/5] Verificando autenticación Azure...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ No estás autenticado en Azure${NC}"
    exit 1
fi

CURRENT_SUB=$(az account show --query id -o tsv)
if [ "$CURRENT_SUB" != "$SUBSCRIPTION_ID" ]; then
    az account set --subscription "$SUBSCRIPTION_ID"
fi
echo -e "${GREEN}✅ Autenticado en suscripción POC AVD${NC}"
echo ""

# Esperar para evitar throttling
echo -e "${YELLOW}[2/5] Esperando para evitar API throttling...${NC}"
echo -e "${BLUE}   Tiempo de espera: ${WAIT_TIME} segundos ($(($WAIT_TIME / 60)) minutos)${NC}"
echo -e "${BLUE}   Inicio: $(date '+%Y-%m-%d %H:%M:%S')${NC}"

for i in $(seq $WAIT_TIME -60 1); do
    if [ $((i % 60)) -eq 0 ]; then
        MINS=$((i / 60))
        echo -e "${YELLOW}   ⏳ Esperando... ${MINS} minuto(s) restante(s)${NC}"
    fi
    sleep 60
done

echo -e "${GREEN}✅ Espera completada${NC}"
echo -e "${BLUE}   Fin: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# Crear JSON para NVadsA10v5
echo -e "${YELLOW}[3/5] Preparando solicitud para NVadsA10v5...${NC}"
cat > /tmp/quota_nv_auto.json << 'EOF'
{
  "properties": {
    "limit": {
      "limitObjectType": "LimitValue",
      "value": 42
    },
    "name": {
      "value": "standardNVADSA10v5Family"
    },
    "resourceType": "dedicated"
  }
}
EOF
echo -e "${GREEN}✅ Payload NVadsA10v5 preparado (42 vCPUs)${NC}"
echo ""

# Solicitar NVadsA10v5
echo -e "${YELLOW}[4/5] Solicitando cuota NVadsA10v5 (42 vCPUs)...${NC}"
NV_RESPONSE=$(az rest --method put \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Compute/locations/${REGION}/providers/Microsoft.Quota/quotas/standardNVADSA10v5Family?api-version=2023-02-01" \
  --body @/tmp/quota_nv_auto.json 2>&1)

if echo "$NV_RESPONSE" | grep -q "error"; then
    echo -e "${RED}❌ Error en solicitud NVadsA10v5:${NC}"
    echo "$NV_RESPONSE"
    NV_SUCCESS=false
else
    echo -e "${GREEN}✅ Solicitud NVadsA10v5 enviada correctamente${NC}"
    NV_SUCCESS=true
fi
echo ""

# Crear JSON para NCadsH100v5
echo -e "${YELLOW}[5/5] Solicitando cuota NCadsH100v5 (40 vCPUs)...${NC}"
cat > /tmp/quota_nc_auto.json << 'EOF'
{
  "properties": {
    "limit": {
      "limitObjectType": "LimitValue",
      "value": 40
    },
    "name": {
      "value": "standardNCadsH100v5Family"
    },
    "resourceType": "dedicated"
  }
}
EOF

NC_RESPONSE=$(az rest --method put \
  --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Compute/locations/${REGION}/providers/Microsoft.Quota/quotas/standardNCadsH100v5Family?api-version=2023-02-01" \
  --body @/tmp/quota_nc_auto.json 2>&1)

if echo "$NC_RESPONSE" | grep -q "error"; then
    echo -e "${RED}❌ Error en solicitud NCadsH100v5:${NC}"
    echo "$NC_RESPONSE"
    NC_SUCCESS=false
else
    echo -e "${GREEN}✅ Solicitud NCadsH100v5 enviada correctamente${NC}"
    NC_SUCCESS=true
fi
echo ""

# Resumen final
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         RESUMEN DE SOLICITUDES                               ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$NV_SUCCESS" = true ] && [ "$NC_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ ÉXITO: Ambas solicitudes enviadas correctamente${NC}"
    echo ""
    echo -e "${BLUE}Solicitudes enviadas:${NC}"
    echo -e "  • Standard NVadsA10v5 Family vCPUs: ${GREEN}0 → 42 vCPUs${NC}"
    echo -e "  • Standard NCadsH100v5 Family vCPUs: ${GREEN}0 → 40 vCPUs${NC}"
    echo ""
    echo -e "${YELLOW}⏱️  Tiempo estimado de aprobación:${NC}"
    echo -e "   Suscripción CSP: ${GREEN}1-2 horas hábiles${NC}"
    echo ""
    echo -e "${BLUE}📧 Notificaciones:${NC}"
    echo -e "   Recibirás confirmación en:"
    echo -e "   • Azure Portal (campana de notificaciones)"
    echo -e "   • Email: a.almeida@prodware.es"
    echo ""
    echo -e "${GREEN}🔍 Verificar estado:${NC}"
    echo -e "   az vm list-usage --location spaincentral --output table | grep -E 'NVADS|NCads'"
    EXIT_CODE=0
elif [ "$NV_SUCCESS" = true ]; then
    echo -e "${YELLOW}⚠️  PARCIAL: Solo NVadsA10v5 enviada correctamente${NC}"
    echo -e "${RED}❌ NCadsH100v5 falló - revisar logs arriba${NC}"
    EXIT_CODE=1
elif [ "$NC_SUCCESS" = true ]; then
    echo -e "${YELLOW}⚠️  PARCIAL: Solo NCadsH100v5 enviada correctamente${NC}"
    echo -e "${RED}❌ NVadsA10v5 falló - revisar logs arriba${NC}"
    EXIT_CODE=1
else
    echo -e "${RED}❌ ERROR: Ambas solicitudes fallaron${NC}"
    echo ""
    echo -e "${YELLOW}Opciones alternativas:${NC}"
    echo -e "  1. Portal Azure (RECOMENDADO):"
    echo -e "     https://portal.azure.com/#view/Microsoft_Azure_Capacity/QuotaMenuBlade/~/myQuotas"
    echo -e "  2. Crear ticket de soporte:"
    echo -e "     https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade"
    EXIT_CODE=2
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"

# Limpiar archivos temporales
rm -f /tmp/quota_nv_auto.json /tmp/quota_nc_auto.json

exit $EXIT_CODE
