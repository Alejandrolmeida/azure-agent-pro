// Metric-based alerts for Azure Virtual Desktop infrastructure
// Monitors VM health, performance, and operational issues

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Log Analytics Workspace ID')
param lawResourceId string

@description('Action Group ID for notifications')
param actionGroupId string

@description('Resource tags')
param tags object = {}

@description('Target resource group for VMs (pattern)')
param targetResourceGroupName string

@description('Enable alerts')
param enableAlerts bool = true

// Action group reference (imported)
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' existing = {
  name: split(actionGroupId, '/')[8]
  scope: resourceGroup(split(actionGroupId, '/')[4])
}

// Alert: High CPU usage (> 95% for 15 minutes)
resource alertHighCpu 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableAlerts) {
  name: 'avd-alert-high-cpu'
  location: 'global'
  tags: tags
  properties: {
    description: 'CPU usage above 95% for sustained period'
    severity: 2
    enabled: true
    scopes: [
      resourceGroup().id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCpuCondition'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Percentage CPU'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          operator: 'GreaterThan'
          threshold: 95
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Alert: Low available memory (< 500 MB for 10 minutes)
resource alertLowMemory 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableAlerts) {
  name: 'avd-alert-low-memory'
  location: 'global'
  tags: tags
  properties: {
    description: 'Available memory below 500 MB'
    severity: 2
    enabled: true
    scopes: [
      resourceGroup().id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT10M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'LowMemoryCondition'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Available Memory Bytes'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          operator: 'LessThan'
          threshold: 524288000 // 500 MB in bytes
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Alert: Low disk space (< 10% free on C: drive)
resource alertLowDisk 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableAlerts) {
  name: 'avd-alert-low-disk'
  location: 'global'
  tags: tags
  properties: {
    description: 'C: drive has less than 10% free space'
    severity: 1
    enabled: true
    scopes: [
      resourceGroup().id
    ]
    evaluationFrequency: 'PT15M'
    windowSize: 'PT30M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'LowDiskCondition'
          criterionType: 'StaticThresholdCriterion'
          metricName: '% Free Space'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          operator: 'LessThan'
          threshold: 10
          timeAggregation: 'Average'
          dimensions: [
            {
              name: 'LogicalDisk'
              operator: 'Include'
              values: [ 'C:' ]
            }
          ]
        }
      ]
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Alert: High disk latency (> 50ms average)
resource alertHighDiskLatency 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableAlerts) {
  name: 'avd-alert-high-disk-latency'
  location: 'global'
  tags: tags
  properties: {
    description: 'Disk read/write latency above 50ms'
    severity: 2
    enabled: true
    scopes: [
      resourceGroup().id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighDiskLatencyCondition'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'OS Disk Latency'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          operator: 'GreaterThan'
          threshold: 50
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Alert: VM Unhealthy (availability metric)
resource alertVmUnhealthy 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableAlerts) {
  name: 'avd-alert-vm-unhealthy'
  location: 'global'
  tags: tags
  properties: {
    description: 'Virtual machine is in an unhealthy state'
    severity: 0
    enabled: true
    scopes: [
      resourceGroup().id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'VmUnhealthyCondition'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'VmAvailabilityMetric'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Alert: Network connectivity issues
resource alertNetworkIssues 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableAlerts) {
  name: 'avd-alert-network-issues'
  location: 'global'
  tags: tags
  properties: {
    description: 'Network connectivity degradation detected'
    severity: 2
    enabled: true
    scopes: [
      resourceGroup().id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'NetworkErrorsCondition'
          criterionType: 'DynamicThresholdCriterion'
          metricName: 'Network In Total'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          operator: 'LessThan'
          alertSensitivity: 'Medium'
          failingPeriods: {
            numberOfEvaluationPeriods: 4
            minFailingPeriodsToAlert: 3
          }
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Outputs
output alertIds array = [
  enableAlerts ? alertHighCpu.id : ''
  enableAlerts ? alertLowMemory.id : ''
  enableAlerts ? alertLowDisk.id : ''
  enableAlerts ? alertHighDiskLatency.id : ''
  enableAlerts ? alertVmUnhealthy.id : ''
  enableAlerts ? alertNetworkIssues.id : ''
]

