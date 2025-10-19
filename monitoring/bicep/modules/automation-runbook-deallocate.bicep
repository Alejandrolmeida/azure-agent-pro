// Azure Automation Account with enhanced auto-deallocate runbook
// Supports multiple cutoff reasons: budget, idle, outOfSchedule

@description('Automation Account name')
param automationAccountName string

@description('Azure region')
param location string = resourceGroup().location

@description('Log Analytics Workspace ID')
param lawResourceId string

@description('Host Pool Resource Group')
param hostPoolResourceGroup string

@description('Host Pool Name')
param hostPoolName string

@description('Class schedule window (HH:mm-HH:mm format)')
param classWindow string = '16:00-21:00'

@description('Idle time before deallocate (minutes)')
param idleDeallocateMinutes int = 30

@description('Runbook script content (loaded from file)')
param runbookScriptContent string

@description('Schedule start time')
param scheduleStartTime string = '2025-10-20T00:00:00Z'

@description('Schedule expiry time')
param scheduleExpiryTime string = '2028-10-20T00:00:00Z'

@description('Webhook expiry time')
param webhookExpiryTime string = '2026-10-20T00:00:00Z'

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
    publicNetworkAccess: true
  }
}

// Link to Log Analytics for job logs
resource lawLink 'Microsoft.Automation/automationAccounts/linkedWorkspace@2020-01-13-preview' = {
  parent: automationAccount
  name: 'default'
  properties: {
    workspaceId: lawResourceId
  }
}

// Automation Variables
resource varHostPoolRG 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'HostPoolResourceGroup'
  properties: {
    value: '"${hostPoolResourceGroup}"'
    description: 'Resource group containing the AVD host pool'
    isEncrypted: false
  }
}

resource varHostPoolName 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'HostPoolName'
  properties: {
    value: '"${hostPoolName}"'
    description: 'Name of the AVD host pool'
    isEncrypted: false
  }
}

resource varClassWindow 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'ClassWindow'
  properties: {
    value: '"${classWindow}"'
    description: 'Class schedule window in HH:mm-HH:mm format'
    isEncrypted: false
  }
}

resource varIdleDeallocate 'Microsoft.Automation/automationAccounts/variables@2023-11-01' = {
  parent: automationAccount
  name: 'IdleDeallocateMinutes'
  properties: {
    value: '"${idleDeallocateMinutes}"'
    description: 'Minutes of inactivity before deallocating a VM'
    isEncrypted: false
  }
}

// Import required PowerShell modules
resource moduleAzAccounts 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.Accounts'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.Accounts'
    }
  }
}

resource moduleAzCompute 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.Compute'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.Compute'
    }
  }
  dependsOn: [ moduleAzAccounts ]
}

resource moduleAzDesktopVirtualization 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.DesktopVirtualization'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.DesktopVirtualization'
    }
  }
  dependsOn: [ moduleAzAccounts ]
}

resource moduleAzResources 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  parent: automationAccount
  name: 'Az.Resources'
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/Az.Resources'
    }
  }
  dependsOn: [ moduleAzAccounts ]
}

// Auto-deallocate Runbook
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: 'auto-deallocate'
  location: location
  tags: tags
  properties: {
    runbookType: 'PowerShell'
    logVerbose: true
    logProgress: true
    logActivityTrace: 1
    publishContentLink: {
      uri: 'https://raw.githubusercontent.com/${githubRepo}/main/ops/runbooks/auto-deallocate.ps1'
      version: '2.0.0'
    }
    description: 'Automatically deallocates idle or out-of-schedule AVD session hosts'
  }
  dependsOn: [
    moduleAzAccounts
    moduleAzCompute
    moduleAzDesktopVirtualization
    moduleAzResources
  ]
}

// Schedule: Run every 15 minutes during extended hours (14:00-23:00)
resource schedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: 'avd-deallocate-schedule'
  properties: {
    description: 'Run auto-deallocate every 15 minutes'
    startTime: dateTimeAdd(utcNow(), 'PT15M')
    expiryTime: dateTimeAdd(utcNow(), 'P3Y')
    interval: 15
    frequency: 'Minute'
    timeZone: 'UTC'
  }
}

// Link schedule to runbook
resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  parent: automationAccount
  name: guid(automationAccount.id, schedule.id, runbook.id)
  properties: {
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: schedule.name
    }
    parameters: {
      CutoffReason: 'auto'
    }
  }
}

// Webhook for Logic App integration (budget cutoff)
resource webhook 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  parent: automationAccount
  name: 'budget-cutoff-webhook'
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(utcNow(), 'P1Y')
    runbook: {
      name: runbook.name
    }
    parameters: {
      CutoffReason: 'budgetExceeded'
      ForcedShutdown: true
    }
  }
}

// Outputs
output automationAccountId string = automationAccount.id
output automationAccountName string = automationAccount.name
output runbookName string = runbook.name
output webhookUri string = webhook.properties.uri
output principalId string = automationAccount.identity.principalId

