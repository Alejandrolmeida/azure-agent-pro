# Security Policy

## Reporting Security Vulnerabilities

Si encuentras una vulnerabilidad de seguridad en el proyecto Azure Agent, por favor repórtala de manera responsable.

### 📧 Contacto de Seguridad

- **Email principal**: security@example.com
- **GitHub**: [@Alejandrolmeida](https://github.com/Alejandrolmeida)
- **Tiempo de respuesta**: 48 horas máximo
- **Disponibilidad**: Lunes a Viernes, 9:00-18:00 UTC

### Proceso de Reporte

1. **NO** abras un issue público para vulnerabilidades de seguridad
2. Envía un email detallado al contacto de seguridad (security@example.com)
3. Incluye toda la información necesaria para reproducir el issue
4. Permite tiempo razonable para la corrección antes de disclosure público

### Información Requerida

Por favor incluye la siguiente información en tu reporte:

- **Descripción** de la vulnerabilidad
- **Pasos** para reproducir el issue
- **Impacto** potencial de la vulnerabilidad
- **Versiones afectadas** del proyecto
- **Mitigation** sugerida si la tienes

## Vulnerabilidades Cubiertas

Nos interesan reportes sobre:

### 🔴 Críticas
- Exposición de credenciales o secrets en código
- Inyección de código en scripts bash
- Configuraciones de Azure que expongan recursos públicamente
- Bypass de autenticación o autorización

### 🟠 Altas
- Configuraciones inseguras en plantillas Bicep
- Permisos excesivos en roles de Azure
- Falta de cifrado en recursos de almacenamiento
- Logs que contengan información sensible

### 🟡 Medias
- Configuraciones de red inseguras
- Falta de validación de entrada en scripts
- Configuraciones por defecto inseguras

### 🔵 Bajas
- Problemas de configuración menores
- Mejores prácticas de seguridad no implementadas

## Fuera de Alcance

Los siguientes issues están **fuera del alcance** de nuestro programa de seguridad:

- Vulnerabilidades en dependencias de terceros (pero las agradecemos)
- Issues que requieren acceso físico a la máquina
- Ataques de ingeniería social
- Issues en ambientes de desarrollo/testing locales
- Spam o ataques DDoS

## 🔄 Proceso de Response

1. **Confirmación** (24-48 horas)
 - Confirmamos recepción del reporte
 - Evaluación inicial del issue

2. **Análisis** (1-7 días)
 - Investigación detallada
 - Confirmación de la vulnerabilidad
 - Evaluación del impacto

3. **Desarrollo** (1-4 semanas)
 - Desarrollo de la corrección
 - Testing en múltiples ambientes
 - Preparación del release

4. **Release** (1-2 días)
 - Deploy de la corrección
 - Notificación a usuarios afectados
 - Disclosure público coordinado

## Severidad y SLA

| Severidad | Tiempo de Response | Tiempo de Fix |
|-----------|-------------------|---------------|
| Crítica | 24 horas | 7 días |
| Alta | 48 horas | 14 días |
| Media | 1 semana | 30 días |
| Baja | 2 semanas | 60 días |

## Configuraciones de Seguridad

### Azure Resources

Todas las plantillas Bicep implementan:

- **Cifrado en tránsito**: HTTPS/TLS 1.3 obligatorio
- **Cifrado en reposo**: Habilitado por defecto
- **Network Security**: Private endpoints cuando es posible
- **Access Control**: RBAC con privilegios mínimos
- **Monitoring**: Logging y alertas habilitadas
- **Backup**: Configurado para recursos críticos

### CI/CD Security

- **OIDC Authentication**: Sin passwords en workflows
- **Secret Management**: Azure Key Vault integration
- **Code Scanning**: Automated security analysis
- **Dependency Scanning**: Dependabot enabled
- **Branch Protection**: Required reviews para main

### Script Security

- **Input Validation**: Todos los scripts validan entrada
- **Error Handling**: Manejo adecuado de errores
- **Logging**: No se logean datos sensibles
- **Permissions**: Principio de menor privilegio

## Security Tools

## Pre-commit Anti-Secrets

El repositorio incluye un hook local en [.githooks/pre-commit](.githooks/pre-commit) para bloquear commits con:

- Archivos `.env` locales
- `AZURE_CLIENT_SECRET`, `APPINSIGHTS_CONNECTION_STRING`, `APPINSIGHTS_RESOURCE_ID` y otros valores de cliente con datos reales
- `InstrumentationKey` reales
- Outputs sensibles guardados en notebooks

Activacion en local (una vez por clon):

1. `git config core.hooksPath .githooks`
2. `chmod +x .githooks/pre-commit`

Este control reduce la probabilidad de subir secretos por error, pero no sustituye la rotacion de credenciales ni el principio de minimo privilegio.

### Automated Scanning

- **Trivy**: Vulnerability scanning
- **ShellCheck**: Bash script analysis
- **Bicep Linter**: Infrastructure security
- **GitHub CodeQL**: Code analysis
- **Dependabot**: Dependency updates

### Manual Reviews

- Security review para todos los PRs con cambios sensibles
- Penetration testing para releases mayores
- Configuration reviews para environments de producción

## Security Resources

### Training Materials

- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Bicep Security Guidelines](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/best-practices)
- [GitHub Security Features](https://docs.github.com/en/code-security)

### External Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Azure Security Benchmark](https://docs.microsoft.com/en-us/security/benchmark/azure/)
- [CIS Azure Foundations](https://www.cisecurity.org/benchmark/azure)

## 🏆 Recognition

Agradecemos a todos los security researchers que han contribuido:

<!-- Lista de contributors será actualizada aquí -->

## Security Metrics

Tracking público de nuestras métricas de seguridad:

- **Tiempo promedio de response**: X horas
- **Tiempo promedio de fix**: X días 
- **Vulnerabilidades encontradas**: X en los últimos 12 meses
- **Vulnerabilidades corregidas**: X% resueltas

---

## 📞 Contact Information

- **Security Team**: security@example.com
- **Project Maintainer**: Project Maintainer (security@example.com)
- **GitHub**: [@Alejandrolmeida](https://github.com/Alejandrolmeida)

**Última actualización**: 2025-09-22
