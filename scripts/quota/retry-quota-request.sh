#!/bin/bash

# Script de Reintento: Solicitud de Cuota Azure
# Proyecto: POC AVD Pix4Dmatic
# Fecha: 22 de Octubre de 2025
# Uso: ./retry-quota-request.sh

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SUBSCRIPTION_ID="36a06bba-6ca7-46f8-a1a8-4abbbebeee86"
REGION="spaincentral"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Reintento de Solicitud de Cuota - Spain Central                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar autenticación
echo -e "${YELLOW}[1/4] Verificando autenticación...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ No autenticado${NC}"
    exit 1
fi
az account set --subscription "$SUBSCRIPTION_ID" &>/dev/null
echo -e "${GREEN}✅ Autenticado${NC}"
echo ""

# Obtener token
echo -e "${YELLOW}[2/4] Obteniendo token de acceso...${NC}"
TOKEN=$(az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ No se pudo obtener token${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Token obtenido${NC}"
echo ""

# Solicitar NVadsA10v5
echo -e "${YELLOW}[3/4] Solicitando cuota NVadsA10v5 (42 vCPUs)...${NC}"

RESPONSE_NV=$(curl -s -w "\n%{http_code}" -X PUT \
  "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Compute/locations/${REGION}/providers/Microsoft.Quota/quotas/standardNVADSA10v5Family?api-version=2023-02-01" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
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
  }')

HTTP_CODE_NV=$(echo "$RESPONSE_NV" | tail -n1)
BODY_NV=$(echo "$RESPONSE_NV" | sed '$d')

if [ "$HTTP_CODE_NV" -eq 200 ] || [ "$HTTP_CODE_NV" -eq 201 ] || [ "$HTTP_CODE_NV" -eq 202 ]; then
    echo -e "${GREEN}✅ NVadsA10v5: Solicitud enviada (HTTP $HTTP_CODE_NV)${NC}"
    NV_SUCCESS=true
else
    echo -e "${RED}❌ NVadsA10v5: Error (HTTP $HTTP_CODE_NV)${NC}"
    echo -e "${YELLOW}Response: $BODY_NV${NC}"
    NV_SUCCESS=false
fi
echo ""

# Solicitar NCadsH100v5
echo -e "${YELLOW}[4/4] Solicitando cuota NCadsH100v5 (40 vCPUs)...${NC}"

RESPONSE_NC=$(curl -s -w "\n%{http_code}" -X PUT \
  "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Compute/locations/${REGION}/providers/Microsoft.Quota/quotas/standardNCadsH100v5Family?api-version=2023-02-01" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
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
  }')

HTTP_CODE_NC=$(echo "$RESPONSE_NC" | tail -n1)
BODY_NC=$(echo "$RESPONSE_NC" | sed '$d')

if [ "$HTTP_CODE_NC" -eq 200 ] || [ "$HTTP_CODE_NC" -eq 201 ] || [ "$HTTP_CODE_NC" -eq 202 ]; then
    echo -e "${GREEN}✅ NCadsH100v5: Solicitud enviada (HTTP $HTTP_CODE_NC)${NC}"
    NC_SUCCESS=true
else
    echo -e "${RED}❌ NCadsH100v5: Error (HTTP $HTTP_CODE_NC)${NC}"
    echo -e "${YELLOW}Response: $BODY_NC${NC}"
    NC_SUCCESS=false
fi
echo ""

# Resumen
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                              RESUMEN                                         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$NV_SUCCESS" = true ] && [ "$NC_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ ÉXITO: Ambas solicitudes enviadas correctamente${NC}"
    echo ""
    echo -e "${BLUE}Verifica el estado en unos minutos:${NC}"
    echo -e "  az vm list-usage --location spaincentral --query \"[?contains(name.value,'NVADS') || contains(name.value,'NCads')]\" -o table"
    echo ""
    echo -e "${YELLOW}⏱️  Tiempo estimado de aprobación: 30 min - 2 horas${NC}"
    EXIT_CODE=0
elif [ "$NV_SUCCESS" = true ] || [ "$NC_SUCCESS" = true ]; then
    echo -e "${YELLOW}⚠️  PARCIAL: Al menos una solicitud fue enviada${NC}"
    EXIT_CODE=1
else
    echo -e "${RED}❌ ERROR: Ninguna solicitud pudo ser enviada${NC}"
    echo ""
    echo -e "${YELLOW}Opciones alternativas:${NC}"
    echo ""
    echo -e "${BLUE}1. Portal Azure (SIN throttling):${NC}"
    echo -e "   https://portal.azure.com/#view/Microsoft_Azure_Capacity/QuotaMenuBlade/~/myQuotas"
    echo ""
    echo -e "${BLUE}2. Contactar partner CSP (Prodware):${NC}"
    echo -e "   Solicitar aumento de cuota GPU para Spain Central"
    echo ""
    echo -e "${BLUE}3. Reintentar más tarde:${NC}"
    echo -e "   ./scripts/quota/retry-quota-request.sh"
    EXIT_CODE=2
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"

exit $EXIT_CODE
