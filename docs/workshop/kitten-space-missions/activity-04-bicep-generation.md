# 🏗️ Actividad 4: Generación de Código Bicep

**⏱️ Duración estimada**: 45 minutos  
**🎯 Objetivo**: Generar con el agente todos los módulos Bicep modulares, parametrizados y siguiendo las mejores prácticas del repositorio

---

## 📋 Objetivos de aprendizaje

Al finalizar esta actividad serás capaz de:

1. ✅ Solicitar al agente generación completa de código Bicep
2. ✅ Obtener módulos reutilizables y bien estructurados
3. ✅ Generar parámetros por entorno (dev/prod)
4. ✅ Validar código Bicep con Azure CLI
5. ✅ Ejecutar what-if deployments para preview
6. ✅ Entender la estructura modular de Bicep

---

## 🎯 Contexto de esta Actividad

Tienes de actividades anteriores:
- ✅ Architecture Design Document (Actividad 2)
- ✅ Análisis FinOps y decisiones de costos (Actividad 3)
- ✅ Decisión de SKUs y configuraciones

Ahora toca **materializar** ese diseño en código Infrastructure as Code (IaC) con Bicep.

---

## 📁 Paso 1: Estructura de Archivos Bicep

### 1.1 Estructura objetivo

```
docs/workshop/kitten-space-missions/solution/
└── bicep/
    ├── main.bicep                    # Orquestador principal
    ├── main.parameters.json          # Parámetros base
    ├── modules/
    │   ├── app-service.bicep         # Módulo App Service
    │   ├── sql-database.bicep        # Módulo SQL Database
    │   ├── key-vault.bicep           # Módulo Key Vault
    │   ├── networking.bicep          # Módulo VNet + Subnet
    │   ├── private-endpoint.bicep    # Módulo Private Endpoint
    │   ├── monitoring.bicep          # Módulo App Insights + Log Analytics
    │   └── rbac.bicep                # Módulo RBAC assignments
    └── parameters/
        ├── dev.parameters.json       # Parámetros dev
        └── prod.parameters.json      # Parámetros prod (futuro)
```

### 1.2 Principios de diseño Bicep

El agente debe seguir estos principios:

1. **Modularidad**: Un módulo = Una responsabilidad
2. **Reutilización**: Módulos parametrizados y reutilizables
3. **Parámetros por entorno**: dev.json vs prod.json
4. **Security by default**: Managed Identities, Private Endpoints, HTTPS only
5. **Observability**: Diagnostic settings en todos los recursos
6. **Naming conventions**: Consistentes con el repositorio

---

## 🤖 Paso 2: Solicitar Generación de Código al Agente

### 2.1 Prompt completo para generación Bicep

Copia este prompt en Copilot Chat:

```
@workspace Hola Azure_Architect_Pro 👋

Basándome en el ADD y análisis FinOps previos, necesito que generes 
AHORA el código Bicep completo para Kitten Space Missions API.

🎯 OBJETIVO:
Generar TODOS los módulos Bicep modulares, parámetros y archivo main 
siguiendo las convenciones del repositorio azure-agent-pro.

📋 DECISIONES DE DISEÑO CONFIRMADAS:
Basado en el análisis FinOps, implementar Scenario B (Balanced):
- App Service Plan: B1 Basic
- SQL Database: Basic (2GB)
- Key Vault: Standard
- VNet + Private Endpoint para SQL: SÍ
- Application Insights: Pay-as-you-go
- Log Analytics: Workspace compartido

🏗️ ESTRUCTURA DE ARCHIVOS:
Generar en: docs/workshop/kitten-space-missions/solution/bicep/

Archivos a crear:
1. main.bicep - Orquestador principal
2. modules/networking.bicep - VNet, Subnet, NSG
3. modules/app-service.bicep - App Service + Plan
4. modules/sql-database.bicep - SQL Server + Database
5. modules/key-vault.bicep - Key Vault con policies
6. modules/private-endpoint.bicep - Private Endpoint genérico
7. modules/monitoring.bicep - App Insights + Log Analytics
8. modules/rbac.bicep - RBAC assignments
9. parameters/dev.parameters.json - Parámetros dev
10. parameters/prod.parameters.json - Parámetros prod (futuro)

🎨 REQUISITOS DE CADA MÓDULO:

### main.bicep:
- Parámetros: environment, location, projectName
- targetScope = 'subscription' o 'resourceGroup' (tú decides)
- Crear resource group si no existe
- Llamar a todos los módulos en orden correcto
- Outputs: URLs, connection strings (Key Vault refs), resource IDs

### networking.bicep:
- VNet: 10.0.0.0/16
- Subnet para App Service: 10.0.1.0/24
- Subnet para Private Endpoints: 10.0.2.0/24
- NSG con reglas mínimas necesarias
- Service Endpoints habilitados

### app-service.bicep:
- App Service Plan B1 (Linux)
- App Service con:
  - Managed Identity (SystemAssigned)
  - HTTPS only, minTlsVersion 1.2
  - VNet Integration al subnet
  - App Settings configuradas (con Key Vault refs)
  - Connection string desde Key Vault
  - Diagnostic settings a Log Analytics

### sql-database.bicep:
- SQL Server con:
  - AAD Authentication (si es posible)
  - No SQL auth (solo AAD)
  - Public network access: Disabled (solo Private Endpoint)
  - minTlsVersion 1.2
- SQL Database Basic (2GB)
- Transparent Data Encryption habilitado
- Diagnostic settings

### key-vault.bicep:
- Key Vault con:
  - Soft delete enabled
  - Purge protection enabled
  - Access policy para App Service Managed Identity
  - Secrets: SQL connection string
  - Private Endpoint (opcional, evalúa costo vs beneficio)
  - Diagnostic settings

### private-endpoint.bicep:
- Módulo genérico reutilizable
- Parámetros: privateLinkServiceId, groupId, subnetId
- Private DNS Zone integration

### monitoring.bicep:
- Log Analytics Workspace
- Application Insights (linked a Log Analytics)
- Diagnostic settings templates
- Basic alert rules:
  - HTTP 5xx > 10 en 5min
  - Response time p95 > 500ms
  - Failed requests > 20%

### rbac.bicep:
- Role assignments:
  - App Service → SQL Database (SQL DB Contributor)
  - App Service → Key Vault (Key Vault Secrets User)

### parameters/dev.parameters.json:
{
  "$schema": "...",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {"value": "dev"},
    "location": {"value": "westeurope"},
    "projectName": {"value": "kitten-missions"},
    "sqlDatabaseSku": {"value": "Basic"},
    "appServicePlanSku": {"value": "B1"},
    "enablePrivateEndpoint": {"value": true},
    "tags": {
      "value": {
        "Environment": "Development",
        "Project": "KittenSpaceMissions",
        "ManagedBy": "Bicep",
        "CostCenter": "Engineering"
      }
    }
  }
}

🔒 SEGURIDAD - CHECKLIST OBLIGATORIO:
Cada módulo DEBE incluir:
- [ ] Managed Identity donde sea posible
- [ ] HTTPS/TLS 1.2+ only
- [ ] Public access disabled (donde aplique)
- [ ] Diagnostic settings configurados
- [ ] Secrets en Key Vault (NUNCA hardcoded)
- [ ] Network isolation (VNet, Private Endpoints)

📊 OBSERVABILITY - OBLIGATORIO:
Todos los recursos PaaS deben tener:
- Diagnostic settings enviando logs a Log Analytics
- Metrics habilitados
- Retention configurado (30 días dev, 90 días prod)

🎯 CONVENCIONES DE NAMING:
Usar formato consistente:
- Resource Group: rg-{projectName}-{environment}
- App Service: app-{projectName}-{environment}
- SQL Server: sql-{projectName}-{environment}
- Database: sqldb-{projectName}-{environment}
- Key Vault: kv-{projectName}-{environment}-{uniqueString}
- VNet: vnet-{projectName}-{environment}
- App Insights: appi-{projectName}-{environment}

💡 IMPORTANTE:
- Todos los módulos deben ser independientes y reutilizables
- Comentarios inline explicando decisiones clave
- @description decorators en TODOS los parámetros
- Usar @secure para passwords/secrets
- Outputs útiles en cada módulo

🚀 ACCIÓN:
Genera AHORA todos los archivos Bicep listados arriba.
No necesito aprobación intermedia, confío en que seguirás estas specs.

Una vez generados todos, muéstrame:
1. Lista de archivos creados
2. Comando para validar syntax
3. Comando para what-if deployment
```

### 2.2 Alternativa: Generación incremental

Si prefieres ver cada módulo antes de continuar:

```
Genera primero main.bicep y los parámetros dev.parameters.json.
Muéstramelos para validación antes de continuar con los módulos.
```

Luego:
```
Perfecto el main.bicep. Ahora genera los módulos en este orden:
1. networking.bicep
2. monitoring.bicep  
3. key-vault.bicep
4. sql-database.bicep
5. app-service.bicep
6. private-endpoint.bicep
7. rbac.bicep

Muéstrame cada uno para revisión.
```

---

## ✅ Paso 3: Validar el Código Generado

### 3.1 Checklist de validación por módulo

Para CADA módulo Bicep generado, verifica:

```markdown
### [nombre-modulo].bicep

Estructura:
- [ ] @description en todos los parámetros
- [ ] Parámetros con valores por defecto razonables
- [ ] Variables calculadas (no hardcoded)
- [ ] Recursos con naming consistente
- [ ] Outputs útiles

Seguridad:
- [ ] Managed Identity configurado
- [ ] HTTPS/TLS settings
- [ ] Public access disabled (si aplica)
- [ ] Secrets parametrizados (@secure)

Observability:
- [ ] Diagnostic settings incluido
- [ ] Logs configurados
- [ ] Metrics habilitados

Best Practices:
- [ ] Comentarios en decisiones complejas
- [ ] Uso de uniqueString() para nombres globales
- [ ] DependsOn solo cuando es necesario (Bicep infiere)
```

### 3.2 Validación de sintaxis Bicep

```bash
cd docs/workshop/kitten-space-missions/solution/bicep

# Validar sintaxis de todos los archivos
az bicep build --file main.bicep

# Si hay errores, los mostrará
# Si OK, genera main.json (ARM template compilado)

# Validar cada módulo individualmente
az bicep build --file modules/app-service.bicep
az bicep build --file modules/sql-database.bicep
az bicep build --file modules/key-vault.bicep
# ... etc
```

**Salida esperada**:
```
✓ Compilation successful
```

### 3.3 Linting de Bicep

```bash
# Ejecutar linter de Bicep
az bicep lint --file main.bicep

# O instalar bicep CLI y usar:
bicep build main.bicep
```

**Warnings comunes (OK si son informativos)**:
- `no-unused-params`: Parámetro declarado pero no usado
- `prefer-interpolation`: Usar string interpolation vs concat()
- `secure-secrets-in-params`: Usar @secure decorator

### 3.4 Revisión manual de código

Abre cada archivo en VS Code y revisa:

```bash
# Abrir VS Code en la carpeta bicep
code .
```

**Verifica visualmente**:
- ✅ Indentación consistente (2 espacios)
- ✅ Comentarios útiles
- ✅ Sin valores hardcoded (IPs, passwords, etc.)
- ✅ Parámetros con tipos correctos (string, int, bool, object, array)

---

## 🔍 Paso 4: What-If Deployment (Pre-flight Check)

**What-If** te permite ver qué cambios se harían SIN desplegar realmente.

### 4.1 Configurar Azure CLI

```bash
# Asegurarte de estar logueado
az login

# Seleccionar tu subscription
az account set --subscription "TU-SUBSCRIPTION-NAME-O-ID"

# Verificar
az account show
```

### 4.2 Ejecutar What-If a nivel Subscription

```bash
cd docs/workshop/kitten-space-missions/solution/bicep

# What-If deployment (sin desplegar)
az deployment sub what-if \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json \
  --result-format FullResourcePayloads
```

**Nota**: Ajusta `sub` por `group` si tu main.bicep tiene `targetScope = 'resourceGroup'`

### 4.3 Interpretar output de What-If

El output mostrará algo como:

```
Resource changes: 15 to create, 0 to modify, 0 to delete.

+ Microsoft.Network/virtualNetworks/vnet-kitten-missions-dev
  name: "vnet-kitten-missions-dev"
  location: "westeurope"
  properties.addressSpace.addressPrefixes: ["10.0.0.0/16"]
  
+ Microsoft.Sql/servers/sql-kitten-missions-dev
  name: "sql-kitten-missions-dev"
  location: "westeurope"
  properties.administratorLogin: null
  properties.azureADAdministrator: {...}

... [más recursos]
```

**Validaciones**:
- ✅ Número de recursos coincide con lo esperado (~12-15)
- ✅ Naming es correcto (kitten-missions-dev, etc.)
- ✅ Locations son correctos (westeurope)
- ✅ SKUs son los correctos (B1, Basic, etc.)
- ✅ No hay errores de dependencias

### 4.4 Troubleshooting What-If

**Error: "Template validation failed"**

```bash
# Validar primero sin what-if
az deployment sub validate \
  --location westeurope \
  --template-file main.bicep \
  --parameters parameters/dev.parameters.json
```

El output mostrará el error específico.

**Error: "Principal does not have permission"**

Necesitas permisos `Contributor` o `Owner` en la subscription. Contacta a tu admin de Azure.

---

## 📝 Paso 5: Documentar el Código Bicep

### 5.1 Crear README.md de Bicep

Pide al agente:

```
Genera un README.md para la carpeta bicep/ que documente:
1. Estructura de archivos y responsabilidad de cada módulo
2. Cómo ejecutar validation y what-if
3. Cómo desplegar (lo veremos en Actividad 6)
4. Naming conventions usadas
5. Variables de entorno necesarias
6. Troubleshooting común

Guárdalo en: docs/workshop/kitten-space-missions/solution/bicep/README.md
```

### 5.2 Crear diagrama de dependencias

Pide al agente:

```
Genera un diagrama ASCII mostrando las dependencias entre módulos Bicep.

Ejemplo:
main.bicep
├── networking.bicep (VNet, Subnets)
├── monitoring.bicep (Log Analytics, App Insights)
├── key-vault.bicep → dependsOn: networking (si Private Endpoint)
├── sql-database.bicep → dependsOn: networking, key-vault
├── private-endpoint.bicep → dependsOn: sql-database
├── app-service.bicep → dependsOn: sql-database, key-vault, monitoring
└── rbac.bicep → dependsOn: app-service, sql-database

Inclúyelo en el README.md de bicep/
```

---

## 🎯 Paso 6: Commit y Push del Código

### 6.1 Revisar cambios

```bash
cd ~/azure-agent-pro  # o tu ruta

# Ver archivos nuevos
git status

# Debe mostrar:
# docs/workshop/kitten-space-missions/solution/bicep/
#   main.bicep
#   parameters/dev.parameters.json
#   parameters/prod.parameters.json
#   modules/*.bicep
#   README.md
```

### 6.2 Commit estructurado

```bash
# Agregar todos los archivos bicep
git add docs/workshop/kitten-space-missions/solution/bicep/

# Commit descriptivo
git commit -m "feat(bicep): add modular IaC for kitten-space-missions

- Add main.bicep orchestrator
- Add modules: networking, app-service, sql-database, key-vault, monitoring
- Add dev/prod parameter files
- Implement security best practices (Managed Identity, Private Endpoints)
- Include diagnostic settings for all resources
- Follow azure-agent-pro naming conventions

Estimated cost: ~$45/month (dev environment)
"

# Push
git push origin main
```

---

## ✅ Entregables de esta actividad

Al finalizar deberías tener:

- ✅ **main.bicep** - Orquestador principal
- ✅ **8 módulos Bicep** en modules/ (networking, app, sql, kv, monitoring, pe, rbac)
- ✅ **Parámetros dev/prod** en parameters/
- ✅ **README.md** documentando la estructura
- ✅ **Validación syntax** exitosa (az bicep build)
- ✅ **What-If** ejecutado y revisado
- ✅ **Código commiteado** a tu fork de GitHub

### Checklist final

```markdown
## Validación Final Actividad 4

Código generado:
- [ ] main.bicep existe y compila
- [ ] 7-8 módulos en modules/ creados
- [ ] dev.parameters.json configurado
- [ ] prod.parameters.json creado (aunque no lo usemos todavía)

Validaciones ejecutadas:
- [ ] az bicep build main.bicep → ✓ OK
- [ ] az bicep lint main.bicep → Sin errores críticos
- [ ] az deployment what-if ejecutado → Revisado

Seguridad:
- [ ] Managed Identities configurados
- [ ] Private Endpoints implementados
- [ ] HTTPS only en todos los servicios
- [ ] Secretos en Key Vault

Observability:
- [ ] Diagnostic settings en todos los recursos
- [ ] Application Insights configurado
- [ ] Log Analytics workspace creado

Documentación:
- [ ] README.md de bicep/ creado
- [ ] Comentarios inline en módulos
- [ ] Diagrama de dependencias incluido

Git:
- [ ] Código commiteado
- [ ] Push a GitHub exitoso
```

---

## 🐛 Troubleshooting Común

### Error: "Az bicep command not found"

```bash
# Instalar/actualizar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar versión (debe ser >= 2.20.0)
az --version
```

### Error: "InvalidTemplate" en What-If

Lee el mensaje de error cuidadosamente. Comunes:

1. **Parámetro faltante**: Agrega en dev.parameters.json
2. **Tipo incorrecto**: Verifica int vs string
3. **Resource name duplicado**: Usa uniqueString()
4. **Dependencia circular**: Revisa dependsOn

### Warning: "linter warnings"

No todos los warnings son críticos:
- `no-unused-params`: OK si planeas usarlo futuro
- `simplify-interpolation`: Opcional
- `prefer-unquoted-property-names`: Estilo

Pero SÍ corrige:
- `secure-secrets-in-params`: Crítico
- `no-hardcoded-location`: Crítico

### El agente generó código incorrecto

Pide corrección específica:

```
En sql-database.bicep, la línea 45 tiene un error de sintaxis:
```bicep
properties.administratorLogin: adminLogin
```

Debería ser:
```bicep
properties: {
  administratorLogin: adminLogin
}
```

Por favor corrige y muéstrame el módulo actualizado.
```

---

## 💡 Tips Pro de Bicep

### 1. Uso de @description decorator

```bicep
@description('The name of the project (lowercase, no spaces)')
@minLength(3)
@maxLength(20)
param projectName string
```

### 2. UniqueString para nombres globales

```bicep
// Key Vault names son globales en Azure
var keyVaultName = 'kv-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'
```

### 3. Outputs útiles

```bicep
output appServiceUrl string = appService.properties.defaultHostName
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output keyVaultUri string = keyVault.properties.vaultUri
```

### 4. Comentarios útiles

```bicep
// Usamos Basic SKU para dev (2GB storage, 5 DTU) - suficiente para testing
// En prod cambiar a Standard S0 (250GB, 10 DTU)
sku: {
  name: sqlDatabaseSku
  tier: 'Basic'
}
```

---

## 🚀 Siguiente Paso

¡Excelente! Ahora tienes el código Bicep completo y validado. El siguiente paso es configurar los workflows de CI/CD en GitHub Actions para automatizar los despliegues.

**➡️ [Actividad 5: Configuración CI/CD con GitHub Actions](./activity-05-cicd-setup.md)**

En la próxima actividad configurarás pipelines completos de validación, testing y deployment automático usando GitHub Actions con OIDC (sin secretos).

---

## 📚 Referencias

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Azure Naming Conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Bicep Modules Registry](https://github.com/Azure/bicep-registry-modules)

---

**🏗️ ¡Felicidades! Has generado infraestructura como código profesional. Ahora vamos a automatizar su despliegue.**
