## Descripción

<!-- Describe brevemente qué cambios incluye este PR -->

## Tipo de Cambio

- [ ] 🐛 Bug fix (cambio que corrige un issue)
- [ ] Nueva funcionalidad (cambio que añade funcionalidad)
- [ ] 💥 Breaking change (fix o feature que causaría que funcionalidad existente no funcione como se espera)
- [ ] Actualización de documentación
- [ ] Refactoring (cambio de código que no corrige bug ni añade funcionalidad)
- [ ] 🎨 Mejora de estilo/formato
- [ ] Mejora de performance
- [ ] Añadir tests
- [ ] 🔨 Actualización de scripts de build/deploy

## Issue Relacionado

<!-- Enlaza al issue que este PR resuelve -->
Fixes #(número_del_issue)
Closes #(número_del_issue)
Related to #(número_del_issue)

## Testing

### Tests Realizados

- [ ] Tests locales pasados
- [ ] Validación de Bicep ejecutada
- [ ] Deployment en ambiente de desarrollo probado
- [ ] ShellCheck ejecutado en scripts modificados
- [ ] Documentación revisada

### 🔄 Comandos para Testing

```bash
# Comandos que otros pueden ejecutar para probar los cambios
./scripts/test-script.sh
az bicep build --file bicep/main.bicep
```

## Archivos Modificados

### Scripts
- [ ] `scripts/common/azure-login.sh`
- [ ] `scripts/agents/architect/bicep-deploy.sh`
- [ ] `scripts/common/azure-config.sh`
- [ ] `scripts/common/azure-utils.sh`
- [ ] `scripts/agents/architect/bicep-utils.sh`
- [ ] Otros: ___________

### Infraestructura
- [ ] `bicep/main.bicep`
- [ ] `bicep/modules/storage-account.bicep`
- [ ] `bicep/modules/key-vault.bicep`
- [ ] `bicep/modules/virtual-network.bicep`
- [ ] `bicep/parameters/*.json`
- [ ] Otros: ___________

### Documentación
- [ ] `README.md`
- [ ] `PROJECT_CONTEXT.md`
- [ ] `docs/cheatsheets/`
- [ ] Comentarios en código
- [ ] Otros: ___________

### 🔄 CI/CD
- [ ] `.github/workflows/`
- [ ] `.github/ISSUE_TEMPLATE/`
- [ ] `.gitignore`
- [ ] Otros: ___________

## 🌍 Impacto en Ambientes

- [ ] Desarrollo (dev) - Sin impacto / Impacto mínimo / Requiere redeploy
- [ ] Testing (test) - Sin impacto / Impacto mínimo / Requiere redeploy
- [ ] Staging (stage) - Sin impacto / Impacto mínimo / Requiere redeploy
- [ ] Producción (prod) - Sin impacto / Impacto mínimo / Requiere redeploy

## 🔄 Pasos de Deployment

<!-- Si este PR requiere pasos especiales de deployment, descríbelos aquí -->

1. [ ] Merge este PR
2. [ ] Ejecutar `./scripts/agents/architect/bicep-deploy.sh`
3. [ ] Verificar recursos en Azure Portal
4. [ ] Actualizar documentación si es necesario

## 📸 Screenshots

<!-- Si aplica, añade screenshots que demuestren los cambios -->

## Checklist del Reviewer

- [ ] El código sigue las convenciones del proyecto
- [ ] Los cambios están bien documentados
- [ ] Los tests pasan
- [ ] No hay hardcoded secrets o configuraciones sensibles
- [ ] Las plantillas Bicep siguen las mejores prácticas de seguridad
- [ ] Los scripts tienen manejo adecuado de errores
- [ ] La documentación está actualizada

## Checklist del Autor

- [ ] He probado mis cambios localmente
- [ ] He actualizado la documentación correspondiente
- [ ] He añadido tests para cubrir mis cambios (si aplica)
- [ ] Todos los tests nuevos y existentes pasan
- [ ] He verificado que no introduzco breaking changes sin avisar
- [ ] He seguido las convenciones de código del proyecto
- [ ] He verificado que no hay información sensible en el código

## Notas Adicionales

<!-- Cualquier información adicional que pueda ser útil para los reviewers -->

## 🔄 Plan de Rollback

<!-- En caso de que este cambio cause problemas, describe cómo hacer rollback -->

- [ ] Este cambio puede ser revertido fácilmente con git revert
- [ ] Se requieren pasos especiales para rollback: ___________
- [ ] No es posible hacer rollback automático
