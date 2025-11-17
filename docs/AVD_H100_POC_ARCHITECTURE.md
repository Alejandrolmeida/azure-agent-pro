# Arquitectura AVD POC - Spain Central con NC40ads_H100_v5

**Fecha:** 24 de Octubre de 2025  
**Región:** Spain Central  
**SKU Aprovisionado:** Standard_NC40ads_H100_v5 (40 vCPUs NVIDIA H100)  
**Modelo:** VDI Personal (1 usuario, 1 VM dedicada)

---

## 🎯 Objetivos del POC

### Requisitos Técnicos
- ✅ **VM:** 1x Standard_NC40ads_H100_v5 en Spain Central
- ✅ **Conexión:** VDI directo para máximo aprovechamiento de recursos
- ✅ **Transferencia:** Archivos pesados de forma eficiente y económica
- ✅ **Auto-shutdown:** Desasignar VM tras 15 min sin sesión activa

### Requisitos de Costos
- 🏷️ **Tag 1 - Cargas de trabajo:** `workload-type=session-host`
  - Límite: **€50/día** (€1,500/mes máximo)
  - Incluye: Costo de VM (encendida + apagada)
  
- 🏷️ **Tag 2 - Infraestructura:** `workload-type=infrastructure`
  - Límite: **€20/mes**
  - Incluye: VNET, NSG, Storage, AVD Workspace, Automation

### Control de Costos
- 📊 Dashboard detallado con análisis por tags
- 🚨 Alertas presupuestarias automáticas
- 📈 Proyecciones y gráficos de consumo

---

## 💰 Análisis de Costos Previsto

### Carga de Trabajo (Tag: session-host)

**VM: Standard_NC40ads_H100_v5**
- **Precio por hora (ejecutando):** €19.56/hora
- **Precio por hora (detenida/desasignada):** €0.00/hora ✅
- **Almacenamiento disco:** ~€8/mes (P30 Premium SSD 1TB)

**Escenarios de Uso:**

| Uso diario | Horas/día | Costo/día | Costo/mes (22 días) | ¿Cumple límite? |
|------------|-----------|-----------|---------------------|-----------------|
| **Conservador** | 2h | €39.12 | €860.64 + €8 disco | ✅ |
| **Estándar** | 2.5h | €48.90 | €1,075.80 + €8 disco | ✅ Justo |
| **Intensivo** | 3h | €58.68 | €1,290.96 + €8 disco | ❌ Excede |
| **Límite máximo** | 2h 33min | €50.00 | €1,100 + €8 disco | ✅ Límite |

**💡 Conclusión:** Máximo **2 horas y 30 minutos** de uso diario para cumplir presupuesto.

**Estrategia de ahorro:**
```
Costo VM encendida:    €19.56/hora
Costo VM apagada:      €0.00/hora
Ahorro por apagado:    100% del costo de compute
Costo fijo (disco):    €8/mes (incluido en infra)
```

---

### Infraestructura (Tag: infrastructure)

| Recurso | Costo/mes estimado | Justificación |
|---------|-------------------|---------------|
| **Virtual Network** | €0.00 | Sin costo en Spain Central |
| **Network Security Group** | €0.00 | Gratis |
| **Storage Account (Standard LRS)** | €2.00 | Para transferencia archivos (100GB) |
| **Storage Account Bandwidth** | €3.00 | Egress datos (estimado 50GB/mes) |
| **AVD Workspace** | €0.00 | Sin costo directo |
| **AVD Host Pool** | €0.00 | Sin costo directo |
| **Log Analytics Workspace** | €5.00 | 5GB ingesta/mes (monitoring) |
| **Azure Monitor Alerts** | €1.00 | Alertas de presupuesto |
| **Managed Disk P30 (1TB)** | €8.00 | OS + datos VM |
| **Azure Automation** | €1.00 | Runbook auto-shutdown |
| **TOTAL** | **€20.00** | ✅ Dentro del límite |

**Optimizaciones aplicadas:**
- Storage Account Standard LRS (no Premium)
- Log Analytics con retención 30 días
- Sin Azure Bastion (uso AVD directo)
- Sin VPN Gateway (acceso público con NSG restrictivo)

---

## 🏗️ Arquitectura de la Solución

### Componentes Principales

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Spain Central                               │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Resource Group: rg-avd-h100-poc                               │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │ Virtual Network: vnet-avd-spaincentral                  │ │ │
│  │  │ Address Space: 10.100.0.0/16                            │ │ │
│  │  │                                                         │ │ │
│  │  │  ┌───────────────────────────────────────────────────┐ │ │ │
│  │  │  │ Subnet: snet-sessionhosts                         │ │ │
│  │  │  │ Range: 10.100.1.0/24                              │ │ │
│  │  │  │                                                   │ │ │
│  │  │  │  ┌──────────────────────────────────────────┐    │ │ │
│  │  │  │  │ VM: vm-avd-h100-001                      │    │ │ │
│  │  │  │  │ SKU: Standard_NC40ads_H100_v5            │    │ │ │
│  │  │  │  │ vCPU: 40 | RAM: 320GB | GPU: H100 80GB  │    │ │ │
│  │  │  │  │ OS: Windows 11 Enterprise Multi-Session  │    │ │ │
│  │  │  │  │ Disk: P30 Premium SSD (1TB)              │    │ │ │
│  │  │  │  │ Tag: workload-type=session-host          │    │ │ │
│  │  │  │  └──────────────────────────────────────────┘    │ │ │
│  │  │  └───────────────────────────────────────────────────┘ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │ AVD Host Pool: hp-h100-personal                         │ │ │
│  │  │ Type: Personal                                          │ │ │
│  │  │ Assignment: Direct                                      │ │ │
│  │  │ Max Session Limit: 1                                    │ │ │
│  │  │ Tag: workload-type=infrastructure                       │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │ AVD Workspace: ws-avd-h100-poc                          │ │ │
│  │  │ Friendly Name: "H100 VDI Workspace"                     │ │ │
│  │  │ Tag: workload-type=infrastructure                       │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │ Storage Account: stavdh100transfer                      │ │ │
│  │  │ Type: Standard LRS                                      │ │ │
│  │  │ Container: file-uploads (100GB)                         │ │ │
│  │  │ Purpose: Transferencia archivos pesados                 │ │ │
│  │  │ Tag: workload-type=infrastructure                       │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │ Log Analytics: law-avd-h100-monitoring                  │ │ │
│  │  │ Retention: 30 days                                      │ │ │
│  │  │ Data Cap: 5GB/day                                       │ │ │
│  │  │ Tag: workload-type=infrastructure                       │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │ Automation Account: aa-avd-auto-shutdown                │ │ │
│  │  │ Runbook: Stop-AVDSessionHost                            │ │ │
│  │  │ Trigger: Cada 5 minutos                                 │ │ │
│  │  │ Logic: Detener si sin sesión > 15 min                   │ │ │
│  │  │ Tag: workload-type=infrastructure                       │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Seguridad y Acceso

### Network Security Group (NSG)

**Reglas de entrada:**
```
Priority | Name                    | Port  | Source        | Allow
---------|-------------------------|-------|---------------|-------
100      | AllowAVDGateway         | 443   | AVD Gateway   | Yes
200      | AllowAVDControl         | 1688  | AVD Control   | Yes
300      | AllowRDPFromCorporate   | 3389  | Tu IP pública | Yes
1000     | DenyAllInbound          | *     | *             | No
```

**Reglas de salida:**
```
Priority | Name                    | Port  | Destination   | Allow
---------|-------------------------|-------|---------------|-------
100      | AllowAzureCloud         | 443   | AzureCloud    | Yes
200      | AllowStorage            | 445   | Storage       | Yes
300      | AllowMonitoring         | 443   | Monitor       | Yes
1000     | DenyAllOutbound         | *     | Internet      | No
```

---

## 📁 Transferencia de Archivos Pesados

### Opción 1: Azure Storage Account + AzCopy (RECOMENDADO)

**Ventajas:**
- ✅ **Gratis:** AzCopy es herramienta gratuita
- ✅ **Rápido:** Transferencia paralela optimizada
- ✅ **Fiable:** Reintento automático en caso de fallo
- ✅ **Costo mínimo:** Solo storage (€2/mes para 100GB)

**Proceso:**
```bash
# 1. Desde tu equipo local, subir archivos a Storage Account
azcopy copy "C:\MisArchivos\*" "https://stavdh100transfer.blob.core.windows.net/file-uploads?<SAS-token>" --recursive

# 2. Desde la VM AVD, descargar archivos
azcopy copy "https://stavdh100transfer.blob.core.windows.net/file-uploads?<SAS-token>" "D:\DataIn\" --recursive

# 3. Procesar archivos en la VM con H100

# 4. Opcional: Subir resultados de vuelta al storage
azcopy copy "D:\DataOut\*" "https://stavdh100transfer.blob.core.windows.net/results?<SAS-token>" --recursive
```

**Costos:**
- Storage Account (Standard LRS 100GB): **€2.00/mes**
- Egress datos (50GB/mes estimado): **€3.00/mes**
- **Total:** €5.00/mes (incluido en presupuesto infra)

**Velocidad estimada:**
- Upload desde tu oficina: 50-200 Mbps (depende de tu conexión)
- Download en VM AVD: ~1 Gbps (red interna Azure)
- 100GB → ~10-40 minutos upload, ~2 minutos download

---

### Opción 2: Azure Files Premium con SMB

**Ventajas:**
- ✅ Montaje como unidad de red (transparente)
- ✅ Sin software adicional
- ❌ **Más caro:** €150/mes mínimo (TiB)

**Decisión:** NO recomendado por costo (excede presupuesto infraestructura)

---

### Opción 3: OneDrive for Business (Si disponible)

**Ventajas:**
- ✅ Sin costo adicional (si ya tienes licencia M365)
- ✅ Sincronización automática
- ❌ Lento para archivos muy grandes (>10GB)

**Decisión:** Solo para archivos pequeños o documentación

---

## ⚙️ Auto-Shutdown y Desasignación

### Lógica de Control

**Objetivo:** Detener y desasignar VM tras 15 minutos sin sesión activa.

### Azure Automation Runbook (PowerShell)

```powershell
<#
.SYNOPSIS
    Detiene y desasigna VMs AVD sin sesiones activas durante 15 minutos
    
.DESCRIPTION
    Verifica cada 5 minutos el estado de sesiones AVD.
    Si no hay sesiones activas por más de 15 minutos, detiene y desasigna la VM.
    
.TAGS
    Cost-Control, Auto-Shutdown, AVD
#>

param(
    [string]$ResourceGroupName = "rg-avd-h100-poc",
    [string]$HostPoolName = "hp-h100-personal",
    [int]$IdleMinutesThreshold = 15
)

# Conectar con identidad gestionada
Connect-AzAccount -Identity

# Obtener sesiones activas del host pool
$sessions = Get-AzWvdUserSession -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName

# Obtener session hosts
$sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName

foreach ($sessionHost in $sessionHosts) {
    $vmName = ($sessionHost.Name -split '/')[1] -replace '\..*$'
    
    # Obtener sesiones activas en este host
    $activeSessions = $sessions | Where-Object { $_.Name -like "*$vmName*" -and $_.SessionState -eq 'Active' }
    
    if ($activeSessions.Count -eq 0) {
        # No hay sesiones activas, verificar tiempo sin sesión
        $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -Status
        
        # Obtener última actividad desde tags
        $lastActivityTag = $vm.Tags['LastActivity']
        
        if ($lastActivityTag) {
            $lastActivity = [DateTime]::Parse($lastActivityTag)
            $minutesIdle = (Get-Date) - $lastActivity
            
            if ($minutesIdle.TotalMinutes -ge $IdleMinutesThreshold) {
                Write-Output "VM $vmName sin sesiones por $([int]$minutesIdle.TotalMinutes) minutos. Deteniendo..."
                
                # Detener y desasignar VM
                Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName -Force
                
                Write-Output "VM $vmName detenida y desasignada correctamente."
                
                # Actualizar tag
                $vm.Tags['LastActivity'] = $null
                $vm.Tags['LastShutdown'] = (Get-Date).ToString('o')
                Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -Tag $vm.Tags
            } else {
                Write-Output "VM $vmName sin sesiones por $([int]$minutesIdle.TotalMinutes) minutos. Esperando..."
            }
        } else {
            # Primera vez sin sesión, marcar timestamp
            $vm.Tags['LastActivity'] = (Get-Date).ToString('o')
            Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -Tag $vm.Tags
            Write-Output "VM $vmName: Marcando inicio de período sin sesiones."
        }
    } else {
        # Hay sesiones activas, actualizar timestamp
        $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vmName
        $vm.Tags['LastActivity'] = (Get-Date).ToString('o')
        Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -Tag $vm.Tags
        Write-Output "VM $vmName: $($activeSessions.Count) sesión(es) activa(s)."
    }
}
```

**Configuración del Schedule:**
- Frecuencia: Cada 5 minutos
- Zona horaria: Europe/Madrid
- Días: Todos

**Ahorro estimado:**
- Asumiendo 8h de trabajo efectivo + tiempos muertos
- Sin auto-shutdown: 24h × €19.56 = **€469.44/día**
- Con auto-shutdown (2.5h real): 2.5h × €19.56 = **€48.90/día**
- **Ahorro:** €420.54/día (90%)

---

## 📊 Dashboard de Costos y Monitoring

### Componentes del Dashboard

**Panel 1: Costos Diarios por Tag**
```kusto
// Query Log Analytics - Costo diario por workload-type
AzureCostData
| where TimeGenerated >= ago(30d)
| extend WorkloadType = tostring(Tags['workload-type'])
| summarize DailyCost = sum(Cost) by bin(TimeGenerated, 1d), WorkloadType
| render timechart
```

**Panel 2: Uso de VM vs Presupuesto Diario**
```kusto
// Comparar uso real vs límite de €50/día
AzureCostData
| where TimeGenerated >= ago(7d)
| where Tags['workload-type'] == 'session-host'
| summarize DailyCost = sum(Cost) by bin(TimeGenerated, 1d)
| extend BudgetLimit = 50.0
| extend Status = iff(DailyCost > BudgetLimit, 'Over Budget', 'Within Budget')
| project TimeGenerated, DailyCost, BudgetLimit, Status
| render columnchart
```

**Panel 3: Costos Infraestructura Mensual**
```kusto
// Proyección mensual de costos de infraestructura
AzureCostData
| where Tags['workload-type'] == 'infrastructure'
| summarize MonthlyCost = sum(Cost)
| extend BudgetLimit = 20.0
| extend Projection = MonthlyCost * (30.0 / dayofmonth(now()))
| project MonthlyCost, Projection, BudgetLimit
```

**Panel 4: Tiempo de Ejecución VM**
```kusto
// Horas de ejecución de la VM por día
AzureActivity
| where OperationNameValue == 'Microsoft.Compute/virtualMachines/start/action' 
    or OperationNameValue == 'Microsoft.Compute/virtualMachines/deallocate/action'
| where ResourceId contains 'vm-avd-h100'
| summarize StartTime = minif(TimeGenerated, OperationNameValue contains 'start'),
            StopTime = maxif(TimeGenerated, OperationNameValue contains 'deallocate')
    by bin(TimeGenerated, 1d)
| extend RuntimeHours = datetime_diff('hour', StopTime, StartTime)
| project Date = format_datetime(TimeGenerated, 'yyyy-MM-dd'), RuntimeHours
| render columnchart
```

**Panel 5: Alertas de Presupuesto**
```kusto
// Alertas cuando se excede el 80% del presupuesto diario
AzureCostData
| where TimeGenerated >= startofday(now())
| where Tags['workload-type'] == 'session-host'
| summarize CurrentCost = sum(Cost)
| extend DailyBudget = 50.0
| extend PercentageUsed = (CurrentCost / DailyBudget) * 100
| where PercentageUsed > 80
| project CurrentCost, DailyBudget, PercentageUsed, 
         Alert = 'WARNING: Budget exceeding 80%'
```

### Alertas Configuradas

**Alerta 1: Presupuesto Diario VM**
- Condición: Costo > €40 (80% de €50)
- Frecuencia: Cada 1 hora
- Acción: Email + Webhook (opcional: detener VM)

**Alerta 2: Presupuesto Mensual Infraestructura**
- Condición: Proyección > €18 (90% de €20)
- Frecuencia: Diaria
- Acción: Email al administrador

**Alerta 3: VM No Detenida**
- Condición: VM ejecutando > 3 horas continuas
- Frecuencia: Cada 30 minutos
- Acción: Email + Ejecutar runbook de apagado forzoso

---

## 🚀 Despliegue - Orden de Implementación

### Fase 1: Infraestructura Base (30 minutos)
1. ✅ Resource Group
2. ✅ Virtual Network + Subnet + NSG
3. ✅ Storage Account + Container
4. ✅ Log Analytics Workspace
5. ✅ Tags en todos los recursos

### Fase 2: AVD (20 minutos)
6. ✅ AVD Workspace
7. ✅ AVD Host Pool (Personal)
8. ✅ Application Group
9. ✅ Asignación de usuarios

### Fase 3: VM Session Host (40 minutos)
10. ✅ Managed Disk P30 (1TB)
11. ✅ VM NC40ads_H100_v5
12. ✅ Extensión NVIDIA GPU Driver
13. ✅ Extensión Azure Monitor Agent
14. ✅ Unión a AVD Host Pool

### Fase 4: Automatización (30 minutos)
15. ✅ Automation Account
16. ✅ Runbook Auto-Shutdown
17. ✅ Schedule cada 5 minutos
18. ✅ Identidad gestionada con permisos

### Fase 5: Monitoring y Costos (20 minutos)
19. ✅ Configurar Cost Analysis
20. ✅ Crear Dashboard
21. ✅ Configurar Alertas presupuestarias
22. ✅ Habilitar diagnósticos en todos los recursos

**Tiempo total estimado:** ~2.5 horas

---

## 📋 Checklist Pre-Despliegue

### Verificaciones

- [ ] Cuota de 40 cores NC40ads_H100_v5 confirmada en Spain Central
- [ ] Suscripción POC AVD activa
- [ ] Usuario Azure AD creado y asignado licencia AVD
- [ ] Tu IP pública identificada para NSG
- [ ] Nombre de Storage Account disponible (stavdh100transfer)

### Decisiones Técnicas

- [ ] **OS de VM:** Windows 11 Enterprise Multi-Session (recomendado)
  - Alternativa: Windows 10 Enterprise Multi-Session
  
- [ ] **Tamaño disco:** 1TB P30 (suficiente para datos Pix4D)
  - Alternativa: 512GB P20 si datos <300GB
  
- [ ] **Backup VM:** ¿Habilitar Azure Backup? (+€20/mes)
  - Recomendación: NO (es POC, datos en Storage Account)

---

## 💡 Mejores Prácticas

### Control de Costos

1. **Detener VM manualmente al finalizar trabajo diario**
   - Ahorra costos inmediatamente
   - Auto-shutdown es respaldo, no solución principal

2. **Monitorear dashboard diariamente**
   - Primera semana: Revisar 2 veces/día
   - Ajustar alertas según patrones reales

3. **Transferir solo datos necesarios**
   - No mantener archivos grandes en VM indefinidamente
   - Usar Storage Account como repositorio principal

4. **Limpiar recursos no usados**
   - Snapshots antiguos
   - Logs > 30 días
   - Contenedores temporales

### Optimización de Rendimiento

1. **Drivers NVIDIA actualizados**
   - Instalar última versión CUDA Toolkit
   - Verificar: `nvidia-smi`

2. **Configurar Pix4Dmatic para GPU**
   - Preferencias → GPU → Habilitar CUDA
   - Asignar máximo de memoria GPU

3. **Disco de datos separado**
   - OS en C:\ (250GB)
   - Datos/proyectos en D:\ (750GB)

### Seguridad

1. **Cambiar contraseña VM regularmente**
2. **Habilitar MFA en Azure AD**
3. **Revisar logs de acceso semanalmente**
4. **Mantener Windows Update activo**

---

## 📞 Soporte y Troubleshooting

### Problema: VM no se detiene automáticamente

**Verificar:**
```powershell
# 1. Comprobar runbook ejecutándose
Get-AzAutomationJob -ResourceGroupName rg-avd-h100-poc `
    -AutomationAccountName aa-avd-auto-shutdown

# 2. Ver logs del último job
Get-AzAutomationJobOutput -ResourceGroupName rg-avd-h100-poc `
    -AutomationAccountName aa-avd-auto-shutdown `
    -Id <job-id> -Stream Output
```

### Problema: Transferencia de archivos lenta

**Soluciones:**
1. Usar AzCopy con flag `--block-size-mb 100`
2. Verificar conexión: `Test-NetConnection stavdh100transfer.blob.core.windows.net -Port 443`
3. Revisar firewall local/corporativo

### Problema: Costo excediendo presupuesto

**Acciones inmediatas:**
1. Detener VM: `Stop-AzVM -ResourceGroupName rg-avd-h100-poc -Name vm-avd-h100-001 -Force`
2. Revisar Cost Analysis por recurso
3. Verificar uso inesperado (backups, logs, etc.)

---

## 📈 Métricas de Éxito del POC

### Objetivos Mesurables

| Métrica | Target | Cómo medir |
|---------|--------|------------|
| **Costo diario VM** | < €50/día | Cost Analysis dashboard |
| **Costo mensual infra** | < €20/mes | Tags filter en Cost Analysis |
| **Tiempo respuesta Pix4D** | < 10h para 10K imágenes | Logs de Pix4Dmatic |
| **Disponibilidad VM** | > 99% cuando encendida | Azure Monitor |
| **Tiempo transferencia 100GB** | < 30 min | Logs AzCopy |

### KPIs Semanales

- Costo total acumulado
- Horas de uso efectivo VM
- GB transferidos
- Número de sesiones AVD
- Incidentes/problemas técnicos

---

**Próximo paso:** Generar archivos Bicep para despliegue automatizado

