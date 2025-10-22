# ====================================================================
# Conexión RDP a PIX4D VM via Azure Bastion
# ====================================================================
#
# Este script se conecta a la VM pix4d-vm en Azure usando Bastion
#
# REQUISITOS:
# - Azure CLI instalado (https://aka.ms/installazurecli)
# - PowerShell 5.1 o superior
#
# CREDENCIALES RDP:
# - Usuario: AzureAD\alejandro.almeida.garcia@gmail.com
# - Contraseña: Tu cuenta Microsoft
#
# ====================================================================

# Configurar ventana
$Host.UI.RawUI.WindowTitle = "Conectando a PIX4D VM via Bastion"
$ErrorActionPreference = "Stop"

# Colores
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Error-Message { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Warning-Message { Write-Host "⚠️  $args" -ForegroundColor Yellow }

# Banner
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         CONEXION RDP A PIX4D VM VIA AZURE BASTION             ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar Azure CLI
Write-Info "Verificando Azure CLI..."
try {
    $azVersion = az version --query '\"azure-cli\"' -o tsv 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Azure CLI $azVersion instalado"
    } else {
        throw "Azure CLI no encontrado"
    }
} catch {
    Write-Error-Message "Azure CLI no está instalado"
    Write-Host ""
    Write-Info "Descárgalo desde: https://aka.ms/installazurecli"
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Verificar sesión Azure
Write-Host ""
Write-Info "Verificando sesión de Azure..."
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Sesión activa: $($account.user.name)"
    } else {
        throw "No hay sesión activa"
    }
} catch {
    Write-Warning-Message "No hay sesión activa en Azure"
    Write-Host ""
    Write-Info "Iniciando login..."
    az login
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Message "Error en el login"
        Read-Host "Presiona Enter para salir"
        exit 1
    }
    Write-Success "Login exitoso"
}

# Verificar estado de la VM
Write-Host ""
Write-Info "Verificando estado de la VM..."
try {
    $vmStatus = az vm get-instance-view `
        -g rg-pix4d-lab-northeurope `
        -n pix4d-vm `
        --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" `
        -o tsv 2>$null
    
    if ($vmStatus -eq "VM running") {
        Write-Success "VM está encendida"
    } elseif ($vmStatus -eq "VM deallocated") {
        Write-Warning-Message "VM está apagada"
        Write-Host ""
        $response = Read-Host "¿Quieres encenderla? (s/n)"
        if ($response -eq "s" -or $response -eq "S") {
            Write-Info "Encendiendo VM (esto toma 2-3 minutos)..."
            az vm start -g rg-pix4d-lab-northeurope -n pix4d-vm --no-wait
            Write-Success "VM en proceso de arranque"
            Write-Info "Esperando 2 minutos..."
            Start-Sleep -Seconds 120
        } else {
            Write-Error-Message "No se puede conectar a una VM apagada"
            Read-Host "Presiona Enter para salir"
            exit 1
        }
    } else {
        Write-Warning-Message "Estado de VM: $vmStatus"
    }
} catch {
    Write-Warning-Message "No se pudo verificar el estado de la VM"
}

# Mostrar información
Write-Host ""
Write-Host "📊 INFORMACIÓN DE LA VM:" -ForegroundColor Yellow
Write-Host "   • Nombre: pix4d-vm"
Write-Host "   • Resource Group: rg-pix4d-lab-northeurope"
Write-Host "   • Región: North Europe"
Write-Host "   • Tipo: Standard_NV4as_v4 (AMD GPU)"
Write-Host "   • OS: Windows 11 Enterprise 23H2"
Write-Host ""

Write-Host "🔐 CREDENCIALES PARA LA VENTANA RDP:" -ForegroundColor Yellow
Write-Host "   • Usuario: " -NoNewline
Write-Host "AzureAD\alejandro.almeida.garcia@gmail.com" -ForegroundColor Green
Write-Host "   • Contraseña: " -NoNewline
Write-Host "[Tu cuenta Microsoft]" -ForegroundColor Cyan
Write-Host ""

Write-Info "Conectando via Bastion..."
Write-Host "   (Esto abrirá una ventana RDP en unos segundos)"
Write-Host ""

# Ejecutar conexión
try {
    az network bastion rdp `
        --name bastion-pix4d-lab `
        --resource-group rg-pix4d-lab-northeurope `
        --target-resource-id /subscriptions/fa69bf2d-3430-415f-bf70-70590e52fd98/resourceGroups/rg-pix4d-lab-northeurope/providers/Microsoft.Compute/virtualMachines/pix4d-vm
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Success "Conexión establecida correctamente"
    } else {
        throw "Error en la conexión"
    }
} catch {
    Write-Host ""
    Write-Error-Message "ERROR en la conexión"
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "   1. La VM está apagada (enciéndela en el Portal Azure)"
    Write-Host "   2. El Bastion no está listo (espera 5-10 minutos después del despliegue)"
    Write-Host "   3. No tienes permisos RBAC (verifica 'Virtual Machine Administrator Login')"
    Write-Host "   4. Problema de red o firewall local"
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit 1
}

Write-Host ""
Read-Host "Presiona Enter para salir"
