// ============================================================================
// Network Module - VNET, Subnet, NSG
// ============================================================================
// Crea la infraestructura de red para AVD con seguridad restrictiva
// Tag: workload-type=infrastructure
// ============================================================================

@description('Región de Azure')
param location string

@description('Prefijo para recursos')
param resourcePrefix string

@description('IP pública permitida para acceso (CIDR format: x.x.x.x/32)')
param allowedSourceIpAddress string

@description('Tags del recurso')
param tags object

// ============================================================================
// VARIABLES
// ============================================================================

var vnetName = 'vnet-${resourcePrefix}-${location}'
var subnetName = 'snet-sessionhosts'
var nsgName = 'nsg-${resourcePrefix}-avd'

var vnetAddressPrefix = '10.100.0.0/16'
var subnetAddressPrefix = '10.100.1.0/24'

// ============================================================================
// NETWORK SECURITY GROUP
// ============================================================================

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // INBOUND RULES
      {
        name: 'AllowAVDGateway'
        properties: {
          description: 'Permitir tráfico desde AVD Gateway'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'WindowsVirtualDesktop'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAVDControl'
        properties: {
          description: 'Permitir comunicación con servicio AVD'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1688'
          sourceAddressPrefix: 'WindowsVirtualDesktop'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowRDPFromAuthorizedIP'
        properties: {
          description: 'Permitir RDP desde IP autorizada (backup access)'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: allowedSourceIpAddress
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Denegar todo el tráfico entrante no especificado'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      // OUTBOUND RULES
      {
        name: 'AllowAzureCloud'
        properties: {
          description: 'Permitir comunicación con servicios Azure'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowStorage'
        properties: {
          description: 'Permitir acceso a Azure Storage'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowMonitoring'
        properties: {
          description: 'Permitir envío de telemetría a Azure Monitor'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAAD'
        properties: {
          description: 'Permitir autenticación Azure AD'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowWindowsUpdate'
        properties: {
          description: 'Permitir Windows Update'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowNVIDIADrivers'
        properties: {
          description: 'Permitir descarga de drivers NVIDIA'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 210
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyInternetOutbound'
        properties: {
          description: 'Denegar todo el resto del tráfico saliente a Internet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 4000
          direction: 'Outbound'
        }
      }
    ]
  }
}

// ============================================================================
// VIRTUAL NETWORK
// ============================================================================

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                location
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                location
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetId string = vnet.properties.subnets[0].id
output subnetName string = subnetName
output nsgId string = nsg.id
output nsgName string = nsg.name
output vnetAddressSpace string = vnetAddressPrefix
output subnetAddressPrefix string = subnetAddressPrefix
