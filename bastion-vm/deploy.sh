#!/bin/bash
set -euo pipefail

# ========================================
# Deploy Simple Bastion VM
# ========================================
# Reads configuration from config/user-config.sh
# This file is in .gitignore - safe for credentials
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/user-config.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PIX4D Simple Bastion VM Deployment                  ║${NC}"
echo -e "${BLUE}║  GPU: AMD Radeon Instinct MI25                        ║${NC}"
echo -e "${BLUE}║  OS: Windows 11 Enterprise                            ║${NC}"
echo -e "${BLUE}║  Access: Azure Bastion (Native RDP Client)            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Configuration file not found!${NC}"
    echo ""
    echo -e "${YELLOW}Please create your configuration file:${NC}"
    echo -e "   1. Copy the template:"
    echo -e "      ${GREEN}cp $SCRIPT_DIR/config/user-config.sh.template $CONFIG_FILE${NC}"
    echo ""
    echo -e "   2. Edit with your credentials:"
    echo -e "      ${GREEN}nano $CONFIG_FILE${NC}"
    echo ""
    echo -e "   3. Run this script again"
    echo ""
    exit 1
fi

# Load configuration (this file is in .gitignore)
source "$CONFIG_FILE"

# Check Azure CLI login
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged in to Azure CLI${NC}"
    echo "Run: az login"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
DEPLOYMENT_NAME="${PROJECT_NAME}-vm-$(date +%Y%m%d-%H%M%S)"

echo -e "${YELLOW}📋 Configuration:${NC}"
echo -e "   Subscription: ${GREEN}$SUBSCRIPTION_NAME${NC}"
echo -e "   Location:     ${GREEN}$LOCATION${NC}"
echo -e "   VM SKU:       ${GREEN}$VM_SKU${NC}"
echo -e "   Project:      ${GREEN}$PROJECT_NAME${NC}"
echo -e "   Environment:  ${GREEN}$ENVIRONMENT${NC}"
echo -e "   Deployment:   ${GREEN}$DEPLOYMENT_NAME${NC}"
echo ""

echo -e "${YELLOW}🚀 Starting deployment...${NC}"
echo ""

# Deploy
az deployment sub create \
    --location "$LOCATION" \
    --template-file "$SCRIPT_DIR/main.bicep" \
    --parameters location="$LOCATION" \
                 environment="$ENVIRONMENT" \
                 projectName="$PROJECT_NAME" \
                 vmSku="$VM_SKU" \
                 adminUsername="$ADMIN_USERNAME" \
                 adminPassword="$ADMIN_PASSWORD" \
    --name "$DEPLOYMENT_NAME"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ Deployment Successful!                            ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get outputs
    RG_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query properties.outputs.resourceGroupName.value -o tsv)
    VM_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query properties.outputs.vmName.value -o tsv)
    BASTION_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query properties.outputs.bastionName.value -o tsv)
    
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo ""
    echo -e "${BLUE}1. Grant yourself 'Virtual Machine Administrator Login' role:${NC}"
    echo -e "   ${GREEN}./grant-vm-access.sh${NC}"
    echo ""
    echo -e "${BLUE}2. Connect via Bastion Native Client from Windows:${NC}"
    echo -e "   ${GREEN}az network bastion rdp \\${NC}"
    echo -e "   ${GREEN}  --name $BASTION_NAME \\${NC}"
    echo -e "   ${GREEN}  --resource-group $RG_NAME \\${NC}"
    echo -e "   ${GREEN}  --target-resource-id /subscriptions/\$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.Compute/virtualMachines/$VM_NAME${NC}"
    echo ""
    echo -e "${BLUE}3. Login with your Microsoft account:${NC}"
    echo -e "   ${YELLOW}AzureAD\\$USER_EMAIL${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ Deployment Failed                                 ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
