@description('Azure region for resources')
param location string

@description('Project name for naming convention')
param projectName string

@description('Environment name')
param environment string

@description('Resource tags')
param tags object

// Variables
var logAnalyticsWorkspaceName = 'log-${projectName}-${environment}'
var applicationInsightsName = 'appi-${projectName}-${environment}'
var actionGroupName = 'ag-${projectName}-${environment}'

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Action Group (for alerts)
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: substring('${projectName}-${environment}', 0, 12)
    enabled: true
    emailReceivers: [
      {
        name: 'DevTeam'
        emailAddress: 'devteam@example.com' // TODO: Update with actual email
        useCommonAlertSchema: true
      }
    ]
  }
}

// Alert Rule: HTTP 5xx Errors
resource alert5xx 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-http5xx-${projectName}-${environment}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when HTTP 5xx errors exceed threshold'
    severity: 2
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'HTTP5xxCount'
          metricName: 'requests/failed'
          dimensions: [
            {
              name: 'request/resultCode'
              operator: 'Include'
              values: [
                '5*'
              ]
            }
          ]
          operator: 'GreaterThan'
          threshold: 10
          timeAggregation: 'Count'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Alert Rule: Response Time P95
resource alertResponseTime 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-responsetime-${projectName}-${environment}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when response time P95 exceeds 500ms'
    severity: 3
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'ResponseTimeP95'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 500
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Alert Rule: Failed Request Percentage
resource alertFailedRequests 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-failedrequests-${projectName}-${environment}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when failed request percentage exceeds 20%'
    severity: 2
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'FailedRequestPercentage'
          metricName: 'requests/failed'
          operator: 'GreaterThan'
          threshold: 20
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Outputs
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output applicationInsightsId string = applicationInsights.id
output applicationInsightsName string = applicationInsights.name
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output actionGroupId string = actionGroup.id
