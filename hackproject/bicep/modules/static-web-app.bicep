// ============================================================================
// Azure Static Web Apps Module
// ============================================================================
// Hosting para frontend de la aplicación BiciMAD Low Emission Router
// ============================================================================

@description('Región de Azure para el recurso')
param location string

@description('Nombre del Static Web App')
param staticWebAppName string

@description('Tags para el recurso')
param tags object = {}

@description('SKU del Static Web App')
@allowed(['Free', 'Standard'])
param sku string = 'Free'

@description('URL del repositorio de GitHub')
param repositoryUrl string = ''

@description('Rama del repositorio')
param branch string = 'main'

@description('Ubicación del código de la app dentro del repo')
param appLocation string = '/'

@description('Ubicación de la API dentro del repo (vacío si API separada)')
param apiLocation string = ''

@description('Ubicación de los archivos de salida del build')
param outputLocation string = ''

@description('Token de GitHub para deployments (si se usa)')
@secure()
param repositoryToken string = ''

// ============================================================================
// AZURE STATIC WEB APP
// ============================================================================

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: staticWebAppName
  location: location
  tags: union(tags, {
    'azd-service-name': 'frontend'
  })
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    buildProperties: {
      appLocation: appLocation
      apiLocation: apiLocation
      outputLocation: outputLocation
    }
    repositoryToken: !empty(repositoryToken) ? repositoryToken : null
    // Configuración de staging environments
    stagingEnvironmentPolicy: sku == 'Standard' ? 'Enabled' : 'Disabled'
    allowConfigFileUpdates: true
    // Provider de autenticación (GitHub por defecto)
    provider: !empty(repositoryUrl) ? 'GitHub' : 'None'
  }
}

// ============================================================================
// CONFIGURACIÓN ADICIONAL
// ============================================================================

// Custom domain (opcional, configurar después del deploy inicial)
// resource customDomain 'Microsoft.Web/staticSites/customDomains@2023-01-01' = {
//   parent: staticWebApp
//   name: 'custom-domain-example-com'
//   properties: {}
// }

// ============================================================================
// OUTPUTS
// ============================================================================

output staticWebAppId string = staticWebApp.id
output staticWebAppName string = staticWebApp.name
output staticWebAppDefaultHostname string = staticWebApp.properties.defaultHostname
output staticWebAppRepositoryUrl string = staticWebApp.properties.repositoryUrl
output staticWebAppBranch string = staticWebApp.properties.branch

// API key para GitHub Actions deployment
output staticWebAppApiKey string = staticWebApp.listSecrets().properties.apiKey
