#!/bin/bash

# Azure Utilities Script
# Funciones auxiliares para operaciones comunes de Azure

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Funciones de logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }

# Función para cargar configuración
load_config() {
    local config_file="../config/azure-config.env"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log_debug "Configuración cargada desde $config_file"
    else
        log_error "Archivo de configuración no encontrado: $config_file"
        log_info "Ejecuta primero: ./login/azure-login.sh"
        exit 1
    fi
}

# Función para validar Azure CLI
validate_azure_cli() {
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI no está instalado"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        log_error "No hay sesión activa de Azure CLI"
        log_info "Ejecuta: ./login/azure-login.sh"
        exit 1
    fi
}

# ========================================
# FUNCIONES DE RECURSOS
# ========================================

# Listar recursos por tipo
list_resources_by_type() {
    local resource_type="$1"
    local resource_group="${2:-}"
    
    log_info "Listando recursos de tipo: $resource_type"
    
    if [[ -n "$resource_group" ]]; then
        az resource list \
            --resource-group "$resource_group" \
            --resource-type "$resource_type" \
            --query '[].{Name:name, Location:location, ResourceGroup:resourceGroup}' \
            --output table
    else
        az resource list \
            --resource-type "$resource_type" \
            --query '[].{Name:name, Location:location, ResourceGroup:resourceGroup}' \
            --output table
    fi
}

# Obtener costos de recursos
get_resource_costs() {
    local resource_group="${1:-}"
    local days="${2:-30}"
    
    log_info "Obteniendo costos de los últimos $days días"
    
    local start_date=$(date -d "$days days ago" +%Y-%m-%d)
    local end_date=$(date +%Y-%m-%d)
    
    if [[ -n "$resource_group" ]]; then
        az consumption usage list \
            --start-date "$start_date" \
            --end-date "$end_date" \
            --query "[?contains(instanceName, '$resource_group')].{Resource:instanceName, Cost:pretaxCost, Currency:currency}" \
            --output table
    else
        az consumption usage list \
            --start-date "$start_date" \
            --end-date "$end_date" \
            --query '[].{Resource:instanceName, Cost:pretaxCost, Currency:currency}' \
            --output table | head -20
    fi
}

# Limpiar recursos no utilizados
cleanup_unused_resources() {
    local dry_run="${1:-true}"
    
    log_info "Buscando recursos no utilizados..."
    
    # NICs no asociados
    log_info "Buscando NICs no asociados..."
    local unused_nics=$(az network nic list --query "[?virtualMachine==null].id" -o tsv)
    
    if [[ -n "$unused_nics" ]]; then
        echo "NICs no asociados encontrados:"
        echo "$unused_nics"
        
        if [[ "$dry_run" == "false" ]]; then
            for nic in $unused_nics; do
                log_warning "Eliminando NIC: $nic"
                az network nic delete --ids "$nic" --no-wait
            done
        fi
    fi
    
    # Discos no asociados
    log_info "Buscando discos no asociados..."
    local unused_disks=$(az disk list --query "[?diskState=='Unattached'].id" -o tsv)
    
    if [[ -n "$unused_disks" ]]; then
        echo "Discos no asociados encontrados:"
        echo "$unused_disks"
        
        if [[ "$dry_run" == "false" ]]; then
            for disk in $unused_disks; do
                log_warning "Eliminando disco: $disk"
                az disk delete --ids "$disk" --no-wait
            done
        fi
    fi
    
    # IPs públicas no asociadas
    log_info "Buscando IPs públicas no asociadas..."
    local unused_ips=$(az network public-ip list --query "[?ipConfiguration==null].id" -o tsv)
    
    if [[ -n "$unused_ips" ]]; then
        echo "IPs públicas no asociadas encontradas:"
        echo "$unused_ips"
        
        if [[ "$dry_run" == "false" ]]; then
            for ip in $unused_ips; do
                log_warning "Eliminando IP pública: $ip"
                az network public-ip delete --ids "$ip" --no-wait
            done
        fi
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "Ejecución en modo dry-run. Para eliminar recursos, usa: cleanup_unused_resources false"
    fi
}

# ========================================
# FUNCIONES DE STORAGE
# ========================================

# Crear storage account con configuración segura
create_secure_storage() {
    local storage_name="$1"
    local resource_group="$2"
    local location="${3:-$AZURE_LOCATION}"
    local sku="${4:-Standard_LRS}"
    
    log_info "Creando storage account seguro: $storage_name"
    
    az storage account create \
        --name "$storage_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --sku "$sku" \
        --kind StorageV2 \
        --access-tier Hot \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --tags Environment="$AZURE_TAG_ENVIRONMENT" Project="$AZURE_TAG_PROJECT"
    
    log_success "Storage account creado: $storage_name"
}

# Backup de blob containers
backup_blob_container() {
    local source_account="$1"
    local source_container="$2"
    local dest_account="$3"
    local dest_container="${4:-$source_container-backup-$(date +%Y%m%d)}"
    
    log_info "Realizando backup de $source_account/$source_container a $dest_account/$dest_container"
    
    # Crear container de destino si no existe
    az storage container create \
        --name "$dest_container" \
        --account-name "$dest_account" \
        --public-access off
    
    # Copiar blobs
    az storage blob copy start-batch \
        --source-account-name "$source_account" \
        --source-container "$source_container" \
        --destination-account-name "$dest_account" \
        --destination-container "$dest_container"
    
    log_success "Backup iniciado de $source_container"
}

# ========================================
# FUNCIONES DE NETWORKING
# ========================================

# Crear VNet con configuración estándar
create_standard_vnet() {
    local vnet_name="$1"
    local resource_group="$2"
    local address_space="${3:-10.0.0.0/16}"
    local location="${4:-$AZURE_LOCATION}"
    
    log_info "Creando VNet: $vnet_name"
    
    # Crear VNet
    az network vnet create \
        --name "$vnet_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --address-prefix "$address_space" \
        --tags Environment="$AZURE_TAG_ENVIRONMENT" Project="$AZURE_TAG_PROJECT"
    
    # Crear subnets por defecto
    az network vnet subnet create \
        --vnet-name "$vnet_name" \
        --resource-group "$resource_group" \
        --name "default" \
        --address-prefix "10.0.1.0/24"
    
    az network vnet subnet create \
        --vnet-name "$vnet_name" \
        --resource-group "$resource_group" \
        --name "app-subnet" \
        --address-prefix "10.0.2.0/24"
    
    log_success "VNet creado: $vnet_name"
}

# Verificar conectividad de red
test_network_connectivity() {
    local vm_name="$1"
    local resource_group="$2"
    local target_host="${3:-8.8.8.8}"
    local target_port="${4:-80}"
    
    log_info "Probando conectividad desde VM $vm_name a $target_host:$target_port"
    
    az vm run-command invoke \
        --resource-group "$resource_group" \
        --name "$vm_name" \
        --command-id RunShellScript \
        --scripts "nc -zv $target_host $target_port"
}

# ========================================
# FUNCIONES DE SEGURIDAD
# ========================================

# Auditar configuración de seguridad
security_audit() {
    local resource_group="${1:-}"
    
    log_info "Realizando auditoría de seguridad..."
    
    # Storage accounts sin HTTPS
    log_info "Verificando storage accounts sin HTTPS obligatorio..."
    if [[ -n "$resource_group" ]]; then
        az storage account list \
            --resource-group "$resource_group" \
            --query "[?supportsHttpsTrafficOnly==\`false\`].{Name:name, ResourceGroup:resourceGroup}" \
            --output table
    else
        az storage account list \
            --query "[?supportsHttpsTrafficOnly==\`false\`].{Name:name, ResourceGroup:resourceGroup}" \
            --output table
    fi
    
    # VMs sin Managed Identity
    log_info "Verificando VMs sin Managed Identity..."
    if [[ -n "$resource_group" ]]; then
        az vm list \
            --resource-group "$resource_group" \
            --query "[?identity==null].{Name:name, ResourceGroup:resourceGroup}" \
            --output table
    else
        az vm list \
            --query "[?identity==null].{Name:name, ResourceGroup:resourceGroup}" \
            --output table
    fi
    
    # NSGs con reglas demasiado permisivas
    log_info "Verificando NSGs con reglas permisivas..."
    local nsgs=$(az network nsg list --query '[].name' -o tsv)
    for nsg in $nsgs; do
        local permissive_rules=$(az network nsg rule list \
            --nsg-name "$nsg" \
            --query "[?access=='Allow' && direction=='Inbound' && sourceAddressPrefix=='*' && destinationPortRange=='*'].name" \
            -o tsv)
        
        if [[ -n "$permissive_rules" ]]; then
            log_warning "NSG $nsg tiene reglas muy permisivas: $permissive_rules"
        fi
    done
}

# Configurar Key Vault con mejores prácticas
create_secure_keyvault() {
    local vault_name="$1"
    local resource_group="$2"
    local location="${3:-$AZURE_LOCATION}"
    
    log_info "Creando Key Vault seguro: $vault_name"
    
    az keyvault create \
        --name "$vault_name" \
        --resource-group "$resource_group" \
        --location "$location" \
        --enable-soft-delete true \
        --enable-purge-protection true \
        --retention-days 90 \
        --tags Environment="$AZURE_TAG_ENVIRONMENT" Project="$AZURE_TAG_PROJECT"
    
    # Configurar política de acceso restrictiva
    az keyvault set-policy \
        --name "$vault_name" \
        --object-id "$(az ad signed-in-user show --query id -o tsv)" \
        --secret-permissions get list set delete recover backup restore \
        --key-permissions get list create delete recover backup restore \
        --certificate-permissions get list create delete recover backup restore
    
    log_success "Key Vault creado: $vault_name"
}

# ========================================
# FUNCIONES DE MONITOREO
# ========================================

# Obtener métricas de recursos
get_resource_metrics() {
    local resource_id="$1"
    local metric_names="$2"
    local time_grain="${3:-PT1H}"
    local start_time="${4:-$(date -d '24 hours ago' -u +%Y-%m-%dT%H:%M:%SZ)}"
    local end_time="${5:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    
    log_info "Obteniendo métricas para recurso: $(basename $resource_id)"
    
    az monitor metrics list \
        --resource "$resource_id" \
        --metric "$metric_names" \
        --interval "$time_grain" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --output table
}

# Configurar alertas básicas
setup_basic_alerts() {
    local resource_group="$1"
    local email="$2"
    
    log_info "Configurando alertas básicas para $resource_group"
    
    # Crear action group
    local action_group_name="email-alerts-$resource_group"
    az monitor action-group create \
        --name "$action_group_name" \
        --resource-group "$resource_group" \
        --short-name "EmailAlert" \
        --action email "$email" "$email"
    
    # Alerta para CPU alta en VMs
    local vms=$(az vm list --resource-group "$resource_group" --query '[].name' -o tsv)
    for vm in $vms; do
        az monitor metrics alert create \
            --name "high-cpu-$vm" \
            --resource-group "$resource_group" \
            --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$resource_group/providers/Microsoft.Compute/virtualMachines/$vm" \
            --condition "avg Percentage CPU > 80" \
            --action "$action_group_name" \
            --evaluation-frequency PT5M \
            --window-size PT15M
    done
    
    log_success "Alertas configuradas para $resource_group"
}

# ========================================
# FUNCIONES DE UTILIDAD
# ========================================

# Generar nombres únicos para recursos
generate_unique_name() {
    local prefix="$1"
    local suffix="${2:-$(echo $RANDOM | md5sum | head -c 5)}"
    echo "${prefix}-${suffix}"
}

# Validar nombres de recursos
validate_resource_name() {
    local name="$1"
    local type="$2"
    
    case "$type" in
        "storage")
            if [[ ${#name} -lt 3 || ${#name} -gt 24 ]]; then
                log_error "Storage account name debe tener entre 3 y 24 caracteres"
                return 1
            fi
            if [[ ! "$name" =~ ^[a-z0-9]+$ ]]; then
                log_error "Storage account name solo puede contener letras minúsculas y números"
                return 1
            fi
            ;;
        "vm")
            if [[ ${#name} -lt 1 || ${#name} -gt 64 ]]; then
                log_error "VM name debe tener entre 1 y 64 caracteres"
                return 1
            fi
            ;;
        "keyvault")
            if [[ ${#name} -lt 3 || ${#name} -gt 24 ]]; then
                log_error "Key Vault name debe tener entre 3 y 24 caracteres"
                return 1
            fi
            ;;
    esac
    
    log_success "Nombre válido: $name"
    return 0
}

# Función para mostrar ayuda
show_help() {
    echo ""
    echo "Azure Utilities Script - Funciones disponibles:"
    echo ""
    echo "RECURSOS:"
    echo "  list_resources_by_type <type> [resource-group]"
    echo "  get_resource_costs [resource-group] [days]"
    echo "  cleanup_unused_resources [true|false]"
    echo ""
    echo "STORAGE:"
    echo "  create_secure_storage <name> <resource-group> [location] [sku]"
    echo "  backup_blob_container <src-account> <src-container> <dest-account> [dest-container]"
    echo ""
    echo "NETWORKING:"
    echo "  create_standard_vnet <name> <resource-group> [address-space] [location]"
    echo "  test_network_connectivity <vm-name> <resource-group> [target-host] [target-port]"
    echo ""
    echo "SEGURIDAD:"
    echo "  security_audit [resource-group]"
    echo "  create_secure_keyvault <name> <resource-group> [location]"
    echo ""
    echo "MONITOREO:"
    echo "  get_resource_metrics <resource-id> <metric-names> [time-grain] [start-time] [end-time]"
    echo "  setup_basic_alerts <resource-group> <email>"
    echo ""
    echo "UTILIDADES:"
    echo "  generate_unique_name <prefix> [suffix]"
    echo "  validate_resource_name <name> <type>"
    echo ""
    echo "Ejemplos:"
    echo "  $0 list_resources_by_type Microsoft.Compute/virtualMachines"
    echo "  $0 create_secure_storage mystorageaccount my-rg"
    echo "  $0 security_audit my-rg"
    echo ""
}

# Función principal
main() {
    local function_name="${1:-help}"
    shift || true
    
    # Cargar configuración si no es help
    if [[ "$function_name" != "help" && "$function_name" != "show_help" ]]; then
        validate_azure_cli
        load_config
    fi
    
    case "$function_name" in
        "list_resources_by_type")
            list_resources_by_type "$@"
            ;;
        "get_resource_costs")
            get_resource_costs "$@"
            ;;
        "cleanup_unused_resources")
            cleanup_unused_resources "$@"
            ;;
        "create_secure_storage")
            create_secure_storage "$@"
            ;;
        "backup_blob_container")
            backup_blob_container "$@"
            ;;
        "create_standard_vnet")
            create_standard_vnet "$@"
            ;;
        "test_network_connectivity")
            test_network_connectivity "$@"
            ;;
        "security_audit")
            security_audit "$@"
            ;;
        "create_secure_keyvault")
            create_secure_keyvault "$@"
            ;;
        "get_resource_metrics")
            get_resource_metrics "$@"
            ;;
        "setup_basic_alerts")
            setup_basic_alerts "$@"
            ;;
        "generate_unique_name")
            generate_unique_name "$@"
            ;;
        "validate_resource_name")
            validate_resource_name "$@"
            ;;
        "help"|"show_help"|*)
            show_help
            ;;
    esac
}

# Ejecutar si se llama directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi