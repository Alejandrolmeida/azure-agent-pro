// Azure Files module for FSLogix profiles
@description('Location for all resources')
param location string = resourceGroup().location

@description('Storage Account Name for FSLogix profiles')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Storage Account SKU')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
])
param storageAccountSku string = 'Premium_LRS'

@description('File Share Name for FSLogix profiles')
param fileShareName string = 'profiles'

@description('File Share Quota in GB')
param shareQuotaGB int = 1024

@description('Enable Azure AD Kerberos for Azure Files')
param enableAzureADKerberos bool = true

@description('Tags for the resources')
param tags object = {}

@description('Virtual Network Resource Group')
param vnetResourceGroup string = resourceGroup().name

@description('Virtual Network Name')
param vnetName string

@description('Subnet Name for private endpoint')
param subnetName string

@description('Enable Private Endpoint')
param enablePrivateEndpoint bool = true

// Storage Account for FSLogix
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'FileStorage'
  sku: {
    name: storageAccountSku
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    azureFilesIdentityBasedAuthentication: enableAzureADKerberos ? {
      directoryServiceOptions: 'AADKERB'
    } : null
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: enablePrivateEndpoint ? 'Deny' : 'Allow'
    }
    encryption: {
      services: {
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// File Services
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// File Share for FSLogix profiles
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: fileServices
  name: fileShareName
  properties: {
    accessTier: 'Premium'
    shareQuota: shareQuotaGB
    enabledProtocols: 'SMB'
  }
}

// Private Endpoint (if enabled)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint) {
  name: '${storageAccountName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: '${storageAccountName}-pe-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group (if private endpoint enabled)
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (enablePrivateEndpoint) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// Private DNS Zone for Azure Files
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// Link Private DNS Zone to VNet
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoint) {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)
    }
  }
}

@description('Storage Account ID')
output storageAccountId string = storageAccount.id

@description('Storage Account Name')
output storageAccountName string = storageAccount.name

@description('File Share Name')
output fileShareName string = fileShare.name

@description('FSLogix Profile Path (UNC)')
output fslogixProfilePath string = '\\\\${storageAccount.name}.file.${environment().suffixes.storage}\\${fileShareName}'
