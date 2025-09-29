// Modern Key Vault module for Azure Agent project
// Updated with 2025 best practices and latest API version

metadata author = 'Alejandro Almeida'
metadata version = '2.0.0'
metadata description = 'Creates a secure Key Vault with RBAC authorization and advanced security features'

// User-Defined Types for enhanced validation
@export()
type KeyVaultSkuType = 'standard' | 'premium'

@export()
type NetworkDefaultActionType = 'Allow' | 'Deny'

@export()
type PublicNetworkAccessType = 'enabled' | 'disabled'

// Parameters with modern decorators and security defaults
@description('Key Vault name - must be globally unique, 3-24 chars, alphanumeric and hyphens only')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Key Vault pricing tier - Premium provides HSM-backed keys')
param sku KeyVaultSkuType = 'premium'

@description('Azure AD tenant ID for authentication')
param tenantId string = subscription().tenantId

@description('Enable RBAC authorization for data plane operations (recommended)')
param enableRbacAuthorization bool = true

@description('Enable access for Azure Virtual Machines (certificate deployment)')
param enabledForDeployment bool = false

@description('Enable access for Azure Resource Manager template deployments')
param enabledForTemplateDeployment bool = true

@description('Enable access for Azure Disk Encryption scenarios')
param enabledForDiskEncryption bool = false

@description('Enable soft delete protection (default: true, cannot be disabled once enabled)')
param enableSoftDelete bool = true

@description('Soft delete retention period in days (7-90 days)')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection (irreversible, prevents permanent deletion)')
param enablePurgeProtection bool = true

@description('Public network access configuration')
param publicNetworkAccess PublicNetworkAccessType = 'disabled'

@description('Default action for network ACLs when public access is enabled')
param networkAclsDefaultAction NetworkDefaultActionType = 'Deny'

@description('Resource tags for organization and governance')
param tags object = {
  Environment: 'dev'
  Project: 'azure-agent'
  CreatedBy: 'bicep-template'
  Purpose: 'secure-secrets-management'
  Security: 'rbac-enabled'
}

// Key Vault resource with 2025 API version and RBAC authorization
resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sku
    }
    tenantId: tenantId

    // Enhanced security features
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    publicNetworkAccess: publicNetworkAccess

    // Service integration settings
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption

    // Network access controls
    networkAcls: {
      defaultAction: networkAclsDefaultAction
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }

    // Access policies (empty when RBAC is enabled - recommended approach)
    accessPolicies: []
  }
}

// Enhanced diagnostic settings for comprehensive monitoring
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${keyVaultName}'
  scope: keyVault
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90 // Extended retention for compliance
        }
      }
      {
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365 // Long-term audit retention
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Outputs with comprehensive information for downstream resources
@description('Key Vault resource ID for ARM template references')
output keyVaultId string = keyVault.id

@description('Key Vault name for application configuration')
output keyVaultName string = keyVault.name

@description('Key Vault URI for SDK and REST API access')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Azure AD tenant ID associated with this Key Vault')
output tenantId string = keyVault.properties.tenantId

@description('Key Vault location for regional compliance requirements')
output location string = keyVault.location

@description('Key Vault SKU tier for cost tracking and feature availability')
output sku string = keyVault.properties.sku.name

@description('RBAC authorization status - true indicates modern security model')
output rbacAuthorizationEnabled bool = keyVault.properties.enableRbacAuthorization

@description('Soft delete protection status')
output softDeleteEnabled bool = keyVault.properties.enableSoftDelete

@description('Purge protection status (irreversible security feature)')
output purgeProtectionEnabled bool = keyVault.properties.enablePurgeProtection

// Security note: Access to Key Vault should be managed through Azure RBAC roles:
// - Key Vault Administrator: Full access to keys, secrets, and certificates
// - Key Vault Secrets Officer: Manage secrets (excluding keys and certificates)
// - Key Vault Secrets User: Read secret contents
// - Key Vault Crypto Officer: Manage keys (excluding certificates and secrets)
// - Key Vault Crypto User: Perform cryptographic operations with keys
