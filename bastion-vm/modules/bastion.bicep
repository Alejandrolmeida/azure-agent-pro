// ========================================
// Azure Bastion Module - Standard SKU
// ========================================
// Standard SKU enables:
// - Native Client support (RDP from Windows desktop)
// - Kerberos authentication
// - Shareable links
// ========================================

@description('Location for all resources')
param location string = resourceGroup().location

@description('Bastion name')
param bastionName string

@description('VNet name (must exist)')
param vnetName string

@description('Tags for resources')
param tags object = {}

// Get existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

// Public IP for Bastion (required)
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${bastionName}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Azure Bastion with Standard SKU
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'  // Standard enables Native Client
  }
  properties: {
    enableTunneling: true  // Required for Native Client
    enableIpConnect: false
    enableFileCopy: true
    enableShareableLink: false
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

output bastionId string = bastion.id
output bastionName string = bastion.name
output bastionPublicIp string = bastionPublicIp.properties.ipAddress
