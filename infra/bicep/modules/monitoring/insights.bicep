// Monitoring module with Log Analytics and Cost Management
@description('Location for all resources')
param location string = resourceGroup().location

@description('Log Analytics Workspace Name')
param workspaceName string

@description('Log Analytics SKU')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param workspaceSku string = 'PerGB2018'

@description('Log Analytics retention in days')
param retentionInDays int = 30

@description('Tags for the resources')
param tags object = {}

@description('Budget notification email')
param notificationEmail string

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: workspaceSku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Saved Queries for AVD monitoring
resource savedQuery1 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'VMs-Running-Long-Time'
  properties: {
    category: 'AVD Monitoring'
    displayName: 'VMs Running Longer Than 8 Hours'
    query: '''
Heartbeat
| where TimeGenerated > ago(1h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| extend HoursRunning = datetime_diff('hour', now(), LastHeartbeat)
| where HoursRunning > 8
| project Computer, HoursRunning, LastHeartbeat
'''
    version: 1
  }
}

resource savedQuery2 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'GPU-Utilization'
  properties: {
    category: 'AVD Monitoring'
    displayName: 'GPU Utilization by Session Host'
    query: '''
Perf
| where ObjectName == "GPU Adapter Memory"
| where CounterName == "Dedicated Usage"
| summarize AvgGPUMemory = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart
'''
    version: 1
  }
}

resource savedQuery3 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: workspace
  name: 'Stopped-Allocated-VMs'
  properties: {
    category: 'AVD Monitoring'
    displayName: 'VMs in Stopped (Allocated) State'
    query: '''
AzureActivity
| where OperationNameValue == "Microsoft.Compute/virtualMachines/powerOff/action"
| where ActivityStatusValue == "Success"
| project TimeGenerated, Caller, ResourceId
| order by TimeGenerated desc
'''
    version: 1
  }
}

// Alert Rule: VM running too long
resource alertVMRunningTooLong 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-vm-running-long'
  location: location
  tags: tags
  properties: {
    displayName: 'VM Running Longer Than 12 Hours'
    description: 'Alert when session host VMs run longer than 12 hours continuously'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT1H'
    scopes: [
      workspace.id
    ]
    windowSize: 'PT360M'
    criteria: {
      allOf: [
        {
          query: '''
Heartbeat
| where TimeGenerated > ago(12h)
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| extend HoursRunning = datetime_diff('hour', now(), LastHeartbeat)
| where HoursRunning > 12
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
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Alert Rule: No GPU detected
resource alertNoGPU 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-no-gpu-detected'
  location: location
  tags: tags
  properties: {
    displayName: 'No GPU Detected on Session Host'
    description: 'Alert when GPU performance counters are not reporting'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      workspace.id
    ]
    windowSize: 'PT30M'
    criteria: {
      allOf: [
        {
          query: '''
Heartbeat
| where Computer contains "avd"
| where TimeGenerated > ago(30m)
| join kind=leftouter (
    Perf
    | where ObjectName == "GPU Adapter Memory"
    | where TimeGenerated > ago(30m)
) on Computer
| where isempty(ObjectName)
| distinct Computer
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
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Action Group for alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-avd-pix4d'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'AVD-PIX4D'
    enabled: true
    emailReceivers: [
      {
        name: 'NotificationEmail'
        emailAddress: notificationEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// Data Collection Endpoint
resource dce 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: 'dce-avd-pix4d'
  location: location
  tags: tags
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// Data Collection Rule for AVD Insights
resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'dcr-avd-pix4d'
  location: location
  tags: tags
  properties: {
    dataCollectionEndpointId: dce.id
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspace.id
          name: 'avd-workspace'
        }
      ]
    }
    dataSources: {
      performanceCounters: [
        {
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\Processor(_Total)\\% Processor Time'
            '\\Memory\\Available Bytes'
            '\\Memory\\% Committed Bytes In Use'
            '\\LogicalDisk(C:)\\Avg. Disk Queue Length'
            '\\LogicalDisk(C:)\\Current Disk Queue Length'
            '\\Network Interface(*)\\Bytes Total/sec'
            '\\GPU Adapter Memory(*)\\Dedicated Usage'
            '\\GPU Engine(*)\\Utilization Percentage'
          ]
          name: 'perfCounterDataSource'
        }
      ]
      windowsEventLogs: [
        {
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
            'System!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0)]]'
            'Microsoft-FSLogix-Apps/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
          ]
          name: 'eventLogsDataSource'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Perf'
          'Microsoft-Event'
        ]
        destinations: [
          'avd-workspace'
        ]
      }
    ]
  }
}

@description('Workspace ID')
output workspaceId string = workspace.id

@description('Workspace Name')
output workspaceName string = workspace.name

@description('Workspace Customer ID')
output workspaceCustomerId string = workspace.properties.customerId

@description('Data Collection Rule ID')
output dcrId string = dcr.id

@description('Data Collection Endpoint ID')
output dceId string = dce.id

@description('Action Group ID')
output actionGroupId string = actionGroup.id
