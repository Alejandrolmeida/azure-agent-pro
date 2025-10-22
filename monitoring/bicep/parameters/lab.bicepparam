using '../main.monitoring.bicep'

// Environment Configuration
param location = 'westeurope'
param environment = 'lab'
param resourceGroupPrefix = 'rg-avd-pix4d'

// Log Analytics Configuration
param lawName = 'law-avd-pix4d-lab'
param dceName = 'dce-avd-pix4d-lab'
param dcrName = 'dcr-avd-windowsgpu-lab'

// Automation Configuration
param automationAccountName = 'aa-avd-pix4d-lab'
param costExportStorageAccountName = 'stcostavdpix4dlab'

// Alerting Configuration
param actionGroupName = 'ag-avd-pix4d-lab'
param actionGroupEmail = 'alejandro@azurebrains.com' // CHANGE THIS to your email

// AVD Configuration
param hostPoolResourceGroup = 'rg-avd-pix4d-lab'
param hostPoolName = 'avd-hostpool-lab'

// Schedule Configuration
param classWindow = '16:00-21:00' // UTC time
param idleDeallocateMinutes = 30

// Budget Configuration (Azure Sponsorship limits)
param monthlyBudgetAmount = 300 // EUR
param dailyBudgetAmount = 15    // EUR

// Feature Flags
param enableAlerts = true
param enableCostExports = true

// Resource Tags
param tags = {
  environment: 'lab'
  project: 'fotogrametria-azure-ia'
  managedBy: 'bicep'
  costCenter: 'training'
  owner: 'alejandro'
  deployment: 'monitoring-stack'
}

