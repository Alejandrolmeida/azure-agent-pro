# 🔒 Security Checklist for Public Repository

Este checklist te ayuda a asegurar que tu repositorio Azure Agent esté correctamente configurado para ser público sin exponer información sensible.

## ✅ Pre-Publication Checklist

### 🔍 Secrets y Credenciales

- [ ] **No hay secrets hardcoded** en el código
- [ ] **No hay API keys** en archivos de configuración
- [ ] **No hay connection strings** en el código
- [ ] **No hay passwords** en texto plano
- [ ] **Azure subscription IDs** están en secrets, no en código
- [ ] **Client IDs y Tenant IDs** están en secrets
- [ ] **Certificates y private keys** están excluidos por .gitignore

### 📁 Archivos de Configuración

- [ ] **`.gitignore`** incluye todos los tipos de archivos sensibles
- [ ] **No hay archivos `.env`** commitados
- [ ] **No hay archivos de configuración local** con datos reales
- [ ] **Parámetros de Bicep** no contienen valores hardcoded
- [ ] **Scripts** usan variables de entorno, no valores hardcoded

### 👥 Información Personal

- [ ] **Emails personales** reemplazados por genéricos
- [ ] **Nombres de usuario** reemplazados por placeholders
- [ ] **URLs del repositorio** son genéricas (YOUR_USERNAME)
- [ ] **Nombres de recursos** usan variables, no nombres específicos
- [ ] **CODEOWNERS** tiene instrucciones para personalizar

### 🏗️ Azure Resources

- [ ] **Nombres de Resource Groups** son configurables
- [ ] **Locations de Azure** son variables
- [ ] **Subscription IDs** están en secrets
- [ ] **No hay nombres específicos** de Storage Accounts
- [ ] **Key Vault names** usan variables

### 🔄 GitHub Actions

- [ ] **Workflows** usan `${{ secrets.* }}` para credenciales
- [ ] **No hay environment names** hardcoded
- [ ] **Variables de repositorio** están documentadas
- [ ] **Secrets requeridos** están listados en documentación
- [ ] **Permisos** están configurados con least privilege

## 🛡️ Post-Publication Security

### 📊 Monitoring

- [ ] **Dependabot** habilitado para updates de seguridad
- [ ] **Code scanning** habilitado
- [ ] **Secret scanning** habilitado
- [ ] **Vulnerability alerts** habilitados
- [ ] **Security advisories** configuradas

### 🔐 Access Control

- [ ] **Branch protection** habilitada en main
- [ ] **Required reviews** configurados
- [ ] **Status checks** obligatorios
- [ ] **Force push** deshabilitado
- [ ] **Delete protection** habilitado

### 📝 Documentation

- [ ] **README** actualizado con instrucciones genéricas
- [ ] **SECURITY.md** incluye proceso de reporte
- [ ] **CONTRIBUTING.md** incluye guidelines de seguridad
- [ ] **Issue templates** no contienen datos sensibles
- [ ] **PR template** incluye security checklist

## 🔧 Configuration Files to Review

### High Priority
```bash
.gitignore                          # Must exclude all sensitive files
.github/workflows/*.yml             # Must use secrets, not hardcoded values
.github/CODEOWNERS                  # Must use placeholders for usernames
README.md                           # Must use generic URLs and examples
SECURITY.md                         # Must use generic contact info
```

### Medium Priority
```bash
bicep/parameters/*.json             # Should not contain real values
.github/ISSUE_TEMPLATE/*.md         # Should not reference specific repos
.github/BRANCH_PROTECTION.md        # Should use examples, not real data
CONTRIBUTING.md                     # Should be generic for reuse
```

### Low Priority
```bash
docs/**/*.md                        # Review for any specific references
scripts/**/*.sh                     # Check for hardcoded values
PROJECT_CONTEXT.md                  # Update dates and references
```

## 🚨 Red Flags to Look For

### Immediate Action Required
- ❌ API keys o tokens visibles
- ❌ Passwords en texto plano
- ❌ Connection strings completas
- ❌ Private keys o certificates
- ❌ Email addresses reales en código

### Should Fix Before Publishing
- ⚠️ Subscription IDs en código
- ⚠️ Resource names específicos
- ⚠️ URLs del repositorio específicas
- ⚠️ Usernames hardcoded
- ⚠️ Company-specific información

### Nice to Have
- 💡 Generic examples en lugar de datos reales
- 💡 Placeholders claramente marcados
- 💡 Documentation para personalización
- 💡 Template files para configuración
- 💡 Automated checks para secrets

## 🔄 Regular Maintenance

### Monthly
- [ ] Review security alerts de GitHub
- [ ] Update dependencies vulnerables
- [ ] Review access permissions
- [ ] Check for new secrets accidentally committed

### Quarterly  
- [ ] Full security audit del código
- [ ] Review y update de .gitignore
- [ ] Test security workflows
- [ ] Update security documentation

### When Adding New Features
- [ ] Review new code for secrets
- [ ] Update .gitignore si es necesario
- [ ] Add security tests si aplica
- [ ] Update documentation de seguridad

## 🛠️ Tools for Verification

### Manual Checks
```bash
# Search for potential secrets
grep -r -i "password\|secret\|key\|token" . --exclude-dir=.git

# Check for email addresses
grep -r -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" .

# Look for hardcoded IDs
grep -r -E "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" .
```

### Automated Tools
- **TruffleHog**: Buscar secrets en Git history
- **GitLeaks**: Detectar leaks de credenciales
- **GitHub Secret Scanning**: Scanning automático
- **Pre-commit hooks**: Prevenir commits con secrets

## 📞 Emergency Response

### If Secrets Are Accidentally Committed

1. **Immediate Actions**
   - [ ] Revoke/rotate the compromised credentials
   - [ ] Remove from Git history (use BFG Repo-Cleaner)
   - [ ] Force push to update remote
   - [ ] Notify team members

2. **Follow-up Actions**
   - [ ] Review logs for unauthorized access
   - [ ] Update security procedures
   - [ ] Add prevention measures
   - [ ] Document incident for learning

### Contact Information
- **Security Team**: security@[your-domain]
- **Emergency**: [emergency-contact]
- **GitHub Support**: https://support.github.com/

---

**Remember**: Es mejor prevenir que remediar. Tómate el tiempo necesario para revisar todo antes de hacer público el repositorio. 🔒✨