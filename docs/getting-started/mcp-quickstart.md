# ⚡ Quick Start: Conectar GitHub Copilot con MCP Servers (v2)

## 🎯 Qué consigues con los MCP Servers

Los **MCP (Model Context Protocol) Servers** permiten a los agentes de Azure Agent Pro acceder a:

- ✅ **azure-mcp**: Tus recursos Azure en **tiempo real** — VMs, VNets, SQL, Storage, RBAC...
- ✅ **github-mcp**: Repos, Issues, PRs, workflows de GitHub Actions
- ✅ **filesystem-mcp**: Lectura de todos los Bicep, scripts y configs del workspace
- ✅ **memory-mcp**: **Contexto persistente** — el agente recuerda tus arquitecturas entre sesiones
- ✅ **brave-search-mcp**: Documentación oficial Azure, community patterns (opcional)

**Tiempo estimado de setup:** 5-10 minutos con el script automatizado

---

## 🚀 Setup Recomendado — Script Interactivo WSL

```bash
# Desde la raíz del proyecto en WSL/Linux
chmod +x scripts/setup/setup-wsl.sh
./scripts/setup/setup-wsl.sh
```

El script `setup-wsl.sh`:
1. Verifica prerrequisitos (Node.js, az CLI, git, jq)
2. **Autodetecta** subscription ID y tenant ID desde `az login`
3. **Autodetecta** GitHub token desde `gh auth token`
4. Configura el archivo `.env` de forma interactiva
5. Opcionalmente añade la carga automática a `~/.bashrc` o `~/.zshrc`
6. Verifica que azure-mcp esté disponible

---

## 📋 Setup Manual (alternativo)

### Paso 1: Variables de entorno

```bash
cp .env.example .env
nano .env
```

Variables mínimas:

```bash
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)
GITHUB_TOKEN=$(gh auth token)  # o crear en github.com/settings/tokens
MEMORY_FILE_PATH=$HOME/.config/mcp/azure-agent-pro-memory.json
```

### Paso 2: Cargar y abrir VS Code

```bash
source .env && az login && code .
```

### Paso 3: Verificar en Copilot Chat

```
@Azure_Architect_Pro ¿Qué MCP servers están activos?
```

---

## ✅ Tests de Verificación

### Test 1: filesystem-mcp (sin credenciales)

```
@Azure_Architect_Pro Lista todos los módulos Bicep disponibles en el proyecto
```
→ Debe listar archivos en `bicep/modules/`

### Test 2: memory-mcp (sin credenciales)

```
@Azure_Architect_Pro Guarda en memoria que usamos westeurope y prefijo "aap"
```
→ Guarda. En otra sesión:
```
@Azure_Architect_Pro ¿Qué convenciones de naming tenemos?
```
→ Recupera la información ✨

### Test 3: azure-mcp (requiere AZURE_SUBSCRIPTION_ID)

```
@Azure_Architect_Pro ¿Qué resource groups tengo en mi subscription?
```
→ Lista RGs reales de tu subscription

### Test 4: github-mcp (requiere GITHUB_TOKEN)

```
@Azure_Architect_Pro ¿Qué Issues abiertos hay en azure-agent-pro?
```
→ Lista Issues reales del repo

---

## 🔧 Troubleshooting WSL

### azure-mcp no responde

```bash
# 1. Verificar autenticación az CLI
az account show --output table

# 2. Verificar variables cargadas
echo "Sub: $AZURE_SUBSCRIPTION_ID"

# 3. Verificar npx funciona
npx --yes @azure/mcp@latest --version

# 4. Reload VS Code: Ctrl+Shift+P → "Reload Window"
```

### Variables no disponibles en VS Code

```bash
# VS Code hereda el entorno bash donde se lanzó
# Asegúrate de lanzar VS Code DESPUÉS de source .env:
source .env && code .

# O configurar carga automática en ~/.bashrc:
echo 'set -a; source ~/projects/azure-agent-pro/.env; set +a' >> ~/.bashrc
```

### github-mcp error de autenticación

```bash
echo $GITHUB_TOKEN | cut -c1-10   # No debe estar vacío
gh auth status                     # Verificar gh CLI
```

---

## 🤖 Uso avanzado con los 7 agentes

```
# Orquestador principal
@Azure_Architect_Pro Diseña una arquitectura hub-spoke para prod en West Europe

# Sub-agentes especializados
@Azure_Admin_Pro     Audita governance y compliance de mi subscription
@Azure_Data_Pro      Optimiza las queries lentas en mi Azure SQL
@Azure_AppServices_Pro Diagnostica cold starts en mi Function App
@Azure_Foundry_Pro   Crea un RAG sobre mis documentos PDF internos
@Azure_Networking_Pro Tengo un problema de conectividad en mi hub-spoke
@Azure_SQL_DBA       Analiza deadlocks en la base de datos de producción
```

> 📖 **Guía completa**: [../reference/agents-overview.md](../reference/agents-overview.md)
