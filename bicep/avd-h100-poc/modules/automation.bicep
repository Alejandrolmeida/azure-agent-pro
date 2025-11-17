// ============================================================================
// Automation Module - Auto-shutdown con Azure Automation
// ============================================================================
// Runbook para detener VM tras 15 minutos sin sesión AVD
// Tag: workload-type=infrastructure
// Costo: €1/mes
// ============================================================================

@description('Región de Azure')
param location string

@description('Prefijo para recursos')
param resourcePrefix string

@description('Nombre del Resource Group')
param resourceGroupName string

@description('Nombre del Host Pool AVD')
param hostPoolName string

@description('Nombre de la VM (para referencia)')
param vmName string = ''

@description('Minutos de inactividad antes de shutdown')
param idleMinutesThreshold int

@description('Habilitar auto-shutdown')
param enableAutoShutdown bool

@description('Tags del recurso')
param tags object

@description('Fecha de inicio del schedule')
param scheduleStartTime string = dateTimeAdd(utcNow(), 'PT5M')

@description('Fecha de expiración del schedule')
param scheduleExpiryTime string = dateTimeAdd(utcNow(), 'P1Y')

// ============================================================================
// VARIABLES
// ============================================================================

var automationAccountName = 'aa-${resourcePrefix}-auto-shutdown'
var runbookName = 'Stop-AVDSessionHost'
var scheduleName = 'Schedule-AutoShutdown'

// ============================================================================
// AUTOMATION ACCOUNT
// ============================================================================

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
    }
    publicNetworkAccess: true
  }
}

// ============================================================================
// POWERSHELL MODULES - Dependencias del Runbook
// ============================================================================

// Módulo Az.Accounts
resource azAccountsModule 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.Accounts'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.Accounts'
      version: '2.13.2'
    }
  }
}

// Módulo Az.Compute
resource azComputeModule 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.Compute'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.Compute'
      version: '6.3.0'
    }
  }
  dependsOn: [
    azAccountsModule
  ]
}

// Módulo Az.DesktopVirtualization
resource azAvdModule 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.DesktopVirtualization'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.DesktopVirtualization'
      version: '4.3.0'
    }
  }
  dependsOn: [
    azAccountsModule
  ]
}

// ============================================================================
// RUNBOOK - Auto-shutdown Logic
// ============================================================================

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: runbookName
  location: location
  tags: tags
  properties: {
    runbookType: 'PowerShell'
    logProgress: true
    logVerbose: true
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/placeholder/runbook.ps1' // Placeholder
      version: '1.0.0.0'
    }
    description: 'Detiene y desasigna VMs AVD sin sesiones activas durante ${idleMinutesThreshold} minutos'
  }
  dependsOn: [
    azComputeModule
    azAvdModule
  ]
}

// ============================================================================
// SCHEDULE - Ejecutar cada 5 minutos
// ============================================================================

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = if (enableAutoShutdown) {
  parent: automationAccount
  name: scheduleName
  properties: {
    description: 'Ejecutar runbook de auto-shutdown cada 5 minutos'
    startTime: scheduleStartTime // Empezar en 5 minutos
    expiryTime: scheduleExpiryTime // Expira en 1 año
    interval: 5
    frequency: 'Minute'
    timeZone: 'Romance Standard Time' // España
  }
}

// ============================================================================
// JOB SCHEDULE - Vincular Schedule con Runbook
// ============================================================================

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = if (enableAutoShutdown) {
  parent: automationAccount
  name: guid(automationAccount.id, runbook.id, schedule.id)
  properties: {
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: schedule.name
    }
    parameters: {
      ResourceGroupName: resourceGroupName
      HostPoolName: hostPoolName
      IdleMinutesThreshold: string(idleMinutesThreshold)
    }
  }
}

// ============================================================================
// ROLE ASSIGNMENTS - Permisos para Managed Identity
// ============================================================================

// Contributor en el Resource Group para poder detener VMs
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(automationAccount.id, resourceGroupName, contributorRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Desktop Virtualization Reader para leer sesiones AVD
var desktopVirtualizationReaderRoleId = '49a72310-ab8d-41df-bbb0-79b649203868'

resource avdReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(automationAccount.id, resourceGroupName, desktopVirtualizationReaderRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', desktopVirtualizationReaderRoleId)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output automationAccountId string = automationAccount.id
output automationAccountName string = automationAccount.name
output runbookName string = runbook.name
output scheduleName string = enableAutoShutdown ? schedule.name : 'disabled'
output managedIdentityPrincipalId string = automationAccount.identity.principalId
