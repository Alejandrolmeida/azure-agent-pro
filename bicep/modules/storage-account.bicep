// Plantilla Bicep para crear una cuenta de Storage
// Archivo: storage-account.bicep

@description('Nombre de la cuenta de storage (debe ser único globalmente)')
param storageAccountName string

@description('Ubicación donde se creará la cuenta de storage')
param location string = resourceGroup().location

@description('SKU de la cuenta de storage')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param sku string = 'Standard_LRS'

@description('Tipo de cuenta de storage')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

@description('Nivel de acceso para la cuenta de storage')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Habilitar HTTPS únicamente')
param supportsHttpsTrafficOnly bool = true

@description('Versión mínima de TLS')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Tags para aplicar a los recursos')
param tags object = {
  Environment: 'dev'
  Project: 'azure-agent'
  CreatedBy: 'bicep-template'
}

// Recurso de Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  tags: tags
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    encryption: {
      requireInfrastructureEncryption: false
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
  }
}

// Contenedor de blob por defecto
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource defaultContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'default'
  properties: {
    publicAccess: 'None'
  }
}

// Outputs
@description('ID del recurso de Storage Account')
output storageAccountId string = storageAccount.id

@description('Nombre de la Storage Account')
output storageAccountName string = storageAccount.name

@description('Endpoint principal de blob')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Endpoint principal de file')
output primaryFileEndpoint string = storageAccount.properties.primaryEndpoints.file

@description('Key de acceso primaria')
output primaryAccessKey string = storageAccount.listKeys().keys[0].value