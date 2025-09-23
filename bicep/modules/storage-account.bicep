// Modern Storage Account module for Azure Agent project
// Updated with 2025 best practices and latest API version

metadata author = 'Alejandro Almeida'
metadata version = '2.0.0'
metadata description = 'Creates a secure Storage Account with modern configuration'

// User-Defined Types for enhanced validation
@export()
type StorageSkuType = 'Standard_LRS' | 'Standard_GRS' | 'Standard_RAGRS' | 'Standard_ZRS' | 'Premium_LRS' | 'Premium_ZRS' | 'Standard_GZRS' | 'Standard_RAGZRS' | 'StandardV2_LRS' | 'StandardV2_GRS' | 'StandardV2_ZRS' | 'StandardV2_GZRS' | 'PremiumV2_LRS' | 'PremiumV2_ZRS'

@export()
type StorageKindType = 'Storage' | 'StorageV2' | 'BlobStorage' | 'FileStorage' | 'BlockBlobStorage'

@export()
type AccessTierType = 'Hot' | 'Cool' | 'Cold' | 'Premium'

@export()
type TlsVersionType = 'TLS1_0' | 'TLS1_1' | 'TLS1_2' | 'TLS1_3'

@export()
type PublicNetworkAccessType = 'Enabled' | 'Disabled' | 'SecuredByPerimeter'

// Parameters with modern decorators
@description('Storage account name - must be globally unique, 3-24 chars, lowercase and numbers only')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Storage account performance tier and replication type')
param sku StorageSkuType = 'Standard_LRS'

@description('Storage account type optimized for specific workloads')
param kind StorageKindType = 'StorageV2'

@description('Default access tier for blob data (billing optimization)')
param accessTier AccessTierType = 'Hot'

@description('Enforce secure transfer (HTTPS-only)')
param supportsHttpsTrafficOnly bool = true

@description('Minimum TLS version for secure connections')
param minimumTlsVersion TlsVersionType = 'TLS1_3'

@description('Public network access configuration')
param publicNetworkAccess PublicNetworkAccessType = 'Disabled'

@description('Allow blob public access for containers')
param allowBlobPublicAccess bool = false

@description('Allow shared key access (disable for enhanced security)')
param allowSharedKeyAccess bool = false

@description('Default to OAuth authentication over shared key')
param defaultToOAuthAuthentication bool = true

@description('Enable hierarchical namespace for Data Lake capabilities')
param isHnsEnabled bool = false

@description('Resource tags for organization and governance')
param tags object = {
  Environment: 'dev'
  Project: 'azure-agent'
  CreatedBy: 'bicep-template'
  Purpose: 'learning'
}

// Storage Account resource with 2025 API version and enhanced security
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  kind: kind
  sku: {
    name: sku
  }
  tags: tags
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    isHnsEnabled: isHnsEnabled
    allowCrossTenantReplication: false
    
    // Enhanced network security
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: []
    }
    
    // Advanced encryption configuration
    encryption: {
      requireInfrastructureEncryption: true
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
    
    // SAS token security policy
    sasPolicy: {
      sasExpirationPeriod: '00.01:00:00' // 1 hour max
      expirationAction: 'Block'
    }
  }
}

// Blob service with modern security and retention policies
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 30 // Extended retention for better data protection
      allowPermanentDelete: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    changeFeed: {
      enabled: true
      retentionInDays: 30
    }
    isVersioningEnabled: true
    lastAccessTimeTrackingPolicy: {
      enable: true
      name: 'AccessTimeTracking'
      trackingGranularityInDays: 1
    }
  }
}

// Secure container with private access only
resource defaultContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: blobService
  name: 'secure-data'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'secure-storage'
      project: 'azure-agent'
    }
    immutableStorageWithVersioning: {
      enabled: false
    }
  }
}

// Outputs with enhanced typing and comprehensive information
@description('Storage Account resource ID for reference in other resources')
output storageAccountId string = storageAccount.id

@description('Storage Account name for connection strings and references')
output storageAccountName string = storageAccount.name

@description('Primary blob storage endpoint for application configuration')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Primary file storage endpoint for SMB/NFS access')
output primaryFileEndpoint string = storageAccount.properties.primaryEndpoints.file

@description('Primary queue storage endpoint for messaging scenarios')
output primaryQueueEndpoint string = storageAccount.properties.primaryEndpoints.queue

@description('Primary table storage endpoint for NoSQL data')
output primaryTableEndpoint string = storageAccount.properties.primaryEndpoints.table

@description('Primary web endpoint for static website hosting')
output primaryWebEndpoint string = storageAccount.properties.primaryEndpoints.web

@description('Primary DFS endpoint for Data Lake operations')
output primaryDfsEndpoint string = storageAccount.properties.primaryEndpoints.dfs

@description('Storage Account resource location')
output location string = storageAccount.location

@description('Storage Account SKU for monitoring and billing')
output sku string = storageAccount.sku.name

@description('Storage Account provisioning state')
output provisioningState string = storageAccount.properties.provisioningState

// Note: Access keys should be retrieved using Azure CLI, PowerShell, or Key Vault integration
// Command: az storage account keys list --resource-group <rg-name> --account-name <storage-name>
// Security: Consider using managed identities instead of access keys for authentication
