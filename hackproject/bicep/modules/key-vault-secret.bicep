// ============================================================================
// Key Vault Secret Module
// ============================================================================
// Almacenar secretos en Key Vault
// ============================================================================

@description('Nombre del Key Vault')
param keyVaultName string

@description('Nombre del secreto')
param secretName string

@description('Valor del secreto')
@secure()
param secretValue string

@description('Content type del secreto')
param contentType string = ''

@description('Tags para el secreto')
param tags object = {}

// ============================================================================
// KEY VAULT (REFERENCIA)
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// ============================================================================
// SECRET
// ============================================================================

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: secretName
  tags: tags
  properties: {
    value: secretValue
    contentType: !empty(contentType) ? contentType : null
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output secretId string = secret.id
output secretName string = secret.name
output secretUri string = secret.properties.secretUri
