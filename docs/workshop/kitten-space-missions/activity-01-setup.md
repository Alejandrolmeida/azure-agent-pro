# Actividad 1: Setup Inicial del Entorno

**⏱️ Duración estimada**: 30 minutos 
** Objetivo**: Preparar tu entorno local con el repositorio, herramientas necesarias y configuración del agente Azure_Architect_Pro

---

## Objetivos de aprendizaje

Al finalizar esta actividad serás capaz de:

1. Crear un fork del repositorio azure-agent-pro en tu cuenta de GitHub
2. Clonar y configurar el proyecto en tu entorno Linux/WSL
3. Instalar y verificar todas las herramientas necesarias
4. Configurar el agente personalizado Azure_Architect_Pro en VS Code
5. Verificar que todo funciona correctamente

---

## Paso 1: Fork del Repositorio

### 1.1 Crear tu propio fork

El primer paso es crear tu propia copia del repositorio para que puedas hacer cambios y subirlos a tu GitHub.

**Acciones**:

1. Ve al repositorio original: https://github.com/alejandrolmeida/azure-agent-pro
2. Haz click en el botón **"Fork"** (arriba a la derecha)
3. Selecciona tu cuenta personal de GitHub como destino
4. **Importante**: Deja marcada la opción "Copy the main branch only"
5. Click en **"Create fork"**

 ¡Ya tienes tu propia copia del repositorio!

### 1.2 Clonar tu fork

Ahora clona tu fork a tu máquina local:

```bash
# Reemplaza YOUR-USERNAME con tu usuario de GitHub
git clone https://github.com/YOUR-USERNAME/azure-agent-pro.git

# Entra al directorio
cd azure-agent-pro

# Verifica que estás en la rama main
git branch
```

### 1.3 Crear carpeta del workshop

Crea la estructura donde trabajarás durante el workshop:

```bash
# Desde la raíz del repositorio
mkdir -p docs/workshop/kitten-space-missions/solution
cd docs/workshop/kitten-space-missions/solution

# Crear subcarpetas para el proyecto
mkdir -p bicep/modules bicep/parameters .github/workflows scripts docs src

# Volver a la raíz
cd ~/azure-agent-pro # o la ruta donde clonaste
```

---

## Paso 2: Instalación de Herramientas

### 2.1 Verificar sistema operativo

Este workshop requiere **Linux o WSL2 en Windows**. Verifica tu entorno:

```bash
# Debe mostrar Linux
uname -s

# Debe mostrar bash
echo $SHELL
```

**Si estás en Windows**:
- Instala WSL2: https://learn.microsoft.com/windows/wsl/install
- Se recomienda Ubuntu 22.04 LTS
- Abre Windows Terminal con Ubuntu

### 2.2 Instalar/Verificar Azure CLI

```bash
# Verificar si ya está instalado
az --version

# Si no está instalado, instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar instalación
az --version

# Debe mostrar versión >= 2.50.0
```

### 2.3 Instalar/Verificar Git

```bash
# Verificar git
git --version

# Si no está instalado (Ubuntu/Debian)
sudo apt update
sudo apt install git -y

# Configurar git (reemplaza con tus datos)
git config --global user.name "Tu Nombre"
git config --global user.email "tu.email@example.com"
```

### 2.4 Instalar/Verificar jq (para parsing JSON)

```bash
# Verificar jq
jq --version

# Si no está instalado
sudo apt install jq -y
```

### 2.5 Verificar VS Code

Necesitas **Visual Studio Code** con estas extensiones:

**Extensiones obligatorias**:
- GitHub Copilot (`GitHub.copilot`)
- GitHub Copilot Chat (`GitHub.copilot-chat`)
- Azure Tools (`ms-vscode.vscode-node-azure-pack`)
- Bicep (`ms-azuretools.vscode-bicep`)

**Instalar desde VS Code**:
1. Abre VS Code
2. Ve a Extensions (Ctrl+Shift+X)
3. Busca e instala cada extensión de la lista

**O instalar desde terminal**:
```bash
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension ms-vscode.vscode-node-azure-pack
code --install-extension ms-azuretools.vscode-bicep
```

---

## 🎭 Paso 3: Configurar Azure Subscription

### 3.1 Login en Azure CLI

```bash
# Login interactivo (abrirá navegador)
az login

# Verificar subscriptions disponibles
az account list --output table

# Si tienes múltiples subscriptions, selecciona una
az account set --subscription "NOMBRE_O_ID_DE_TU_SUBSCRIPTION"

# Verificar cual está activa
az account show --output table
```

### 3.2 Crear Service Principal para GitHub Actions (opcional ahora)

**Nota**: Lo haremos más adelante en la Actividad 5, pero puedes adelantar:

```bash
# Crear Service Principal con permisos Contributor
az ad sp create-for-rbac \
 --name "kitten-space-missions-sp" \
 --role Contributor \
 --scopes /subscriptions/$(az account show --query id -o tsv) \
 --sdk-auth

# ⚠️ GUARDA EL OUTPUT JSON en un lugar seguro (lo necesitarás luego)
```

---

## Paso 4: Configurar el Agente Azure_Architect_Pro

Este es el paso más importante: configurar el agente personalizado en VS Code.

### 4.1 Abrir el workspace en VS Code

```bash
# Desde la raíz del repositorio
code .
```

### 4.2 Verificar configuración del agente

El agente ya está configurado en el repositorio. Verifica que existe el archivo:

```bash
ls -la .github/agents/azure-architect.agent.md
```

Este archivo contiene toda la configuración del agente **Azure_Architect_Pro**.

### 4.3 Verificar MCP Servers configurados

El agente usa MCP (Model Context Protocol) servers para acceder a herramientas avanzadas:

```bash
# Ver configuración de MCP servers
cat mcp.json
```

Deberías ver configurados estos servidores:
- `azure-mcp` - Para interactuar con Azure
- `bicep-mcp` - Para Bicep best practices
- `github-mcp` - Para GitHub operations
- `filesystem-mcp` - Para navegación del workspace
- `brave-search-mcp` - Para búsquedas web
- `memory-mcp` - Para contexto persistente

### 4.4 Activar el agente en Copilot Chat

1. Abre **GitHub Copilot Chat** en VS Code (Ctrl+Shift+I o icono de chat)
2. En el chat, escribe: `@workspace /help`
3. Deberías ver el agente disponible como `@azure-architect` o similar
4. Si no aparece, verifica que:
 - GitHub Copilot está activo (ícono en la barra de estado)
 - El archivo `.github/agents/azure-architect.agent.md` existe
 - Has recargado VS Code (Ctrl+Shift+P → "Reload Window")

### 4.5 Primera prueba del agente

Escribe en el Copilot Chat:

```
@workspace Hola Azure_Architect_Pro, ¿estás listo para ayudarme a desplegar la API de Kitten Space Missions?
```

Si todo está bien configurado, el agente responderá presentándose y confirmando que tiene acceso a:
- MCP servers
- Repositorio azure-agent-pro
- Tu workspace

---

## Paso 5: Verificación Final

### 5.1 Checklist de herramientas

Ejecuta este script de verificación:

```bash
#!/bin/bash
# verify-setup.sh

echo " Verificando setup del workshop..."
echo ""

# Azure CLI
if command -v az &> /dev/null; then
 echo " Azure CLI: $(az --version | head -n1)"
else
 echo " Azure CLI: NO INSTALADO"
fi

# Git
if command -v git &> /dev/null; then
 echo " Git: $(git --version)"
else
 echo " Git: NO INSTALADO"
fi

# jq
if command -v jq &> /dev/null; then
 echo " jq: $(jq --version)"
else
 echo " jq: NO INSTALADO"
fi

# VS Code
if command -v code &> /dev/null; then
 echo " VS Code: $(code --version | head -n1)"
else
 echo " VS Code: NO INSTALADO"
fi

# Azure subscription
echo ""
echo "🔐 Azure Subscription activa:"
az account show --query "{Name:name, ID:id, State:state}" -o table 2>/dev/null || echo " No logueado en Azure"

echo ""
echo " Estructura del workshop:"
if [ -d "docs/workshop/kitten-space-missions/solution" ]; then
 echo " Carpeta solution creada"
else
 echo " Carpeta solution NO creada"
fi

echo ""
echo " Configuración del agente:"
if [ -f ".github/agents/azure-architect.agent.md" ]; then
 echo " Agente Azure_Architect_Pro configurado"
else
 echo " Archivo del agente NO encontrado"
fi

if [ -f "mcp.json" ]; then
 echo " MCP servers configurados"
else
 echo " mcp.json NO encontrado"
fi

echo ""
echo " Verificación completada!"
```

Ejecuta el script:

```bash
# Guardar el script
cat > verify-setup.sh << 'EOF'
[... copiar contenido del script anterior ...]
EOF

# Dar permisos de ejecución
chmod +x verify-setup.sh

# Ejecutar
./verify-setup.sh
```

### 5.2 Crear commit inicial

Si todo está OK, crea tu primer commit:

```bash
git add .
git commit -m "chore: setup workshop kitten-space-missions"
git push origin main
```

---

## Entregables de esta actividad

Al finalizar deberías tener:

- Fork del repositorio azure-agent-pro en tu GitHub
- Repositorio clonado en tu entorno Linux/WSL
- Carpeta `docs/workshop/kitten-space-missions/solution/` creada
- Azure CLI instalado y logueado
- VS Code con extensiones necesarias
- Agente Azure_Architect_Pro configurado y respondiendo
- Primer commit pusheado a tu fork

---

## 🐛 Troubleshooting

### Problema: Azure CLI no se instala

```bash
# Método alternativo con snap
sudo snap install azure-cli --classic
```

### Problema: El agente no aparece en Copilot Chat

1. Verifica que GitHub Copilot está activo (ícono verde en barra de estado)
2. Recarga VS Code: `Ctrl+Shift+P` → "Developer: Reload Window"
3. Verifica que el archivo `.github/agents/azure-architect.agent.md` existe
4. Intenta cerrar y abrir VS Code

### Problema: WSL2 no encuentra VS Code command

```bash
# Instalar code en WSL
export PATH="$PATH:/mnt/c/Users/YOUR_WINDOWS_USER/AppData/Local/Programs/Microsoft VS Code/bin"

# Agregar a .bashrc para permanente
echo 'export PATH="$PATH:/mnt/c/Users/YOUR_WINDOWS_USER/AppData/Local/Programs/Microsoft VS Code/bin"' >> ~/.bashrc
```

### Problema: No tengo Azure Subscription

Crea una cuenta gratuita:
- https://azure.microsoft.com/free/
- Incluye $200 de crédito para 30 días
- Muchos servicios gratuitos por 12 meses

---

## Tips y Mejores Prácticas

### Organización del workspace

```
azure-agent-pro/
├── docs/workshop/kitten-space-missions/
│ ├── solution/ ← TU CÓDIGO AQUÍ
│ │ ├── bicep/
│ │ ├── .github/
│ │ ├── scripts/
│ │ └── docs/
│ └── activity-*.md ← Instrucciones
```

### Git workflow recomendado

```bash
# Crear rama por actividad
git checkout -b activity-2-architecture

# Hacer cambios, commits frecuentes
git add .
git commit -m "feat: add architecture design"

# Push a tu fork
git push origin activity-2-architecture

# Cuando completes la actividad, merge a main
git checkout main
git merge activity-2-architecture
git push origin main
```

### Alias útiles para bash

Agrega a tu `~/.bashrc`:

```bash
# Azure shortcuts
alias azlogin='az login'
alias azlist='az account list -o table'
alias azset='az account set --subscription'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'

# Workshop
alias workshop='cd ~/azure-agent-pro/docs/workshop/kitten-space-missions'
```

Recarga:
```bash
source ~/.bashrc
```

---

## Siguiente Paso

Una vez completada esta actividad y verificado que todo funciona, continúa con:

**➡️ [Actividad 2: Primera Conversación con el Agente](./activity-02-first-conversation.md)**

En la siguiente actividad aprenderás a comunicarte eficientemente con Azure_Architect_Pro para pedirle que diseñe la arquitectura de la API de Kitten Space Missions.

---

## Referencias útiles

- [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
- [VS Code Tips](https://code.visualstudio.com/docs/getstarted/tips-and-tricks)
- [WSL Installation Guide](https://learn.microsoft.com/windows/wsl/install)

---

** ¡Felicidades! Has completado el setup inicial. Ahora estás listo para empezar a hacer Vibe Coding con el agente.**

