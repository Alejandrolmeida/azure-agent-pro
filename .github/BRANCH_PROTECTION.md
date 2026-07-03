# Branch Protection Rules

Esta documentación describe las reglas de protección de ramas recomendadas para el repositorio Azure Agent.

## Configuración Recomendada

### Rama `main`

#### Protecciones Básicas
- **Require a pull request before merging**
 - Require approvals: **1**
 - Dismiss stale PR approvals when new commits are pushed
 - Require review from code owners
 - Restrict pushes that create pull requests

#### Checks de Estado Requeridos
- **Require status checks to pass before merging**
 - Require branches to be up to date before merging
 - **Required checks:**
 - `bicep-validation / Validate Bicep Templates`
 - `shellcheck / Shell Script Analysis`
 - `markdown-lint / Markdown Linting`
 - `security-scan / Security Scanning`
 - `bicep-security / Bicep Security Analysis`

#### Restricciones Adicionales
- **Restrict pushes to matching branches**
 - **Who can push:** Admins only
- **Allow force pushes:** Disabled
- **Allow deletions:** Disabled

### Rama `develop` (si se usa)

#### Protecciones Básicas
- **Require a pull request before merging**
 - Require approvals: **1**
 - Dismiss stale PR approvals when new commits are pushed
 - Require review from code owners

#### Checks de Estado Requeridos
- **Require status checks to pass before merging**
 - Require branches to be up to date before merging
 - **Required checks:**
 - `bicep-validation / Validate Bicep Templates`
 - `shellcheck / Shell Script Analysis`

## Configuración Manual en GitHub

### Pasos para Configurar Branch Protection

1. **Ir a Settings del repositorio**
 ```
 GitHub Repository → Settings → Code and automation → Branches
 ```

2. **Añadir regla para `main`**
 ```
 Branch name pattern: main
 ```

3. **Configurar protecciones según la tabla anterior**

4. **Guardar cambios**

### Via GitHub CLI

```bash
# Configurar protección para main
gh api repos/:owner/:repo/branches/main/protection \
 --method PUT \
 --field required_status_checks='{"strict":true,"contexts":["bicep-validation / Validate Bicep Templates","shellcheck / Shell Script Analysis","security-scan / Security Scanning"]}' \
 --field enforce_admins=true \
 --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
 --field restrictions=null
```

## 🏷️ CODEOWNERS

El archivo `.github/CODEOWNERS` define quién debe revisar cambios en archivos específicos:

```
# Global owners
* @alejandrolmeida

# Bicep templates require infrastructure team review
bicep/ @alejandrolmeida @infrastructure-team

# CI/CD workflows require DevOps review
.github/workflows/ @alejandrolmeida @devops-team

# Scripts require approval from maintainer
scripts/ @alejandrolmeida

# Documentation can be reviewed by maintainer
docs/ @alejandrolmeida
*.md @alejandrolmeida @docs-team

# Security-sensitive files require security review
.github/workflows/deploy-azure.yml @alejandrolmeida @security-team
bicep/modules/key-vault.bicep @alejandrolmeida @security-team
```

## Environments

### Configurar Environments en GitHub

1. **Development Environment**
 - Protection rules: None (auto-deploy)
 - Required reviewers: None
 - Wait timer: 0 minutes

2. **Test Environment**
 - Protection rules: Required reviewers
 - Required reviewers: @alejandrolmeida
 - Wait timer: 0 minutes

3. **Staging Environment**
 - Protection rules: Required reviewers
 - Required reviewers: @alejandrolmeida, @staging-approvers
 - Wait timer: 5 minutes

4. **Production Environment**
 - Protection rules: Required reviewers
 - Required reviewers: @alejandrolmeida, @production-approvers
 - Wait timer: 30 minutes
 - Deployment branches: main only

## Required Secrets

### Repository Secrets

```bash
# Azure Service Principal for OIDC
AZURE_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Optional: Notification webhooks
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
TEAMS_WEBHOOK_URL=https://outlook.office.com/webhook/...
```

### Environment Secrets

Cada environment puede tener sus propios secrets:

```bash
# Development
DEV_RESOURCE_GROUP=azure-agent-dev-rg
DEV_LOCATION=eastus

# Production
PROD_RESOURCE_GROUP=azure-agent-prod-rg
PROD_LOCATION=eastus
PROD_BACKUP_LOCATION=westus2
```

## 🔄 Workflow de Branches

### Estrategia Recomendada: GitHub Flow

```
main (protegida)
├── feature/nueva-funcionalidad
├── fix/corregir-bug
├── docs/actualizar-readme
└── hotfix/fix-urgente-prod
```

### Convenciones de Naming

- `feature/descripcion-corta` - Nuevas funcionalidades
- `fix/numero-issue-descripcion` - Bug fixes
- `docs/descripcion-cambio` - Cambios de documentación
- `refactor/descripcion-cambio` - Refactoring
- `hotfix/descripcion-urgente` - Fixes urgentes para producción

## Monitoring y Alerts

### GitHub Repository Insights

- Habilitar **Pulse** para ver actividad semanal
- Configurar **Code frequency** para ver contribuciones
- Revisar **Dependency graph** para vulnerabilidades

### Notifications

```bash
# Configurar notifications para:
- Pull request reviews
- Failed workflow runs
- Security alerts
- New releases
```

## Security Settings

### Security Features Recomendadas

- **Dependency graph:** Enabled
- **Dependabot alerts:** Enabled
- **Dependabot security updates:** Enabled
- **Code scanning:** Enabled (via workflows)
- **Secret scanning:** Enabled
- **Private vulnerability reporting:** Enabled

### Repository Security Policy

Crear archivo `SECURITY.md` con políticas de seguridad del proyecto.

---

## Tips Adicionales

1. **Revisar configuración regularmente** - Las reglas pueden necesitar ajustes
2. **Documentar excepciones** - Si se necesita bypass temporal, documentar el motivo
3. **Automatizar donde sea posible** - Usar GitHub Actions para aplicar políticas
4. **Entrenar al equipo** - Asegurar que todos entienden las reglas y el proceso
