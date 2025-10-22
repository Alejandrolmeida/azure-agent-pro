// Automation module for auto-shutdown and deallocation
@description('Location for all resources')
param location string = resourceGroup().location

@description('Automation Account Name')
param automationAccountName string

@description('Tags for the resources')
param tags object = {}

@description('Log Analytics Workspace ID for diagnostics')
param workspaceId string

@description('Host Pool Resource Group')
param hostPoolResourceGroup string

@description('Host Pool Name')
param hostPoolName string

@description('Class Window in UTC (format: HH:MM-HH:MM)')
param classWindow string = '16:00-21:00'

@description('Idle minutes before deallocate')
param idleDeallocateMinutes int = 30

@description('Time Zone')
param timeZone string = 'UTC'

@description('Schedule start time (ISO 8601 format)')
param scheduleStartTime string = dateTimeAdd(utcNow(), 'PT15M')

// Automation Account
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
  }
}

// Diagnostic Settings
resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: automationAccount
  name: 'diag-${automationAccountName}'
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Variables for runbook
resource varHostPoolRG 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'HostPoolResourceGroup'
  properties: {
    value: '"${hostPoolResourceGroup}"'
    isEncrypted: false
  }
}

resource varHostPoolName 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'HostPoolName'
  properties: {
    value: '"${hostPoolName}"'
    isEncrypted: false
  }
}

resource varClassWindow 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'ClassWindow'
  properties: {
    value: '"${classWindow}"'
    isEncrypted: false
  }
}

resource varIdleMinutes 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'IdleDeallocateMinutes'
  properties: {
    value: '"${idleDeallocateMinutes}"'
    isEncrypted: false
  }
}

// Runbook for auto-deallocation
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: 'AVD-Auto-Deallocate'
  location: location
  tags: tags
  properties: {
    runbookType: 'PowerShell'
    logVerbose: true
    logProgress: true
    description: 'Automatically deallocate stopped VMs and shut down VMs outside class window'
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/alejandrolmeida/azure-agent-pro/main/ops/runbooks/auto-deallocate.ps1'
      version: '1.0.0.0'
    }
  }
}

// Schedule: Check every 15 minutes
resource scheduleCheck 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: 'schedule-check-vms'
  properties: {
    description: 'Check VMs every 15 minutes for deallocation'
    startTime: scheduleStartTime
    frequency: 'Minute'
    interval: 15
    timeZone: timeZone
  }
}

// Link schedule to runbook
resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  parent: automationAccount
  name: guid(automationAccount.id, runbook.id, scheduleCheck.id)
  properties: {
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: scheduleCheck.name
    }
  }
}

// Modules needed
resource moduleAz 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.Accounts'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.Accounts'
    }
  }
}

resource moduleCompute 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.Compute'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.Compute'
    }
  }
  dependsOn: [
    moduleAz
  ]
}

resource moduleDesktopVirtualization 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.DesktopVirtualization'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.DesktopVirtualization'
    }
  }
  dependsOn: [
    moduleAz
  ]
}

@description('Automation Account ID')
output automationAccountId string = automationAccount.id

@description('Automation Account Name')
output automationAccountName string = automationAccount.name

@description('Automation Account Principal ID')
output principalId string = automationAccount.identity.principalId

@description('Runbook Name')
output runbookName string = runbook.name
