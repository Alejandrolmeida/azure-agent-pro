// ============================================================================
// Parameters File: Production Environment
// ============================================================================
// BiciMAD Low Emission Router - DataSaturday Madrid 2025
// ============================================================================

using '../main.bicep'

// ============================================================================
// BASIC PARAMETERS
// ============================================================================

param projectName = 'bicimad'
param environment = 'prod'
param location = 'westeurope'

// ============================================================================
// TAGS
// ============================================================================

param tags = {
  Project: 'BiciMAD-Low-Emission-Router'
  Environment: 'Production'
  Hackathon: 'DataSaturday-Madrid-2025'
  ManagedBy: 'Bicep-IaC'
  CostCenter: 'Hackathon-Prod'
  Owner: 'OpsTeam'
  DeployedBy: 'GitHub-Actions'
  Criticality: 'High'
  DataClassification: 'Public'
}

// ============================================================================
// AZURE AD & SECURITY
// ============================================================================

// TODO: Reemplazar con el Object ID del usuario o service principal que tendrá acceso a Key Vault
param keyVaultAdminObjectId = '<REPLACE-WITH-YOUR-OBJECT-ID>'

// ============================================================================
// MONITORING
// ============================================================================

param enableMonitoring = true
param logRetentionDays = 90 // Mayor retención en producción

// ============================================================================
// AZURE MAPS API KEY (OPCIONAL)
// ============================================================================

// Si no se proporciona, se usará la primary key generada por Azure Maps
param azureMapsApiKey = ''
