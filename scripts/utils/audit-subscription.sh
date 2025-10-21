#!/bin/bash
# ============================================================================
# Azure Subscription Cleanup Audit Script
# ============================================================================
# Purpose: Identify orphaned resources and cost leaks before deployment
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Azure Subscription Cleanup Audit                           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verify current subscription
CURRENT_SUB=$(az account show --query name -o tsv)
CURRENT_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}📋 Auditing Subscription: ${CURRENT_SUB}${NC}"
echo -e "${CYAN}   ID: ${CURRENT_ID}${NC}"
echo ""

# ============================================================================
# 1. RESOURCE GROUPS
# ============================================================================
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📦 RESOURCE GROUPS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

RG_COUNT=$(az group list --query "length([])" -o tsv)
echo -e "${CYAN}Total Resource Groups: ${RG_COUNT}${NC}"
echo ""

if [ "$RG_COUNT" -gt 0 ]; then
    az group list --query "[].{Name:name, Location:location, State:properties.provisioningState}" -o table
    echo ""
fi

# ============================================================================
# 2. COMPUTE RESOURCES (VMs, Disks, NICs)
# ============================================================================
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}💻 COMPUTE RESOURCES${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

# Virtual Machines
VM_COUNT=$(az vm list --query "length([])" -o tsv)
echo -e "${CYAN}Virtual Machines: ${VM_COUNT}${NC}"
if [ "$VM_COUNT" -gt 0 ]; then
    az vm list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Size:hardwareProfile.vmSize, State:powerState}" -o table
    echo ""
fi

# Disks (including orphaned)
DISK_COUNT=$(az disk list --query "length([])" -o tsv)
echo -e "${CYAN}Managed Disks: ${DISK_COUNT}${NC}"
if [ "$DISK_COUNT" -gt 0 ]; then
    echo "Checking for orphaned disks..."
    ORPHANED_DISKS=$(az disk list --query "[?managedBy==null].{Name:name, ResourceGroup:resourceGroup, SizeGB:diskSizeGb, SKU:sku.name}" -o json)
    ORPHANED_COUNT=$(echo "$ORPHANED_DISKS" | jq 'length')
    
    if [ "$ORPHANED_COUNT" -gt 0 ]; then
        echo -e "${RED}⚠️  Found ${ORPHANED_COUNT} ORPHANED disks (not attached to any VM):${NC}"
        echo "$ORPHANED_DISKS" | jq -r '.[] | "  - \(.Name) (\(.SizeGB)GB \(.SKU)) in \(.ResourceGroup)"'
    else
        echo -e "${GREEN}✅ No orphaned disks found${NC}"
    fi
    echo ""
fi

# Network Interfaces (orphaned)
NIC_COUNT=$(az network nic list --query "length([])" -o tsv)
echo -e "${CYAN}Network Interfaces: ${NIC_COUNT}${NC}"
if [ "$NIC_COUNT" -gt 0 ]; then
    ORPHANED_NICS=$(az network nic list --query "[?virtualMachine==null].{Name:name, ResourceGroup:resourceGroup}" -o json)
    ORPHANED_NIC_COUNT=$(echo "$ORPHANED_NICS" | jq 'length')
    
    if [ "$ORPHANED_NIC_COUNT" -gt 0 ]; then
        echo -e "${RED}⚠️  Found ${ORPHANED_NIC_COUNT} ORPHANED NICs (not attached to any VM):${NC}"
        echo "$ORPHANED_NICS" | jq -r '.[] | "  - \(.Name) in \(.ResourceGroup)"'
    else
        echo -e "${GREEN}✅ No orphaned NICs found${NC}"
    fi
    echo ""
fi

# Public IPs (orphaned)
PIP_COUNT=$(az network public-ip list --query "length([])" -o tsv)
echo -e "${CYAN}Public IPs: ${PIP_COUNT}${NC}"
if [ "$PIP_COUNT" -gt 0 ]; then
    ORPHANED_PIPS=$(az network public-ip list --query "[?ipConfiguration==null].{Name:name, ResourceGroup:resourceGroup, IP:ipAddress, SKU:sku.name}" -o json)
    ORPHANED_PIP_COUNT=$(echo "$ORPHANED_PIPS" | jq 'length')
    
    if [ "$ORPHANED_PIP_COUNT" -gt 0 ]; then
        echo -e "${RED}⚠️  Found ${ORPHANED_PIP_COUNT} ORPHANED Public IPs:${NC}"
        echo "$ORPHANED_PIPS" | jq -r '.[] | "  - \(.Name) (\(.IP)) [\(.SKU)] in \(.ResourceGroup)"'
    else
        echo -e "${GREEN}✅ No orphaned Public IPs found${NC}"
    fi
    echo ""
fi

# ============================================================================
# 3. STORAGE RESOURCES
# ============================================================================
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}💾 STORAGE RESOURCES${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

STORAGE_COUNT=$(az storage account list --query "length([])" -o tsv)
echo -e "${CYAN}Storage Accounts: ${STORAGE_COUNT}${NC}"
if [ "$STORAGE_COUNT" -gt 0 ]; then
    az storage account list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, SKU:sku.name, Kind:kind}" -o table
    echo ""
fi

# ============================================================================
# 4. NETWORKING RESOURCES
# ============================================================================
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🌐 NETWORKING RESOURCES${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

VNET_COUNT=$(az network vnet list --query "length([])" -o tsv)
echo -e "${CYAN}Virtual Networks: ${VNET_COUNT}${NC}"
if [ "$VNET_COUNT" -gt 0 ]; then
    az network vnet list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, AddressSpace:join(',',addressSpace.addressPrefixes)}" -o table
    echo ""
fi

NSG_COUNT=$(az network nsg list --query "length([])" -o tsv)
echo -e "${CYAN}Network Security Groups: ${NSG_COUNT}${NC}"
if [ "$NSG_COUNT" -gt 0 ]; then
    az network nsg list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o table
    echo ""
fi

# ============================================================================
# 5. AVD RESOURCES
# ============================================================================
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}🖥️  AVD RESOURCES${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

HOSTPOOL_COUNT=$(az desktopvirtualization hostpool list --query "length([])" -o tsv 2>/dev/null || echo "0")
echo -e "${CYAN}Host Pools: ${HOSTPOOL_COUNT}${NC}"
if [ "$HOSTPOOL_COUNT" -gt 0 ]; then
    az desktopvirtualization hostpool list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Type:hostPoolType}" -o table
    echo ""
fi

WORKSPACE_COUNT=$(az desktopvirtualization workspace list --query "length([])" -o tsv 2>/dev/null || echo "0")
echo -e "${CYAN}Workspaces: ${WORKSPACE_COUNT}${NC}"
if [ "$WORKSPACE_COUNT" -gt 0 ]; then
    az desktopvirtualization workspace list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o table
    echo ""
fi

# ============================================================================
# 6. MONITORING & AUTOMATION
# ============================================================================
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📊 MONITORING & AUTOMATION${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

LAW_COUNT=$(az monitor log-analytics workspace list --query "length([])" -o tsv)
echo -e "${CYAN}Log Analytics Workspaces: ${LAW_COUNT}${NC}"
if [ "$LAW_COUNT" -gt 0 ]; then
    az monitor log-analytics workspace list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, SKU:sku.name}" -o table
    echo ""
fi

AA_COUNT=$(az automation account list --query "length([])" -o tsv 2>/dev/null || echo "0")
echo -e "${CYAN}Automation Accounts: ${AA_COUNT}${NC}"
if [ "$AA_COUNT" -gt 0 ]; then
    az automation account list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o table
    echo ""
fi

# ============================================================================
# 7. COST ESTIMATE (Last 30 days)
# ============================================================================
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}💰 COST ANALYSIS (Last 30 days)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"

# Get cost for last 30 days
START_DATE=$(date -d '30 days ago' '+%Y-%m-%d')
END_DATE=$(date '+%Y-%m-%d')

echo -e "${CYAN}Fetching costs from ${START_DATE} to ${END_DATE}...${NC}"
TOTAL_COST=$(az consumption usage list \
    --start-date "$START_DATE" \
    --end-date "$END_DATE" \
    --query "sum([].pretaxCost)" -o tsv 2>/dev/null || echo "N/A")

if [ "$TOTAL_COST" != "N/A" ]; then
    echo -e "${CYAN}Total Cost (30 days): €${TOTAL_COST}${NC}"
    echo -e "${CYAN}Estimated monthly: €$(echo "$TOTAL_COST" | awk '{printf "%.2f", $1}')/month${NC}"
else
    echo -e "${YELLOW}⚠️  Cost data not available (API limitation or no usage)${NC}"
fi
echo ""

# ============================================================================
# 8. SUMMARY & RECOMMENDATIONS
# ============================================================================
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  CLEANUP RECOMMENDATIONS                                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

CLEANUP_NEEDED=0

if [ "$ORPHANED_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  Delete ${ORPHANED_COUNT} orphaned disks to save storage costs${NC}"
    CLEANUP_NEEDED=1
fi

if [ "$ORPHANED_NIC_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  Delete ${ORPHANED_NIC_COUNT} orphaned NICs (minimal cost but cleaner)${NC}"
    CLEANUP_NEEDED=1
fi

if [ "$ORPHANED_PIP_COUNT" -gt 0 ]; then
    echo -e "${RED}⚠️  Delete ${ORPHANED_PIP_COUNT} orphaned Public IPs to save ~€3-4/month each${NC}"
    CLEANUP_NEEDED=1
fi

if [ "$VM_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}ℹ️  Review ${VM_COUNT} VMs - ensure they are deallocated when not in use${NC}"
    CLEANUP_NEEDED=1
fi

if [ "$CLEANUP_NEEDED" -eq 0 ]; then
    echo -e "${GREEN}✅ No cleanup needed! Subscription is clean.${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Audit completed!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
