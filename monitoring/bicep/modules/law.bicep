// Log Analytics Workspace with AVD Insights
// Provides centralized logging and monitoring for Azure Virtual Desktop

@description('Name of the Log Analytics Workspace')
param lawName string

@description('Azure region for the resource')
param location string = resourceGroup().location

@description('Pricing tier for Log Analytics')
@allowed([
  'PerGB2018'
  'CapacityReservation'
])
param sku string = 'PerGB2018'

@description('Data retention in days (30-730)')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Daily quota in GB (optional, -1 for unlimited)')
param dailyQuotaGb int = -1

@description('Enable AVD Insights solution')
param enableAVDInsights bool = true

@description('Resource tags')
param tags object = {}

// Log Analytics Workspace
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: dailyQuotaGb > 0 ? {
      dailyQuotaGb: dailyQuotaGb
    } : null
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// AVD Insights Solution
resource avdInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (enableAVDInsights) {
  name: 'AVDInsights(${law.name})'
  location: location
  tags: tags
  plan: {
    name: 'AVDInsights(${law.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/AVDInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: law.id
  }
}

// Additional tables for AVD monitoring
resource avdConnectionsTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: 'WVDConnections'
  properties: {
    retentionInDays: retentionInDays
  }
}

resource avdCheckpointsTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: 'WVDCheckpoints'
  properties: {
    retentionInDays: retentionInDays
  }
}

resource avdErrorsTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: 'WVDErrors'
  properties: {
    retentionInDays: retentionInDays
  }
}

resource avdManagementTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: law
  name: 'WVDManagement'
  properties: {
    retentionInDays: retentionInDays
  }
}

// Outputs
output lawId string = law.id
output lawName string = law.name
output customerId string = law.properties.customerId
output lawResourceId string = law.id

