# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.1.0] - 2025-12-29

### 🎯 Highlights
- **🆕 Diagnostic Validation Protocol** - Prevención de errores diagnósticos con checklist obligatorio
- Azure SQL DBA Agent completo con metodología evidence-first
- **Lecciones aprendidas de incidentes reales** (caso 2025-12: zombie transactions false positive)
- Herramientas SQL avanzadas (sql-query.py, sql-analyzer.sh, detect-zombie-transactions.sh)
- Scripts de validación pre/post diagnóstico
- Detección de transacciones zombie (ADR/PVS-aware)
- Reorganización completa de scripts por agente
- 15 nuevos archivos (12 documentación + 3 scripts validación)
- 9 scripts SQL/Bash/Python nuevos

### Added
- **🆕 Diagnostic Validation Protocol**
  - `pre-diagnosis-zombie-validation.sh` - Checklist 5 pasos obligatorio antes de diagnosticar zombie
  - `post-diagnosis-validation.sh` - Auto-validación post-diagnóstico
  - `docs/reference/diagnostic-checklists.md` - 940+ líneas con 5 protocolos completos
- Azure SQL DBA Agent con 6 playbooks completos
- **Lecciones de Incidentes Reales** en agent (caso 2025-12)
- SQL query execution tools (Python + Bash)
- SQL performance analyzer con 8 análisis automatizados
- Zombie transaction detection tools
- Interactive SQL diagnosis scripts for SSMS
- Azure SQL connection guide (327 líneas)
- Microsoft Support email templates
- Usage pattern analysis for maintenance windows
- WSL quick setup script

### Changed
- **IMPROVED**: Azure_SQL_DBA.agent.md con sección "Lecciones Aprendidas"
- **IMPROVED**: Playbook 3 (Storage Growth) integra pre-diagnosis validation
- **BREAKING**: Scripts reorganizados en estructura por agente
  - `scripts/common/` - Scripts compartidos
  - `scripts/agents/architect/` - Azure Architect Agent
  - `scripts/agents/sql-dba/` - Azure SQL DBA Agent
- 87+ referencias actualizadas en documentación

### Fixed
- SQL Server Bicep module corregido
- Workflows de calidad configurados para ejecución manual

### Security
- Repository sanitizado (sin datos reales en commits)
- Ejemplos anonymizados en toda la documentación
- Azure AD authentication preferido sobre SQL auth

### Lessons Learned
**Caso 2025-12: Falso Positivo "Zombie Transactions"**
- ❌ Error: Diagnosticar transacciones de 47 días como zombies sin verificar SQL uptime ni correlación con restart
- ✅ Corrección: Microsoft identificó que eran transacciones internas post-restart (session_id=NULL)
- 🎓 Aprendizaje: Implementar checklist obligatorio con 5 checkpoints antes de diagnosticar
- 🛡️ Impacto: Previene errores que dañan credibilidad profesional, asegura evidence-first approach

**📄 Full Release Notes**: [docs/releases/v1.1.0.md](docs/releases/v1.1.0.md)  
**📦 Commits**: 19 commits (incluye mejoras post-release) | **📊 Files**: +15 | **📝 Lines**: +6,000

---

## [v1.0.0] - 2025-12-09

### Initial Release
- Azure Architect Agent completo
- Bicep modules para infraestructura Azure
- MCP servers integration (Bicep experimental, Pylance)
- GitHub Actions workflows
- Complete documentation structure
- Kitten Space Missions workshop

**📄 Full Release Notes**: [docs/releases/v1.0.0.md](docs/releases/v1.0.0.md)

---

## Release Links

- **Latest**: [v1.1.0](https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.1.0)
- **Previous**: [v1.0.0](https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.0.0)
- **All Releases**: [GitHub Releases](https://github.com/Alejandrolmeida/azure-agent-pro/releases)

---

## Migration Guides

### From v1.0.0 to v1.1.0

**Scripts Path Changes:**

| Old Path | New Path |
|----------|----------|
| `scripts/utils/sql-*.sh` | `scripts/agents/sql-dba/sql-*.sh` |
| `scripts/deploy/bicep-deploy.sh` | `scripts/agents/architect/bicep-deploy.sh` |
| `scripts/config/azure-config.sh` | `scripts/common/azure-config.sh` |
| `scripts/login/azure-login.sh` | `scripts/common/azure-login.sh` |

**Action Required**: Update any scripts or CI/CD pipelines that reference old paths.

---

[v1.1.0]: https://github.com/Alejandrolmeida/azure-agent-pro/compare/v1.0.0...v1.1.0
[v1.0.0]: https://github.com/Alejandrolmeida/azure-agent-pro/releases/tag/v1.0.0
