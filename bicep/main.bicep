// Plantilla principal que utiliza múltiples módulos
// Archivo: main.bicep
// Actualizado con Bicep Best Practices 2025

// User-Defined Types (nueva recomendación 2025)
@description('Configuración de red para el proyecto')
type NetworkConfig = {
  @description('Nombre de la VNet')
  vnetName: string
  @description('Prefijo de direcciones CIDR')
  addressPrefix: string
  @description('Configuración de subredes')
  subnets: SubnetConfig[]
}

@description('Configuración individual de subnet')
type SubnetConfig = {
  @description('Nombre de la subnet')
  name: string
  @description('Prefijo de direcciones de la subnet')
  addressPrefix: string
  @description('Habilitar Network Security Group')
  networkSecurityGroup: bool
}

@description('Configuración de tags comunes')
type CommonTags = {
  @description('Entorno del recurso')
  Environment: string
  @description('Nombre del proyecto')
  Project: string
  @description('Método de creación')
  CreatedBy: string
  @description('Fecha de creación')
  CreatedDate: string
}

@description('Prefijo para los nombres de recursos')
param resourcePrefix string = 'demo'

@description('Ubicación donde se crearán los recursos')
param location string = resourceGroup().location

@description('Entorno (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Nombre del proyecto')
param projectName string = 'azure-agent'

// Variables optimizadas (compatible con versiones actuales)
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 5)
var storageAccountName = '${resourcePrefix}st${uniqueSuffix}'
var keyVaultName = '${resourcePrefix}-kv-${uniqueSuffix}'
var vnetName = '${resourcePrefix}-vnet'

// Configuración de red estructurada con configuración moderna
var networkConfiguration = {
  virtualNetworkName: vnetName
  addressPrefixes: ['10.0.0.0/16']
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.1.0/24'
      defaultOutboundAccess: false
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      createNetworkSecurityGroup: true
    }
    {
      name: 'app-subnet'
      addressPrefix: '10.0.2.0/24'
      defaultOutboundAccess: false
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      createNetworkSecurityGroup: true
    }
    {
      name: 'data-subnet'
      addressPrefix: '10.0.3.0/24'
      defaultOutboundAccess: false
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      createNetworkSecurityGroup: true
    }
  ]
}

// Tags comunes con estructura mejorada
var commonTags = {
  Environment: environment
  Project: projectName
  CreatedBy: 'bicep-template'
  CreatedDate: '2025-09-23'
  ManagedBy: 'Azure-Agent-Pro'
}

// Storage Account usando módulo (sin nombre explícito - Best Practice 2025)
module storageAccount './modules/storage-account.bicep' = {
  params: {
    storageAccountName: storageAccountName
    location: location
    sku: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
    tags: commonTags
  }
}

// Virtual Network usando módulo modernizado (sin nombre explícito)
module virtualNetwork './modules/virtual-network.bicep' = {
  params: {
    virtualNetworkName: networkConfiguration.virtualNetworkName
    location: location
    addressPrefixes: networkConfiguration.addressPrefixes
    subnets: networkConfiguration.subnets
    tags: commonTags
    enableDdosProtection: environment == 'prod' ? true : false
    enableVmProtection: environment == 'prod' ? true : false
    flowTimeoutInMinutes: 4
  }
}

// Key Vault usando módulo (sin nombre explícito)
module keyVault './modules/key-vault.bicep' = {
  params: {
    keyVaultName: keyVaultName
    location: location
    sku: environment == 'prod' ? 'premium' : 'standard'
    enablePurgeProtection: environment == 'prod' ? true : false
    tags: commonTags
  }
}

// Outputs principales
@description('Información de Storage Account')
output storageAccount object = {
  id: storageAccount.outputs.storageAccountId
  name: storageAccount.outputs.storageAccountName
  primaryBlobEndpoint: storageAccount.outputs.primaryBlobEndpoint
}

@description('Información de Virtual Network')
output virtualNetwork object = {
  id: virtualNetwork.outputs.virtualNetworkId
  name: virtualNetwork.outputs.virtualNetworkName
  addressSpace: virtualNetwork.outputs.addressSpace
  subnets: virtualNetwork.outputs.subnetIds
}

@description('Información de Key Vault')
output keyVault object = {
  id: keyVault.outputs.keyVaultId
  name: keyVault.outputs.keyVaultName
  uri: keyVault.outputs.keyVaultUri
}

@description('Sufijo único generado')
output uniqueSuffix string = uniqueSuffix