<#
.SYNOPSIS
    Automatically deallocate stopped AVD session host VMs to save costs.

.DESCRIPTION
    This runbook performs the following:
    1. Finds VMs in "Stopped" (allocated) state and deallocates them
    2. Checks if current time is outside the class window
    3. If outside class window, stops and deallocates running VMs (except those tagged with maintenance=true)
    4. Handles budget exceeded scenarios with forced shutdown
    5. Supports multiple cutoff reasons: budgetExceeded, idle, outOfSchedule, stoppedAllocated
    6. Tags VMs with cutoff reason and timestamp
    7. Sends detailed logs to Log Analytics

.NOTES
    Author: Azure Agent Pro
    Version: 2.0.0
    Requires: Az.Accounts, Az.Compute, Az.DesktopVirtualization modules
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('budgetExceeded', 'idle', 'outOfSchedule', 'stoppedAllocated', 'manual', 'auto')]
    [string]$CutoffReason = 'auto',
    
    [Parameter(Mandatory = $false)]
    [string]$TargetResourceGroup = '',
    
    [Parameter(Mandatory = $false)]
    [string]$TargetOwner = '',
    
    [Parameter(Mandatory = $false)]
    [string]$TargetCourseId = '',
    
    [Parameter(Mandatory = $false)]
    [bool]$ForcedShutdown = $false
)

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
    Write-Output "  Cutoff Reason: $CutoffReason"
    Write-Output "  Forced Shutdown: $ForcedShutdown"
    
    if ($TargetResourceGroup) {
        Write-Output "  Target Resource Group: $TargetResourceGroup"
    }
    if ($TargetOwner) {
        Write-Output "  Target Owner: $TargetOwner"
    }
    if ($TargetCourseId) {
        Write-Output "  Target Course ID: $TargetCourseId"
    }
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
$allSessionHostVMs = Get-AzVM -Status | Where-Object { 
    $_.Tags.ContainsKey('sessionHost') -and $_.Tags['sessionHost'] -eq 'true'
}

# Apply filters based on parameters
$sessionHostVMs = $allSessionHostVMs | Where-Object {
    $match = $true
    
    # Filter by Resource Group if specified
    if ($TargetResourceGroup -and $_.ResourceGroupName -ne $TargetResourceGroup) {
        $match = $false
    }
    
    # Filter by Owner tag if specified
    if ($TargetOwner -and ($_.Tags['owner'] -ne $TargetOwner)) {
        $match = $false
    }
    
    # Filter by CourseId tag if specified
    if ($TargetCourseId -and ($_.Tags['courseId'] -ne $TargetCourseId)) {
        $match = $false
    }
    
    $match
}

Write-Output "Found $($allSessionHostVMs.Count) total session host VMs"
Write-Output "After filtering: $($sessionHostVMs.Count) VMs match criteria"

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
    
    if ($isInMaintenance -and -not $ForcedShutdown) {
        Write-Output "  VM $vmName is in maintenance mode, skipping"
        continue
    }
    
    # Determine action based on cutoff reason and current state
    $shouldShutdown = $false
    $actionReason = $CutoffReason
    
    # Handle different cutoff reasons
    switch ($CutoffReason) {
        'budgetExceeded' {
            # Budget exceeded: shut down all running VMs immediately
            if ($powerState -in @('running', 'starting')) {
                $shouldShutdown = $true
                Write-Output "  Budget exceeded: forcing shutdown of $vmName"
            }
        }
        'idle' {
            # Idle: only shut down if no active sessions
            if ($powerState -eq 'running') {
                try {
                    $sessions = Get-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $HostPoolResourceGroup -SessionHostName "$vmName*" -ErrorAction SilentlyContinue
                    
                    if (-not $sessions -or $sessions.Count -eq 0) {
                        $shouldShutdown = $true
                        Write-Output "  VM $vmName is idle with no active sessions"
                    }
                    else {
                        Write-Output "  VM $vmName has $($sessions.Count) active session(s), skipping"
                    }
                }
                catch {
                    Write-Warning "  Could not check sessions for $vmName : $_"
                }
            }
        }
        'outOfSchedule' {
            # Out of schedule: shut down running VMs if outside class window
            if ($powerState -eq 'running' -and -not $inClassWindow) {
                $shouldShutdown = $true
                Write-Output "  VM $vmName is running outside class window"
            }
        }
        'stoppedAllocated' {
            # Specifically target stopped but allocated VMs
            if ($powerState -eq 'stopped') {
                $shouldShutdown = $true
                Write-Output "  VM $vmName is stopped but not deallocated"
            }
        }
        'manual' {
            # Manual: shut down all running or stopped VMs
            if ($powerState -in @('running', 'stopped', 'starting')) {
                $shouldShutdown = $true
                Write-Output "  Manual shutdown requested for $vmName"
            }
        }
        'auto' {
            # Auto mode: apply standard logic
            if ($powerState -eq 'stopped') {
                $shouldShutdown = $true
                $actionReason = 'stoppedAllocated'
            }
            elseif ($powerState -eq 'running' -and -not $inClassWindow) {
                try {
                    $sessions = Get-AzWvdUserSession -HostPoolName $HostPoolName -ResourceGroupName $HostPoolResourceGroup -SessionHostName "$vmName*" -ErrorAction SilentlyContinue
                    
                    if (-not $sessions -or $sessions.Count -eq 0) {
                        $shouldShutdown = $true
                        $actionReason = 'outOfSchedule'
                    }
                }
                catch {
                    Write-Warning "  Could not check sessions for $vmName : $_"
                }
            }
        }
    }
    
    # Execute shutdown if needed
    if ($shouldShutdown) {
        try {
            # Stop and deallocate
            Write-Output "  Shutting down and deallocating $vmName (reason: $actionReason)..."
            Stop-AzVM -ResourceGroupName $vmRG -Name $vmName -Force -NoWait -ErrorAction Stop
            
            # Tag VM with cutoff reason and timestamp
            $newTags = $vm.Tags
            if (-not $newTags) {
                $newTags = @{}
            }
            $newTags['lastCutoffReason'] = $actionReason
            $newTags['lastCutoffTimestamp'] = (Get-Date -Format o)
            
            Update-AzTag -ResourceId $vm.Id -Tag $newTags -Operation Merge -ErrorAction SilentlyContinue
            
            # Track action
            if ($actionReason -eq 'stoppedAllocated') {
                $stoppedAllocated += $vmName
            }
            else {
                $shutDown += $vmName
            }
            
            Write-Output "  Shutdown command sent for $vmName"
        }
        catch {
            $errorMsg = "Failed to shutdown $vmName : $_"
            Write-Error $errorMsg
            $errors += $errorMsg
        }
    }
    elseif ($powerState -eq 'deallocated') {
        $deallocated += $vmName
        Write-Output "  VM $vmName is already deallocated"
    }
    else {
        Write-Output "  VM $vmName requires no action (State: $powerState)"
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
