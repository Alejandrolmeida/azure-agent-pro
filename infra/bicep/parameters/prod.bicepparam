using '../main.bicep'

// Environment configuration
param location = 'westcentralus'
param environment = 'prod'
param projectName = 'pix4d-avd'

// VM Configuration
param vmSku = 'Standard_NV36ads_A10_v5' // Full power for production
param sessionHostCount = 20 // More hosts for production
param dataDiskSizeGB = 512 // Larger disk for production datasets

// AVD Settings
param enableStartVmOnConnect = true
param idleDeallocateMinutes = 30
param classWindow = '08:00-20:00' // Longer class hours

// Storage
param fslogixShareTier = 'Premium_ZRS' // Zone redundancy for production
param fslogixShareQuotaGB = 2048 // Larger for production

// Authentication
param enableAADJoin = true
param domainToJoin = ''
param ouPath = ''

// Image Builder
param buildCustomImage = false // Will be set to true in CI/CD
param customImageId = '' // Will be populated from image build pipeline

// Admin Credentials (from Key Vault in production)
param adminUsername = 'avdadmin'
// adminPassword - from Key Vault

// Notification
param notificationEmail = 'operations@example.com' // Change this!

// Network Configuration
param vnetAddressPrefix = '10.100.0.0/16'
param sessionHostsSubnetPrefix = '10.100.1.0/24'
param privateEndpointsSubnetPrefix = '10.100.2.0/24'
param aibSubnetPrefix = '10.100.3.0/24'

// Tags
param tags = {
  env: 'prod'
  project: 'fotogrametria-azure-ia'
  costCenter: 'training'
  managedBy: 'bicep'
  purpose: 'pix4d-production'
  criticality: 'high'
}
