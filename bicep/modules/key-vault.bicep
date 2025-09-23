// Módulo Bicep para crear un Key Vault
// Archivo: key-vault.bicep

@description('Nombre del Key Vault (debe ser único globalmente)')
param keyVaultName string

@description('Ubicación donde se creará el Key Vault')
param location string = resourceGroup().location

@description('SKU del Key Vault')
@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'

@description('ID del tenant de Azure AD')
param tenantId string = subscription().tenantId

@description('Habilitar el acceso desde Azure Virtual Machines')
param enabledForDeployment bool = false

@description('Habilitar el acceso desde Azure Resource Manager para deployments de plantillas')
param enabledForTemplateDeployment bool = true

@description('Habilitar el acceso desde Azure Disk Encryption')
param enabledForDiskEncryption bool = false

@description('Habilitar el soft delete')
param enableSoftDelete bool = true

@description('Días de retención para soft delete')
param softDeleteRetentionInDays int = 90

@description('Habilitar purge protection')
param enablePurgeProtection bool = true

@description('Configuración de acceso a la red')
@allowed([
  'Allow'
  'Deny'
])
param networkAclsDefaultAction string = 'Allow'

@description('Tags para aplicar a los recursos')
param tags object = {
  Environment: 'dev'
  Project: 'azure-agent'
  CreatedBy: 'bicep-template'
}

@description('Políticas de acceso para usuarios/aplicaciones')
param accessPolicies array = []

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sku
    }
    tenantId: tenantId
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    networkAcls: {
      defaultAction: networkAclsDefaultAction
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: accessPolicies
  }
}

// Secrets de ejemplo (comentados por seguridad)
/*
resource exampleSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'example-secret'
  properties: {
    value: 'example-secret-value'
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}
*/

// Diagnostic Settings para logging
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${keyVaultName}'
  scope: keyVault
  properties: {
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Outputs
@description('ID del recurso de Key Vault')
output keyVaultId string = keyVault.id

@description('Nombre del Key Vault')
output keyVaultName string = keyVault.name

@description('URI del Key Vault')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Tenant ID del Key Vault')
output tenantId string = keyVault.properties.tenantId