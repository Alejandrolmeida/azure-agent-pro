// KQL-based scheduled query alerts for AVD monitoring
// Detects idle VMs, out-of-schedule usage, and high GPU usage

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Log Analytics Workspace ID')
param lawResourceId string

@description('Action Group ID for notifications')
param actionGroupId string

@description('Resource tags')
param tags object = {}

@description('Enable alerts')
param enableAlerts bool = true

@description('Idle time threshold in minutes')
param idleThresholdMinutes int = 30

@description('Class schedule start time (HH:mm format)')
param scheduleStartTime string = '16:00'

@description('Class schedule end time (HH:mm format)')
param scheduleEndTime string = '21:00'

@description('GPU utilization threshold percentage')
param gpuThresholdPercent int = 95

// Action group reference
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: split(actionGroupId, '/')[8]
  scope: resourceGroup(split(actionGroupId, '/')[4])
}

// Alert: VMs running outside class schedule
resource alertOutOfSchedule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerts) {
  name: 'avd-alert-out-of-schedule'
  location: location
  tags: tags
  properties: {
    displayName: 'AVD Session Hosts Running Out of Schedule'
    description: 'Detects session hosts running outside of ${scheduleStartTime}-${scheduleEndTime} class schedule'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [ lawResourceId ]
    targetResourceTypes: [ 'Microsoft.Compute/virtualMachines' ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: '''
            Heartbeat
            | where TimeGenerated > ago(15m)
            | where ResourceType == "virtualMachines"
            | where ResourceGroup startswith "rg-avd"
            | summarize LastHeartbeat = max(TimeGenerated) by Computer, ResourceId
            | where format_datetime(now(), 'HH:mm') !between ('${scheduleStartTime}' .. '${scheduleEndTime}')
            | project Computer, ResourceId, LastHeartbeat, TimeOutOfSchedule = now()
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
    actions: {
      actionGroups: [ actionGroupId ]
      customProperties: {
        reason: 'outOfSchedule'
        scheduleWindow: '${scheduleStartTime}-${scheduleEndTime}'
      }
    }
  }
}

// Alert: Idle session hosts (no active sessions for threshold time)
resource alertIdleHosts 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerts) {
  name: 'avd-alert-idle-hosts'
  location: location
  tags: tags
  properties: {
    displayName: 'AVD Session Hosts Idle for Deallocate'
    description: 'Session hosts with no active connections for more than ${idleThresholdMinutes} minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [ lawResourceId ]
    targetResourceTypes: [ 'Microsoft.Compute/virtualMachines' ]
    windowSize: 'PT${idleThresholdMinutes}M'
    criteria: {
      allOf: [
        {
          query: '''
            let idleThreshold = ${idleThresholdMinutes}m;
            let lastUserActivity = WVDConnections
              | where TimeGenerated > ago(idleThreshold)
              | where State == "Connected"
              | summarize LastActivity = max(TimeGenerated) by SessionHostName
              | extend IdleMinutes = datetime_diff('minute', now(), LastActivity);
            Heartbeat
            | where TimeGenerated > ago(15m)
            | where ResourceType == "virtualMachines"
              and ResourceGroup startswith "rg-avd"
            | summarize LastHeartbeat = max(TimeGenerated) by Computer, ResourceId
            | join kind=leftouter (lastUserActivity) on $left.Computer == $right.SessionHostName
            | extend IdleMinutes = coalesce(IdleMinutes, datetime_diff('minute', now(), LastHeartbeat))
            | where IdleMinutes > ${idleThresholdMinutes}
            | project Computer, ResourceId, IdleMinutes, LastHeartbeat, LastActivity
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [ '*' ]
            }
          ]
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [ actionGroupId ]
      customProperties: {
        reason: 'idle'
        idleThresholdMinutes: string(idleThresholdMinutes)
      }
    }
  }
}

// Alert: High sustained GPU usage (potential performance issues or bitcoin mining)
resource alertHighGpu 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerts) {
  name: 'avd-alert-high-gpu'
  location: location
  tags: tags
  properties: {
    displayName: 'AVD High GPU Utilization Alert'
    description: 'GPU utilization above ${gpuThresholdPercent}% for sustained period'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [ lawResourceId ]
    targetResourceTypes: [ 'Microsoft.Compute/virtualMachines' ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: '''
            Perf
            | where TimeGenerated > ago(15m)
            | where ObjectName == "GPU Engine"
              and CounterName == "Utilization Percentage"
            | summarize AvgGpuUtil = avg(CounterValue) by Computer, InstanceName, bin(TimeGenerated, 5m)
            | where AvgGpuUtil > ${gpuThresholdPercent}
            | summarize HighUtilPeriods = count(), MaxUtil = max(AvgGpuUtil) by Computer, InstanceName
            | where HighUtilPeriods >= 3  // At least 3 consecutive 5-min periods
            | project Computer, InstanceName, MaxUtil, HighUtilPeriods
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
          dimensions: [
            {
              name: 'Computer'
              operator: 'Include'
              values: [ '*' ]
            }
          ]
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [ actionGroupId ]
      customProperties: {
        reason: 'highGpuUtilization'
        threshold: string(gpuThresholdPercent)
      }
    }
  }
}

// Alert: VM stopped but not deallocated (still incurring costs)
resource alertStoppedAllocated 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerts) {
  name: 'avd-alert-stopped-allocated'
  location: location
  tags: tags
  properties: {
    displayName: 'AVD VMs Stopped But Still Allocated'
    description: 'Session hosts in Stopped (allocated) state for more than 30 minutes'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [ lawResourceId ]
    targetResourceTypes: [ 'Microsoft.Compute/virtualMachines' ]
    windowSize: 'PT30M'
    criteria: {
      allOf: [
        {
          query: '''
            InsightsMetrics
            | where TimeGenerated > ago(30m)
            | where Namespace == "Computer"
              and Name == "VmAvailabilityState"
            | extend PowerState = case(
                Val == 0, "Unavailable",
                Val == 1, "Available",
                "Unknown"
              )
            | where ResourceGroup startswith "rg-avd"
            | summarize LastSeen = max(TimeGenerated), StateChanges = dcount(Val) by Computer, _ResourceId
            | where StateChanges <= 1  // No state changes in 30 min
            | join kind=inner (
                Heartbeat
                | where TimeGenerated > ago(35m) and TimeGenerated < ago(30m)
                | summarize OldHeartbeat = max(TimeGenerated) by Computer
              ) on Computer
            | project Computer, _ResourceId, LastSeen, StateStableDuration = datetime_diff('minute', now(), LastSeen)
            | where StateStableDuration >= 30
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [ actionGroupId ]
      customProperties: {
        reason: 'stoppedAllocated'
        costImpact: 'high'
      }
    }
  }
}

// Alert: FSLogix profile load failures
resource alertFslogixFailures 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerts) {
  name: 'avd-alert-fslogix-failures'
  location: location
  tags: tags
  properties: {
    displayName: 'AVD FSLogix Profile Load Failures'
    description: 'Detects FSLogix profile mount or load failures'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [ lawResourceId ]
    targetResourceTypes: [ 'Microsoft.Storage/storageAccounts' ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: '''
            Event
            | where TimeGenerated > ago(15m)
            | where Source == "Microsoft-FSLogix-Apps"
              and EventLevelName == "Error"
            | where EventID in (34, 51, 52, 43)  // Profile mount/load errors
            | summarize ErrorCount = count() by Computer, EventID, RenderedDescription
            | project Computer, EventID, RenderedDescription, ErrorCount
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [ actionGroupId ]
      customProperties: {
        reason: 'fslogixError'
        component: 'userProfiles'
      }
    }
  }
}

// Alert: No heartbeat from session hosts (VM down or agent issue)
resource alertNoHeartbeat 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerts) {
  name: 'avd-alert-no-heartbeat'
  location: location
  tags: tags
  properties: {
    displayName: 'AVD Session Host No Heartbeat'
    description: 'Session host has not sent heartbeat for 10 minutes'
    severity: 0
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [ lawResourceId ]
    targetResourceTypes: [ 'Microsoft.Compute/virtualMachines' ]
    windowSize: 'PT10M'
    criteria: {
      allOf: [
        {
          query: '''
            let expectedHosts = Heartbeat
              | where TimeGenerated > ago(1h)
              | where ResourceGroup startswith "rg-avd"
              | distinct Computer;
            Heartbeat
            | where TimeGenerated > ago(10m)
            | where ResourceGroup startswith "rg-avd"
            | summarize LastHeartbeat = max(TimeGenerated) by Computer, ResourceId
            | join kind=rightouter (expectedHosts) on Computer
            | where isnull(LastHeartbeat) or LastHeartbeat < ago(10m)
            | project Computer, ResourceId, LastHeartbeat, MissingFor = datetime_diff('minute', now(), coalesce(LastHeartbeat, ago(10m)))
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: [ actionGroupId ]
      customProperties: {
        reason: 'noHeartbeat'
        severity: 'critical'
      }
    }
  }
}

// Outputs
output alertIds array = [
  enableAlerts ? alertOutOfSchedule.id : ''
  enableAlerts ? alertIdleHosts.id : ''
  enableAlerts ? alertHighGpu.id : ''
  enableAlerts ? alertStoppedAllocated.id : ''
  enableAlerts ? alertFslogixFailures.id : ''
  enableAlerts ? alertNoHeartbeat.id : ''
]

