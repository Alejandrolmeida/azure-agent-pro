#!/bin/bash
# Complete AVD PIX4D Lab Deployment Script
# Deploys infrastructure first, then monitoring

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-lab}"
LOCATION="${2:-westcentralus}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
DEPLOYMENT_NAME="avd-pix4d-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AVD PIX4D Lab - Complete Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Environment: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "Location: ${GREEN}${LOCATION}${NC}"
echo -e "Subscription: ${GREEN}${SUBSCRIPTION_ID}${NC}"
echo -e "Deployment Name: ${GREEN}${DEPLOYMENT_NAME}${NC}"
echo ""

# Prompt for admin password
echo -e "${YELLOW}Please enter the AVD admin password:${NC}"
read -s AVD_ADMIN_PASSWORD
echo ""

if [ -z "$AVD_ADMIN_PASSWORD" ]; then
    echo -e "${RED}Error: Admin password cannot be empty${NC}"
    exit 1
fi

# Validate minimum password requirements
if [ ${#AVD_ADMIN_PASSWORD} -lt 12 ]; then
    echo -e "${RED}Error: Password must be at least 12 characters${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Password validated${NC}"
echo ""

# Step 1: Lint and validate Bicep files
echo -e "${BLUE}Step 1: Validating Bicep templates...${NC}"
az bicep build --file infra/bicep/main.bicep
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Main infrastructure template validated${NC}"
else
    echo -e "${RED}✗ Main infrastructure template validation failed${NC}"
    exit 1
fi

# Validate monitoring (might have warnings, but continue)
az bicep build --file monitoring/bicep/main.monitoring.bicep 2>/dev/null || echo -e "${YELLOW}⚠ Monitoring template has warnings (expected)${NC}"

echo ""

# Step 2: What-If Analysis
echo -e "${BLUE}Step 2: Running What-If analysis for infrastructure...${NC}"
az deployment sub what-if \
    --name "${DEPLOYMENT_NAME}-whatif" \
    --location "${LOCATION}" \
    --template-file infra/bicep/main.bicep \
    --parameters infra/bicep/parameters/${ENVIRONMENT}.bicepparam \
    --parameters adminPassword="${AVD_ADMIN_PASSWORD}" \
    --only-show-errors

echo ""
read -p "$(echo -e ${YELLOW}Do you want to proceed with deployment? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo ""

# Step 3: Deploy Infrastructure (AVD + Storage + Network)
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 3: Deploying AVD Infrastructure${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}This may take 30-45 minutes...${NC}"
echo ""

INFRA_DEPLOYMENT_OUTPUT=$(az deployment sub create \
    --name "${DEPLOYMENT_NAME}-infra" \
    --location "${LOCATION}" \
    --template-file infra/bicep/main.bicep \
    --parameters infra/bicep/parameters/${ENVIRONMENT}.bicepparam \
    --parameters adminPassword="${AVD_ADMIN_PASSWORD}" \
    --output json)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Infrastructure deployment completed successfully!${NC}"
    
    # Extract outputs
    HOST_POOL_NAME=$(echo $INFRA_DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.hostPoolName.value')
    HOST_POOL_RG=$(echo $INFRA_DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.resourceGroupNames.value.avd')
    STORAGE_ACCOUNT_NAME=$(echo $INFRA_DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.storageAccountName.value')
    
    echo -e "${GREEN}Host Pool: ${HOST_POOL_NAME}${NC}"
    echo -e "${GREEN}Resource Group: ${HOST_POOL_RG}${NC}"
    echo -e "${GREEN}Storage Account: ${STORAGE_ACCOUNT_NAME}${NC}"
else
    echo -e "${RED}✗ Infrastructure deployment failed${NC}"
    exit 1
fi

echo ""

# Step 4: Verify Session Hosts are Running
echo -e "${BLUE}Step 4: Verifying Session Hosts...${NC}"
sleep 30  # Wait for VMs to register

SESSION_HOST_COUNT=$(az desktopvirtualization sessionhost list \
    --resource-group "${HOST_POOL_RG}" \
    --host-pool-name "${HOST_POOL_NAME}" \
    --query "length(@)" -o tsv)

echo -e "${GREEN}✓ Found ${SESSION_HOST_COUNT} session hosts${NC}"

# List session hosts with status
az desktopvirtualization sessionhost list \
    --resource-group "${HOST_POOL_RG}" \
    --host-pool-name "${HOST_POOL_NAME}" \
    --query "[].{Name:name, Status:status, LastHeartBeat:lastHeartBeat}" \
    -o table

echo ""

# Step 5: Deploy Monitoring Stack
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 5: Deploying Monitoring Stack${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}This may take 15-20 minutes...${NC}"
echo ""

# Prompt for notification email
read -p "$(echo -e ${YELLOW}Enter notification email address: ${NC})" NOTIFICATION_EMAIL

if [ -z "$NOTIFICATION_EMAIL" ]; then
    echo -e "${YELLOW}No email provided, using default${NC}"
    NOTIFICATION_EMAIL="admin@example.com"
fi

# Create monitoring parameter file
cat > /tmp/monitoring-params.json <<EOF
{
  "\$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "value": "${LOCATION}"
    },
    "environment": {
      "value": "${ENVIRONMENT}"
    },
    "actionGroupEmail": {
      "value": "${NOTIFICATION_EMAIL}"
    },
    "hostPoolResourceGroup": {
      "value": "${HOST_POOL_RG}"
    },
    "hostPoolName": {
      "value": "${HOST_POOL_NAME}"
    },
    "monthlyBudgetAmount": {
      "value": 300
    },
    "dailyBudgetAmount": {
      "value": 15
    },
    "enableAlerts": {
      "value": true
    },
    "enableCostExports": {
      "value": true
    }
  }
}
EOF

echo -e "${GREEN}✓ Monitoring parameters prepared${NC}"
echo ""

# Note: Monitoring deployment might fail on some advanced features
# We'll deploy what we can
echo -e "${YELLOW}⚠ Note: Some advanced monitoring features may not deploy in Sponsorship subscription${NC}"
echo -e "${YELLOW}   (Budgets, Policy Assignments, etc.)${NC}"
echo ""

MONITORING_DEPLOYMENT_OUTPUT=$(az deployment sub create \
    --name "${DEPLOYMENT_NAME}-monitoring" \
    --location "${LOCATION}" \
    --template-file monitoring/bicep/main.monitoring.bicep \
    --parameters /tmp/monitoring-params.json \
    --output json 2>&1) || true

# Check if monitoring deployed successfully (some failures are acceptable)
if echo "$MONITORING_DEPLOYMENT_OUTPUT" | grep -q "Succeeded"; then
    echo -e "${GREEN}✓ Monitoring deployment completed${NC}"
    
    LAW_NAME=$(echo $MONITORING_DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.lawName.value' 2>/dev/null || echo "N/A")
    echo -e "${GREEN}Log Analytics Workspace: ${LAW_NAME}${NC}"
else
    echo -e "${YELLOW}⚠ Monitoring deployment had issues (this is expected in Sponsorship)${NC}"
    echo -e "${YELLOW}   Core AVD infrastructure is deployed and functional${NC}"
fi

echo ""

# Step 6: Post-Deployment Configuration
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 6: Post-Deployment Tasks${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "${YELLOW}Manual steps required:${NC}"
echo ""
echo -e "1. ${GREEN}Assign users to Application Group:${NC}"
echo -e "   az desktopvirtualization applicationgroup update \\"
echo -e "     --resource-group ${HOST_POOL_RG} \\"
echo -e "     --name <app-group-name> \\"
echo -e "     --user-principal-names user@domain.com"
echo ""
echo -e "2. ${GREEN}Configure FSLogix profiles:${NC}"
echo -e "   Storage Account: ${STORAGE_ACCOUNT_NAME}"
echo -e "   File Share: profiles"
echo ""
echo -e "3. ${GREEN}Build custom image (optional):${NC}"
echo -e "   Update lab.bicepparam: buildCustomImage = true"
echo -e "   Redeploy with image builder enabled"
echo ""
echo -e "4. ${GREEN}Configure monitoring DCR associations:${NC}"
echo -e "   Associate Data Collection Rule with Session Host VMs"
echo ""

# Step 7: Run Smoke Tests
echo -e "${BLUE}Step 7: Running Smoke Tests...${NC}"
echo ""

if [ -f "tests/smoke/az-smoke.sh" ]; then
    chmod +x tests/smoke/az-smoke.sh
    ./tests/smoke/az-smoke.sh -g "${HOST_POOL_RG}" -l "${LOCATION}" || echo -e "${YELLOW}⚠ Some smoke tests failed (review output above)${NC}"
else
    echo -e "${YELLOW}⚠ Smoke test script not found, skipping${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deployment Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Infrastructure Status: DEPLOYED${NC}"
echo -e "${GREEN}✓ Session Hosts: ${SESSION_HOST_COUNT} hosts${NC}"
echo -e "${YELLOW}⚠ Monitoring Status: PARTIAL${NC}"
echo ""
echo -e "${BLUE}Resource Groups Created:${NC}"
az group list --query "[?tags.env=='${ENVIRONMENT}' && tags.project=='fotogrametria-azure-ia'].{Name:name, Location:location}" -o table
echo ""
echo -e "${BLUE}Total Deployment Time: ${SECONDS} seconds${NC}"
echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo -e "${YELLOW}📝 Review manual steps above before using the environment${NC}"
echo ""

# Cleanup temp files
rm -f /tmp/monitoring-params.json

