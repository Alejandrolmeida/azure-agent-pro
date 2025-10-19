# Monitoring Nativo AVD PIX4D Lab

> **Observabilidad, Control de Costes y Automatización Pay-Per-Use**  
> Stack 100% nativo de Azure válido para Azure Sponsorship (sin software de terceros)

## 📋 Descripción General

Este módulo implementa una solución completa de monitorización y control de costes para el laboratorio AVD PIX4D, incluyendo:

- ✅ **Observabilidad**: Log Analytics + AVD Insights + Data Collection Rules (GPU/CPU/RAM/Disco)
- ✅ **Alertas**: Métricas y consultas KQL para idle, fuera de horario, GPU alto, FSLogix
- ✅ **Control de Costes**: Presupuestos mensuales/diarios, alertas, exports a Storage
- ✅ **Automatización**: Runbook de auto-deallocate con múltiples razones (budget, idle, schedule)
- ✅ **Governance**: Azure Policies para SKUs permitidos y tags obligatorios
- ✅ **Workbooks**: Dashboards de AVD y showback de costes por alumno

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Subscription                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ rg-avd-pix4d-monitoring-lab                               │  │
│  │                                                            │  │
│  │  • Log Analytics Workspace (AVD Insights habilitado)      │  │
│  │  • Data Collection Endpoint + Rules (GPU counters)        │  │
│  │  • Action Group (email/webhook)                           │  │
│  │  • Metric Alerts (CPU, RAM, Disk)                         │  │
│  │  • KQL Alerts (idle, out-of-schedule, GPU high)          │  │
│  │  • Automation Account + Auto-Deallocate Runbook          │  │
│  │  • Workbooks (AVD Overview, Cost Showback)               │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ rg-avd-pix4d-cost-lab                                     │  │
│  │                                                            │  │
│  │  • Storage Account (cost exports)                         │  │
│  │  • Budgets (monthly: €300, daily: €15)                   │  │
│  │  • Cost Management Exports (daily/monthly)                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Subscription-level Resources                              │  │
│  │                                                            │  │
│  │  • Azure Policies (allowed SKUs, required tags)           │  │
│  │  • RBAC Assignments (Automation → VMs/AVD)                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Despliegue Rápido

### Prerrequisitos

```bash
# Activar entorno conda
conda activate avd-pix4d

# Login a Azure
az login
az account set --subscription <SUBSCRIPTION_ID>
```

### Desplegar Monitoring Completo

```bash
# Desde la raíz del repositorio
cd monitoring/bicep

# Desplegar (nivel subscription)
az deployment sub create \
  --name "avd-monitoring-$(date +%Y%m%d-%H%M%S)" \
  --location westeurope \
  --template-file main.monitoring.bicep \
  --parameters \
    environment=lab \
    resourceGroupPrefix=rg-avd-pix4d \
    actionGroupEmail="admin@example.com" \
    hostPoolResourceGroup=rg-avd-pix4d-lab \
    hostPoolName=avd-hostpool-lab \
    classWindow="16:00-21:00" \
    idleDeallocateMinutes=30 \
    monthlyBudgetAmount=300 \
    dailyBudgetAmount=15
```

## 📊 Componentes Principales

### 1. Log Analytics Workspace (LAW)

- **Retención**: 30 días (parametrizable)
- **Solución**: AVD Insights habilitado automáticamente
- **Tablas**: `WVDConnections`, `WVDCheckpoints`, `WVDErrors`, `WVDManagement`, `Heartbeat`, `Perf`, `Event`

```bicep
// Módulo: modules/law.bicep
```

### 2. Data Collection Rules (DCR)

Recolecta métricas críticas cada 60 segundos:

#### Performance Counters
- **CPU**: `\Processor(_Total)\% Processor Time`
- **RAM**: `\Memory\Available MBytes`, `\Memory\% Committed Bytes In Use`
- **Disco**: `\LogicalDisk(C:)\% Free Space`, `\PhysicalDisk(_Total)\Avg. Disk sec/Read`
- **GPU**: `\GPU Engine(*)\Utilization Percentage`, `\GPU Adapter Memory(*)\Dedicated Usage`
- **AVD**: `\RemoteFX Network(*)\Current TCP RTT`, `\User Input Delay per Session(*)\Max Input Delay`

#### Event Logs
- AVD Sessions: `TerminalServices-LocalSessionManager/Operational`
- FSLogix: `Microsoft-FSLogix-Apps/Operational` y `/Admin`
- System/Application: Errors and Warnings
- Security: Failed logins (EventID 4625)

```bicep
// Módulo: modules/dce-dcr-windowsgpu.bicep
```

### 3. Alertas

#### Alertas Métricas (modules/alerts-metrics.bicep)
| Alerta | Threshold | Window | Severity |
|--------|-----------|--------|----------|
| High CPU | > 95% | 15 min | Sev2 |
| Low Memory | < 500 MB | 10 min | Sev2 |
| Low Disk | < 10% free | 30 min | Sev1 |
| High Disk Latency | > 50ms | 15 min | Sev2 |
| VM Unhealthy | Availability < 1 | 5 min | Sev0 |

#### Alertas KQL (modules/alerts-kql.bicep)
| Alerta | Trigger | Acción |
|--------|---------|--------|
| Out of Schedule | VMs running outside 16:00-21:00 | Deallocate |
| Idle Hosts | No sessions > 30 min | Deallocate |
| High GPU | GPU > 95% for 15 min | Notify |
| Stopped Allocated | VM stopped > 30 min | Deallocate |
| FSLogix Failures | Profile mount errors | Notify |
| No Heartbeat | Missing heartbeat > 10 min | Critical Alert |

### 4. Automation Account + Runbook

**Runbook**: `ops/runbooks/auto-deallocate.ps1` (v2.0.0)

#### Razones de Corte (CutoffReason)
- `auto`: Lógica estándar (stopped allocated + out of schedule)
- `budgetExceeded`: Forzar shutdown inmediato (presupuesto superado)
- `idle`: Deallocate hosts sin sesiones activas
- `outOfSchedule`: Apagar VMs fuera de horario docente
- `stoppedAllocated`: Solo deallocate VMs en estado "stopped"
- `manual`: Shutdown manual (cualquier estado)

#### Parámetros del Runbook
```powershell
-CutoffReason "budgetExceeded"
-TargetResourceGroup "rg-avd-pix4d-lab"
-TargetOwner "student01"
-TargetCourseId "PIX4D-2024"
-ForcedShutdown $true
```

#### Programación
- **Frecuencia**: Cada 15 minutos
- **Horario**: 24/7 (evalúa ventana de clase internamente)
- **Webhook**: Disponible para Logic Apps (budget cutoff)

### 5. Presupuestos y Control de Costes

#### Presupuestos Configurados

| Tipo | Monto | Scope | Alertas |
|------|-------|-------|---------|
| Monthly | €300 | Subscription (tag: env=lab) | 50%, 80%, 90%, 100%, 110% |
| Daily | €15 | Subscription (tag: env=lab) | 80%, 100% |
| Por RG | €150 | Resource Group | 80%, 100% |
| Por Owner | €50 | Subscription (tag: owner) | 100% |

#### Cost Exports
- **Frecuencia**: Diaria y mensual
- **Formato**: CSV
- **Destino**: Storage Account `stcost*` → Container `costexports/`
- **Datos**: ActualCost (diario) y AmortizedCost (mensual)

```bicep
// Módulo: modules/budgets-cost-exports.bicep
// NOTA: Los budgets requieren despliegue a nivel subscription
```

### 6. Consultas KQL

Ubicación: `monitoring/kql/*.kql`

#### avd-activity.kql
Muestra sesiones activas por host y usuario.

```kusto
WVDConnections
| where TimeGenerated > ago(1h)
| where State == "Connected"
| summarize ActiveSessions = dcount(UserName) by SessionHostName
```

#### gpu-usage.kql
Monitoriza uso de GPU con percentiles.

```kusto
Perf
| where ObjectName == "GPU Engine"
| summarize 
    AvgUtil = avg(CounterValue),
    P95Util = percentile(CounterValue, 95)
    by Computer, bin(TimeGenerated, 5m)
```

#### deallocate-candidates.kql
Identifica VMs candidatas a deallocate por inactividad.

```kusto
let idleThreshold = 30m;
Heartbeat
| join kind=leftouter (WVDConnections) on $left.Computer == $right.SessionHostName
| extend IdleMinutes = datetime_diff('minute', now(), LastActivity)
| where IdleMinutes > 30
```

#### cost-showback.kql
Calcula coste estimado por alumno (owner tag).

```kusto
Heartbeat
| where ResourceGroup startswith "rg-avd"
| extend Owner = tostring(Tags['owner'])
| summarize RunningHours = count() / 60.0 by Owner
| extend EstimatedCost = RunningHours * 1.224  // NV12 hourly rate
```

## 🎨 Workbooks

### AVD Lab Overview
- Estado de hosts (Running/Stopped/Deallocated)
- Conexiones activas por alumno
- Uso de GPU/CPU/RAM/Disco (gráficos 5 min)
- Alertas activas
- Últimos eventos de cutoff

### Cost Showback
- Coste diario y mensual por `owner` y `courseId`
- Costo/hora estimado por alumno
- Comparativa vs presupuesto
- Top consumers

```bicep
// Módulo: modules/workbooks.bicep (pendiente de implementar JSON completo)
```

## 🔐 Azure Policies

### 1. Allowed SKUs Policy
Solo permite SKUs GPU de la familia NVads A10 v5:
- `Standard_NV12ads_A10_v5` (12 vCPU, 110 GB RAM, 1/4 GPU)
- `Standard_NV18ads_A10_v5` (18 vCPU, 220 GB RAM, 1/2 GPU)
- `Standard_NV36ads_A10_v5` (36 vCPU, 440 GB RAM, 1 GPU)

### 2. Required Tags Policy
Tags obligatorias para todos los recursos AVD:
- `env`: environment (lab/prod)
- `project`: nombre del proyecto
- `owner`: responsable del recurso
- `courseId`: identificador del curso
- `costCenter`: centro de coste

```bicep
// Módulo: modules/policy-tags-skus.bicep (pendiente de implementar)
```

## 📖 Guía de Triage

### Problema: GPU al 100% sostenido

**Síntomas**:
- Alerta "AVD High GPU Utilization"
- Usuario reporta lentitud en PIX4D

**Diagnóstico**:
```kusto
Perf
| where Computer == "avd-sh-01"
| where ObjectName == "GPU Engine"
| summarize avg(CounterValue) by bin(TimeGenerated, 1m)
| render timechart
```

**Soluciones**:
1. Verificar procesos con Task Manager en la VM
2. Si es trabajo legítimo de PIX4D: escalar a NV18 o NV36
3. Si es crypto mining: investigar breach y remediar

### Problema: FSLogix profile mount failure

**Síntomas**:
- Alerta "AVD FSLogix Profile Load Failures"
- Usuario no puede iniciar sesión

**Diagnóstico**:
```kusto
Event
| where Source == "Microsoft-FSLogix-Apps"
| where EventID in (34, 51, 52)
| project TimeGenerated, Computer, RenderedDescription
```

**Soluciones**:
1. Verificar conectividad con Azure Files
2. Check permisos RBAC en Storage Account
3. Validar private endpoint y DNS

### Problema: Budget exceeded

**Síntomas**:
- Email de "Budget Alert at 100%"
- VMs deallocateadas automáticamente

**Diagnóstico**:
```kusto
// Ver histórico de cutoffs
AzureActivity
| where ResourceProvider == "Microsoft.Compute"
| where OperationNameValue == "Microsoft.Compute/virtualMachines/deallocate/action"
| project TimeGenerated, Caller, ResourceGroup, Resource
```

**Acciones**:
1. Revisar cost-showback.kql para identificar top consumers
2. Validar tags (owner, courseId) para showback
3. Ajustar budget o policies según necesidad
4. Comunicar a alumnos sobre uso responsable

## 🧪 Testing

### Smoke Test
```bash
# Verificar que todos los recursos existen
cd tests/smoke
./az-smoke.sh -g "rg-avd-pix4d-monitoring-lab" -l "westeurope"
```

### E2E Test: Idle Deallocate
```bash
# 1. Encender una VM manualmente
az vm start --name avd-sh-01 --resource-group rg-avd-pix4d-lab

# 2. Esperar 35 minutos (idle threshold + margen)
sleep 2100

# 3. Verificar que se deallocó
az vm get-instance-view --name avd-sh-01 --resource-group rg-avd-pix4d-lab \
  --query "instanceView.statuses[1].code" -o tsv
# Expected: PowerState/deallocated
```

### E2E Test: Out of Schedule
```bash
# 1. Forzar ejecución del runbook fuera de horario
az automation runbook start \
  --automation-account-name aa-avd-pix4d-lab \
  --resource-group rg-avd-pix4d-monitoring-lab \
  --name auto-deallocate \
  --parameters '{"CutoffReason":"outOfSchedule"}'

# 2. Verificar logs
az automation job list \
  --automation-account-name aa-avd-pix4d-lab \
  --resource-group rg-avd-pix4d-monitoring-lab \
  --output table
```

### E2E Test: Budget Exceeded
```bash
# 1. Simular budget alert (requiere Logic App implementada)
# Por ahora, ejecutar manualmente el runbook
az automation runbook start \
  --automation-account-name aa-avd-pix4d-lab \
  --resource-group rg-avd-pix4d-monitoring-lab \
  --name auto-deallocate \
  --parameters '{"CutoffReason":"budgetExceeded","ForcedShutdown":true}'
```

## 📁 Estructura de Archivos

```
monitoring/
├── bicep/
│   ├── main.monitoring.bicep              # Orchestrator principal
│   ├── modules/
│   │   ├── law.bicep                       # Log Analytics Workspace ✅
│   │   ├── dce-dcr-windowsgpu.bicep       # Data Collection ✅
│   │   ├── action-group.bicep              # Action Group ✅
│   │   ├── alerts-metrics.bicep            # Metric Alerts ✅
│   │   ├── alerts-kql.bicep                # KQL Alerts ✅
│   │   ├── budgets-cost-exports.bicep     # Budgets ✅ (con errores de lint)
│   │   ├── automation-runbook-deallocate.bicep  # Automation ✅ (con errores)
│   │   ├── storage-cost-export.bicep       # Storage ✅
│   │   ├── rbac-automation.bicep           # RBAC ✅
│   │   ├── workbooks.bicep                 # Workbooks ⚠️ (pendiente JSON)
│   │   └── policy-tags-skus.bicep          # Policies ⚠️ (pendiente)
│   └── parameters/
│       ├── lab.bicepparam                  # Parámetros lab
│       └── prod.bicepparam                 # Parámetros prod
├── kql/
│   ├── avd-activity.kql                    # Active sessions ✅
│   ├── gpu-usage.kql                       # GPU monitoring ✅
│   ├── deallocate-candidates.kql           # Idle detection ✅
│   ├── idle-sessions.kql                   # Session idle ✅
│   └── cost-showback.kql                   # Cost by owner ✅
└── README.md                               # Este archivo
```

## 🔧 Configuración Post-Despliegue

### 1. Configurar DCR en Session Hosts

Cada session host debe asociarse al Data Collection Rule:

```bash
# Obtener DCR ID
DCR_ID=$(az monitor data-collection rule show \
  --name dcr-avd-windowsgpu-lab \
  --resource-group rg-avd-pix4d-monitoring-lab \
  --query id -o tsv)

# Asociar a cada VM
for VM in $(az vm list -g rg-avd-pix4d-lab --query "[].name" -o tsv); do
  az monitor data-collection rule association create \
    --name "dcr-association-$VM" \
    --rule-id "$DCR_ID" \
    --resource "/subscriptions/<SUB_ID>/resourceGroups/rg-avd-pix4d-lab/providers/Microsoft.Compute/virtualMachines/$VM"
done
```

### 2. Configurar AVD Diagnostic Settings

```bash
az monitor diagnostic-settings create \
  --name avd-diagnostics \
  --resource $(az desktopvirtualization hostpool show \
    --name avd-hostpool-lab \
    --resource-group rg-avd-pix4d-lab \
    --query id -o tsv) \
  --workspace $(az monitor log-analytics workspace show \
    --name law-avd-pix4d-lab \
    --resource-group rg-avd-pix4d-monitoring-lab \
    --query id -o tsv) \
  --logs '[{"category":"Checkpoint","enabled":true},{"category":"Error","enabled":true},{"category":"Management","enabled":true},{"category":"Connection","enabled":true},{"category":"HostRegistration","enabled":true}]'
```

### 3. Importar Workbooks

```bash
# Pendiente: crear JSON files y usar az portal dashboard create
```

## 🛠️ Pendientes de Implementación

### Alta Prioridad
- [ ] **workbooks.bicep**: Crear JSON completos para AVD Overview y Cost Showback
- [ ] **policy-tags-skus.bicep**: Implementar Azure Policy definitions
- [ ] **Logic App**: Crear logicapp-budget-cutoff.bicep para webhook de budgets
- [ ] **Parámetros files**: Crear lab.bicepparam y prod.bicepparam
- [ ] **Arreglar lint errors**: Budgets require subscription scope, automation require utcNow fix

### Media Prioridad
- [ ] **GitHub Actions**: workflows para deploy/destroy/lint
- [ ] **Tests automatizados**: scripts E2E para CI/CD
- [ ] **Power BI template**: Plantilla de showback (opcional)

### Baja Prioridad
- [ ] **Alertas adicionales**: Network throughput, Storage IOPS
- [ ] **Dashboards Azure Portal**: Alternativa a workbooks
- [ ] **Teams integration**: Webhook para notificaciones en Teams

## 📚 Referencias

- [Azure Monitor Documentation](https://learn.microsoft.com/azure/azure-monitor/)
- [AVD Insights](https://learn.microsoft.com/azure/virtual-desktop/insights)
- [Azure Cost Management](https://learn.microsoft.com/azure/cost-management-billing/)
- [Azure Automation Runbooks](https://learn.microsoft.com/azure/automation/automation-runbook-types)
- [KQL Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)

---

**Autor**: Azure Agent Pro  
**Versión**: 1.0.0  
**Última actualización**: 2025-10-19

