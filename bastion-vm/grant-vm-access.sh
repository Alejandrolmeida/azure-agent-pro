#!/bin/bash
set -euo pipefail

# ========================================
# Grant VM Access Script
# ========================================
# Assigns 'Virtual Machine Administrator Login' role
# Required for Azure AD authentication
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/user-config.sh"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

echo -e "${YELLOW}🔐 Granting VM access permissions...${NC}"
echo ""

# Get current user
USER_ID=$(az ad signed-in-user show --query id -o tsv)
CURRENT_USER=$(az account show --query user.name -o tsv)

echo -e "User: ${GREEN}$CURRENT_USER${NC}"
echo -e "User Object ID: ${GREEN}$USER_ID${NC}"
echo ""

# Get VM resource ID
RG_NAME="${PROJECT_NAME:-pix4d}-${ENVIRONMENT:-lab}-${LOCATION:-northeurope}"
RG_NAME="rg-$RG_NAME"
VM_NAME="${PROJECT_NAME:-pix4d}-vm"

VM_ID=$(az vm show --resource-group "$RG_NAME" --name "$VM_NAME" --query id -o tsv 2>/dev/null)

if [ -z "$VM_ID" ]; then
    echo -e "${RED}❌ VM not found!${NC}"
    echo -e "   Resource Group: $RG_NAME"
    echo -e "   VM Name: $VM_NAME"
    echo ""
    echo -e "${YELLOW}💡 Make sure the VM is deployed first:${NC}"
    echo -e "   ./deploy.sh"
    exit 1
fi

echo -e "VM: ${GREEN}$VM_NAME${NC}"
echo -e "Resource Group: ${GREEN}$RG_NAME${NC}"
echo ""

# Assign role
echo -e "${YELLOW}Assigning 'Virtual Machine Administrator Login' role...${NC}"

az role assignment create \
    --assignee "$USER_ID" \
    --role "Virtual Machine Administrator Login" \
    --scope "$VM_ID"

echo ""
echo -e "${GREEN}✅ Access granted successfully!${NC}"
echo ""
echo -e "${YELLOW}You can now connect to the VM via Bastion with your Azure AD account.${NC}"
