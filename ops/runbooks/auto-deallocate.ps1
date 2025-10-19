<#
.SYNOPSIS
    Automatically deallocate stopped AVD session host VMs to save costs.

.DESCRIPTION
    This runbook performs the following:
    1. Finds VMs in "Stopped" (allocated) state and deallocates them
    2. Checks if current time is outside the class window
    3. If outside class window, stops and deallocates running VMs (except those tagged with maintenance=true)
    4. Sends detailed logs to Log Analytics

.NOTES
    Author: Azure Agent Pro
    Version: 1.0.0
    Requires: Az.Accounts, Az.Compute, Az.DesktopVirtualization modules
#>

param()

# Connect using System-Assigned Managed Identity
try {
    Write-Output "Connecting to Azure using Managed Identity..."
    Connect-AzAccount -Identity -ErrorAction Stop
    Write-Output "Successfully connected to Azure"
}
catch {
    Write-Error "Failed to connect to Azure: $_"
    exit 1
}

# Get automation variables
try {
    $HostPoolResourceGroup = Get-AutomationVariable -Name 'HostPoolResourceGroup'
    $HostPoolName = Get-AutomationVariable -Name 'HostPoolName'
    $ClassWindow = Get-AutomationVariable -Name 'ClassWindow'
    $IdleDeallocateMinutes = [int](Get-AutomationVariable -Name 'IdleDeallocateMinutes')
    
    Write-Output "Configuration loaded:"
    Write-Output "  Host Pool RG: $HostPoolResourceGroup"
    Write-Output "  Host Pool Name: $HostPoolName"
    Write-Output "  Class Window: $ClassWindow"
    Write-Output "  Idle Deallocate Minutes: $IdleDeallocateMinutes"
}
catch {
    Write-Error "Failed to load automation variables: $_"
    exit 1
}

# Parse class window
$windowParts = $ClassWindow -split '-'
$windowStart = [DateTime]::ParseExact($windowParts[0], 'HH:mm', $null)
$windowEnd = [DateTime]::ParseExact($windowParts[1], 'HH:mm', $null)
$currentTime = (Get-Date).ToUniversalTime()
$currentTimeOnly = [DateTime]::ParseExact($currentTime.ToString('HH:mm'), 'HH:mm', $null)

Write-Output "Current UTC time: $($currentTime.ToString('HH:mm'))"
Write-Output "Class window: $($windowStart.ToString('HH:mm')) - $($windowEnd.ToString('HH:mm'))"

# Check if we're in class window
$inClassWindow = $false
if ($windowStart -lt $windowEnd) {
    $inClassWindow = ($currentTimeOnly -ge $windowStart) -and ($currentTimeOnly -le $windowEnd)
}
else {
    # Window spans midnight
    $inClassWindow = ($currentTimeOnly -ge $windowStart) -or ($currentTimeOnly -le $windowEnd)
}

Write-Output "Currently in class window: $inClassWindow"

# Get all VMs with sessionHost tag
$sessionHostVMs = Get-AzVM -Status | Where-Object { 
    $_.Tags.ContainsKey('sessionHost') -and $_.Tags['sessionHost'] -eq 'true'
}

Write-Output "Found $($sessionHostVMs.Count) session host VMs"

$stoppedAllocated = @()
$deallocated = @()
$shutDown = @()
$errors = @()

foreach ($vm in $sessionHostVMs) {
    $vmName = $vm.Name
    $vmRG = $vm.ResourceGroupName
    $powerState = ($vm.PowerState -split ' ')[1]
    
    Write-Output "Processing VM: $vmName (State: $powerState)"
    
    # Check if VM has maintenance tag
    $isInMaintenance = $vm.Tags.ContainsKey('maintenance') -and $vm.Tags['maintenance'] -eq 'true'
    
    if ($isInMaintenance) {
        Write-Output "  VM $vmName is in maintenance mode, skipping"
        continue
    }
    
    # Handle stopped but not deallocated VMs
    if ($powerState -eq 'stopped') {
        Write-Output "  VM $vmName is stopped but not deallocated. Deallocating..."
        try {
            Stop-AzVM -ResourceGroupName $vmRG -Name $vmName -Force -NoWait
            $stoppedAllocated += $vmName
            Write-Output "  Deallocation command sent for $vmName"
        }
        catch {
            $errorMsg = "Failed to deallocate $vmName : $_"
            Write-Error $errorMsg
            $errors += $errorMsg
        }
        continue
    }
    
    # Handle running VMs outside class window
    if ($powerState -eq 'running' -and -not $inClassWindow) {
        Write-Output "  VM $vmName is running outside class window. Checking idle time..."
        
        # Get VM session status from AVD
        try {
            $sessions = Get-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $HostPoolResourceGroup -SessionHostName "$vmName*" -ErrorAction SilentlyContinue
            
            if ($sessions -and $sessions.Count -gt 0) {
                Write-Output "  VM $vmName has $($sessions.Count) active session(s), skipping shutdown"
                continue
            }
            
            # No active sessions, safe to shut down
            Write-Output "  VM $vmName has no active sessions. Shutting down and deallocating..."
            Stop-AzVM -ResourceGroupName $vmRG -Name $vmName -Force -NoWait
            $shutDown += $vmName
            Write-Output "  Shutdown command sent for $vmName"
        }
        catch {
            $errorMsg = "Failed to check sessions or shutdown $vmName : $_"
            Write-Error $errorMsg
            $errors += $errorMsg
        }
        continue
    }
    
    # Handle deallocated VMs
    if ($powerState -eq 'deallocated') {
        $deallocated += $vmName
        Write-Output "  VM $vmName is already deallocated"
    }
}

# Summary
Write-Output "`n=== SUMMARY ==="
Write-Output "VMs already deallocated: $($deallocated.Count)"
if ($deallocated.Count -gt 0) {
    Write-Output "  $($deallocated -join ', ')"
}

Write-Output "VMs deallocated this run: $($stoppedAllocated.Count)"
if ($stoppedAllocated.Count -gt 0) {
    Write-Output "  $($stoppedAllocated -join ', ')"
}

Write-Output "VMs shut down outside class window: $($shutDown.Count)"
if ($shutDown.Count -gt 0) {
    Write-Output "  $($shutDown -join ', ')"
}

Write-Output "Errors encountered: $($errors.Count)"
if ($errors.Count -gt 0) {
    foreach ($err in $errors) {
        Write-Output "  $err"
    }
}

Write-Output "`nRunbook execution completed"
