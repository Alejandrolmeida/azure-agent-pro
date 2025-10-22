// ========================================
// Virtual Network Module - Simple
// ========================================

@description('Location for all resources')
param location string = resourceGroup().location

@description('VNet name')
param vnetName string

@description('Tags for resources')
param tags object = {}

// VNet with 2 subnets: VM subnet and Bastion subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-vm'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'  // Name is required by Azure Bastion
        properties: {
          addressPrefix: '10.0.255.0/26'  // Minimum /26 required
        }
      }
    ]
  }
}

// Basic NSG for VM subnet
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: []  // Bastion handles all RDP access securely
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output vmSubnetId string = vnet.properties.subnets[0].id
output bastionSubnetId string = vnet.properties.subnets[1].id
