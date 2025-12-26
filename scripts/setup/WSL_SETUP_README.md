# WSL Quick Setup Script

Script automatizado para configurar WSL con todas las herramientas necesarias para desarrollo Azure.

## 🚀 Características

Este script configura automáticamente:

- **Miniconda3**: Gestor de entornos Python
- **Entorno `azurecli`**: Entorno conda dedicado con Python 3.11
- **Azure CLI**: Herramienta de línea de comandos de Azure
- **Librerías Azure**: SDK de Python para Azure (storage, compute, network, etc.)
- **AZQR**: Azure Quick Review para análisis de recursos
- **CaskaydiaCove Nerd Font**: Fuente con iconos para terminal
- **Oh-my-posh**: Prompt personalizado con tema custom
- **Aliases útiles**: Atajos para comandos comunes

## 📋 Requisitos Previos

- WSL2 instalado en Windows
- Distribución Ubuntu/Debian en WSL
- Conexión a Internet

## 🎯 Instalación

### Método 1: Ejecutar directamente

```bash
# Descargar y ejecutar
curl -fsSL https://raw.githubusercontent.com/alejandrolmeida/azure-agent-pro/main/scripts/setup/wsl-quick-setup.sh | bash
```

### Método 2: Clonar repositorio

```bash
# Clonar el repositorio
git clone https://github.com/alejandrolmeida/azure-agent-pro.git
cd azure-agent-pro/scripts/setup

# Ejecutar el script
./wsl-quick-setup.sh
```

### Método 3: Descargar script

```bash
# Descargar
wget https://raw.githubusercontent.com/alejandrolmeida/azure-agent-pro/main/scripts/setup/wsl-quick-setup.sh

# Dar permisos de ejecución
chmod +x wsl-quick-setup.sh

# Ejecutar
./wsl-quick-setup.sh
```

## ⚙️ Qué hace el script

1. **Actualiza el sistema**: `apt-get update && upgrade`
2. **Instala dependencias**: build tools, curl, wget, git, etc.
3. **Instala Miniconda**: Si no está ya instalado
4. **Crea entorno azurecli**: Con Python 3.11
5. **Instala Azure CLI**: Vía pip en el entorno
6. **Instala herramientas Azure**: SDKs y librerías
7. **Descarga Nerd Font**: CaskaydiaCove para terminal
8. **Instala Oh-my-posh**: Prompt personalizado
9. **Configura .bashrc**: Aliases y auto-activación
10. **Añade extensiones Azure CLI**: DevOps, Container Apps, AKS

## 🎨 Configuración Post-Instalación

### 1. Reiniciar terminal

```bash
# Cerrar y abrir nueva terminal, o:
source ~/.bashrc
```

### 2. Configurar fuente en Windows Terminal

1. Abrir Windows Terminal
2. Settings (Ctrl+,)
3. Perfil de Ubuntu/WSL
4. Appearance
5. Font face: **CaskaydiaCove Nerd Font** o **CaskaydiaCove NF**

### 3. Login Azure

```bash
az login
# o con device code:
azlogin
```

## 📦 Herramientas Instaladas

### Azure CLI y Extensiones

- `azure-cli`: CLI principal de Azure
- `azure-devops`: Gestión de Azure DevOps
- `containerapp`: Azure Container Apps
- `aks-preview`: Azure Kubernetes Service

### Python Packages

- `azure-identity`: Autenticación Azure
- `azure-mgmt-resource`: Gestión de recursos
- `azure-mgmt-compute`: VMs y compute
- `azure-mgmt-network`: Redes y VNETs
- `azure-mgmt-storage`: Storage accounts
- `azure-storage-blob`: Blob storage
- `azure-keyvault-secrets`: Key Vault
- `azqr`: Azure Quick Review

## 🔧 Aliases Disponibles

### Generales
```bash
ll      # ls -alF (lista detallada)
la      # ls -A (mostrar ocultos)
cls     # clear (limpiar pantalla)
..      # cd .. (subir directorio)
...     # cd ../..
....    # cd ../../..
```

### Azure
```bash
azlogin   # az login --use-device-code
azaccount # az account show
azlist    # az account list --output table
```

### Git
```bash
gs  # git status
ga  # git add
gc  # git commit
gp  # git push
gl  # git log --oneline --graph --decorate
```

## 🎭 Tema Oh-my-posh

El script instala un tema personalizado (`almeida.omp.json`) que muestra:

- 👤 Usuario actual
- 📂 Ruta actual
- 🌿 Estado de Git (branch, cambios)
- 🐍 Entorno Python/Conda activo
- ☁️ Azure subscription activa
- ⚡ Indicadores de Node, Go, Rust (si están presentes)

## 🔄 Actualizar Configuración

Si necesitas actualizar la configuración:

```bash
# Restaurar backup de .bashrc
cp ~/.bashrc.backup.YYYYMMDD_HHMMSS ~/.bashrc

# Re-ejecutar script
./wsl-quick-setup.sh
```

## 🐛 Troubleshooting

### El prompt no se ve bien

- Verifica que la fuente esté configurada correctamente en Windows Terminal
- Usa **CaskaydiaCove NF** o **CaskaydiaCove Nerd Font**

### Conda no se encuentra

```bash
# Re-inicializar conda
source ~/miniconda3/etc/profile.d/conda.sh
conda init bash
source ~/.bashrc
```

### Azure CLI no funciona

```bash
# Activar entorno
conda activate azurecli

# Verificar instalación
az --version

# Reinstalar si necesario
pip install --upgrade azure-cli
```

### Oh-my-posh no se muestra

```bash
# Verificar instalación
which oh-my-posh

# Reinstalar
curl -s https://ohmyposh.dev/install.sh | bash -s
```

## 📝 Archivos Modificados

El script modifica/crea:

- `~/.bashrc`: Añade aliases y configuración de oh-my-posh
- `~/.bash_profile`: Auto-activación del entorno azurecli
- `~/.local/share/fonts/`: Instala Nerd Font
- `/usr/local/share/omp-templates/`: Tema oh-my-posh
- `~/miniconda3/`: Instalación de Miniconda

**Nota**: Se crea un backup de `.bashrc` automáticamente.

## 🔐 Seguridad

El script:
- ✅ Usa fuentes oficiales (GitHub releases, sitios oficiales)
- ✅ Verifica existencia antes de instalar
- ✅ No requiere credenciales
- ✅ Crea backups automáticos
- ✅ Puede ejecutarse múltiples veces sin problemas

## 🤝 Contribuir

Si encuentras problemas o tienes mejoras:

1. Fork el repositorio
2. Crea un branch: `git checkout -b feature/mejora`
3. Commit cambios: `git commit -am 'Add mejora'`
4. Push: `git push origin feature/mejora`
5. Crea Pull Request

## 📄 Licencia

MIT License - Ver [LICENSE](../../LICENSE)

## 👤 Autor

**Alejandro Almeida**
- GitHub: [@alejandrolmeida](https://github.com/alejandrolmeida)

## 🙏 Agradecimientos

- [Oh-my-posh](https://ohmyposh.dev/) por el framework de prompt
- [Nerd Fonts](https://www.nerdfonts.com/) por las fuentes con iconos
- [Miniconda](https://docs.conda.io/en/latest/miniconda.html) por el gestor de entornos
- [Azure CLI](https://docs.microsoft.com/cli/azure/) por las herramientas

---

**¿Preguntas o problemas?** Abre un [issue](https://github.com/alejandrolmeida/azure-agent-pro/issues)
