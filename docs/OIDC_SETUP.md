# Configuración OIDC para GitHub Actions

Este documento explica cómo configurar la autenticación OIDC (OpenID Connect) entre GitHub Actions y Azure para desplegar la infraestructura sin necesidad de guardar credenciales en secrets.

## ¿Por qué OIDC?

- ✅ **Sin secrets de larga duración**: No se almacenan passwords ni service principal keys
- ✅ **Más seguro**: Los tokens son de corta duración y específicos por workflow
- ✅ **Auditable**: Trazabilidad completa de qué workflow ejecutó qué acción
- ✅ **Recomendado por Microsoft**: Best practice oficial

## Pasos de Configuración

### 1. Crear Azure AD Application

```bash
# Login a Azure
az login

# Crear la aplicación
APP_NAME="github-actions-avd-pix4d"
az ad app create --display-name "$APP_NAME"

# Obtener el App ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
echo "App ID: $APP_ID"
```

### 2. Crear Service Principal

```bash
# Crear service principal para la app
az ad sp create --id $APP_ID

# Obtener Object ID del service principal
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query "id" -o tsv)
echo "Service Principal Object ID: $SP_OBJECT_ID"
```

### 3. Configurar Federated Credentials

```bash
# Obtener información del repositorio
GITHUB_ORG="alejandrolmeida"  # Tu usuario/organización
GITHUB_REPO="azure-agent-pro"
BRANCH="feature/avd-pix4d-lab"

# Crear federated credential para la rama principal
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-avd-pix4d-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/'$BRANCH'",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Crear federated credential para Pull Requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-avd-pix4d-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Crear federated credential para environments
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-avd-pix4d-lab-env",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:lab",
    "audiences": ["api://AzureADTokenExchange"]
  }'

az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-avd-pix4d-prod-env",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':environment:prod",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 4. Asignar Permisos en Azure

```bash
# Obtener Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Asignar rol Contributor a nivel de suscripción
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Asignar permisos adicionales si es necesario
# Para User Access Administrator (gestionar RBAC)
az role assignment create \
  --assignee $APP_ID \
  --role "User Access Administrator" \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

### 5. Configurar GitHub Secrets

En tu repositorio de GitHub, ve a **Settings → Secrets and variables → Actions** y añade:

```
AZURE_CLIENT_ID = [App ID del paso 1]
AZURE_TENANT_ID = [Tu Tenant ID]
AZURE_SUBSCRIPTION_ID = [Tu Subscription ID]
AVD_ADMIN_PASSWORD = [Password seguro para el admin de las VMs]
```

Para obtener tu Tenant ID:
```bash
az account show --query tenantId -o tsv
```

### 6. Crear Environments en GitHub

1. Ve a **Settings → Environments**
2. Crea dos environments:
   - `lab`
   - `prod`
3. Opcionalmente, configura **Required reviewers** para prod

### 7. Verificar Configuración

```bash
# Listar federated credentials
az ad app federated-credential list --id $APP_ID --query "[].{Name:name, Subject:subject}" -o table

# Verificar role assignments
az role assignment list --assignee $APP_ID --query "[].{Role:roleDefinitionName, Scope:scope}" -o table
```

## Uso en GitHub Actions

Los workflows ya están configurados para usar OIDC. El bloque clave es:

```yaml
jobs:
  deploy:
    permissions:
      id-token: write  # Necesario para OIDC
      contents: read
    steps:
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Troubleshooting

### Error: "AADSTS700016: Application not found"

**Causa**: El App ID es incorrecto o la aplicación no existe.

**Solución**:
```bash
az ad app list --display-name "github-actions-avd-pix4d"
```

### Error: "AADSTS70021: No matching federated identity record found"

**Causa**: El subject del federated credential no coincide con el repositorio/rama.

**Solución**: Verificar que el subject es exacto:
```bash
# Para rama
subject: repo:OWNER/REPO:ref:refs/heads/BRANCH

# Para PR
subject: repo:OWNER/REPO:pull_request

# Para environment
subject: repo:OWNER/REPO:environment:ENV_NAME
```

### Error: "Authorization failed"

**Causa**: El service principal no tiene permisos suficientes.

**Solución**:
```bash
# Verificar role assignments
az role assignment list --assignee $APP_ID -o table

# Añadir Contributor si falta
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

## Seguridad

### Best Practices

1. ✅ **Usa environments** con required reviewers para prod
2. ✅ **Limita federated credentials** solo a ramas/environments necesarios
3. ✅ **Revisa regularmente** los role assignments
4. ✅ **Usa el principio de mínimo privilegio**
5. ✅ **Habilita audit logs** en Azure AD

### Rotación

Los tokens OIDC son de corta duración (< 1 hora), pero debes:

- Revisar periódicamente las credenciales federadas
- Eliminar las que ya no se usen
- Auditar los role assignments

```bash
# Listar y limpiar federated credentials antiguas
az ad app federated-credential list --id $APP_ID

# Eliminar una credential
az ad app federated-credential delete --id $APP_ID --federated-credential-id <CRED_ID>
```

## Referencias

- [Azure OIDC Documentation](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
- [GitHub Actions - Azure Login](https://github.com/Azure/login)
- [Configuring OpenID Connect in Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)

---

**Nota**: Guarda los valores de `APP_ID`, `TENANT_ID` y `SUBSCRIPTION_ID` en un lugar seguro para futuras referencias.
