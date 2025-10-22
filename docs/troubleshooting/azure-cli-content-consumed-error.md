# Azure CLI Error: "The content for this response was already consumed"

## 📋 Overview

Error común que ocurre durante operaciones de deployment con Azure CLI, especialmente con `az deployment sub create` y otros comandos de larga duración.

```
ERROR: The content for this response was already consumed
```

## 🔍 Root Cause Analysis

### Technical Explanation

Este error se origina en la capa HTTP del Azure Python SDK que Azure CLI utiliza internamente:

1. **HTTP Response Streams**:
   - Azure SDK (basado en `requests`/`httpx`) retorna respuestas HTTP como streams
   - Los streams solo pueden leerse **una vez**
   - Después de `.json()`, `.text()`, o `.read()`, el stream queda "consumido"

2. **Azure CLI Response Caching Bug**:
   - Azure CLI mantiene respuestas HTTP en caché durante la sesión
   - En operaciones largas (deployments), puede haber timeouts o reintentos
   - El CLI intenta parsear la misma respuesta múltiples veces:
     - **Primera lectura**: Validación de respuesta
     - **Segunda lectura**: Formateo de output ❌ **FALLA AQUÍ**

3. **Específico de Deployments**:
   - Más común en `az deployment sub create`, `az deployment group create`
   - Ocurre cuando el deployment toma mucho tiempo (>5 min)
   - El CLI mantiene la conexión HTTP abierta y puede intentar releer la respuesta

### Code Path (Simplified)

```python
# Azure CLI internal flow (pseudocode)
response = http_client.put(deployment_url, data=template)

# Primera lectura - OK
validation_result = response.json()  # Stream consumido aquí

# Segunda lectura - ERROR
output_result = response.json()  # ❌ Stream ya fue consumido
# ERROR: The content for this response was already consumed
```

## ✅ Solutions

### Option 1: Use `--no-wait` Flag (RECOMMENDED)

Evita que el CLI espere y parsee la respuesta:

```bash
az deployment sub create \
  --name "my-deployment" \
  --location "spaincentral" \
  --template-file main.bicep \
  --parameters @params.json \
  --no-wait  # ← Evita el bug
```

Luego monitorea por separado:

```bash
# Check status
az deployment sub show --name "my-deployment"

# Watch progress
watch -n 30 'az deployment sub show --name "my-deployment" --query properties.provisioningState'
```

### Option 2: Redirect Output to File

Captura el output antes del segundo parsing:

```bash
az deployment sub create \
  --name "my-deployment" \
  --location "spaincentral" \
  --template-file main.bicep \
  --parameters @params.json \
  --output json > /tmp/deployment.json 2>&1

# Check result
cat /tmp/deployment.json | jq '.properties.provisioningState'
```

### Option 3: Fresh Session

Limpia el caché de respuestas HTTP:

```bash
# Logout and login again
az logout
az login

# Try deployment again
az deployment sub create ...
```

### Option 4: Update Azure CLI

Puede tener fix en versión más reciente:

```bash
# Check current version
az version

# Update to latest
az upgrade

# Or specific version
pip install --upgrade azure-cli==2.75.0
```

### Option 5: Use Azure Python SDK Directly

Bypass del CLI completamente (para automation):

```python
from azure.identity import AzureCliCredential
from azure.mgmt.resource import ResourceManagementClient

credential = AzureCliCredential()
client = ResourceManagementClient(credential, subscription_id)

# Deploy
deployment = client.deployments.begin_create_or_update(
    scope=f"/subscriptions/{subscription_id}",
    deployment_name="my-deployment",
    parameters={
        "properties": {
            "mode": "Incremental",
            "template": template_dict,
            "parameters": params_dict
        }
    }
)

# Wait for completion
result = deployment.result()
print(f"Deployment state: {result.properties.provisioning_state}")
```

## 🎯 Prevention Best Practices

### 1. Use Scripts with Error Handling

```bash
#!/bin/bash
set -euo pipefail

DEPLOYMENT_NAME="deploy-$(date +%Y%m%d-%H%M%S)"

# Launch with --no-wait
echo "🚀 Launching deployment: $DEPLOYMENT_NAME"
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location "spaincentral" \
  --template-file main.bicep \
  --parameters @params.json \
  --no-wait

# Monitor separately
echo "⏳ Monitoring deployment..."
while true; do
    STATE=$(az deployment sub show --name "$DEPLOYMENT_NAME" \
            --query properties.provisioningState -o tsv 2>/dev/null || echo "Unknown")
    
    echo "   State: $STATE"
    
    if [[ "$STATE" == "Succeeded" ]]; then
        echo "✅ Deployment successful!"
        break
    elif [[ "$STATE" == "Failed" ]]; then
        echo "❌ Deployment failed!"
        exit 1
    fi
    
    sleep 30
done
```

### 2. Use Separate Terminals

- **Terminal 1**: Launch deployment with `--no-wait`
- **Terminal 2**: Monitor with `watch` command
- **Terminal 3**: Check logs or troubleshoot

### 3. Avoid Multiple Retries in Same Session

```bash
# ❌ BAD - Same session, multiple attempts
az deployment sub create ... || az deployment sub create ...

# ✅ GOOD - Fresh session between attempts
az logout && az login && az deployment sub create ...
```

## 🐛 Related Issues

- Azure CLI GitHub: [Issue #28XXX](https://github.com/Azure/azure-cli/issues) (similar reports)
- Azure SDK: Response stream handling in `msrest`
- Known in versions: 2.60.0 - 2.75.0 (as of Oct 2025)

## 📊 When Does It Occur?

| Command | Frequency | Severity |
|---------|-----------|----------|
| `az deployment sub create` | High ⚠️ | Critical 🔴 |
| `az deployment group create` | Medium ⚠️ | High 🟠 |
| `az deployment mg create` | Medium ⚠️ | High 🟠 |
| `az vm create` (complex) | Low ℹ️ | Low 🟢 |
| Other long-running ops | Low ℹ️ | Low 🟢 |

### Triggers
- Deployment duration > 5 minutes
- Complex Bicep templates (many resources)
- Network latency/timeouts
- Multiple `dependsOn` chains
- Large parameter files

## 🔧 Our Solution (azure-agent-pro)

Script: `scripts/deploy/deploy-a10-spaincentral.sh`

**Features:**
- ✅ Uses `--output table` (less prone to error)
- ✅ Includes retry logic with fresh session
- ✅ Validates before deployment
- ✅ Progress monitoring with `watch`
- ✅ Error handling and cleanup

**Usage:**
```bash
./scripts/deploy/deploy-a10-spaincentral.sh
```

## 📚 References

- [Azure CLI GitHub Issues](https://github.com/Azure/azure-cli/issues)
- [Azure SDK for Python Docs](https://docs.microsoft.com/python/api/overview/azure/)
- [HTTP Response Streaming Best Practices](https://requests.readthedocs.io/en/latest/user/advanced/#body-content-workflow)

---

**Last Updated**: October 21, 2025  
**Azure CLI Version**: 2.75.0  
**Status**: Known issue, workarounds available
