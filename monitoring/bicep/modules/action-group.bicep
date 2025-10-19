// Action Group for alert notifications
// Sends notifications via email, SMS, webhook, etc.

@description('Action Group name')
param actionGroupName string

@description('Location (must be global for action groups)')
param location string = 'global'

@description('Email addresses for notifications')
param emailAddresses array

@description('Short name (max 12 chars)')
param shortName string = substring(actionGroupName, 0, min(length(actionGroupName), 12))

@description('Resource tags')
param tags object = {}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  tags: tags
  properties: {
    groupShortName: shortName
    enabled: true
    emailReceivers: [for (email, i) in emailAddresses: {
      name: 'Email${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
  }
}

output actionGroupId string = actionGroup.id
output actionGroupName string = actionGroup.name

