#!/bin/bash
# ============================================================================
# AVD H100 POC - Deployment Script
# ============================================================================
# Script para desplegar infraestructura AVD con VM NC40ads_H100_v5
# Región: Spain Central
# Subscription: POC AVD
# ============================================================================

set -e  # Exit on error

# ============================================================================
# COLORS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCTIONS
# ============================================================================

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

# ============================================================================
# CONFIGURATION
# ============================================================================

SUBSCRIPTION_ID="36a06bba-6ca7-46f8-a1a8-4abbbebeee86"
SUBSCRIPTION_NAME="POC AVD"
LOCATION="spaincentral"
BICEP_MAIN="bicep/avd-h100-poc/main.bicep"
PARAMETERS_FILE="bicep/avd-h100-poc/parameters/poc.bicepparam"
DEPLOYMENT_NAME="avd-h100-poc-$(date +%Y%m%d-%H%M%S)"

# ============================================================================
# PRE-DEPLOYMENT CHECKS
# ============================================================================

log_info "==================================================================="
log_info "AVD H100 POC - Pre-deployment Checks"
log_info "==================================================================="

# Check Azure CLI
if ! command -v az &> /dev/null; then
    log_error "Azure CLI no está instalado. Instalar desde: https://aka.ms/install-azure-cli"
    exit 1
fi

log_success "Azure CLI encontrado: $(az version --query '\"azure-cli\"' -o tsv)"

# Check login status
log_info "Verificando autenticación Azure..."
if ! az account show &> /dev/null; then
    log_warning "No autenticado. Iniciando sesión..."
    az login
fi

CURRENT_USER=$(az account show --query user.name -o tsv)
log_success "Autenticado como: $CURRENT_USER"

# Set subscription
log_info "Configurando subscription: $SUBSCRIPTION_NAME"
az account set --subscription "$SUBSCRIPTION_ID"
log_success "Subscription configurada: $(az account show --query name -o tsv)"

# Check quota
log_info "Verificando cuota NC40ads_H100_v5 en $LOCATION..."
QUOTA_USAGE=$(az vm list-usage --location "$LOCATION" --query "[?name.value=='standardNCadsH100v5Family'].{current:currentValue, limit:limit}" -o json)

if [ -n "$QUOTA_USAGE" ]; then
    CURRENT=$(echo "$QUOTA_USAGE" | jq -r '.[0].current')
    LIMIT=$(echo "$QUOTA_USAGE" | jq -r '.[0].limit')
    
    log_info "Cuota NC40ads_H100_v5: $CURRENT / $LIMIT cores"
    
    if [ "$LIMIT" -lt 40 ]; then
        log_error "Cuota insuficiente. Se requieren 40 cores, disponibles: $LIMIT"
        exit 1
    fi
    
    log_success "Cuota verificada: $LIMIT cores disponibles"
else
    log_warning "No se pudo verificar la cuota. Continuando de todos modos..."
fi

# ============================================================================
# COLLECT REQUIRED PARAMETERS
# ============================================================================

log_info "==================================================================="
log_info "Recopilando parámetros necesarios"
log_info "==================================================================="

# VM Admin Username
read -p "Nombre de usuario administrador de la VM [azureadmin]: " VM_ADMIN_USERNAME
VM_ADMIN_USERNAME=${VM_ADMIN_USERNAME:-azureadmin}

# VM Admin Password
while true; do
    read -sp "Contraseña del administrador (mín. 12 caracteres): " VM_ADMIN_PASSWORD
    echo
    
    if [ ${#VM_ADMIN_PASSWORD} -lt 12 ]; then
        log_error "La contraseña debe tener al menos 12 caracteres"
        continue
    fi
    
    read -sp "Confirmar contraseña: " VM_ADMIN_PASSWORD_CONFIRM
    echo
    
    if [ "$VM_ADMIN_PASSWORD" != "$VM_ADMIN_PASSWORD_CONFIRM" ]; then
        log_error "Las contraseñas no coinciden"
        continue
    fi
    
    break
done

# AVD User Object ID
read -p "Email del usuario Azure AD para acceso AVD: " AVD_USER_EMAIL

if [ -n "$AVD_USER_EMAIL" ]; then
    log_info "Buscando usuario Azure AD: $AVD_USER_EMAIL"
    AVD_USER_OBJECT_ID=$(az ad user show --id "$AVD_USER_EMAIL" --query id -o tsv 2>/dev/null || echo "")
    
    if [ -z "$AVD_USER_OBJECT_ID" ]; then
        log_error "Usuario no encontrado en Azure AD: $AVD_USER_EMAIL"
        exit 1
    fi
    
    log_success "Usuario encontrado. Object ID: $AVD_USER_OBJECT_ID"
else
    log_error "Email de usuario es obligatorio"
    exit 1
fi

# Source IP Address
log_info "Obteniendo tu IP pública..."
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "")

if [ -n "$PUBLIC_IP" ]; then
    log_success "Tu IP pública detectada: $PUBLIC_IP"
    ALLOWED_SOURCE_IP="$PUBLIC_IP/32"
else
    log_warning "No se pudo detectar IP pública automáticamente"
    read -p "Ingresa tu IP pública (formato: x.x.x.x): " PUBLIC_IP
    ALLOWED_SOURCE_IP="$PUBLIC_IP/32"
fi

log_info "IP permitida en NSG: $ALLOWED_SOURCE_IP"

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================

log_info "==================================================================="
log_info "Resumen del Despliegue"
log_info "==================================================================="
echo ""
echo "Subscription:          $SUBSCRIPTION_NAME"
echo "Region:                $LOCATION"
echo "VM Size:               Standard_NC40ads_H100_v5"
echo "VM Admin User:         $VM_ADMIN_USERNAME"
echo "AVD User:              $AVD_USER_EMAIL"
echo "AVD User Object ID:    $AVD_USER_OBJECT_ID"
echo "Allowed Source IP:     $ALLOWED_SOURCE_IP"
echo "Auto-shutdown:         Enabled (15 min idle)"
echo ""
echo "COSTOS ESTIMADOS:"
echo "  - Infraestructura:   €20/mes"
echo "  - VM (2.5h/día):     €48.90/día (€1,076/mes)"
echo "  - TOTAL ESTIMADO:    ~€1,096/mes"
echo ""

read -p "¿Continuar con el despliegue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log_warning "Despliegue cancelado por el usuario"
    exit 0
fi

# ============================================================================
# DEPLOYMENT
# ============================================================================

log_info "==================================================================="
log_info "Iniciando despliegue..."
log_info "==================================================================="

log_info "Validando template Bicep..."

az deployment sub validate \
    --location "$LOCATION" \
    --template-file "$BICEP_MAIN" \
    --parameters vmAdminUsername="$VM_ADMIN_USERNAME" \
    --parameters vmAdminPassword="$VM_ADMIN_PASSWORD" \
    --parameters avdUserObjectId="$AVD_USER_OBJECT_ID" \
    --parameters allowedSourceIpAddress="$ALLOWED_SOURCE_IP" \
    --output none

if [ $? -eq 0 ]; then
    log_success "Validación exitosa"
else
    log_error "Validación fallida. Revisar errores arriba."
    exit 1
fi

log_info "Desplegando infraestructura AVD H100 POC..."
log_info "Nombre del despliegue: $DEPLOYMENT_NAME"
log_info "Tiempo estimado: 30-40 minutos"

az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file "$BICEP_MAIN" \
    --parameters vmAdminUsername="$VM_ADMIN_USERNAME" \
    --parameters vmAdminPassword="$VM_ADMIN_PASSWORD" \
    --parameters avdUserObjectId="$AVD_USER_OBJECT_ID" \
    --parameters allowedSourceIpAddress="$ALLOWED_SOURCE_IP" \
    --output table

if [ $? -eq 0 ]; then
    log_success "Despliegue completado exitosamente"
else
    log_error "Despliegue fallido"
    exit 1
fi

# ============================================================================
# POST-DEPLOYMENT
# ============================================================================

log_info "==================================================================="
log_info "Post-deployment tasks"
log_info "==================================================================="

# Get outputs
log_info "Obteniendo información del despliegue..."

RESOURCE_GROUP=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query 'properties.outputs.resourceGroupName.value' -o tsv)
VM_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query 'properties.outputs.vmName.value' -o tsv)
STORAGE_ACCOUNT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query 'properties.outputs.storageAccountName.value' -o tsv)
AVD_WORKSPACE=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query 'properties.outputs.avdWorkspaceName.value' -o tsv)

log_success "Resource Group: $RESOURCE_GROUP"
log_success "VM Name: $VM_NAME"
log_success "Storage Account: $STORAGE_ACCOUNT"
log_success "AVD Workspace: $AVD_WORKSPACE"

# Upload runbook
log_info "Subiendo runbook PowerShell a Automation Account..."

AUTOMATION_ACCOUNT=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query 'properties.outputs.automationAccountName.value' -o tsv)

# TODO: Upload runbook script to automation account
# Esto requiere que el runbook esté publicado en una URL pública o en GitHub

log_info "==================================================================="
log_success "¡DESPLIEGUE COMPLETADO!"
log_info "==================================================================="
echo ""
echo "PRÓXIMOS PASOS:"
echo ""
echo "1. Conectarse al escritorio AVD:"
echo "   - Ir a https://client.wvd.microsoft.com/arm/webclient"
echo "   - Iniciar sesión con: $AVD_USER_EMAIL"
echo "   - Seleccionar workspace: $AVD_WORKSPACE"
echo ""
echo "2. Transferir archivos al Storage Account:"
echo "   azcopy copy 'C:\\MisArchivos\\*' 'https://$STORAGE_ACCOUNT.blob.core.windows.net/file-uploads?<SAS>' --recursive"
echo ""
echo "3. Generar SAS token:"
echo "   az storage container generate-sas --account-name $STORAGE_ACCOUNT --name file-uploads --permissions rwl --expiry 2025-12-31"
echo ""
echo "4. Monitorear costos:"
echo "   - Portal Azure → Cost Management → Cost Analysis"
echo "   - Filtrar por tag: workload-type"
echo ""
echo "5. Verificar auto-shutdown:"
echo "   - Portal Azure → Automation Accounts → $AUTOMATION_ACCOUNT → Jobs"
echo ""

log_info "==================================================================="
