// ============================================================================
// Monitoring Module - Log Analytics Workspace
// ============================================================================
// Workspace para centralizar logs y métricas
// Tag: workload-type=infrastructure
// Costo estimado: €5/mes (5GB ingesta)
// ============================================================================

@description('Región de Azure')
param location string

@description('Prefijo para recursos')
param resourcePrefix string

@description('Tags del recurso')
param tags object

@description('Retención de datos en días')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Límite diario de ingesta en GB')
@minValue(1)
@maxValue(10)
param dailyQuotaGb int = 5

// ============================================================================
// VARIABLES
// ============================================================================

var workspaceName = 'law-${resourcePrefix}-monitoring'

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018' // Pay-as-you-go
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ============================================================================
// DATA SOURCES - Performance Counters
// ============================================================================

// CPU Counters
resource cpuCounters 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: logAnalytics
  name: 'CPUCounters'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Processor'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Processor Time'
  }
}

// Memory Counters
resource memoryCounters 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: logAnalytics
  name: 'MemoryCounters'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Memory'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Available MBytes'
  }
}

// Disk Counters
resource diskCounters 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: logAnalytics
  name: 'DiskCounters'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'LogicalDisk'
    instanceName: '*'
    intervalSeconds: 60
    counterName: '% Free Space'
  }
}

// Network Counters
resource networkCounters 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: logAnalytics
  name: 'NetworkCounters'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Network Interface'
    instanceName: '*'
    intervalSeconds: 60
    counterName: 'Bytes Total/sec'
  }
}

// ============================================================================
// DATA SOURCES - Windows Event Logs
// ============================================================================

// System Events
resource systemEvents 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: logAnalytics
  name: 'SystemEvents'
  kind: 'WindowsEvent'
  properties: {
    eventLogName: 'System'
    eventTypes: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
    ]
  }
}

// Application Events
resource applicationEvents 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: logAnalytics
  name: 'ApplicationEvents'
  kind: 'WindowsEvent'
  properties: {
    eventLogName: 'Application'
    eventTypes: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
    ]
  }
}

// ============================================================================
// SOLUTIONS
// ============================================================================

// Updates Solution
resource updatesolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Updates(${logAnalytics.name})'
  location: location
  tags: tags
  plan: {
    name: 'Updates(${logAnalytics.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Updates'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalytics.id
  }
}

// Security Solution
resource securitySolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Security(${logAnalytics.name})'
  location: location
  tags: tags
  plan: {
    name: 'Security(${logAnalytics.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Security'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalytics.id
  }
}

// ============================================================================
// SAVED QUERIES - Cost Analysis
// ============================================================================

resource costByTagQuery 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalytics
  name: 'CostByWorkloadType'
  properties: {
    category: 'Cost Management'
    displayName: 'Daily Cost by Workload Type'
    query: '''
AzureDiagnostics
| where ResourceType == "MICROSOFT.COMPUTE/VIRTUALMACHINES"
| extend WorkloadType = tostring(tags_s.workload_type)
| summarize DailyCost = sum(todouble(Cost_d)) by bin(TimeGenerated, 1d), WorkloadType
| render timechart
'''
    version: 2
  }
}

resource vmRuntimeQuery 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalytics
  name: 'VMRuntimeHours'
  properties: {
    category: 'Cost Management'
    displayName: 'VM Runtime Hours per Day'
    query: '''
AzureActivity
| where OperationNameValue == "Microsoft.Compute/virtualMachines/start/action" 
    or OperationNameValue == "Microsoft.Compute/virtualMachines/deallocate/action"
| where ResourceId contains "vm-avdh100"
| summarize StartTime = minif(TimeGenerated, OperationNameValue contains "start"),
            StopTime = maxif(TimeGenerated, OperationNameValue contains "deallocate")
    by bin(TimeGenerated, 1d)
| extend RuntimeHours = datetime_diff("hour", StopTime, StartTime)
| project Date = format_datetime(TimeGenerated, "yyyy-MM-dd"), RuntimeHours
'''
    version: 2
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
output logAnalyticsCustomerId string = logAnalytics.properties.customerId
output logAnalyticsWorkspaceLocation string = logAnalytics.location
