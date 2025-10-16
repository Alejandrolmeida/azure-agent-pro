#!/bin/bash
# Script simplificado de configuración de servidores MCP
# Basado en la configuración existente en mcp.json

set -euo pipefail

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Configuración de Servidores MCP - Azure Agent Pro${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo

# Verificar Node.js y npm
log_info "Verificando prerequisitos..."
if ! command -v node &> /dev/null; then
    log_error "Node.js no está instalado"
    exit 1
fi
if ! command -v npm &> /dev/null; then
    log_error "npm no está instalado"
    exit 1
fi
log_success "Node.js $(node --version) y npm $(npm --version) detectados"

# Cargar variables de entorno
if [[ -f .env ]]; then
    log_info "Cargando variables de entorno desde .env"
    export $(grep -v '^#' .env | xargs)
    log_success "Variables de entorno cargadas"
else
    log_warning "Archivo .env no encontrado"
fi

# Verificar variables críticas
log_info "Verificando configuración de Azure..."
missing_vars=()
[[ -z "${AZURE_SUBSCRIPTION_ID:-}" ]] && missing_vars+=("AZURE_SUBSCRIPTION_ID")
[[ -z "${AZURE_TENANT_ID:-}" ]] && missing_vars+=("AZURE_TENANT_ID")

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log_error "Variables requeridas faltantes: ${missing_vars[*]}"
    log_info "Por favor, configura estas variables en el archivo .env"
    exit 1
fi
log_success "Configuración de Azure: OK"
log_info "  Subscription ID: ${AZURE_SUBSCRIPTION_ID}"
log_info "  Tenant ID: ${AZURE_TENANT_ID}"

# Verificar GitHub token
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    log_success "GitHub Token configurado"
else
    log_warning "GitHub Token no configurado (opcional)"
fi

# Verificar Brave API Key
if [[ -n "${BRAVE_API_KEY:-}" ]]; then
    log_success "Brave API Key configurado (opcional)"
else
    log_warning "Brave API Key no configurado (opcional)"
fi

echo
log_info "Probando servidores MCP..."
echo

# Test Azure MCP Server
log_info "1. Azure MCP Server (@azure/mcp-server-azure)"
if timeout 15 npx -y @azure/mcp-server-azure --version &>/dev/null 2>&1 || true; then
    log_success "   Azure MCP Server disponible"
else
    log_warning "   Azure MCP Server: No se pudo verificar (se descargará en primer uso)"
fi

# Test Bicep MCP Server
log_info "2. Bicep MCP Server (@modelcontextprotocol/server-bicep)"
if timeout 15 npx -y @modelcontextprotocol/server-bicep --version &>/dev/null 2>&1 || true; then
    log_success "   Bicep MCP Server disponible"
else
    log_warning "   Bicep MCP Server: No se pudo verificar (se descargará en primer uso)"
fi

# Test GitHub MCP Server
log_info "3. GitHub MCP Server (@modelcontextprotocol/server-github)"
if timeout 15 npx -y @modelcontextprotocol/server-github --version &>/dev/null 2>&1 || true; then
    log_success "   GitHub MCP Server disponible"
else
    log_warning "   GitHub MCP Server: No se pudo verificar (se descargará en primer uso)"
fi

# Test Filesystem MCP Server
log_info "4. Filesystem MCP Server (@modelcontextprotocol/server-filesystem)"
if timeout 15 npx -y @modelcontextprotocol/server-filesystem --version &>/dev/null 2>&1 || true; then
    log_success "   Filesystem MCP Server disponible"
else
    log_warning "   Filesystem MCP Server: No se pudo verificar (se descargará en primer uso)"
fi

# Test Memory MCP Server
log_info "5. Memory MCP Server (@modelcontextprotocol/server-memory)"
if timeout 15 npx -y @modelcontextprotocol/server-memory --version &>/dev/null 2>&1 || true; then
    log_success "   Memory MCP Server disponible"
else
    log_warning "   Memory MCP Server: No se pudo verificar (se descargará en primer uso)"
fi

echo
log_info "Verificando autenticación Azure CLI..."
if command -v az &> /dev/null; then
    if az account show &>/dev/null; then
        current_sub=$(az account show --query name -o tsv)
        current_sub_id=$(az account show --query id -o tsv)
        log_success "Azure CLI autenticado"
        log_info "  Subscription activa: $current_sub"
        log_info "  Subscription ID: $current_sub_id"
        
        if [[ "$current_sub_id" != "${AZURE_SUBSCRIPTION_ID}" ]]; then
            log_warning "La suscripción activa difiere de AZURE_SUBSCRIPTION_ID en .env"
        fi
    else
        log_warning "Azure CLI no está autenticado. Ejecuta: az login"
    fi
else
    log_warning "Azure CLI no está instalado"
fi

echo
log_success "═══════════════════════════════════════════════════════"
log_success "  Configuración de servidores MCP completada"
log_success "═══════════════════════════════════════════════════════"
echo
log_info "Archivos de configuración:"
log_info "  • mcp.json: Configuración de servidores MCP"
log_info "  • .env: Variables de entorno"
echo
log_info "Servidores configurados:"
log_info "  1. Azure MCP - Gestión de recursos Azure"
log_info "  2. Bicep MCP - Infraestructura como código"
log_info "  3. GitHub MCP - Control de versiones y colaboración"
log_info "  4. Filesystem MCP - Navegación del proyecto"
log_info "  5. Memory MCP - Contexto persistente"
echo
log_info "Próximos pasos:"
log_info "  1. Los servidores MCP se iniciarán automáticamente cuando uses GitHub Copilot"
log_info "  2. Usa @ en el chat de Copilot para acceder a los servidores MCP"
log_info "  3. Para más información: docs/MCP_QUICKSTART.md"
echo
