# Meta‑contexto para **Azure Agent Pro** — Laboratorio PIX4Dmatic sobre Azure Virtual Desktop (AVD)

> Rama propuesta: `feature/avd-pix4d-lab`  
> Objetivo: Generar **infraestructura como código** + **automatizaciones** para un laboratorio docente de **PIX4Dmatic** usando **AVD con GPU** y **pago estrictamente por uso** (encendido bajo demanda / deasignación tras uso), con **mejores prácticas de Azure**.

---

## 1) Resultado esperado (Definition of Done)

1. **IaC lista para desplegar** en `infra/` con _Bicep_ (preferente) y _Terraform_ (opcional) para:
   - Host pool **AVD Personal** (1 VM dedicada por alumno).
   - VM SKU **NVads A10 v5** parametrizable (`NV36ads`, `NV18ads`, `NV12ads`).
   - **Start VM on Connect** activado.
   - **Apagado + deasignación** tras inactividad o al cerrar sesión.
   - Perfiles **FSLogix** en **Azure Files Premium** (NTFS ACL + AD DS/AAD DS).
   - **Log Analytics** + **Azure Monitor** (métricas/alertas) y **Cost Management** (alertas).
   - **Azure Image Builder** para imagen dorada con **driver NVIDIA A10** y _software base_ (prerrequisitos PIX4Dmatic).
2. **Automatización** en `ops/`:
   - Runbook/Function para **apagado/deallocate** de hosts fuera de ventana docente.
   - GitHub Actions: `deploy.yml`, `destroy.yml`, `image-build.yml`, `lint.yml`.
3. **Seguridad y gobierno**:
   - `policy/` con Azure Policy para restringir tamaños, etiquetas obligatorias y _compliance_.
   - `rbac/` con definiciones de roles/grupos (alumnos/profesores/operaciones).
4. **Documentación** en `docs/`:
   - Guía de **costes por hora** por SKU (variables regionales).
   - _Runbook_ docente (checklist de clase y carga de datasets).
   - Troubleshooting GPU/FSLogix/AVD.
5. **Pruebas**:
   - `tests/` incluye pruebas de humo post‑deploy (Az CLI/PowerShell) y verificación de GPU (`nvidia-smi`).
   - Escenario E2E: conectar, procesar dataset de ejemplo, validar que el coste se detiene tras deallocate.

---

## 2) Alcance funcional (User Stories)

- **US‑1**: Como alumno, quiero **conectarme** y que la **VM arranque sola** si está apagada, para trabajar al instante.
- **US‑2**: Como alumno, al **cerrar sesión** o tras inactividad, la VM debe **apagarse y deasignarse** para **no facturar cómputo**.
- **US‑3**: Como profesor, quiero **3 perfiles de potencia** (NV12/NV18/NV36) para asignarlos según el tamaño del proyecto.
- **US‑4**: Como operador, quiero **cost alerts** y **tags obligatorias** (`owner`, `env=lab`, `courseId`, `costCenter`).

---

## 3) Arquitectura objetivo (alto nivel)

```
Alumno ↔ AVD (Gateway/Broker) ↔ Host Pool Personal (NVads A10 v5)
                                  ├─ Session Host VM (GPU A10 vGPU)
                                  ├─ Start VM on Connect (auto‑power on)
                                  ├─ Auto-shutdown + deallocate (runbook/func)
                                  ├─ FSLogix profiles → Azure Files Premium
                                  └─ Insights: Log Analytics + Azure Monitor
                                    └─ Cost Mgmt + Budget/Alerts
Imagen base: Azure Image Builder (NVIDIA driver + prereqs PIX4Dmatic)
```

**Notas clave**:
- **Pago por uso**: Solo se factura compute cuando la VM está **Running**. En **Stopped (deallocated)** no se factura compute; los **discos** sí.
- **GPU**: serie **NVads A10 v5** (vGPU). Preferencia por **NV36ads A10 v5** (24 GB VRAM) para datasets muy grandes.
- **Perfiles**: FSLogix en **Azure Files Premium** para desconexión limpia y movilidad.
- **Observabilidad**: Kusto queries y alertas ante VMs que queden **Stopped (allocated)** accidentalmente.

---

## 4) Parámetros operativos (por defecto)

- `region`: `westeurope`
- `sku`: `NV36ads_A10_v5` (alternativas: `NV18ads_A10_v5`, `NV12ads_A10_v5`)
- `vmImage`: imagen AIB `pix4d-avd-gpu-v1`
- `avdPersonalDesktopAssignmentType`: `Automatic`
- `enableStartVmOnConnect`: `true`
- `idleDeallocateMinutes`: `30` (parametrizable)
- `classWindowUtc`: `16:00-21:00` (ejemplo; para apagado programado fuera de horario)
- `fslogixShareTier`: `Premium`
- `budgetMonthlyEUR`: `300`
- `tags`: `{ env: "lab", project: "fotogrametria-azure-ia", owner: "alumnos", costCenter: "training" }`

---

## 5) Estructura del repositorio (rama `feature/avd-pix4d-lab`)

```
/infra
  /bicep
    main.bicep
    modules/avd/ *.bicep
    modules/storage/ *.bicep
    modules/imagebuilder/ *.bicep
    modules/monitoring/ *.bicep
  /terraform (opcional)
/ops
  runbooks/auto-deallocate.ps1
  functions/auto-deallocate (C# or Python)
  scripts/post-deploy/verify-gpu.ps1
/.github/workflows
  deploy.yml
  destroy.yml
  image-build.yml
  lint.yml
/policy
  allowed-skus.json
  required-tags.json
/rbac
  groups.tf|bicep.json
  role-assignments.ps1
/docs
  README.md
  costs.md
  operations.md
  troubleshooting.md
/tests
  smoke/az-smoke.ps1
  e2e/check-start-stop.ps1
```

---

## 6) Generación de código — **Instrucciones al Agente**

1. **Bicep**:
   - `main.bicep`: orquestación de RG, VNet/subnets, Key Vault, Storage (Azure Files), Log Analytics, Host Pool, App Group, Workspace, Session Hosts (VMSS o ARM template specs), roles, políticas.
   - Módulos:
     - `modules/avd/hostpool.bicep`, `workspace.bicep`, `appgroup.bicep`, `sessionhost.bicep` (con Start VM on Connect).
     - `modules/storage/azurefiles.bicep` con NTFS ACL + AD (o AAD DS) + configuración FSLogix (`profiles` share, GPO JSON/registry).
     - `modules/imagebuilder/aib.bicep` para hornear imagen con **NVIDIA A10 driver**, **Visual C++ runtimes**, .NET, DirectX, **prerrequisitos** de PIX4Dmatic (el instalador final puede ser manual/licencia BYOL).
     - `modules/monitoring/insights.bicep` (LAW, DCR, DCE, alertas métricas) y `cost/budget.bicep`.
     - `modules/automation/auto-shutdown.bicep` (Automation Account + runbook o Function + Timer/HTTP trigger).
   - **Variables/param** para SKU NVads A10 v5 (NV12/NV18/NV36) y tamaño de disco SO/Temp/Data (Premium SSD v2 si aplica).

2. **Runbooks / Functions**:
   - `auto-deallocate.ps1`: detectar VMs del host pool en `Stopped` (allocated) y **Deallocate**; opción de **apagar fuera de ventana**; excluir `maintenance=true`.
   - `sessionIdleWatcher` (opcional): escucha de eventos de cierre de sesión para _deallocate_ inmediato.

3. **GitHub Actions**:
   - `deploy.yml`: lint bicep, _what-if_, aprobación manual, `az deployment sub create`/`group create`.
   - `image-build.yml`: construir imagen AIB en PR/merge; versionado semántico.
   - `destroy.yml`: despliegue inverso (con confirmación).
   - `lint.yml`: Bicep linter + PSRule for Azure.

4. **Policies y RBAC**:
   - `allowed-skus`: permitir solo `NVads_A10_v5` y tamaños `Standard_NV12/18/36ads_A10_v5`.
   - `required-tags`: `env`, `project`, `owner`, `costCenter`.
   - RBAC mínimo: `Desktop Virtualization Contributor` para operadores; `Reader` para docentes; `Virtual Machine Contributor` para runbook.

5. **Observabilidad**:
   - KQL de ejemplo: VMs activas > X horas, estados `Stopped (allocated)`, consumo A10 vGPU, fallos FSLogix.
   - Alertas: VM Running fuera de ventana, sin GPU, sin heartbeat, coste diario > umbral.

6. **Coste por hora (informativo)**:
   - Variable `vmHourlyUSD` por SKU (ej. `NV36≈3.20`, `NV18≈1.60`, `NV12≈0.91`) y `regionMultiplier` (tabla simple). *No usar valores fijos para facturación, solo referenciales.*

---

## 7) MCP Servers recomendados (Model Context Protocol)

> Objetivo: dotar al Agente de herramientas con **alto contexto operativo** para generar/validar IaC y operar Azure/GitHub con autonomía controlada. Las credenciales irán vía variables/OIDC.

| Servidor MCP | Propósito | Notas de configuración mínima |
|---|---|---|
| **filesystem** | Leer/escribir en el repo | Sandboxado a la raíz del proyecto. |
| **shell / powershell** | Ejecutar `az`, `bicep`, `pwsh` | Limitar comandos peligrosos; timeout. |
| **http(s)** | Consumir documentación oficial | Lista de allow‑domains (learn.microsoft.com, docs.microsoft.com, github.com). |
| **azure-cli** | Operar Azure vía `az` | Autenticación OIDC GitHub → Azure (federación). |
| **azure-arm** | Llamadas REST ARM/Deployments | Para `what-if`, plantillas y operaciones no cubiertas por CLI. |
| **azure-monitor** | Logs/alertas (KQL) | Lectura LAW; validar que las métricas/alertas se crean. |
| **azure-cost** | Cost Management (presupuestos/alerts) | Lectura presupuestos y gastos diarios. |
| **github** | PRs, ramas, Issues, Actions | Firmar commits; convenciones Conventional Commits. |
| **git** | Operaciones de bajo nivel | Rebase/merge automáticos (con política). |
| **docker** | Construcción de contenedores de build | Imagen para AIB scripts/linter. |
| **openapi-http** | Generar clientes de APIs | Para servicios secundarios si hiciera falta. |

### Ejemplo de configuración (esquema JSON simplificado)

```jsonc
{
  "mcpServers": [
    { "name": "filesystem", "type": "filesystem", "root": "." },
    { "name": "shell", "type": "shell", "allowed": ["az", "pwsh", "bicep", "jq"] },
    { "name": "http", "type": "http", "allowDomains": ["learn.microsoft.com", "github.com", "docs.microsoft.com"] },
    { "name": "azure-cli", "type": "process", "command": "az", "auth": "federatedOIDC" },
    { "name": "azure-arm", "type": "http", "baseUrl": "https://management.azure.com", "auth": "azureAD" },
    { "name": "azure-monitor", "type": "http", "baseUrl": "https://api.loganalytics.io", "auth": "azureAD" },
    { "name": "azure-cost", "type": "http", "baseUrl": "https://management.azure.com/providers/Microsoft.CostManagement", "auth": "azureAD" },
    { "name": "github", "type": "http", "baseUrl": "https://api.github.com", "auth": "githubAppOIDC" }
  ]
}
```

> **Credenciales**: usar **OIDC (workload identity)** entre GitHub Actions y Azure; mínimo privilegio; secretos rotados; `AZURE_CLIENT_ID`/`TENANT_ID`/`SUBSCRIPTION_ID` como variables protegidas. Para GitHub, usar GitHub App o token de entorno con permisos mínimos.

---

## 8) Plantillas iniciales a generar (esqueleto)

### `infra/bicep/main.bicep` (extracto)

```bicep
param location string = 'westeurope'
param sku string = 'Standard_NV36ads_A10_v5'
param enableStartVmOnConnect bool = true
param idleDeallocateMinutes int = 30
param classWindow string = '16:00-21:00'
param fslogixShareTier string = 'Premium'
param tags object = { env: 'lab', project: 'fotogrametria-azure-ia', costCenter: 'training' }

// RG, VNet, Key Vault, Storage (Azure Files), Log Analytics
module storage 'modules/storage/azurefiles.bicep' = { ... }
module monitor 'modules/monitoring/insights.bicep' = { ... }
module avd 'modules/avd/hostpool.bicep' = { ... }
module aib 'modules/imagebuilder/aib.bicep' = { ... }
module auto 'modules/automation/auto-shutdown.bicep' = { ... }
```

### `ops/runbooks/auto-deallocate.ps1` (extracto)

```powershell
# Encuentra VMs del host pool en Stopped (allocated) y las deasigna
$vmList = Get-AzVM -Status | Where-Object { $_.PowerState -eq 'VM stopped' }
foreach ($vm in $vmList) {
  Write-Output "Deallocating $($vm.Name)"
  Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force -NoWait
}
```

### `.github/workflows/deploy.yml` (extracto)

```yaml
name: deploy
on:
  workflow_dispatch:
  push:
    branches: [ "feature/avd-pix4d-lab" ]
jobs:
  bicep-deploy:
    permissions:
      id-token: write
      contents: read
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - uses: Azure/cli@v2
        with:
          inlineScript: |
            az deployment sub create \
              --name avd-lab-$(date +%s) \
              --location westeurope \
              --template-file infra/bicep/main.bicep \
              --parameters sku=Standard_NV36ads_A10_v5 enableStartVmOnConnect=true idleDeallocateMinutes=30
```

---

## 9) Buenas prácticas (checklist)

- **Pay‑per‑use**: `Start VM on Connect` + **deallocate** siempre (no `Stopped/Allocated`).
- **Imagen dorada** con **AIB**; versionado semántico; drift control.
- **FSLogix**: excluir caches pesadas de proyectos si se guardan en disco de datos.
- **Coste**: presupuesto y alertas; etiquetas obligatorias.
- **Security**: Managed Identities, Key Vault, RBAC mínimo; Defender for Cloud habilitado (plan básico).
- **Observabilidad**: LAW + alertas; KQL de VMs activas > X h; métricas GPU si disponibles.
- **Región**: `westeurope` (latencia para Madrid) salvo necesidades de capacidad.

---

## 10) Datos operativos de PIX4Dmatic (contexto para sizing)

- **CPU**: alto rendimiento por núcleo; escalan múltiples hilos en fases de densa.
- **RAM**: 64–440 GiB según tamaño del proyecto (para miles de imágenes grandes, apuntar a **NV36ads**).
- **GPU**: NVIDIA A10 (vGPU) con 8–24 GB VRAM; preferir 24 GB para datasets muy grandes.
- **Disco**: SSD Premium; datasets grandes requieren +500 GB temporales/resultado. Parametrizar discos de datos por alumno.

> El instalador/licencia de **PIX4Dmatic** es **BYOL**. El pipeline instalará **drivers NVIDIA** y **prerrequisitos**; la aplicación puede distribuirse por `WinGet`/`Intune`/script si el EULA lo permite o dejar **manual step** documentado.

---

## 11) Tareas iniciales para el agente

1. Crear rama `feature/avd-pix4d-lab` y estructura de carpetas.
2. Generar **Bicep** y módulos indicados con parámetros.
3. Crear **workflows** de GitHub con OIDC → Azure y secretos mínimos.
4. Implementar **runbook** o **Function** de deallocate + programador.
5. Añadir **Policy** de SKUs permitidos y **tags obligatorias**.
6. Documentar **cómo asignar** una VM por alumno y cómo escalarlas de NV18→NV36.
7. Añadir `tests/` para verificar GPU (`nvidia-smi`) y estado de FSLogix.
8. Publicar `docs/` con guía de costes por hora y mejores prácticas.

---

## 12) Convenciones

- **Conventional Commits**, **semantic‑versioning** para imagen AIB.
- Código con **lint** (Bicep linter, PSRule for Azure), `pre-commit` opcional.
- Todo recurso con `tags` obligatorias.

---

> **Fin del meta‑contexto**. A partir de aquí, Azure Agent Pro debe generar el esqueleto y PRs automáticos, además de ejecutar validaciones y preparar la documentación operativa.
