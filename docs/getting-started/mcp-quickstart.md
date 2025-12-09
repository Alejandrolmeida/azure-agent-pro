# ⚡ Quick Start: Conectar GitHub Copilot con MCP Servers

## 🎯 Resumen Ejecutivo

Los **MCP (Model Context Protocol) Servers** permiten a GitHub Copilot acceder a:

- ✅ Tus recursos de Azure Networking en tiempo real
- ✅ Plantillas Bicep y Azure Resource Manager
- ✅ Análisis inteligente de configuraciones de red
- ✅ Búsqueda en documentación web de Azure
- ✅ Contexto persistente entre sesiones

**Tiempo estimado de setup:** 10-15 minutos

---

## 🚀 Setup Rápido (3 Pasos)

### Paso 1: Configurar Credenciales (5 min)

```bash
# 1. Copiar template
cp .env.example .env

# 2. Editar con tus credenciales
nano .env
```

**Mínimo requerido para empezar:**

```bash
# Azure (obtener de: az account show)
AZURE_SUBSCRIPTION_ID=<tu-subscription-id>
AZURE_TENANT_ID=<tu-tenant-id>

# GitHub (crear en: https://github.com/settings/tokens)
# Permisos: repo, read:user
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Paso 2: Instalar Dependencias (3 min)

```bash
# Opción A: Script automático
./scripts/setup/mcp-setup.sh

# Opción B: Manual (si falla el script)
# Verificar Node.js 20+
node --version
```

**Nota:** Los MCP servers de Node.js se instalan automáticamente con `npx` cuando los uses por primera vez.

### Paso 3: Activar en VS Code (2 min)

1. **Abrir este proyecto en VS Code**

   ```bash
   code .
   ```

2. **Recargar ventana**
   - Presiona `Ctrl+Shift+P`
   - Escribe: "Reload Window"
   - Enter

3. **Verificar conexión**
   - Abre GitHub Copilot Chat: `Ctrl+Shift+I`
   - Escribe: `@workspace ¿Qué MCP servers están activos?`
   - Deberías ver una lista de servidores

---

## ✅ Verificación

### Test 1: Filesystem MCP (no requiere credenciales)

```
Prompt en Copilot Chat:
@workspace Lista todos los archivos Bicep en el proyecto
```

**Respuesta esperada:** Lista de archivos .bicep con descripciones

### Test 2: Azure MCP (requiere Azure credentials)

```
Prompt en Copilot Chat:
@workspace Usando Azure MCP, lista las redes virtuales en mi suscripción
```

**Respuesta esperada:** Lista de VNETs disponibles

### Test 3: GitHub MCP (requiere GITHUB_TOKEN)

```
Prompt en Copilot Chat:
@workspace Busca issues relacionados con "NSG rules" en repositorios 
públicos de Azure networking
```

**Respuesta esperada:** Lista de issues relevantes

### Test 4: Brave Search MCP (opcional, requiere BRAVE_API_KEY)

```
Prompt en Copilot Chat:
@workspace Busca las mejores prácticas de diseño de hub-spoke en Azure
```

**Respuesta esperada:** Artículos y documentación oficial

---

## 🔧 Configuración de VS Code

El archivo `mcp.json` en la raíz del proyecto define 6 MCP servers:

| Server | Estado | Requiere | Capacidad Principal |
|--------|--------|----------|---------------------|
| 🔵 azure-mcp | ⚠️ Requiere config | Azure credentials | Acceso a recursos Azure |
| 📄 bicep-mcp | ✅ Listo | Ninguno | Asistencia con Bicep |
| 🐙 github-mcp | ⚠️ Requiere config | GitHub token | Búsqueda repos/issues |
| 📁 filesystem-mcp | ✅ Listo | Ninguno | Navegación proyecto |
| 🔍 brave-search-mcp | ⚙️ Opcional | Brave API key | Búsqueda web |
| 🧠 memory-mcp | ✅ Listo | Ninguno | Contexto persistente |

**Leyenda:**

- ✅ Listo = Funciona sin configuración
- ⚠️ Requiere config = Necesita variables en .env
- ⚙️ Opcional = Útil pero no esencial

---

## 💡 Ejemplos de Uso

### Ejemplo 1: Diseñar una Red Hub-Spoke

```
@workspace Usando el patrón hub-spoke, genera una plantilla Bicep para:
- 1 VNET hub (10.0.0.0/16)
- 2 VNET spokes (10.1.0.0/16, 10.2.0.0/16)
- Peering entre hub y spokes
- Azure Firewall en el hub
- Route tables para forzar tráfico por el firewall
```

### Ejemplo 2: Configurar NSG con Mejores Prácticas

```
@workspace Genera reglas NSG para una aplicación web de 3 capas:
- Web tier: permite HTTP/HTTPS desde Internet
- App tier: permite solo desde web tier
- DB tier: permite solo desde app tier
Aplica el principio de mínimo privilegio
```

### Ejemplo 3: Desplegar VPN Gateway

```
@workspace Crea una plantilla Bicep para VPN Gateway site-to-site con:
- VPN Gateway SKU VpnGw2
- Local Network Gateway para oficina local (IP: 203.0.113.1)
- Rango de red local: 192.168.0.0/16
- IPsec/IKE phase 1 y 2 según estándares
```

---

## 📚 Documentación Completa

Para setup avanzado, troubleshooting y casos de uso detallados, consulta:

📖 **[docs/MCP_SETUP_GUIDE.md](docs/MCP_SETUP_GUIDE.md)**

---

## 🆘 Problemas Comunes

### MCP Servers no aparecen en Copilot

**Solución:**

1. Verificar que `mcp.json` está en la raíz del proyecto
2. Recargar VS Code: `Ctrl+Shift+P` → "Reload Window"
3. Revisar Developer Console: `Help` → `Toggle Developer Tools` → `Console`

### Error: "AZURE_SUBSCRIPTION_ID not found"

**Solución:**

1. Verificar que `.env` existe (no `.env.example`)
2. Verificar que contiene `AZURE_SUBSCRIPTION_ID=...`
3. Recargar ventana de VS Code

### Node.js MCP servers no funcionan

**Solución:**

```bash
# Instalar Node.js 20+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar
node --version  # debe ser v20+
npx --version
```

---

## 🎓 Próximo Paso

Una vez verificado que los MCP servers funcionan:

➡️ **[Workshop: Networking en Azure con GitHub Copilot](docs/workshop/README.md)**

Aprende a:

- Usar MCP servers para networking profesional
- Diseñar arquitecturas hub-spoke
- Implementar seguridad con NSG y Azure Firewall
- Configurar conectividad híbrida con VPN/ExpressRoute
- Implementar monitorización con Network Watcher

---

## 📞 Soporte

- 📖 Documentación: [docs/MCP_SETUP_GUIDE.md](docs/MCP_SETUP_GUIDE.md)
- 🐛 Issues: [GitHub Issues](https://github.com/Alejandrolmeida/azure-agent-pro/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/Alejandrolmeida/azure-agent-pro/discussions)

---

**🎉 ¡Disfruta de GitHub Copilot supercargado con MCP Servers!**
