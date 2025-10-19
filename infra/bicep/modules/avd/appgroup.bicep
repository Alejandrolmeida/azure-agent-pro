// AVD Application Group module
@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Application Group')
param applicationGroupName string

@description('Friendly name of the Application Group')
param applicationGroupFriendlyName string = 'PIX4D Desktop'

@description('Description of the Application Group')
param applicationGroupDescription string = 'Desktop Application Group for PIX4Dmatic'

@description('Application Group Type')
@allowed([
  'Desktop'
  'RemoteApp'
])
param applicationGroupType string = 'Desktop'

@description('Host Pool Resource ID')
param hostPoolId string

@description('Tags for the resources')
param tags object = {}

// Application Group
resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: applicationGroupName
  location: location
  tags: tags
  properties: {
    friendlyName: applicationGroupFriendlyName
    description: applicationGroupDescription
    applicationGroupType: applicationGroupType
    hostPoolArmPath: hostPoolId
  }
}

@description('Application Group Resource ID')
output applicationGroupId string = applicationGroup.id

@description('Application Group Name')
output applicationGroupName string = applicationGroup.name
