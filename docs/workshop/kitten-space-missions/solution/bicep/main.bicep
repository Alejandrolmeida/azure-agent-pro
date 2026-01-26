targetScope = 'subscription'

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Azure region for all resources')
param location string = 'westeurope'

@description('Project name used for resource naming')
@minLength(3)
@maxLength(15)
param projectName string = 'kitten-missions'

@description('SQL Database SKU')
@allowed(['Basic', 'S0', 'S1', 'P1'])
param sqlDatabaseSku string = 'Basic'

@description('App Service Plan SKU')
@allowed(['B1', 'B2', 'S1', 'P1v2'])
param appServicePlanSku string = 'B1'

@description('Enable Private Endpoint for SQL Database')
param enablePrivateEndpoint bool = true

@description('Resource tags for cost allocation and management')
param tags object = {
  Environment: environment
  Project: 'KittenSpaceMissions'
  ManagedBy: 'Bicep'
  CostCenter: 'Engineering'
}

@description('SQL Administrator Username')
param sqlAdminUsername string = 'sqladmin'

@description('SQL Administrator Password')
@secure()
param sqlAdminPassword string

// Variables
var resourceGroupName = 'rg-${projectName}-${environment}'
var uniqueSuffix = uniqueString(subscription().subscriptionId, resourceGroupName)

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Networking Module
module networking 'modules/networking.bicep' = {
  scope: rg
  name: 'networking-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
  }
}

// Monitoring Module (must be deployed before other resources for diagnostic settings)
module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  name: 'monitoring-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
  }
}

// Key Vault Module
module keyVault 'modules/key-vault.bicep' = {
  scope: rg
  name: 'keyvault-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    uniqueSuffix: uniqueSuffix
    tags: tags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// SQL Database Module
module sqlDatabase 'modules/sql-database.bicep' = {
  scope: rg
  name: 'sqldatabase-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    sqlDatabaseSku: sqlDatabaseSku
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword
    tags: tags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// Private Endpoint for SQL Database (if enabled)
module sqlPrivateEndpoint 'modules/private-endpoint.bicep' = if (enablePrivateEndpoint) {
  scope: rg
  name: 'sql-privateendpoint-deployment'
  params: {
    location: location
    privateEndpointName: 'pe-${projectName}-sql-${environment}'
    privateLinkServiceId: sqlDatabase.outputs.sqlServerId
    groupId: 'sqlServer'
    subnetId: networking.outputs.privateEndpointSubnetId
    privateDnsZoneName: 'privatelink${az.environment().suffixes.sqlServerHostname}'
    tags: tags
  }
}

// App Service Module
module appService 'modules/app-service.bicep' = {
  scope: rg
  name: 'appservice-deployment'
  params: {
    location: location
    projectName: projectName
    environment: environment
    appServicePlanSku: appServicePlanSku
    subnetId: networking.outputs.appServiceSubnetId
    keyVaultName: keyVault.outputs.keyVaultName
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    applicationInsightsInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
    tags: tags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// Store SQL Connection String in Key Vault
module sqlConnectionStringSecret 'modules/key-vault-secret.bicep' = {
  scope: rg
  name: 'sql-connectionstring-secret'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'SqlConnectionString'
    secretValue: 'Server=tcp:${sqlDatabase.outputs.sqlServerFqdn},1433;Initial Catalog=${sqlDatabase.outputs.sqlDatabaseName};Authentication=Active Directory Managed Identity;'
  }
}

// RBAC Assignments
module rbac 'modules/rbac.bicep' = {
  scope: rg
  name: 'rbac-deployment'
  params: {
    appServicePrincipalId: appService.outputs.appServicePrincipalId
    keyVaultName: keyVault.outputs.keyVaultName
    sqlServerId: sqlDatabase.outputs.sqlServerId
  }
}

// Outputs
output resourceGroupName string = rg.name
output appServiceUrl string = appService.outputs.appServiceDefaultHostName
output appServiceName string = appService.outputs.appServiceName
output sqlServerFqdn string = sqlDatabase.outputs.sqlServerFqdn
output sqlDatabaseName string = sqlDatabase.outputs.sqlDatabaseName
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName
output vnetId string = networking.outputs.vnetId
