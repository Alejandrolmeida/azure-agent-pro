// AVD Host Pool module with Start VM on Connect
@description('Location for all resources')
param location string = resourceGroup().location

@description('Registration token expiration time')
param tokenExpirationTime string = dateTimeAdd(utcNow(), 'P7D')

@description('Name of the Host Pool')
param hostPoolName string

@description('Friendly name of the Host Pool')
param hostPoolFriendlyName string = 'PIX4D Lab Host Pool'

@description('Description of the Host Pool')
param hostPoolDescription string = 'Azure Virtual Desktop Host Pool for PIX4Dmatic workloads'

@description('Type of Host Pool')
@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'

@description('Personal Desktop Assignment Type')
@allowed([
  'Automatic'
  'Direct'
])
param personalDesktopAssignmentType string = 'Automatic'

@description('Load Balancer Type')
@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'DepthFirst'

@description('Max Session Limit')
param maxSessionLimit int = 1

@description('Enable Start VM on Connect')
param enableStartVmOnConnect bool = true

@description('Validation Environment')
param validationEnvironment bool = false

@description('Preferred App Group Type')
@allowed([
  'Desktop'
  'RailApplications'
])
param preferredAppGroupType string = 'Desktop'

@description('Tags for the resources')
param tags object = {}

@description('Custom RDP Properties')
param customRdpProperty string = 'drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:*;redirectcomports:i:0;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;use multimon:i:1;targetisaadjoined:i:1;enablerdsaadauth:i:1;audiocapturemode:i:1;encode redirected video capture:i:1;redirected video capture encoding quality:i:1'

// Host Pool
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    friendlyName: hostPoolFriendlyName
    description: hostPoolDescription
    hostPoolType: hostPoolType
    personalDesktopAssignmentType: personalDesktopAssignmentType
    loadBalancerType: loadBalancerType
    maxSessionLimit: maxSessionLimit
    startVMOnConnect: enableStartVmOnConnect
    validationEnvironment: validationEnvironment
    preferredAppGroupType: preferredAppGroupType
    customRdpProperty: customRdpProperty
    registrationInfo: {
      expirationTime: tokenExpirationTime
      registrationTokenOperation: 'Update'
    }
  }
}

@description('Host Pool Resource ID')
output hostPoolId string = hostPool.id

@description('Host Pool Name')
output hostPoolName string = hostPool.name

@description('Registration Token')
@secure()
output registrationToken string = hostPool.listRegistrationTokens().value[0].token
