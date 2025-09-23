// Plantilla principal que utiliza múltiples módulos
// Archivo: main.bicep

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

// Variables
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 5)
var storageAccountName = '${resourcePrefix}st${uniqueSuffix}'
var keyVaultName = '${resourcePrefix}-kv-${uniqueSuffix}'
var vnetName = '${resourcePrefix}-vnet'

var commonTags = {
  Environment: environment
  Project: projectName
  CreatedBy: 'bicep-template'
  CreatedDate: utcNow('yyyy-MM-dd')
}

// Storage Account usando módulo
module storageAccount './modules/storage-account.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    sku: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
    tags: commonTags
  }
}

// Virtual Network usando módulo
module virtualNetwork './modules/virtual-network.bicep' = {
  name: 'virtualNetworkDeployment'
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: '10.0.0.0/16'
    subnets: [
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
    tags: commonTags
  }
}

// Key Vault usando módulo
module keyVault './modules/key-vault.bicep' = {
  name: 'keyVaultDeployment'
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