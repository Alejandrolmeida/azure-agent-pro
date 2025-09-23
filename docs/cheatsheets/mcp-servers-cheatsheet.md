# MCP Servers Cheatsheet 🤖

Guía completa para trabajar con Model Context Protocol (MCP) Servers de Azure, GitHub y Azure DevOps.

## 📑 Índice

- [¿Qué es MCP?](#qué-es-mcp)
- [Configuración Inicial](#configuración-inicial)
- [MCP Server - Azure](#mcp-server---azure)
- [MCP Server - GitHub](#mcp-server---github)
- [MCP Server - Azure DevOps](#mcp-server---azure-devops)
- [Integración con VS Code](#integración-con-vs-code)
- [Configuración Avanzada](#configuración-avanzada)
- [Casos de Uso Comunes](#casos-de-uso-comunes)
- [Troubleshooting](#troubleshooting)
- [Mejores Prácticas](#mejores-prácticas)

---

## 🤔 ¿Qué es MCP?

**Model Context Protocol (MCP)** es un protocolo que permite a los modelos de IA acceder a recursos y herramientas externas de manera segura y estandarizada. Los MCP Servers actúan como puentes entre el modelo de IA y servicios específicos.

### Beneficios de MCP
- **Acceso seguro** a APIs y servicios externos
- **Contexto enriquecido** para modelos de IA
- **Integración nativa** con herramientas de desarrollo
- **Protocolo estandarizado** para comunicación

---

## ⚙️ Configuración Inicial

### Prerequisitos
```bash
# Node.js y npm
node --version  # v18+
npm --version

# Python (para algunos servidores)
python --version  # 3.8+
pip --version

# Git
git --version

# Azure CLI (para Azure MCP)
az --version

# GitHub CLI (para GitHub MCP)
gh --version
```

### Instalación Base de MCP
```bash
# Instalar MCP CLI
npm install -g @modelcontextprotocol/cli

# Verificar instalación
mcp --version

# Crear directorio para configuración MCP
mkdir -p ~/.config/mcp
cd ~/.config/mcp
```

---

## ☁️ MCP Server - Azure

### Instalación y Configuración

```bash
# Instalar Azure MCP Server
npm install -g @azure/mcp-server

# O usando el server oficial de Microsoft
git clone https://github.com/microsoft/mcp-server-azure.git
cd mcp-server-azure
npm install
npm run build
```

### Configuración de Credenciales Azure

```json
// ~/.config/mcp/azure-config.json
{
  "azure": {
    "tenantId": "your-tenant-id",
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret",
    "subscriptionId": "your-subscription-id"
  }
}
```

```bash
# Usando Azure CLI (recomendado)
az login
az account set --subscription "your-subscription-id"

# Crear service principal para MCP
az ad sp create-for-rbac \
  --name "mcp-azure-server" \
  --role "Contributor" \
  --scopes "/subscriptions/your-subscription-id"
```

### Configuración MCP Server Azure

```json
// mcp-server-azure.json
{
  "mcpVersion": "2024-11-05",
  "name": "azure-server",
  "version": "1.0.0",
  "server": {
    "command": "node",
    "args": ["/path/to/mcp-server-azure/dist/index.js"],
    "env": {
      "AZURE_TENANT_ID": "your-tenant-id",
      "AZURE_CLIENT_ID": "your-client-id",
      "AZURE_CLIENT_SECRET": "your-client-secret",
      "AZURE_SUBSCRIPTION_ID": "your-subscription-id"
    }
  },
  "capabilities": {
    "resources": true,
    "tools": true,
    "prompts": true
  }
}
```

### Capacidades del Azure MCP Server

#### Resources (Recursos)
```javascript
// Listar recursos Azure disponibles
{
  "method": "resources/list",
  "params": {}
}

// Obtener información específica de un recurso
{
  "method": "resources/read",
  "params": {
    "uri": "azure://subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}"
  }
}
```

#### Tools (Herramientas)
```javascript
// Crear recurso
{
  "method": "tools/call",
  "params": {
    "name": "azure_create_resource",
    "arguments": {
      "resourceType": "Microsoft.Storage/storageAccounts",
      "resourceGroup": "my-rg",
      "name": "mystorageaccount",
      "location": "eastus",
      "properties": {
        "sku": {"name": "Standard_LRS"},
        "kind": "StorageV2"
      }
    }
  }
}

// Ejecutar comando Azure CLI
{
  "method": "tools/call",
  "params": {
    "name": "azure_cli_execute",
    "arguments": {
      "command": "az vm list --resource-group my-rg --output json"
    }
  }
}

// Deploy Bicep template
{
  "method": "tools/call",
  "params": {
    "name": "azure_deploy_bicep",
    "arguments": {
      "templateFile": "/path/to/template.bicep",
      "parametersFile": "/path/to/parameters.json",
      "resourceGroup": "my-rg"
    }
  }
}
```

### Script de Configuración Azure MCP

```bash
#!/bin/bash
# setup-azure-mcp.sh

# Variables
MCP_DIR="$HOME/.config/mcp"
AZURE_MCP_DIR="$MCP_DIR/azure"

# Crear directorios
mkdir -p "$AZURE_MCP_DIR"

# Obtener información de Azure CLI
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Configurando Azure MCP Server..."
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"

# Crear service principal
echo "Creando service principal para MCP..."
SP_INFO=$(az ad sp create-for-rbac \
  --name "mcp-azure-server-$(date +%s)" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --output json)

CLIENT_ID=$(echo $SP_INFO | jq -r '.appId')
CLIENT_SECRET=$(echo $SP_INFO | jq -r '.password')

# Crear configuración
cat > "$AZURE_MCP_DIR/config.json" << EOF
{
  "tenantId": "$TENANT_ID",
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET",
  "subscriptionId": "$SUBSCRIPTION_ID"
}
EOF

echo "Azure MCP Server configurado correctamente!"
echo "Config guardada en: $AZURE_MCP_DIR/config.json"
```

---

## 🐱 MCP Server - GitHub

### Instalación y Configuración

```bash
# Instalar GitHub MCP Server
npm install -g @github/mcp-server

# O clonar desde source
git clone https://github.com/github/mcp-server-github.git
cd mcp-server-github
npm install
npm run build
```

### Configuración de Credenciales GitHub

```bash
# Usando GitHub CLI
gh auth login

# O crear Personal Access Token
# Settings > Developer settings > Personal access tokens > Tokens (classic)
# Scopes necesarios: repo, read:org, read:user, read:project
```

### Configuración MCP Server GitHub

```json
// mcp-server-github.json
{
  "mcpVersion": "2024-11-05",
  "name": "github-server",
  "version": "1.0.0",
  "server": {
    "command": "node",
    "args": ["/path/to/mcp-server-github/dist/index.js"],
    "env": {
      "GITHUB_TOKEN": "your-personal-access-token",
      "GITHUB_API_URL": "https://api.github.com"
    }
  },
  "capabilities": {
    "resources": true,
    "tools": true,
    "prompts": true
  }
}
```

### Capacidades del GitHub MCP Server

#### Resources (Recursos)
```javascript
// Listar repositorios
{
  "method": "resources/list",
  "params": {
    "uri": "github://repos"
  }
}

// Obtener contenido de archivo
{
  "method": "resources/read",
  "params": {
    "uri": "github://repos/owner/repo/contents/path/to/file.js"
  }
}

// Obtener información de issue
{
  "method": "resources/read",
  "params": {
    "uri": "github://repos/owner/repo/issues/123"
  }
}
```

#### Tools (Herramientas)
```javascript
// Crear issue
{
  "method": "tools/call",
  "params": {
    "name": "github_create_issue",
    "arguments": {
      "owner": "myusername",
      "repo": "myrepo",
      "title": "Bug report",
      "body": "Description of the bug...",
      "labels": ["bug", "high-priority"]
    }
  }
}

// Crear pull request
{
  "method": "tools/call",
  "params": {
    "name": "github_create_pull_request",
    "arguments": {
      "owner": "myusername",
      "repo": "myrepo",
      "title": "Feature: Add new functionality",
      "body": "This PR adds...",
      "head": "feature-branch",
      "base": "main"
    }
  }
}

// Buscar en código
{
  "method": "tools/call",
  "params": {
    "name": "github_search_code",
    "arguments": {
      "query": "function authenticate",
      "repo": "owner/repo"
    }
  }
}

// Crear archivo
{
  "method": "tools/call",
  "params": {
    "name": "github_create_file",
    "arguments": {
      "owner": "myusername",
      "repo": "myrepo",
      "path": "src/newfile.js",
      "content": "console.log('Hello World');",
      "message": "Add new file",
      "branch": "main"
    }
  }
}
```

### Script de Configuración GitHub MCP

```bash
#!/bin/bash
# setup-github-mcp.sh

MCP_DIR="$HOME/.config/mcp"
GITHUB_MCP_DIR="$MCP_DIR/github"

mkdir -p "$GITHUB_MCP_DIR"

# Verificar GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI no está instalado"
    echo "Instala con: curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    exit 1
fi

# Login si es necesario
if ! gh auth status &> /dev/null; then
    echo "Realizando login a GitHub..."
    gh auth login
fi

# Obtener token (para uso en MCP)
echo "Para configurar MCP Server, necesitas un Personal Access Token"
echo "Ve a: https://github.com/settings/tokens"
echo "Crea un token con permisos: repo, read:org, read:user, read:project"
read -p "Ingresa tu Personal Access Token: " GITHUB_TOKEN

# Crear configuración
cat > "$GITHUB_MCP_DIR/config.json" << EOF
{
  "token": "$GITHUB_TOKEN",
  "apiUrl": "https://api.github.com"
}
EOF

echo "GitHub MCP Server configurado correctamente!"
echo "Config guardada en: $GITHUB_MCP_DIR/config.json"
```

---

## 🔧 MCP Server - Azure DevOps

### Instalación y Configuración

```bash
# Instalar Azure DevOps MCP Server
npm install -g @azure/mcp-server-devops

# O desde source
git clone https://github.com/microsoft/mcp-server-azuredevops.git
cd mcp-server-azuredevops
npm install
npm run build
```

### Configuración de Credenciales Azure DevOps

```bash
# Instalar Azure DevOps CLI extension
az extension add --name azure-devops

# Login
az devops login

# O crear Personal Access Token
# https://dev.azure.com/{org}/_usersSettings/tokens
# Scopes: Build (read & execute), Code (read & write), Work Items (read & write)
```

### Configuración MCP Server Azure DevOps

```json
// mcp-server-azuredevops.json
{
  "mcpVersion": "2024-11-05",
  "name": "azuredevops-server",
  "version": "1.0.0",
  "server": {
    "command": "node",
    "args": ["/path/to/mcp-server-azuredevops/dist/index.js"],
    "env": {
      "AZURE_DEVOPS_ORG_URL": "https://dev.azure.com/your-org",
      "AZURE_DEVOPS_PAT": "your-personal-access-token"
    }
  },
  "capabilities": {
    "resources": true,
    "tools": true,
    "prompts": true
  }
}
```

### Capacidades del Azure DevOps MCP Server

#### Resources (Recursos)
```javascript
// Listar proyectos
{
  "method": "resources/list",
  "params": {
    "uri": "azuredevops://projects"
  }
}

// Obtener work items
{
  "method": "resources/read",
  "params": {
    "uri": "azuredevops://projects/myproject/workitems/123"
  }
}

// Listar builds
{
  "method": "resources/list",
  "params": {
    "uri": "azuredevops://projects/myproject/builds"
  }
}
```

#### Tools (Herramientas)
```javascript
// Crear work item
{
  "method": "tools/call",
  "params": {
    "name": "azuredevops_create_workitem",
    "arguments": {
      "project": "myproject",
      "type": "Bug",
      "title": "Fix authentication issue",
      "description": "User authentication fails in production",
      "assignedTo": "user@company.com",
      "priority": "High"
    }
  }
}

// Ejecutar build
{
  "method": "tools/call",
  "params": {
    "name": "azuredevops_queue_build",
    "arguments": {
      "project": "myproject",
      "definitionId": 123,
      "sourceBranch": "refs/heads/main"
    }
  }
}

// Crear pull request
{
  "method": "tools/call",
  "params": {
    "name": "azuredevops_create_pullrequest",
    "arguments": {
      "project": "myproject",
      "repository": "myrepo",
      "title": "Feature: Add new API endpoint",
      "description": "This PR adds a new API endpoint for user management",
      "sourceBranch": "feature/user-api",
      "targetBranch": "main",
      "reviewers": ["reviewer1@company.com"]
    }
  }
}

// Consultar work items con WIQL
{
  "method": "tools/call",
  "params": {
    "name": "azuredevops_query_workitems",
    "arguments": {
      "project": "myproject",
      "wiql": "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.AssignedTo] = @Me AND [System.State] = 'Active'"
    }
  }
}
```

### Script de Configuración Azure DevOps MCP

```bash
#!/bin/bash
# setup-azuredevops-mcp.sh

MCP_DIR="$HOME/.config/mcp"
AZDO_MCP_DIR="$MCP_DIR/azuredevops"

mkdir -p "$AZDO_MCP_DIR"

# Verificar Azure DevOps CLI
if ! az extension list | grep -q azure-devops; then
    echo "Instalando Azure DevOps CLI extension..."
    az extension add --name azure-devops
fi

echo "Para configurar Azure DevOps MCP Server necesitas:"
echo "1. URL de tu organización (ej: https://dev.azure.com/myorg)"
echo "2. Personal Access Token con permisos: Build, Code, Work Items"
echo ""

read -p "Ingresa la URL de tu organización: " ORG_URL
read -p "Ingresa tu Personal Access Token: " PAT

# Configurar Azure DevOps CLI defaults
az devops configure --defaults organization="$ORG_URL"

# Crear configuración
cat > "$AZDO_MCP_DIR/config.json" << EOF
{
  "organizationUrl": "$ORG_URL",
  "personalAccessToken": "$PAT"
}
EOF

echo "Azure DevOps MCP Server configurado correctamente!"
echo "Config guardada en: $AZDO_MCP_DIR/config.json"
```

---

## 💻 Integración con VS Code

### Configuración de VS Code MCP

```json
// settings.json en VS Code
{
  "mcp.servers": {
    "azure": {
      "command": "node",
      "args": ["/path/to/mcp-server-azure/dist/index.js"],
      "env": {
        "AZURE_TENANT_ID": "your-tenant-id",
        "AZURE_CLIENT_ID": "your-client-id",
        "AZURE_CLIENT_SECRET": "your-client-secret",
        "AZURE_SUBSCRIPTION_ID": "your-subscription-id"
      }
    },
    "github": {
      "command": "node",
      "args": ["/path/to/mcp-server-github/dist/index.js"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    },
    "azuredevops": {
      "command": "node",
      "args": ["/path/to/mcp-server-azuredevops/dist/index.js"],
      "env": {
        "AZURE_DEVOPS_ORG_URL": "https://dev.azure.com/your-org",
        "AZURE_DEVOPS_PAT": "your-pat"
      }
    }
  }
}
```

### Extensión MCP para VS Code

```bash
# Instalar extensión MCP
code --install-extension modelcontextprotocol.mcp-vscode

# O buscar "MCP" en el marketplace de VS Code
```

---

## 🔧 Configuración Avanzada

### Configuración Centralizada MCP

```json
// ~/.config/mcp/servers.json
{
  "mcpVersion": "2024-11-05",
  "servers": {
    "azure": {
      "command": "node",
      "args": ["/usr/local/lib/node_modules/@azure/mcp-server/dist/index.js"],
      "env": {
        "AZURE_CONFIG_FILE": "/home/user/.config/mcp/azure/config.json"
      }
    },
    "github": {
      "command": "node", 
      "args": ["/usr/local/lib/node_modules/@github/mcp-server/dist/index.js"],
      "env": {
        "GITHUB_CONFIG_FILE": "/home/user/.config/mcp/github/config.json"
      }
    },
    "azuredevops": {
      "command": "node",
      "args": ["/usr/local/lib/node_modules/@azure/mcp-server-devops/dist/index.js"],
      "env": {
        "AZDO_CONFIG_FILE": "/home/user/.config/mcp/azuredevops/config.json"
      }
    }
  }
}
```

### Variables de Entorno Seguras

```bash
# ~/.bashrc o ~/.zshrc
export MCP_CONFIG_DIR="$HOME/.config/mcp"
export MCP_AZURE_CONFIG="$MCP_CONFIG_DIR/azure/config.json"
export MCP_GITHUB_CONFIG="$MCP_CONFIG_DIR/github/config.json"
export MCP_AZDO_CONFIG="$MCP_CONFIG_DIR/azuredevops/config.json"

# Usar Azure Key Vault para secretos en producción
export AZURE_KEY_VAULT_URL="https://myvault.vault.azure.net/"
```

### Logging y Debugging

```json
// mcp-logging.json
{
  "logging": {
    "level": "info",
    "file": "/var/log/mcp/mcp-servers.log",
    "console": true,
    "structured": true
  },
  "debugging": {
    "enabled": true,
    "verboseRequests": false,
    "traceConnections": true
  }
}
```

---

## 🎯 Casos de Uso Comunes

### Desarrollo Automatizado

```javascript
// Workflow completo: GitHub → Azure DevOps → Azure Deploy
async function automatedDeployment() {
  // 1. Crear branch en GitHub
  await mcp.call("github_create_branch", {
    owner: "myorg",
    repo: "myapp",
    branch: "feature/new-api",
    from: "main"
  });
  
  // 2. Crear work item en Azure DevOps
  const workItem = await mcp.call("azuredevops_create_workitem", {
    project: "MyProject",
    type: "Feature",
    title: "Implement new API endpoint",
    description: "Add user management API"
  });
  
  // 3. Deploy infrastructure con Bicep
  await mcp.call("azure_deploy_bicep", {
    templateFile: "/templates/api-infrastructure.bicep",
    resourceGroup: "api-rg",
    parameters: {
      environment: "dev",
      apiName: "user-management"
    }
  });
  
  // 4. Crear pull request
  await mcp.call("github_create_pull_request", {
    owner: "myorg",
    repo: "myapp",
    title: "Feature: User Management API",
    body: `Implements user management API\n\nRelated work item: ${workItem.id}`,
    head: "feature/new-api",
    base: "main"
  });
}
```

### Monitoreo y Alertas

```javascript
// Monitoreo automático de recursos Azure
async function monitorAzureResources() {
  // Obtener recursos críticos
  const resources = await mcp.call("azure_list_resources", {
    resourceGroup: "production-rg",
    filter: "critical"
  });
  
  for (const resource of resources) {
    // Verificar estado de salud
    const health = await mcp.call("azure_get_resource_health", {
      resourceId: resource.id
    });
    
    if (health.status !== "Available") {
      // Crear issue en GitHub
      await mcp.call("github_create_issue", {
        owner: "ops-team",
        repo: "alerts",
        title: `Azure Resource Health Alert: ${resource.name}`,
        body: `Resource ${resource.name} is ${health.status}`,
        labels: ["alert", "azure", "critical"]
      });
      
      // Crear incident en Azure DevOps
      await mcp.call("azuredevops_create_workitem", {
        project: "Operations",
        type: "Bug",
        title: `Production Issue: ${resource.name}`,
        priority: "Critical",
        assignedTo: "ops-team@company.com"
      });
    }
  }
}
```

### CI/CD Integration

```javascript
// Integración completa CI/CD
async function cicdPipeline(changes) {
  // 1. Validar cambios en GitHub
  const validation = await mcp.call("github_validate_changes", {
    pullRequestId: changes.prId,
    checks: ["lint", "test", "security"]
  });
  
  if (validation.passed) {
    // 2. Trigger build en Azure DevOps
    const build = await mcp.call("azuredevops_queue_build", {
      project: "MyProject",
      definitionId: 123,
      sourceBranch: changes.branch
    });
    
    // 3. Si build exitoso, deploy a staging
    if (build.result === "succeeded") {
      await mcp.call("azure_deploy_bicep", {
        templateFile: "/templates/staging.bicep",
        resourceGroup: "staging-rg",
        parameters: {
          buildNumber: build.buildNumber,
          environment: "staging"
        }
      });
    }
  }
}
```

---

## 🐛 Troubleshooting

### Problemas Comunes

#### Error de Autenticación Azure
```bash
# Verificar Azure CLI login
az account show

# Re-autenticar si es necesario
az login --tenant your-tenant-id

# Verificar permisos del service principal
az role assignment list --assignee your-client-id
```

#### Error de Token GitHub
```bash
# Verificar token
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user

# Regenerar token si es necesario
# GitHub → Settings → Developer settings → Personal access tokens
```

#### Error de Conexión Azure DevOps
```bash
# Verificar configuración
az devops configure --list

# Test de conexión
az devops project list --organization https://dev.azure.com/your-org
```

### Debugging MCP Servers

```bash
# Ejecutar server en modo debug
NODE_ENV=development \
DEBUG=mcp:* \
node /path/to/mcp-server/dist/index.js

# Ver logs detallados
tail -f /var/log/mcp/mcp-servers.log

# Test de conectividad
mcp test-connection --server azure
mcp test-connection --server github
mcp test-connection --server azuredevops
```

### Validación de Configuración

```bash
#!/bin/bash
# validate-mcp-config.sh

echo "Validando configuración MCP..."

# Verificar archivos de configuración
for server in azure github azuredevops; do
    config_file="$HOME/.config/mcp/$server/config.json"
    if [[ -f "$config_file" ]]; then
        echo "✅ $server: config encontrado"
        # Validar JSON
        if jq empty "$config_file" 2>/dev/null; then
            echo "✅ $server: JSON válido"
        else
            echo "❌ $server: JSON inválido"
        fi
    else
        echo "❌ $server: config no encontrado"
    fi
done

# Test de conectividad
echo "Probando conectividad..."

# Azure
if az account show &>/dev/null; then
    echo "✅ Azure: autenticado"
else
    echo "❌ Azure: no autenticado"
fi

# GitHub
if gh auth status &>/dev/null; then
    echo "✅ GitHub: autenticado"
else
    echo "❌ GitHub: no autenticado"
fi

# Azure DevOps
if az devops project list &>/dev/null; then
    echo "✅ Azure DevOps: autenticado"
else
    echo "❌ Azure DevOps: no autenticado"
fi
```

---

## ✅ Mejores Prácticas

### Seguridad

```bash
# 1. Usar variables de entorno para secretos
export AZURE_CLIENT_SECRET="$(az keyvault secret show --vault-name myvault --name azure-client-secret --query value -o tsv)"

# 2. Rotar credenciales regularmente
# Script de rotación automática
#!/bin/bash
rotate_credentials() {
    # Rotar Azure Service Principal
    az ad sp credential reset --id your-sp-id
    
    # Rotar GitHub Token (manual)
    echo "Recuerda rotar GitHub Personal Access Token"
    
    # Rotar Azure DevOps PAT (manual)
    echo "Recuerda rotar Azure DevOps Personal Access Token"
}

# 3. Usar least privilege principle
# Solo dar permisos necesarios a cada service principal
```

### Performance

```json
// Configuración optimizada
{
  "connection": {
    "maxRetries": 3,
    "retryDelay": 1000,
    "timeout": 30000,
    "keepAlive": true
  },
  "caching": {
    "enabled": true,
    "ttl": 300,
    "maxSize": 100
  },
  "rateLimit": {
    "enabled": true,
    "maxRequests": 100,
    "windowMs": 60000
  }
}
```

### Monitoreo

```javascript
// Health check automático
async function healthCheck() {
  const servers = ['azure', 'github', 'azuredevops'];
  const results = {};
  
  for (const server of servers) {
    try {
      const start = Date.now();
      await mcp.call(`${server}_health_check`);
      results[server] = {
        status: 'healthy',
        responseTime: Date.now() - start
      };
    } catch (error) {
      results[server] = {
        status: 'unhealthy',
        error: error.message
      };
    }
  }
  
  return results;
}

// Ejecutar cada 5 minutos
setInterval(healthCheck, 5 * 60 * 1000);
```

---

## 📚 Recursos Adicionales

### Documentación Oficial
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Azure MCP Server](https://github.com/microsoft/mcp-server-azure)
- [GitHub MCP Server](https://github.com/github/mcp-server-github)
- [Azure DevOps MCP Server](https://github.com/microsoft/mcp-server-azuredevops)

### Herramientas Útiles
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector) - Debug tool
- [MCP CLI](https://github.com/modelcontextprotocol/cli) - Command line interface
- [VS Code MCP Extension](https://marketplace.visualstudio.com/items?itemName=modelcontextprotocol.mcp-vscode)

### Ejemplos y Templates
- [MCP Server Templates](https://github.com/modelcontextprotocol/templates)
- [Azure Bicep con MCP](https://github.com/Azure/bicep-mcp-examples)
- [GitHub Actions con MCP](https://github.com/actions/mcp-examples)

---

💡 **Tip**: Utiliza MCP Servers para crear workflows automatizados que conecten Azure, GitHub y Azure DevOps de manera seamless, mejorando la productividad y reduciendo errores manuales.