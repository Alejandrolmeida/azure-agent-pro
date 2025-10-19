#!/bin/bash
#
# Smoke tests for AVD PIX4D infrastructure deployment (Bash version)
#
# Usage: ./az-smoke.sh [environment] [location]
#

set -e

ENVIRONMENT="${1:-lab}"
LOCATION="${2:-westeurope}"

echo "========================================"
echo "AVD PIX4D Smoke Tests (Bash)"
echo "Environment: $ENVIRONMENT"
echo "Location: $LOCATION"
echo "========================================
"

TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

test_resource() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name..."
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e " ${GREEN}✅ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e " ${RED}❌ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Resource Groups Exist
test_resource "Resource Groups Exist" \
    "az group exists --name rg-pix4d-avd-$ENVIRONMENT-$LOCATION && \
     az group exists --name rg-pix4d-avd-networking-$ENVIRONMENT-$LOCATION && \
     az group exists --name rg-pix4d-avd-monitoring-$ENVIRONMENT-$LOCATION"

# Test 2: Virtual Network Exists
test_resource "Virtual Network Exists" \
    "az network vnet show --resource-group rg-pix4d-avd-networking-$ENVIRONMENT-$LOCATION \
     --name vnet-pix4d-avd-$ENVIRONMENT"

# Test 3: Required Subnets Exist
echo -n "Testing: Required Subnets Exist..."
RG_NETWORKING="rg-pix4d-avd-networking-$ENVIRONMENT-$LOCATION"
VNET_NAME="vnet-pix4d-avd-$ENVIRONMENT"

SUBNETS=$(az network vnet subnet list \
    --resource-group "$RG_NETWORKING" \
    --vnet-name "$VNET_NAME" \
    --query "[].name" -o tsv 2>/dev/null)

if echo "$SUBNETS" | grep -q "snet-sessionhosts" && \
   echo "$SUBNETS" | grep -q "snet-privateendpoints" && \
   echo "$SUBNETS" | grep -q "snet-aib"; then
    echo -e " ${GREEN}✅ PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e " ${RED}❌ FAILED${NC}"
    ((TESTS_FAILED++))
fi

# Test 4: Host Pool Exists
test_resource "AVD Host Pool Exists" \
    "az desktopvirtualization hostpool show \
     --resource-group rg-pix4d-avd-$ENVIRONMENT-$LOCATION \
     --name hp-pix4d-avd-$ENVIRONMENT"

# Test 5: Start VM on Connect Enabled
echo -n "Testing: Start VM on Connect Enabled..."
RG_MAIN="rg-pix4d-avd-$ENVIRONMENT-$LOCATION"
HP_NAME="hp-pix4d-avd-$ENVIRONMENT"

START_VM_ENABLED=$(az desktopvirtualization hostpool show \
    --resource-group "$RG_MAIN" \
    --name "$HP_NAME" \
    --query "startVMOnConnect" -o tsv 2>/dev/null)

if [ "$START_VM_ENABLED" = "true" ]; then
    echo -e " ${GREEN}✅ PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e " ${RED}❌ FAILED${NC}"
    ((TESTS_FAILED++))
fi

# Test 6: Workspace Exists
test_resource "AVD Workspace Exists" \
    "az desktopvirtualization workspace show \
     --resource-group rg-pix4d-avd-$ENVIRONMENT-$LOCATION \
     --name ws-pix4d-avd-$ENVIRONMENT"

# Test 7: Application Group Exists
test_resource "Application Group Exists" \
    "az desktopvirtualization applicationgroup show \
     --resource-group rg-pix4d-avd-$ENVIRONMENT-$LOCATION \
     --name ag-pix4d-avd-$ENVIRONMENT"

# Test 8: Storage Account Exists
STORAGE_NAME=$(echo "stpix4davd$ENVIRONMENT" | tr -d '-')
test_resource "Storage Account Exists" \
    "az storage account show \
     --resource-group rg-pix4d-avd-$ENVIRONMENT-$LOCATION \
     --name $STORAGE_NAME"

# Test 9: FSLogix File Share Exists
echo -n "Testing: FSLogix File Share Exists..."
STORAGE_NAME=$(echo "stpix4davd$ENVIRONMENT" | tr -d '-')

SHARE_EXISTS=$(az storage share exists \
    --account-name "$STORAGE_NAME" \
    --name "profiles" \
    --query "exists" -o tsv 2>/dev/null)

if [ "$SHARE_EXISTS" = "true" ]; then
    echo -e " ${GREEN}✅ PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e " ${RED}❌ FAILED${NC}"
    ((TESTS_FAILED++))
fi

# Test 10: Log Analytics Workspace Exists
test_resource "Log Analytics Workspace Exists" \
    "az monitor log-analytics workspace show \
     --resource-group rg-pix4d-avd-monitoring-$ENVIRONMENT-$LOCATION \
     --workspace-name law-pix4d-avd-$ENVIRONMENT"

# Test 11: Automation Account Exists
test_resource "Automation Account Exists" \
    "az automation account show \
     --resource-group rg-pix4d-avd-$ENVIRONMENT-$LOCATION \
     --name aa-pix4d-avd-$ENVIRONMENT"

# Test 12: Session Hosts Exist
echo -n "Testing: Session Hosts Exist..."
SESSION_HOSTS=$(az desktopvirtualization sessionhost list \
    --resource-group "$RG_MAIN" \
    --host-pool-name "$HP_NAME" \
    --query "length(@)" -o tsv 2>/dev/null)

if [ "$SESSION_HOSTS" -gt 0 ]; then
    echo -e " ${GREEN}✅ PASSED (${SESSION_HOSTS} hosts)${NC}"
    ((TESTS_PASSED++))
else
    echo -e " ${RED}❌ FAILED${NC}"
    ((TESTS_FAILED++))
fi

# Summary
echo ""
echo "========================================"
echo -e "${CYAN}Test Results Summary${NC}"
echo "========================================"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo -e "${CYAN}Total Tests: $((TESTS_PASSED + TESTS_FAILED))${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review the errors above.${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ All tests passed successfully!${NC}"
    exit 0
fi
