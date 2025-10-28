// ============================================================================
// AVD H100 POC - Main Orchestrator
// ============================================================================
// Despliegue completo de infraestructura AVD con VM NC40ads_H100_v5
// Region: Spain Central
// Presupuesto: Infraestructura €20/mes, Workload €50/día
// ============================================================================

targetScope = 'subscription'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Nombre del Resource Group')
param resourceGroupName string = 'rg-avd-h100-poc'

@description('Región de Azure para el despliegue')
@allowed([
  'spaincentral'
])
param location string = 'spaincentral'

@description('Nombre del ambiente (dev, poc, prod)')
@allowed([
  'dev'
  'poc'
  'prod'
])
param environment string = 'poc'

@description('Prefijo para nombrado de recursos')
param resourcePrefix string = 'avdh100'

@description('Usuario administrador de la VM')
@secure()
param vmAdminUsername string

@description('Contraseña del administrador de la VM')
@secure()
param vmAdminPassword string

@description('Object ID del usuario Azure AD para asignar a AVD')
param avdUserObjectId string

@description('SKU de la VM')
@allowed([
  'Standard_NC40ads_H100_v5'
])
param vmSize string = 'Standard_NC40ads_H100_v5'

@description('Habilitar auto-shutdown')
param enableAutoShutdown bool = true

@description('Minutos de inactividad antes de shutdown')
@minValue(5)
@maxValue(60)
param idleMinutesThreshold int = 15

@description('Tu IP pública para acceso NSG (formato CIDR)')
param allowedSourceIpAddress string

@description('Tags comunes para todos los recursos')
param commonTags object = {
  Environment: environment
  Project: 'AVD-H100-POC'
  ManagedBy: 'Bicep'
  CostCenter: 'IT-Innovation'
  DeploymentDate: utcNow('yyyy-MM-dd')
}

// ============================================================================
// VARIABLES
// ============================================================================

var infrastructureTags = union(commonTags, {
  'workload-type': 'infrastructure'
  'budget-limit': '20-eur-month'
})

var workloadTags = union(commonTags, {
  'workload-type': 'session-host'
  'budget-limit': '50-eur-day'
})

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: infrastructureTags
}

// ============================================================================
// MODULE DEPLOYMENTS
// ============================================================================

// 1. Networking - VNET, Subnet, NSG
module network 'modules/network.bicep' = {
  scope: rg
  name: 'network-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    allowedSourceIpAddress: allowedSourceIpAddress
    tags: infrastructureTags
  }
}

// 2. Storage Account - Para transferencia de archivos
module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    tags: infrastructureTags
  }
}

// 3. Monitoring - Log Analytics Workspace
module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  name: 'monitoring-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    tags: infrastructureTags
  }
}

// 4. AVD - Host Pool, Workspace, Application Group
module avd 'modules/avd.bicep' = {
  scope: rg
  name: 'avd-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    avdUserObjectId: avdUserObjectId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: infrastructureTags
  }
}

// 5. Virtual Machine - NC40ads_H100_v5 con drivers NVIDIA
module vm 'modules/vm.bicep' = {
  scope: rg
  name: 'vm-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    vmSize: vmSize
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
    subnetId: network.outputs.subnetId
    hostPoolToken: avd.outputs.hostPoolRegistrationToken
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: workloadTags
  }
}

// 6. Automation - Auto-shutdown con Azure Automation
module automation 'modules/automation.bicep' = {
  scope: rg
  name: 'automation-deployment'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    resourceGroupName: resourceGroupName
    hostPoolName: avd.outputs.hostPoolName
    vmName: vm.outputs.vmName
    idleMinutesThreshold: idleMinutesThreshold
    enableAutoShutdown: enableAutoShutdown
    tags: infrastructureTags
  }
}

// 7. Cost Management - Budgets y Alertas
module costManagement 'modules/cost-management.bicep' = {
  scope: rg
  name: 'cost-management-deployment'
  params: {
    resourceGroupName: resourceGroupName
    infrastructureBudgetAmount: 20
    workloadBudgetAmount: 1500 // €50/día × 30 días
    alertEmailAddress: 'a.almeida@prodware.es'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output resourceGroupName string = rg.name
output vnetId string = network.outputs.vnetId
output subnetId string = network.outputs.subnetId
output nsgId string = network.outputs.nsgId
output storageAccountName string = storage.outputs.storageAccountName
output storageContainerName string = storage.outputs.containerName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output avdWorkspaceName string = avd.outputs.workspaceName
output avdHostPoolName string = avd.outputs.hostPoolName
output vmName string = vm.outputs.vmName
output vmPrivateIpAddress string = vm.outputs.privateIpAddress
output automationAccountName string = automation.outputs.automationAccountName
output deploymentInfo object = {
  deploymentName: deployment().name
  region: location
  environment: environment
  vmSize: vmSize
  autoShutdownEnabled: enableAutoShutdown
  idleThresholdMinutes: idleMinutesThreshold
}
