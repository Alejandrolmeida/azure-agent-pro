#!/bin/bash

# Script de deployment para templates Bicep
# Este script facilita el despliegue de plantillas Bicep en Azure

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para cargar configuración
load_config() {
    local config_file="../config/azure-config.env"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log_info "Configuración cargada"
    else
        log_error "Configuración no encontrada. Ejecuta primero: ./login/azure-login.sh"
        exit 1
    fi
}

# Función para validar Bicep CLI
check_bicep_cli() {
    if ! command -v az bicep &> /dev/null; then
        log_warning "Bicep CLI no encontrado. Instalando..."
        az bicep install
        log_success "Bicep CLI instalado"
    else
        local version=$(az bicep version --query bicepVersion -o tsv 2>/dev/null || echo "unknown")
        log_info "Bicep CLI versión: $version"
    fi
}

# Función para validar plantilla Bicep
validate_template() {
    local template_file="$1"
    local parameters_file="${2:-}"
    
    log_info "Validando plantilla Bicep: $template_file"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Archivo de plantilla no encontrado: $template_file"
        exit 1
    fi
    
    # Construir comando de validación
    local validate_cmd="az deployment group validate --resource-group temp-validation --template-file $template_file"
    
    if [[ -n "$parameters_file" && -f "$parameters_file" ]]; then
        validate_cmd+=" --parameters @$parameters_file"
        log_info "Usando archivo de parámetros: $parameters_file"
    fi
    
    # Crear grupo temporal para validación
    local temp_rg="temp-validation-$(date +%s)"
    log_info "Creando grupo temporal para validación: $temp_rg"
    az group create --name "$temp_rg" --location "$AZURE_LOCATION" > /dev/null
    
    # Ejecutar validación
    if eval "$validate_cmd --resource-group $temp_rg" > /dev/null 2>&1; then
        log_success "Plantilla válida"
    else
        log_error "Error en validación de plantilla"
        az group delete --name "$temp_rg" --yes --no-wait > /dev/null 2>&1
        exit 1
    fi
    
    # Limpiar grupo temporal
    az group delete --name "$temp_rg" --yes --no-wait > /dev/null 2>&1
    log_info "Grupo temporal eliminado"
}

# Función para realizar deployment
deploy_template() {
    local template_file="$1"
    local resource_group="$2"
    local deployment_name="${3:-bicep-deployment-$(date +%Y%m%d%H%M%S)}"
    local parameters_file="${4:-}"
    local mode="${5:-Incremental}"
    
    log_info "Iniciando deployment..."
    log_info "Plantilla: $template_file"
    log_info "Grupo de recursos: $resource_group"
    log_info "Nombre del deployment: $deployment_name"
    log_info "Modo: $mode"
    
    # Verificar si el grupo de recursos existe
    if ! az group show --name "$resource_group" &> /dev/null; then
        log_warning "El grupo de recursos '$resource_group' no existe"
        read -p "¿Deseas crearlo? (y/n): " create_rg
        
        if [[ $create_rg == "y" || $create_rg == "Y" ]]; then
            log_info "Creando grupo de recursos: $resource_group"
            az group create --name "$resource_group" --location "$AZURE_LOCATION"
            log_success "Grupo de recursos creado"
        else
            log_error "Deployment cancelado"
            exit 1
        fi
    fi
    
    # Construir comando de deployment
    local deploy_cmd="az deployment group create"
    deploy_cmd+=" --resource-group $resource_group"
    deploy_cmd+=" --name $deployment_name"
    deploy_cmd+=" --template-file $template_file"
    deploy_cmd+=" --mode $mode"
    
    if [[ -n "$parameters_file" && -f "$parameters_file" ]]; then
        deploy_cmd+=" --parameters @$parameters_file"
    fi
    
    # Ejecutar deployment
    log_info "Ejecutando deployment..."
    if eval "$deploy_cmd"; then
        log_success "Deployment completado exitosamente"
        
        # Mostrar outputs si existen
        local outputs=$(az deployment group show --resource-group "$resource_group" --name "$deployment_name" --query properties.outputs 2>/dev/null || echo "{}")
        if [[ "$outputs" != "{}" ]]; then
            log_info "Outputs del deployment:"
            echo "$outputs" | jq .
        fi
    else
        log_error "Error durante el deployment"
        exit 1
    fi
}

# Función para mostrar deployments existentes
list_deployments() {
    local resource_group="$1"
    
    if [[ -n "$resource_group" ]]; then
        log_info "Deployments en el grupo de recursos: $resource_group"
        az deployment group list --resource-group "$resource_group" --query '[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}' -o table
    else
        log_info "Deployments por grupo de recursos:"
        az deployment group list --query 'group_by([].{ResourceGroup:resourceGroup, Name:name, State:properties.provisioningState}, &ResourceGroup)' -o table
    fi
}

# Función para eliminar deployment
delete_deployment() {
    local resource_group="$1"
    local deployment_name="$2"
    
    log_warning "Eliminando deployment: $deployment_name en $resource_group"
    
    if az deployment group delete --resource-group "$resource_group" --name "$deployment_name"; then
        log_success "Deployment eliminado"
    else
        log_error "Error al eliminar deployment"
        exit 1
    fi
}

# Función para generar template de parámetros
generate_parameters_template() {
    local template_file="$1"
    local output_file="${2:-parameters.json}"
    
    log_info "Generando plantilla de parámetros desde: $template_file"
    
    # Usar Bicep para generar parámetros
    az bicep generate-params --file "$template_file" --output-file "$output_file"
    
    if [[ -f "$output_file" ]]; then
        log_success "Plantilla de parámetros generada: $output_file"
    else
        log_error "Error al generar plantilla de parámetros"
        exit 1
    fi
}

# Función para mostrar ayuda
show_help() {
    echo ""
    echo "Bicep Deployment Script - Uso:"
    echo ""
    echo "  $0 [comando] [opciones]"
    echo ""
    echo "Comandos:"
    echo "  validate <template> [parameters]     Validar plantilla Bicep"
    echo "  deploy <template> <rg> [name] [params] [mode]  Realizar deployment"
    echo "  list [resource-group]                Listar deployments"
    echo "  delete <resource-group> <name>       Eliminar deployment"
    echo "  gen-params <template> [output]       Generar plantilla de parámetros"
    echo ""
    echo "Ejemplos:"
    echo "  $0 validate ../bicep/templates/storage.bicep"
    echo "  $0 deploy ../bicep/templates/storage.bicep my-rg storage-deploy params.json"
    echo "  $0 list my-rg"
    echo "  $0 gen-params ../bicep/templates/storage.bicep"
    echo ""
}

# Función principal
main() {
    local command="${1:-}"
    
    case "$command" in
        validate)
            check_bicep_cli
            validate_template "$2" "$3"
            ;;
        deploy)
            if [[ $# -lt 3 ]]; then
                log_error "Faltan argumentos para deploy"
                log_info "Uso: $0 deploy <template> <resource-group> [deployment-name] [parameters-file] [mode]"
                exit 1
            fi
            load_config
            check_bicep_cli
            validate_template "$2" "$5"
            deploy_template "$2" "$3" "$4" "$5" "$6"
            ;;
        list)
            load_config
            list_deployments "$2"
            ;;
        delete)
            if [[ $# -lt 3 ]]; then
                log_error "Faltan argumentos para delete"
                log_info "Uso: $0 delete <resource-group> <deployment-name>"
                exit 1
            fi
            load_config
            delete_deployment "$2" "$3"
            ;;
        gen-params)
            if [[ -z "$2" ]]; then
                log_error "Falta archivo de plantilla"
                log_info "Uso: $0 gen-params <template> [output-file]"
                exit 1
            fi
            check_bicep_cli
            generate_parameters_template "$2" "$3"
            ;;
        -h|--help|help)
            show_help
            ;;
        *)
            log_error "Comando no reconocido: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"