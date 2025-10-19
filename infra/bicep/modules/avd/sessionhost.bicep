// AVD Session Host module
@description('Location for all resources')
param location string = resourceGroup().location

@description('Name prefix for Session Hosts')
param sessionHostNamePrefix string

@description('Number of Session Hosts')
param sessionHostCount int = 1

@description('VM Size for Session Hosts - NVads A10 v5 series for GPU workloads')
@allowed([
  'Standard_NV12ads_A10_v5'
  'Standard_NV18ads_A10_v5'
  'Standard_NV36ads_A10_v5'
])
param vmSize string = 'Standard_NV36ads_A10_v5'

@description('Virtual Network Resource Group')
param vnetResourceGroup string

@description('Virtual Network Name')
param vnetName string

@description('Subnet Name')
param subnetName string

@description('Image Reference')
param imageReference object = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'Windows-11'
  sku: 'win11-23h2-avd'
  version: 'latest'
}

@description('Custom Image ID (if using custom image from AIB)')
param customImageId string = ''

@description('OS Disk Type')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
  'PremiumV2_LRS'
])
param osDiskType string = 'Premium_LRS'

@description('Data Disk Size in GB (for PIX4D projects and cache)')
param dataDiskSizeGB int = 512

@description('Admin Username')
@secure()
param adminUsername string

@description('Admin Password')
@secure()
param adminPassword string

@description('Host Pool Registration Token')
@secure()
param hostPoolToken string

@description('Domain to join (optional, for AD DS)')
param domainToJoin string = ''

@description('OU Path for domain join')
param ouPath string = ''

@description('Domain Join Username')
@secure()
param domainJoinUsername string = ''

@description('Domain Join Password')
@secure()
param domainJoinPassword string = ''

@description('Enable Azure AD Join instead of AD DS')
param enableAADJoin bool = true

@description('Tags for the resources')
param tags object = {}

@description('Idle time before deallocate (minutes)')
param idleDeallocateMinutes int = 30

// Get existing subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: vnet
  name: subnetName
}

// Session Host VMs
resource sessionHost 'Microsoft.Compute/virtualMachines@2023-09-01' = [for i in range(0, sessionHostCount): {
  name: '${sessionHostNamePrefix}-${i}'
  location: location
  tags: union(tags, {
    sessionHost: 'true'
    idleShutdownMinutes: string(idleDeallocateMinutes)
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${sessionHostNamePrefix}-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
      }
    }
    storageProfile: {
      imageReference: empty(customImageId) ? imageReference : {
        id: customImageId
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: 'Delete'
      }
      dataDisks: [
        {
          lun: 0
          name: '${sessionHostNamePrefix}-${i}-datadisk'
          createOption: 'Empty'
          diskSizeGB: dataDiskSizeGB
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          deleteOption: 'Delete'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: sessionHostNic[i].id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    licenseType: 'Windows_Client'
    priority: 'Regular'
  }
}]

// Network Interfaces
resource sessionHostNic 'Microsoft.Network/networkInterfaces@2023-05-01' = [for i in range(0, sessionHostCount): {
  name: '${sessionHostNamePrefix}-${i}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}]

// AVD Agent Extension
resource avdAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, sessionHostCount): {
  parent: sessionHost[i]
  name: 'DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_01-20-2023.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: split(hostPoolToken, '.')[0] // Extract from token
        registrationInfoToken: hostPoolToken
        aadJoin: enableAADJoin
      }
    }
  }
  dependsOn: [
    sessionHostNic
  ]
}]

// Azure AD Join Extension (if enabled)
resource aadJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, sessionHostCount): if (enableAADJoin) {
  parent: sessionHost[i]
  name: 'AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    avdAgentExtension[i]
  ]
}]

// Domain Join Extension (if not using AAD Join)
resource domainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, sessionHostCount): if (!enableAADJoin && !empty(domainToJoin)) {
  parent: sessionHost[i]
  name: 'JsonADDomainExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: domainJoinUsername
      restart: true
      options: '3' // Join domain and create computer account
    }
    protectedSettings: {
      password: domainJoinPassword
    }
  }
  dependsOn: [
    avdAgentExtension[i]
  ]
}]

// NVIDIA GPU Driver Extension
resource nvidiaExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = [for i in range(0, sessionHostCount): {
  parent: sessionHost[i]
  name: 'NvidiaGpuDriverWindows'
  location: location
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.6'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [
    aadJoinExtension
    domainJoinExtension
  ]
}]

@description('Session Host VM IDs')
output sessionHostIds array = [for i in range(0, sessionHostCount): sessionHost[i].id]

@description('Session Host VM Names')
output sessionHostNames array = [for i in range(0, sessionHostCount): sessionHost[i].name]
