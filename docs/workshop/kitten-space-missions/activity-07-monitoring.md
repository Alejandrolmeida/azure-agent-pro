# 📊 Actividad 7: Monitoreo y Observabilidad

**⏱️ Duración estimada**: 20 minutos  
**🎯 Objetivo**: Configurar Application Insights, dashboards y alertas para observabilidad completa de la solución

---

## 📋 Objetivos de aprendizaje

1. ✅ Configurar queries en Application Insights
2. ✅ Crear dashboards de monitoreo
3. ✅ Configurar alertas críticas
4. ✅ Entender métricas clave (latency, availability, errors)
5. ✅ Revisar diagnostic logs

---

## 🔍 Paso 1: Explorar Application Insights

### 1.1 Acceder a Application Insights

```bash
# Obtener URL de Application Insights
az monitor app-insights component show \
  --app appi-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query "id" -o tsv
```

**En Azure Portal**:
1. Resource Group → `rg-kitten-missions-dev`
2. Click en `appi-kitten-missions-dev`
3. Overview dashboard

### 1.2 Secciones importantes

- **Overview**: Métricas generales (requests, failures, response time)
- **Live Metrics**: Telemetría en tiempo real
- **Failures**: Errores y excepciones
- **Performance**: Latency por endpoint
- **Logs**: Queries KQL (Kusto)

---

## 📈 Paso 2: Queries KQL Esenciales

### 2.1 Solicitar queries al agente

```
@workspace 

Genera queries KQL para Application Insights que monitoreen:

1. Request rate (requests/min) últimas 24h
2. Response time p95 por endpoint
3. Error rate (HTTP 5xx)
4. Top 10 endpoints más lentos
5. Failed requests con detalles
6. Dependency calls (SQL, Key Vault)
7. Custom telemetry (cuando desplegemos la API)

Formato: Query KQL listo para ejecutar en Logs section.
```

### 2.2 Queries esperadas

**Request Rate**:
```kql
requests
| where timestamp > ago(24h)
| summarize RequestCount = count() by bin(timestamp, 5m)
| render timechart
```

**P95 Latency por Endpoint**:
```kql
requests
| where timestamp > ago(1h)
| summarize percentile_95 = percentile(duration, 95) by name
| order by percentile_95 desc
| render barchart
```

**Error Rate**:
```kql
requests
| where timestamp > ago(1h)
| summarize TotalRequests = count(), 
            FailedRequests = countif(success == false)
| extend ErrorRate = (FailedRequests * 100.0) / TotalRequests
| project ErrorRate, TotalRequests, FailedRequests
```

---

## 🎨 Paso 3: Crear Dashboard

### 3.1 Solicitar configuración al agente

```
Ayúdame a crear un Azure Dashboard para monitoreo de Kitten Space Missions.

Debe incluir:
- Request rate (line chart)
- Response time p95 (gauge)
- Error rate (big number)
- Server response time (time chart)
- Failed request details (table)
- Availability (percentage)

Dame los pasos para crearlo en Azure Portal o JSON ARM template.
```

### 3.2 Crear dashboard manual

**En Azure Portal**:
1. Dashboard → Create → Blank dashboard
2. Nombre: "Kitten Missions - Dev"
3. Add tiles:
   - **Metrics chart** (App Service response time)
   - **Metrics chart** (SQL Database DTU usage)
   - **Log Analytics query** (error rate)
   - **Application Insights** (availability)

---

## 🚨 Paso 4: Configurar Alertas

### 4.1 Alertas críticas necesarias

Solicita al agente:

```
Genera comandos Azure CLI o ARM template para configurar estas alertas 
en Application Insights:

1. **High Error Rate**
   - Condición: HTTP 5xx > 10 en 5 minutos
   - Severity: Critical (Sev 0)
   - Action: Email [tu-email]

2. **High Response Time**
   - Condición: p95 response time > 500ms por 10 minutos
   - Severity: Warning (Sev 2)
   - Action: Email

3. **Availability Drop**
   - Condición: Availability < 99% en 15 minutos
   - Severity: Critical (Sev 0)
   - Action: Email + SMS (opcional)

4. **High SQL DTU**
   - Condición: SQL Database DTU > 80% por 10 minutos
   - Severity: Warning (Sev 2)
   - Action: Email

Resource Group: rg-kitten-missions-dev
```

### 4.2 Crear Action Group

```bash
# Action Group para notificaciones
az monitor action-group create \
  --name "ag-kitten-missions-dev" \
  --resource-group "rg-kitten-missions-dev" \
  --short-name "KittenOps" \
  --email-receiver "admin" "[tu-email]"
```

### 4.3 Crear alerta de ejemplo

```bash
# Alerta: High error rate
az monitor metrics alert create \
  --name "High-Error-Rate" \
  --resource-group "rg-kitten-missions-dev" \
  --scopes [APP-INSIGHTS-RESOURCE-ID] \
  --condition "count failed requests > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action [ACTION-GROUP-ID] \
  --severity 0
```

---

## 📝 Paso 5: Diagnostic Settings

### 5.1 Verificar diagnostic settings

```bash
# Listar diagnostic settings de App Service
az monitor diagnostic-settings list \
  --resource [APP-SERVICE-RESOURCE-ID] \
  | jq '.value[].logs'
```

### 5.2 Logs importantes habilitados

Verificar que estos logs están habilitados:
- ✅ AppServiceHTTPLogs
- ✅ AppServiceConsoleLogs
- ✅ AppServiceAppLogs
- ✅ AppServicePlatformLogs

---

## ✅ Entregables

- ✅ Queries KQL guardadas en Application Insights
- ✅ Dashboard creado con métricas clave
- ✅ 3-4 alertas configuradas
- ✅ Action Group para notificaciones
- ✅ Diagnostic settings verificados

---

## 💡 Tips Pro de Observability

### SRE Golden Signals

Monitorea siempre:
1. **Latency**: Response time p50, p95, p99
2. **Traffic**: Requests per second
3. **Errors**: Error rate (5xx, exceptions)
4. **Saturation**: CPU, Memory, DTU usage

### Queries útiles adicionales

**Dependency tracking**:
```kql
dependencies
| where timestamp > ago(1h)
| summarize count(), avg(duration) by name, type
| order by avg_duration desc
```

**Slow queries SQL**:
```kql
dependencies
| where type == "SQL"
| where duration > 1000  // > 1 segundo
| project timestamp, name, duration, success
| order by timestamp desc
```

---

## 🚀 Siguiente Paso

**➡️ [Actividad 8: Testing y Validación](./activity-08-testing.md)**

En la última actividad desplegarás una API simple de prueba y ejecutarás smoke tests completos.
