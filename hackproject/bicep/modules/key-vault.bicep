// ============================================================================
// Azure Key Vault Module
// ============================================================================
// Gestión segura de secretos, keys y certificados
// ============================================================================

@description('Región de Azure')
param location string

@description('Nombre del Key Vault')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Tags para el recurso')
param tags object = {}

@description('Azure AD Tenant ID')
param tenantId string

@description('SKU del Key Vault')
@allowed(['standard', 'premium'])
param sku string = 'standard'

@description('Habilitar para VM deployments')
param enabledForDeployment bool = false

@description('Habilitar para disk encryption')
param enabledForDiskEncryption bool = false

@description('Habilitar para template deployments')
param enabledForTemplateDeployment bool = true

@description('Habilitar soft delete')
param enableSoftDelete bool = true

@description('Días de retención para soft delete')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 7

@description('Habilitar purge protection')
param enablePurgeProtection bool = false

@description('Access policies iniciales')
param accessPolicies array = []

@description('ID del workspace de Log Analytics para diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Habilitar acceso público a red')
param publicNetworkAccess bool = true

// ============================================================================
// KEY VAULT
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: sku
    }
    
    // Access policies
    accessPolicies: accessPolicies
    
    // RBAC vs Access Policies (usar access policies para hackathon)
    enableRbacAuthorization: false
    
    // Soft delete configuration
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    
    // Deployment flags
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    
    // Network configuration
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
    networkAcls: {
      defaultAction: 'Allow' // Para hackathon, en prod usar 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// ============================================================================
// DIAGNOSTIC SETTINGS
// ============================================================================

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${keyVault.name}-diagnostics'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
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

// ============================================================================
// OUTPUTS
// ============================================================================

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
