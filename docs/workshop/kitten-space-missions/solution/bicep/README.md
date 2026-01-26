# 🚀 Kitten Space Missions - Infraestructura Azure con Bicep

![Azure](https://img.shields.io/badge/Azure-Infrastructure-0078D4?logo=microsoftazure)
![Bicep](https://img.shields.io/badge/Bicep-IaC-0078D4)
![Status](https://img.shields.io/badge/Status-Ready-success)

Infraestructura como código (IaC) para la API de Kitten Space Missions, implementando el **Scenario B (Balanced)** del análisis FinOps con arquitectura Azure Well-Architected.

---

## 📑 Tabla de Contenidos

- [Estructura de Archivos](#-estructura-de-archivos)
- [Arquitectura](#-arquitectura)
- [Naming Conventions](#-naming-conventions)
- [Variables de Entorno](#-variables-de-entorno)
- [Comandos de Validación](#-comandos-de-validación)
- [Deployment](#-deployment)
- [Troubleshooting](#-troubleshooting)
- [Costos Estimados](#-costos-estimados)
- [Referencias](#-referencias)

---

## 📂 Estructura de Archivos

```
bicep/
├── main.bicep                      # Orquestador principal (targetScope: subscription)
├── parameters/
│   ├── dev.parameters.json         # Parámetros para entorno Development
│   └── prod.parameters.json        # Parámetros para entorno Production (template)
└── modules/
    ├── networking.bicep            # VNet, Subnets, NSG
    ├── app-service.bicep           # App Service + Plan con VNet integration
    ├── sql-database.bicep          # SQL Server + Database con TDE
    ├── key-vault.bicep             # Key Vault con RBAC y soft delete
    ├── private-endpoint.bicep      # Private Endpoint genérico reutilizable
    ├── monitoring.bicep            # Application Insights + Log Analytics + Alerts
    ├── rbac.bicep                  # RBAC assignments para Managed Identities
    └── key-vault-secret.bicep      # Helper para crear secrets en Key Vault
```

### Responsabilidad de cada Módulo

#### 🎯 `main.bicep`
**Orquestador principal** que coordina el despliegue de todos los recursos.

- **Target Scope**: Subscription (crea Resource Group)
- **Responsabilidades**:
  - Crear Resource Group
  - Orquestar despliegue de módulos en orden correcto
  - Gestionar dependencias entre módulos
  - Exponer outputs importantes (URLs, connection strings, IDs)

#### 🌐 `modules/networking.bicep`
**Infraestructura de red** con arquitectura hub-spoke simplificada.

- **Recursos**:
  - Virtual Network (10.0.0.0/16)
  - Subnet para App Service (10.0.1.0/24) con delegación
  - Subnet para Private Endpoints (10.0.2.0/24)
  - Network Security Group con reglas mínimas
  - Service Endpoints (SQL, Key Vault)
- **Seguridad**: NSG con deny-all default, allow solo HTTPS/HTTP

#### 🌍 `modules/app-service.bicep`
**Hosting de la API** con integración de red privada.

- **Recursos**:
  - App Service Plan B1 (Linux)
  - App Service con Managed Identity
  - VNet Integration configurada
  - Application Settings con Key Vault references
- **Características**:
  - HTTPS only, TLS 1.2 mínimo
  - Always On habilitado
  - Diagnostic settings a Log Analytics
  - Connection strings desde Key Vault

#### 🗄️ `modules/sql-database.bicep`
**Base de datos** con seguridad enterprise.

- **Recursos**:
  - SQL Server con autenticación AAD
  - SQL Database Basic (2GB)
  - Transparent Data Encryption (TDE) habilitado
  - Diagnostic settings para auditoría
- **Seguridad**:
  - Public network access: Disabled
  - Solo accesible vía Private Endpoint
  - TLS 1.2 mínimo
  - Backup automático (retention: 7 días Basic)

#### 🔐 `modules/key-vault.bicep`
**Gestión de secretos** centralizada.

- **Recursos**:
  - Key Vault Standard
  - Soft delete habilitado (90 días)
  - Purge protection habilitado
  - RBAC authorization mode
- **Configuración**:
  - Diagnostic settings para auditoría
  - Network ACLs (preparado para Private Endpoint)
  - Access policies vía RBAC (no legacy)

#### 🔗 `modules/private-endpoint.bicep`
**Conectividad privada** reutilizable para servicios PaaS.

- **Recursos**:
  - Private Endpoint
  - Private DNS Zone
  - DNS Zone Group (auto-registration)
- **Uso**: Módulo genérico parametrizable para cualquier servicio PaaS

#### 📊 `modules/monitoring.bicep`
**Observabilidad** completa de la plataforma.

- **Recursos**:
  - Log Analytics Workspace
  - Application Insights (linked a Log Analytics)
  - Action Group para notificaciones
  - Alert Rules:
    - HTTP 5xx > 10 en 5 minutos
    - Response time p95 > 500ms
    - Failed requests > 20%
- **Configuración**:
  - Retention: 30 días (dev) / 90 días (prod)
  - Email notifications al Action Group

#### 🛡️ `modules/rbac.bicep`
**Permisos mínimos** siguiendo principio de Least Privilege.

- **Role Assignments**:
  - App Service → Key Vault (Key Vault Secrets User)
  - App Service → SQL Server (SQL DB Contributor)
- **Modelo**: RBAC con Built-in Roles de Azure

#### 🔑 `modules/key-vault-secret.bicep`
**Helper** para creación de secretos en Key Vault.

- **Uso**: Módulo auxiliar para almacenar connection strings y passwords
- **Seguridad**: Parámetros `@secure()` para valores sensibles

---

## 🏗️ Arquitectura

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                         SUBSCRIPTION                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              Resource Group: rg-kitten-missions-dev       │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────┐    │  │
│  │  │  VNet: vnet-kitten-missions-dev (10.0.0.0/16)    │    │  │
│  │  │                                                   │    │  │
│  │  │  ┌────────────────────────────────────────┐      │    │  │
│  │  │  │ Subnet: App Service (10.0.1.0/24)     │      │    │  │
│  │  │  │ ┌────────────────────────────────┐    │      │    │  │
│  │  │  │ │ App Service (with Managed ID)  │────┼──────┼────┼──┐
│  │  │  │ │ app-kitten-missions-dev        │    │      │    │  │
│  │  │  │ └────────────────────────────────┘    │      │    │  │
│  │  │  └────────────────────────────────────────┘      │    │  │
│  │  │                                                   │    │  │
│  │  │  ┌────────────────────────────────────────┐      │    │  │
│  │  │  │ Subnet: Private Endpoints (10.0.2.0/24)│      │    │  │
│  │  │  │ ┌────────────────────────────────┐    │      │    │  │
│  │  │  │ │ Private Endpoint (SQL)         │─────┼──┐   │    │  │
│  │  │  │ └────────────────────────────────┘    │  │   │    │  │
│  │  │  └────────────────────────────────────────┘  │   │    │  │
│  │  └──────────────────────────────────────────────┼───┘    │  │
│  │                                                  │        │  │
│  │  ┌───────────────────────────────────┐          │        │  │
│  │  │ SQL Server + Database             │◄─────────┘        │  │
│  │  │ sql-kitten-missions-dev-xxxxx     │                   │  │
│  │  │ (Public Access: Disabled)         │                   │  │
│  │  └───────────────────────────────────┘                   │  │
│  │             ▲                                             │  │
│  │             │ RBAC: SQL DB Contributor                    │  │
│  │             │                                             │  │
│  │  ┌───────────────────────────────────┐                   │  │
│  │  │ Key Vault                         │◄──────────────────┘  │
│  │  │ kv-kitten-missions-dev-xxxxx      │                      │
│  │  │ (Secrets: SQL Connection String)  │                      │
│  │  └───────────────────────────────────┘                      │
│  │             ▲                                                │
│  │             │ RBAC: Key Vault Secrets User                  │
│  │                                                              │
│  │  ┌───────────────────────────────────┐                      │
│  │  │ Log Analytics Workspace           │                      │
│  │  │ log-kitten-missions-dev           │                      │
│  │  └───────────────────────────────────┘                      │
│  │             ▲                                                │
│  │             │ Diagnostic Settings                           │
│  │                                                              │
│  │  ┌───────────────────────────────────┐                      │
│  │  │ Application Insights              │                      │
│  │  │ appi-kitten-missions-dev          │                      │
│  │  └───────────────────────────────────┘                      │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de Datos

1. **Usuario** → App Service (HTTPS)
2. **App Service** → SQL Server (Private Endpoint)
3. **App Service** → Key Vault (obtener connection string)
4. **Todos los recursos** → Log Analytics (diagnostic logs)
5. **Application Insights** → Telemetría y métricas

---

## 🏷️ Naming Conventions

Seguimos las **Azure naming best practices** con prefijos estándar:

| Recurso | Formato | Ejemplo |
|---------|---------|---------|
| Resource Group | `rg-{project}-{env}` | `rg-kitten-missions-dev` |
| Virtual Network | `vnet-{project}-{env}` | `vnet-kitten-missions-dev` |
| Subnet | `snet-{purpose}` | `snet-appservice` |
| Network Security Group | `nsg-{project}-{env}` | `nsg-kitten-missions-dev` |
| App Service Plan | `asp-{project}-{env}` | `asp-kitten-missions-dev` |
| App Service | `app-{project}-{env}` | `app-kitten-missions-dev` |
| SQL Server | `sql-{project}-{env}-{unique}` | `sql-kitten-missions-dev-abc123` |
| SQL Database | `sqldb-{project}-{env}` | `sqldb-kitten-missions-dev` |
| Key Vault | `kv-{project}-{env}-{unique}` | `kv-kitten-missions-dev-abc123` |
| Private Endpoint | `pe-{project}-{service}-{env}` | `pe-kitten-missions-sql-dev` |
| Log Analytics | `log-{project}-{env}` | `log-kitten-missions-dev` |
| Application Insights | `appi-{project}-{env}` | `appi-kitten-missions-dev` |
| Action Group | `ag-{project}-{env}` | `ag-kitten-missions-dev` |

**Convenciones adicionales**:
- `{unique}` se genera con `uniqueString()` para garantizar nombres globalmente únicos
- Todos los nombres en minúsculas
- Separador: guion medio (`-`)
- Longitud máxima respetada según límites Azure

---

## 🔧 Variables de Entorno

### Requeridas para Deployment

#### 1. Azure CLI Autenticado

```bash
# Login a Azure
az login

# Seleccionar suscripción
az account set --subscription "<SUBSCRIPTION_ID>"
```

#### 2. SQL Admin Password

**⚠️ CRÍTICO**: Nunca guardar passwords en parámetros JSON sin protección.

**Opción A: Pasar como parámetro en línea de comandos**
```bash
export SQL_ADMIN_PASSWORD="YourSecurePassword123!"
```

**Opción B: Usar Key Vault Reference (RECOMENDADO)**

Primero, crear el secret:
```bash
# Crear Key Vault temporal para secrets de deployment
az keyvault create \
  --name "kv-deployment-secrets" \
  --resource-group "rg-shared" \
  --location westeurope

# Almacenar password
az keyvault secret set \
  --vault-name "kv-deployment-secrets" \
  --name "SqlAdminPassword" \
  --value "YourSecurePassword123!"
```

Luego, actualizar `parameters/dev.parameters.json`:
```json
{
  "sqlAdminPassword": {
    "reference": {
      "keyVault": {
        "id": "/subscriptions/{sub-id}/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-deployment-secrets"
      },
      "secretName": "SqlAdminPassword"
    }
  }
}
```

#### 3. Variables de Entorno Opcionales

```bash
# Región de Azure
export AZURE_LOCATION="westeurope"

# Entorno
export ENVIRONMENT="dev"

# Nombre del proyecto
export PROJECT_NAME="kitten-missions"
```

### Variables para CI/CD (GitHub Actions)

Si planeas automatizar el deployment con GitHub Actions:

```yaml
# .github/workflows/deploy-infrastructure.yml
env:
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}      # Service Principal
  SQL_ADMIN_PASSWORD: ${{ secrets.SQL_ADMIN_PASSWORD }}
```

---

## ✅ Comandos de Validación

### 1. Validar Sintaxis Bicep

```bash
# Validar archivo principal
az bicep build --file main.bicep

# Validar todos los módulos
for module in modules/*.bicep; do
  echo "Validating $module..."
  az bicep build --file "$module"
done
```

**Output esperado**: `✓ Compilation succeeded`

### 2. Linting (Estilo y Best Practices)

```bash
# Instalar Bicep linter (incluido en Azure CLI 2.20+)
az bicep lint --file main.bicep

# Ver warnings y sugerencias
az bicep lint --file main.bicep --diagnostics-format sarif
```

### 3. Validate Deployment (sin ejecutar)

```bash
# Validate a nivel de subscription
az deployment sub validate \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD"
```

**¿Qué hace?**
- Valida sintaxis Bicep
- Verifica permisos del usuario
- Comprueba que los recursos pueden crearse
- **NO** crea recursos reales

### 4. What-If Analysis (Preview de Cambios)

```bash
# Ver qué cambios se aplicarían
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD"
```

**Interpretación del output**:
- `+` (verde): Recurso se creará
- `~` (amarillo): Recurso se modificará
- `-` (rojo): Recurso se eliminará
- `*` (gris): Sin cambios

**Ejemplo de output**:
```
Resource changes: 12 to create, 0 to modify, 0 to delete.

+ Microsoft.Resources/resourceGroups/rg-kitten-missions-dev [2021-04-01]
+ Microsoft.Network/virtualNetworks/vnet-kitten-missions-dev [2023-05-01]
+ Microsoft.Sql/servers/sql-kitten-missions-dev-abc123 [2023-05-01-preview]
...
```

### 5. What-If con Formato Detallado

```bash
# Ver cambios en formato JSON detallado
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD" \
  --result-format FullResourcePayloads \
  --output json > what-if-output.json
```

---

## 🚀 Deployment

### Pre-requisitos

- [x] Azure CLI instalado (`az --version`)
- [x] Bicep CLI instalado (incluido en Azure CLI 2.20+)
- [x] Permisos en la suscripción: `Contributor` o `Owner`
- [x] SQL Admin Password definido

### Deployment a Dev

#### Paso 1: Verificar Contexto

```bash
# Confirmar suscripción activa
az account show --query "{Name:name, SubscriptionId:id, TenantId:tenantId}" -o table

# Listar resource groups existentes
az group list --query "[].{Name:name, Location:location}" -o table
```

#### Paso 2: Ejecutar What-If (Recomendado)

```bash
# Preview de cambios
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD"
```

**⚠️ REVISAR OUTPUT**: Asegúrate de que solo se crean recursos esperados.

#### Paso 3: Deployment Real

```bash
# Deployment con nombre único
DEPLOYMENT_NAME="kitten-missions-dev-$(date +%Y%m%d-%H%M%S)"

az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD"
```

**Duración estimada**: 10-15 minutos

#### Paso 4: Verificar Outputs

```bash
# Ver outputs del deployment
az deployment sub show \
  --name "$DEPLOYMENT_NAME" \
  --query properties.outputs -o json

# Extraer valores específicos
APP_URL=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query properties.outputs.appServiceUrl.value -o tsv)
echo "App Service URL: https://$APP_URL"

KV_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query properties.outputs.keyVaultName.value -o tsv)
echo "Key Vault Name: $KV_NAME"
```

### Deployment Incremental (Re-deploy)

Si necesitas actualizar recursos existentes:

```bash
# Re-ejecutar deployment (solo aplica cambios)
az deployment sub create \
  --name "kitten-missions-dev-update-$(date +%Y%m%d)" \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD"
```

**Comportamiento**:
- Recursos sin cambios: No se tocan
- Recursos modificados: Se actualizan (puede causar downtime)
- Recursos nuevos: Se crean
- Recursos eliminados del Bicep: **NO** se eliminan (modo incremental)

### Deployment Completo (Complete Mode)

**⚠️ PELIGRO**: Elimina recursos que no están en el template.

```bash
# NO USAR EN PRODUCCIÓN SIN VALIDACIÓN
az deployment sub create \
  --name "kitten-missions-dev-complete" \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD" \
  --mode Complete
```

---

## 🐛 Troubleshooting

### Errores Comunes

#### 1. Error: "Deployment template validation failed"

**Síntoma**:
```
ERROR: {'code': 'InvalidTemplateDeployment', 'message': 'The template deployment failed...'}
```

**Causas comunes**:
- Sintaxis Bicep incorrecta
- Parámetros faltantes
- Permisos insuficientes

**Solución**:
```bash
# Validar sintaxis
az bicep build --file main.bicep

# Validar deployment
az deployment sub validate \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --parameters sqlAdminPassword="test"
```

#### 2. Error: "The subscription is not registered to use namespace 'Microsoft.XXX'"

**Síntoma**:
```
ERROR: The subscription is not registered to use namespace 'Microsoft.Sql'
```

**Solución**:
```bash
# Registrar resource provider
az provider register --namespace Microsoft.Sql

# Verificar estado (tarda 2-5 minutos)
az provider show --namespace Microsoft.Sql --query "registrationState"
```

**Resource Providers necesarios**:
- `Microsoft.Network`
- `Microsoft.Web`
- `Microsoft.Sql`
- `Microsoft.KeyVault`
- `Microsoft.OperationalInsights`
- `Microsoft.Insights`

#### 3. Error: "Key Vault name already exists"

**Síntoma**:
```
ERROR: The vault name 'kv-kitten-missions-dev-abc123' is already in use
```

**Causa**: Key Vault con soft-delete habilitado aún existe (hasta 90 días después de eliminación).

**Solución A: Recuperar Key Vault eliminado**
```bash
# Listar Key Vaults eliminados
az keyvault list-deleted --query "[].{Name:name, Location:location, DeletionDate:properties.deletionDate}"

# Recuperar
az keyvault recover --name "kv-kitten-missions-dev-abc123"
```

**Solución B: Purge definitivo (requiere permisos)**
```bash
# Eliminar permanentemente
az keyvault purge --name "kv-kitten-missions-dev-abc123"
```

**Solución C: Cambiar nombre en parámetros**
```json
{
  "projectName": {
    "value": "kitten-missions-v2"
  }
}
```

#### 4. Error: "Private Endpoint creation failed"

**Síntoma**:
```
ERROR: The private endpoint could not be created in subnet 'snet-privateendpoints'
```

**Causa**: Private Endpoint Network Policies no deshabilitadas.

**Solución**:
```bash
# Verificar configuración del subnet
az network vnet subnet show \
  --resource-group rg-kitten-missions-dev \
  --vnet-name vnet-kitten-missions-dev \
  --name snet-privateendpoints \
  --query "{PrivateEndpointNetworkPolicies:privateEndpointNetworkPolicies}"

# Si no está 'Disabled', actualizar
az network vnet subnet update \
  --resource-group rg-kitten-missions-dev \
  --vnet-name vnet-kitten-missions-dev \
  --name snet-privateendpoints \
  --disable-private-endpoint-network-policies true
```

#### 5. Error: "SQL Connection failed from App Service"

**Síntoma**: App Service no puede conectar a SQL Database.

**Diagnóstico**:
```bash
# 1. Verificar Private Endpoint
az network private-endpoint list \
  --resource-group rg-kitten-missions-dev \
  --query "[].{Name:name, ConnectionState:privateLinkServiceConnections[0].privateLinkServiceConnectionState.status}"

# 2. Verificar DNS resolution
az network private-endpoint dns-zone-group list \
  --resource-group rg-kitten-missions-dev \
  --endpoint-name pe-kitten-missions-sql-dev

# 3. Verificar Managed Identity tiene permisos
az role assignment list \
  --assignee <APP_SERVICE_PRINCIPAL_ID> \
  --query "[].{Role:roleDefinitionName, Scope:scope}"
```

**Solución**:
- Verificar que Private Endpoint esté en estado "Approved"
- Confirmar que DNS Zone Group está configurado
- Añadir RBAC role si falta:
  ```bash
  az role assignment create \
    --assignee <APP_SERVICE_PRINCIPAL_ID> \
    --role "SQL DB Contributor" \
    --scope <SQL_SERVER_ID>
  ```

#### 6. Error: "Key Vault access denied for App Service"

**Síntoma**: App Service no puede leer secrets de Key Vault.

**Solución**:
```bash
# Verificar Managed Identity está habilitada
az webapp identity show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev

# Verificar RBAC role
az role assignment list \
  --scope <KEY_VAULT_ID> \
  --query "[?principalId=='<APP_SERVICE_PRINCIPAL_ID>'].{Role:roleDefinitionName}"

# Añadir role si falta
az role assignment create \
  --assignee <APP_SERVICE_PRINCIPAL_ID> \
  --role "Key Vault Secrets User" \
  --scope <KEY_VAULT_ID>
```

### Comandos de Diagnóstico

#### Ver logs de deployment

```bash
# Listar deployments recientes
az deployment sub list \
  --query "sort_by([].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}, &Timestamp)" \
  -o table

# Ver detalles de un deployment fallido
az deployment sub show \
  --name <DEPLOYMENT_NAME> \
  --query properties.error
```

#### Verificar estado de recursos

```bash
# Estado del Resource Group
az group show --name rg-kitten-missions-dev --query properties.provisioningState

# Estado de App Service
az webapp show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query "{State:state, DefaultHostName:defaultHostName, OutboundIpAddresses:outboundIpAddresses}"

# Estado de SQL Server
az sql server show \
  --name sql-kitten-missions-dev-xxxxx \
  --resource-group rg-kitten-missions-dev \
  --query "{State:state, FQDN:fullyQualifiedDomainName, PublicNetworkAccess:publicNetworkAccess}"
```

#### Test de conectividad

```bash
# Test App Service endpoint
curl -I https://app-kitten-missions-dev.azurewebsites.net

# Test SQL Server (desde VM en VNet o via Private Endpoint)
# Requiere sqlcmd instalado
sqlcmd -S sql-kitten-missions-dev-xxxxx.database.windows.net -d sqldb-kitten-missions-dev -G -U <AAD_USER>
```

---

## 💰 Costos Estimados

### Scenario B (Balanced) - Entorno Dev

| Recurso | SKU | Costo Mensual (EUR) |
|---------|-----|---------------------|
| App Service Plan | B1 Basic | ~13.14 EUR |
| SQL Database | Basic (2GB) | ~4.38 EUR |
| Key Vault | Standard | ~0.03 EUR (por transacción) |
| Log Analytics | Pay-as-you-go | ~5-10 EUR (aprox.) |
| Application Insights | Pay-as-you-go | Incluido con Log Analytics |
| VNet | Gratis | 0 EUR |
| Private Endpoint | Standard | ~6.57 EUR |
| **TOTAL ESTIMADO** | | **~29-35 EUR/mes** |

**Notas**:
- Precios basados en West Europe (enero 2026)
- Log Analytics varía según ingestion rate (5GB gratis/mes)
- Private Endpoint: ~6.57 EUR/mes + 0.00876 EUR/GB procesado
- No incluye transferencia de datos saliente

### Cost Optimization Tips

#### Dev/Test
```bash
# Auto-shutdown de App Service fuera de horario laboral
az webapp config appsettings set \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --settings WEBSITE_TIME_ZONE="W. Europe Standard Time"

# Usar Spot instances si aplica (no disponible en Basic)
```

#### Monitoreo de Costos
```bash
# Ver costos actuales
az consumption usage list \
  --start-date $(date -d '7 days ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceName, 'kitten-missions')].{Resource:instanceName, Cost:pretaxCost}" \
  -o table
```

---

## 📚 Referencias

### Documentación Oficial

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [App Service Best Practices](https://learn.microsoft.com/azure/app-service/deploy-best-practices)
- [SQL Database Security](https://learn.microsoft.com/azure/azure-sql/database/security-overview)
- [Key Vault Best Practices](https://learn.microsoft.com/azure/key-vault/general/best-practices)
- [Private Link Documentation](https://learn.microsoft.com/azure/private-link/)

### Azure Naming Conventions

- [Naming rules and restrictions](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules)
- [Recommended abbreviations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)

### Bicep Best Practices

- [Bicep file structure](https://learn.microsoft.com/azure/azure-resource-manager/bicep/file)
- [Bicep modules](https://learn.microsoft.com/azure/azure-resource-manager/bicep/modules)
- [Parameter files](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameter-files)

### Herramientas

- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
- [Bicep Playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Speed Test](https://www.azurespeed.com/)

---

## 🤝 Contribuir

Mejoras y sugerencias son bienvenidas. Si encuentras errores o tienes optimizaciones:

1. Crea un Issue describiendo el problema/mejora
2. Propone cambios vía Pull Request
3. Actualiza esta documentación si cambias recursos

---

## 📧 Soporte

Para preguntas sobre esta infraestructura:
- **Workshop**: [Kitten Space Missions Workshop](../README.md)
- **Proyecto**: azure-agent-pro
- **Autor**: Azure Architect Pro Agent

---

**Última actualización**: Enero 2026  
**Versión Bicep**: 0.24.x  
**Azure CLI**: 2.56.x

