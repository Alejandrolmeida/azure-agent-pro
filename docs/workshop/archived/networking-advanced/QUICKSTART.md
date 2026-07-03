# Inicio Rápido - Workshop Azure Networking

**Tiempo estimado:** 15 minutos

---

## Setup Express (15 minutos)

### 1️⃣ Clonar y Configurar (5 min)

```bash
# Clonar repositorio
git clone https://github.com/alejandrolmeida/azure-agent-pro.git
cd azure-agent-pro

# Ejecutar setup automático
./scripts/setup/initial-setup.sh
```

El script te pedirá:
- Azure Subscription ID
- Azure Tenant ID
- GitHub Token (opcional)
- Brave API Key (opcional)

### 2️⃣ Configurar MCP Servers (5 min)

```bash
# Instalar y configurar MCP servers
./scripts/setup/mcp-setup.sh

# Reiniciar VS Code
code .
# Luego: Ctrl+Shift+P → "Developer: Reload Window"
```

### 3️⃣ Verificar MCP Servers (3 min)

1. Abre VS Code en la raíz del proyecto
2. Reinicia VS Code completamente (importante!)
3. Presiona `Ctrl+Shift+I` (Copilot Chat)
4. Pregunta: `@workspace ¿Qué servidores MCP tienes disponibles?`

**Deberías ver:** 6 servidores MCP listados

### 4️⃣ Test Rápido (2 min)

Prueba que todo funciona:

```text
@workspace Usando Azure MCP, lista las redes virtuales en mi suscripción
```

Si ves VNETs listadas (o mensaje de que no hay ninguna): **¡Estás listo! **

---

## Verificación Pre-Workshop

Marca estos items:

- [ ] Copilot responde con 6 servidores MCP
- [ ] Azure CLI autenticado (`az account show`)
- [ ] Archivo `.env` existe con credenciales
- [ ] Puedes ejecutar comandos de Azure CLI
- [ ] Git configurado con tu email/nombre

---

## Herramientas Necesarias

### Verificar Instalaciones

```bash
# Azure CLI
az --version

# Git
git --version

# Node.js (debe ser 20+)
node --version

# VS Code
code --version
```

### Instalar Faltantes

**Azure CLI:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Node.js 20:**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Git:**
```bash
sudo apt-get update
sudo apt-get install git
```

---

## 🐛 Troubleshooting Express

### Problema: "MCP servers no aparecen"

```bash
# Solución rápida
./scripts/setup/mcp-setup.sh
# Luego: Reiniciar VS Code COMPLETAMENTE
```

### Problema: "Azure authentication failed"

```bash
# Re-autenticar
az login
az account set --subscription "<nombre-o-id-de-suscripción>"
```

### Problema: "No tengo permisos en Azure"

Necesitas rol **Contributor** o **Network Contributor** mínimo.

Pide a tu administrador:
```bash
az role assignment create \
 --assignee <tu-email> \
 --role Contributor \
 --scope /subscriptions/<subscription-id>
```

### Problema: "GitHub Copilot no responde"

1. Verifica licencia activa: https://github.com/settings/copilot
2. Reinstala extensión en VS Code
3. Cierra sesión y vuelve a iniciar en VS Code

---

## Recursos Rápidos

- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Networking Docs](https://learn.microsoft.com/azure/networking/)

---

## Checklist Final

Antes de empezar el workshop, confirma:

- [ ] Azure CLI funciona y estás autenticado
- [ ] GitHub Copilot responde en VS Code
- [ ] MCP servers cargados (6 servidores)
- [ ] Puedes crear recursos en Azure (permisos OK)
- [ ] Tienes cuota disponible para VNETs y VPN Gateway

---

**¿Todo listo? ➡️ [Comienza el Workshop](WORKSHOP_NETWORKING.md)**

