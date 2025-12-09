# 🚀🐱 Workshop: Kitten Space Missions API

**Duración total**: 3-4 horas  
**Nivel**: Básico  
**Objetivo**: Aprender **Vibe Coding profesional** con Azure Agent Pro desplegando una API divertida de misiones espaciales de gatitos

---

## 🎯 ¿Qué vas a aprender?

En este workshop aprenderás a trabajar como un profesional usando **Vibe Coding** con el agente personalizado **Azure_Architect_Pro**. No escribirás infraestructura manualmente: el agente será tu arquitecto de soluciones Azure que te ayudará a:

- 🏗️ Diseñar arquitecturas siguiendo Azure Well-Architected Framework
- 💰 Realizar análisis FinOps con informes HTML detallados antes de desplegar
- 🔧 Generar código Bicep modular y reutilizable
- 🚀 Crear pipelines CI/CD con GitHub Actions
- 📊 Configurar monitoreo y observabilidad enterprise
- ✅ Validar todo siguiendo las mejores prácticas de Azure

**Lo más importante**: Aprenderás a comunicarte eficientemente con el agente para que realice sesiones largas de trabajo sin interrupciones constantes.

---

## 📦 ¿Qué vamos a construir?

Una **API REST de Misiones Espaciales de Gatitos** (Kitten Space Missions) con:

### Endpoints de la API:
- `GET /api/missions` - Listar todas las misiones espaciales
- `POST /api/missions` - Registrar nueva misión
- `GET /api/astronauts` - Listar astronautas felinos
- `POST /api/astronauts` - Registrar nuevo astronauta gatuno
- `GET /api/telemetry` - Consultar telemetría de misiones

### Arquitectura Azure:
- ☁️ Azure App Service (API hosting)
- 🗄️ Azure SQL Database (datos de misiones y astronautas)
- 🔐 Azure Key Vault (gestión de secretos)
- 📊 Application Insights (monitoreo)
- 🌐 Virtual Network con Private Endpoints
- 🔒 Managed Identities (sin contraseñas)

Todo desplegado con **Bicep** y automatizado con **GitHub Actions**.

---

## 📋 Requisitos previos

Antes de empezar necesitas:

- ✅ **GitHub Account** - Para fork del repositorio
- ✅ **Azure Subscription** - Con permisos Contributor (puedes usar [Azure Free Account](https://azure.microsoft.com/free/))
- ✅ **VS Code** instalado con extensiones:
  - GitHub Copilot
  - Azure Tools
  - Bicep
- ✅ **Sistema Linux o WSL2** - Para ejecutar scripts bash
- ✅ **Azure CLI** instalado y configurado
- ✅ Conocimientos básicos de:
  - Git y GitHub
  - Línea de comandos bash
  - Conceptos básicos de Azure (resource groups, etc.)

---

## 🗓️ Actividades del Workshop

Este workshop está dividido en **8 actividades** progresivas. Cada actividad incluye tiempo estimado, objetivos y entregables.

| # | Actividad | Duración | Objetivos |
|---|-----------|----------|-----------|
| 1 | [Setup Inicial del Entorno](./activity-01-setup.md) | 30 min | Fork repo, clonar, configurar entorno Linux/WSL, preparar agente |
| 2 | [Primera Conversación con el Agente](./activity-02-first-conversation.md) | 30 min | Aprender a comunicarse con Azure_Architect_Pro, pedir diseño arquitectónico |
| 3 | [Análisis FinOps Previo al Despliegue](./activity-03-finops-analysis.md) | 30 min | Generar informe HTML con estimación de costos de infraestructura |
| 4 | [Generación de Código Bicep](./activity-04-bicep-generation.md) | 45 min | Crear módulos Bicep modulares y parametrizados |
| 5 | [Configuración CI/CD](./activity-05-cicd-setup.md) | 30 min | Workflows de GitHub Actions con OIDC |
| 6 | [Despliegue en Azure](./activity-06-azure-deployment.md) | 45 min | Deploy de infraestructura y validación |
| 7 | [Monitoreo y Observabilidad](./activity-07-monitoring.md) | 20 min | Application Insights, alerts, dashboards |
| 8 | [Testing y Validación](./activity-08-testing.md) | 20 min | Smoke tests, health checks, validación endpoints |

**Total**: ~3h 30min (puede variar según tu ritmo)

---

## 🎓 Metodología: Vibe Coding Profesional

### ¿Qué es Vibe Coding?

Es una forma de trabajar donde **describes tu intención al agente en lenguaje natural** y él se encarga de implementar siguiendo las mejores prácticas. En lugar de escribir código línea por línea, mantienes una conversación profesional con el agente.

### Principios clave del workshop:

1. **🗣️ Comunicación clara con el agente**
   - Sé específico pero no microgestiones
   - Da contexto (cliente, entorno, compliance)
   - Confía pero verifica

2. **🔄 Iteración rápida**
   - Valida cada paso
   - Ajusta según necesites
   - Aprende de las respuestas del agente

3. **🛠️ Automatización total**
   - Bicep sobre Azure Portal
   - GitHub Actions sobre comandos manuales
   - Scripts sobre clicks

4. **✅ Well-Architected desde día 1**
   - Seguridad por defecto
   - FinOps desde el diseño
   - Observabilidad integrada

---

## 💡 Tips para sesiones largas con el agente

Para que el agente trabaje de forma autónoma sin interrupciones:

### ✅ DO (Hacer):
- "Diseña, genera el código Bicep, crea los workflows de CI/CD y actualiza la documentación para esta API"
- "Incluye todos los parámetros por entorno (dev/prod) y sigue las convenciones del repo"
- "Valida todo con what-if y genera el informe de costos antes de desplegar"

### ❌ DON'T (Evitar):
- "¿Qué opinas sobre usar App Service?" (decisiones abiertas que requieren tu input)
- Peticiones ambiguas sin contexto
- Preguntar paso por paso cuando puedes pedir todo junto

### 🎯 Contexto que debes dar siempre:
- **Cliente/Proyecto**: "Kitten Space Missions para cliente Meowtech"
- **Entorno**: "dev" o "prod"
- **Compliance**: Si aplica (GDPR, etc.)
- **Budget**: Si hay restricciones de costo

---

## 📂 Estructura de archivos del proyecto

Al finalizar el workshop, tu carpeta `docs/workshop/kitten-space-missions/` tendrá:

```
kitten-space-missions/
├── README.md                      # Este archivo
├── activity-01-setup.md           # Actividad 1
├── activity-02-first-conversation.md  # Actividad 2
├── activity-03-finops-analysis.md # Actividad 3
├── activity-04-bicep-generation.md  # Actividad 4
├── activity-05-cicd-setup.md      # Actividad 5
├── activity-06-azure-deployment.md  # Actividad 6
├── activity-07-monitoring.md      # Actividad 7
├── activity-08-testing.md         # Actividad 8
└── solution/                      # Código generado durante el workshop
    ├── bicep/
    │   ├── main.bicep
    │   ├── modules/
    │   └── parameters/
    ├── .github/
    │   └── workflows/
    ├── scripts/
    ├── src/                       # Código API (opcional)
    └── docs/
        └── finops-report.html
```

---

## 🚀 ¡Comienza ahora!

**Paso siguiente**: Ve a la [Actividad 1: Setup Inicial del Entorno](./activity-01-setup.md)

---

## 📚 Recursos adicionales

- [Documentación Azure Agent Pro](../../README.md)
- [MCP Quickstart](../../MCP_QUICKSTART.md)
- [Azure CLI Cheatsheet](../../cheatsheets/azure-cli-cheatsheet.md)
- [Bicep Cheatsheet](../../cheatsheets/bicep-cheatsheet.md)

---

## 🤝 ¿Necesitas ayuda?

- 📖 Consulta la documentación del proyecto
- 💬 Pregunta al agente Azure_Architect_Pro
- 🐛 Reporta issues en el repositorio
- 📧 Contacta al equipo de Azure Agent Pro

---

**¡Que disfrutes construyendo tu API de gatitos astronautas! 🐱🚀✨**
