# ✅ Despliegue Bastion VM - COMPLETADO

**Fecha:** 2025-10-22 00:22:03 UTC  
**Duración:** 8 minutos 37 segundos  
**Estado:** ✅ Succeeded

---

## 📦 Recursos Desplegados

| Tipo | Nombre | Estado |
|------|--------|--------|
| Resource Group | rg-pix4d-lab-northeurope | ✅ |
| Virtual Network | vnet-pix4d-lab (10.0.0.0/16) | ✅ |
| VM Subnet | snet-vm (10.0.1.0/24) | ✅ |
| Bastion Subnet | AzureBastionSubnet (10.0.255.0/26) | ✅ |
| Network Security Group | vnet-pix4d-lab-nsg | ✅ |
| Virtual Machine | pix4d-vm | ✅ |
| VM Size | **Standard_NV4as_v4** (AMD Radeon Instinct MI25) | ✅ |
| VM OS | Windows 11 Enterprise 23H2 | ✅ |
| VM Identity | System Assigned (Azure AD Join) | ✅ |
| Network Interface | pix4d-vm-nic | ✅ |
| Azure Bastion | bastion-pix4d-lab (Standard SKU) | ✅ |
| Bastion Public IP | bastion-pix4d-lab-pip | ✅ |
| AAD Extension | AADLoginForWindows | ✅ |

---

## 🔐 CONFIGURACIÓN SEGURA - PRÓXIMOS PASOS

### Paso 1: Crear Configuración Segura

```bash
cd /home/alejandrolmeida/source/github/alejandrolmeida/azure-agent-pro/bastion-vm
./setup-config.sh
```

**El script te pedirá:**
- ✉️ Email de Azure AD: `alejandro.almeida.garcia@gmail.com`
- 🔑 Contraseña del administrador de la VM (la que quieras usar)
- 🌍 Región: `northeurope` (ya desplegado aquí)
- 💻 VM SKU: `Standard_NV4as_v4` (ya desplegado)

**⚠️ IMPORTANTE:** Este script creará `config/user-config.sh` con permisos `600` y está protegido por `.gitignore`.

---

### Paso 2: Asignar Permisos RBAC

```bash
./grant-vm-access.sh
```

Este script asignará el rol **"Virtual Machine Administrator Login"** a tu usuario para que puedas hacer login con Azure AD.

---

### Paso 3: Conectar por RDP

#### Opción A: Azure CLI (Recomendado)

```bash
az network bastion rdp \
  --name bastion-pix4d-lab \
  --resource-group rg-pix4d-lab-northeurope \
  --target-resource-id /subscriptions/fa69bf2d-3430-415f-bf70-70590e52fd98/resourceGroups/rg-pix4d-lab-northeurope/providers/Microsoft.Compute/virtualMachines/pix4d-vm
```

**Credenciales:**
- Usuario: `AzureAD\alejandro.almeida.garcia@gmail.com`
- Contraseña: (tu cuenta Microsoft)

#### Opción B: Portal Azure

1. Ve a: https://portal.azure.com/#@/resource/subscriptions/fa69bf2d-3430-415f-bf70-70590e52fd98/resourceGroups/rg-pix4d-lab-northeurope/providers/Microsoft.Compute/virtualMachines/pix4d-vm/overview
2. Click en **"Connect"** → **"Connect via Bastion"**
3. Introduce las credenciales de Azure AD

---

## 🎮 Características de la VM

### Hardware (Standard_NV4as_v4)
- **GPU:** AMD Radeon Instinct MI25 (8GB VRAM)
- **vCPUs:** 4
- **RAM:** 14GB
- **Disco OS:** Premium SSD P10 (128GB)
- **Disco Datos:** Premium SSD P15 (256GB)

### Software
- **SO:** Windows 11 Enterprise 23H2
- **Autenticación:** Azure AD Join
- **Extensiones:** AADLoginForWindows

### Networking
- **IP Privada:** 10.0.1.x (dinámica)
- **Acceso:** Solo via Azure Bastion (sin IP pública en VM)
- **Bastion SKU:** Standard (soporte para cliente RDP nativo)
- **Bastion Features:** 
  - ✅ Native Client Support (enableTunneling)
  - ✅ File Copy/Paste (enableFileCopy)

---

## 🛡️ Seguridad Implementada

### ✅ En el Repositorio
- ❌ **CERO datos personales** en archivos commiteados
- ❌ **CERO contraseñas** en archivos commiteados
- ✅ Patrón de configuración segura con `config/user-config.sh` en `.gitignore`
- ✅ Template público: `config/user-config.sh.template` (sin datos reales)
- ✅ Scripts de configuración interactiva con validaciones
- ✅ Permisos `600` en archivos de configuración

### ✅ En Azure
- ✅ VM sin IP pública (acceso solo via Bastion)
- ✅ NSG sin reglas de entrada directas
- ✅ Azure AD Join (autenticación centralizada)
- ✅ System Assigned Identity para RBAC
- ✅ Premium SSD con encriptación por defecto
- ✅ Bastion con TLS 1.2 obligatorio

---

## 📝 Verificación del Despliegue

```bash
# Estado de los recursos
az resource list -g rg-pix4d-lab-northeurope -o table

# Detalles de la VM
az vm show -g rg-pix4d-lab-northeurope -n pix4d-vm

# Estado del Bastion
az network bastion show -g rg-pix4d-lab-northeurope -n bastion-pix4d-lab

# Verificar extensión AAD
az vm extension list -g rg-pix4d-lab-northeurope --vm-name pix4d-vm -o table
```

---

## 🎯 Para PIX4D

Una vez conectado a la VM:

1. **Verificar GPU:**
   ```powershell
   Get-WmiObject Win32_VideoController | Select-Object Name, AdapterRAM
   ```

2. **Instalar PIX4D:**
   - Descargar instalador desde: https://www.pix4d.com/
   - Verificar que detecta la GPU AMD

3. **Drivers AMD:**
   - Pueden requerir instalación manual desde AMD
   - Consultar: https://docs.microsoft.com/en-us/azure/virtual-machines/nv-series

---

## 🔧 Troubleshooting

### No puedo conectar por Bastion
1. Verifica que has ejecutado `./grant-vm-access.sh`
2. Espera 5-10 minutos para propagación de RBAC
3. Verifica en Portal: VM → Identity → Azure role assignments

### Login con Azure AD falla
1. Usuario correcto: `AzureAD\alejandro.almeida.garcia@gmail.com`
2. Contraseña: la de tu cuenta Microsoft
3. Verifica extensión AADLoginForWindows: debe estar "Succeeded"

### GPU no detectada
1. Instalar drivers AMD para NVv4 series
2. Ver: https://learn.microsoft.com/en-us/azure/virtual-machines/windows/n-series-amd-driver-setup

---

## 📊 Costos Estimados

**Standard_NV4as_v4 (North Europe):**
- ~€0.60/hora (precio aproximado, verificar pricing actual)
- ~€14.40/día si se deja encendida 24/7
- **💡 RECOMENDACIÓN:** Apagar cuando no esté en uso

```bash
# Apagar VM
az vm deallocate -g rg-pix4d-lab-northeurope -n pix4d-vm

# Encender VM
az vm start -g rg-pix4d-lab-northeurope -n pix4d-vm
```

---

## 📚 Documentación de Referencia

- [Azure Bastion](https://docs.microsoft.com/en-us/azure/bastion/)
- [NVv4 Series (AMD GPU)](https://docs.microsoft.com/en-us/azure/virtual-machines/nvv4-series)
- [Azure AD Join for VMs](https://docs.microsoft.com/en-us/azure/active-directory/devices/howto-vm-sign-in-azure-ad-windows)
- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

---

**🎉 ¡Listo para usar! Ejecuta los pasos 1 y 2 para configurar el acceso.**
