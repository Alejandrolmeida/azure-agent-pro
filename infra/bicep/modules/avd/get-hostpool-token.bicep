// Module to retrieve Host Pool Registration Token using Deployment Script
@description('Location for the deployment script')
param location string = resourceGroup().location

@description('Host Pool Name')
param hostPoolName string

@description('Host Pool Resource Group')
param hostPoolResourceGroup string

@description('Token expiration time (default 7 days)')
param tokenExpirationTime string = dateTimeAdd(utcNow(), 'P7D')

@description('User Assigned Identity ID for the deployment script')
param managedIdentityId string

// Deployment Script to get Host Pool token
resource getTokenScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'get-hostpool-token-${uniqueString(hostPoolName)}'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    azCliVersion: '2.50.0'
    timeout: 'PT10M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'OnSuccess'
    scriptContent: '''
      #!/bin/bash
      set -e
      
      # Get the token from the Host Pool
      TOKEN=$(az desktopvirtualization hostpool retrieve-registration-token \
        --name "${HOSTPOOL_NAME}" \
        --resource-group "${HOSTPOOL_RG}" \
        --query "token" -o tsv)
      
      # Return the token as output
      echo "{\"token\": \"$TOKEN\"}" > $AZ_SCRIPTS_OUTPUT_PATH
    '''
    environmentVariables: [
      {
        name: 'HOSTPOOL_NAME'
        value: hostPoolName
      }
      {
        name: 'HOSTPOOL_RG'
        value: hostPoolResourceGroup
      }
    ]
  }
}

@description('Host Pool Registration Token')
output token string = getTokenScript.properties.outputs.token
