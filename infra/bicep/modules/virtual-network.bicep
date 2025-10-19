// Virtual Network module with multiple subnets
@description('Location for all resources')
param location string = resourceGroup().location

@description('Virtual Network Name')
param vnetName string

@description('Address prefix for VNet')
param addressPrefix string = '10.100.0.0/16'

@description('Subnets configuration')
param subnets array = []

@description('Tags for the resources')
param tags object = {}

// Network Security Groups
resource nsgs 'Microsoft.Network/networkSecurityGroups@2023-05-01' = [for subnet in subnets: if (contains(subnet, 'networkSecurityGroupName')) {
  name: subnet.networkSecurityGroupName
  location: location
  tags: tags
  properties: {
    securityRules: subnet.name == 'snet-sessionhosts' ? [
      {
        name: 'AllowAVDGateway'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'WindowsVirtualDesktop'
        }
      }
      {
        name: 'AllowAzureCloud'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
        }
      }
    ] : []
  }
}]

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for (subnet, i) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: contains(subnet, 'networkSecurityGroupName') ? {
          id: nsgs[i].id
        } : null
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    }]
  }
}

@description('Virtual Network ID')
output vnetId string = vnet.id

@description('Virtual Network Name')
output vnetName string = vnet.name

@description('Subnet IDs')
output subnetIds array = [for (subnet, i) in subnets: {
  name: subnet.name
  id: vnet.properties.subnets[i].id
}]
