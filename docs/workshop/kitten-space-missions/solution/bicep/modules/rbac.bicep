@description('Principal ID of the App Service Managed Identity')
param appServicePrincipalId string

@description('Key Vault name')
param keyVaultName string

@description('SQL Server resource ID')
param sqlServerId string

// Built-in Role Definitions
// Key Vault Secrets User: 4633458b-17de-408a-b874-0445c86b69e6
// SQL DB Contributor: 9b7fa17d-e63e-47b0-bb0a-15c516ac86ec

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'
var sqlDbContributorRoleId = '9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'

// Reference existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Reference existing SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' existing = {
  name: split(sqlServerId, '/')[8]
}

// RBAC: App Service → Key Vault (Secrets User)
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appServicePrincipalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: App Service → SQL Server (SQL DB Contributor)
resource sqlRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sqlServerId, appServicePrincipalId, sqlDbContributorRoleId)
  scope: sqlServer
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', sqlDbContributorRoleId)
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output keyVaultRoleAssignmentId string = keyVaultRoleAssignment.id
output sqlRoleAssignmentId string = sqlRoleAssignment.id
