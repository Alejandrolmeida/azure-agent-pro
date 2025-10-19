#!/bin/bash
#
# E2E test for Start VM on Connect and auto-deallocate functionality (Bash version)
#
# Usage: ./check-start-stop.sh [environment] [location] [vm-name]
#

set -e

ENVIRONMENT="${1:-lab}"
LOCATION="${2:-westeurope}"
SESSION_HOST_NAME="${3:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "========================================"
echo "AVD Start/Stop E2E Test (Bash)"
echo "========================================"
echo ""

RG_MAIN="rg-pix4d-avd-$ENVIRONMENT-$LOCATION"
HP_NAME="hp-pix4d-avd-$ENVIRONMENT"

# Get a session host if not provided
if [ -z "$SESSION_HOST_NAME" ]; then
    echo "Getting first available session host..."
    SESSION_HOST_NAME=$(az desktopvirtualization sessionhost list \
        --resource-group "$RG_MAIN" \
        --host-pool-name "$HP_NAME" \
        --query "[0].name" -o tsv 2>/dev/null | cut -d'/' -f2)
    
    if [ -z "$SESSION_HOST_NAME" ]; then
        echo -e "${RED}❌ No session hosts found!${NC}"
        exit 1
    fi
    echo -e "${CYAN}Selected session host: $SESSION_HOST_NAME${NC}"
fi

# Extract VM name
VM_NAME=$(echo "$SESSION_HOST_NAME" | cut -d'.' -f1)
echo -e "${CYAN}VM Name: $VM_NAME${NC}"

# Test 1: Check initial VM state
echo ""
echo "[Test 1] Checking initial VM state..."
INITIAL_STATE=$(az vm show \
    --resource-group "$RG_MAIN" \
    --name "$VM_NAME" \
    --show-details \
    --query "powerState" -o tsv)
echo -e "${CYAN}Initial state: $INITIAL_STATE${NC}"

# Test 2: Verify VM can be deallocated
if [ "$INITIAL_STATE" != "VM deallocated" ]; then
    echo ""
    echo "[Test 2] Deallocating VM..."
    az vm deallocate --resource-group "$RG_MAIN" --name "$VM_NAME" --no-wait
    
    # Wait for deallocation
    TIMEOUT=300
    ELAPSED=0
    
    while [ $ELAPSED -lt $TIMEOUT ]; do
        STATE=$(az vm show \
            --resource-group "$RG_MAIN" \
            --name "$VM_NAME" \
            --show-details \
            --query "powerState" -o tsv)
        
        if [ "$STATE" = "VM deallocated" ]; then
            echo -e "${GREEN}✅ VM successfully deallocated${NC}"
            break
        fi
        
        echo -e "${YELLOW}Waiting for deallocation... ($ELAPSED seconds elapsed)${NC}"
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done
    
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo -e "${RED}❌ Timeout waiting for VM to deallocate${NC}"
        exit 1
    fi
fi

# Test 3: Verify Start VM on Connect setting
echo ""
echo "[Test 3] Verifying Start VM on Connect is enabled..."
START_VM_ENABLED=$(az desktopvirtualization hostpool show \
    --resource-group "$RG_MAIN" \
    --name "$HP_NAME" \
    --query "startVMOnConnect" -o tsv)

if [ "$START_VM_ENABLED" = "true" ]; then
    echo -e "${GREEN}✅ Start VM on Connect is enabled${NC}"
else
    echo -e "${RED}❌ Start VM on Connect is NOT enabled${NC}"
    exit 1
fi

# Test 4: Verify idle shutdown tag
echo ""
echo "[Test 4] Verifying idle shutdown configuration..."
IDLE_TAG=$(az vm show \
    --resource-group "$RG_MAIN" \
    --name "$VM_NAME" \
    --query "tags.idleShutdownMinutes" -o tsv)

if [ -n "$IDLE_TAG" ]; then
    echo -e "${GREEN}✅ Idle shutdown configured: $IDLE_TAG minutes${NC}"
else
    echo -e "${YELLOW}⚠️  Idle shutdown tag not found on VM${NC}"
fi

# Test 5: Check automation runbook
echo ""
echo "[Test 5] Checking automation runbook..."
AA_NAME="aa-pix4d-avd-$ENVIRONMENT"

RUNBOOK=$(az automation runbook list \
    --resource-group "$RG_MAIN" \
    --automation-account-name "$AA_NAME" \
    --query "[?contains(name, 'deallocate')].{name:name,state:state}" -o table 2>/dev/null)

if [ -n "$RUNBOOK" ]; then
    echo -e "${GREEN}✅ Auto-deallocate runbook found:${NC}"
    echo "$RUNBOOK"
else
    echo -e "${YELLOW}⚠️  Auto-deallocate runbook not found${NC}"
fi

# Test 6: Simulate manual start
echo ""
echo "[Test 6] Testing manual VM start..."
echo -e "${YELLOW}Starting VM...${NC}"
az vm start --resource-group "$RG_MAIN" --name "$VM_NAME" --no-wait

echo -e "${YELLOW}Waiting for VM to start...${NC}"
TIMEOUT=300
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    STATE=$(az vm show \
        --resource-group "$RG_MAIN" \
        --name "$VM_NAME" \
        --show-details \
        --query "powerState" -o tsv)
    
    if [ "$STATE" = "VM running" ]; then
        echo -e "${GREEN}✅ VM successfully started${NC}"
        break
    fi
    
    echo -e "${YELLOW}Waiting for start... ($ELAPSED seconds elapsed)${NC}"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "${RED}❌ Timeout waiting for VM to start${NC}"
    exit 1
fi

# Test 7: Verify GPU availability
echo ""
echo "[Test 7] Verifying GPU availability..."
echo -e "${YELLOW}Note: This requires VM extensions to be fully installed${NC}"
echo -e "${CYAN}You should manually verify GPU with: nvidia-smi${NC}"

# Summary
echo ""
echo "========================================"
echo -e "${CYAN}E2E Test Summary${NC}"
echo "========================================"
echo -e "${GREEN}✅ All critical tests passed${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "${NC}1. Connect to the session host via AVD${NC}"
echo -e "${NC}2. Verify GPU with 'nvidia-smi'${NC}"
echo -e "${NC}3. Disconnect and wait for auto-deallocation${NC}"
echo -e "${NC}4. Verify VM is deallocated after idle period${NC}"

exit 0
