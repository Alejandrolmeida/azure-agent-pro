![Azure Agent Pro](./workshop/kitten-space-missions/assets/workshop-hero.png)

# 📚 Documentación - Azure Agent Pro

Bienvenido a **Azure Agent Pro**, un proyecto educativo que te enseña a construir infraestructura Azure enterprise usando **Vibe Coding** con el agente personalizado **Azure_Architect_Pro**.

---

## 🚀 Empezar Aquí

¿Nuevo en el proyecto? Comienza por el workshop hands-on:

### ⭐ [Workshop: Kitten Space Missions](./workshop/kitten-space-missions/)

**Construye una API REST completa sin escribir código manualmente**

- ⏱️ **Duración**: 3-4 horas
- 🎯 **Nivel**: Básico (no necesitas ser experto en Azure)
- 🎓 **Aprenderás**: Vibe Coding profesional con Azure_Architect_Pro
- 🔧 **Generarás**: Arquitectura, Bicep, CI/CD, Monitoring, todo automático

**Lo que cubre:**
- 🏗️ Architecture Design Documents (Azure Well-Architected)
- 💰 Análisis FinOps con informes HTML antes de desplegar
- 🔧 Código Bicep modular generado por IA
- 🚀 CI/CD con GitHub Actions y OIDC (secretless)
- 🔒 Security by design (Private Endpoints, Managed Identities)
- 📊 Observabilidad enterprise (Application Insights, dashboards)
- ✅ Testing y validación completa

**[👉 Comenzar Workshop →](./workshop/kitten-space-missions/activity-01-setup.md)**

---

## ⚙️ Configuración Inicial

Si es tu primera vez, necesitas configurar los MCP Servers:

### 📘 [Guía de Setup MCP](./getting-started/mcp-quickstart.md)

**Tiempo estimado:** 10-15 minutos

Los MCP (Model Context Protocol) Servers permiten al agente acceder a:
- ✅ Recursos de Azure en tiempo real
- ✅ Repositorios de GitHub
- ✅ Sistema de archivos del proyecto
- ✅ Documentación web de Azure
- ✅ Contexto persistente entre sesiones

---

## 📖 Referencias Rápidas

### Cheatsheets para consulta rápida:

| Cheatsheet | Descripción | Líneas |
|------------|-------------|--------|
| [Azure CLI](./reference/azure-cli-cheatsheet.md) | Comandos Azure CLI organizados por categoría | 711 |
| [Bicep](./reference/bicep-cheatsheet.md) | Sintaxis Bicep y patrones comunes | 1,165 |
| [MCP Servers](./reference/mcp-servers-cheatsheet.md) | Uso avanzado de MCP servers | 1,059 |

---

## 🤖 ¿Qué es Azure_Architect_Pro?

**Azure_Architect_Pro** es un agente de IA personalizado que actúa como tu **Arquitecto Azure Senior personal**.

### Diferencias vs GitHub Copilot estándar:

| Característica | Copilot Base | Azure_Architect_Pro |
|----------------|--------------|---------------------|
| **Instrucciones** | Genéricas | Miles de líneas especializadas en Azure |
| **Metodología** | Ninguna | Azure Well-Architected Framework |
| **FinOps** | No | Análisis de costos integrado |
| **MCP Servers** | No | 6 servidores especializados |
| **Contexto Azure** | Limitado | Acceso directo a recursos Azure |
| **Bicep** | Sintaxis básica | Generación modular con best practices |

### Los 6 MCP Servers especializados:

1. **azure-mcp** - Acceso a recursos Azure (VNets, NSGs, Key Vaults, etc.)
2. **bicep-mcp** - Validación y generación de Bicep siguiendo patrones
3. **github-mcp** - Gestión de repos, issues, PRs y workflows
4. **filesystem-mcp** - Navegación inteligente del código del proyecto
5. **brave-search-mcp** - Búsqueda de documentación oficial y comunidad
6. **memory-mcp** - Contexto persistente entre sesiones

---

## 🎯 ¿Para quién es este proyecto?

### Ideal para:

- 👨‍💻 **Desarrolladores** que quieren aprender Azure sin memorizar sintaxis
- 🏢 **IT Admins** que necesitan automatizar infraestructura
- 🎓 **Estudiantes** que buscan proyectos prácticos para su portfolio
- 🚀 **Cloud Architects** que quieren explorar IA en IaC
- 💼 **Equipos enterprise** buscando adoptar Vibe Coding

### No necesitas:

- ❌ Ser experto en Azure
- ❌ Saber Bicep de memoria
- ❌ Conocer comandos Azure CLI
- ❌ Experiencia previa con IaC

### Solo necesitas:

- ✅ Curiosidad y ganas de aprender
- ✅ GitHub Copilot (Individual, Business o Enterprise)
- ✅ Azure subscription (free trial funciona)
- ✅ VS Code instalado

---

## 🛠️ Arquitectura del Proyecto

```
azure-agent-pro/
├── docs/                    # 📚 Documentación (estás aquí)
│   ├── getting-started/     # ⚙️ Setup inicial
│   ├── reference/           # 📖 Cheatsheets
│   └── workshop/            # 🎓 Workshop principal
│
├── bicep/                   # 🔧 Módulos Bicep reutilizables
│   ├── modules/             # Componentes (vnet, nsg, keyvault, etc.)
│   └── parameters/          # Parámetros por entorno (dev, prod)
│
├── scripts/                 # 🤖 Scripts de automatización
│   ├── deploy/              # Deployment y validación
│   ├── config/              # Configuración de Azure
│   └── utils/               # Utilidades (RBAC, FinOps, etc.)
│
├── .github/workflows/       # 🚀 CI/CD con GitHub Actions
│
└── mcp.json                 # ⚡ Configuración de MCP Servers
```

---

## 🌟 Características Principales

### 1. Vibe Coding Profesional

Describe lo que necesitas en lenguaje natural → el agente diseña e implementa → tú validas y aprendes.

**Ejemplo:**
```
"Diseña una arquitectura Azure para una API REST con:
- Alta disponibilidad
- Security by design
- Optimizada para costos en dev
- Con monitorización completa"
```

El agente genera:
- Architecture Design Document completo
- Análisis de costos con alternativas de SKUs
- Código Bicep modular
- Pipelines CI/CD
- Configuración de seguridad y monitoring

### 2. Azure Well-Architected Framework

Todas las arquitecturas siguen los 5 pilares:
- 🛡️ **Reliability** - Multi-zone, health probes, auto-healing
- 🔒 **Security** - Zero Trust, Private Endpoints, Managed Identities
- 💰 **Cost Optimization** - Right-sizing, reservas, auto-scaling
- ⚙️ **Operational Excellence** - IaC, GitOps, automated testing
- ⚡ **Performance Efficiency** - Caching, CDN, async processing

### 3. FinOps Desde el Diseño

Análisis de costos **ANTES** de desplegar:
- Estimación mensual por entorno
- Comparativa de SKUs
- Oportunidades de optimización
- Budget alerts recomendados

### 4. Security by Default

Toda infraestructura incluye:
- Private Endpoints para servicios PaaS
- Managed Identities (no secrets hardcodeados)
- NSGs con least privilege
- TLS 1.2+ obligatorio
- Key Vault para secretos
- Azure Policy enforcement

### 5. DevOps & GitOps

CI/CD completo con:
- GitHub Actions workflows
- OIDC authentication (secretless)
- Multi-stage deployments (dev → test → prod)
- Approval gates para producción
- Rollback automático en failures
- Security scanning integrado

---

## 📊 Métricas del Proyecto

- 📄 **10,368 líneas** de documentación
- 🎓 **8 actividades** progresivas en el workshop
- 🔧 **15+ módulos** Bicep reutilizables
- 🤖 **6 MCP Servers** especializados
- ⏱️ **3-4 horas** para completar el workshop
- 💰 **~$40-50/mes** costo estimado infra dev
- ⭐ **100% gratuito** y open source

---

## 🤝 Contribuir

¿Quieres mejorar el proyecto?

1. 🐛 [Reportar un problema](https://github.com/Alejandrolmeida/azure-agent-pro/issues/new?labels=bug)
2. 💡 [Sugerir mejora](https://github.com/Alejandrolmeida/azure-agent-pro/issues/new?labels=enhancement)
3. 🔀 [Abrir Pull Request](https://github.com/Alejandrolmeida/azure-agent-pro/pulls)
4. ⭐ [Star en GitHub](https://github.com/Alejandrolmeida/azure-agent-pro)

---

## 📞 Soporte y Comunidad

**¿Dudas o problemas?**

1. Consulta las secciones de **Troubleshooting** en el workshop
2. Revisa los [Issues cerrados](https://github.com/Alejandrolmeida/azure-agent-pro/issues?q=is%3Aissue+is%3Aclosed) por si ya está resuelto
3. Abre un [nuevo Issue](https://github.com/Alejandrolmeida/azure-agent-pro/issues/new)
4. Comparte tu experiencia en LinkedIn etiquetando [@alejandrolmeida](https://www.linkedin.com/in/alejandrolmeida/)

---

## 📜 Licencia

Este proyecto es **open source** bajo licencia MIT. Puedes:
- ✅ Usar en proyectos personales y comerciales
- ✅ Modificar y adaptar el código
- ✅ Compartir y distribuir
- ✅ Crear workshops derivados

---

## 🎉 ¡Comienza tu Aventura!

**[🚀 Ir al Workshop: Kitten Space Missions →](./workshop/kitten-space-missions/)**

*Construye infraestructura Azure enterprise mientras te diviertes con gatitos astronautas. Porque aprender no tiene que ser aburrido.* 🐱✨

---

## 🗂️ Contenido Archivado

Si buscas documentación anterior:
- [Workshops deprecados](./workshop/archived/)
- [Learning paths antiguos](./workshop/archived/old-learning-paths/)
- [Tutoriales antiguos](./workshop/archived/old-tutorials/)

**Nota:** Este contenido se mantiene por referencia histórica pero no recibe actualizaciones. Se recomienda usar el workshop actual.
