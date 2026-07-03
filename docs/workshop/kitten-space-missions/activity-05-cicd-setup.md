# Actividad 5: Configuración CI/CD con GitHub Actions

**⏱️ Duración estimada**: 30 minutos 
** Objetivo**: Configurar pipelines de CI/CD automatizados con GitHub Actions usando OIDC (sin secretos)

---

## Objetivos de aprendizaje

1. Configurar OIDC entre GitHub y Azure (secretless authentication)
2. Crear workflows de validación y deployment
3. Configurar GitHub Environments con protection rules
4. Implementar deployment gates y approvals
5. Automatizar validación de Bicep en cada PR

---

## 🔐 Paso 1: Configurar OIDC (OpenID Connect)

### 1.1 ¿Por qué OIDC?

**OIDC** permite que GitHub Actions se autentique en Azure SIN almacenar secretos/passwords en GitHub.

Beneficios:
- No hay secretos que rotar
- 🔐 Autenticación basada en tokens de corta duración
- Auditable y seguro

### 1.2 Prompt para configurar OIDC

```
@workspace 

Dame los comandos Azure CLI completos para configurar OIDC entre mi 
repositorio GitHub y Azure subscription.

Detalles:
- GitHub Username: [TU-USERNAME]
- GitHub Repo: azure-agent-pro
- Azure Subscription ID: [ejecuta: az account show --query id -o tsv]
- Permisos: Contributor en subscription
- Configurar federated credentials para:
 - Branch: main
 - Pull requests
 - Environment: dev

Genera los comandos listos para copy-paste.
```

---

## 🔄 Paso 2: Workflows de CI/CD

### 2.1 Workflow de Validación

Solicita al agente:

```
Genera GitHub Actions workflow para validación de Bicep en PRs.

Ruta: docs/workshop/kitten-space-missions/solution/.github/workflows/bicep-validation.yml

Features:
- Trigger en PR que modifiquen bicep/**
- Jobs: lint, build, security-scan (Checkov), what-if
- OIDC authentication
- Comment en PR con resultados what-if
```

### 2.2 Workflow de Deployment

```
Genera workflow de deployment a Azure.

Ruta: docs/workshop/kitten-space-missions/solution/.github/workflows/deploy-dev.yml

Features:
- Manual trigger (workflow_dispatch)
- Auto-trigger en push a main
- Environment: dev (con approvals)
- Jobs: deploy, smoke-tests
- Rollback automático si falla
```

---

## Paso 3: GitHub Environments

### 3.1 Crear environment dev

```bash
# Via GitHub CLI
gh api repos/YOUR-USERNAME/azure-agent-pro/environments/dev --method PUT

# O manualmente: Settings → Environments → New environment → "dev"
```

### 3.2 Protection Rules

```
Settings → Environments → dev:
- Required reviewers: [tu usuario]
- Wait timer: 0 minutos
- Deployment branches: main only
```

---

## Entregables

- OIDC configurado
- Workflow validación (.github/workflows/bicep-validation.yml)
- Workflow deployment (.github/workflows/deploy-dev.yml) 
- Environment dev configurado
- GitHub Secrets: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID

---

## Siguiente Paso

**➡️ [Actividad 6: Despliegue en Azure](./activity-06-azure-deployment.md)**

