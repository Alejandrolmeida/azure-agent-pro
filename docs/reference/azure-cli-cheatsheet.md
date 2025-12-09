# Azure CLI Cheatsheet 🚀

Una guía completa de comandos Azure CLI organizados por categorías con ejemplos prácticos y mejores prácticas.

## 📑 Índice

- [Autenticación y Configuración](#autenticación-y-configuración)
- [Gestión de Suscripciones](#gestión-de-suscripciones)
- [Grupos de Recursos](#grupos-de-recursos)
- [Compute (VMs)](#compute-vms)
- [Storage](#storage)
- [Networking](#networking)
- [Azure Active Directory](#azure-active-directory)
- [Key Vault](#key-vault)
- [Container Services](#container-services)
- [App Services](#app-services)
- [Azure Functions](#azure-functions)
- [Monitoring y Logging](#monitoring-y-logging)
- [DevOps](#devops)
- [Mejores Prácticas](#mejores-prácticas)

---

## 🔐 Autenticación y Configuración

### Login y Logout
```bash
# Login interactivo
az login

# Login con service principal
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>

# Login con identidad administrada
az login --identity

# Logout
az logout

# Mostrar información de la cuenta actual
az account show

# Listar todas las cuentas
az account list
```

### Configuración Global
```bash
# Configurar valores por defecto
az configure --defaults location=eastus
az configure --defaults group=my-resource-group

# Ver configuración actual
az configure --list-defaults

# Configurar formato de salida por defecto
az configure --defaults output=table
# Opciones: json, jsonc, table, tsv, yaml, yamlc, none

# Configurar core settings
az config set core.output=table
az config set core.collect_telemetry=false
```

---

## 🏷️ Gestión de Suscripciones

### Suscripciones
```bash
# Listar suscripciones
az account list

# Establecer suscripción activa
az account set --subscription "subscription-name-or-id"

# Mostrar suscripción actual
az account show --query name

# Obtener ID de suscripción
az account show --query id -o tsv

# Listar ubicaciones disponibles
az account list-locations --query '[].{Name:name, DisplayName:displayName}' -o table
```

---

## 📦 Grupos de Recursos

### Operaciones Básicas
```bash
# Crear grupo de recursos
az group create --name myResourceGroup --location eastus

# Listar grupos de recursos
az group list

# Mostrar información de un grupo
az group show --name myResourceGroup

# Eliminar grupo de recursos
az group delete --name myResourceGroup --yes --no-wait

# Listar recursos en un grupo
az resource list --resource-group myResourceGroup

# Exportar template de un grupo
az group export --name myResourceGroup
```

### Tags y Metadata
```bash
# Agregar tags a un grupo de recursos
az group update --name myResourceGroup --tags Environment=Dev Project=MyApp

# Listar grupos por tag
az group list --tag Environment=Dev

# Obtener tags de un grupo
az group show --name myResourceGroup --query tags
```

---

## 💻 Compute (VMs)

### Virtual Machines
```bash
# Crear VM
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --size Standard_B1s

# Listar VMs
az vm list

# Mostrar información de VM
az vm show --resource-group myResourceGroup --name myVM

# Iniciar/Parar/Reiniciar VM
az vm start --resource-group myResourceGroup --name myVM
az vm stop --resource-group myResourceGroup --name myVM
az vm restart --resource-group myResourceGroup --name myVM

# Deallocate VM (stop billing)
az vm deallocate --resource-group myResourceGroup --name myVM

# Eliminar VM
az vm delete --resource-group myResourceGroup --name myVM

# Obtener IP pública de VM
az vm show --resource-group myResourceGroup --name myVM --show-details --query publicIps

# Redimensionar VM
az vm resize --resource-group myResourceGroup --name myVM --size Standard_B2s
```

### VM Scale Sets
```bash
# Crear VM Scale Set
az vmss create \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --image Ubuntu2204 \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --generate-ssh-keys

# Escalar manualmente
az vmss scale --resource-group myResourceGroup --name myScaleSet --new-capacity 5

# Listar instancias
az vmss list-instances --resource-group myResourceGroup --name myScaleSet
```

---

## 💾 Storage

### Storage Accounts
```bash
# Crear storage account
az storage account create \
  --name mystorageaccount \
  --resource-group myResourceGroup \
  --location eastus \
  --sku Standard_LRS

# Listar storage accounts
az storage account list

# Obtener connection string
az storage account show-connection-string --name mystorageaccount --resource-group myResourceGroup

# Obtener keys
az storage account keys list --account-name mystorageaccount --resource-group myResourceGroup

# Habilitar static website
az storage blob service-properties update --account-name mystorageaccount --static-website --index-document index.html
```

### Blob Storage
```bash
# Crear container
az storage container create --name mycontainer --account-name mystorageaccount

# Subir archivo
az storage blob upload \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --name myblob \
  --file /path/to/file

# Listar blobs
az storage blob list --account-name mystorageaccount --container-name mycontainer

# Descargar blob
az storage blob download \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --name myblob \
  --file /path/to/download
```

---

## 🌐 Networking

### Virtual Networks
```bash
# Crear VNet
az network vnet create \
  --resource-group myResourceGroup \
  --name myVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name mySubnet \
  --subnet-prefix 10.0.1.0/24

# Crear subnet adicional
az network vnet subnet create \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name mySubnet2 \
  --address-prefix 10.0.2.0/24

# Listar VNets
az network vnet list
```

### Network Security Groups
```bash
# Crear NSG
az network nsg create --resource-group myResourceGroup --name myNSG

# Crear regla NSG
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name AllowHTTP \
  --protocol tcp \
  --priority 1000 \
  --destination-port-range 80 \
  --access allow

# Asociar NSG a subnet
az network vnet subnet update \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name mySubnet \
  --network-security-group myNSG
```

### Load Balancer
```bash
# Crear Load Balancer público
az network lb create \
  --resource-group myResourceGroup \
  --name myLoadBalancer \
  --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEnd \
  --backend-pool-name myBackEndPool

# Crear health probe
az network lb probe create \
  --resource-group myResourceGroup \
  --lb-name myLoadBalancer \
  --name myHealthProbe \
  --protocol tcp \
  --port 80

# Crear regla de balanceo
az network lb rule create \
  --resource-group myResourceGroup \
  --lb-name myLoadBalancer \
  --name myHTTPRule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name myFrontEnd \
  --backend-pool-name myBackEndPool \
  --probe-name myHealthProbe
```

---

## 👥 Azure Active Directory

### Service Principals
```bash
# Crear service principal
az ad sp create-for-rbac --name myServicePrincipal

# Listar service principals
az ad sp list --display-name myServicePrincipal

# Eliminar service principal
az ad sp delete --id <object-id>

# Asignar rol a service principal
az role assignment create \
  --assignee <app-id> \
  --role Contributor \
  --scope /subscriptions/<subscription-id>/resourceGroups/myResourceGroup
```

### Roles y Permisos
```bash
# Listar definiciones de roles
az role definition list

# Crear asignación de rol
az role assignment create \
  --assignee user@domain.com \
  --role "Virtual Machine Contributor" \
  --resource-group myResourceGroup

# Listar asignaciones de rol
az role assignment list --assignee user@domain.com

# Eliminar asignación de rol
az role assignment delete \
  --assignee user@domain.com \
  --role "Virtual Machine Contributor" \
  --resource-group myResourceGroup
```

---

## 🔐 Key Vault

### Operaciones Básicas
```bash
# Crear Key Vault
az keyvault create \
  --name myKeyVault \
  --resource-group myResourceGroup \
  --location eastus

# Establecer política de acceso
az keyvault set-policy \
  --name myKeyVault \
  --upn user@domain.com \
  --secret-permissions get list set delete

# Crear secret
az keyvault secret set --vault-name myKeyVault --name mySecret --value mySecretValue

# Obtener secret
az keyvault secret show --vault-name myKeyVault --name mySecret --query value

# Listar secrets
az keyvault secret list --vault-name myKeyVault

# Eliminar secret
az keyvault secret delete --vault-name myKeyVault --name mySecret
```

### Certificados y Keys
```bash
# Crear key
az keyvault key create --vault-name myKeyVault --name myKey --protection software

# Crear certificado
az keyvault certificate create \
  --vault-name myKeyVault \
  --name myCertificate \
  --policy "$(az keyvault certificate get-default-policy)"

# Importar certificado
az keyvault certificate import \
  --vault-name myKeyVault \
  --name myCertificate \
  --file /path/to/cert.pfx
```

---

## 📦 Container Services

### Azure Container Registry
```bash
# Crear ACR
az acr create \
  --resource-group myResourceGroup \
  --name myRegistry \
  --sku Basic

# Login a ACR
az acr login --name myRegistry

# Build y push imagen
az acr build --registry myRegistry --image myapp:v1 .

# Listar repositorios
az acr repository list --name myRegistry

# Listar tags
az acr repository show-tags --name myRegistry --repository myapp
```

### Azure Container Instances
```bash
# Crear container instance
az container create \
  --resource-group myResourceGroup \
  --name mycontainer \
  --image nginx \
  --dns-name-label myapp \
  --ports 80

# Mostrar logs
az container logs --resource-group myResourceGroup --name mycontainer

# Ejecutar comando en container
az container exec --resource-group myResourceGroup --name mycontainer --exec-command "/bin/bash"
```

### Azure Kubernetes Service
```bash
# Crear cluster AKS
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 1 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Obtener credenciales
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster

# Escalar cluster
az aks scale --resource-group myResourceGroup --name myAKSCluster --node-count 3

# Actualizar cluster
az aks upgrade --resource-group myResourceGroup --name myAKSCluster --kubernetes-version 1.27.0
```

---

## 🌐 App Services

### Web Apps
```bash
# Crear App Service Plan
az appservice plan create \
  --name myAppServicePlan \
  --resource-group myResourceGroup \
  --sku B1

# Crear Web App
az webapp create \
  --resource-group myResourceGroup \
  --plan myAppServicePlan \
  --name myWebApp \
  --runtime "NODE|18-lts"

# Deploy desde Git
az webapp deployment source config \
  --resource-group myResourceGroup \
  --name myWebApp \
  --repo-url https://github.com/user/repo \
  --branch main

# Configurar app settings
az webapp config appsettings set \
  --resource-group myResourceGroup \
  --name myWebApp \
  --settings KEY1=value1 KEY2=value2

# Ver logs
az webapp log tail --resource-group myResourceGroup --name myWebApp
```

---

## ⚡ Azure Functions

### Function Apps
```bash
# Crear Function App
az functionapp create \
  --resource-group myResourceGroup \
  --consumption-plan-location eastus \
  --runtime node \
  --runtime-version 18 \
  --functions-version 4 \
  --name myFunctionApp \
  --storage-account mystorageaccount

# Deploy función
az functionapp deployment source config \
  --resource-group myResourceGroup \
  --name myFunctionApp \
  --repo-url https://github.com/user/function-repo \
  --branch main

# Configurar app settings
az functionapp config appsettings set \
  --resource-group myResourceGroup \
  --name myFunctionApp \
  --settings KEY1=value1
```

---

## 📊 Monitoring y Logging

### Application Insights
```bash
# Crear Application Insights
az monitor app-insights component create \
  --app myAppInsights \
  --location eastus \
  --resource-group myResourceGroup

# Obtener instrumentation key
az monitor app-insights component show \
  --app myAppInsights \
  --resource-group myResourceGroup \
  --query instrumentationKey
```

### Log Analytics
```bash
# Crear workspace
az monitor log-analytics workspace create \
  --resource-group myResourceGroup \
  --workspace-name myWorkspace

# Query logs
az monitor log-analytics query \
  --workspace myWorkspace \
  --analytics-query "AzureActivity | limit 10"
```

---

## 🚀 DevOps

### Azure DevOps
```bash
# Configurar extensión DevOps
az extension add --name azure-devops

# Configurar organización por defecto
az devops configure --defaults organization=https://dev.azure.com/myorg

# Crear proyecto
az devops project create --name myProject

# Listar proyectos
az devops project list

# Crear repositorio
az repos create --name myRepo --project myProject
```

---

## 🎯 Mejores Prácticas

### Seguridad
```bash
# Usar Managed Identity siempre que sea posible
az vm identity assign --resource-group myResourceGroup --name myVM

# Rotar keys regularmente
az storage account keys renew --account-name mystorageaccount --key key1

# Usar Key Vault para secretos
az keyvault secret set --vault-name myKeyVault --name connectionString --value "secret"

# Configurar Network Security Groups restrictivos
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name DenyAll \
  --priority 4096 \
  --access Deny \
  --protocol "*" \
  --source-address-prefix "*" \
  --destination-port-range "*"
```

### Performance y Costo
```bash
# Usar tags para tracking de costos
az resource tag --tags Environment=Dev CostCenter=IT --ids /subscriptions/sub-id/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm

# Programar auto-shutdown para VMs de desarrollo
az vm auto-shutdown -g myResourceGroup -n myVM --time 1800

# Usar spot instances para cargas de trabajo tolerantes a fallos
az vm create \
  --resource-group myResourceGroup \
  --name mySpotVM \
  --image Ubuntu2204 \
  --priority Spot \
  --max-price 0.01
```

### Automatización
```bash
# Usar JSON queries para automatización
VM_ID=$(az vm show --resource-group myResourceGroup --name myVM --query id -o tsv)

# Usar loops para operaciones en batch
for vm in $(az vm list --query '[].name' -o tsv); do
  az vm stop --resource-group myResourceGroup --name $vm --no-wait
done

# Usar --no-wait para operaciones asíncronas
az vm start --resource-group myResourceGroup --name myVM --no-wait

# Usar output templates para formato consistente
az vm list --output table --query '[].{Name:name, Status:powerState, Size:hardwareProfile.vmSize}'
```

### Troubleshooting
```bash
# Habilitar debug output
az vm list --debug

# Ver actividad reciente
az monitor activity-log list --resource-group myResourceGroup

# Verificar límites y quotas
az vm list-usage --location eastus

# Obtener logs de deployment
az deployment group list --resource-group myResourceGroup
az deployment operation group list --resource-group myResourceGroup --name myDeployment
```

---

## 🔧 Comandos de Utilidad

### Información del Sistema
```bash
# Versión de Azure CLI
az version

# Actualizar Azure CLI
az upgrade

# Listar extensiones instaladas
az extension list

# Instalar extensión
az extension add --name <extension-name>

# Obtener ayuda
az <command> --help
az vm create --help
```

### JSON Queries Útiles
```bash
# Obtener solo nombres
az vm list --query '[].name'

# Filtrar por ubicación
az vm list --query "[?location=='eastus'].name"

# Ordenar resultados
az vm list --query 'sort_by([], &name)'

# Contar elementos
az vm list --query 'length([])'

# Usar contains
az vm list --query "[?contains(name, 'web')]"
```

---

## 📚 Recursos Adicionales

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure CLI GitHub](https://github.com/Azure/azure-cli)
- [JMESPath Tutorial](http://jmespath.org/tutorial.html) - Para queries JSON
- [Azure CLI Extensions](https://docs.microsoft.com/en-us/cli/azure/azure-cli-extensions-list)

---

💡 **Tip**: Usa `az interactive` para una experiencia mejorada con autocompletado y ayuda contextual.