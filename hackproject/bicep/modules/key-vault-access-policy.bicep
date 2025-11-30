// ============================================================================
// Key Vault Access Policy Module
// ============================================================================
// Añadir access policies adicionales a un Key Vault existente
// ============================================================================

@description('Nombre del Key Vault')
param keyVaultName string

@description('Object ID del principal (user, group, service principal, managed identity)')
param objectId string

@description('Tenant ID')
param tenantId string

@description('Permisos a otorgar')
param permissions object = {
  keys: []
  secrets: []
  certificates: []
}

// ============================================================================
// KEY VAULT (REFERENCIA)
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// ============================================================================
// ACCESS POLICY
// ============================================================================

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: objectId
        permissions: permissions
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output accessPolicyObjectId string = objectId
