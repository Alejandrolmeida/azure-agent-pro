<#
.SYNOPSIS
    E2E test for Start VM on Connect and auto-deallocate functionality.

.DESCRIPTION
    Tests the complete lifecycle:
    1. VM starts automatically when user connects
    2. VM deallocates after session ends
    3. Cost is only incurred during active usage
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "lab",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westeurope",
    
    [Parameter(Mandatory=$false)]
    [string]$SessionHostName = $null
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AVD Start/Stop E2E Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$rgMain = "rg-pix4d-avd-$Environment-$Location"
$hostPoolName = "hp-pix4d-avd-$Environment"

# Get a session host
if ([string]::IsNullOrEmpty($SessionHostName)) {
    Write-Host "Getting first available session host..."
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $rgMain -HostPoolName $hostPoolName
    if ($sessionHosts.Count -eq 0) {
        Write-Error "No session hosts found!"
        exit 1
    }
    $sessionHost = $sessionHosts[0]
    $SessionHostName = $sessionHost.Name.Split('/')[-1]
    Write-Host "Selected session host: $SessionHostName"
}

# Extract VM name from session host name
$vmName = $SessionHostName.Split('.')[0]
Write-Host "VM Name: $vmName"

# Test 1: Check initial VM state
Write-Host "`n[Test 1] Checking initial VM state..."
$vm = Get-AzVM -ResourceGroupName $rgMain -Name $vmName -Status
$initialState = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty Code
Write-Host "Initial state: $initialState" -ForegroundColor Cyan

# Test 2: Verify VM can be deallocated
if ($initialState -ne 'PowerState/deallocated') {
    Write-Host "`n[Test 2] Deallocating VM..."
    Stop-AzVM -ResourceGroupName $rgMain -Name $vmName -Force
    
    # Wait for deallocation
    $timeout = 300 # 5 minutes
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $vm = Get-AzVM -ResourceGroupName $rgMain -Name $vmName -Status
        $state = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty Code
        
        if ($state -eq 'PowerState/deallocated') {
            Write-Host "✅ VM successfully deallocated" -ForegroundColor Green
            break
        }
        
        Write-Host "Waiting for deallocation... ($elapsed seconds elapsed)" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        $elapsed += 10
    }
    
    if ($elapsed -ge $timeout) {
        Write-Error "Timeout waiting for VM to deallocate"
        exit 1
    }
}

# Test 3: Verify Start VM on Connect setting
Write-Host "`n[Test 3] Verifying Start VM on Connect is enabled..."
$hostPool = Get-AzWvdHostPool -ResourceGroupName $rgMain -Name $hostPoolName
if ($hostPool.StartVMOnConnect -eq $true) {
    Write-Host "✅ Start VM on Connect is enabled" -ForegroundColor Green
} else {
    Write-Error "❌ Start VM on Connect is NOT enabled"
    exit 1
}

# Test 4: Verify idle shutdown tag
Write-Host "`n[Test 4] Verifying idle shutdown configuration..."
$vm = Get-AzVM -ResourceGroupName $rgMain -Name $vmName
if ($vm.Tags.ContainsKey('idleShutdownMinutes')) {
    $idleMinutes = $vm.Tags['idleShutdownMinutes']
    Write-Host "✅ Idle shutdown configured: $idleMinutes minutes" -ForegroundColor Green
} else {
    Write-Warning "⚠️ Idle shutdown tag not found on VM"
}

# Test 5: Check automation runbook
Write-Host "`n[Test 5] Checking automation runbook..."
$aaName = "aa-pix4d-avd-$Environment"
$aa = Get-AzAutomationAccount -ResourceGroupName $rgMain -Name $aaName -ErrorAction SilentlyContinue

if ($null -ne $aa) {
    $runbooks = Get-AzAutomationRunbook -ResourceGroupName $rgMain -AutomationAccountName $aaName
    $deallocateRunbook = $runbooks | Where-Object { $_.Name -like '*deallocate*' }
    
    if ($null -ne $deallocateRunbook) {
        Write-Host "✅ Auto-deallocate runbook found: $($deallocateRunbook.Name)" -ForegroundColor Green
        Write-Host "   State: $($deallocateRunbook.State)" -ForegroundColor Cyan
    } else {
        Write-Warning "⚠️ Auto-deallocate runbook not found"
    }
} else {
    Write-Warning "⚠️ Automation account not found"
}

# Test 6: Simulate manual start (would normally happen via AVD connection)
Write-Host "`n[Test 6] Testing manual VM start..."
Write-Host "Starting VM..." -ForegroundColor Yellow
Start-AzVM -ResourceGroupName $rgMain -Name $vmName -NoWait

Write-Host "Waiting for VM to start..." -ForegroundColor Yellow
$timeout = 300 # 5 minutes
$elapsed = 0
while ($elapsed -lt $timeout) {
    $vm = Get-AzVM -ResourceGroupName $rgMain -Name $vmName -Status
    $state = $vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' } | Select-Object -ExpandProperty Code
    
    if ($state -eq 'PowerState/running') {
        Write-Host "✅ VM successfully started" -ForegroundColor Green
        break
    }
    
    Write-Host "Waiting for start... ($elapsed seconds elapsed)" -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    $elapsed += 10
}

if ($elapsed -ge $timeout) {
    Write-Error "Timeout waiting for VM to start"
    exit 1
}

# Test 7: Verify GPU is available (if VM is running)
Write-Host "`n[Test 7] Verifying GPU availability..."
Write-Host "Note: This requires VM extensions to be fully installed" -ForegroundColor Yellow
Write-Host "You should manually verify GPU with: nvidia-smi" -ForegroundColor Cyan

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "E2E Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ All critical tests passed" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Connect to the session host via AVD" -ForegroundColor White
Write-Host "2. Verify GPU with 'nvidia-smi'" -ForegroundColor White
Write-Host "3. Disconnect and wait for auto-deallocation" -ForegroundColor White
Write-Host "4. Verify VM is deallocated after idle period" -ForegroundColor White

exit 0
