// RBAC assignments for Automation Account
// Grants permissions to manage VMs and AVD resources

targetScope = 'subscription'

@description('Automation Account Managed Identity Principal ID')
param automationAccountPrincipalId string

@description('Host Pool Resource Group name')
param hostPoolResourceGroupName string

// Virtual Machine Contributor role for VM management
resource vmContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, automationAccountPrincipalId, 'VMContributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c') // Virtual Machine Contributor
    principalId: automationAccountPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Desktop Virtualization Contributor for AVD management
resource avdContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, automationAccountPrincipalId, 'AVDContributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '082f0a83-3be5-4ba1-904c-961cca79b387') // Desktop Virtualization Contributor
    principalId: automationAccountPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Reader role for querying resources
resource readerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, automationAccountPrincipalId, 'Reader')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader
    principalId: automationAccountPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output vmContributorRoleId string = vmContributorRole.id
output avdContributorRoleId string = avdContributorRole.id
output readerRoleId string = readerRole.id

