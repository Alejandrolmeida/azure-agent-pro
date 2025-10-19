// Azure Image Builder module for PIX4Dmatic golden image
@description('Location for all resources')
param location string = resourceGroup().location

@description('Image Template Name')
param imageTemplateName string

@description('Image Version')
param imageVersion string = '1.0.0'

@description('Source Image')
param sourceImage object = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'Windows-11'
  sku: 'win11-23h2-avd'
  version: 'latest'
}

@description('Tags for the resources')
param tags object = {}

@description('Virtual Network Resource Group')
param vnetResourceGroup string

@description('Virtual Network Name')
param vnetName string

@description('Subnet Name for Image Builder')
param subnetName string

@description('Shared Image Gallery Name')
param galleryName string

@description('Image Definition Name')
param imageDefinitionName string = 'pix4d-avd-gpu'

@description('Run Output Name')
param runOutputName string = 'pix4d-avd-image'

// User Assigned Identity for Image Builder
resource aibIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${imageTemplateName}-identity'
  location: location
  tags: tags
}

// Shared Image Gallery
resource gallery 'Microsoft.Compute/galleries@2023-07-03' = {
  name: galleryName
  location: location
  tags: tags
  properties: {
    description: 'Shared Image Gallery for PIX4D AVD images'
  }
}

// Image Definition
resource imageDefinition 'Microsoft.Compute/galleries/images@2023-07-03' = {
  parent: gallery
  name: imageDefinitionName
  location: location
  tags: tags
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      publisher: 'PIX4D'
      offer: 'AVD-PIX4D'
      sku: 'win11-gpu-a10'
    }
    recommended: {
      vCPUs: {
        min: 12
        max: 36
      }
      memory: {
        min: 64
        max: 440
      }
    }
    hyperVGeneration: 'V2'
    features: [
      {
        name: 'SecurityType'
        value: 'TrustedLaunch'
      }
    ]
  }
}

// Image Template
resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2023-07-01' = {
  name: imageTemplateName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aibIdentity.id}': {}
    }
  }
  properties: {
    buildTimeoutInMinutes: 240
    vmProfile: {
      vmSize: 'Standard_D4s_v5'
      osDiskSizeGB: 127
      vnetConfig: {
        subnetId: resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
      }
    }
    source: {
      type: 'PlatformImage'
      publisher: sourceImage.publisher
      offer: sourceImage.offer
      sku: sourceImage.sku
      version: sourceImage.version
    }
    customize: [
      // Windows Updates
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 40
      }
      // Install NVIDIA GRID Drivers for A10
      {
        type: 'PowerShell'
        name: 'InstallNVIDIADriver'
        inline: [
          'Write-Host "Installing NVIDIA GRID Driver for A10..."'
          '$ProgressPreference = \'SilentlyContinue\''
          'Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2168295" -OutFile "$env:TEMP\\nvidia-driver.exe"'
          'Start-Process -FilePath "$env:TEMP\\nvidia-driver.exe" -ArgumentList "/s", "/n" -Wait'
          'Remove-Item "$env:TEMP\\nvidia-driver.exe" -Force'
          'Write-Host "NVIDIA Driver installed successfully"'
        ]
        runElevated: true
      }
      // Install Visual C++ Redistributables
      {
        type: 'PowerShell'
        name: 'InstallVCRedist'
        inline: [
          'Write-Host "Installing Visual C++ Redistributables..."'
          '$urls = @('
          '  "https://aka.ms/vs/17/release/vc_redist.x64.exe",'
          '  "https://aka.ms/vs/16/release/vc_redist.x64.exe"'
          ')'
          'foreach ($url in $urls) {'
          '  $fileName = Split-Path $url -Leaf'
          '  Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\\$fileName"'
          '  Start-Process -FilePath "$env:TEMP\\$fileName" -ArgumentList "/install", "/quiet", "/norestart" -Wait'
          '  Remove-Item "$env:TEMP\\$fileName" -Force'
          '}'
          'Write-Host "Visual C++ Redistributables installed"'
        ]
        runElevated: true
      }
      // Install .NET Framework 4.8
      {
        type: 'PowerShell'
        name: 'InstallDotNet'
        inline: [
          'Write-Host "Installing .NET Framework 4.8..."'
          'Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2088631" -OutFile "$env:TEMP\\ndp48-web.exe"'
          'Start-Process -FilePath "$env:TEMP\\ndp48-web.exe" -ArgumentList "/q", "/norestart" -Wait'
          'Remove-Item "$env:TEMP\\ndp48-web.exe" -Force'
          'Write-Host ".NET Framework 4.8 installed"'
        ]
        runElevated: true
      }
      // Install DirectX Runtime
      {
        type: 'PowerShell'
        name: 'InstallDirectX'
        inline: [
          'Write-Host "Installing DirectX Runtime..."'
          'Invoke-WebRequest -Uri "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" -OutFile "$env:TEMP\\dxwebsetup.exe"'
          'Start-Process -FilePath "$env:TEMP\\dxwebsetup.exe" -ArgumentList "/silent" -Wait'
          'Remove-Item "$env:TEMP\\dxwebsetup.exe" -Force'
          'Write-Host "DirectX Runtime installed"'
        ]
        runElevated: true
      }
      // Configure Windows for optimal performance
      {
        type: 'PowerShell'
        name: 'OptimizeWindows'
        inline: [
          'Write-Host "Optimizing Windows for GPU workloads..."'
          '# Disable hibernation to save disk space'
          'powercfg /hibernate off'
          '# Set high performance power plan'
          'powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
          '# Disable unnecessary services'
          '$services = @("SysMain", "WSearch")'
          'foreach ($service in $services) {'
          '  Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue'
          '}'
          '# Configure visual effects for performance'
          'Set-ItemProperty -Path "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects" -Name "VisualFXSetting" -Value 2'
          'Write-Host "Windows optimization completed"'
        ]
        runElevated: true
      }
      // Create PIX4D prerequisites marker file
      {
        type: 'PowerShell'
        name: 'CreateMarkerFile'
        inline: [
          'Write-Host "Creating image marker file..."'
          '$markerPath = "C:\\ImageInfo.txt"'
          '$info = @"'
          'Image Name: PIX4D AVD GPU Image'
          'Version: ${imageVersion}'
          'Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")'
          'GPU: NVIDIA A10 vGPU'
          'Prerequisites: NVIDIA Driver, VC++ Redist, .NET 4.8, DirectX'
          'Note: PIX4Dmatic must be installed separately (BYOL)'
          '"@'
          '$info | Out-File -FilePath $markerPath -Encoding UTF8'
          'Write-Host "Marker file created at $markerPath"'
        ]
        runElevated: false
      }
      // Run Windows Update again after all installations
      {
        type: 'WindowsUpdate'
        searchCriteria: 'IsInstalled=0'
        filters: [
          'exclude:$_.Title -like \'*Preview*\''
          'include:$true'
        ]
        updateLimit: 20
      }
      // Generalize the image
      {
        type: 'WindowsRestart'
        restartTimeout: '10m'
      }
    ]
    distribute: [
      {
        type: 'SharedImage'
        galleryImageId: imageDefinition.id
        runOutputName: runOutputName
        replicationRegions: [
          location
        ]
        storageAccountType: 'Premium_LRS'
      }
    ]
  }
}

@description('Image Template Name')
output imageTemplateName string = imageTemplate.name

@description('Image Template ID')
output imageTemplateId string = imageTemplate.id

@description('Gallery Name')
output galleryName string = gallery.name

@description('Image Definition ID')
output imageDefinitionId string = imageDefinition.id

@description('Identity Principal ID')
output identityPrincipalId string = aibIdentity.properties.principalId
