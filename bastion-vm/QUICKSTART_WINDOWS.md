# 🚀 Conexión Rápida desde Windows

## ⚡ SOLUCIÓN RÁPIDA - Sin problemas de PowerShell

### Opción 1: Script BAT (RECOMENDADO - Sin restricciones)

**1. Descarga el archivo:**
- Abre el Explorador de Windows
- Navega a: `\\wsl$\Ubuntu\home\alejandrolmeida\source\github\alejandrolmeida\azure-agent-pro\bastion-vm\`
- Copia `connect-pix4d-vm.bat` a tu Escritorio

**2. Doble clic en `connect-pix4d-vm.bat`**

**3. Credenciales:**
```
Usuario: AzureAD\alejandro.almeida.garcia@gmail.com
Contraseña: [Tu cuenta Microsoft]
```

---

### Opción 2: Comando Directo (Más Simple)

Abre **CMD** (Command Prompt) y ejecuta:

```cmd
az network bastion rdp --name bastion-pix4d-lab --resource-group rg-pix4d-lab-northeurope --target-resource-id /subscriptions/fa69bf2d-3430-415f-bf70-70590e52fd98/resourceGroups/rg-pix4d-lab-northeurope/providers/Microsoft.Compute/virtualMachines/pix4d-vm
```

---

### Opción 3: PowerShell (Requiere permisos)

**Error actual:** El script no está firmado digitalmente.

**Solución A - Ejecutar sin cambiar políticas:**

Abre PowerShell normal (NO como administrador) y ejecuta:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\aleja\source\connect-pix4d-vm.ps1"
```

**Solución B - Cambiar política (una sola vez):**

Abre PowerShell **como Administrador** y ejecuta:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Luego cierra y abre PowerShell normal:

```powershell
.\connect-pix4d-vm.ps1
```

---

## 🎯 Recomendación: USA EL SCRIPT .BAT

El archivo `.bat` no tiene restricciones de seguridad y funciona siempre.

**Pasos finales:**

1. Copia `connect-pix4d-vm.bat` al Escritorio
2. Doble clic
3. Introduce credenciales en la ventana RDP
4. ✅ ¡Listo!

---

## 🔐 Credenciales de Login

```
Usuario: AzureAD\alejandro.almeida.garcia@gmail.com
Contraseña: [Tu contraseña de cuenta Microsoft]
```

**IMPORTANTE:** El prefijo `AzureAD\` es obligatorio.

---

## 💡 Si el script BAT tampoco funciona

Verifica que Azure CLI esté instalado:

```cmd
az version
```

Si no está instalado:
- Descarga: https://aka.ms/installazurecli
- Instala
- Reinicia CMD/PowerShell
- Vuelve a intentar

---

## �� Verificar Estado de la VM

```cmd
# Ver si está encendida
az vm get-instance-view -g rg-pix4d-lab-northeurope -n pix4d-vm --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv

# Encender si está apagada
az vm start -g rg-pix4d-lab-northeurope -n pix4d-vm

# Apagar cuando termines (para ahorrar costos)
az vm deallocate -g rg-pix4d-lab-northeurope -n pix4d-vm
```

---

**🎉 ¡Disfruta tu VM Windows 11 con GPU AMD!**
