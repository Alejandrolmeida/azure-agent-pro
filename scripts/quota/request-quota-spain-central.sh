#!/bin/bash

# Script de Ayuda: Solicitud de Cuota Azure en Spain Central
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
SUBSCRIPTION_NAME="POC AVD"
REGION="spaincentral"
REGION_DISPLAY="Spain Central"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Solicitud de Ampliación de Cuota - Spain Central                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar autenticación
echo -e "${YELLOW}[1/4] Verificando autenticación Azure...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ No estás autenticado en Azure${NC}"
    echo -e "${YELLOW}   Ejecuta: az login${NC}"
    exit 1
fi

CURRENT_SUB=$(az account show --query id -o tsv)
if [ "$CURRENT_SUB" != "$SUBSCRIPTION_ID" ]; then
    echo -e "${YELLOW}   Cambiando a suscripción $SUBSCRIPTION_NAME...${NC}"
    az account set --subscription "$SUBSCRIPTION_ID"
fi
echo -e "${GREEN}✅ Autenticado correctamente${NC}"
echo ""

# Verificar disponibilidad de SKUs
echo -e "${YELLOW}[2/4] Verificando disponibilidad de SKUs en $REGION_DISPLAY...${NC}"

echo -e "${BLUE}   Verificando NVadsA10v5...${NC}"
NV_SKUS=$(az vm list-skus --location "$REGION" --size Standard_NV --all --output tsv 2>/dev/null | grep -c "NV.*A10" || true)
if [ "$NV_SKUS" -gt 0 ]; then
    echo -e "${GREEN}   ✅ NVadsA10v5 disponible ($NV_SKUS SKUs encontrados)${NC}"
else
    echo -e "${RED}   ❌ NVadsA10v5 no disponible en $REGION_DISPLAY${NC}"
fi

echo -e "${BLUE}   Verificando NCadsH100v5...${NC}"
NC_SKUS=$(az vm list-skus --location "$REGION" --size Standard_NC --all --output tsv 2>/dev/null | grep -c "NC.*H100" || true)
if [ "$NC_SKUS" -gt 0 ]; then
    echo -e "${GREEN}   ✅ NCadsH100v5 disponible ($NC_SKUS SKUs encontrados)${NC}"
else
    echo -e "${RED}   ❌ NCadsH100v5 no disponible en $REGION_DISPLAY${NC}"
fi
echo ""

# Verificar cuota actual
echo -e "${YELLOW}[3/4] Verificando cuota actual en $REGION_DISPLAY...${NC}"

echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│ Familia de VM                  │ Actual │ Límite │ Disponible │${NC}"
echo -e "${BLUE}├────────────────────────────────┼────────┼────────┼────────────┤${NC}"

# NVadsA10v5
NV_QUOTA=$(az vm list-usage --location "$REGION" --query "[?contains(name.value, 'NVADSA10v5')]" -o tsv 2>/dev/null || echo "0	0")
NV_CURRENT=$(echo "$NV_QUOTA" | awk '{print $1}')
NV_LIMIT=$(echo "$NV_QUOTA" | awk '{print $2}')
NV_AVAILABLE=$((NV_LIMIT - NV_CURRENT))

printf "${BLUE}│${NC} %-30s ${BLUE}│${NC} %6s ${BLUE}│${NC} %6s ${BLUE}│${NC} %10s ${BLUE}│${NC}\n" \
    "NVADSA10v5 Family vCPUs" "$NV_CURRENT" "$NV_LIMIT" "$NV_AVAILABLE"

# NCadsH100v5
NC_QUOTA=$(az vm list-usage --location "$REGION" --query "[?contains(name.value, 'NCadsH100v5')]" -o tsv 2>/dev/null || echo "0	0")
NC_CURRENT=$(echo "$NC_QUOTA" | awk '{print $1}')
NC_LIMIT=$(echo "$NC_QUOTA" | awk '{print $2}')
NC_AVAILABLE=$((NC_LIMIT - NC_CURRENT))

printf "${BLUE}│${NC} %-30s ${BLUE}│${NC} %6s ${BLUE}│${NC} %6s ${BLUE}│${NC} %10s ${BLUE}│${NC}\n" \
    "NCadsH100v5 Family vCPUs" "$NC_CURRENT" "$NC_LIMIT" "$NC_AVAILABLE"

echo -e "${BLUE}└────────────────────────────────┴────────┴────────┴────────────┘${NC}"
echo ""

# Generar URLs de solicitud
echo -e "${YELLOW}[4/4] Generando URLs para solicitud de cuota...${NC}"
echo ""

PORTAL_URL="https://portal.azure.com/#view/Microsoft_Azure_Capacity/QuotaMenuBlade/~/myQuotas"
SUPPORT_URL="https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade/overview"

echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  📋 SOLICITUD DE CUOTA - INSTRUCCIONES${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}MÉTODO 1: Portal Azure - Usage + Quotas (RECOMENDADO)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "1. Accede a: ${GREEN}$PORTAL_URL${NC}"
echo -e "2. Selecciona: ${YELLOW}Microsoft.Compute${NC}"
echo -e "3. Filtra por región: ${YELLOW}Spain Central${NC}"
echo -e "4. Busca y solicita aumento para:"
echo -e "   ${GREEN}✓${NC} Standard NVADSA10v5 Family vCPUs  → ${GREEN}42 vCPUs${NC}"
echo -e "   ${GREEN}✓${NC} Standard NCadsH100v5 Family vCPUs → ${GREEN}40 vCPUs${NC}"
echo ""

echo -e "${BLUE}MÉTODO 2: Crear Ticket de Soporte${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "1. Accede a: ${GREEN}$SUPPORT_URL${NC}"
echo -e "2. Click: ${YELLOW}+ Create a support request${NC}"
echo -e "3. Issue type: ${YELLOW}Service and subscription limits (quotas)${NC}"
echo -e "4. Subscription: ${YELLOW}$SUBSCRIPTION_NAME${NC}"
echo -e "5. Quota type: ${YELLOW}Compute-VM (cores-vCPUs)${NC}"
echo -e "6. Problem type: ${YELLOW}Regional vCPU quota${NC}"
echo -e "7. Location: ${YELLOW}Spain Central${NC}"
echo -e "8. Detalles:"
echo -e "   - Familia: ${GREEN}Standard NVadsA10v5${NC} → Nuevo límite: ${GREEN}42${NC}"
echo -e "   - Familia: ${GREEN}Standard NCadsH100v5${NC} → Nuevo límite: ${GREEN}40${NC}"
echo ""

echo -e "${BLUE}JUSTIFICACIÓN A INCLUIR:${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
cat << 'JUSTIFICATION'
Proyecto: POC Azure Virtual Desktop con Pix4Dmatic
Modelo: Personal Desktop (1 VM dedicada por usuario)
Software: Pix4Dmatic (fotogrametría, requiere GPU CUDA)
Región: Spain Central (proximidad usuarios en España)

Configuración:
- Producción: 1x NV36ads_A10_v5 (36 vCPU) + 1x NV6ads_A10_v5 (6 vCPU) = 42 vCPU
- Demo/POC: 1x NC40ads_H100_v5 (40 vCPU) = 40 vCPU

Beneficios:
- Latencia óptima para usuarios españoles
- Compliance: datos residentes en España/EU
- AVD nativo soportado en la región
- GPUs NVIDIA con soporte CUDA para Pix4Dmatic
JUSTIFICATION
echo ""

echo -e "${GREEN}⏱️  TIEMPO DE APROBACIÓN ESTIMADO:${NC}"
echo -e "   Suscripción CSP: ${GREEN}1-2 horas hábiles${NC} (máx. 24h)"
echo -e "   Suscripción Enterprise: ${GREEN}2-4 horas hábiles${NC} (máx. 48h)"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  📄 Documentación completa disponible en:${NC}"
echo -e "${GREEN}     docs/QUOTA_REQUEST_SPAIN_CENTRAL.md${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Preguntar si desea abrir el navegador
read -p "¿Deseas abrir el portal Azure para solicitar la cuota? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    if command -v xdg-open &> /dev/null; then
        xdg-open "$PORTAL_URL" 2>/dev/null || echo -e "${YELLOW}Abre manualmente: $PORTAL_URL${NC}"
    elif command -v open &> /dev/null; then
        open "$PORTAL_URL" 2>/dev/null || echo -e "${YELLOW}Abre manualmente: $PORTAL_URL${NC}"
    else
        echo -e "${YELLOW}Abre manualmente en tu navegador: $PORTAL_URL${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Script completado exitosamente${NC}"
