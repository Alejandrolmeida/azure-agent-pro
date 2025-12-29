#!/bin/bash

# Azure CLI Login Script with MCP Integration
# Este script maneja la autenticación con Azure CLI, gestión de suscripciones y integración MCP
# Integra con MCP servers para sincronización automática de contexto

set -euo pipefail  # Salir en caso de error, variables undefined, y pipe failures

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con colores
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuración y constantes
MCP_CONFIG_DIR="$HOME/.config/mcp"
PROJECT_CONFIG_FILE="$(dirname "$0")/../../config/config.json"
AZURE_MCP_CONFIG="$MCP_CONFIG_DIR/azure/config.json"

# Función para verificar si Azure CLI está instalado
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI no está instalado. Por favor, instálalo primero."
        log_info "Instrucciones de instalación: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    local version=$(az version --query '."azure-cli"' -o tsv 2>/dev/null)
    log_info "Azure CLI versión: $version"
    
    # Verificar versión mínima recomendada
    local major_version=$(echo "$version" | cut -d'.' -f1)
    local minor_version=$(echo "$version" | cut -d'.' -f2)
    
    if [[ $major_version -lt 2 || ($major_version -eq 2 && $minor_version -lt 50) ]]; then
        log_warning "Versión de Azure CLI $version detectada. Recomendada: 2.50+"
        log_info "Considera actualizar: az upgrade"
    fi
}

# Función para realizar login
azure_login() {
    log_info "Iniciando proceso de autenticación con Azure..."
    
    # Verificar si ya hay una sesión activa
    if az account show &> /dev/null; then
        local current_user=$(az account show --query user.name -o tsv)
        log_warning "Ya existe una sesión activa para: $current_user"
        
        read -p "¿Deseas continuar con esta sesión? (y/n): " continue_session
        if [[ $continue_session == "y" || $continue_session == "Y" ]]; then
            return 0
        else
            log_info "Cerrando sesión actual..."
            az logout
        fi
    fi
    
    # Realizar login
    log_info "Abriendo navegador para autenticación..."
    if az login; then
        local logged_user=$(az account show --query user.name -o tsv)
        log_success "Login exitoso para: $logged_user"
    else
        log_error "Error durante el proceso de login"
        exit 1
    fi
}

# Función para listar y seleccionar suscripción
select_subscription() {
    log_info "Obteniendo lista de suscripciones disponibles..."
    
    # Obtener suscripciones
    local subscriptions=$(az account list --query '[].{Name:name, Id:id, State:state}' -o table)
    
    if [[ -z "$subscriptions" ]]; then
        log_error "No se encontraron suscripciones disponibles"
        exit 1
    fi
    
    echo ""
    log_info "Suscripciones disponibles:"
    echo "$subscriptions"
    echo ""
    
    # Mostrar suscripción actual
    local current_subscription=$(az account show --query name -o tsv 2>/dev/null || echo "Ninguna")
    log_info "Suscripción actual: $current_subscription"
    
    # Preguntar si desea cambiar
    read -p "¿Deseas cambiar de suscripción? (y/n): " change_subscription
    
    if [[ $change_subscription == "y" || $change_subscription == "Y" ]]; then
        echo ""
        read -p "Ingresa el ID o nombre de la suscripción: " subscription_input
        
        if [[ -n "$subscription_input" ]]; then
            log_info "Cambiando a suscripción: $subscription_input"
            if az account set --subscription "$subscription_input"; then
                local new_subscription=$(az account show --query name -o tsv)
                log_success "Suscripción cambiada exitosamente a: $new_subscription"
            else
                log_error "Error al cambiar la suscripción"
                exit 1
            fi
        fi
    fi
}

# Función para mostrar información de la cuenta
show_account_info() {
    log_info "Información de la cuenta actual:"
    echo ""
    
    local account_info=$(az account show --query '{
        Subscription: name,
        SubscriptionId: id,
        User: user.name,
        UserType: user.type,
        TenantId: tenantId,
        State: state
    }' -o table)
    
    echo "$account_info"
    echo ""
    
    # Verificar permisos básicos
    log_info "Verificando permisos básicos..."
    if az group list --query '[0].name' -o tsv &> /dev/null; then
        log_success "Permisos de lectura verificados"
    else
        log_warning "Posibles problemas con permisos de lectura"
    fi
}

# Función para guardar configuración
save_config() {
    local config_dir="../config"
    local config_file="$config_dir/azure-config.env"
    
    # Crear directorio si no existe
    mkdir -p "$config_dir"
    
    # Obtener información actual
    local subscription_id=$(az account show --query id -o tsv)
    local subscription_name=$(az account show --query name -o tsv)
    local tenant_id=$(az account show --query tenantId -o tsv)
    local user_name=$(az account show --query user.name -o tsv)
    
    # Guardar en archivo de configuración
    cat > "$config_file" << EOF
# Azure Configuration
# Generado automáticamente por azure-login.sh el $(date)

export AZURE_SUBSCRIPTION_ID="$subscription_id"
export AZURE_SUBSCRIPTION_NAME="$subscription_name"
export AZURE_TENANT_ID="$tenant_id"
export AZURE_USER="$user_name"

# Variables adicionales
export AZURE_LOCATION="eastus"  # Cambia según tu región preferida
export AZURE_RESOURCE_GROUP_PREFIX="rg"
export AZURE_TAG_ENVIRONMENT="dev"
export AZURE_TAG_PROJECT="azure-agent"
EOF

    log_success "Configuración guardada en: $config_file"
    log_info "Puedes cargar esta configuración con: source $config_file"
}

# Función para mostrar ayuda
show_help() {
    echo ""
    echo "Azure Login Script - Uso:"
    echo ""
    echo "  $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help           Mostrar esta ayuda"
    echo "  -s, --subscription   Solo seleccionar suscripción (sin login)"
# Función para sincronizar con MCP Azure Server
sync_with_mcp() {
    log_info "Sincronizando contexto con MCP Azure Server..."
    
    if [[ ! -f "$AZURE_MCP_CONFIG" ]]; then
        log_warning "Configuración MCP no encontrada. Ejecuta: scripts/setup/mcp-setup.sh"
        return 0
    fi
    
    # Obtener información actual de Azure
    local current_subscription=$(az account show --query '{id:id, name:name, tenantId:tenantId}' -o json 2>/dev/null || echo "{}")
    local current_user=$(az account show --query user.name -o tsv 2>/dev/null || echo "unknown")
    
    # Actualizar configuración MCP con contexto actual
    if command -v jq &> /dev/null && [[ -n "$current_subscription" ]]; then
        local updated_config=$(jq --argjson subscription "$current_subscription" --arg user "$current_user" '. + {
            "currentSubscription": $subscription,
            "currentUser": $user,
            "lastSync": (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
        }' "$AZURE_MCP_CONFIG")
        
        echo "$updated_config" > "$AZURE_MCP_CONFIG"
        log_success "Contexto sincronizado con MCP Azure Server"
    else
        log_warning "jq no disponible o contexto Azure inválido. Saltando sincronización MCP"
    fi
}

# Función para verificar límites y cuotas
check_azure_limits() {
    log_info "Verificando límites y cuotas de Azure..."
    
    local subscription_id=$(az account show --query id -o tsv 2>/dev/null)
    if [[ -z "$subscription_id" ]]; then
        log_warning "No se pudo obtener ID de suscripción"
        return 0
    fi
    
    # Verificar límites de VM en región principal
    local primary_location="eastus"
    local vm_usage=$(az vm list-usage --location "$primary_location" --query '[?name.value==`cores`]' -o json 2>/dev/null)
    
    if [[ -n "$vm_usage" ]] && command -v jq &> /dev/null; then
        local current_usage=$(echo "$vm_usage" | jq -r '.[0].currentValue // 0')
        local limit=$(echo "$vm_usage" | jq -r '.[0].limit // 0')
        local usage_percent=$((current_usage * 100 / limit))
        
        if [[ $usage_percent -gt 80 ]]; then
            log_warning "Uso de CPU cores en $primary_location: ${usage_percent}% (${current_usage}/${limit})"
        else
            log_info "Uso de CPU cores en $primary_location: ${usage_percent}% (${current_usage}/${limit})"
        fi
    fi
}

# Función para verificar políticas de Azure
check_azure_policies() {
    log_info "Verificando políticas de Azure aplicables..."
    
    # Verificar asignaciones de políticas
    local policy_assignments=$(az policy assignment list --disable-scope-strict-match --query 'length(@)' -o tsv 2>/dev/null || echo "0")
    
    if [[ "$policy_assignments" -gt 0 ]]; then
        log_info "Políticas de Azure detectadas: $policy_assignments asignaciones activas"
        
        # Verificar estado de compliance
        local non_compliant=$(az policy state list --query '[?complianceState==`NonCompliant`] | length(@)' -o tsv 2>/dev/null || echo "0")
        
        if [[ "$non_compliant" -gt 0 ]]; then
            log_warning "Recursos no conformes detectados: $non_compliant"
            log_info "Ejecuta 'az policy state list --filter \"complianceState eq 'NonCompliant'\"' para detalles"
        else
            log_success "Todos los recursos están en conformidad con las políticas"
        fi
    else
        log_info "No se detectaron políticas de Azure en el contexto actual"
    fi
}

# Función para verificar conexión MCP
test_mcp_connection() {
    log_info "Verificando conexión con servidores MCP..."
    
    local mcp_servers_config="$MCP_CONFIG_DIR/servers.json"
    
    if [[ ! -f "$mcp_servers_config" ]]; then
        log_warning "Configuración de servidores MCP no encontrada"
        log_info "Ejecuta 'scripts/setup/mcp-setup.sh' para configurar servidores MCP"
        return 0
    fi
    
    # Verificar si los servidores MCP están ejecutándose
    if command -v pgrep &> /dev/null; then
        local mcp_processes=$(pgrep -f "mcp-server" | wc -l)
        if [[ $mcp_processes -gt 0 ]]; then
            log_success "Servidores MCP activos: $mcp_processes procesos"
        else
            log_info "No se detectaron servidores MCP ejecutándose"
        fi
    fi
}

# Función para setup de environment variables
setup_environment() {
    log_info "Configurando variables de entorno..."
    
    local subscription_id=$(az account show --query id -o tsv 2>/dev/null)
    local tenant_id=$(az account show --query tenantId -o tsv 2>/dev/null)
    local subscription_name=$(az account show --query name -o tsv 2>/dev/null)
    
    if [[ -n "$subscription_id" ]]; then
        export AZURE_SUBSCRIPTION_ID="$subscription_id"
        export AZURE_TENANT_ID="$tenant_id"
        export AZURE_SUBSCRIPTION_NAME="$subscription_name"
        
        log_success "Variables de entorno configuradas:"
        log_info "  AZURE_SUBSCRIPTION_ID=$subscription_id"
        log_info "  AZURE_TENANT_ID=$tenant_id"
        log_info "  AZURE_SUBSCRIPTION_NAME=$subscription_name"
    else
        log_warning "No se pudieron configurar variables de entorno Azure"
    fi
}

    echo "  -i, --info           Solo mostrar información de la cuenta"
    echo "  -c, --config         Solo guardar configuración"
    echo "  --mcp-sync           Solo sincronizar con MCP servers"
    echo "  --check-limits       Solo verificar límites y cuotas"
    echo ""
    echo "Ejemplos:"
    echo "  $0                   Login completo y configuración"
    echo "  $0 -s               Solo cambiar suscripción"
    echo "  $0 -i               Mostrar información actual"
    echo "  $0 --mcp-sync       Sincronizar con servidores MCP"
    echo ""
}

# Función principal
main() {
    echo ""
    log_info "=== Azure CLI Login y Configuración con MCP Integration ==="
    echo ""
    
    # Verificar Azure CLI
    check_azure_cli
    
    # Procesar argumentos
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--subscription)
            select_subscription
            show_account_info
            save_config
            sync_with_mcp
            setup_environment
            ;;
        -i|--info)
            show_account_info
            check_azure_limits
            check_azure_policies
            ;;
        -c|--config)
            save_config
            sync_with_mcp
            setup_environment
            ;;
        --mcp-sync)
            sync_with_mcp
            test_mcp_connection
            ;;
        --check-limits)
            check_azure_limits
            check_azure_policies
            ;;
        *)
            # Proceso completo
            azure_login
            select_subscription
            show_account_info
            save_config
            sync_with_mcp
            setup_environment
            test_mcp_connection
            check_azure_limits
            check_azure_policies
            ;;
    esac
    
    echo ""
    log_success "¡Proceso completado exitosamente!"
    log_info "Contexto Azure sincronizado con servidores MCP"
    log_info "Variables de entorno configuradas para este proyecto"
    echo ""
}

# Ejecutar función principal con todos los argumentos
main "$@"