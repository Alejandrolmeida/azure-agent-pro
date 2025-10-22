# Simple Bastion VM for PIX4D

**Solución simple y funcional** - Una VM Windows 11 con GPU AMD y acceso seguro via Azure Bastion.

## 🎯 Arquitectura

- ✅ **1 VM Windows 11 Enterprise** (Standard_NV4as_v4)
- ✅ **AMD Radeon Instinct MI25 GPU** (4 vCPUs, 14GB RAM, 8GB VRAM)
- ✅ **Azure Bastion Standard** (acceso RDP seguro)
- ✅ **Azure AD Join** (login con cuenta Microsoft)
- ✅ **VNet simple** (10.0.0.0/16)
- ❌ **NO AVD** (sin complejidad innecesaria)

## 🔐 Configuración Segura

Esta solución usa **archivos de configuración protegidos** que NO se commitean a Git:

```
bastion-vm/
├── config/
│   ├── user-config.sh.template  ← Template (público, sin datos)
│   └── user-config.sh           ← TU configuración (en .gitignore)
```

## 🚀 Despliegue

### Paso 1: Crear configuración (PRIMERA VEZ)

```bash
cd bastion-vm
chmod +x setup-config.sh deploy.sh grant-vm-access.sh
./setup-config.sh
```

Te pedirá:
- Tu email de Azure AD
- Contraseña para el usuario local de la VM
- Región, VM SKU, etc.

**Esto crea `config/user-config.sh` que está protegido por .gitignore**

### Paso 2: Desplegar infraestructura

```bash
./deploy.sh
```

Lee tu configuración de `config/user-config.sh` (segura, no se sube a Git).

**Tiempo:** 10-15 minutos

### Paso 3: Asignar permisos de acceso

```bash
./grant-vm-access.sh
```

Esto te asigna el role **"Virtual Machine Administrator Login"**.

### Paso 4: Conectar via Bastion

**Opción A: Desde Azure Portal**

1. Ve a la VM en Azure Portal
2. Click en "Connect" → "Bastion"
3. Login: `AzureAD\tu-email@domain.com`
4. Password: Tu contraseña de cuenta Microsoft

**Opción B: Desde Windows (RDP Cliente Nativo)** ⭐ **RECOMENDADO**

```bash
az network bastion rdp \
  --name bastion-pix4d-lab \
  --resource-group rg-pix4d-lab-northeurope \
  --target-resource-id $(az vm show -g rg-pix4d-lab-northeurope -n pix4d-vm --query id -o tsv)
```

Se abrirá el cliente RDP de Windows automáticamente.

## 🔐 Seguridad

### Protección de Credenciales

✅ **Archivo de configuración protegido:**
- `config/user-config.sh` está en `.gitignore`
- Permisos 600 (solo owner puede leer/escribir)
- NUNCA se commitea a Git

✅ **NO hay datos sensibles en el código:**
- Scripts públicos usan variables de entorno
- Template solo tiene placeholders
- README sin emails ni contraseñas

### Protección de Red

✅ **NO hay IP pública** en la VM
✅ **NO hay puerto RDP abierto** en NSG
✅ **TODO el tráfico RDP** va via Bastion (SSL/443)
✅ **Autenticación Azure AD** (MFA supported)

## 📊 Recursos Desplegados

| Recurso | Nombre | Propósito |
|---------|--------|-----------|
| Resource Group | `rg-pix4d-lab-northeurope` | Contiene todos los recursos |
| VM | `pix4d-vm` | Windows 11 con GPU AMD |
| Bastion | `bastion-pix4d-lab` | Acceso RDP seguro |
| VNet | `vnet-pix4d-lab` | Red virtual |
| NSG | `vnet-pix4d-lab-nsg` | Sin reglas (Bastion maneja todo) |

## 🗑️ Limpieza

Para eliminar todo:

```bash
az group delete --name rg-pix4d-lab-northeurope --yes --no-wait
```

## 📝 Archivos

- `setup-config.sh` - Crea tu configuración segura (primera vez)
- `deploy.sh` - Despliega infraestructura
- `grant-vm-access.sh` - Asigna permisos RBAC
- `config/user-config.sh.template` - Template de configuración
- `config/user-config.sh` - **TU configuración (en .gitignore, NO se commitea)**

## ❓ Troubleshooting

### "Configuration file not found"

```bash
./setup-config.sh
```

### No puedo conectarme

1. Verifica que tienes el role asignado:

   ```bash
   az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --scope $(az vm show -g rg-pix4d-lab-northeurope -n pix4d-vm --query id -o tsv)
   ```

2. Verifica que el Bastion está funcionando:

   ```bash
   az network bastion show -g rg-pix4d-lab-northeurope -n bastion-pix4d-lab
   ```

---

**Esta solución es SIMPLE, SEGURA y FUNCIONA.** ✅
