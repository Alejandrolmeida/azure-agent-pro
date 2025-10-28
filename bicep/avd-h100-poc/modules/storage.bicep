// ============================================================================
// Storage Account Module
// ============================================================================
// Storage Account para transferencia de archivos pesados
// Performance: Standard (LRS para optimizar costos)
// Tag: workload-type=infrastructure
// Costo estimado: €2/mes (100GB) + €3/mes (egress)
// ============================================================================

@description('Región de Azure')
param location string

@description('Prefijo para recursos')
param resourcePrefix string

@description('Tags del recurso')
param tags object

// ============================================================================
// VARIABLES
// ============================================================================

// Nombre único global para Storage Account (sin guiones, máx 24 chars)
var storageAccountName = toLower(replace('st${resourcePrefix}transfer', '-', ''))
var containerName = 'file-uploads'
var resultsContainerName = 'results'

// ============================================================================
// STORAGE ACCOUNT
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS' // Local Redundant Storage para optimizar costos
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot' // Hot tier para acceso frecuente
    allowBlobPublicAccess: false // Seguridad: sin acceso público
    allowSharedKeyAccess: true // Permitir acceso con SAS tokens
    supportsHttpsTrafficOnly: true // Solo HTTPS
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow' // Permitir acceso desde cualquier red (usar SAS para control)
      virtualNetworkRules: []
      ipRules: []
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
// BLOB SERVICE
// ============================================================================

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7 // Retener archivos borrados 7 días
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
  }
}

// ============================================================================
// BLOB CONTAINERS
// ============================================================================

// Container para subida de archivos
resource uploadContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'File uploads from local workstation to AVD VM'
      maxSize: '100GB'
    }
  }
}

// Container para resultados procesados
resource resultsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: resultsContainerName
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Processed results from Pix4Dmatic'
      retention: '30 days'
    }
  }
}

// ============================================================================
// LIFECYCLE MANAGEMENT (Opcional - Ahorro de costos)
// ============================================================================

resource managementPolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'DeleteOldResults'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: 30 // Borrar archivos > 30 días
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                '${resultsContainerName}/'
              ]
            }
          }
        }
        {
          enabled: true
          name: 'MoveToArchive'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToArchive: {
                  daysAfterModificationGreaterThan: 7 // Archivar después de 7 días
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                '${uploadContainer.name}/'
              ]
            }
          }
        }
      ]
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output containerName string = containerName
output resultsContainerName string = resultsContainerName
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
