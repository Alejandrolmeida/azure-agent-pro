@description('Key Vault name')
param keyVaultName string

@description('Secret name')
param secretName string

@description('Secret value')
@secure()
param secretValue string

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Create Secret
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: secretName
  properties: {
    value: secretValue
    contentType: 'text/plain'
  }
}

// Outputs
output secretUri string = secret.properties.secretUri
output secretName string = secret.name
