// AVD Workspace module
@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Workspace')
param workspaceName string

@description('Friendly name of the Workspace')
param workspaceFriendlyName string = 'PIX4D Lab Workspace'

@description('Description of the Workspace')
param workspaceDescription string = 'Azure Virtual Desktop Workspace for PIX4Dmatic'

@description('Application Group References')
param applicationGroupReferences array = []

@description('Tags for the resources')
param tags object = {}

// Workspace
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    friendlyName: workspaceFriendlyName
    description: workspaceDescription
    applicationGroupReferences: applicationGroupReferences
  }
}

@description('Workspace Resource ID')
output workspaceId string = workspace.id

@description('Workspace Name')
output workspaceName string = workspace.name
