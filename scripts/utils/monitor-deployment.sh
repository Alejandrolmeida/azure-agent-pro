#!/bin/bash
# ============================================================================
# Monitor Active Deployment Progress
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

DEPLOYMENT_NAME="avd-pix4d-m60-20251020-204634"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Monitoring Deployment: ${DEPLOYMENT_NAME}                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}⏱️  Started at: 2025-10-20 18:46:59 UTC${NC}"
echo -e "${CYAN}📍 Location: West Europe${NC}"
echo -e "${CYAN}🎯 Target: 2x Standard_NV6 (NVIDIA Tesla M60)${NC}"
echo ""

while true; do
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  AVD PIX4D M60 Deployment Monitor                           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get deployment status
    STATUS=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query properties.provisioningState -o tsv 2>/dev/null || echo "Unknown")
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${CYAN}🕐 Current Time: ${TIMESTAMP}${NC}"
    echo -e "${CYAN}📊 Deployment Status: ${NC}"
    
    if [ "$STATUS" == "Running" ]; then
        echo -e "   ${YELLOW}⏳ Running...${NC}"
    elif [ "$STATUS" == "Succeeded" ]; then
        echo -e "   ${GREEN}✅ Succeeded!${NC}"
        break
    elif [ "$STATUS" == "Failed" ]; then
        echo -e "   ${RED}❌ Failed${NC}"
        break
    else
        echo -e "   ${YELLOW}Status: ${STATUS}${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Resource Group Deployment Status:${NC}"
    echo ""
    
    # Get resource group deployments
    az deployment sub show --name "$DEPLOYMENT_NAME" \
        --query 'properties.outputResources[].id' -o tsv 2>/dev/null | \
        grep -E 'resourceGroups' | \
        cut -d'/' -f5 | \
        sort -u | \
        while read -r rg; do
            if [ ! -z "$rg" ]; then
                RG_STATE=$(az group show --name "$rg" --query properties.provisioningState -o tsv 2>/dev/null || echo "NotFound")
                if [ "$RG_STATE" == "Succeeded" ]; then
                    echo -e "  ${GREEN}✅${NC} $rg"
                else
                    echo -e "  ${YELLOW}⏳${NC} $rg ($RG_STATE)"
                fi
            fi
        done
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Estimated completion: ~30-45 minutes from start${NC}"
    echo -e "${CYAN}Press Ctrl+C to stop monitoring (deployment continues)${NC}"
    echo ""
    
    if [ "$STATUS" != "Running" ]; then
        break
    fi
    
    sleep 30
done

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

if [ "$STATUS" == "Succeeded" ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ Deployment Completed Successfully!                       ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "  1. Access AVD: https://client.wvd.microsoft.com"
    echo "  2. Login with your Azure AD credentials"
    echo "  3. Install PIX4Dmatic"
    echo "  4. Test GPU performance"
    echo ""
    
    echo -e "${YELLOW}📊 View Resources:${NC}"
    echo "  az group list --query \"[?contains(name, 'pix4d')].name\" -o table"
    
elif [ "$STATUS" == "Failed" ]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ Deployment Failed                                        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}🔍 View Error Details:${NC}"
    echo "  az deployment sub show --name $DEPLOYMENT_NAME --query properties.error"
fi

echo ""
