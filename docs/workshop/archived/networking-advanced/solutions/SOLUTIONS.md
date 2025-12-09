# 📝 Soluciones del Workshop - Azure Networking con GitHub Copilot

Este documento contiene soluciones de referencia para todos los ejercicios del workshop.

---

## 🔧 Módulo 1: Setup y Verificación de MCP Servers

### Ejercicio 1.1.1: Verificar Servidores MCP

**Prompt en Copilot Chat:**

```text
@workspace ¿Qué servidores MCP tienes disponibles?
```

**Respuesta esperada:**

Copilot debería listar 6 servidores:

1. **azure-mcp**: Acceso a Azure (VNETs, NSGs, VPN Gateway, etc.)
2. **bicep-mcp**: Asistencia con plantillas Bicep
3. **github-mcp**: Repos, issues, PRs
4. **filesystem-mcp**: Navegación optimizada del proyecto
5. **brave-search-mcp**: Búsqueda web
6. **memory-mcp**: Contexto persistente

---

### Ejercicio 1.1.2: Probar Azure MCP

**Prompt:**

```text
@workspace Usando Azure MCP, lista las redes virtuales en mi suscripción
```

**Comando generado (ejemplo):**

```bash
az network vnet list --output table
```

---

## 🏗️ Módulo 2: Diseño de Redes y Arquitecturas Hub-Spoke

### Ejercicio 2.2.1: Crear Módulo de VNET Hub

**Archivo:** `bicep/modules/vnet-hub.bicep`

```bicep
@description('Nombre de la VNET Hub')
param vnetName string

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('Rango de direcciones de la VNET')
param addressPrefix string = '10.0.0.0/16'

@description('Tags para los recursos')
param tags object = {}

// VNET Hub
resource vnetHub 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'ManagementSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.3.0/26'
        }
      }
    ]
  }
}

// Outputs
output vnetId string = vnetHub.id
output vnetName string = vnetHub.name
output firewallSubnetId string = vnetHub.properties.subnets[0].id
output gatewaySubnetId string = vnetHub.properties.subnets[1].id
output managementSubnetId string = vnetHub.properties.subnets[2].id
output bastionSubnetId string = vnetHub.properties.subnets[3].id
```

---

### Ejercicio 2.2.2: Crear Módulo de VNET Spoke

**Archivo:** `bicep/modules/vnet-spoke.bicep`

```bicep
@description('Nombre de la VNET Spoke')
param vnetName string

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('Rango de direcciones de la VNET')
param addressPrefix string

@description('Configuración de subnets')
param subnets array

@description('ID de la VNET Hub para peering')
param hubVnetId string

@description('Nombre del peering')
param peeringName string

@description('Tags para los recursos')
param tags object = {}

// VNET Spoke
resource vnetSpoke 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: contains(subnet, 'delegation') ? [
          {
            name: subnet.delegation
            properties: {
              serviceName: subnet.delegation
            }
          }
        ] : []
      }
    }]
  }
}

// Peering Spoke to Hub
resource peeringToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: vnetSpoke
  name: '${peeringName}-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Outputs
output vnetId string = vnetSpoke.id
output vnetName string = vnetSpoke.name
output subnets array = [for (subnet, i) in subnets: {
  name: subnet.name
  id: vnetSpoke.properties.subnets[i].id
}]
```

---

### Ejercicio 2.2.3: Orquestación con Main Bicep

**Archivo:** `bicep/main.bicep`

```bicep
targetScope = 'subscription'

@description('Ubicación principal de los recursos')
param location string = 'westeurope'

@description('Ambiente (dev, test, prod)')
param environment string

@description('Tags comunes para todos los recursos')
param commonTags object = {
  Environment: environment
  ManagedBy: 'Bicep'
  Project: 'AzureAgentPro'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-networking-${environment}'
  location: location
  tags: commonTags
}

// VNET Hub
module vnetHub 'modules/vnet-hub.bicep' = {
  scope: rg
  name: 'vnet-hub-deployment'
  params: {
    vnetName: 'vnet-hub-${environment}'
    location: location
    addressPrefix: '10.0.0.0/16'
    tags: commonTags
  }
}

// VNET Spoke 1 (Aplicaciones Web)
module vnetSpoke1 'modules/vnet-spoke.bicep' = {
  scope: rg
  name: 'vnet-spoke1-deployment'
  params: {
    vnetName: 'vnet-spoke1-${environment}'
    location: location
    addressPrefix: '10.1.0.0/16'
    hubVnetId: vnetHub.outputs.vnetId
    peeringName: 'spoke1'
    subnets: [
      {
        name: 'WebTier'
        addressPrefix: '10.1.1.0/24'
      }
      {
        name: 'AppTier'
        addressPrefix: '10.1.2.0/24'
      }
      {
        name: 'DataTier'
        addressPrefix: '10.1.3.0/24'
      }
    ]
    tags: union(commonTags, { Workload: 'WebApps' })
  }
}

// VNET Spoke 2 (Bases de Datos)
module vnetSpoke2 'modules/vnet-spoke.bicep' = {
  scope: rg
  name: 'vnet-spoke2-deployment'
  params: {
    vnetName: 'vnet-spoke2-${environment}'
    location: location
    addressPrefix: '10.2.0.0/16'
    hubVnetId: vnetHub.outputs.vnetId
    peeringName: 'spoke2'
    subnets: [
      {
        name: 'DatabaseTier'
        addressPrefix: '10.2.1.0/24'
      }
      {
        name: 'AnalyticsTier'
        addressPrefix: '10.2.2.0/24'
      }
    ]
    tags: union(commonTags, { Workload: 'Databases' })
  }
}

// Peering Hub to Spoke 1
module peeringHubToSpoke1 'modules/vnet-peering.bicep' = {
  scope: rg
  name: 'peering-hub-to-spoke1'
  params: {
    localVnetName: vnetHub.outputs.vnetName
    remoteVnetId: vnetSpoke1.outputs.vnetId
    peeringName: 'hub-to-spoke1'
    allowGatewayTransit: true
  }
  dependsOn: [
    vnetHub
    vnetSpoke1
  ]
}

// Peering Hub to Spoke 2
module peeringHubToSpoke2 'modules/vnet-peering.bicep' = {
  scope: rg
  name: 'peering-hub-to-spoke2'
  params: {
    localVnetName: vnetHub.outputs.vnetName
    remoteVnetId: vnetSpoke2.outputs.vnetId
    peeringName: 'hub-to-spoke2'
    allowGatewayTransit: true
  }
  dependsOn: [
    vnetHub
    vnetSpoke2
  ]
}

// Outputs
output hubVnetId string = vnetHub.outputs.vnetId
output spoke1VnetId string = vnetSpoke1.outputs.vnetId
output spoke2VnetId string = vnetSpoke2.outputs.vnetId
```

---

## 🔒 Módulo 3: Seguridad de Red

### Ejercicio 3.1.1: NSG para Aplicación de 3 Capas

**Archivo:** `bicep/modules/nsg-3tier.bicep`

```bicep
@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('Tags para los recursos')
param tags object = {}

// NSG para Web Tier
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-web-tier'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          description: 'Allow HTTPS from Internet'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          description: 'Allow HTTP from Internet'
        }
      }
      {
        name: 'AllowSSHFromManagement'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.0.2.0/24' // Management subnet
          destinationAddressPrefix: '*'
          description: 'Allow SSH from Management subnet'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// NSG para App Tier
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-app-tier'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowAppPortFromWeb'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '8090'
          ]
          sourceAddressPrefix: '10.1.1.0/24' // Web Tier subnet
          destinationAddressPrefix: '*'
          description: 'Allow app ports from Web Tier'
        }
      }
      {
        name: 'AllowSSHFromManagement'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.0.2.0/24' // Management subnet
          destinationAddressPrefix: '*'
          description: 'Allow SSH from Management subnet'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// NSG para DB Tier
resource nsgDb 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'nsg-db-tier'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSQLFromApp'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.1.2.0/24' // App Tier subnet
          destinationAddressPrefix: '*'
          description: 'Allow SQL Server from App Tier'
        }
      }
      {
        name: 'AllowPostgreSQLFromApp'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5432'
          sourceAddressPrefix: '10.1.2.0/24' // App Tier subnet
          destinationAddressPrefix: '*'
          description: 'Allow PostgreSQL from App Tier'
        }
      }
      {
        name: 'AllowSSHFromManagement'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.0.2.0/24' // Management subnet
          destinationAddressPrefix: '*'
          description: 'Allow SSH from Management subnet'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// Outputs
output nsgWebId string = nsgWeb.id
output nsgAppId string = nsgApp.id
output nsgDbId string = nsgDb.id
```

---

### Ejercicio 3.2.1: Desplegar Azure Firewall

**Archivo:** `bicep/modules/azure-firewall.bicep`

```bicep
@description('Nombre del Azure Firewall')
param firewallName string

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('ID de la subnet del firewall')
param firewallSubnetId string

@description('Nombre del Firewall Policy')
param policyName string

@description('Tags para los recursos')
param tags object = {}

// Public IP para Azure Firewall
resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${firewallName}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Azure Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-05-01' = {
  name: policyName
  location: location
  tags: tags
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
    }
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: firewallName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'firewallConfig'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPublicIP.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

// Outputs
output firewallId string = firewall.id
output firewallPrivateIP string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIP string = firewallPublicIP.properties.ipAddress
output policyId string = firewallPolicy.id
```

---

### Ejercicio 3.2.3: Route Tables

**Archivo:** `bicep/modules/route-table.bicep`

```bicep
@description('Nombre de la Route Table')
param routeTableName string

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('IP privada del Azure Firewall')
param firewallPrivateIP string

@description('Deshabilitar propagación de rutas BGP')
param disableBgpRoutePropagation bool = false

@description('Tags para los recursos')
param tags object = {}

// Route Table
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: [
      {
        name: 'route-to-internet-via-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
      {
        name: 'route-to-spoke1-via-firewall'
        properties: {
          addressPrefix: '10.1.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
      {
        name: 'route-to-spoke2-via-firewall'
        properties: {
          addressPrefix: '10.2.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
    ]
  }
}

// Output
output routeTableId string = routeTable.id
```

---

## 🌐 Módulo 4: Conectividad Híbrida

### Ejercicio 4.1.1: VPN Gateway

**Archivo:** `bicep/modules/vpn-gateway.bicep`

```bicep
@description('Nombre del VPN Gateway')
param gatewayName string

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('ID de la Gateway Subnet')
param gatewaySubnetId string

@description('SKU del VPN Gateway')
@allowed([
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
])
param gatewaySku string = 'VpnGw2'

@description('Habilitar modo Active-Active')
param enableActiveActive bool = true

@description('Número de ASN para BGP')
param asn int = 65515

@description('Tags para los recursos')
param tags object = {}

// Public IP 1
resource publicIP1 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${gatewayName}-pip1'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Public IP 2 (para Active-Active)
resource publicIP2 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableActiveActive) {
  name: '${gatewayName}-pip2'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: gatewayName
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    activeActive: enableActiveActive
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    bgpSettings: {
      asn: asn
    }
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: publicIP1.id
          }
        }
      }
      {
        name: 'ipConfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: enableActiveActive ? {
            id: publicIP2.id
          } : null
        }
      }
    ]
  }
}

// Outputs
output gatewayId string = vpnGateway.id
output gatewayPublicIP1 string = publicIP1.properties.ipAddress
output gatewayPublicIP2 string = enableActiveActive ? publicIP2.properties.ipAddress : ''
output bgpPeeringAddress string = vpnGateway.properties.bgpSettings.bgpPeeringAddress
```

---

### Ejercicio 4.1.2: Local Network Gateway

**Archivo:** `bicep/modules/local-network-gateway.bicep`

```bicep
@description('Nombre del Local Network Gateway')
param localGatewayName string

@description('Ubicación de los recursos')
param location string = resourceGroup().location

@description('IP pública del gateway local')
param gatewayIpAddress string

@description('Rangos de direcciones de la red local')
param addressPrefixes array

@description('Habilitar BGP')
param enableBgp bool = true

@description('ASN BGP del gateway local')
param bgpAsn int = 65001

@description('IP del peer BGP')
param bgpPeeringAddress string

@description('Tags para los recursos')
param tags object = {}

// Local Network Gateway
resource localGateway 'Microsoft.Network/localNetworkGateways@2023-05-01' = {
  name: localGatewayName
  location: location
  tags: tags
  properties: {
    gatewayIpAddress: gatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: addressPrefixes
    }
    bgpSettings: enableBgp ? {
      asn: bgpAsn
      bgpPeeringAddress: bgpPeeringAddress
    } : null
  }
}

// Output
output localGatewayId string = localGateway.id
```

---

## 📊 Módulo 5: Monitorización y Troubleshooting

### Ejercicio 5.1.1: Habilitar Network Watcher

**Script:** `scripts/enable-network-watcher.sh`

```bash
#!/bin/bash

# Script para habilitar Network Watcher en todas las regiones

set -e

echo "🔍 Habilitando Network Watcher en todas las regiones activas..."

# Obtener lista de regiones activas
regions=$(az account list-locations --query "[?metadata.regionType=='Physical'].name" -o tsv)

# Resource group para Network Watcher
rg_name="NetworkWatcherRG"

# Crear resource group si no existe
if ! az group show --name "$rg_name" &>/dev/null; then
    echo "Creando resource group $rg_name..."
    az group create --name "$rg_name" --location "westeurope"
fi

# Habilitar Network Watcher en cada región
for region in $regions; do
    echo "Verificando Network Watcher en región: $region"
    
    # Verificar si ya existe
    if ! az network watcher show --resource-group "$rg_name" --name "NetworkWatcher_$region" &>/dev/null; then
        echo "  ✅ Habilitando Network Watcher en $region..."
        az network watcher configure \
            --resource-group "$rg_name" \
            --locations "$region" \
            --enabled true
    else
        echo "  ℹ️  Network Watcher ya habilitado en $region"
    fi
done

echo "✅ Network Watcher habilitado en todas las regiones"
```

---

### Ejercicio 5.2.2: Workbooks y Dashboards

**Queries KQL:**

**1. Top 10 IPs por tráfico denegado en NSG:**

```kql
AzureNetworkAnalytics_CL
| where SubType_s == "FlowLog"
| where FlowStatus_s == "D" // Denied
| summarize DeniedCount = count() by SrcIP_s
| top 10 by DeniedCount desc
| render barchart
```

**2. Conexiones VPN activas:**

```kql
AzureDiagnostics
| where Category == "GatewayDiagnosticLog"
| where OperationName == "DiagnosticLog"
| where Message contains "connected"
| summarize ActiveConnections = dcount(instance_s) by bin(TimeGenerated, 5m)
| render timechart
```

**3. Tráfico bloqueado por Azure Firewall:**

```kql
AzureDiagnostics
| where Category == "AzureFirewallApplicationRule" or Category == "AzureFirewallNetworkRule"
| where msg_s contains "Deny"
| extend Reason = extract("Reason: ([^.]+)", 1, msg_s)
| summarize Count = count() by Reason
| render piechart
```

**4. Failed connection attempts por origen:**

```kql
AzureNetworkAnalytics_CL
| where SubType_s == "FlowLog"
| where FlowStatus_s == "D"
| summarize FailedAttempts = count() by SrcIP_s, DestPort_s
| where FailedAttempts > 100
| order by FailedAttempts desc
| take 20
```

---

## 🎁 Bonus: GitHub Actions Workflow

**Archivo:** `.github/workflows/deploy-network.yml`

```yaml
name: Deploy Azure Networking Infrastructure

on:
  push:
    branches: [main]
    paths:
      - 'bicep/**'
  pull_request:
    branches: [main]
    paths:
      - 'bicep/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy (dev/prod)'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - prod

permissions:
  id-token: write
  contents: read

env:
  AZURE_RESOURCE_GROUP: 'rg-networking-${{ github.event.inputs.environment || 'dev' }}'
  LOCATION: 'westeurope'

jobs:
  validate:
    name: Validate Bicep Templates
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Bicep Build
        run: |
          az bicep build --file bicep/main.bicep

      - name: What-If Analysis
        run: |
          az deployment sub what-if \
            --location ${{ env.LOCATION }} \
            --template-file bicep/main.bicep \
            --parameters bicep/parameters/${{ github.event.inputs.environment || 'dev' }}.bicepparam

  deploy-dev:
    name: Deploy to Development
    needs: validate
    if: github.event_name == 'push' || (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'dev')
    runs-on: ubuntu-latest
    environment: development
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Infrastructure
        id: deploy
        run: |
          az deployment sub create \
            --name "networking-$(date +%Y%m%d-%H%M%S)" \
            --location ${{ env.LOCATION }} \
            --template-file bicep/main.bicep \
            --parameters bicep/parameters/dev.bicepparam \
            --output json > deployment-output.json
          
          echo "deployment_name=$(jq -r '.name' deployment-output.json)" >> $GITHUB_OUTPUT

      - name: Post-Deployment Tests
        run: |
          chmod +x scripts/test-network-deployment.sh
          ./scripts/test-network-deployment.sh dev

      - name: Upload Deployment Logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: deployment-logs-dev
          path: deployment-output.json

  deploy-prod:
    name: Deploy to Production
    needs: validate
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'prod'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Infrastructure
        id: deploy
        run: |
          az deployment sub create \
            --name "networking-prod-$(date +%Y%m%d-%H%M%S)" \
            --location ${{ env.LOCATION }} \
            --template-file bicep/main.bicep \
            --parameters bicep/parameters/prod.bicepparam \
            --output json > deployment-output.json

      - name: Post-Deployment Tests
        run: |
          chmod +x scripts/test-network-deployment.sh
          ./scripts/test-network-deployment.sh prod

      - name: Upload Deployment Logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: deployment-logs-prod
          path: deployment-output.json
```

---

## 📚 Recursos Adicionales

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Networking Best Practices](https://learn.microsoft.com/azure/architecture/framework/networking/)
- [Azure Firewall Documentation](https://learn.microsoft.com/azure/firewall/)
- [VPN Gateway Documentation](https://learn.microsoft.com/azure/vpn-gateway/)

---

**¡Felicidades por completar el workshop! 🎉**
