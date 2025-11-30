// ============================================================================
// Azure Storage Account Module
// ============================================================================
// Storage para cache de datos y logs de la aplicación
// ============================================================================

@description('Región de Azure')
param location string

@description('Nombre del Storage Account')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Tags para el recurso')
param tags object = {}

@description('SKU del Storage Account')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_RAGRS', 'Standard_ZRS', 'Premium_LRS'])
param sku string = 'Standard_LRS'

@description('Tipo de cuenta de almacenamiento')
@allowed(['BlobStorage', 'BlockBlobStorage', 'FileStorage', 'Storage', 'StorageV2'])
param kind string = 'StorageV2'

@description('Nivel de acceso por defecto')
@allowed(['Hot', 'Cool'])
param accessTier string = 'Hot'

@description('Habilitar HTTPS only')
param httpsOnly bool = true

@description('Versión mínima de TLS')
@allowed(['TLS1_0', 'TLS1_1', 'TLS1_2'])
param minimumTlsVersion string = 'TLS1_2'

@description('Permitir acceso público a blobs')
param allowBlobPublicAccess bool = false

@description('Habilitar versionado de blobs')
param enableBlobVersioning bool = false

@description('Habilitar delete retention')
param enableDeleteRetention bool = true

@description('Días de retención de blobs eliminados')
param deleteRetentionDays int = 7

@description('Contenedores a crear')
param containers array = []

@description('Tables de Azure Table Storage a crear')
param tables array = []

// ============================================================================
// STORAGE ACCOUNT
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: httpsOnly
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: allowBlobPublicAccess
    
    networkAcls: {
      defaultAction: 'Allow' // Para hackathon, en prod usar 'Deny' con reglas específicas
      bypass: 'AzureServices'
    }
    
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// ============================================================================
// BLOB SERVICE CONFIGURATION
// ============================================================================

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: enableDeleteRetention
      days: deleteRetentionDays
    }
    isVersioningEnabled: enableBlobVersioning
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'HEAD', 'POST', 'PUT']
          maxAgeInSeconds: 3600
          exposedHeaders: ['*']
          allowedHeaders: ['*']
        }
      ]
    }
  }
}

// ============================================================================
// BLOB CONTAINERS
// ============================================================================

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for container in containers: {
  parent: blobServices
  name: container.name
  properties: {
    publicAccess: contains(container, 'publicAccess') ? container.publicAccess : 'None'
  }
}]

// ============================================================================
// TABLE SERVICE
// ============================================================================

resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = if (length(tables) > 0) {
  parent: storageAccount
  name: 'default'
}

resource storageTables 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-01-01' = [for table in tables: if (length(tables) > 0) {
  parent: tableServices
  name: table
}]

// ============================================================================
// OUTPUTS
// ============================================================================

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
output primaryConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
output primaryKey string = storageAccount.listKeys().keys[0].value
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output tableEndpoint string = storageAccount.properties.primaryEndpoints.table
