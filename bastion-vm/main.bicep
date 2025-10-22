// ========================================
// Simple Bastion VM Deployment
// ========================================
// Purpose: Single Windows 11 VM with Azure Bastion for secure RDP
// No AVD complexity - just a simple VM with GPU
// ========================================

targetScope = 'subscription'

@description('Location for all resources')
param location string = 'northeurope'

@description('Environment name')
param environment string = 'lab'

@description('Project name prefix')
param projectName string = 'pix4d'

@description('VM SKU - GPU enabled')
param vmSku string = 'Standard_NV4as_v4'

@description('Admin Username for VM')
param adminUsername string = 'azureuser'

@description('Admin Password for VM')
@secure()
param adminPassword string

@description('Tags for resources')
param tags object = {
  Environment: environment
  Project: 'PIX4D GPU Lab'
  ManagedBy: 'Bicep'
  Purpose: 'Simple VM with Bastion'
}

// Variables
var resourceGroupName = 'rg-${projectName}-${environment}-${location}'
var vnetName = 'vnet-${projectName}-${environment}'
var bastionName = 'bastion-${projectName}-${environment}'
var vmName = '${projectName}-vm'

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Virtual Network
module vnet './modules/vnet.bicep' = {
  scope: rg
  name: 'deploy-vnet'
  params: {
    location: location
    vnetName: vnetName
    tags: tags
  }
}

// Azure Bastion (Standard SKU for Native Client support)
module bastion './modules/bastion.bicep' = {
  scope: rg
  name: 'deploy-bastion'
  params: {
    location: location
    bastionName: bastionName
    vnetName: vnetName
    tags: tags
  }
  dependsOn: [
    vnet
  ]
}

// Virtual Machine with Azure AD Join
module vm './modules/vm.bicep' = {
  scope: rg
  name: 'deploy-vm'
  params: {
    location: location
    vmName: vmName
    vmSku: vmSku
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetName: vnetName
    tags: tags
  }
  dependsOn: [
    vnet
  ]
}

// Outputs
output resourceGroupName string = resourceGroupName
output vmName string = vmName
output bastionName string = bastionName
output vnetName string = vnetName
output location string = location
