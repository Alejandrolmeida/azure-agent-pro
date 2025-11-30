// ============================================================================
// Azure Functions Module
// ============================================================================
// Backend APIs para BiciMAD Low Emission Router (Python 3.11)
// ============================================================================

@description('Región de Azure')
param location string

@description('Nombre del Function App')
param functionAppName string

@description('Nombre del App Service Plan')
param appServicePlanName string

@description('Nombre del Storage Account asociado')
param storageAccountName string

@description('Instrumentation Key de Application Insights')
param appInsightsInstrumentationKey string = ''

@description('Connection String de Application Insights')
param appInsightsConnectionString string = ''

@description('Nombre del Key Vault para referencias de secretos')
param keyVaultName string

@description('Tags para los recursos')
param tags object = {}

@description('Runtime de la Function App')
@allowed(['python', 'node', 'dotnet'])
param runtime string = 'python'

@description('Versión del runtime')
param runtimeVersion string = '3.11'

@description('SKU del App Service Plan')
param functionAppPlanSku object = {
  name: 'Y1' // Consumption plan
  tier: 'Dynamic'
}

@description('Habilitar Managed Identity')
param enableManagedIdentity bool = true

@description('Configuración CORS')
param corsAllowedOrigins array = ['*']

@description('Habilitar Always On (no disponible en Consumption)')
param alwaysOn bool = false

// ============================================================================
// STORAGE ACCOUNT (REFERENCIA)
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// ============================================================================
// APP SERVICE PLAN
// ============================================================================

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: functionAppPlanSku
  kind: 'functionapp'
  properties: {
    reserved: true // Required for Linux
  }
}

// ============================================================================
// FUNCTION APP
// ============================================================================

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  tags: union(tags, {
    'azd-service-name': 'api'
  })
  kind: 'functionapp,linux'
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true // Linux
    httpsOnly: true
    
    siteConfig: {
      linuxFxVersion: '${toUpper(runtime)}|${runtimeVersion}'
      
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        // Key Vault reference para Azure Maps API key
        {
          name: 'AZURE_MAPS_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=azure-maps-api-key)'
        }
        {
          name: 'STORAGE_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=storage-connection-string)'
        }
        // Python specific settings
        {
          name: 'PYTHON_ISOLATE_WORKER_DEPENDENCIES'
          value: '1'
        }
        {
          name: 'PYTHON_ENABLE_WORKER_EXTENSIONS'
          value: '1'
        }
        // Custom app settings
        {
          name: 'BICIMAD_API_URL'
          value: 'https://opendata.emtmadrid.es/getdatasets'
        }
        {
          name: 'AIR_QUALITY_API_URL'
          value: 'https://datos.madrid.es/egob/catalogo/'
        }
        {
          name: 'CACHE_TTL_MINUTES'
          value: '20'
        }
      ]
      
      cors: {
        allowedOrigins: corsAllowedOrigins
        supportCredentials: false
      }
      
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      alwaysOn: alwaysOn
      
      // Health check
      healthCheckPath: '/api/health'
    }
  }
}

// ============================================================================
// DIAGNOSTIC SETTINGS
// ============================================================================

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(appInsightsInstrumentationKey)) {
  name: '${functionApp.name}-diagnostics'
  scope: functionApp
  properties: {
    logs: [
      {
        category: 'FunctionAppLogs'
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

// ============================================================================
// OUTPUTS
// ============================================================================

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output functionAppHostname string = functionApp.properties.defaultHostName
output functionAppPrincipalId string = enableManagedIdentity ? functionApp.identity.principalId : ''
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output appServicePlanId string = appServicePlan.id
