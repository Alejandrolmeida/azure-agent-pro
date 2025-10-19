# Azure Virtual Desktop para PIX4Dmatic - Laboratorio Docente

## 📋 Descripción

Este PR implementa una **solución completa de Infraestructura como Código (IaC)** para desplegar un laboratorio de **Azure Virtual Desktop** optimizado para cargas de trabajo de **PIX4Dmatic** con GPU NVIDIA A10, con **pago estrictamente por uso** y **automatización completa**.

## ✨ Características Principales

### 💰 Optimización de Costes
- ✅ **Start VM on Connect**: Las VMs arrancan automáticamente al conectarse
- ✅ **Auto-deallocate**: Apagado y deasignación automática tras inactividad
- ✅ **Ventanas de clase configurables**: Apagado fuera de horario docente
- ✅ **Zero-cost cuando no se usa**: Solo se paga compute cuando las VMs están Running

### 🎮 GPU NVIDIA A10 vGPU
- ✅ Serie **NVads A10 v5** con 3 SKUs disponibles (12/18/36 cores)
- ✅ Hasta **24 GB VRAM** para datasets grandes de fotogrametría
- ✅ Drivers NVIDIA instalados automáticamente vía Azure Image Builder
- ✅ Optimizaciones de Windows para workloads GPU

### 🔄 Automatización Completa
- ✅ Despliegue declarativo con **Bicep**
- ✅ CI/CD con **GitHub Actions** (deploy, destroy, lint, image-build)
- ✅ Autenticación **OIDC** (sin passwords almacenados)
- ✅ Runbooks de mantenimiento automático

### 📊 Observabilidad y Governance
- ✅ **Log Analytics** con queries KQL predefinidas
- ✅ **Azure Monitor** con 3 alertas críticas
- ✅ **Cost Management** integrado
- ✅ **Azure Policy** para compliance

## 📦 Archivos Añadidos

### Infraestructura (Bicep)
```
infra/bicep/
├── main.bicep                          # Orquestador principal
├── parameters/
│   ├── lab.bicepparam                  # Parámetros para laboratorio
│   └── prod.bicepparam                 # Parámetros para producción
└── modules/
    ├── avd/                            # Azure Virtual Desktop
    │   ├── hostpool.bicep
    │   ├── workspace.bicep
    │   ├── appgroup.bicep
    │   └── sessionhost.bicep
    ├── storage/
    │   └── azurefiles.bicep            # FSLogix con Premium Files
    ├── imagebuilder/
    │   └── aib.bicep                   # Imagen dorada con NVIDIA
    ├── monitoring/
    │   └── insights.bicep              # Log Analytics + Alertas
    ├── automation/
    │   └── auto-shutdown.bicep         # Auto-deallocate
    ├── virtual-network.bicep           # VNet + Subnets + NSGs
    └── role-assignment.bicep           # RBAC
```

### Automatización
```
ops/
└── runbooks/
    └── auto-deallocate.ps1             # Runbook PowerShell

.github/workflows/
├── deploy.yml                          # Despliegue automatizado
├── destroy.yml                         # Destrucción segura
├── image-build.yml                     # Build de imágenes
└── lint.yml                            # Linting y calidad
```

### Governance
```
policy/
├── allowed-skus.json                   # Solo NVads A10 v5
├── required-tags.json                  # Tags obligatorias
└── enforce-auto-shutdown.json          # Enforcement de shutdown
```

### Testing
```
tests/
├── smoke/
│   └── az-smoke.ps1                    # 12 validaciones básicas
└── e2e/
    └── check-start-stop.ps1            # Test ciclo completo
```

### Documentación
```
docs/
├── costs.md                            # Guía de costes y optimización
└── OIDC_SETUP.md                       # Configuración OIDC/GitHub

infra/README.md                         # Documentación principal
PROJECT_SUMMARY.md                      # Resumen del proyecto
```

## 📊 Métricas

- **Archivos nuevos**: 28
- **Líneas de código**: 4,536
- **Módulos Bicep**: 10
- **Workflows CI/CD**: 4
- **Azure Policies**: 3
- **Tests**: 2 suites (smoke + e2e)

## 🏗️ Arquitectura

```
Azure Subscription
├── Resource Groups (4)
│   ├── rg-pix4d-avd-{env}-{location}          [Main: AVD + VMs]
│   ├── rg-pix4d-avd-networking-{env}-{location}
│   ├── rg-pix4d-avd-images-{env}-{location}
│   └── rg-pix4d-avd-monitoring-{env}-{location}
│
├── AVD Components
│   ├── Host Pool (Personal, Start VM on Connect)
│   ├── Workspace
│   ├── Application Group (Desktop)
│   └── Session Hosts (NVads A10 v5 con GPU)
│
├── Storage
│   ├── Azure Files Premium (FSLogix)
│   └── Private Endpoint
│
├── Monitoring
│   ├── Log Analytics Workspace
│   ├── Data Collection Rules
│   ├── Alert Rules (3)
│   └── Action Groups
│
└── Automation
    ├── Automation Account
    ├── Runbook (auto-deallocate)
    └── Schedule (cada 15 min)
```

## 💰 Estimación de Costes

### Escenario Lab (10 alumnos, NV18, 8h/día)
- **Compute**: ~€2,816/mes
- **Storage**: ~€900/mes
- **Networking + Monitoring**: ~€50/mes
- **TOTAL**: **~€3,766/mes**

**Con auto-deallocate**: Ahorro del 60-80% vs VMs siempre encendidas

## ✅ Testing

### Smoke Tests
```bash
pwsh tests/smoke/az-smoke.ps1 -Environment lab
```
Valida 12 componentes críticos.

### E2E Tests
```bash
pwsh tests/e2e/check-start-stop.ps1 -Environment lab
```
Prueba el ciclo completo de Start/Stop/Deallocate.

## 🚀 Despliegue

### Prerequisitos
1. Configurar OIDC siguiendo `docs/OIDC_SETUP.md`
2. Configurar GitHub Secrets:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   - `AVD_ADMIN_PASSWORD`

### Vía GitHub Actions (Recomendado)
```bash
# Al hacer merge, se despliega automáticamente
git checkout main
git merge feature/avd-pix4d
git push
```

### Manual
```bash
az deployment sub create \
  --name avd-pix4d-lab \
  --location westeurope \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/lab.bicepparam \
  --parameters adminPassword='<PASSWORD>'
```

## 📚 Documentación

- **[README Principal](infra/README.md)**: Guía completa con arquitectura, costes y ejemplos
- **[Guía de Costes](docs/costs.md)**: Estrategias de optimización y estimaciones
- **[OIDC Setup](docs/OIDC_SETUP.md)**: Configuración de autenticación segura
- **[Project Summary](PROJECT_SUMMARY.md)**: Resumen técnico completo

## 🔐 Seguridad

- ✅ Autenticación OIDC (sin passwords en repos)
- ✅ Managed Identities para servicios
- ✅ Private Endpoints para storage
- ✅ Azure AD Join por defecto
- ✅ Network Security Groups
- ✅ Azure Policy enforcement

## 📋 Checklist

- [x] Infraestructura como código completa (Bicep)
- [x] Start VM on Connect habilitado
- [x] Auto-deallocate implementado
- [x] FSLogix con Azure Files Premium
- [x] Azure Image Builder con drivers NVIDIA
- [x] Monitoring y alertas configuradas
- [x] CI/CD workflows (deploy, destroy, lint, image-build)
- [x] Azure Policies para governance
- [x] Smoke tests y E2E tests
- [x] Documentación completa
- [x] OIDC setup documentado
- [x] Guía de costes y optimización
- [x] Support para 3 SKUs (NV12/18/36)

## 🎯 Próximos Pasos (Post-Merge)

1. Configurar OIDC en Azure AD
2. Añadir secrets en GitHub
3. Actualizar parámetros de environment
4. Ejecutar primer despliegue
5. Validar con smoke tests
6. Instalar PIX4Dmatic (manual/licencia BYOL)
7. Asignar escritorios a alumnos

## 🙏 Referencias

- Implementa requisitos de: `avd-pix4d/azure-agent-pro-metacontexto-avd-pix4d.md`
- Basado en mejores prácticas de Azure AVD
- Optimizado para cargas de trabajo PIX4Dmatic

---

**Tipo**: Feature  
**Impacto**: Major (nueva funcionalidad completa)  
**Breaking Changes**: No  
**Requiere acción**: Sí (configurar OIDC y secrets)

**Revisor sugerido**: @alejandrolmeida  
**Etiquetas**: `feature`, `avd`, `bicep`, `gpu`, `pix4d`, `infrastructure`
