// ============================================================================
// PARAMETERS FILE - POC Environment
// ============================================================================
// Configuración para despliegue del POC AVD H100 en Spain Central
// Subscription: POC AVD (36a06bba-6ca7-46f8-a1a8-4abbbebeee86)
// ============================================================================

using '../main.bicep'

// ============================================================================
// BASIC CONFIGURATION
// ============================================================================

param resourceGroupName = 'rg-avd-h100-poc'
param location = 'spaincentral'
param environment = 'poc'
param resourcePrefix = 'avdh100'

// ============================================================================
// VM CONFIGURATION
// ============================================================================

param vmSize = 'Standard_NC40ads_H100_v5'

// NOTA: Estos valores deben proporcionarse en runtime o mediante Azure KeyVault
// No incluir credenciales en este archivo
// Uso: az deployment sub create --parameters @poc.bicepparam --parameters vmAdminUsername='admin' vmAdminPassword='...'
param vmAdminUsername = 'azureadmin'
param vmAdminPassword = '' // Proporcionar en runtime

// ============================================================================
// AVD CONFIGURATION
// ============================================================================

// Object ID del usuario Azure AD que tendrá acceso al escritorio
// Obtener con: az ad user show --id usuario@dominio.com --query id -o tsv
param avdUserObjectId = '' // Proporcionar en runtime o reemplazar con tu Object ID

// ============================================================================
// NETWORK CONFIGURATION
// ============================================================================

// Tu IP pública en formato CIDR para acceso directo vía RDP (backup)
// Obtener con: curl ifconfig.me
// Formato: x.x.x.x/32
param allowedSourceIpAddress = '0.0.0.0/0' // CAMBIAR por tu IP específica

// ============================================================================
// AUTO-SHUTDOWN CONFIGURATION
// ============================================================================

param enableAutoShutdown = true
param idleMinutesThreshold = 15

// ============================================================================
// TAGS
// ============================================================================

param commonTags = {
  Environment: 'poc'
  Project: 'AVD-H100-POC'
  ManagedBy: 'Bicep-IaC'
  CostCenter: 'IT-Innovation'
  Owner: 'a.almeida@prodware.es'
  Criticality: 'Low'
  DataClassification: 'Internal'
}
