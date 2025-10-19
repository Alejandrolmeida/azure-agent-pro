# Guía de Costes - AVD PIX4D Lab

## 📊 Desglose de Costes

### Compute (VMs con GPU)

**Solo se factura cuando la VM está en estado "Running"**

| SKU | Descripción | Coste/hora (€) | 8h/día x 22 días | Uso Recomendado |
|-----|-------------|----------------|------------------|-----------------|
| **NV12ads_A10_v5** | 12 vCPU, 110 GB RAM, 8 GB VRAM | ~0.91 | ~160€/mes | Proyectos pequeños, aprendizaje |
| **NV18ads_A10_v5** | 18 vCPU, 220 GB RAM, 12 GB VRAM | ~1.60 | ~281€/mes | Proyectos medianos, uso general |
| **NV36ads_A10_v5** | 36 vCPU, 440 GB RAM, 24 GB VRAM | ~3.20 | ~563€/mes | Proyectos grandes, producción |

> ⚠️ **Importante**: VMs en estado "Stopped (allocated)" siguen facturando. Usar **deallocate** siempre.

### Storage

| Componente | SKU | Capacidad | Coste mensual |
|------------|-----|-----------|---------------|
| **FSLogix Profiles** | Azure Files Premium | 1 TB | ~150€ |
| **OS Disks** | Premium SSD (127 GB) | 10 VMs | ~150€ |
| **Data Disks** | Premium SSD (512 GB) | 10 VMs | ~600€ |

### Networking

| Componente | Coste mensual |
|------------|---------------|
| VNet, Subnets, NSGs | 0€ |
| Private Endpoints (3) | ~21€ |
| Egress (estimado) | ~10€ |

### Monitoring & Automation

| Componente | Coste mensual |
|------------|---------------|
| Log Analytics (5 GB/mes) | ~10€ |
| Automation Account | 0€ (primeras 500 min gratis) |
| Azure Monitor Alerts | ~2€ |

## 💡 Estimaciones por Escenario

### Escenario 1: Lab Pequeño (5 alumnos, NV12)
- **Compute**: 5 VMs × €0.91/h × 8h/día × 22 días = **€800/mes**
- **Storage**: Profiles (500GB) + Disks = **€500/mes**
- **Otros**: Networking + Monitoring = **€50/mes**
- **TOTAL**: **~€1,350/mes**

### Escenario 2: Lab Mediano (10 alumnos, NV18)
- **Compute**: 10 VMs × €1.60/h × 8h/día × 22 días = **€2,816/mes**
- **Storage**: Profiles (1TB) + Disks = **€900/mes**
- **Otros**: Networking + Monitoring = **€50/mes**
- **TOTAL**: **~€3,766/mes**

### Escenario 3: Lab Grande (20 alumnos, NV36)
- **Compute**: 20 VMs × €3.20/h × 8h/día × 22 días = **€11,264/mes**
- **Storage**: Profiles (2TB) + Disks = **€1,800/mes**
- **Otros**: Networking + Monitoring = **€100/mes**
- **TOTAL**: **~€13,164/mes**

## 🎯 Estrategias de Optimización

### 1. Deallocate Agresivo ✅
```powershell
# El runbook hace esto automáticamente
Stop-AzVM -ResourceGroupName $rg -Name $vm -Force
```
**Ahorro**: 60-80% del coste de compute

### 2. Ventanas de Clase Definidas 📅
```bicep
param classWindow = '08:00-20:00'  // Solo activo en este horario
```
**Ahorro**: 33% (16h apagado vs 24h)

### 3. SKU Adecuado por Proyecto 🎚️
- **Intro/Learning**: NV12ads (datasets < 1000 imágenes)
- **General**: NV18ads (datasets 1000-5000 imágenes)
- **Advanced**: NV36ads (datasets > 5000 imágenes)

**Ahorro**: 50-70% usando NV12 vs NV36 donde sea posible

### 4. Storage Lifecycle Management 📦
```bash
# Eliminar perfiles de alumnos antiguos
az storage file delete --account-name $storage --share-name profiles
```
**Ahorro**: €150 por cada TB no usado

### 5. Reserved Instances (Prod) 💎
Para uso constante > 6 meses, considerar **Azure Reserved Instances**
**Ahorro**: 30-40% del coste de compute

## 📈 Monitorización de Costes

### Cost Alerts Configuradas

1. **Daily Budget Alert**
   - Umbral: 80% del presupuesto diario
   - Acción: Email a operaciones

2. **Monthly Budget Alert**
   - Umbral: 90% del presupuesto mensual
   - Acción: Email + bloqueo de nuevas VMs

3. **VM Running > 12h Alert**
   - Detecta VMs que no se apagan
   - Acción: Email + log

### Dashboard de Costes

Acceder vía Azure Portal:
```
Cost Management → Cost Analysis → Resource Group: rg-pix4d-avd-*
```

**Métricas clave**:
- Coste por día
- Coste por VM
- Coste por servicio (Compute, Storage, Network)
- Tendencia mensual

### Queries KQL Útiles

```kusto
// VMs activas > 8h hoy
AzureActivity
| where TimeGenerated > ago(24h)
| where OperationNameValue == "Microsoft.Compute/virtualMachines/start/action"
| summarize StartCount=count() by Resource
| where StartCount > 1

// Coste por tag
CostManagement
| where TimeGenerated > ago(30d)
| summarize TotalCost=sum(Cost) by tostring(Tags.project)
```

## 🚨 Red Flags de Costes

| Síntoma | Problema | Solución |
|---------|----------|----------|
| Coste > 2x estimado | VMs no deallocated | Verificar runbook automation |
| Storage creciendo 10%/mes | Perfiles no limpiados | Implementar lifecycle policy |
| VMs running 24/7 | Start VM on Connect fallando | Verificar host pool settings |
| Alta factura networking | Egress excesivo | Revisar arquitectura, usar Private Endpoint |

## 📋 Checklist Mensual

- [ ] Revisar Cost Analysis dashboard
- [ ] Verificar alertas de presupuesto
- [ ] Auditar VMs stopped (allocated)
- [ ] Limpiar perfiles FSLogix antiguos
- [ ] Revisar tags de costes
- [ ] Validar deallocate schedule
- [ ] Comparar coste real vs. estimado

## 🔗 Recursos

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [AVD Pricing](https://azure.microsoft.com/pricing/details/virtual-desktop/)
- [Cost Management Best Practices](https://learn.microsoft.com/azure/cost-management-billing/costs/cost-mgt-best-practices)
