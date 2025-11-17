// ============================================================================
// AVD Module - Host Pool, Workspace, Application Group
// ============================================================================
// Configuración AVD Personal Desktop para 1 usuario
// Tag: workload-type=infrastructure
// ============================================================================

@description('Región de Azure')
param location string

@description('Prefijo para recursos')
param resourcePrefix string

@description('Object ID del usuario Azure AD')
param avdUserObjectId string

@description('ID del Log Analytics Workspace')
param logAnalyticsWorkspaceId string

@description('Tags del recurso')
param tags object

@description('Tiempo de expiración del token de registro (formato ISO 8601)')
param tokenExpirationTime string = dateTimeAdd(utcNow(), 'P30D')

// ============================================================================
// VARIABLES
// ============================================================================

var hostPoolName = 'hp-${resourcePrefix}-personal'
var workspaceName = 'ws-${resourcePrefix}-poc'
var appGroupName = 'ag-${resourcePrefix}-desktop'

// ============================================================================
// HOST POOL - Personal Desktop
// ============================================================================

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    hostPoolType: 'Personal' // VDI dedicado (1 usuario, 1 VM)
    personalDesktopAssignmentType: 'Direct' // Asignación directa
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 1 // Solo 1 sesión simultánea
    loadBalancerType: 'Persistent' // Usuario siempre conecta a su VM
    validationEnvironment: false
    startVMOnConnect: true // Arrancar VM automáticamente al conectar
    registrationInfo: {
      expirationTime: tokenExpirationTime
      registrationTokenOperation: 'Update'
    }
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;enablerdsaadauth:i:1'
    // Explicación de propiedades RDP:
    // - drivestoredirect: No redirigir drives locales (seguridad)
    // - audiomode:0: Reproducir audio en sesión remota
    // - videoplaybackmode:1: Usar GPU para video
    // - redirectclipboard:1: Habilitar portapapeles
    // - redirectprinters:0: No redirigir impresoras
    // - redirectcomports:0: No redirigir puertos COM
    // - redirectsmartcards:0: No redirigir tarjetas inteligentes
    // - usbdevicestoredirect: No redirigir USB
    // - enablecredsspsupport:1: Habilitar CredSSP
    // - redirectwebauthn:1: Habilitar autenticación web
    // - use multimon:1: Soportar múltiples monitores
    // - enablerdsaadauth:1: Autenticación Azure AD
  }
}

// ============================================================================
// DIAGNOSTIC SETTINGS - Host Pool
// ============================================================================

resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'hostpool-diagnostics'
  scope: hostPool
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Error'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Management'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Connection'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'HostRegistration'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AgentHealthStatus'
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
// APPLICATION GROUP - Desktop
// ============================================================================

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: appGroupName
  location: location
  tags: tags
  properties: {
    applicationGroupType: 'Desktop'
    hostPoolArmPath: hostPool.id
    friendlyName: 'Desktop Principal H100'
    description: 'Full desktop access para VM con GPU H100'
  }
}

// ============================================================================
// ROLE ASSIGNMENT - Asignar usuario a Application Group
// ============================================================================

// Desktop Virtualization User role (GUID estándar de Azure)
var desktopVirtualizationUserRoleId = '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'

resource userAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appGroup.id, avdUserObjectId, desktopVirtualizationUserRoleId)
  scope: appGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', desktopVirtualizationUserRoleId)
    principalId: avdUserObjectId
    principalType: 'User'
  }
}

// ============================================================================
// WORKSPACE
// ============================================================================

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    friendlyName: 'H100 VDI Workspace'
    description: 'Workspace para POC AVD con GPU NVIDIA H100'
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

// ============================================================================
// DIAGNOSTIC SETTINGS - Workspace
// ============================================================================

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'workspace-diagnostics'
  scope: workspace
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Error'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Management'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Feed'
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

output hostPoolId string = hostPool.id
output hostPoolName string = hostPool.name
output hostPoolRegistrationToken string = hostPool.properties.registrationInfo.token
output appGroupId string = appGroup.id
output appGroupName string = appGroup.name
output workspaceId string = workspace.id
output workspaceName string = workspace.name
