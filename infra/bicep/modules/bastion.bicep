// ========================================
// Azure Bastion Module
// ========================================
// Description: Deploys Azure Bastion for secure RDP/SSH access to VMs
//              without exposing public IPs or opening inbound NSG rules.
// Security: Uses SSL over port 443, integrates with Azure AD, no public IPs on VMs required.
// ========================================

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Bastion host')
param bastionName string

@description('Name of the public IP for Bastion')
param bastionPublicIpName string

@description('Name of the existing Virtual Network')
param vnetName string

@description('Tags to apply to resources')
param tags object = {}

// Bastion requires a subnet named exactly 'AzureBastionSubnet' with minimum /26
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  name: '${vnetName}/AzureBastionSubnet'
  properties: {
    addressPrefix: '10.0.255.0/26' // Subnet for Bastion (minimum /26 required)
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
}

// Public IP for Bastion (Standard SKU required)
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: bastionPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard' // Required for Bastion
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Required for Bastion
    publicIPAddressVersion: 'IPv4'
  }
}

// Azure Bastion Host
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Basic' // Options: Basic, Standard (Standard supports native client, file transfer, etc.)
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

// ========================================
// Outputs
// ========================================

@description('Resource ID of the Bastion host')
output bastionId string = bastion.id

@description('Name of the Bastion host')
output bastionName string = bastion.name

@description('DNS name of the Bastion public IP')
output bastionFqdn string = bastionPublicIp.properties.dnsSettings.fqdn
