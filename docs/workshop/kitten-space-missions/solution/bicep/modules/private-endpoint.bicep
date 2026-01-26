@description('Azure region for resources')
param location string

@description('Name for the Private Endpoint')
param privateEndpointName string

@description('Resource ID of the service to connect via Private Link')
param privateLinkServiceId string

@description('Group ID for the Private Link (e.g., sqlServer, vault)')
param groupId string

@description('Subnet ID where Private Endpoint will be created')
param subnetId string

@description('Private DNS Zone name')
param privateDnsZoneName string

@description('Resource tags')
param tags object

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

// Private DNS Zone Group (links Private Endpoint to DNS Zone)
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// Link Private DNS Zone to VNet (requires VNet ID)
// Note: This should be done at the VNet level, not here
// Keeping this as a reference for manual configuration

// Outputs
output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneName string = privateDnsZone.name
