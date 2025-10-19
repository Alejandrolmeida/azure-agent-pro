// Main monitoring orchestrator for AVD PIX4D Lab
// Deploys comprehensive observability, cost control, and automation

targetScope = 'subscription'

@description('Azure region')
param location string = 'westeurope'

@description('Environment (lab/prod)')
param environment string = 'lab'

@description('Resource Group prefix')
param resourceGroupPrefix string = 'rg-avd-pix4d'

@description('Log Analytics Workspace name')
param lawName string = 'law-avd-pix4d-${environment}'

@description('Data Collection Endpoint name')
param dceName string = 'dce-avd-pix4d-${environment}'

@description('Data Collection Rule name')
param dcrName string = 'dcr-avd-windowsgpu-${environment}'

@description('Automation Account name')
param automationAccountName string = 'aa-avd-pix4d-${environment}'

@description('Storage Account name for cost exports')
param costExportStorageAccountName string = 'stcost${uniqueString(subscription().subscriptionId)}'

@description('Action Group name for alerts')
param actionGroupName string = 'ag-avd-pix4d-${environment}'

@description('Action Group email')
param actionGroupEmail string

@description('Host Pool Resource Group')
param hostPoolResourceGroup string = '${resourceGroupPrefix}-${environment}'

@description('Host Pool Name')
param hostPoolName string = 'avd-hostpool-${environment}'

@description('Class schedule window (HH:mm-HH:mm)')
param classWindow string = '16:00-21:00'

@description('Idle deallocate threshold (minutes)')
param idleDeallocateMinutes int = 30

@description('Monthly budget in EUR')
param monthlyBudgetAmount int = 300

@description('Daily budget in EUR')
param dailyBudgetAmount int = 15

@description('Enable alerts')
param enableAlerts bool = true

@description('Enable cost exports')
param enableCostExports bool = true

@description('Common resource tags')
param tags object = {
  environment: environment
  project: 'fotogrametria-azure-ia'
  managedBy: 'bicep'
  costCenter: 'training'
}

// Resource Groups
resource rgMonitoring 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${resourceGroupPrefix}-monitoring-${environment}'
  location: location
  tags: tags
}

resource rgCost 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${resourceGroupPrefix}-cost-${environment}'
  location: location
  tags: tags
}

// Action Group (for alerts and budget notifications)
module actionGroup 'modules/action-group.bicep' = {
  name: 'deploy-action-group'
  scope: rgMonitoring
  params: {
    actionGroupName: actionGroupName
    location: 'global'
    emailAddresses: [actionGroupEmail]
    tags: tags
  }
}

// Log Analytics Workspace with AVD Insights
module law 'modules/law.bicep' = {
  name: 'deploy-law'
  scope: rgMonitoring
  params: {
    lawName: lawName
    location: location
    retentionInDays: 30
    enableAVDInsights: true
    tags: tags
  }
}

// Data Collection Endpoint and Rules (GPU counters)
module dceDcr 'modules/dce-dcr-windowsgpu.bicep' = {
  name: 'deploy-dce-dcr'
  scope: rgMonitoring
  params: {
    dceName: dceName
    dcrName: dcrName
    location: location
    lawResourceId: law.outputs.lawId
    counterFrequency: 60
    tags: tags
  }
}

// Metric-based Alerts
module alertsMetrics 'modules/alerts-metrics.bicep' = {
  name: 'deploy-alerts-metrics'
  scope: rgMonitoring
  params: {
    location: location
    lawResourceId: law.outputs.lawId
    actionGroupId: actionGroup.outputs.actionGroupId
    enableAlerts: enableAlerts
    tags: tags
  }
}

// KQL-based Alerts
module alertsKql 'modules/alerts-kql.bicep' = {
  name: 'deploy-alerts-kql'
  scope: rgMonitoring
  params: {
    location: location
    lawResourceId: law.outputs.lawId
    actionGroupId: actionGroup.outputs.actionGroupId
    enableAlerts: enableAlerts
    idleThresholdMinutes: idleDeallocateMinutes
    scheduleStartTime: split(classWindow, '-')[0]
    scheduleEndTime: split(classWindow, '-')[1]
    gpuThresholdPercent: 95
    tags: tags
  }
}

// Storage Account for Cost Exports
module costExportStorage 'modules/storage-cost-export.bicep' = if (enableCostExports) {
  name: 'deploy-cost-export-storage'
  scope: rgCost
  params: {
    storageAccountName: costExportStorageAccountName
    location: location
    tags: tags
  }
}

// Budgets and Cost Exports (subscription scope)
module budgets 'modules/budgets-cost-exports.bicep' = {
  name: 'deploy-budgets-cost-exports'
  scope: rgCost
  params: {
    actionGroupId: actionGroup.outputs.actionGroupId
    storageAccountId: enableCostExports ? costExportStorage.outputs.storageAccountId : ''
    monthlyBudgetAmount: monthlyBudgetAmount
    dailyBudgetAmount: dailyBudgetAmount
    enableCostExports: enableCostExports
    tags: tags
  }
}

// Automation Account with Auto-Deallocate Runbook
module automation 'modules/automation-runbook-deallocate.bicep' = {
  name: 'deploy-automation'
  scope: rgMonitoring
  params: {
    automationAccountName: automationAccountName
    location: location
    lawResourceId: law.outputs.lawId
    hostPoolResourceGroup: hostPoolResourceGroup
    hostPoolName: hostPoolName
    classWindow: classWindow
    idleDeallocateMinutes: idleDeallocateMinutes
  }
}

// Workbooks (AVD Overview + Cost Showback)
module workbooks 'modules/workbooks.bicep' = {
  name: 'deploy-workbooks'
  scope: rgMonitoring
  params: {
    location: location
    lawResourceId: law.outputs.lawId
    tags: tags
  }
}

// Azure Policy Definitions (SKU restrictions, required tags)
module policies 'modules/policy-tags-skus.bicep' = {
  name: 'deploy-policies'
  params: {
    allowedVmSkus: [
      'Standard_NV12ads_A10_v5'
      'Standard_NV18ads_A10_v5'
      'Standard_NV36ads_A10_v5'
    ]
    requiredTags: [
      'env'
      'project'
      'owner'
      'courseId'
      'costCenter'
    ]
    enforcementMode: 'Default'
  }
}

// RBAC: Grant Automation Account permissions
module rbacAutomation 'modules/rbac-automation.bicep' = {
  name: 'deploy-rbac-automation'
  params: {
    automationAccountPrincipalId: automation.outputs.principalId
    hostPoolResourceGroupName: hostPoolResourceGroup
  }
}

// Outputs
output monitoringResourceGroupName string = rgMonitoring.name
output costResourceGroupName string = rgCost.name
output lawId string = law.outputs.lawId
output lawName string = law.outputs.lawName
output dceId string = dceDcr.outputs.dceId
output dcrId string = dceDcr.outputs.dcrId
output automationAccountId string = automation.outputs.automationAccountId
output actionGroupId string = actionGroup.outputs.actionGroupId
output costExportStorageAccountId string = enableCostExports ? costExportStorage.outputs.storageAccountId : ''

