// ============================================================================
// VM Module - Session Host NC40ads_H100_v5
// ============================================================================
// VM con GPU NVIDIA H100 para Pix4Dmatic
// Tag: workload-type=session-host
// Costo: €19.56/hora (cuando ejecutando)
// ============================================================================

@description('Región de Azure')
param location string

@description('Prefijo para recursos')
param resourcePrefix string

@description('SKU de la VM')
param vmSize string

@description('Usuario administrador')
@secure()
param vmAdminUsername string

@description('Contraseña administrador')
@secure()
param vmAdminPassword string

@description('ID de la subnet')
param subnetId string

@description('Token de registro del Host Pool AVD')
@secure()
param hostPoolToken string

@description('ID del Log Analytics Workspace')
param logAnalyticsWorkspaceId string

@description('Tags del recurso')
param tags object

@description('Nombre de la imagen del SO')
@allowed([
  'win11-23h2-ent'
  'win11-22h2-ent'
  'win10-22h2-ent'
])
param osImageName string = 'win11-23h2-ent'

// ============================================================================
// VARIABLES
// ============================================================================

var vmName = 'vm-${resourcePrefix}-001'
var nicName = '${vmName}-nic'
var osDiskName = '${vmName}-osdisk'

// Configuración de imagen según parámetro
var imageReference = {
  'win11-23h2-ent': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-23h2-ent'
    version: 'latest'
  }
  'win11-22h2-ent': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-22h2-ent'
    version: 'latest'
  }
  'win10-22h2-ent': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-10'
    sku: 'win10-22h2-ent'
    version: 'latest'
  }
}

// ============================================================================
// NETWORK INTERFACE
// ============================================================================

resource nic 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true // Importante para rendimiento GPU
  }
}

// ============================================================================
// VIRTUAL MACHINE
// ============================================================================

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: union(tags, {
    LastActivity: ''
    LastShutdown: ''
    AutoShutdownEnabled: 'true'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: imageReference[osImageName]
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS' // SSD Premium para mejor rendimiento
        }
        diskSizeGB: 256 // OS disk
        caching: 'ReadWrite'
      }
      dataDisks: [
        {
          lun: 0
          name: '${vmName}-datadisk-001'
          createOption: 'Empty'
          diskSizeGB: 1024 // 1TB para datos Pix4D
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          caching: 'ReadOnly'
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
        timeZone: 'Romance Standard Time' // España
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Client' // Azure Hybrid Benefit si aplica
    priority: 'Regular' // No usar Spot VMs para producción
  }
}

// ============================================================================
// VM EXTENSIONS
// ============================================================================

// 1. NVIDIA GPU Driver Extension
resource gpuDriverExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'NvidiaGpuDriverWindows'
  location: location
  properties: {
    publisher: 'Microsoft.HpcCompute'
    type: 'NvidiaGpuDriverWindows'
    typeHandlerVersion: '1.6'
    autoUpgradeMinorVersion: true
    settings: {
      // Driver NVIDIA CUDA para H100
      DriverVersion: 'latest'
      DriverBranch: 'CUDA'
      InstallCUDA: 'true'
      InstallCUDNN: 'true'
    }
  }
}

// 2. Azure Monitor Agent
resource monitoringExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: logAnalyticsWorkspaceId
    }
  }
  dependsOn: [
    gpuDriverExtension
  ]
}

// 3. AVD Host Pool Registration
resource avdExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: uri(environment().resourceManager, 'wvdportalstorageblob/galleryartifacts/Configuration_1.0.02714.342.zip')
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: split(hostPoolToken, '/')[8] // Extraer nombre del token
        registrationInfoToken: hostPoolToken
        aadJoin: true
        useAgentDownloadEndpoint: true
      }
    }
  }
  dependsOn: [
    monitoringExtension
  ]
}

// 4. Custom Script Extension - Configuración post-instalación
resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -Command "& {Get-WmiObject -Class Win32_VideoController | Select-Object Name,DriverVersion,Status | Out-File C:\\gpu-info.txt; nvidia-smi > C:\\nvidia-smi.txt}"'
    }
  }
  dependsOn: [
    avdExtension
  ]
}

// ============================================================================
// DIAGNOSTIC SETTINGS
// ============================================================================

resource vmDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vm-diagnostics'
  scope: vm
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output vmId string = vm.id
output vmName string = vm.name
output privateIpAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output vmIdentityPrincipalId string = vm.identity.principalId
output osDiskId string = vm.properties.storageProfile.osDisk.managedDisk.id
output dataDiskId string = vm.properties.storageProfile.dataDisks[0].managedDisk.id
