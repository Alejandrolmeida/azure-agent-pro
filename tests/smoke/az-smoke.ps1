<#
.SYNOPSIS
    Smoke tests for AVD PIX4D infrastructure deployment.

.DESCRIPTION
    Performs basic validation that core resources are deployed and accessible.
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "lab",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westeurope"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AVD PIX4D Smoke Tests" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testsPassed = 0
$testsFailed = 0

function Test-Resource {
    param(
        [string]$TestName,
        [scriptblock]$TestBlock
    )
    
    Write-Host "Testing: $TestName..." -NoNewline
    try {
        $result = & $TestBlock
        if ($result) {
            Write-Host " ✅ PASSED" -ForegroundColor Green
            $script:testsPassed++
            return $true
        } else {
            Write-Host " ❌ FAILED" -ForegroundColor Red
            $script:testsFailed++
            return $false
        }
    }
    catch {
        Write-Host " ❌ FAILED: $_" -ForegroundColor Red
        $script:testsFailed++
        return $false
    }
}

# Test 1: Resource Groups Exist
Test-Resource "Resource Groups Exist" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $rgNetworking = "rg-pix4d-avd-networking-$Environment-$Location"
    $rgMonitoring = "rg-pix4d-avd-monitoring-$Environment-$Location"
    
    $rgs = Get-AzResourceGroup
    return ($rgs.ResourceGroupName -contains $rgMain) -and 
           ($rgs.ResourceGroupName -contains $rgNetworking) -and
           ($rgs.ResourceGroupName -contains $rgMonitoring)
}

# Test 2: Virtual Network Exists
Test-Resource "Virtual Network Exists" {
    $rgNetworking = "rg-pix4d-avd-networking-$Environment-$Location"
    $vnetName = "vnet-pix4d-avd-$Environment"
    
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $rgNetworking -Name $vnetName -ErrorAction SilentlyContinue
    return $null -ne $vnet
}

# Test 3: Required Subnets Exist
Test-Resource "Required Subnets Exist" {
    $rgNetworking = "rg-pix4d-avd-networking-$Environment-$Location"
    $vnetName = "vnet-pix4d-avd-$Environment"
    
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $rgNetworking -Name $vnetName
    $requiredSubnets = @('snet-sessionhosts', 'snet-privateendpoints', 'snet-aib')
    
    foreach ($subnet in $requiredSubnets) {
        if ($vnet.Subnets.Name -notcontains $subnet) {
            return $false
        }
    }
    return $true
}

# Test 4: Host Pool Exists
Test-Resource "AVD Host Pool Exists" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $hostPoolName = "hp-pix4d-avd-$Environment"
    
    $hostPool = Get-AzWvdHostPool -ResourceGroupName $rgMain -Name $hostPoolName -ErrorAction SilentlyContinue
    return $null -ne $hostPool
}

# Test 5: Start VM on Connect Enabled
Test-Resource "Start VM on Connect Enabled" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $hostPoolName = "hp-pix4d-avd-$Environment"
    
    $hostPool = Get-AzWvdHostPool -ResourceGroupName $rgMain -Name $hostPoolName
    return $hostPool.StartVMOnConnect -eq $true
}

# Test 6: Workspace Exists
Test-Resource "AVD Workspace Exists" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $workspaceName = "ws-pix4d-avd-$Environment"
    
    $workspace = Get-AzWvdWorkspace -ResourceGroupName $rgMain -Name $workspaceName -ErrorAction SilentlyContinue
    return $null -ne $workspace
}

# Test 7: Application Group Exists
Test-Resource "Application Group Exists" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $appGroupName = "ag-pix4d-avd-$Environment"
    
    $appGroup = Get-AzWvdApplicationGroup -ResourceGroupName $rgMain -Name $appGroupName -ErrorAction SilentlyContinue
    return $null -ne $appGroup
}

# Test 8: Storage Account Exists
Test-Resource "Storage Account Exists" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $storageAccountName = "stpix4davd$Environment" -replace '-', ''
    
    $storage = Get-AzStorageAccount -ResourceGroupName $rgMain -Name $storageAccountName -ErrorAction SilentlyContinue
    return $null -ne $storage
}

# Test 9: FSLogix File Share Exists
Test-Resource "FSLogix File Share Exists" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $storageAccountName = "stpix4davd$Environment" -replace '-', ''
    
    $storage = Get-AzStorageAccount -ResourceGroupName $rgMain -Name $storageAccountName
    $ctx = $storage.Context
    $share = Get-AzStorageShare -Context $ctx -Name "profiles" -ErrorAction SilentlyContinue
    return $null -ne $share
}

# Test 10: Log Analytics Workspace Exists
Test-Resource "Log Analytics Workspace Exists" {
    $rgMonitoring = "rg-pix4d-avd-monitoring-$Environment-$Location"
    $lawName = "law-pix4d-avd-$Environment"
    
    $law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgMonitoring -Name $lawName -ErrorAction SilentlyContinue
    return $null -ne $law
}

# Test 11: Automation Account Exists
Test-Resource "Automation Account Exists" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $aaName = "aa-pix4d-avd-$Environment"
    
    $aa = Get-AzAutomationAccount -ResourceGroupName $rgMain -Name $aaName -ErrorAction SilentlyContinue
    return $null -ne $aa
}

# Test 12: Session Hosts Exist
Test-Resource "Session Hosts Exist" {
    $rgMain = "rg-pix4d-avd-$Environment-$Location"
    $hostPoolName = "hp-pix4d-avd-$Environment"
    
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $rgMain -HostPoolName $hostPoolName -ErrorAction SilentlyContinue
    return $sessionHosts.Count -gt 0
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor Red
Write-Host "Total Tests: $($testsPassed + $testsFailed)" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    Write-Host "`n❌ Some tests failed. Please review the errors above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All tests passed successfully!" -ForegroundColor Green
    exit 0
}
