#!/bin/bash
#
# Deploy AVD PIX4D Monitoring Stack
# Deploys monitoring infrastructure in phases to Azure Sponsorship subscription
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUBSCRIPTION_NAME="Sponsorship - Alejandro"
LOCATION="westeurope"
ENV="lab"
RG_PREFIX="rg-avd-pix4d"

# Resource names
RG_MONITORING="${RG_PREFIX}-monitoring-${ENV}"
RG_COST="${RG_PREFIX}-cost-${ENV}"
RG_INFRA="${RG_PREFIX}-${ENV}"

# Email for notifications
ACTION_GROUP_EMAIL="alejandro@azurebrains.com"  # CHANGE THIS

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AVD PIX4D Monitoring Stack Deployment                      ║${NC}"
echo -e "${BLUE}║   Azure Sponsorship - Phase-by-Phase Deployment              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print step
print_step() {
    echo -e "\n${BLUE}▶ Step $1: $2${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verify Azure CLI is logged in
print_step "0" "Verifying Azure CLI connection"
if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure CLI"
    echo "Run: az login"
    exit 1
fi

CURRENT_SUB=$(az account show --query name -o tsv)
print_success "Connected to subscription: $CURRENT_SUB"

# Verify correct subscription
if [[ "$CURRENT_SUB" != *"Sponsorship"* ]]; then
    print_warning "Not on Sponsorship subscription. Current: $CURRENT_SUB"
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_success "Subscription ID: $SUBSCRIPTION_ID"

# Phase 1: Create Resource Groups
print_step "1" "Creating Resource Groups"

if az group show --name "$RG_MONITORING" &> /dev/null; then
    print_warning "Resource group $RG_MONITORING already exists"
else
    az group create --name "$RG_MONITORING" --location "$LOCATION" \
        --tags environment=lab project=fotogrametria-azure-ia managedBy=bicep
    print_success "Created $RG_MONITORING"
fi

if az group show --name "$RG_COST" &> /dev/null; then
    print_warning "Resource group $RG_COST already exists"
else
    az group create --name "$RG_COST" --location "$LOCATION" \
        --tags environment=lab project=fotogrametria-azure-ia managedBy=bicep
    print_success "Created $RG_COST"
fi

if az group show --name "$RG_INFRA" &> /dev/null; then
    print_warning "Resource group $RG_INFRA already exists (will be created by main infra deployment)"
else
    print_warning "Infrastructure RG $RG_INFRA will be created by main AVD deployment"
fi

# Phase 2: Deploy Log Analytics Workspace
print_step "2" "Deploying Log Analytics Workspace"

LAW_NAME="law-avd-pix4d-${ENV}"
LAW_DEPLOYMENT="deploy-law-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RG_MONITORING" \
    --name "$LAW_DEPLOYMENT" \
    --template-file "monitoring/bicep/modules/law.bicep" \
    --parameters \
        lawName="$LAW_NAME" \
        location="$LOCATION" \
        retentionInDays=30 \
        enableAVDInsights=true \
        tags='{"environment":"lab","project":"fotogrametria-azure-ia"}' \
    --output table

LAW_ID=$(az deployment group show --resource-group "$RG_MONITORING" --name "$LAW_DEPLOYMENT" --query properties.outputs.lawId.value -o tsv)
print_success "Log Analytics Workspace deployed: $LAW_ID"

# Phase 3: Deploy Action Group
print_step "3" "Deploying Action Group for Alerts"

ACTION_GROUP_NAME="ag-avd-pix4d-${ENV}"
AG_DEPLOYMENT="deploy-actiongroup-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RG_MONITORING" \
    --name "$AG_DEPLOYMENT" \
    --template-file "monitoring/bicep/modules/action-group.bicep" \
    --parameters \
        actionGroupName="$ACTION_GROUP_NAME" \
        location="global" \
        emailAddresses="[\"$ACTION_GROUP_EMAIL\"]" \
        tags='{"environment":"lab","project":"fotogrametria-azure-ia"}' \
    --output table

ACTION_GROUP_ID=$(az deployment group show --resource-group "$RG_MONITORING" --name "$AG_DEPLOYMENT" --query properties.outputs.actionGroupId.value -o tsv)
print_success "Action Group deployed: $ACTION_GROUP_ID"

# Phase 4: Deploy Data Collection Endpoint and Rules
print_step "4" "Deploying Data Collection Endpoint and Rules (GPU monitoring)"

DCE_NAME="dce-avd-pix4d-${ENV}"
DCR_NAME="dcr-avd-windowsgpu-${ENV}"
DCE_DEPLOYMENT="deploy-dce-dcr-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RG_MONITORING" \
    --name "$DCE_DEPLOYMENT" \
    --template-file "monitoring/bicep/modules/dce-dcr-simple.bicep" \
    --parameters \
        dceName="$DCE_NAME" \
        dcrName="$DCR_NAME" \
        location="$LOCATION" \
        lawResourceId="$LAW_ID" \
        counterFrequency=60 \
        tags='{"environment":"lab","project":"fotogrametria-azure-ia"}' \
    --output table

DCR_ID=$(az deployment group show --resource-group "$RG_MONITORING" --name "$DCE_DEPLOYMENT" --query properties.outputs.dcrId.value -o tsv)
print_success "Data Collection Rules deployed: $DCR_ID"

# Phase 5: Deploy Storage Account for Cost Exports
print_step "5" "Deploying Storage Account for Cost Management Exports"

STORAGE_NAME="stcostavdpix4d${ENV}"
STORAGE_DEPLOYMENT="deploy-storage-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RG_COST" \
    --name "$STORAGE_DEPLOYMENT" \
    --template-file "monitoring/bicep/modules/storage-cost-export.bicep" \
    --parameters \
        storageAccountName="$STORAGE_NAME" \
        location="$LOCATION" \
        containerName="costexports" \
        tags='{"environment":"lab","project":"fotogrametria-azure-ia"}' \
    --output table

STORAGE_ID=$(az deployment group show --resource-group "$RG_COST" --name "$STORAGE_DEPLOYMENT" --query properties.outputs.storageAccountId.value -o tsv)
print_success "Storage Account deployed: $STORAGE_ID"

# Phase 6: Deploy Metric Alerts
print_step "6" "Deploying Metric-based Alerts"

ALERTS_METRICS_DEPLOYMENT="deploy-alerts-metrics-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RG_MONITORING" \
    --name "$ALERTS_METRICS_DEPLOYMENT" \
    --template-file "monitoring/bicep/modules/alerts-metrics.bicep" \
    --parameters \
        location="$LOCATION" \
        lawResourceId="$LAW_ID" \
        actionGroupId="$ACTION_GROUP_ID" \
        enableAlerts=true \
        tags='{"environment":"lab","project":"fotogrametria-azure-ia"}' \
    --output table

print_success "Metric alerts deployed"

# Phase 7: Deploy KQL Alerts
print_step "7" "Deploying KQL-based Query Alerts"

ALERTS_KQL_DEPLOYMENT="deploy-alerts-kql-$(date +%Y%m%d-%H%M%S)"

az deployment group create \
    --resource-group "$RG_MONITORING" \
    --name "$ALERTS_KQL_DEPLOYMENT" \
    --template-file "monitoring/bicep/modules/alerts-kql.bicep" \
    --parameters \
        location="$LOCATION" \
        lawResourceId="$LAW_ID" \
        actionGroupId="$ACTION_GROUP_ID" \
        enableAlerts=true \
        idleThresholdMinutes=30 \
        scheduleStartTime="16:00" \
        scheduleEndTime="21:00" \
        gpuThresholdPercent=95 \
        tags='{"environment":"lab","project":"fotogrametria-azure-ia"}' \
    --output table

print_success "KQL alerts deployed"

# Phase 8: Summary
print_step "8" "Deployment Summary"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Core Monitoring Stack Deployed Successfully              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Resource Groups:${NC}"
echo "  • $RG_MONITORING"
echo "  • $RG_COST"
echo ""
echo -e "${BLUE}Resources Deployed:${NC}"
echo "  • Log Analytics Workspace: $LAW_NAME"
echo "  • Action Group: $ACTION_GROUP_NAME (Email: $ACTION_GROUP_EMAIL)"
echo "  • Data Collection Rules: $DCR_NAME"
echo "  • Storage Account: $STORAGE_NAME"
echo "  • Metric Alerts: 6 configured"
echo "  • KQL Alerts: 6 configured"
echo ""
echo -e "${YELLOW}⚠ Next Steps:${NC}"
echo "  1. Deploy AVD infrastructure (infra/bicep/main.bicep)"
echo "  2. Associate DCR with session host VMs"
echo "  3. Deploy Automation Account with runbooks"
echo "  4. Configure Budgets (requires subscription-level deployment)"
echo "  5. Test alerting by simulating conditions"
echo ""
echo -e "${BLUE}View in Azure Portal:${NC}"
echo "  https://portal.azure.com/#@azurebrains.com/resource$LAW_ID"
echo ""

