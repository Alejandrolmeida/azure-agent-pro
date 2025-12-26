// Azure SQL Database Module
// Crea un Azure SQL Server y databases con seguridad y monitoreo avanzado
// Author: Azure Architect Pro
// Date: 2025-12-26

@description('Nombre del SQL Server (debe ser único globalmente)')
param sqlServerName string

@description('Región de Azure')
param location string = resourceGroup().location

@description('Tags para los recursos')
param tags object = {}

@description('Nombre de la base de datos')
param databaseName string

@description('SKU de la base de datos')
@allowed([
  'Basic'
  'S0'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P4'
  'GP_Gen5_2'
  'GP_Gen5_4'
  'GP_Gen5_8'
  'BC_Gen5_2'
  'BC_Gen5_4'
])
param databaseSku string = 'S0'

@description('Habilitar Azure AD authentication')
param enableAzureADAuth bool = true

@description('Azure AD admin object ID')
param azureAdAdminObjectId string = ''

@description('Azure AD admin username')
param azureAdAdminUsername string = ''

@description('Habilitar transparent data encryption')
param enableTDE bool = true

@description('Habilitar Advanced Threat Protection')
param enableThreatProtection bool = true

@description('Habilitar auditoría')
param enableAuditing bool = true

@description('ID de Log Analytics workspace para auditoría')
param logAnalyticsWorkspaceId string

@description('ID de Storage Account para auditoría')
param auditStorageAccountId string = ''

@description('Habilitar private endpoint')
param enablePrivateEndpoint bool = true

@description('ID de subnet para private endpoint')
param privateEndpointSubnetId string = ''

@description('ID de private DNS zone')
param privateDnsZoneId string = ''

@description('Retention de backups en días')
@minValue(7)
@maxValue(35)
param backupRetentionDays int = 7

@description('Habilitar geo-redundant backup')
param enableGeoRedundantBackup bool = false

@description('Configuración de auto-pause para serverless (minutos)')
param autoPauseDelay int = 60

@description('Configuración de firewall - IPs permitidas')
param allowedIpAddresses array = []

// Variables
var sqlServerFullName = '${sqlServerName}.database.windows.net'

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: union(tags, {
    resource: 'sql-server'
    deployedBy: 'Bicep'
  })
  properties: {
    administratorLogin: enableAzureADAuth ? null : 'sqladmin'
    administratorLoginPassword: enableAzureADAuth ? null : newGuid() // Auto-generate if not using AAD
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Azure AD Administrator
resource sqlServerAdministrator 'Microsoft.Sql/servers/administrators@2023-05-01-preview' = if (enableAzureADAuth && !empty(azureAdAdminObjectId)) {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: azureAdAdminUsername
    sid: azureAdAdminObjectId
    tenantId: subscription().tenantId
  }
}

// Firewall rules
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (!enablePrivateEndpoint) {
  parent: sqlServer
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource customFirewallRules 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = [for (ip, index) in allowedIpAddresses: if (!enablePrivateEndpoint) {
  parent: sqlServer
  name: 'AllowedIP-${index}'
  properties: {
    startIpAddress: ip
    endIpAddress: ip
  }
}]

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: databaseSku
    tier: contains(databaseSku, 'GP') ? 'GeneralPurpose' : contains(databaseSku, 'BC') ? 'BusinessCritical' : 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 268435456000 // 250 GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: enableGeoRedundantBackup ? 'Geo' : 'Local'
    minCapacity: contains(databaseSku, 'GP') ? json('0.5') : null
    autoPauseDelay: contains(databaseSku, 'GP') ? autoPauseDelay : null
    isLedgerOn: false
  }
}

// Transparent Data Encryption
resource tde 'Microsoft.Sql/servers/databases/transparentDataEncryption@2023-05-01-preview' = if (enableTDE) {
  parent: sqlDatabase
  name: 'current'
  properties: {
    state: 'Enabled'
  }
}

// Backup long-term retention policy
resource backupLongTermRetention 'Microsoft.Sql/servers/databases/backupLongTermRetentionPolicies@2023-05-01-preview' = {
  parent: sqlDatabase
  name: 'default'
  properties: {
    weeklyRetention: 'P1W'
    monthlyRetention: 'P1M'
    yearlyRetention: 'P1Y'
    weekOfYear: 1
  }
}

// Advanced Threat Protection
resource securityAlertPolicy 'Microsoft.Sql/servers/databases/securityAlertPolicies@2023-05-01-preview' = if (enableThreatProtection) {
  parent: sqlDatabase
  name: 'default'
  properties: {
    state: 'Enabled'
    emailAccountAdmins: true
    emailAddresses: []
    retentionDays: 90
  }
}

// Vulnerability Assessment
resource vulnerabilityAssessment 'Microsoft.Sql/servers/vulnerabilityAssessments@2023-05-01-preview' = if (enableThreatProtection && !empty(auditStorageAccountId)) {
  parent: sqlServer
  name: 'default'
  properties: {
    storageContainerPath: '${auditStorageAccountId}/vulnerability-assessment'
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: true
      emails: []
    }
  }
}

// Auditing
resource auditing 'Microsoft.Sql/servers/databases/auditingSettings@2023-05-01-preview' = if (enableAuditing) {
  parent: sqlDatabase
  name: 'default'
  properties: {
    state: 'Enabled'
    auditActionsAndGroups: [
      'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
      'BATCH_COMPLETED_GROUP'
    ]
    storageEndpoint: !empty(auditStorageAccountId) ? '${auditStorageAccountId}/audit' : ''
    isStorageSecondaryKeyInUse: false
    retentionDays: 90
    isAzureMonitorTargetEnabled: true
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sqlDatabase.name}-diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'AutomaticTuning'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'Errors'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'Timeouts'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'Blocks'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'Deadlocks'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'InstanceAndAppAdvanced'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'WorkloadManagement'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Private Endpoint
module privateEndpoint '../modules/private-endpoint.bicep' = if (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) {
  name: '${sqlServer.name}-pe-deployment'
  params: {
    name: '${sqlServer.name}-pe'
    location: location
    tags: tags
    privateLinkServiceId: sqlServer.id
    groupId: 'sqlServer'
    subnetId: privateEndpointSubnetId
    privateDnsZoneId: privateDnsZoneId
  }
}

// Outputs
output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlServerFQDN string = sqlServerFullName
output databaseId string = sqlDatabase.id
output databaseName string = sqlDatabase.name
output principalId string = sqlServer.identity.principalId
output connectionString string = 'Server=tcp:${sqlServerFullName},1433;Initial Catalog=${databaseName};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;'
