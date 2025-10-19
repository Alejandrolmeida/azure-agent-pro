// Main Bicep orchestration for PIX4D AVD Lab
targetScope = 'subscription'

@description('Location for all resources')
param location string = 'westeurope'

@description('Environment name')
@allowed([
  'dev'
  'prod'
  'lab'
])
param environment string = 'lab'

@description('Project name prefix')
param projectName string = 'pix4d-avd'

@description('VM SKU for Session Hosts - NVads A10 v5 series')
@allowed([
  'Standard_NV12ads_A10_v5'
  'Standard_NV18ads_A10_v5'
  'Standard_NV36ads_A10_v5'
])
param vmSku string = 'Standard_NV36ads_A10_v5'

@description('Number of Session Hosts')
@minValue(1)
@maxValue(50)
param sessionHostCount int = 10

@description('Enable Start VM on Connect')
param enableStartVmOnConnect bool = true

@description('Idle time before deallocate (minutes)')
param idleDeallocateMinutes int = 30

@description('Class window in UTC (format: HH:MM-HH:MM)')
param classWindow string = '16:00-21:00'

@description('FSLogix share tier')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
])
param fslogixShareTier string = 'Premium_LRS'

@description('FSLogix share quota in GB')
param fslogixShareQuotaGB int = 1024

@description('Data disk size per VM in GB')
param dataDiskSizeGB int = 512

@description('Admin Username for VMs')
@secure()
param adminUsername string

@description('Admin Password for VMs')
@secure()
param adminPassword string

@description('Enable Azure AD Join (true) or AD DS (false)')
param enableAADJoin bool = true

@description('Domain to join (for AD DS only)')
param domainToJoin string = ''

@description('OU Path for domain join (for AD DS only)')
param ouPath string = ''

@description('Domain Join Username (for AD DS only)')
@secure()
param domainJoinUsername string = ''

@description('Domain Join Password (for AD DS only)')
@secure()
param domainJoinPassword string = ''

@description('Custom Image ID from Azure Image Builder')
param customImageId string = ''

@description('Build custom image with Azure Image Builder')
param buildCustomImage bool = false

@description('Notification email for alerts and budgets')
param notificationEmail string

@description('VNet address prefix')
param vnetAddressPrefix string = '10.100.0.0/16'

@description('Session hosts subnet prefix')
param sessionHostsSubnetPrefix string = '10.100.1.0/24'

@description('Private endpoints subnet prefix')
param privateEndpointsSubnetPrefix string = '10.100.2.0/24'

@description('Azure Image Builder subnet prefix')
param aibSubnetPrefix string = '10.100.3.0/24'

@description('Tags for all resources')
param tags object = {
  env: environment
  project: 'fotogrametria-azure-ia'
  costCenter: 'training'
  managedBy: 'bicep'
}

// Variables
var resourceGroupName = 'rg-${projectName}-${environment}-${location}'
var networkingRGName = 'rg-${projectName}-networking-${environment}-${location}'
var imageRGName = 'rg-${projectName}-images-${environment}-${location}'
var monitoringRGName = 'rg-${projectName}-monitoring-${environment}-${location}'

var vnetName = 'vnet-${projectName}-${environment}'
var hostPoolName = 'hp-${projectName}-${environment}'
var workspaceName = 'ws-${projectName}-${environment}'
var appGroupName = 'ag-${projectName}-${environment}'
var storageAccountName = replace('st${projectName}${environment}', '-', '')
var automationAccountName = 'aa-${projectName}-${environment}'
var lawName = 'law-${projectName}-${environment}'
var galleryName = replace('sig${projectName}${environment}', '-', '')
var imageTemplateName = 'it-${projectName}-${environment}'

// Resource Groups
resource rgMain 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

resource rgNetworking 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: networkingRGName
  location: location
  tags: tags
}

resource rgImage 'Microsoft.Resources/resourceGroups@2023-07-01' = if (buildCustomImage) {
  name: imageRGName
  location: location
  tags: tags
}

resource rgMonitoring 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: monitoringRGName
  location: location
  tags: tags
}

// Virtual Network
module vnet './modules/virtual-network.bicep' = {
  scope: rgNetworking
  name: 'deploy-vnet'
  params: {
    location: location
    vnetName: vnetName
    addressPrefix: vnetAddressPrefix
    subnets: [
      {
        name: 'snet-sessionhosts'
        addressPrefix: sessionHostsSubnetPrefix
        networkSecurityGroupName: 'nsg-sessionhosts'
      }
      {
        name: 'snet-privateendpoints'
        addressPrefix: privateEndpointsSubnetPrefix
        networkSecurityGroupName: 'nsg-privateendpoints'
        privateEndpointNetworkPolicies: 'Disabled'
      }
      {
        name: 'snet-aib'
        addressPrefix: aibSubnetPrefix
        networkSecurityGroupName: 'nsg-aib'
      }
    ]
    tags: tags
  }
}

// Monitoring
module monitoring './modules/monitoring/insights.bicep' = {
  scope: rgMonitoring
  name: 'deploy-monitoring'
  params: {
    location: location
    workspaceName: lawName
    notificationEmail: notificationEmail
    tags: tags
  }
}

// Azure Files for FSLogix
module storage './modules/storage/azurefiles.bicep' = {
  scope: rgMain
  name: 'deploy-storage'
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountSku: fslogixShareTier
    shareQuotaGB: fslogixShareQuotaGB
    vnetResourceGroup: networkingRGName
    vnetName: vnetName
    subnetName: 'snet-privateendpoints'
    enablePrivateEndpoint: true
    tags: tags
  }
  dependsOn: [
    vnet
  ]
}

// Azure Image Builder (optional)
module imageBuilder './modules/imagebuilder/aib.bicep' = if (buildCustomImage) {
  scope: rgImage
  name: 'deploy-image-builder'
  params: {
    location: location
    imageTemplateName: imageTemplateName
    galleryName: galleryName
    vnetResourceGroup: networkingRGName
    vnetName: vnetName
    subnetName: 'snet-aib'
    tags: tags
  }
  dependsOn: [
    vnet
  ]
}

// AVD Host Pool
module hostPool './modules/avd/hostpool.bicep' = {
  scope: rgMain
  name: 'deploy-hostpool'
  params: {
    location: location
    hostPoolName: hostPoolName
    enableStartVmOnConnect: enableStartVmOnConnect
    tags: tags
  }
}

// AVD Application Group
module appGroup './modules/avd/appgroup.bicep' = {
  scope: rgMain
  name: 'deploy-appgroup'
  params: {
    location: location
    applicationGroupName: appGroupName
    hostPoolId: hostPool.outputs.hostPoolId
    tags: tags
  }
}

// AVD Workspace
module workspace './modules/avd/workspace.bicep' = {
  scope: rgMain
  name: 'deploy-workspace'
  params: {
    location: location
    workspaceName: workspaceName
    applicationGroupReferences: [
      appGroup.outputs.applicationGroupId
    ]
    tags: tags
  }
}

// AVD Session Hosts
module sessionHosts './modules/avd/sessionhost.bicep' = {
  scope: rgMain
  name: 'deploy-sessionhosts'
  params: {
    location: location
    sessionHostNamePrefix: '${projectName}-sh'
    sessionHostCount: sessionHostCount
    vmSize: vmSku
    vnetResourceGroup: networkingRGName
    vnetName: vnetName
    subnetName: 'snet-sessionhosts'
    customImageId: customImageId
    dataDiskSizeGB: dataDiskSizeGB
    adminUsername: adminUsername
    adminPassword: adminPassword
    hostPoolToken: hostPool.outputs.registrationToken
    enableAADJoin: enableAADJoin
    domainToJoin: domainToJoin
    ouPath: ouPath
    domainJoinUsername: domainJoinUsername
    domainJoinPassword: domainJoinPassword
    idleDeallocateMinutes: idleDeallocateMinutes
    tags: tags
  }
  dependsOn: [
    vnet
  ]
}

// Automation Account for auto-shutdown
module automation './modules/automation/auto-shutdown.bicep' = {
  scope: rgMain
  name: 'deploy-automation'
  params: {
    location: location
    automationAccountName: automationAccountName
    workspaceId: monitoring.outputs.workspaceId
    hostPoolResourceGroup: resourceGroupName
    hostPoolName: hostPoolName
    classWindow: classWindow
    idleDeallocateMinutes: idleDeallocateMinutes
    tags: tags
  }
  dependsOn: [
    hostPool
  ]
}

// Role Assignment: Automation Account needs Contributor on RG
module roleAssignmentAutomation './modules/role-assignment.bicep' = {
  scope: rgMain
  name: 'deploy-role-automation'
  params: {
    principalId: automation.outputs.principalId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment: Automation Account needs Power On/Off on Start VM on Connect
module roleAssignmentVMContributor './modules/role-assignment.bicep' = {
  scope: rgMain
  name: 'deploy-role-vm-contributor'
  params: {
    principalId: automation.outputs.principalId
    roleDefinitionId: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c' // Virtual Machine Contributor
    principalType: 'ServicePrincipal'
  }
}

// Outputs
@description('Resource Group Name')
output resourceGroupName string = resourceGroupName

@description('Host Pool Name')
output hostPoolName string = hostPool.outputs.hostPoolName

@description('Workspace Name')
output workspaceName string = workspace.outputs.workspaceName

@description('Storage Account Name')
output storageAccountName string = storage.outputs.storageAccountName

@description('FSLogix Profile Path')
output fslogixProfilePath string = storage.outputs.fslogixProfilePath

@description('Log Analytics Workspace Name')
output logAnalyticsWorkspaceName string = monitoring.outputs.workspaceName

@description('Automation Account Name')
output automationAccountName string = automation.outputs.automationAccountName

@description('Session Host Names')
output sessionHostNames array = sessionHosts.outputs.sessionHostNames
