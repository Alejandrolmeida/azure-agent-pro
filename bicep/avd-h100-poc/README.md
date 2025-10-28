# AVD H100 POC - Infraestructura como Código

Este directorio contiene toda la infraestructura necesaria para desplegar un entorno Azure Virtual Desktop (AVD) con máquina virtual GPU NVIDIA H100 en Spain Central.

## 📋 Contenido

```
avd-h100-poc/
├── main.bicep                      # Orquestador principal
├── deploy.sh                       # Script de despliegue automatizado
├── README.md                       # Este archivo
├── modules/                        # Módulos Bicep reutilizables
│   ├── network.bicep              # VNET, Subnet, NSG
│   ├── storage.bicep              # Storage Account para transferencia
│   ├── monitoring.bicep           # Log Analytics Workspace
│   ├── avd.bicep                  # Host Pool, Workspace, App Group
│   ├── vm.bicep                   # VM NC40ads_H100_v5 con drivers
│   ├── automation.bicep           # Auto-shutdown automation
│   └── cost-management.bicep      # Budgets y alertas
├── parameters/
│   └── poc.bicepparam             # Parámetros para entorno POC
└── scripts/
    └── Stop-AVDSessionHost.ps1    # Runbook PowerShell auto-shutdown
```

## 🎯 Arquitectura Desplegada

### Recursos Creados

| Recurso | Nombre | SKU/Tier | Tag | Costo Mensual |
|---------|--------|----------|-----|---------------|
| **Resource Group** | rg-avd-h100-poc | N/A | infrastructure | €0 |
| **Virtual Network** | vnet-avdh100-spaincentral | N/A | infrastructure | €0 |
| **NSG** | nsg-avdh100-avd | N/A | infrastructure | €0 |
| **Storage Account** | stavdh100transfer | Standard LRS | infrastructure | €5 |
| **Log Analytics** | law-avdh100-monitoring | Pay-as-you-go | infrastructure | €5 |
| **AVD Host Pool** | hp-avdh100-personal | Personal | infrastructure | €0 |
| **AVD Workspace** | ws-avdh100-poc | N/A | infrastructure | €0 |
| **Automation Account** | aa-avdh100-auto-shutdown | Basic | infrastructure | €1 |
| **Action Group** | ag-cost-alerts | N/A | infrastructure | €1 |
| **VM** | vm-avdh100-001 | Standard_NC40ads_H100_v5 | session-host | €1,076* |
| **Managed Disk (OS)** | vm-avdh100-001-osdisk | Premium P10 (256GB) | session-host | €8 |
| **Managed Disk (Data)** | vm-avdh100-001-datadisk-001 | Premium P30 (1TB) | session-host | €8 |

**Total Infraestructura:** ~€12/mes  
**Total Workload:** ~€1,092/mes (asumiendo 2.5h/día de uso)

\* Costo de VM calculado con auto-shutdown activo (2.5h diarias × €19.56/hora × 22 días)

### Tags de Control de Costos

- **`workload-type=infrastructure`**: Recursos de soporte (límite: €20/mes)
- **`workload-type=session-host`**: VM y discos (límite: €50/día = €1,500/mes)

## 🚀 Despliegue

### Prerequisitos

1. **Azure CLI** instalado y autenticado
   ```bash
   az --version
   az login
   ```

2. **Subscription** configurada
   ```bash
   az account set --subscription "POC AVD"
   ```

3. **Cuota aprobada** para NC40ads_H100_v5 (40 cores en Spain Central)

4. **Usuario Azure AD** creado para acceso AVD

### Despliegue Automático

```bash
# Dar permisos de ejecución
chmod +x deploy.sh

# Ejecutar script de despliegue
./deploy.sh
```

El script te pedirá:
- Usuario administrador de la VM
- Contraseña del administrador (mín. 12 caracteres)
- Email del usuario Azure AD para AVD
- IP pública (se detecta automáticamente)

**Tiempo estimado:** 30-40 minutos

### Despliegue Manual

```bash
# 1. Validar template
az deployment sub validate \
  --location spaincentral \
  --template-file main.bicep \
  --parameters vmAdminUsername='azureadmin' \
  --parameters vmAdminPassword='TuPasswordSegura123!' \
  --parameters avdUserObjectId='<object-id-usuario>' \
  --parameters allowedSourceIpAddress='<tu-ip>/32'

# 2. Desplegar
az deployment sub create \
  --name "avd-h100-poc-$(date +%Y%m%d-%H%M%S)" \
  --location spaincentral \
  --template-file main.bicep \
  --parameters vmAdminUsername='azureadmin' \
  --parameters vmAdminPassword='TuPasswordSegura123!' \
  --parameters avdUserObjectId='<object-id-usuario>' \
  --parameters allowedSourceIpAddress='<tu-ip>/32'
```

### Obtener Object ID de Usuario

```bash
az ad user show --id usuario@dominio.com --query id -o tsv
```

### Obtener Tu IP Pública

```bash
curl ifconfig.me
```

## 🔐 Seguridad

### Network Security Group (NSG)

**Reglas de entrada:**
- Permitir AVD Gateway (443)
- Permitir AVD Control (1688)
- Permitir RDP desde tu IP (3389)
- Denegar todo lo demás

**Reglas de salida:**
- Permitir Azure Cloud (443)
- Permitir Storage (445)
- Permitir Monitoring (443)
- Permitir Azure AD (443)
- Permitir Windows Update (80, 443)
- Denegar Internet general

### Autenticación

- **VM:** Usuario/contraseña local (proporcionados en deployment)
- **AVD:** Azure AD + MFA (recomendado)
- **Automation Account:** Managed Identity con roles mínimos necesarios

## 📁 Transferencia de Archivos

### Método Recomendado: AzCopy

```bash
# 1. Generar SAS token (válido 24 horas)
az storage container generate-sas \
  --account-name stavdh100transfer \
  --name file-uploads \
  --permissions rwl \
  --expiry $(date -u -d "+1 day" '+%Y-%m-%dT%H:%M:%SZ')

# 2. Subir archivos desde tu PC
azcopy copy 'C:\MisArchivos\*' \
  'https://stavdh100transfer.blob.core.windows.net/file-uploads?<SAS-token>' \
  --recursive

# 3. Descargar en la VM AVD
azcopy copy \
  'https://stavdh100transfer.blob.core.windows.net/file-uploads?<SAS-token>' \
  'D:\DataIn\' \
  --recursive
```

**Velocidad estimada:**
- Upload desde oficina: 50-200 Mbps (10-40 min para 100GB)
- Download en VM: ~1 Gbps (2 min para 100GB)

### Método Alternativo: Azure Storage Explorer

1. Descargar: https://azure.microsoft.com/features/storage-explorer/
2. Conectar con tu cuenta Azure
3. Navegar a `stavdh100transfer` → `file-uploads`
4. Arrastrar archivos

## ⚙️ Auto-Shutdown

### Configuración

- **Trigger:** Azure Automation Schedule (cada 5 minutos)
- **Lógica:** Runbook PowerShell
- **Condición:** Sin sesiones AVD activas durante 15 minutos
- **Acción:** Detener y desasignar VM (PowerState/deallocated)

### Verificar Funcionamiento

```bash
# Ver jobs ejecutados
az automation job list \
  --resource-group rg-avd-h100-poc \
  --automation-account-name aa-avdh100-auto-shutdown \
  --output table

# Ver output de último job
JOB_ID=$(az automation job list \
  --resource-group rg-avd-h100-poc \
  --automation-account-name aa-avdh100-auto-shutdown \
  --query '[0].jobId' -o tsv)

az automation job show \
  --resource-group rg-avd-h100-poc \
  --automation-account-name aa-avdh100-auto-shutdown \
  --job-id $JOB_ID
```

### Deshabilitar Auto-Shutdown

```bash
# Modificar parámetro en deployment
az deployment sub create \
  ... \
  --parameters enableAutoShutdown=false
```

## 📊 Monitoring y Costos

### Dashboard de Costos

1. Portal Azure → **Cost Management + Billing**
2. **Cost Analysis**
3. Filtros:
   - Scope: `rg-avd-h100-poc`
   - Group by: `Tag` → `workload-type`
   - Time range: Last 7 days

### Queries KQL Útiles

**Costo diario por workload type:**
```kusto
AzureCostData
| where TimeGenerated >= ago(30d)
| extend WorkloadType = tostring(Tags['workload-type'])
| summarize DailyCost = sum(Cost) by bin(TimeGenerated, 1d), WorkloadType
| render timechart
```

**Horas de ejecución VM:**
```kusto
AzureActivity
| where OperationNameValue contains "virtualMachines"
| where ResourceId contains "vm-avdh100"
| where OperationNameValue endswith "/start/action" or OperationNameValue endswith "/deallocate/action"
| summarize StartTime = minif(TimeGenerated, OperationNameValue contains "start"),
            StopTime = maxif(TimeGenerated, OperationNameValue contains "deallocate")
    by bin(TimeGenerated, 1d)
| extend RuntimeHours = datetime_diff('hour', StopTime, StartTime)
```

### Alertas Presupuestarias

Configuradas automáticamente:

| Presupuesto | Límite | Alertas |
|-------------|--------|---------|
| **Infrastructure** | €20/mes | 80%, 90%, 100%, Forecast 100% |
| **Workload** | €1,500/mes | 80%, 90%, 100%, Forecast 100% |

**Email de notificación:** Configurado en parámetros (alertEmailAddress)

## 🔧 Conexión al Escritorio AVD

### Web Client (Recomendado)

1. Ir a: https://client.wvd.microsoft.com/arm/webclient
2. Iniciar sesión con tu usuario Azure AD
3. Seleccionar workspace: **H100 VDI Workspace**
4. Click en **Desktop Principal H100**

### Windows Client

1. Descargar: https://aka.ms/wvd/clients/windows
2. Instalar Remote Desktop Client
3. Subscribe a workspace con URL:
   ```
   https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery
   ```
4. Iniciar sesión con Azure AD

### macOS / iOS / Android

Clientes disponibles en App Store / Google Play: **Microsoft Remote Desktop**

## 🛠️ Troubleshooting

### VM no arranca automáticamente al conectar

**Causa:** Configuración `startVMOnConnect` no habilitada

**Solución:**
```bash
az desktopvirtualization hostpool update \
  --resource-group rg-avd-h100-poc \
  --name hp-avdh100-personal \
  --start-vm-on-connect true
```

### No puedo ver el workspace en AVD client

**Causa:** Usuario no asignado al Application Group

**Solución:**
```bash
az role assignment create \
  --assignee <usuario-email> \
  --role "Desktop Virtualization User" \
  --scope $(az desktopvirtualization applicationgroup show \
    --resource-group rg-avd-h100-poc \
    --name ag-avdh100-desktop \
    --query id -o tsv)
```

### Drivers NVIDIA no instalados

**Causa:** Extensión GPU Driver falló

**Verificar:**
```bash
az vm extension show \
  --resource-group rg-avd-h100-poc \
  --vm-name vm-avdh100-001 \
  --name NvidiaGpuDriverWindows
```

**Reinstalar:**
```bash
az vm extension set \
  --resource-group rg-avd-h100-poc \
  --vm-name vm-avdh100-001 \
  --name NvidiaGpuDriverWindows \
  --publisher Microsoft.HpcCompute \
  --version 1.6
```

### Costos excediendo presupuesto

1. **Verificar estado VM:**
   ```bash
   az vm show -d \
     --resource-group rg-avd-h100-poc \
     --name vm-avdh100-001 \
     --query powerState
   ```

2. **Detener VM manualmente:**
   ```bash
   az vm deallocate \
     --resource-group rg-avd-h100-poc \
     --name vm-avdh100-001
   ```

3. **Revisar logs auto-shutdown:**
   ```bash
   az automation job list \
     --resource-group rg-avd-h100-poc \
     --automation-account-name aa-avdh100-auto-shutdown
   ```

## 🗑️ Limpieza (Eliminar Todo)

```bash
# ADVERTENCIA: Esto eliminará TODOS los recursos y datos

az group delete --name rg-avd-h100-poc --yes --no-wait
```

## 📚 Referencias

- [Arquitectura AVD](../docs/AVD_H100_POC_ARCHITECTURE.md)
- [CUDA Compatibility](../docs/PIX4D_CUDA_COMPATIBILITY.md)
- [Pricing Comparison](../docs/PIX4D_VM_PRICING_COMPARISON.md)
- [Azure AVD Documentation](https://docs.microsoft.com/azure/virtual-desktop/)
- [NVIDIA H100 Specs](https://www.nvidia.com/en-us/data-center/h100/)

## 📧 Soporte

Para problemas o preguntas: a.almeida@prodware.es
