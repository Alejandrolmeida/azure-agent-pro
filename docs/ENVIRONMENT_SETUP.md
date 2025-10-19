# Environment Setup for AVD PIX4D Project

Este documento explica cómo configurar el entorno de desarrollo para trabajar con el proyecto AVD PIX4D en diferentes sistemas operativos.

## 🐍 Entorno Miniconda/Conda (Linux/macOS)

### Prerequisitos

Este proyecto está diseñado para funcionar en entornos Conda/Miniconda y es completamente compatible con Linux, macOS y Windows.

### Instalación de Dependencias

#### 1. Azure CLI

```bash
# Instalar Azure CLI en conda
conda install -c conda-forge azure-cli

# Verificar instalación
az --version
```

#### 2. Bicep CLI

```bash
# Instalar Bicep CLI
az bicep install

# Verificar instalación
az bicep version
```

#### 3. PowerShell (Opcional - para scripts PowerShell originales)

Si prefieres usar los scripts PowerShell en lugar de los Bash equivalentes:

**Linux:**
```bash
# Instalar PowerShell en conda
conda install -c conda-forge powershell

# O instalar desde el repositorio oficial
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell-7.4.0-linux-x64.tar.gz
mkdir -p ~/powershell
tar -xvf powershell-7.4.0-linux-x64.tar.gz -C ~/powershell
ln -s ~/powershell/pwsh ~/.local/bin/pwsh

# Verificar instalación
pwsh --version
```

**macOS:**
```bash
# Instalar con Homebrew
brew install --cask powershell

# O con conda
conda install -c conda-forge powershell

# Verificar instalación
pwsh --version
```

**Windows:**
```powershell
# PowerShell ya está instalado en Windows
# Actualizar a la última versión
winget install --id Microsoft.Powershell --source winget
```

#### 4. Git

```bash
# Git suele estar preinstalado, si no:
conda install -c conda-forge git
```

#### 5. jq (para procesamiento JSON en scripts Bash)

```bash
# Instalar jq
conda install -c conda-forge jq

# Verificar instalación
jq --version
```

### Crear Entorno Conda Dedicado (Recomendado)

```bash
# Crear entorno para AVD PIX4D
conda create -n avd-pix4d python=3.11

# Activar entorno
conda activate avd-pix4d

# Instalar todas las dependencias
conda install -c conda-forge azure-cli jq git

# Instalar Bicep
az bicep install

# (Opcional) Instalar PowerShell si quieres usar scripts .ps1
conda install -c conda-forge powershell
```

### Guardar Configuración del Entorno

```bash
# Exportar entorno para reproducibilidad
conda env export > environment.yml

# Otros pueden recrear el entorno con:
# conda env create -f environment.yml
```

## 📝 Scripts Disponibles

Este proyecto incluye scripts en **dos formatos** para máxima compatibilidad:

### Scripts Bash (Recomendado para Linux/macOS)

```bash
# Smoke tests
./tests/smoke/az-smoke.sh lab westeurope

# E2E tests
./tests/e2e/check-start-stop.sh lab westeurope
```

### Scripts PowerShell (Cross-platform)

```bash
# Smoke tests (requiere PowerShell instalado)
pwsh tests/smoke/az-smoke.ps1 -Environment lab -Location westeurope

# E2E tests
pwsh tests/e2e/check-start-stop.ps1 -Environment lab -Location westeurope
```

## 🔧 Configuración del Proyecto

### 1. Login a Azure

```bash
# Login interactivo
az login

# Verificar suscripción activa
az account show

# Cambiar suscripción si es necesario
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```

### 2. Configurar Variables de Entorno (Opcional)

Crea un archivo `.env` en la raíz del proyecto:

```bash
# .env
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export AVD_ENVIRONMENT="lab"
export AVD_LOCATION="westeurope"
```

Luego carga las variables:

```bash
source .env
```

### 3. Validar Configuración

```bash
# Verificar todas las herramientas
echo "=== Tool Versions ==="
az --version | head -1
az bicep version
jq --version
git --version

# (Opcional) Si instalaste PowerShell
pwsh --version
```

## 🐳 Alternativa: Docker

Si prefieres un entorno completamente aislado:

```bash
# Crear Dockerfile
cat > Dockerfile <<EOF
FROM continuumio/miniconda3:latest

RUN conda install -c conda-forge azure-cli jq git && \
    az bicep install && \
    conda clean -afy

WORKDIR /workspace
EOF

# Construir imagen
docker build -t avd-pix4d-env .

# Ejecutar
docker run -it -v $(pwd):/workspace avd-pix4d-env bash
```

## 🔍 Troubleshooting

### Azure CLI no encuentra Bicep

```bash
# Reinstalar Bicep
az bicep install --force
```

### Scripts Bash no tienen permisos

```bash
# Dar permisos de ejecución
chmod +x tests/smoke/*.sh tests/e2e/*.sh
```

### PowerShell no ejecuta scripts

```bash
# En PowerShell, cambiar ExecutionPolicy
pwsh -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
```

### Comandos az desktopvirtualization no disponibles

```bash
# Instalar extensión de AVD
az extension add --name desktopvirtualization
```

## 📦 Dependencias del Proyecto

### Herramientas Requeridas

| Herramienta | Versión Mínima | Propósito |
|-------------|----------------|-----------|
| **Azure CLI** | >= 2.50.0 | Gestión de recursos Azure |
| **Bicep CLI** | >= 0.20.0 | Compilación de templates |
| **Bash** | >= 4.0 | Scripts de automatización |
| **jq** | >= 1.6 | Procesamiento JSON |
| **Git** | >= 2.30 | Control de versiones |

### Herramientas Opcionales

| Herramienta | Versión Mínima | Propósito |
|-------------|----------------|-----------|
| **PowerShell** | >= 7.0 | Scripts PowerShell alternativos |
| **Python** | >= 3.8 | Extensiones futuras |
| **Docker** | >= 20.10 | Entorno containerizado |

## 🚀 Quick Start

```bash
# 1. Clonar repositorio
git clone https://github.com/alejandrolmeida/azure-agent-pro.git
cd azure-agent-pro
git checkout feature/avd-pix4d

# 2. Crear y activar entorno conda
conda create -n avd-pix4d python=3.11
conda activate avd-pix4d

# 3. Instalar dependencias
conda install -c conda-forge azure-cli jq git
az bicep install
az extension add --name desktopvirtualization

# 4. Login a Azure
az login

# 5. Ejecutar tests de validación
./tests/smoke/az-smoke.sh lab westeurope

# 6. Desplegar infraestructura
az deployment sub create \
  --name avd-pix4d-lab \
  --location westeurope \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/parameters/lab.bicepparam
```

## 📚 Referencias

- [Azure CLI Installation](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Bicep CLI Installation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)
- [PowerShell Installation](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
- [Conda Documentation](https://docs.conda.io/)
- [jq Manual](https://stedolan.github.io/jq/manual/)

---

**Nota**: Los scripts Bash (`.sh`) son la opción recomendada para entornos Linux/macOS y no requieren PowerShell.
