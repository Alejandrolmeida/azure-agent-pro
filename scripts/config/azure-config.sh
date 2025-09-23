#!/bin/bash

# Script de configuración de variables de entorno para Azure
# Este script carga las variables de configuración guardadas por azure-login.sh

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para cargar configuración
load_azure_config() {
    local config_file="../config/azure-config.env"
    
    if [[ -f "$config_file" ]]; then
        log_info "Cargando configuración desde: $config_file"
        source "$config_file"
        log_success "Configuración cargada exitosamente"
        
        echo ""
        echo "Variables de entorno configuradas:"
        echo "  AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"
        echo "  AZURE_SUBSCRIPTION_NAME: $AZURE_SUBSCRIPTION_NAME"
        echo "  AZURE_TENANT_ID: $AZURE_TENANT_ID"
        echo "  AZURE_USER: $AZURE_USER"
        echo "  AZURE_LOCATION: $AZURE_LOCATION"
        echo "  AZURE_RESOURCE_GROUP_PREFIX: $AZURE_RESOURCE_GROUP_PREFIX"
        echo "  AZURE_TAG_ENVIRONMENT: $AZURE_TAG_ENVIRONMENT"
        echo "  AZURE_TAG_PROJECT: $AZURE_TAG_PROJECT"
        echo ""
    else
        log_error "Archivo de configuración no encontrado: $config_file"
        log_info "Ejecuta primero: ./login/azure-login.sh"
        exit 1
    fi
}

# Función para validar la configuración actual
validate_azure_config() {
    log_info "Validando configuración de Azure..."
    
    # Verificar que Azure CLI esté logueado
    if ! az account show &> /dev/null; then
        log_error "No hay sesión activa de Azure CLI"
        log_info "Ejecuta: ./login/azure-login.sh"
        exit 1
    fi
    
    # Verificar que la suscripción coincida
    local current_sub=$(az account show --query id -o tsv)
    if [[ "$current_sub" != "$AZURE_SUBSCRIPTION_ID" ]]; then
        log_error "La suscripción actual ($current_sub) no coincide con la configurada ($AZURE_SUBSCRIPTION_ID)"
        log_info "Ejecuta: ./login/azure-login.sh -s"
        exit 1
    fi
    
    log_success "Configuración válida"
}

# Función para mostrar estado actual
show_current_status() {
    echo ""
    log_info "=== Estado Actual de Azure ==="
    echo ""
    
    if az account show &> /dev/null; then
        local account_info=$(az account show --query '{
            Subscription: name,
            SubscriptionId: id,
            User: user.name,
            TenantId: tenantId
        }' -o table)
        echo "$account_info"
    else
        log_error "No hay sesión activa de Azure CLI"
    fi
    
    echo ""
    log_info "Variables de entorno:"
    env | grep ^AZURE_ | sort
    echo ""
}

# Función para configurar ubicación por defecto
set_default_location() {
    local location="${1:-eastus}"
    
    log_info "Configurando ubicación por defecto: $location"
    az configure --defaults location="$location"
    
    # Actualizar variable de entorno
    export AZURE_LOCATION="$location"
    
    # Actualizar archivo de configuración
    local config_file="../config/azure-config.env"
    if [[ -f "$config_file" ]]; then
        sed -i "s/^export AZURE_LOCATION=.*/export AZURE_LOCATION=\"$location\"/" "$config_file"
        log_success "Ubicación actualizada en configuración"
    fi
}

# Función para listar ubicaciones disponibles
list_locations() {
    log_info "Obteniendo ubicaciones disponibles..."
    az account list-locations --query '[].{Name:name, DisplayName:displayName}' -o table
}

# Función principal
main() {
    case "${1:-}" in
        -l|--locations)
            list_locations
            ;;
        -s|--status)
            show_current_status
            ;;
        -v|--validate)
            load_azure_config
            validate_azure_config
            ;;
        --set-location)
            if [[ -z "$2" ]]; then
                log_error "Debes especificar una ubicación"
                log_info "Uso: $0 --set-location <ubicacion>"
                exit 1
            fi
            load_azure_config
            set_default_location "$2"
            ;;
        -h|--help)
            echo ""
            echo "Azure Config Script - Uso:"
            echo ""
            echo "  $0 [opciones]"
            echo ""
            echo "Opciones:"
            echo "  -h, --help              Mostrar ayuda"
            echo "  -l, --locations         Listar ubicaciones disponibles"
            echo "  -s, --status            Mostrar estado actual"
            echo "  -v, --validate          Validar configuración"
            echo "  --set-location <loc>    Establecer ubicación por defecto"
            echo ""
            echo "Ejemplos:"
            echo "  $0                      Cargar configuración"
            echo "  $0 -l                   Listar ubicaciones"
            echo "  $0 --set-location westeurope"
            echo ""
            exit 0
            ;;
        *)
            load_azure_config
            validate_azure_config
            show_current_status
            ;;
    esac
}

main "$@"