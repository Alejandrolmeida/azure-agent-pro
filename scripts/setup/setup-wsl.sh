#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#   Azure Agent Pro v2 — WSL Setup Script
#   Configura todas las variables de entorno necesarias para el proyecto
#   en WSL (Ubuntu/Debian) de forma interactiva y persistente
#
#   Uso: chmod +x scripts/setup/setup-wsl.sh && ./scripts/setup/setup-wsl.sh
# ═══════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colores ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ ${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠️ ${NC} $*"; }
log_error()   { echo -e "${RED}❌${NC} $*"; }
log_section() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# ── Banner ─────────────────────────────────────────────────────────────────
echo -e "${CYAN}"
echo '  ╔═══════════════════════════════════════════╗'
echo '  ║   Azure Agent Pro v2 — WSL Setup          ║'
echo '  ║   Configuración interactiva de entorno     ║'
echo '  ╚═══════════════════════════════════════════╝'
echo -e "${NC}"

# ── Verificar prerrequisitos ───────────────────────────────────────────────
log_section "Verificando prerrequisitos"

check_tool() {
    if command -v "$1" &>/dev/null; then
        log_success "$1 $(${2:-$1 --version 2>&1 | head -1})"
    else
        log_warn "$1 no encontrado — instalar con: ${3:-apt-get install $1}"
        return 1
    fi
}

MISSING=0
check_tool "node" "node --version" "nvm install --lts" || MISSING=1
check_tool "npx"  "npx --version"  "npm install -g npx" || MISSING=1
check_tool "az"   "az version --query '\"azure-cli\"' -o tsv 2>/dev/null || echo 'instalado'" \
    "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash" || MISSING=1
check_tool "git"  "git --version" || MISSING=1
check_tool "jq"   "jq --version" "sudo apt-get install -y jq" || MISSING=1

if [[ $MISSING -eq 1 ]]; then
    log_warn "Algunos prerrequisitos faltan. El setup continuará pero algunas funciones pueden no estar disponibles."
    read -r -p "¿Continuar de todas formas? [s/N] " CONTINUE
    [[ "${CONTINUE,,}" == "s" ]] || { log_error "Abortando."; exit 1; }
fi

# ── Comprobar versión de Node.js ───────────────────────────────────────────
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | cut -dv -f2 | cut -d. -f1)
    if [[ $NODE_VER -lt 18 ]]; then
        log_warn "Node.js v${NODE_VER} detectado. Se recomienda v20+ para mejor compatibilidad con MCP servers."
    fi
fi

# ── Inicializar .env ───────────────────────────────────────────────────────
log_section "Configuración del archivo .env"

if [[ -f "$ENV_FILE" ]]; then
    log_warn ".env ya existe en: $ENV_FILE"
    read -r -p "¿Sobrescribir? Los valores actuales se perderán [s/N] " OVERWRITE
    if [[ "${OVERWRITE,,}" != "s" ]]; then
        log_info "Usando .env existente. Solo se actualizarán las variables que falten."
    else
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        log_success ".env creado desde template"
    fi
else
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    log_success ".env creado desde template"
fi

# Función helper para leer input con valor por defecto
prompt_value() {
    local key="$1" description="$2" default="${3:-}" secret="${4:-false}"
    local current
    current=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d= -f2- | sed "s/your-.*-here//" || echo "")

    if [[ -n "$current" && "$current" != "ghp_your_token_here" ]]; then
        if [[ "$secret" == "true" ]]; then
            log_info "$description ya configurado [***redacted***]"
        else
            log_info "$description ya configurado: $current"
        fi
        return
    fi

    echo -e "\n${BOLD}${description}${NC}"
    [[ -n "$default" ]] && echo -e "  Default: ${CYAN}${default}${NC}"

    if [[ "$secret" == "true" ]]; then
        read -rs -p "  Valor (oculto): " VALUE; echo ""
    else
        read -r -p "  Valor${default:+ [$default]}: " VALUE
    fi

    VALUE="${VALUE:-$default}"
    if [[ -n "$VALUE" ]]; then
        # Reemplazar o añadir la línea en .env
        if grep -q "^${key}=" "$ENV_FILE"; then
            sed -i "s|^${key}=.*|${key}=${VALUE}|" "$ENV_FILE"
        else
            echo "${key}=${VALUE}" >> "$ENV_FILE"
        fi
        log_success "${key} configurado"
    else
        log_warn "${key} omitido (puede configurarse luego en .env)"
    fi
}

# ── Obtener valores de az CLI si está autenticado ─────────────────────────
log_section "Azure CLI — Autodetección"

AZ_SUB="" AZ_TENANT=""
if command -v az &>/dev/null && az account show &>/dev/null 2>&1; then
    AZ_SUB=$(az account show --query id -o tsv 2>/dev/null || echo "")
    AZ_TENANT=$(az account show --query tenantId -o tsv 2>/dev/null || echo "")
    AZ_NAME=$(az account show --query name -o tsv 2>/dev/null || echo "")
    if [[ -n "$AZ_SUB" ]]; then
        log_success "az CLI autenticado: $AZ_NAME ($AZ_SUB)"
    fi
else
    log_warn "az CLI no autenticado. Ejecuta 'az login' para autenticar."
    log_info "Puedes configurar los valores manualmente."
fi

# ── Configuración interactiva ─────────────────────────────────────────────
log_section "Configuración de Azure"
prompt_value "AZURE_SUBSCRIPTION_ID" "Azure Subscription ID" "${AZ_SUB}"
prompt_value "AZURE_TENANT_ID"       "Azure Tenant ID"        "${AZ_TENANT}"

log_section "Configuración de GitHub"
GH_TOKEN_DEFAULT=""
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    GH_TOKEN_DEFAULT=$(gh auth token 2>/dev/null || echo "")
    [[ -n "$GH_TOKEN_DEFAULT" ]] && log_success "gh CLI autenticado — token autodetectado"
fi
prompt_value "GITHUB_TOKEN" "GitHub Personal Access Token (scopes: repo, read:user, workflow)" \
    "${GH_TOKEN_DEFAULT}" "true"

log_section "Configuración de MCP Memory (opcional)"
MEMORY_DEFAULT="$HOME/.config/mcp/azure-agent-pro-memory.json"
mkdir -p "$HOME/.config/mcp"
prompt_value "MEMORY_FILE_PATH" "Ruta para el archivo de memoria persistente del agente" "$MEMORY_DEFAULT"

log_section "Brave Search (opcional — 2000 queries/mes gratis)"
echo "  Obtener API key gratuita en: https://brave.com/search/api/"
prompt_value "BRAVE_API_KEY" "Brave Search API Key" "" "true"

log_section "Configuración de recursos Azure"
prompt_value "RESOURCE_GROUP" "Resource Group por defecto"  "rg-azure-agent-pro-dev"
prompt_value "AZURE_LOCATION"  "Región Azure"                "westeurope"
prompt_value "ENVIRONMENT"     "Entorno (dev/test/stage/prod)" "dev"
prompt_value "RESOURCE_PREFIX" "Prefijo para naming convention" "aap"

# ── Cargar en shell profile ───────────────────────────────────────────────
log_section "Configuración de shell profile"

SHELL_PROFILE=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
fi

if [[ -n "$SHELL_PROFILE" ]]; then
    MARKER="# azure-agent-pro env"
    if grep -q "$MARKER" "$SHELL_PROFILE" 2>/dev/null; then
        log_info "Carga automática ya configurada en $SHELL_PROFILE"
    else
        read -r -p "¿Cargar .env automáticamente en nuevas sesiones de terminal? [$SHELL_PROFILE] [s/N] " AUTO_LOAD
        if [[ "${AUTO_LOAD,,}" == "s" ]]; then
            cat >> "$SHELL_PROFILE" << EOF

$MARKER — cargado por setup-wsl.sh
if [[ -f "${ENV_FILE}" ]]; then
    set -a; source "${ENV_FILE}"; set +a
fi
EOF
            log_success "Carga automática configurada en $SHELL_PROFILE"
            log_info "Reinicia el terminal o ejecuta: source $SHELL_PROFILE"
        fi
    fi
fi

# ── Verificación de MCP servers ───────────────────────────────────────────
log_section "Verificando MCP servers (descarga bajo demanda via npx)"

verify_mcp() {
    local pkg="$1" name="$2"
    log_info "Verificando $name ($pkg)..."
    if npx --yes "$pkg" --version &>/dev/null 2>&1; then
        log_success "$name disponible"
    else
        log_warn "$name: verificación falló (se descargará la primera vez que se use)"
    fi
}

# Solo verificar azure-mcp (el más crítico)
if command -v npx &>/dev/null; then
    npx --yes @azure/mcp@latest --version &>/dev/null 2>&1 \
        && log_success "azure-mcp (@azure/mcp) disponible" \
        || log_warn "azure-mcp: se descargará la primera vez que Copilot lo use"
fi

# ── Resumen final ─────────────────────────────────────────────────────────
log_section "✅ Setup completado"

# Cargar .env para mostrar resumen (enmascarar secrets)
set -a; source "$ENV_FILE" 2>/dev/null; set +a

echo ""
echo -e "  ${BOLD}Configuración activa:${NC}"
echo -e "  ├── Azure Subscription : ${CYAN}${AZURE_SUBSCRIPTION_ID:-❌ no configurado}${NC}"
echo -e "  ├── Azure Tenant       : ${CYAN}${AZURE_TENANT_ID:-❌ no configurado}${NC}"
echo -e "  ├── GitHub Token       : ${CYAN}${GITHUB_TOKEN:+✅ configurado}${GITHUB_TOKEN:-❌ no configurado}${NC}"
echo -e "  ├── Memory MCP         : ${CYAN}${MEMORY_FILE_PATH:-~/.config/mcp/memory.json}${NC}"
echo -e "  ├── Brave Search       : ${CYAN}${BRAVE_API_KEY:+✅ configurado}${BRAVE_API_KEY:-⚠️  no configurado (opcional)}${NC}"
echo -e "  ├── Resource Group     : ${CYAN}${RESOURCE_GROUP:-rg-azure-agent-pro-dev}${NC}"
echo -e "  ├── Location           : ${CYAN}${AZURE_LOCATION:-westeurope}${NC}"
echo -e "  └── Entorno            : ${CYAN}${ENVIRONMENT:-dev}${NC}"

echo ""
echo -e "  ${BOLD}Próximos pasos:${NC}"
echo -e "  1. ${GREEN}source ${ENV_FILE}${NC}  — cargar variables en sesión actual"
echo -e "  2. ${GREEN}az login${NC}  — autenticar az CLI (si no está autenticado)"
echo -e "  3. ${GREEN}code .${NC}  — abrir VS Code en el proyecto"
echo -e "  4. En Copilot Chat: ${CYAN}@Azure_Architect_Pro Hola, analiza mi subscription Azure${NC}"
echo ""
echo -e "  ${BOLD}Documentación:${NC} docs/getting-started/mcp-quickstart.md"
echo -e "  ${BOLD}Agentes disponibles:${NC} .github/agents/"
echo ""
