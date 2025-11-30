// ============================================================================
// BiciMAD Low Emission Router - Main Infrastructure Orchestrator
// ============================================================================
// Hackathon: DataSaturday Madrid 2025
// Proyecto: Sistema de routing inteligente para ciclistas que minimiza
//           exposición a contaminación atmosférica
// ============================================================================

targetScope = 'subscription'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Nombre del proyecto (usado como prefijo para recursos)')
param projectName string = 'bicimad'

@description('Entorno de despliegue')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Región principal de Azure')
param location string = 'westeurope'

@description('Tags comunes para todos los recursos')
param tags object = {
  Project: 'BiciMAD-Low-Emission-Router'
  Environment: environment
  Hackathon: 'DataSaturday-Madrid-2025'
  ManagedBy: 'Bicep-IaC'
  CostCenter: 'Hackathon'
  DeployedBy: 'GitHub-Actions'
}

@description('ID del tenant de Azure AD')
param tenantId string = subscription().tenantId

@description('ID de objeto del usuario/service principal para acceso a Key Vault')
param keyVaultAdminObjectId string

@description('API key de Azure Maps (se almacenará en Key Vault)')
@secure()
param azureMapsApiKey string = ''

@description('Habilitar Application Insights')
param enableMonitoring bool = true

@description('Periodo de retención de logs en días')
param logRetentionDays int = environment == 'prod' ? 90 : 30

// ============================================================================
// VARIABLES
// ============================================================================

var resourceGroupName = 'rg-${projectName}-${environment}-${location}'
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroupName), 0, 6)

// Naming convention
var naming = {
  resourceGroup: resourceGroupName
  logAnalytics: 'log-${projectName}-${environment}-${uniqueSuffix}'
  appInsights: 'appi-${projectName}-${environment}-${uniqueSuffix}'
  storage: 'st${projectName}${environment}${uniqueSuffix}'
  keyVault: 'kv-${projectName}-${environment}-${uniqueSuffix}'
  functionApp: 'func-${projectName}-${environment}-${uniqueSuffix}'
  appServicePlan: 'asp-${projectName}-${environment}-${uniqueSuffix}'
  staticWebApp: 'stapp-${projectName}-${environment}-${uniqueSuffix}'
  azureMaps: 'map-${projectName}-${environment}-${uniqueSuffix}'
}

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: naming.resourceGroup
  location: location
  tags: tags
}

// ============================================================================
// MODULE: MONITORING (Application Insights + Log Analytics)
// ============================================================================

module monitoring './modules/app-insights.bicep' = if (enableMonitoring) {
  name: 'deploy-monitoring'
  scope: resourceGroup
  params: {
    location: location
    logAnalyticsName: naming.logAnalytics
    appInsightsName: naming.appInsights
    retentionInDays: logRetentionDays
    tags: tags
  }
}

// ============================================================================
// MODULE: STORAGE ACCOUNT (Cache + Logs)
// ============================================================================

module storage './modules/storage-account.bicep' = {
  name: 'deploy-storage'
  scope: resourceGroup
  params: {
    location: location
    storageAccountName: naming.storage
    tags: tags
    containers: [
      {
        name: 'cache'
        publicAccess: 'None'
      }
      {
        name: 'air-quality-data'
        publicAccess: 'None'
      }
      {
        name: 'bicimad-data'
        publicAccess: 'None'
      }
    ]
    enableBlobVersioning: false
    enableDeleteRetention: environment == 'prod' ? true : false
    deleteRetentionDays: 7
  }
}

// ============================================================================
// MODULE: KEY VAULT (Secretos y API Keys)
// ============================================================================

module keyVault './modules/key-vault.bicep' = {
  name: 'deploy-keyvault'
  scope: resourceGroup
  params: {
    location: location
    keyVaultName: naming.keyVault
    tenantId: tenantId
    tags: tags
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: environment == 'prod' ? true : false
    logAnalyticsWorkspaceId: enableMonitoring ? monitoring.outputs.logAnalyticsWorkspaceId : ''
    // Access policy para el admin
    accessPolicies: [
      {
        objectId: keyVaultAdminObjectId
        tenantId: tenantId
        permissions: {
          keys: ['get', 'list', 'create', 'update']
          secrets: ['get', 'list', 'set', 'delete']
          certificates: ['get', 'list', 'create']
        }
      }
    ]
  }
}

// ============================================================================
// MODULE: AZURE MAPS
// ============================================================================

module azureMaps './modules/azure-maps.bicep' = {
  name: 'deploy-azure-maps'
  scope: resourceGroup
  params: {
    location: location
    mapsAccountName: naming.azureMaps
    tags: tags
    sku: 'G2' // Gen2 pricing tier
  }
}

// ============================================================================
// MODULE: AZURE FUNCTIONS (Backend APIs)
// ============================================================================

module functionApp './modules/function-app.bicep' = {
  name: 'deploy-function-app'
  scope: resourceGroup
  params: {
    location: location
    functionAppName: naming.functionApp
    appServicePlanName: naming.appServicePlan
    storageAccountName: storage.outputs.storageAccountName
    appInsightsInstrumentationKey: enableMonitoring ? monitoring.outputs.appInsightsInstrumentationKey : ''
    appInsightsConnectionString: enableMonitoring ? monitoring.outputs.appInsightsConnectionString : ''
    keyVaultName: keyVault.outputs.keyVaultName
    tags: tags
    runtime: 'python'
    runtimeVersion: '3.11'
    // Consumption plan para hackathon (cost-effective)
    functionAppPlanSku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
    enableManagedIdentity: true
  }
}

// ============================================================================
// MODULE: AZURE STATIC WEB APPS (Frontend)
// ============================================================================

module staticWebApp './modules/static-web-app.bicep' = {
  name: 'deploy-static-web-app'
  scope: resourceGroup
  params: {
    location: location
    staticWebAppName: naming.staticWebApp
    tags: tags
    sku: 'Free'
    repositoryUrl: '' // Se configurará via GitHub Actions
    branch: 'datahack4good'
    appLocation: 'hackproject/src/frontend'
    apiLocation: '' // API via Azure Functions separada
    outputLocation: ''
  }
}

// ============================================================================
// RBAC: Function App Managed Identity -> Key Vault Access
// ============================================================================

module functionAppKeyVaultAccess './modules/key-vault-access-policy.bicep' = {
  name: 'deploy-function-keyvault-access'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    objectId: functionApp.outputs.functionAppPrincipalId
    tenantId: tenantId
    permissions: {
      secrets: ['get', 'list']
    }
  }
  dependsOn: [
    functionApp
    keyVault
  ]
}

// ============================================================================
// RBAC: Function App Managed Identity -> Storage Account Access
// ============================================================================

resource storageAccountBlobDataContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // Storage Blob Data Contributor role
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource functionAppStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup.id, functionApp.outputs.functionAppPrincipalId, storageAccountBlobDataContributor.id)
  scope: resourceGroup
  properties: {
    roleDefinitionId: storageAccountBlobDataContributor.id
    principalId: functionApp.outputs.functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// SECRETS: Almacenar API Keys en Key Vault
// ============================================================================

module secretAzureMapsKey 'modules/key-vault-secret.bicep' = if (!empty(azureMapsApiKey)) {
  name: 'deploy-secret-azure-maps-key'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'azure-maps-api-key'
    secretValue: !empty(azureMapsApiKey) ? azureMapsApiKey : azureMaps.outputs.primaryKey
  }
  dependsOn: [
    keyVault
    azureMaps
  ]
}

module secretStorageConnectionString 'modules/key-vault-secret.bicep' = {
  name: 'deploy-secret-storage-connection'
  scope: resourceGroup
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: 'storage-connection-string'
    secretValue: storage.outputs.primaryConnectionString
  }
  dependsOn: [
    keyVault
    storage
  ]
}

// ============================================================================
// OUTPUTS
// ============================================================================

output resourceGroupName string = resourceGroup.name
output location string = location
output environment string = environment

// Storage outputs
output storageAccountName string = storage.outputs.storageAccountName
output storageAccountId string = storage.outputs.storageAccountId

// Key Vault outputs
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri

// Function App outputs
output functionAppName string = functionApp.outputs.functionAppName
output functionAppHostname string = functionApp.outputs.functionAppHostname
output functionAppPrincipalId string = functionApp.outputs.functionAppPrincipalId

// Static Web App outputs
output staticWebAppName string = staticWebApp.outputs.staticWebAppName
output staticWebAppHostname string = staticWebApp.outputs.staticWebAppDefaultHostname

// Azure Maps outputs
output azureMapsAccountName string = azureMaps.outputs.mapsAccountName
output azureMapsAccountId string = azureMaps.outputs.mapsAccountId

// Monitoring outputs
output logAnalyticsWorkspaceId string = enableMonitoring ? monitoring.outputs.logAnalyticsWorkspaceId : ''
output appInsightsInstrumentationKey string = enableMonitoring ? monitoring.outputs.appInsightsInstrumentationKey : ''
output appInsightsConnectionString string = enableMonitoring ? monitoring.outputs.appInsightsConnectionString : ''

// Deployment metadata
output deploymentTimestamp string = utcNow('yyyy-MM-dd HH:mm:ss')
output deployedBy string = 'Bicep IaC'
output projectName string = projectName
output tags object = tags
