// Role Assignment module
targetScope = 'resourceGroup'

@description('Principal ID to assign the role to')
param principalId string

@description('Role Definition ID (GUID)')
param roleDefinitionId string

@description('Principal Type')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'

@description('Role Assignment Notes')
param assignmentDescription string = ''

// Role Assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
    description: assignmentDescription
  }
}

@description('Role Assignment ID')
output roleAssignmentId string = roleAssignment.id
