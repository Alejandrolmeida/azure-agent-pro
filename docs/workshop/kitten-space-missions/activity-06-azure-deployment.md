# 🌐 Actividad 6: Despliegue en Azure

**⏱️ Duración estimada**: 45 minutos  
**🎯 Objetivo**: Desplegar la infraestructura completa en Azure y validar que todo funciona correctamente

---

## 📋 Objetivos de aprendizaje

1. ✅ Ejecutar deployment desde GitHub Actions
2. ✅ Monitorear el progreso del deployment
3. ✅ Validar recursos creados en Azure Portal
4. ✅ Verificar conectividad y configuración
5. ✅ Resolver problemas comunes de deployment

---

## 🚀 Paso 1: Pre-Deployment Checklist

Antes de desplegar, verifica:

```markdown
## Pre-Deployment Checklist

Azure:
- [ ] Azure CLI logueado (az login)
- [ ] Subscription correcta seleccionada
- [ ] Permisos Contributor en subscription
- [ ] OIDC configurado (Actividad 5)

GitHub:
- [ ] Código Bicep en main branch
- [ ] Workflows creados (.github/workflows/)
- [ ] Secrets configurados (CLIENT_ID, TENANT_ID, SUBSCRIPTION_ID)
- [ ] Environment "dev" creado

Bicep:
- [ ] az bicep build exitoso
- [ ] az deployment what-if revisado
- [ ] Sin errores de validación
```

---

## 🎬 Paso 2: Ejecutar Deployment Manual

### 2.1 Desde GitHub Actions UI

1. Ve a tu repo en GitHub
2. **Actions** tab
3. Selecciona workflow **"Deploy Infrastructure"**
4. Click **"Run workflow"**
5. Branch: `main`
6. Environment: `dev`
7. Click **"Run workflow"** verde

### 2.2 Monitorear progreso

- ✅ Job "deploy-dev" debe aparecer running
- 🔍 Click en el job para ver logs en tiempo real
- ⏱️ Duración esperada: 10-15 minutos

### 2.3 Logs importantes

Busca en los logs:

```
✓ Azure Login (OIDC) - SUCCESS
✓ Deploy Bicep Template - IN PROGRESS
  └─ Creating resource group...
  └─ Deploying virtual network...
  └─ Deploying monitoring...
  └─ Deploying Key Vault...
  └─ Deploying SQL Database...
  └─ Deploying App Service...
  └─ Configuring RBAC...
✓ Deployment completed successfully
```

---

## 🔍 Paso 3: Validar Recursos en Azure Portal

### 3.1 Verificar Resource Group

```bash
# Listar resource groups
az group list --query "[?starts_with(name, 'rg-kitten')].name" -o table

# Debe mostrar: rg-kitten-missions-dev
```

**En Azure Portal**:
1. Portal.azure.com → Resource Groups
2. Buscar `rg-kitten-missions-dev`
3. Click para abrir

### 3.2 Inventario de recursos esperados

Deberías ver ~12-15 recursos:

| Recurso | Nombre esperado | Estado |
|---------|-----------------|---------|
| Resource Group | rg-kitten-missions-dev | ✅ |
| Virtual Network | vnet-kitten-missions-dev | ✅ |
| Network Security Group | nsg-app-dev | ✅ |
| App Service Plan | plan-kitten-missions-dev | ✅ |
| App Service | app-kitten-missions-dev | ✅ |
| SQL Server | sql-kitten-missions-dev | ✅ |
| SQL Database | sqldb-kitten-missions-dev | ✅ |
| Key Vault | kv-kitten-missions-dev-xxx | ✅ |
| Private Endpoint | pe-sql-dev | ✅ |
| Log Analytics | log-kitten-missions-dev | ✅ |
| Application Insights | appi-kitten-missions-dev | ✅ |

### 3.3 Validar cada recurso

**App Service**:
```bash
az webapp show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query "{Name:name, State:state, Url:defaultHostName}" -o table
```

**SQL Database**:
```bash
az sql db show \
  --name sqldb-kitten-missions-dev \
  --server sql-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query "{Name:name, Status:status, Size:maxSizeBytes}" -o table
```

**Key Vault**:
```bash
az keyvault show \
  --name [KV-NAME-CON-UNIQUE-STRING] \
  --query "{Name:name, Location:location, Sku:sku.name}" -o table
```

---

## 🔗 Paso 4: Verificar Conectividad

### 4.1 App Service → SQL Database

```bash
# Verificar Managed Identity asignado
az webapp identity show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev
```

### 4.2 App Service → Key Vault

```bash
# Verificar access policy en Key Vault
az keyvault show \
  --name [KV-NAME] \
  --query "properties.accessPolicies[].objectId" -o table
```

### 4.3 Private Endpoint

```bash
# Verificar Private Endpoint connection
az network private-endpoint show \
  --name pe-sql-dev \
  --resource-group rg-kitten-missions-dev \
  --query "privateLinkServiceConnections[0].privateLinkServiceConnectionState.status" -o tsv

# Debe mostrar: Approved
```

---

## 🧪 Paso 5: Smoke Tests

### 5.1 Test App Service Health

```bash
# Obtener URL del App Service
APP_URL=$(az webapp show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query defaultHostName -o tsv)

# Test HTTP (aunque no haya app desplegada todavía)
curl -I https://$APP_URL

# Debe retornar HTTP 200 o 404 (OK), NO 502/503
```

### 5.2 Test Application Insights

```bash
# Verificar que está recibiendo telemetría
az monitor app-insights component show \
  --app appi-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query "instrumentationKey" -o tsv
```

---

## 💰 Paso 6: Verificar Costos

### 6.1 Azure Cost Management

```bash
# Ver costos estimados del resource group
az consumption usage list \
  --start-date $(date -d '1 day ago' +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  | jq '.[] | select(.instanceName | contains("kitten-missions"))'
```

**En Portal**:
- Cost Management + Billing
- Cost analysis
- Filter by Resource Group: rg-kitten-missions-dev
- View: Last 7 days

### 6.2 Comparar vs estimación FinOps

```markdown
## Cost Reality Check

| Concepto | Estimado (Act 3) | Real (Act 6) | Δ |
|----------|------------------|--------------|---|
| App Service B1 | $13/mes | TBD | |
| SQL Basic | $5/mes | TBD | |
| Private Endpoint | $7/mes | TBD | |
| Otros | $10/mes | TBD | |
| **Total** | **$35-45/mes** | **TBD** | |
```

---

## ✅ Entregables

- ✅ Infraestructura desplegada en Azure
- ✅ Todos los recursos creados y funcionando
- ✅ Conectividad verificada (MI, Private Endpoint)
- ✅ Smoke tests pasados
- ✅ Costos dentro de budget
- ✅ Screenshot del Resource Group (opcional)

---

## 🐛 Troubleshooting

### Error: "Deployment failed"

1. Revisar logs detallados en GitHub Actions
2. Buscar línea con "ERROR" o "Failed"
3. Común: Naming conflict (nombre ya existe)

**Solución**:
```bash
# Agregar uniqueString en nombres globales (Key Vault, Storage)
# El agente debería haberlo hecho, pero verifica
```

### Error: "Insufficient permissions"

**Solución**:
```bash
# Verificar OIDC Service Principal tiene rol Contributor
az role assignment list \
  --assignee [CLIENT_ID] \
  --scope /subscriptions/[SUBSCRIPTION_ID]
```

### Deployment OK pero App Service muestra 502

**Normal**: No has desplegado código de la API todavía, solo infraestructura.
En Actividad 8 desplegarás la aplicación.

---

## 🚀 Siguiente Paso

**➡️ [Actividad 7: Monitoreo y Observabilidad](./activity-07-monitoring.md)**

En la siguiente actividad configurarás dashboards, alertas y queries en Application Insights.
