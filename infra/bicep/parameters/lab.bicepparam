using '../main.bicep'

// Environment configuration
param location = 'westcentralus'
param environment = 'lab'
param projectName = 'pix4d-avd'

// VM Configuration
param vmSku = 'Standard_NV18ads_A10_v5' // Cheaper for dev/testing
param sessionHostCount = 3 // Fewer hosts for lab
param dataDiskSizeGB = 256 // Smaller disk for lab

// AVD Settings
param enableStartVmOnConnect = true
param idleDeallocateMinutes = 15 // Shorter for lab (faster cost savings)
param classWindow = '16:00-21:00'

// Storage
param fslogixShareTier = 'Premium_LRS'
param fslogixShareQuotaGB = 512 // Smaller for lab

// Authentication
param enableAADJoin = true
param domainToJoin = ''
param ouPath = ''

// Image Builder
param buildCustomImage = false // Set to true when you want to build the image
param customImageId = '' // Will be populated after first image build

// Admin Credentials (will be prompted or from Key Vault)
param adminUsername = 'avdadmin'
// adminPassword - will be prompted at deployment

// Notification
param notificationEmail = 'admin@example.com' // Change this!

// Network Configuration
param vnetAddressPrefix = '10.100.0.0/16'
param sessionHostsSubnetPrefix = '10.100.1.0/24'
param privateEndpointsSubnetPrefix = '10.100.2.0/24'
param aibSubnetPrefix = '10.100.3.0/24'

// Tags
param tags = {
  env: 'lab'
  project: 'fotogrametria-azure-ia'
  costCenter: 'training'
  managedBy: 'bicep'
  purpose: 'pix4d-learning'
}
