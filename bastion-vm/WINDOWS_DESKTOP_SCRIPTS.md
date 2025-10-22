# 🖥️ Scripts de Conexión para Windows Desktop

Este directorio contiene scripts para conectar a la VM PIX4D desde tu escritorio Windows.

---

## 📦 Archivos Disponibles

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `connect-pix4d-vm.bat` | Batch Script | Script simple para CMD |
| `connect-pix4d-vm.ps1` | PowerShell | Script avanzado con verificaciones |

---

## 🚀 Opción 1: Script BAT (Más Simple)

### Instalación en Escritorio Windows

1. **Copia el archivo** `connect-pix4d-vm.bat` a tu escritorio Windows:
   
   ```
   Desde Linux WSL/Git Bash:
   cp connect-pix4d-vm.bat /mnt/c/Users/TU_USUARIO/Desktop/
   
   O desde Windows:
   - Abre este directorio en el Explorador
   - Copia "connect-pix4d-vm.bat" al Escritorio
   ```

2. **Ejecuta con doble clic** en el archivo `.bat`

3. **Credenciales RDP:**
   - Usuario: `AzureAD\alejandro.almeida.garcia@gmail.com`
   - Contraseña: Tu cuenta Microsoft

### Crear Acceso Directo Personalizado

1. Clic derecho en el Escritorio → **Nuevo** → **Acceso directo**

2. En "Ubicación del elemento", pega:
   ```
   C:\Windows\System32\cmd.exe /c "C:\Users\TU_USUARIO\Desktop\connect-pix4d-vm.bat"
   ```
   *(Reemplaza TU_USUARIO con tu nombre de usuario Windows)*

3. Nombre: `PIX4D VM`

4. **Personalizar icono:**
   - Clic derecho en el acceso directo → Propiedades
   - Cambiar icono → Buscar icono de computadora o descargar uno

---

## 🚀 Opción 2: Script PowerShell (Más Completo)

### Instalación

1. **Copia el archivo** `connect-pix4d-vm.ps1` a tu escritorio:
   ```
   cp connect-pix4d-vm.ps1 /mnt/c/Users/TU_USUARIO/Desktop/
   ```

2. **Primera vez:** Habilitar ejecución de scripts PowerShell:
   ```powershell
   # Ejecuta PowerShell como Administrador
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Ejecutar:**
   ```powershell
   # Clic derecho en el archivo → "Run with PowerShell"
   # O desde PowerShell:
   .\connect-pix4d-vm.ps1
   ```

### Ventajas del Script PowerShell

- ✅ **Verificación de estado de VM** (encendida/apagada)
- ✅ **Opción de encender VM** automáticamente si está apagada
- ✅ **Mensajes con colores** y mejor UX
- ✅ **Verificación de Azure CLI** instalado
- ✅ **Verificación de sesión Azure** activa
- ✅ **Mejor manejo de errores**

---

## 📋 Requisitos Previos

### 1. Instalar Azure CLI en Windows

**Descargar:**
- 🔗 https://aka.ms/installazurecli

**Verificar instalación:**
```cmd
az version
```

### 2. Login en Azure

**Primera vez:**
```cmd
az login
```

Esto abrirá un navegador para autenticarte con tu cuenta Microsoft.

**Verificar sesión:**
```cmd
az account show
```

### 3. Permisos RBAC (Ya configurados)

✅ Ya tienes asignado el rol `Virtual Machine Administrator Login`

---

## 🔐 Credenciales de Conexión

Cuando se abra la ventana RDP, introduce:

| Campo | Valor |
|-------|-------|
| **Usuario** | `AzureAD\alejandro.almeida.garcia@gmail.com` |
| **Contraseña** | Tu contraseña de cuenta Microsoft |

**Importante:**
- El prefijo `AzureAD\` es **obligatorio**
- Es tu cuenta Microsoft personal (no contraseña local)
- Si tienes MFA, sigue el proceso de verificación

---

## 🛠️ Troubleshooting

### Error: "Azure CLI no encontrado"

**Solución:**
1. Instala Azure CLI: https://aka.ms/installazurecli
2. Reinicia la terminal/PowerShell
3. Verifica: `az version`

---

### Error: "No hay sesión activa"

**Solución:**
```cmd
az login
```

---

### Error: "VM no encontrada" o "No tienes permisos"

**Verificar rol RBAC:**
```bash
az role assignment list --scope /subscriptions/fa69bf2d-3430-415f-bf70-70590e52fd98/resourceGroups/rg-pix4d-lab-northeurope/providers/Microsoft.Compute/virtualMachines/pix4d-vm
```

Debe aparecer: `Virtual Machine Administrator Login`

---

### Error: "La VM está apagada"

**Opción 1: Portal Azure**
- Ve a https://portal.azure.com
- Busca VM `pix4d-vm`
- Click en **Start**

**Opción 2: Azure CLI**
```cmd
az vm start -g rg-pix4d-lab-northeurope -n pix4d-vm
```

**Opción 3: Script PowerShell**
- El script `connect-pix4d-vm.ps1` detecta esto y te pregunta si quieres encenderla

---

### Error: Login RDP falla

**Verificar formato de usuario:**
- ✅ Correcto: `AzureAD\alejandro.almeida.garcia@gmail.com`
- ❌ Incorrecto: `alejandro.almeida.garcia@gmail.com`
- ❌ Incorrecto: `AZUREAD\alejandro.almeida.garcia@gmail.com` (mayúsculas)

**Otros pasos:**
1. Verifica que la extensión AADLoginForWindows está instalada:
   ```bash
   az vm extension show -g rg-pix4d-lab-northeurope --vm-name pix4d-vm -n AADLoginForWindows
   ```

2. Espera 10 minutos después de la asignación de roles RBAC

---

## 🎨 Personalizar Acceso Directo

### Descargar Icono Personalizado

**Opción 1: Usar icono de Windows**
- En propiedades del acceso directo → Cambiar icono
- Buscar en: `C:\Windows\System32\imageres.dll`
- Selecciona icono de computadora/servidor

**Opción 2: Descargar icono personalizado**
- Busca "computer icon" o "server icon" en Google Images
- Descarga archivo `.ico`
- Guarda en: `C:\Users\TU_USUARIO\Desktop\pix4d-vm.ico`
- Propiedades → Cambiar icono → Examinar → Selecciona tu `.ico`

**Opción 3: Crear icono con logo PIX4D**
- Descarga logo PIX4D
- Usa herramienta online: https://convertico.com/
- Convierte a `.ico`

---

## 🚀 Uso Rápido

### Una vez configurado:

1. **Doble clic** en el icono del escritorio
2. Espera que se abra la ventana RDP (5-15 segundos)
3. Introduce credenciales:
   - Usuario: `AzureAD\alejandro.almeida.garcia@gmail.com`
   - Contraseña: [Tu cuenta Microsoft]
4. ✅ ¡Conectado a Windows 11 con GPU AMD!

---

## 📊 Información de la VM

| Característica | Valor |
|----------------|-------|
| **Nombre** | pix4d-vm |
| **Región** | North Europe |
| **Tipo** | Standard_NV4as_v4 |
| **GPU** | AMD Radeon Instinct MI25 (8GB VRAM) |
| **vCPUs** | 4 |
| **RAM** | 14GB |
| **OS** | Windows 11 Enterprise 23H2 |
| **Disco OS** | 128GB Premium SSD |
| **Disco Datos** | 256GB Premium SSD |

---

## 💰 Gestión de Costos

**Apagar VM cuando no la uses:**

```cmd
# Apagar (deallocate - NO cobra por compute)
az vm deallocate -g rg-pix4d-lab-northeurope -n pix4d-vm

# Encender
az vm start -g rg-pix4d-lab-northeurope -n pix4d-vm
```

**Costo aproximado:**
- Encendida: ~€0.60/hora
- Apagada (deallocate): ~€0.05/hora (solo discos)

💡 **Ahorro:** Apagar 16 horas/día = ~€10/día ahorrados

---

## 📚 Referencias

- [Azure Bastion Documentation](https://docs.microsoft.com/en-us/azure/bastion/)
- [Azure AD Join for VMs](https://docs.microsoft.com/en-us/azure/active-directory/devices/howto-vm-sign-in-azure-ad-windows)
- [NVv4 Series (AMD GPU)](https://docs.microsoft.com/en-us/azure/virtual-machines/nvv4-series)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)

---

**🎉 ¡Disfruta de tu VM PIX4D con GPU AMD!**
