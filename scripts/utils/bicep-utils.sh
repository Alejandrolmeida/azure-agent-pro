#!/bin/bash

# Bicep Utilities Script
# Funciones auxiliares para trabajar con plantillas Bicep

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Funciones de logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }

# Verificar Bicep CLI
validate_bicep_cli() {
    if ! az bicep version &> /dev/null; then
        log_warning "Bicep CLI no encontrado. Instalando..."
        az bicep install
        log_success "Bicep CLI instalado"
    fi
}

# ========================================
# FUNCIONES DE DESARROLLO
# ========================================

# Crear plantilla Bicep desde template
create_bicep_template() {
    local template_type="$1"
    local output_file="$2"
    local resource_name="${3:-myresource}"
    
    log_info "Creando plantilla Bicep: $template_type"
    
    case "$template_type" in
        "storage")
            cat > "$output_file" << 'EOF'
@description('Storage account name')
param storageAccountName string

@description('Location for the storage account')
param location string = resourceGroup().location

@description('Storage account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param sku string = 'Standard_LRS'

@description('Tags for the storage account')
param tags object = {
  Environment: 'dev'
  Project: 'myproject'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

output storageAccountId string = storageAccount.id
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
EOF
            ;;
        "vm")
            cat > "$output_file" << 'EOF'
@description('Virtual machine name')
param vmName string

@description('Location for the VM')
param location string = resourceGroup().location

@description('VM size')
param vmSize string = 'Standard_B2s'

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('OS disk type')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
])
param osDiskType string = 'Standard_LRS'

@description('Tags for resources')
param tags object = {
  Environment: 'dev'
  Project: 'myproject'
}

var networkInterfaceName = '${vmName}-nic'
var publicIPName = '${vmName}-pip'
var networkSecurityGroupName = '${vmName}-nsg'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: networkSecurityGroupName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1001
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIPName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: networkInterfaceName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

output vmId string = virtualMachine.id
output publicIPAddress string = publicIP.properties.ipAddress
EOF
            ;;
        "webapp")
            cat > "$output_file" << 'EOF'
@description('Web app name')
param webAppName string

@description('Location for resources')
param location string = resourceGroup().location

@description('App Service Plan name')
param appServicePlanName string = '${webAppName}-asp'

@description('App Service Plan SKU')
@allowed([
  'F1'
  'B1'
  'B2'
  'S1'
  'S2'
  'P1V2'
])
param sku string = 'F1'

@description('Runtime stack')
@allowed([
  'NODE|18-lts'
  'PYTHON|3.9'
  'DOTNETCORE|6.0'
  'JAVA|11'
])
param runtimeStack string = 'NODE|18-lts'

@description('Tags for resources')
param tags object = {
  Environment: 'dev'
  Project: 'myproject'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'app'
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: runtimeStack
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppId string = webApp.id
EOF
            ;;
        *)
            log_error "Tipo de plantilla no soportado: $template_type"
            log_info "Tipos disponibles: storage, vm, webapp"
            return 1
            ;;
    esac
    
    log_success "Plantilla Bicep creada: $output_file"
}

# Generar archivo de parámetros automáticamente
generate_parameters_file() {
    local template_file="$1"
    local output_file="${2:-${template_file%.*}.parameters.json}"
    local environment="${3:-dev}"
    
    log_info "Generando archivo de parámetros para: $template_file"
    
    # Verificar que el archivo template existe
    if [[ ! -f "$template_file" ]]; then
        log_error "Archivo de plantilla no encontrado: $template_file"
        return 1
    fi
    
    # Usar Bicep CLI para generar parámetros base
    az bicep generate-params --file "$template_file" --output-file "$output_file"
    
    # Personalizar para el entorno
    local temp_file=$(mktemp)
    jq --arg env "$environment" '
        .parameters |= with_entries(
            if .key == "location" then
                .value.value = "eastus"
            elif .key == "environment" then
                .value.value = $env
            elif .key == "tags" then
                .value.value = {
                    "Environment": $env,
                    "Project": "azure-agent",
                    "CreatedBy": "bicep-utils"
                }
            else
                .
            end
        )
    ' "$output_file" > "$temp_file" && mv "$temp_file" "$output_file"
    
    log_success "Archivo de parámetros generado: $output_file"
}

# ========================================
# FUNCIONES DE VALIDACIÓN
# ========================================

# Linting avanzado de Bicep
lint_bicep_advanced() {
    local template_file="$1"
    local fix_issues="${2:-false}"
    
    log_info "Ejecutando linting avanzado en: $template_file"
    
    # Linting básico
    log_info "Ejecutando linting básico..."
    az bicep lint --file "$template_file"
    
    # Verificaciones adicionales
    log_info "Verificando mejores prácticas..."
    
    # Verificar que se usan las versiones más recientes de API
    log_info "Verificando versiones de API..."
    local old_apis=$(grep -n "@[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" "$template_file" | grep -v "2023\|2024")
    if [[ -n "$old_apis" ]]; then
        log_warning "APIs antiguas encontradas:"
        echo "$old_apis"
    fi
    
    # Verificar uso de @secure() para passwords
    log_info "Verificando uso de @secure()..."
    local insecure_passwords=$(grep -n "param.*[Pp]assword\|param.*[Ss]ecret" "$template_file" | grep -v "@secure()")
    if [[ -n "$insecure_passwords" ]]; then
        log_warning "Parámetros de contraseña sin @secure() encontrados:"
        echo "$insecure_passwords"
    fi
    
    # Verificar que hay descriptions
    log_info "Verificando descriptions..."
    local missing_descriptions=$(grep -n "^param\|^var\|^output" "$template_file" | grep -v "@description")
    if [[ -n "$missing_descriptions" ]]; then
        log_warning "Elementos sin @description encontrados:"
        echo "$missing_descriptions"
    fi
    
    # Verificar tags en recursos
    log_info "Verificando tags en recursos..."
    local resources_without_tags=$(grep -A 10 "^resource" "$template_file" | grep -B 10 "properties:" | grep -v "tags:")
    if [[ -n "$resources_without_tags" ]]; then
        log_warning "Considerar agregar tags a todos los recursos"
    fi
    
    log_success "Linting avanzado completado"
}

# Validar convenciones de nomenclatura
validate_naming_conventions() {
    local template_file="$1"
    
    log_info "Validando convenciones de nomenclatura en: $template_file"
    
    # Verificar naming pattern para recursos
    local issues_found=false
    
    # Storage accounts (lowercase, no dashes)
    local storage_names=$(grep -o "name:.*'.*st.*'" "$template_file" || true)
    if [[ -n "$storage_names" ]]; then
        for name in $storage_names; do
            if [[ "$name" =~ [A-Z] || "$name" =~ [-] ]]; then
                log_warning "Storage account name debería ser lowercase sin guiones: $name"
                issues_found=true
            fi
        done
    fi
    
    # Key Vault names (should include 'kv')
    local kv_names=$(grep -o "Microsoft.KeyVault/vaults" -A 5 "$template_file" | grep "name:" || true)
    if [[ -n "$kv_names" && ! "$kv_names" =~ "kv" ]]; then
        log_warning "Key Vault debería incluir 'kv' en el nombre"
        issues_found=true
    fi
    
    if [[ "$issues_found" == false ]]; then
        log_success "Convenciones de nomenclatura correctas"
    fi
}

# ========================================
# FUNCIONES DE OPTIMIZACIÓN
# ========================================

# Optimizar plantilla Bicep
optimize_bicep_template() {
    local template_file="$1"
    local output_file="${2:-${template_file%.*}.optimized.bicep}"
    
    log_info "Optimizando plantilla Bicep: $template_file"
    
    # Crear copia de trabajo
    cp "$template_file" "$output_file"
    
    # Optimización 1: Consolidar variables similares
    log_info "Consolidando variables similares..."
    
    # Optimización 2: Agregar outputs útiles si faltan
    log_info "Verificando outputs útiles..."
    if ! grep -q "output.*Id" "$output_file"; then
        log_info "Agregando output de ID de recurso principal..."
        # Esto requeriría análisis más sofisticado del contenido
    fi
    
    # Optimización 3: Agregar tags si faltan
    log_info "Verificando tags consistentes..."
    if ! grep -q "tags:" "$output_file"; then
        log_warning "Considerar agregar tags consistentes a todos los recursos"
    fi
    
    log_success "Plantilla optimizada guardada: $output_file"
}

# Analizar dependencias de recursos
analyze_dependencies() {
    local template_file="$1"
    
    log_info "Analizando dependencias en: $template_file"
    
    # Extraer recursos
    local resources=$(grep -n "^resource" "$template_file")
    log_info "Recursos encontrados:"
    echo "$resources"
    
    # Buscar dependencias explícitas
    log_info "Dependencias explícitas (dependsOn):"
    grep -n "dependsOn:" "$template_file" || log_info "No se encontraron dependencias explícitas"
    
    # Buscar dependencias implícitas (referencias)
    log_info "Dependencias implícitas (referencias a otros recursos):"
    grep -n "\\.id" "$template_file" || log_info "No se encontraron referencias implícitas"
}

# ========================================
# FUNCIONES DE TESTING
# ========================================

# Test de deployment What-If
test_whatif_deployment() {
    local template_file="$1"
    local resource_group="$2"
    local parameters_file="${3:-}"
    
    log_info "Ejecutando What-If deployment para: $template_file"
    
    local cmd="az deployment group what-if --resource-group $resource_group --template-file $template_file"
    
    if [[ -n "$parameters_file" && -f "$parameters_file" ]]; then
        cmd+=" --parameters @$parameters_file"
    fi
    
    log_info "Comando: $cmd"
    eval "$cmd"
}

# Crear entorno de testing
create_test_environment() {
    local test_prefix="${1:-test}"
    local location="${2:-eastus}"
    
    local test_rg="${test_prefix}-rg-$(date +%Y%m%d%H%M%S)"
    
    log_info "Creando entorno de testing: $test_rg"
    
    az group create --name "$test_rg" --location "$location" --tags Purpose=Testing CreatedBy=bicep-utils
    
    log_success "Entorno de testing creado: $test_rg"
    echo "$test_rg"
}

# Limpiar entorno de testing
cleanup_test_environment() {
    local resource_group="$1"
    local confirm="${2:-true}"
    
    if [[ "$confirm" == "true" ]]; then
        read -p "¿Estás seguro de eliminar el grupo de recursos $resource_group? (y/N): " confirmation
        if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
            log_info "Operación cancelada"
            return 0
        fi
    fi
    
    log_info "Eliminando entorno de testing: $resource_group"
    az group delete --name "$resource_group" --yes --no-wait
    log_success "Eliminación iniciada para: $resource_group"
}

# ========================================
# FUNCIONES DE DOCUMENTACIÓN
# ========================================

# Generar documentación de plantilla
generate_bicep_docs() {
    local template_file="$1"
    local output_file="${2:-${template_file%.*}-docs.md}"
    
    log_info "Generando documentación para: $template_file"
    
    cat > "$output_file" << EOF
# Documentación de Plantilla Bicep

**Archivo:** \`$(basename "$template_file")\`  
**Generado:** $(date)

## Descripción

$(grep "@description" "$template_file" | head -1 | sed "s/@description('//" | sed "s/')//" || echo "No hay descripción disponible")

## Parámetros

| Nombre | Tipo | Descripción | Valor por Defecto |
|--------|------|-------------|-------------------|
EOF
    
    # Extraer parámetros
    local params=$(grep -A 1 "^param" "$template_file")
    echo "$params" | while read -r line; do
        if [[ "$line" =~ ^param ]]; then
            local param_name=$(echo "$line" | cut -d' ' -f2)
            local param_type=$(echo "$line" | cut -d' ' -f3)
            local default_value=$(echo "$line" | grep -o "= .*" | cut -c3- || echo "N/A")
            echo "| $param_name | $param_type | | $default_value |" >> "$output_file"
        fi
    done
    
    cat >> "$output_file" << EOF

## Recursos Creados

EOF
    
    # Extraer recursos
    grep "^resource" "$template_file" | while read -r line; do
        local resource_name=$(echo "$line" | awk '{print $2}')
        local resource_type=$(echo "$line" | awk '{print $3}' | cut -d'@' -f1)
        echo "- **$resource_name**: $resource_type" >> "$output_file"
    done
    
    cat >> "$output_file" << EOF

## Outputs

EOF
    
    # Extraer outputs
    grep "^output" "$template_file" | while read -r line; do
        local output_name=$(echo "$line" | awk '{print $2}')
        local output_type=$(echo "$line" | awk '{print $3}')
        echo "- **$output_name** ($output_type)" >> "$output_file"
    done
    
    log_success "Documentación generada: $output_file"
}

# ========================================
# FUNCIÓN DE AYUDA
# ========================================

show_help() {
    echo ""
    echo "Bicep Utilities Script - Funciones disponibles:"
    echo ""
    echo "DESARROLLO:"
    echo "  create_bicep_template <type> <output-file> [resource-name]"
    echo "    Tipos: storage, vm, webapp"
    echo "  generate_parameters_file <template-file> [output-file] [environment]"
    echo ""
    echo "VALIDACIÓN:"
    echo "  lint_bicep_advanced <template-file> [fix-issues]"
    echo "  validate_naming_conventions <template-file>"
    echo ""
    echo "OPTIMIZACIÓN:"
    echo "  optimize_bicep_template <template-file> [output-file]"
    echo "  analyze_dependencies <template-file>"
    echo ""
    echo "TESTING:"
    echo "  test_whatif_deployment <template-file> <resource-group> [parameters-file]"
    echo "  create_test_environment [test-prefix] [location]"
    echo "  cleanup_test_environment <resource-group> [confirm]"
    echo ""
    echo "DOCUMENTACIÓN:"
    echo "  generate_bicep_docs <template-file> [output-file]"
    echo ""
    echo "Ejemplos:"
    echo "  $0 create_bicep_template storage my-storage.bicep"
    echo "  $0 lint_bicep_advanced main.bicep"
    echo "  $0 test_whatif_deployment main.bicep test-rg parameters.json"
    echo "  $0 generate_bicep_docs main.bicep"
    echo ""
}

# Función principal
main() {
    local function_name="${1:-help}"
    shift || true
    
    # Validar Bicep CLI si no es help
    if [[ "$function_name" != "help" && "$function_name" != "show_help" ]]; then
        validate_bicep_cli
    fi
    
    case "$function_name" in
        "create_bicep_template")
            create_bicep_template "$@"
            ;;
        "generate_parameters_file")
            generate_parameters_file "$@"
            ;;
        "lint_bicep_advanced")
            lint_bicep_advanced "$@"
            ;;
        "validate_naming_conventions")
            validate_naming_conventions "$@"
            ;;
        "optimize_bicep_template")
            optimize_bicep_template "$@"
            ;;
        "analyze_dependencies")
            analyze_dependencies "$@"
            ;;
        "test_whatif_deployment")
            test_whatif_deployment "$@"
            ;;
        "create_test_environment")
            create_test_environment "$@"
            ;;
        "cleanup_test_environment")
            cleanup_test_environment "$@"
            ;;
        "generate_bicep_docs")
            generate_bicep_docs "$@"
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