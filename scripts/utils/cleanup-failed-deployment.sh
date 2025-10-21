#!/bin/bash
# ============================================================================
# Cleanup Failed M60 Deployment in West Central US
# ============================================================================
# Purpose: Remove orphaned resources from failed deployment attempts
# Impact: Saves ~€12-17/month in storage and networking costs
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cleanup Failed Deployment Resources                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Resource Groups to delete
RGS_TO_DELETE=(
    "rg-pix4d-avd-m60-networking-lab-westcentralus"
    "rg-pix4d-avd-m60-lab-westcentralus"
    "rg-pix4d-avd-m60-monitoring-lab-westcentralus"
)

echo -e "${YELLOW}⚠️  This will DELETE the following Resource Groups and ALL their resources:${NC}"
echo ""
for rg in "${RGS_TO_DELETE[@]}"; do
    echo -e "${RED}  ❌ ${rg}${NC}"
done
echo ""

echo -e "${YELLOW}Resources to be deleted:${NC}"
echo "  - 3 Network Interfaces (orphaned)"
echo "  - 1 Storage Account (Premium_LRS FileStorage)"
echo "  - 1 Virtual Network (10.60.0.0/16)"
echo "  - 3 Network Security Groups"
echo "  - 1 AVD Host Pool (empty)"
echo "  - 1 AVD Workspace"
echo "  - 1 Log Analytics Workspace"
echo "  - 1 Automation Account"
echo ""

echo -e "${GREEN}💰 Estimated monthly savings: €12-17${NC}"
echo ""

# Confirmation
read -p "$(echo -e ${YELLOW}Type 'DELETE' to confirm: ${NC})" CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo -e "${RED}❌ Cleanup cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🗑️  Starting cleanup...${NC}"
echo ""

# Delete each resource group
for rg in "${RGS_TO_DELETE[@]}"; do
    echo -e "${YELLOW}Deleting ${rg}...${NC}"
    
    # Check if RG exists
    if az group show --name "$rg" &>/dev/null; then
        # Delete with no-wait for faster execution
        az group delete --name "$rg" --yes --no-wait
        echo -e "${GREEN}✅ Deletion initiated for ${rg}${NC}"
    else
        echo -e "${YELLOW}⚠️  ${rg} not found (already deleted?)${NC}"
    fi
    echo ""
done

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cleanup Summary                                            ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Cleanup initiated for all Resource Groups${NC}"
echo -e "${CYAN}ℹ️  Deletion is running in background (--no-wait)${NC}"
echo -e "${CYAN}ℹ️  Full deletion may take 5-10 minutes${NC}"
echo ""
echo -e "${YELLOW}To check deletion progress:${NC}"
echo "  az group list --query \"[?starts_with(name, 'rg-pix4d-avd-m60')].{Name:name, State:properties.provisioningState}\" -o table"
echo ""
echo -e "${GREEN}💰 Once complete, you'll save ~€12-17/month${NC}"
echo ""
