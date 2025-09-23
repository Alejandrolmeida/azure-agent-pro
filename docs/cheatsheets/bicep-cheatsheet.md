# Bicep Cheatsheet 🏗️

Guía completa de Azure Bicep con sintaxis, funciones, mejores prácticas y ejemplos listos para usar.

## 📑 Índice

- [Sintaxis Básica](#sintaxis-básica)
- [Parámetros](#parámetros)
- [Variables](#variables)
- [Recursos](#recursos)
- [Outputs](#outputs)
- [Módulos](#módulos)
- [Funciones Integradas](#funciones-integradas)
- [Expresiones Condicionales](#expresiones-condicionales)
- [Loops e Iteraciones](#loops-e-iteraciones)
- [Scope y Targeting](#scope-y-targeting)
- [Patrones Comunes](#patrones-comunes)
- [Mejores Prácticas](#mejores-prácticas)
- [Debugging](#debugging)

---

## 🔧 Sintaxis Básica

### Estructura de Archivo
```bicep
// Comentarios de línea
/* Comentarios de bloque */

// Metadata
@description('Descripción del template')
metadata description = 'Mi plantilla Bicep'

// Parámetros
@description('Nombre del recurso')
param resourceName string

// Variables
var resourceTags = {
  Environment: 'dev'
  Project: 'myapp'
}

// Recursos
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: resourceName
  location: resourceGroup().location
  // propiedades...
}

// Outputs
@description('Storage account ID')
output storageId string = storageAccount.id
```

### Tipos de Datos
```bicep
// String
param appName string = 'defaultapp'

// Int
param instanceCount int = 1

// Bool
param enableHttps bool = true

// Array
param allowedLocations array = ['eastus', 'westus']

// Object
param tags object = {
  Environment: 'dev'
  Owner: 'team'
}

// Secure string (para passwords)
@secure()
param adminPassword string
```

---

## 📝 Parámetros

### Decoradores de Parámetros
```bicep
@description('Descripción del parámetro')
@minLength(3)
@maxLength(24)
param storageAccountName string

@minValue(1)
@maxValue(10)
param instanceCount int = 2

@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@secure()
@description('Admin password for VM')
param adminPassword string

// Metadata personalizada
@metadata({
  description: 'The location for resources'
  strongType: 'location'
})
param location string = resourceGroup().location
```

### Parámetros Avanzados
```bicep
// Array con validación
@description('List of allowed IP ranges')
param allowedIpRanges array = [
  '10.0.0.0/8'
  '172.16.0.0/12'
  '192.168.0.0/16'
]

// Object con estructura específica
@description('VM configuration')
param vmConfig object = {
  size: 'Standard_B2s'
  diskSizeGB: 128
  osDisk: {
    createOption: 'FromImage'
    managedDisk: {
      storageAccountType: 'Premium_LRS'
    }
  }
}

// Parámetro condicional
@description('Enable backup only in production')
param enableBackup bool = environment == 'prod'
```

---

## 🔢 Variables

### Variables Básicas
```bicep
// String concatenation
var storageAccountName = '${prefix}${uniqueString(resourceGroup().id)}'

// Complex objects
var networkConfig = {
  vnetName: '${prefix}-vnet'
  subnets: [
    {
      name: 'default'
      addressPrefix: '10.0.1.0/24'
    }
    {
      name: 'app'
      addressPrefix: '10.0.2.0/24'
    }
  ]
}

// Conditional variables
var sku = environment == 'prod' ? 'Premium_LRS' : 'Standard_LRS'
var vmSize = instanceCount > 3 ? 'Standard_D4s_v3' : 'Standard_B2s'
```

### Variables Dinámicas
```bicep
// Using functions
var currentDateTime = utcNow()
var resourceSuffix = substring(uniqueString(resourceGroup().id), 0, 5)

// Complex logic
var storageConfig = {
  name: '${prefix}st${resourceSuffix}'
  sku: environment == 'prod' ? {
    name: 'Standard_GRS'
    tier: 'Standard'
  } : {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: environment != 'prod'
  }
}
```

---

## 🏗️ Recursos

### Sintaxis de Recursos
```bicep
// Sintaxis básica
resource resourceName 'resourceType@apiVersion' = {
  name: 'resource-name'
  location: location
  properties: {
    // propiedades específicas del recurso
  }
  tags: tags
}

// Con dependencias explícitas
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  dependsOn: [
    networkInterface
    storageAccount
  ]
  properties: {
    // configuración de VM
  }
}
```

### Recursos Anidados
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  
  // Recurso anidado
  resource blobService 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        enabled: true
        days: 7
      }
    }
    
    // Recurso anidado dentro de anidado
    resource container 'containers' = {
      name: 'data'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}
```

### Recursos Existentes
```bicep
// Referenciar recurso existente
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

// Usar en otro recurso
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: existingVnet
  name: 'new-subnet'
  properties: {
    addressPrefix: '10.0.3.0/24'
  }
}
```

---

## 📤 Outputs

### Outputs Básicos
```bicep
@description('Resource ID of the storage account')
output storageAccountId string = storageAccount.id

@description('Primary blob endpoint')
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Storage account keys')
@secure()
output storageKey string = storageAccount.listKeys().keys[0].value
```

### Outputs Complejos
```bicep
// Object output
@description('Network configuration details')
output networkInfo object = {
  vnetId: virtualNetwork.id
  vnetName: virtualNetwork.name
  subnets: [for (subnet, index) in subnets: {
    name: virtualNetwork.properties.subnets[index].name
    id: virtualNetwork.properties.subnets[index].id
    addressPrefix: virtualNetwork.properties.subnets[index].properties.addressPrefix
  }]
}

// Array output
@description('List of created resource IDs')
output resourceIds array = [
  storageAccount.id
  virtualNetwork.id
  keyVault.id
]

// Conditional output
@description('Load balancer public IP (only if created)')
output publicIp string = createPublicLoadBalancer ? publicIP.properties.ipAddress : ''
```

---

## 📦 Módulos

### Definición de Módulo
```bicep
// storage-module.bicep
@description('Storage account name')
param storageAccountName string

@description('Location for the storage account')
param location string = resourceGroup().location

@description('Storage account SKU')
param sku string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
}

output storageAccountId string = storageAccount.id
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
```

### Uso de Módulos
```bicep
// main.bicep
module storageModule 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    storageAccountName: 'mystorageaccount'
    location: location
    sku: 'Standard_GRS'
  }
}

// Usar outputs del módulo
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: 'myapp'
  location: location
  properties: {
    connectionStrings: {
      DefaultConnection: {
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageModule.outputs.storageAccountName}'
        type: 'Custom'
      }
    }
  }
}
```

### Módulos con Scope
```bicep
// Deploy a diferentes scopes
module rgModule 'modules/resourcegroup.bicep' = {
  name: 'rgDeployment'
  scope: subscription()
  params: {
    resourceGroupName: 'my-rg'
    location: 'eastus'
  }
}

module storageModule 'modules/storage.bicep' = {
  name: 'storageDeployment'
  scope: resourceGroup('my-rg')
  dependsOn: [
    rgModule
  ]
  params: {
    storageAccountName: 'mystorageaccount'
  }
}
```

---

## ⚙️ Funciones Integradas

### Funciones de String
```bicep
// String manipulation
var accountName = toLower('${prefix}${uniqueString(resourceGroup().id)}')
var displayName = toUpper(appName)
var shortName = substring(longName, 0, 8)
var fullName = concat(prefix, '-', appName, '-', environment)

// String functions with conditionals
var resourceName = empty(customName) ? 'default-name' : customName
var finalName = contains(resourceName, environment) ? resourceName : '${resourceName}-${environment}'
```

### Funciones de Array
```bicep
// Array operations
param locations array = ['eastus', 'westus', 'centralus']
param vmSizes array = ['Standard_B1s', 'Standard_B2s', 'Standard_D2s_v3']

var firstLocation = first(locations)
var lastSize = last(vmSizes)
var locationCount = length(locations)
var hasEastUS = contains(locations, 'eastus')

// Array manipulation
var allLocations = concat(locations, ['northeurope', 'westeurope'])
var primaryLocations = take(locations, 2)
var secondaryLocations = skip(locations, 2)
```

### Funciones de Object
```bicep
// Object operations
param config object = {
  database: {
    tier: 'Basic'
    size: '2GB'
  }
  storage: {
    type: 'Premium_LRS'
    size: '100GB'
  }
}

var dbTier = config.database.tier
var configKeys = keys(config)
var hasDatabase = contains(config, 'database')

// Union objects
var defaultConfig = {
  environment: 'dev'
  monitoring: true
}
var finalConfig = union(defaultConfig, config)
```

### Funciones de Deployment
```bicep
// Deployment context
var rgLocation = resourceGroup().location
var rgName = resourceGroup().name
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

// Unique identifiers
var uniqueId = uniqueString(resourceGroup().id)
var guid = newGuid()
var timestamp = utcNow()
var formattedTime = utcNow('yyyy-MM-dd-HH-mm')

// Reference functions
var existingStorage = reference(storageAccountId, '2023-01-01')
var storageKeys = listKeys(storageAccountId, '2023-01-01')
```

---

## 🔀 Expresiones Condicionales

### Recursos Condicionales
```bicep
@description('Create public IP for load balancer')
param createPublicIP bool = false

// Conditional resource creation
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (createPublicIP) {
  name: '${resourcePrefix}-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Use conditional resource
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-05-01' = {
  name: '${resourcePrefix}-lb'
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontendConfig'
        properties: createPublicIP ? {
          publicIPAddress: {
            id: publicIP.id
          }
        } : {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}
```

### Propiedades Condicionales
```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    // Conditional property
    networkAcls: enableNetworkRestrictions ? {
      defaultAction: 'Deny'
      virtualNetworkRules: virtualNetworkRules
      ipRules: ipRules
    } : {
      defaultAction: 'Allow'
    }
  }
}
```

---

## 🔄 Loops e Iteraciones

### For Loops en Arrays
```bicep
@description('List of storage accounts to create')
param storageAccounts array = [
  {
    name: 'storage1'
    sku: 'Standard_LRS'
  }
  {
    name: 'storage2'
    sku: 'Standard_GRS'
  }
]

// Create multiple resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = [for (storage, index) in storageAccounts: {
  name: '${storage.name}${uniqueString(resourceGroup().id, string(index))}'
  location: location
  sku: {
    name: storage.sku
  }
  kind: 'StorageV2'
}]

// Use index in loop
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = [for i in range(0, vmCount): {
  name: '${vmNamePrefix}-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    // más configuración...
  }
}]
```

### Loops con Objetos
```bicep
@description('Subnets configuration')
param subnets object = {
  frontend: {
    addressPrefix: '10.0.1.0/24'
    nsg: true
  }
  backend: {
    addressPrefix: '10.0.2.0/24'
    nsg: true
  }
  data: {
    addressPrefix: '10.0.3.0/24'
    nsg: false
  }
}

// Create subnets from object
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = [for (config, name) in items(subnets): {
  parent: virtualNetwork
  name: name
  properties: {
    addressPrefix: config.addressPrefix
    networkSecurityGroup: config.nsg ? {
      id: networkSecurityGroup[name].id
    } : null
  }
}]

// items() function converts object to array of key-value pairs
var subnetArray = items(subnets)
// Result: [{ key: 'frontend', value: { addressPrefix: '...', nsg: true } }, ...]
```

### Loops Anidados
```bicep
@description('Virtual networks configuration')
param vnets array = [
  {
    name: 'vnet1'
    addressSpace: '10.0.0.0/16'
    subnets: [
      { name: 'subnet1', prefix: '10.0.1.0/24' }
      { name: 'subnet2', prefix: '10.0.2.0/24' }
    ]
  }
  {
    name: 'vnet2'
    addressSpace: '10.1.0.0/16'
    subnets: [
      { name: 'subnet1', prefix: '10.1.1.0/24' }
    ]
  }
]

// Flatten array for all subnets across all vnets
var allSubnets = flatten([for vnet in vnets: [for subnet in vnet.subnets: {
  vnetName: vnet.name
  subnetName: subnet.name
  addressPrefix: subnet.prefix
}]])

// Create NSG for each subnet
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = [for subnet in allSubnets: {
  name: 'nsg-${subnet.vnetName}-${subnet.subnetName}'
  location: location
}]
```

---

## 🎯 Scope y Targeting

### Deployment Scopes
```bicep
// Subscription level deployment
targetScope = 'subscription'

param resourceGroupName string = 'my-rg'
param location string = 'eastus'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module storageModule 'modules/storage.bicep' = {
  name: 'storageDeployment'
  scope: resourceGroup
  params: {
    storageAccountName: 'mystorageaccount'
  }
}
```

```bicep
// Management Group level
targetScope = 'managementGroup'

resource policy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'my-policy'
  properties: {
    displayName: 'My Custom Policy'
    policyType: 'Custom'
    mode: 'All'
    // policy definition...
  }
}
```

```bicep
// Tenant level
targetScope = 'tenant'

resource managementGroup 'Microsoft.Management/managementGroups@2021-04-01' = {
  name: 'my-mg'
  properties: {
    displayName: 'My Management Group'
  }
}
```

### Cross-Scope References
```bicep
// Reference resource in different scope
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
}

// Use across scopes
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

// Grant access to key vault in different RG
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: existingKeyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}
```

---

## 🎨 Patrones Comunes

### Naming Convention Pattern
```bicep
@description('Resource prefix')
param prefix string = 'contoso'

@description('Environment')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location abbreviation mapping')
var locationAbbreviations = {
  eastus: 'eus'
  westus: 'wus'
  centralus: 'cus'
  eastus2: 'eus2'
  westeurope: 'weu'
  northeurope: 'neu'
}

var locationAbbr = locationAbbreviations[location]
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 5)

// Consistent naming pattern
var namingConvention = {
  resourceGroup: '${prefix}-${environment}-${locationAbbr}-rg'
  storageAccount: '${prefix}${environment}${locationAbbr}st${uniqueSuffix}'
  keyVault: '${prefix}-${environment}-${locationAbbr}-kv-${uniqueSuffix}'
  appServicePlan: '${prefix}-${environment}-${locationAbbr}-asp'
  webApp: '${prefix}-${environment}-${locationAbbr}-web'
  virtualNetwork: '${prefix}-${environment}-${locationAbbr}-vnet'
  subnet: '${prefix}-${environment}-${locationAbbr}-subnet'
  nsg: '${prefix}-${environment}-${locationAbbr}-nsg'
}
```

### Configuration Pattern
```bicep
@description('Environment-specific configuration')
var environmentConfig = {
  dev: {
    skuName: 'F1'
    skuTier: 'Free'
    instanceCount: 1
    storageReplication: 'Standard_LRS'
    backupEnabled: false
    monitoringEnabled: false
  }
  test: {
    skuName: 'S1'
    skuTier: 'Standard'
    instanceCount: 1
    storageReplication: 'Standard_LRS'
    backupEnabled: true
    monitoringEnabled: true
  }
  prod: {
    skuName: 'P1V2'
    skuTier: 'PremiumV2'
    instanceCount: 3
    storageReplication: 'Standard_GRS'
    backupEnabled: true
    monitoringEnabled: true
  }
}

var currentConfig = environmentConfig[environment]
```

### Resource Factory Pattern
```bicep
// Define standard resource configurations
var resourceDefaults = {
  tags: {
    Environment: environment
    Project: projectName
    CostCenter: costCenter
    CreatedBy: 'bicep'
    CreatedDate: utcNow('yyyy-MM-dd')
  }
  storageAccount: {
    sku: currentConfig.storageReplication
    kind: 'StorageV2'
    properties: {
      supportsHttpsTrafficOnly: true
      minimumTlsVersion: 'TLS1_2'
      allowBlobPublicAccess: false
      encryption: {
        keySource: 'Microsoft.Storage'
        services: {
          blob: { enabled: true }
          file: { enabled: true }
        }
      }
    }
  }
}

// Apply defaults to resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: namingConvention.storageAccount
  location: location
  tags: resourceDefaults.tags
  sku: {
    name: resourceDefaults.storageAccount.sku
  }
  kind: resourceDefaults.storageAccount.kind
  properties: resourceDefaults.storageAccount.properties
}
```

---

## ✅ Mejores Prácticas

### Estructura y Organización
```bicep
// 1. Use metadata for documentation
metadata description = 'Creates a complete web application infrastructure'
metadata author = 'DevOps Team'
metadata version = '1.0.0'

// 2. Group related parameters
@description('Application Configuration')
param appConfig object = {
  name: 'myapp'
  version: '1.0.0'
  environment: 'dev'
}

@description('Network Configuration')
param networkConfig object = {
  addressSpace: '10.0.0.0/16'
  subnets: [
    { name: 'web', prefix: '10.0.1.0/24' }
    { name: 'data', prefix: '10.0.2.0/24' }
  ]
}

// 3. Use descriptive variable names
var webAppServicePlanName = '${appConfig.name}-${appConfig.environment}-asp'
var applicationInsightsName = '${appConfig.name}-${appConfig.environment}-ai'
var keyVaultNameForSecrets = '${appConfig.name}-${appConfig.environment}-kv-secrets'
```

### Seguridad
```bicep
// 1. Always use @secure() for sensitive data
@secure()
@description('Database admin password')
param databaseAdminPassword string

@secure()
@description('Application secrets')
param applicationSecrets object

// 2. Use Key Vault references
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroup)
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'DatabaseConnectionString'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=db-connection)'
        }
      ]
    }
  }
}

// 3. Use Managed Identity
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

// Grant Key Vault access
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: ['get']
        }
      }
    ]
  }
}
```

### Performance y Costo
```bicep
// 1. Use appropriate SKUs based on environment
var skuMapping = {
  dev: 'Basic'
  test: 'Standard'
  prod: 'Premium'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuMapping[environment]
    tier: skuMapping[environment]
  }
}

// 2. Implement cost controls
resource budgetAlert 'Microsoft.Consumption/budgets@2021-10-01' = if (environment == 'prod') {
  name: 'monthly-budget'
  properties: {
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: utcNow('yyyy-MM-01')
    }
    amount: 1000
    category: 'Cost'
    notifications: {
      actual: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: ['admin@company.com']
      }
    }
  }
}
```

### Error Handling
```bicep
// 1. Validate parameters
@description('VM size must be appropriate for environment')
@allowed([
  'Standard_B1s'
  'Standard_B2s'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
])
param vmSize string = environment == 'prod' ? 'Standard_D2s_v3' : 'Standard_B1s'

// 2. Use try-catch pattern with conditional logic
var storageAccountExists = !empty(filter(existingStorageAccounts, account => account.name == storageAccountName))
var useExistingStorage = storageAccountExists && reuseExistingResources

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = if (!useExistingStorage) {
  name: storageAccountName
  location: location
  // properties...
}

// 3. Provide meaningful error messages through validation
param subnetAddressPrefix string = '10.0.1.0/24'

// Custom validation
var isValidCidr = length(split(subnetAddressPrefix, '/')) == 2
var cidrSuffix = int(split(subnetAddressPrefix, '/')[1])
var isValidSuffix = cidrSuffix >= 8 && cidrSuffix <= 30

// Use in conditional logic or fail early
var validatedSubnetPrefix = isValidCidr && isValidSuffix ? subnetAddressPrefix : error('Invalid CIDR notation for subnet')
```

---

## 🐛 Debugging

### Debugging Techniques
```bicep
// 1. Use outputs for debugging
@description('Debug: Show computed values')
output debugInfo object = {
  computedStorageName: storageAccountName
  environmentConfig: currentConfig
  namingConvention: namingConvention
  resourceGroup: {
    id: resourceGroup().id
    location: resourceGroup().location
    name: resourceGroup().name
  }
  deployment: {
    name: deployment().name
    timestamp: utcNow()
  }
}

// 2. Conditional debugging outputs
@description('Enable detailed debugging output')
param enableDebug bool = false

output debugDetails object = enableDebug ? {
  allVariables: {
    prefix: prefix
    environment: environment
    uniqueSuffix: uniqueSuffix
    locationAbbr: locationAbbr
  }
  computedNames: namingConvention
  environmentConfig: currentConfig
} : {}

// 3. Validation outputs
output validation object = {
  parametersValid: {
    environmentIsValid: contains(['dev', 'test', 'prod'], environment)
    locationIsSupported: contains(keys(locationAbbreviations), location)
    prefixLength: length(prefix)
  }
  resourceNamesLength: {
    storageAccount: length(namingConvention.storageAccount)
    keyVault: length(namingConvention.keyVault)
    webApp: length(namingConvention.webApp)
  }
}
```

### Error Prevention
```bicep
// 1. Use assertions (when available)
// assert environment in ['dev', 'test', 'prod']
// assert length(prefix) >= 2 && length(prefix) <= 10

// 2. Fail early with clear messages
var errorChecks = {
  storageNameTooLong: length(namingConvention.storageAccount) > 24
  keyVaultNameTooLong: length(namingConvention.keyVault) > 24
  invalidEnvironment: !contains(['dev', 'test', 'prod'], environment)
}

var hasErrors = errorChecks.storageNameTooLong || errorChecks.keyVaultNameTooLong || errorChecks.invalidEnvironment

// Use in resource conditions
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = if (!hasErrors) {
  name: namingConvention.storageAccount
  // properties...
}

// Output error information
output deploymentErrors object = hasErrors ? {
  errors: [for (error, key) in items(errorChecks): error ? 'Error: ${key}' : '']
  suggestions: {
    shortenPrefix: errorChecks.storageNameTooLong ? 'Use shorter prefix (current: ${length(prefix)} chars)' : ''
    validEnvironments: errorChecks.invalidEnvironment ? 'Use: dev, test, or prod' : ''
  }
} : {}
```

---

## 🚀 Comandos CLI de Bicep

### Compilación y Validación
```bash
# Compilar Bicep a ARM JSON
az bicep build --file main.bicep

# Decompile ARM JSON to Bicep
az bicep decompile --file template.json

# Validar sintaxis
az bicep build --file main.bicep --stdout | jq .

# Generar archivo de parámetros
az bicep generate-params --file main.bicep --output-file params.json

# Formato de código
az bicep format --file main.bicep

# Linting
az bicep lint --file main.bicep
```

### Deployment
```bash
# Deploy con validación previa
az deployment group validate \
  --resource-group myRG \
  --template-file main.bicep \
  --parameters @params.json

# Deploy real
az deployment group create \
  --resource-group myRG \
  --template-file main.bicep \
  --parameters @params.json \
  --mode Incremental

# What-if deployment
az deployment group what-if \
  --resource-group myRG \
  --template-file main.bicep \
  --parameters @params.json
```

---

## 📚 Recursos Adicionales

- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Bicep GitHub Repository](https://github.com/Azure/bicep)
- [ARM Template Reference](https://docs.microsoft.com/en-us/azure/templates/)
- [Bicep Playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Resource Explorer](https://resources.azure.com/)

---

💡 **Tip**: Usa VS Code con la extensión Bicep para autocompletado, validación en tiempo real y snippets útiles.