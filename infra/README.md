# Azure Virtual Desktop para PIX4Dmatic - Laboratorio Docente

> 🚀 **Infraestructura como Código** para un laboratorio de Azure Virtual Desktop optimizado para cargas de trabajo de **PIX4Dmatic** con GPU NVIDIA A10, **pago por uso** estricto y **automatización completa**.

[![Deploy](https://github.com/alejandrolmeida/azure-agent-pro/actions/workflows/deploy.yml/badge.svg)](https://github.com/alejandrolmeida/azure-agent-pro/actions/workflows/deploy.yml)
[![Lint](https://github.com/alejandrolmeida/azure-agent-pro/actions/workflows/lint.yml/badge.svg)](https://github.com/alejandrolmeida/azure-agent-pro/actions/workflows/lint.yml)

## 📋 Tabla de Contenidos

- [Características Principales](#-características-principales)
- [Arquitectura](#-arquitectura)
- [Requisitos Previos](#-requisitos-previos)
- [Inicio Rápido](#-inicio-rápido)
- [Costes](#-costes)
- [Documentación](#-documentación)
- [Contribuir](#-contribuir)

## ✨ Características Principales

### 💰 Optimizado para Pago por Uso
- **Start VM on Connect**: Las VMs arrancan automáticamente al conectarse
- **Auto-deallocate**: Apagado y deasignación automática tras inactividad o fuera de horario
- **Zero-cost cuando no se usa**: Solo pagas por compute cuando las VMs están en ejecución

### 🎮 GPU NVIDIA A10 vGPU
- Serie **NVads A10 v5** (12/18/36 cores)
- Hasta **24 GB VRAM** para datasets grandes
- Drivers NVIDIA instalados automáticamente
- Optimizado para **fotogrametría** y procesamiento intensivo

### 🔄 Automatización Completa
- Despliegue con **Bicep** (IaC)
- CI/CD con **GitHub Actions**
- Azure Image Builder para imagen dorada
- Runbooks de mantenimiento automático

### 📊 Observabilidad y Governance
- **Log Analytics** + Azure Monitor
- **Cost Management** con alertas
- **Azure Policy** para compliance
- **Dashboards** de utilización

### 🎓 Diseñado para Formación
- Escritorios **personales** (1 VM por alumno)
- Perfiles **FSLogix** en Azure Files Premium
- Configuración por perfiles de potencia
- Documentación operativa completa

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Virtual Desktop                       │
│  ┌─────────────┐    ┌──────────────────────────────────────┐   │
│  │   Gateway   │───▶│  Host Pool Personal (NVads A10 v5)   │   │
│  │   Broker    │    │  ┌────────────┐  ┌────────────┐      │   │
│  └─────────────┘    │  │ Session    │  │ Session    │      │   │
│                     │  │ Host VM    │  │ Host VM    │ ...  │   │
│                     │  │ (GPU A10)  │  │ (GPU A10)  │      │   │
│                     │  └────────────┘  └────────────┘      │   │
│                     │         │               │             │   │
│                     └─────────┼───────────────┼─────────────┘   │
└───────────────────────────────┼───────────────┼─────────────────┘
                                │               │
                    ┌───────────▼───────────────▼──────────┐
                    │   FSLogix Profiles (Azure Files)     │
                    │        Premium / Zone Redundant       │
                    └──────────────────────────────────────┘
                                │
                    ┌───────────▼──────────────────────────┐
                    │  Monitoring & Automation             │
                    │  • Log Analytics                     │
                    │  • Azure Monitor Alerts              │
                    │  • Automation Account (Auto-shutdown)│
                    │  • Cost Management                   │
                    └──────────────────────────────────────┘
```

### Componentes Clave

| Componente | Descripción | SKU/Tier |
|------------|-------------|----------|
| **Session Hosts** | VMs con GPU para PIX4D | NV12/18/36ads A10 v5 |
| **Storage** | Perfiles FSLogix | Azure Files Premium |
| **Networking** | VNet con subnets aisladas | Standard |
| **Monitoring** | Observabilidad completa | Log Analytics |
| **Automation** | Auto-shutdown/deallocate | Automation Account |
| **Image** | Imagen dorada con drivers | Azure Image Builder |

## 🔧 Requisitos Previos

### En Azure
- Suscripción de Azure con permisos de **Owner** o **Contributor**
- Service Principal con permisos para crear recursos
- Cuota disponible para **NVads A10 v5** en la región elegida

### Entorno de Desarrollo (Miniconda/Conda Recomendado)

Este proyecto está optimizado para funcionar en entornos **Conda/Miniconda** y es completamente multiplataforma (Linux, macOS, Windows).

#### Setup Rápido con Script Automatizado

```bash
# Clonar repositorio
git clone https://github.com/alejandrolmeida/azure-agent-pro.git
cd azure-agent-pro
git checkout feature/avd-pix4d-lab

# Crear entorno conda (recomendado)
conda create -n avd-pix4d python=3.11
conda activate avd-pix4d

# Ejecutar script de setup automatizado
./setup-dev-env.sh
```

Este script instala automáticamente:
- ✅ Azure CLI (>= 2.50.0)
- ✅ Bicep CLI (>= 0.20.0)
- ✅ jq (procesamiento JSON)
- ✅ Git
- ✅ Extensiones Azure necesarias
- ✅ PowerShell (opcional, para scripts .ps1)

#### Setup Manual

```bash
# Activar entorno conda
conda activate avd-pix4d

# Instalar dependencias
conda install -c conda-forge azure-cli jq git
az bicep install
az extension add --name desktopvirtualization

# (Opcional) Instalar PowerShell si quieres usar scripts .ps1
conda install -c conda-forge powershell
```

#### Usando environment.yml

```bash
# Crear entorno desde archivo
conda env create -f environment.yml
conda activate avd-pix4d

# Completar instalación
az bicep install
az extension add --name desktopvirtualization
```

### Herramientas Locales (Alternativa sin Conda)

Si no usas Conda, puedes instalar manualmente:
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) >= 2.50.0
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install) >= 0.20.0
- [Bash](https://www.gnu.org/software/bash/) >= 4.0 (Linux/macOS) o [Git Bash](https://git-scm.com/) (Windows)
- [jq](https://stedolan.github.io/jq/download/) >= 1.6
- [PowerShell 7+](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) (opcional)
- [Git](https://git-scm.com/)

📖 **[Ver Guía Completa de Configuración del Entorno](../docs/ENVIRONMENT_SETUP.md)**

### Configuración GitHub
- Repositorio con **GitHub Actions** habilitado
- Secrets configurados:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`
  - `AVD_ADMIN_PASSWORD`

## 🚀 Inicio Rápido

### 1. Clonar el repositorio

```bash
git clone https://github.com/alejandrolmeida/azure-agent-pro.git
cd azure-agent-pro
git checkout feature/avd-pix4d-lab
```

### 2. Configurar parámetros

Edita `infra/bicep/parameters/lab.bicepparam`:

```bicep
param notificationEmail = 'tu-email@example.com'
param sessionHostCount = 5  // Número de alumnos
param vmSku = 'Standard_NV18ads_A10_v5'  // Ajusta según necesidad
```

### 3. Desplegar vía GitHub Actions

```bash
# Commit y push para desplegar automáticamente
git add .
git commit -m "feat: configure lab parameters"
git push origin feature/avd-pix4d-lab
```

O manualmente:

### 4. Desplegar manualmente

```bash
# Login a Azure
az login

# Desplegar infraestructura
az deployment sub create \
  --name avd-pix4d-lab \
  --location westeurope \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/lab.bicepparam \
  --parameters adminPassword='<TU_PASSWORD_SEGURO>'
```

### 5. Verificar despliegue

```bash
# Ejecutar smoke tests
pwsh tests/smoke/az-smoke.ps1 -Environment lab
```

## 💰 Costes

### Estimación de Costes por Hora (West Europe)

| SKU | vCPU | RAM (GB) | GPU VRAM | Coste/hora* | Uso 8h/día |
|-----|------|----------|----------|-------------|------------|
| NV12ads_A10_v5 | 12 | 110 | 8 GB | ~€0.91 | ~€218/mes |
| NV18ads_A10_v5 | 18 | 220 | 12 GB | ~€1.60 | ~€384/mes |
| NV36ads_A10_v5 | 36 | 440 | 24 GB | ~€3.20 | ~€768/mes |

_*Precios aproximados, consulta [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)_

### Otros Costes

- **Storage** (Azure Files Premium): ~€0.15/GB/mes
- **Networking**: Mínimo (<€10/mes)
- **Log Analytics**: Pay-per-GB (~€2-5/mes)

### 💡 Consejos para Reducir Costes

1. ✅ **Siempre usa deallocate**: 0€ de compute cuando está apagada
2. ✅ **Configura ventanas de clase**: Auto-apagado fuera de horario
3. ✅ **Usa NV12/NV18 para labs**: Reserva NV36 para proyectos grandes
4. ✅ **Monitoriza costes**: Configura alertas de presupuesto
5. ✅ **Revisa tags**: Todas las VMs deben tener `idleShutdownMinutes`

📖 **[Ver Guía Completa de Costes](docs/costs.md)**

## 📚 Documentación

### Guías de Usuario
- 📘 [**Guía de Operaciones**](docs/operations.md) - Tareas diarias del operador
- 🔧 [**Troubleshooting**](docs/troubleshooting.md) - Resolución de problemas comunes
- 💰 [**Gestión de Costes**](docs/costs.md) - Optimización y monitorización

### Guías Técnicas
- 🏗️ **Arquitectura Detallada** - Diseño y decisiones técnicas
- 🔐 **Seguridad y Compliance** - Políticas y RBAC
- 📊 **Monitorización** - Dashboards y alertas

### Tutoriales
- 🎓 **Asignar VMs a Alumnos** - Gestión de escritorios personales
- 📦 **Instalar PIX4Dmatic** - Deployment de aplicación
- 🖼️ **Crear Imagen Custom** - Azure Image Builder workflow

## 🧪 Tests

Los tests están disponibles en dos formatos para máxima compatibilidad:

### Smoke Tests

**Linux/macOS (Recomendado en Conda):**

```bash
# Validar que todos los recursos existen
cd tests/smoke
./az-smoke.sh -g "rg-avd-pix4d" -l "westeurope"
```

**Windows/PowerShell:**

```bash
cd tests/smoke
pwsh -File ./az-smoke.ps1 -ResourceGroupPrefix "rg-avd-pix4d" -Location "westeurope"
```

### E2E Tests

**Linux/macOS (Recomendado en Conda):**

```bash
# Test del ciclo start-stop-deallocate
cd tests/e2e
./check-start-stop.sh -g "rg-avd-pix4d-lab" -p "avd-sh"
```

**Windows/PowerShell:**

```bash
cd tests/e2e
pwsh -File ./check-start-stop.ps1 -ResourceGroupBase "rg-avd-pix4d-lab" -SessionHostPrefix "avd-sh"
```

### Linting

```bash
# Lint all Bicep files
az bicep lint --file bicep/main.bicep
```

## 🤝 Contribuir

Las contribuciones son bienvenidas! Por favor:

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/amazing-feature`)
3. Commit cambios (`git commit -m 'feat: add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para más detalles.

## 📝 Licencia

Este proyecto está bajo licencia MIT. Ver [LICENSE](LICENSE) para más información.

## 🙏 Agradecimientos

- **PIX4D** por su software de fotogrametría líder
- **Microsoft Azure** por la plataforma AVD y GPU compute
- **Comunidad** de Azure y GitHub Copilot

---

**Maintainer**: [@alejandrolmeida](https://github.com/alejandrolmeida)  
**Proyecto**: Azure Agent Pro - AVD PIX4D Lab  
**Status**: ✅ Production Ready
