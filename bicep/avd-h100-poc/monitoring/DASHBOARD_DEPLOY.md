# Dashboard de Costos - Instrucciones de Despliegue

Este archivo contiene el Azure Workbook para monitorear costos del POC AVD H100.

## 📊 Paneles Incluidos

1. **Resumen Presupuestario**: Tabla con % usado de cada presupuesto (infra €20/mes, workload €1,500/mes)
2. **Costo Diario por Workload**: Gráfico temporal separando infraestructura vs VM
3. **Uso VM vs Presupuesto Diario**: Columnas comparando costo diario VM vs límite €50
4. **Horas de Ejecución VM**: Barras mostrando horas que la VM estuvo encendida por día
5. **Proyección Mensual Infraestructura**: Estimación de costo final del mes vs límite €20
6. **Alertas Presupuestarias Activas**: Tabla de alertas cuando se supera 80%/90%/100%
7. **Top 10 Recursos por Costo**: Pie chart de recursos más caros
8. **Operaciones VM Más Frecuentes**: Actividad de start/stop/deallocate

## 🚀 Despliegue del Dashboard

### Opción 1: Portal de Azure (Manual)

1. Ir a **Azure Portal** → **Monitor** → **Workbooks**
2. Click en **+ New**
3. Click en **Advanced Editor** (icono `</>` arriba a la derecha)
4. Pegar el contenido de `cost-dashboard.workbook.json`
5. Click **Apply**
6. Click **Done Editing**
7. **Save** con nombre: `AVD H100 POC - Cost Dashboard`
8. Ubicación: Subscription scope o Resource Group `rg-avd-h100-poc`

### Opción 2: Azure CLI

```bash
#!/bin/bash

RESOURCE_GROUP="rg-avd-h100-poc"
LOCATION="spaincentral"
WORKBOOK_NAME="AVD H100 POC - Cost Dashboard"
WORKBOOK_FILE="monitoring/cost-dashboard.workbook.json"

# Obtener Resource Group ID
RG_ID=$(az group show --name $RESOURCE_GROUP --query id -o tsv)

# Crear el workbook
az monitor app-insights workbook create \
  --resource-group $RESOURCE_GROUP \
  --name "avd-h100-cost-dashboard" \
  --display-name "$WORKBOOK_NAME" \
  --location $LOCATION \
  --category "workbook" \
  --serialized-data "@$WORKBOOK_FILE" \
  --source-id "$RG_ID" \
  --tags workload-type=infrastructure

echo "Dashboard creado exitosamente"
echo "Acceder en: Portal Azure → Monitor → Workbooks → $WORKBOOK_NAME"
```

### Opción 3: Bicep/ARM Template

```bicep
// Agregar al módulo monitoring.bicep o crear nuevo módulo dashboard.bicep

resource costDashboard 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid('cost-dashboard', resourceGroup().id)
  location: location
  kind: 'shared'
  tags: tags
  properties: {
    displayName: 'AVD H100 POC - Cost Dashboard'
    category: 'workbook'
    serializedData: loadTextContent('monitoring/cost-dashboard.workbook.json')
    sourceId: resourceGroup().id
    version: '1.0'
  }
}
```

## 📋 Configuración Post-Despliegue

### 1. Vincular Log Analytics Workspace

Si las queries no muestran datos:

1. Abrir el dashboard
2. Click **Edit**
3. En cada query, verificar que esté seleccionado el Workspace: `law-avdh100-monitoring`
4. Si no aparece, cambiar "Resource type" a `Log Analytics` y seleccionar el workspace
5. **Save**

### 2. Ajustar Rango de Tiempo

Por defecto muestra últimos 30 días. Para cambiar:

1. **Edit** dashboard
2. Parámetro **TimeRange** → cambiar `defaultValue`
3. **Save**

### 3. Crear Acceso Directo

Para acceso rápido:

1. Abrir el dashboard
2. Click **Share** → **Pin to dashboard**
3. Seleccionar **Azure Dashboard** existente o crear nuevo
4. Dashboard aparecerá en página principal de Azure Portal

## 🔍 Queries KQL Personalizadas

Si necesitas agregar más paneles, estas queries KQL pueden ser útiles:

### Costo Acumulado del Mes

```kusto
AzureDiagnostics
| where ResourceGroup == 'rg-avd-h100-poc'
| where TimeGenerated >= startofmonth(now())
| extend WorkloadType = tostring(tags_s['workload-type'])
| summarize TotalCost = sum(todouble(Cost_d)) by WorkloadType
```

### Comparar Semanas

```kusto
AzureDiagnostics
| where ResourceGroup == 'rg-avd-h100-poc'
| where TimeGenerated >= ago(14d)
| extend WeekNumber = week_of_year(TimeGenerated)
| extend WorkloadType = tostring(tags_s['workload-type'])
| summarize WeeklyCost = sum(todouble(Cost_d)) by WeekNumber, WorkloadType
| render columnchart
```

### Verificar Auto-Shutdown Funcionando

```kusto
AzureActivity
| where ResourceGroup == 'rg-avd-h100-poc'
| where OperationNameValue == 'Microsoft.Compute/virtualMachines/deallocate/action'
| where ActivityStatusValue == 'Success'
| extend Caller = tostring(Caller)
| where Caller contains 'automation'
| project TimeGenerated, Caller, ResourceId
| order by TimeGenerated desc
```

### Sesiones AVD por Día

```kusto
WVDConnections
| where TimeGenerated >= ago(30d)
| where State == 'Connected'
| summarize Sessions = dcount(CorrelationId) by bin(TimeGenerated, 1d)
| render timechart
```

## 🛠️ Troubleshooting

### No aparecen datos en las queries

**Causa:** Datos de costos no están disponibles aún (tarda 24-48h)

**Solución temporal:** Cambiar queries para usar métricas en lugar de costos:

```kusto
// En lugar de Cost_d, usar métricas de compute
Perf
| where Computer contains 'vm-avdh100'
| where CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by bin(TimeGenerated, 1h)
```

### Error "Resource not found"

**Causa:** Log Analytics Workspace no vinculado

**Solución:**
1. Edit dashboard
2. Cada query → cambiar "Data source" a tu Workspace específico
3. Save

### Dashboard vacío después de desplegar

**Causa:** Template JSON no se parseó correctamente

**Solución:**
1. Validar JSON: https://jsonlint.com/
2. Verificar que no haya caracteres especiales
3. Redesplegar con Azure CLI en lugar de Portal

## 📧 Exportar Datos

Para exportar datos del dashboard a Excel/CSV:

1. Ejecutar query en **Logs** (no Workbook)
2. Copiar query KQL del workbook
3. Azure Portal → Monitor → Logs
4. Pegar query
5. Run → Export → CSV

## 🔔 Alertas Adicionales

Para crear alertas basadas en las queries del dashboard:

```bash
# Alerta cuando VM lleva >3h encendida
az monitor metrics alert create \
  --name "VM-Running-Too-Long" \
  --resource-group rg-avd-h100-poc \
  --scopes $(az vm show -g rg-avd-h100-poc -n vm-avdh100-001 --query id -o tsv) \
  --condition "count vmAvailabilityMetric > 10800" \
  --window-size 1h \
  --evaluation-frequency 30m \
  --severity 2 \
  --description "VM lleva más de 3 horas encendida"
```

## 📚 Referencias

- [Azure Workbooks Documentation](https://docs.microsoft.com/azure/azure-monitor/visualize/workbooks-overview)
- [KQL Query Language](https://docs.microsoft.com/azure/data-explorer/kusto/query/)
- [Cost Management Queries](https://docs.microsoft.com/azure/cost-management-billing/costs/quick-acm-cost-analysis)
