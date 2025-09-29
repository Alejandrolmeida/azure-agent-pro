// ========================================
// AZURE VIRTUAL NETWORK MODULE - 2025 MODERNIZED
// ========================================
// This module creates a virtual network with modern security and configuration
// Updated for Azure Network API 2024-05-01 with best practices
// ========================================

// User-Defined Types for improved parameter validation and intellisense
@description('Subnet configuration object')
type SubnetConfig = {
  @description('Name of the subnet')
  name: string

  @description('Address prefix for the subnet (CIDR notation)')
  @minLength(9)
  @maxLength(18)
  addressPrefix: string

  @description('Whether to disable default outbound connectivity')
  defaultOutboundAccess: bool?

  @description('Enable private endpoint network policies (Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled)')
  privateEndpointNetworkPolicies: string?

  @description('Enable private link service network policies (Enabled, Disabled)')
  privateLinkServiceNetworkPolicies: string?

  @description('Array of service endpoint configurations')
  serviceEndpoints: {
    service: string
    locations: string[]?
  }[]?

  @description('Sharing scope for the subnet (Tenant, DelegatedServices)')
  sharingScope: string?

  @description('Create NSG for this subnet')
  createNetworkSecurityGroup: bool?
}

@description('Virtual network encryption configuration')
type VNetEncryptionConfig = {
  @description('Whether encryption is enabled on the virtual network')
  enabled: bool

  @description('Enforcement policy for unencrypted VMs (DropUnencrypted, AllowUnencrypted)')
  enforcement: string?
}

@description('BGP communities configuration')
type BgpCommunitiesConfig = {
  @description('BGP community associated with the virtual network')
  virtualNetworkCommunity: string
}

// Parameters with enhanced validation and modern defaults
@description('The name of the Virtual Network')
@minLength(2)
@maxLength(64)
param virtualNetworkName string

@description('Array of address prefixes for the Virtual Network (CIDR notation)')
@minLength(1)
param addressPrefixes string[] = ['10.0.0.0/16']

@description('Array of subnet configurations with enhanced properties')
@minLength(1)
param subnets SubnetConfig[] = [
  {
    name: 'default'
    addressPrefix: '10.0.0.0/24'
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    createNetworkSecurityGroup: true
  }
  {
    name: 'app-subnet'
    addressPrefix: '10.0.1.0/24'
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    createNetworkSecurityGroup: true
  }
  {
    name: 'data-subnet'
    addressPrefix: '10.0.2.0/24'
    defaultOutboundAccess: false
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    createNetworkSecurityGroup: true
  }
]

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('Enable DDoS protection for the virtual network')
param enableDdosProtection bool = false

@description('Resource ID of the DDoS protection plan (required if enableDdosProtection is true)')
param ddosProtectionPlanId string?

@description('DNS servers for the virtual network (leave empty for Azure-provided DNS)')
param dnsServers string[] = []

@description('Virtual network encryption configuration')
param encryption VNetEncryptionConfig?

@description('BGP communities configuration for ExpressRoute scenarios')
param bgpCommunities BgpCommunitiesConfig?

@description('Flow timeout in minutes for the virtual network (4-30 minutes)')
@minValue(4)
@maxValue(30)
param flowTimeoutInMinutes int = 4

@description('Enable VM protection for all subnets in the virtual network')
param enableVmProtection bool = false

@description('Private endpoint VNet policies')
@allowed(['Disabled', 'Basic'])
param privateEndpointVNetPolicies string = 'Basic'

@description('Create route table for all subnets')
param createRouteTable bool = false

// Variables
var dhcpOptions = !empty(dnsServers)
  ? {
      dnsServers: dnsServers
    }
  : null

var ddosProtectionPlan = enableDdosProtection && ddosProtectionPlanId != null
  ? {
      id: ddosProtectionPlanId!
    }
  : null

// Secure Network Security Groups with modern rules
resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2024-05-01' = [
  for subnet in subnets: if (subnet.?createNetworkSecurityGroup ?? false) {
    name: 'nsg-${subnet.name}'
    location: location
    tags: tags
    properties: {
      securityRules: [
        {
          name: 'AllowHttpsInbound'
          properties: {
            description: 'Allow HTTPS inbound traffic'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 1000
            direction: 'Inbound'
          }
        }
        {
          name: 'AllowSSHFromPrivateNetworks'
          properties: {
            description: 'Allow SSH inbound traffic from private networks only'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '22'
            sourceAddressPrefixes: [
              '10.0.0.0/8'
              '172.16.0.0/12'
              '192.168.0.0/16'
            ]
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 1100
            direction: 'Inbound'
          }
        }
        {
          name: 'AllowVirtualNetworkInbound'
          properties: {
            description: 'Allow inbound traffic within virtual network'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
            access: 'Allow'
            priority: 2000
            direction: 'Inbound'
          }
        }
        {
          name: 'AllowAzureLoadBalancerInbound'
          properties: {
            description: 'Allow Azure Load Balancer health probes'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationAddressPrefix: '*'
            access: 'Allow'
            priority: 2100
            direction: 'Inbound'
          }
        }
        {
          name: 'DenyAllInbound'
          properties: {
            description: 'Deny all other inbound traffic'
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
      ]
      // Enable flush connection for updated rules
      flushConnection: true
    }
  }
]

// Modern Route Table with security-focused defaults
resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = if (createRouteTable) {
  name: 'rt-${virtualNetworkName}'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'InternetRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

// Main Virtual Network Resource with 2024-05-01 API
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    // Address space configuration
    addressSpace: {
      addressPrefixes: addressPrefixes
    }

    // Enhanced subnet configuration with modern security defaults
    subnets: [
      for (subnet, index) in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix

          // Modern security defaults
          defaultOutboundAccess: subnet.?defaultOutboundAccess ?? false
          privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Enabled'
          privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies ?? 'Enabled'

          // Network Security Group association
          networkSecurityGroup: (subnet.?createNetworkSecurityGroup ?? false)
            ? {
                id: networkSecurityGroups[index].id
              }
            : null

          // Route table association
          routeTable: createRouteTable
            ? {
                id: routeTable.id
              }
            : null

          // Service endpoints if specified 
          serviceEndpoints: subnet.?serviceEndpoints

          // Sharing scope for advanced scenarios
          sharingScope: subnet.?sharingScope
        }
      }
    ]

    // DNS configuration
    dhcpOptions: dhcpOptions

    // DDoS protection configuration
    enableDdosProtection: enableDdosProtection
    ddosProtectionPlan: ddosProtectionPlan

    // VM protection
    enableVmProtection: enableVmProtection

    // Flow timeout configuration
    flowTimeoutInMinutes: flowTimeoutInMinutes

    // Encryption configuration for secure networks
    encryption: encryption

    // BGP communities for ExpressRoute
    bgpCommunities: bgpCommunities

    // Private endpoint policies
    privateEndpointVNetPolicies: privateEndpointVNetPolicies
  }
}

// Comprehensive outputs with modern patterns
@description('The resource ID of the virtual network')
output virtualNetworkId string = virtualNetwork.id

@description('The name of the virtual network')
output virtualNetworkName string = virtualNetwork.name

@description('The address space of the virtual network')
output addressSpace string[] = virtualNetwork.properties.addressSpace.addressPrefixes

@description('Array of subnet resource IDs')
output subnetIds string[] = [for (subnet, i) in subnets: virtualNetwork.properties.subnets[i].id]

@description('Array of subnet names and their IDs for easy reference')
output subnetDetails array = [
  for (subnet, i) in subnets: {
    name: subnet.name
    id: virtualNetwork.properties.subnets[i].id
    addressPrefix: subnet.addressPrefix
  }
]

@description('Array of Network Security Group IDs')
output networkSecurityGroupIds array = [
  for (subnet, index) in subnets: (subnet.?createNetworkSecurityGroup ?? false)
    ? {
        name: subnet.name
        nsgId: networkSecurityGroups[index].id
      }
    : {}
]

@description('Route table ID if created')
output routeTableId string = createRouteTable ? routeTable.id : ''

@description('The resource GUID of the virtual network')
output resourceGuid string = virtualNetwork.properties.resourceGuid

@description('The provisioning state of the virtual network')
output provisioningState string = virtualNetwork.properties.provisioningState

@description('Whether DDoS protection is enabled')
output ddosProtectionEnabled bool = virtualNetwork.properties.enableDdosProtection

@description('Whether VM protection is enabled')
output vmProtectionEnabled bool = virtualNetwork.properties.enableVmProtection

@description('Flow timeout in minutes')
output flowTimeoutInMinutes int = virtualNetwork.properties.flowTimeoutInMinutes
