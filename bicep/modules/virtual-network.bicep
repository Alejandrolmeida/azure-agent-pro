// Plantilla Bicep para crear una Virtual Network con subredes
// Archivo: virtual-network.bicep

@description('Nombre de la Virtual Network')
param vnetName string

@description('Ubicación donde se creará la Virtual Network')
param location string = resourceGroup().location

@description('Espacio de direcciones CIDR para la Virtual Network')
param addressPrefix string = '10.0.0.0/16'

@description('Configuración de subredes')
param subnets array = [
  {
    name: 'default'
    addressPrefix: '10.0.1.0/24'
    networkSecurityGroup: true
  }
  {
    name: 'app-subnet'
    addressPrefix: '10.0.2.0/24'
    networkSecurityGroup: true
  }
  {
    name: 'data-subnet'
    addressPrefix: '10.0.3.0/24'
    networkSecurityGroup: true
  }
]

@description('Habilitar protección DDoS')
param enableDdosProtection bool = false

@description('Tags para aplicar a los recursos')
param tags object = {
  Environment: 'dev'
  Project: 'azure-agent'
  CreatedBy: 'bicep-template'
}

// Network Security Groups para cada subnet
resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2023-09-01' = [for subnet in subnets: if (subnet.networkSecurityGroup) {
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
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHttpInbound'
        properties: {
          description: 'Allow HTTP inbound traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSSHInbound'
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
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1002
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
  }
}]

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    enableDdosProtection: enableDdosProtection
    subnets: [for (subnet, index) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: subnet.networkSecurityGroup ? {
          id: networkSecurityGroups[index].id
        } : null
      }
    }]
  }
}

// Route Table (opcional)
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: 'rt-${vnetName}'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'DefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}

// Outputs
@description('ID del recurso de Virtual Network')
output virtualNetworkId string = virtualNetwork.id

@description('Nombre de la Virtual Network')
output virtualNetworkName string = virtualNetwork.name

@description('Espacio de direcciones de la Virtual Network')
output addressSpace array = virtualNetwork.properties.addressSpace.addressPrefixes

@description('IDs de las subredes creadas')
output subnetIds array = [for (subnet, index) in subnets: {
  name: subnet.name
  id: virtualNetwork.properties.subnets[index].id
  addressPrefix: virtualNetwork.properties.subnets[index].properties.addressPrefix
}]

@description('IDs de los Network Security Groups')
output networkSecurityGroupIds array = [for (subnet, index) in subnets: subnet.networkSecurityGroup ? {
  name: subnet.name
  nsgId: networkSecurityGroups[index].id
} : {}]