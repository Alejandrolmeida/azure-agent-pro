// ============================================================================
// Application Insights + Log Analytics Module
// ============================================================================
// Monitoring y observabilidad para la aplicación
// ============================================================================

@description('Región de Azure')
param location string

@description('Nombre del Log Analytics Workspace')
param logAnalyticsName string

@description('Nombre de Application Insights')
param appInsightsName string

@description('Tags para los recursos')
param tags object = {}

@description('SKU del Log Analytics Workspace')
@allowed(['PerGB2018', 'Free', 'Standalone', 'PerNode', 'Standard', 'Premium'])
param logAnalyticsSku string = 'PerGB2018'

@description('Periodo de retención de datos en días')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Tipo de aplicación')
@allowed(['web', 'other'])
param applicationType string = 'web'

@description('Modo de ingesta')
@allowed(['ApplicationInsights', 'ApplicationInsightsWithDiagnosticSettings', 'LogAnalytics'])
param ingestionMode string = 'LogAnalytics'

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1 // Límite de 1GB/día para control de costos en hackathon
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// APPLICATION INSIGHTS
// ============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: applicationType
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: ingestionMode
    RetentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    // Sampling para reducir costos (50% en prod, 100% en dev)
    SamplingPercentage: 100
  }
}

// ============================================================================
// ALERT RULES (Opcional para producción)
// ============================================================================

// Alert: Function App con alta tasa de errores
resource functionErrorRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appInsightsName}-high-error-rate'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert cuando la tasa de errores supera el 5%'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M' // Cada 5 minutos
    windowSize: 'PT15M' // Ventana de 15 minutos
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'High error rate'
          metricName: 'exceptions/server'
          metricNamespace: 'microsoft.insights/components'
          operator: 'GreaterThan'
          threshold: 10
          timeAggregation: 'Count'
        }
      ]
    }
    autoMitigate: true
  }
}

// Alert: Disponibilidad baja
resource availabilityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appInsightsName}-low-availability'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert cuando la disponibilidad cae por debajo del 95%'
    severity: 1
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Low availability'
          metricName: 'availabilityResults/availabilityPercentage'
          metricNamespace: 'microsoft.insights/components'
          operator: 'LessThan'
          threshold: 95
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
output logAnalyticsCustomerId string = logAnalytics.properties.customerId

output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsAppId string = appInsights.properties.AppId
