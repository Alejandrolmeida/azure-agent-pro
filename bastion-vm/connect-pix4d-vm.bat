@echo off
REM ====================================================================
REM  Conexión RDP a PIX4D VM via Azure Bastion
REM ====================================================================
REM
REM  Este script se conecta a la VM pix4d-vm en Azure usando Bastion
REM  
REM  REQUISITOS:
REM  - Azure CLI instalado (https://aka.ms/installazurecli)
REM  - Sesión activa en Azure (az login)
REM
REM  CREDENCIALES RDP:
REM  - Usuario: AzureAD\alejandro.almeida.garcia@gmail.com
REM  - Contraseña: Tu cuenta Microsoft
REM
REM ====================================================================

title Conectando a PIX4D VM via Bastion

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║         CONEXION RDP A PIX4D VM VIA AZURE BASTION             ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM Verificar que Azure CLI está instalado
where az >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ERROR: Azure CLI no está instalado
    echo.
    echo Descárgalo desde: https://aka.ms/installazurecli
    echo.
    pause
    exit /b 1
)

echo ✅ Azure CLI encontrado
echo.

REM Verificar sesión de Azure
echo 🔍 Verificando sesión de Azure...
az account show >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ No hay sesión activa en Azure
    echo.
    echo 🔐 Iniciando login...
    az login
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ Error en el login
        pause
        exit /b 1
    )
)

echo ✅ Sesión de Azure activa
echo.

REM Mostrar información de la VM
echo 📊 INFORMACIÓN DE LA VM:
echo    • Nombre: pix4d-vm
echo    • Resource Group: rg-pix4d-lab-northeurope
echo    • Región: North Europe
echo    • Tipo: Standard_NV4as_v4 (AMD GPU)
echo    • OS: Windows 11 Enterprise 23H2
echo.

REM Mostrar credenciales
echo 🔐 CREDENCIALES PARA LA VENTANA RDP:
echo    • Usuario: AzureAD\alejandro.almeida.garcia@gmail.com
echo    • Contraseña: [Tu cuenta Microsoft]
echo.

echo 🚀 Conectando via Bastion...
echo    (Esto abrirá una ventana RDP en unos segundos)
echo.

REM Ejecutar conexión Bastion
az network bastion rdp ^
  --name bastion-pix4d-lab ^
  --resource-group rg-pix4d-lab-northeurope ^
  --target-resource-id /subscriptions/fa69bf2d-3430-415f-bf70-70590e52fd98/resourceGroups/rg-pix4d-lab-northeurope/providers/Microsoft.Compute/virtualMachines/pix4d-vm

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ ERROR en la conexión
    echo.
    echo Posibles causas:
    echo    1. La VM está apagada (enciéndela en el Portal Azure)
    echo    2. El Bastion no está listo (espera 5-10 minutos)
    echo    3. No tienes permisos RBAC (verifica en Portal Azure)
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ Conexión establecida
echo.
pause
