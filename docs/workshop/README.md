![Kitten Space Missions - Workshop Header](./kitten-space-missions/assets/workshop-hero.png)

# Workshops - Azure Agent Pro

Aprende **Vibe Coding profesional** con Azure usando el agente personalizado **Azure_Architect_Pro** a través de workshops prácticos y divertidos.

---

## Workshop Principal: Kitten Space Missions API

**👉 [Comenzar Workshop](./kitten-space-missions/)**

Construye una API REST completa para gestionar misiones espaciales de gatitos astronautas mientras aprendes:

- Arquitectura Azure siguiendo Well-Architected Framework
- Análisis FinOps con informes HTML profesionales
- Código Bicep modular generado por IA
- CI/CD con GitHub Actions y OIDC
- Observabilidad enterprise con Application Insights
- Testing y validación completa

**Nivel:** Básico 
**Duración:** 3-4 horas 
**Requisitos:** Azure subscription, GitHub Copilot, VS Code

### ¿Por qué este workshop?

 **Divertido y memorable** - Gatitos en el espacio (pero infraestructura Azure real) 
 **Progresivo** - 8 actividades de simple a complejo 
 **Vibe Coding** - El agente hace el trabajo pesado, tú aprendes la estrategia 
 **Production-ready** - Código y prácticas aplicables a proyectos reales 
🆓 **Gratuito y open source** - Todo el contenido disponible

---

## Contenido Archivado

### ⚠️ Workshops Deprecados

El siguiente contenido ha sido archivado y reemplazado por material de mayor calidad:

• [Azure Networking con GitHub Copilot](./archived/networking-advanced/) - **DEPRECATED** 
 → Reemplazado por Kitten Space Missions (cubre los mismos conceptos de forma más didáctica)

---

## Empezar Ahora

### Opción 1: Workshop Completo (Recomendado)

```bash
# 1. Fork y clona el repositorio
git clone https://github.com/TU-USUARIO/azure-agent-pro.git
cd azure-agent-pro

# 2. Sigue el workshop paso a paso
# 👉 docs/workshop/kitten-space-missions/README.md
```

**[ Ir a Activity 1: Setup →](./kitten-space-missions/activity-01-setup.md)**

### Opción 2: Explorar el Proyecto

Si prefieres explorar primero:

- 📖 [Documentación del Proyecto](../../README.md)
- [Tutoriales](../tutorials/)
- [Learning Paths](../learning-paths/)
- [MCP Quickstart](../MCP_QUICKSTART.md)

---

## ¿Qué aprenderás?

Al completar el workshop de Kitten Space Missions dominarás:

### Habilidades Técnicas
- **Vibe Coding** - Comunicación efectiva con agentes IA
- **Azure Well-Architected** - Diseño siguiendo los 5 pilares
- **Bicep IaC** - Infraestructura como código modular
- **FinOps** - Optimización de costos desde el diseño
- **DevOps** - CI/CD con GitHub Actions y OIDC
- **Security** - Zero Trust, Private Endpoints, Managed Identities
- **Observability** - Application Insights, KQL, dashboards

### Servicios Azure
- 🌐 **Networking** - VNet, NSG, Private Endpoints
- 💾 **Data** - Azure SQL Database con TDE
- 🔐 **Security** - Key Vault, Managed Identities
- **Compute** - App Service con auto-scaling
- **Monitoring** - Application Insights, Log Analytics
- 🔄 **Automation** - GitHub Actions, OIDC authentication

---

## Recursos Complementarios

### Documentación
- 📖 [MCP Quickstart Guide](../MCP_QUICKSTART.md)
- 📘 [Azure CLI Cheatsheet](../cheatsheets/azure-cli-cheatsheet.md)
- 📗 [Bicep Cheatsheet](../cheatsheets/bicep-cheatsheet.md)
- 📙 [MCP Servers Cheatsheet](../cheatsheets/mcp-servers-cheatsheet.md)

### Learning Paths
- [Azure Professional Management](../learning-paths/azure-professional-management.md)
- [GitHub Copilot para Azure](../learning-paths/github-copilot-azure.md)

### Tutoriales
- [AI-Enhanced Azure Development](../tutorials/ai-enhanced-azure-development.md)

---

## 🐛 Troubleshooting Común

### MCP Servers no aparecen

```bash
# Ejecutar setup de MCP
./scripts/setup/mcp-setup.sh

# Reiniciar VS Code completamente
# Ctrl+Shift+P → "Developer: Reload Window"
```

### Error de autenticación en Azure

```bash
# Re-autenticar con Azure CLI
az login

# Verificar cuenta activa
az account show
```

### Problemas al desplegar recursos

```bash
# Verificar permisos
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Verificar cuotas disponibles
az vm list-usage --location westeurope -o table
```

**📖 Más troubleshooting**: Cada actividad del workshop incluye su propia sección de resolución de problemas.

---

## 🤝 Contribuir

¿Encontraste un error o tienes una sugerencia para mejorar el workshop?

1. 🐛 [Reportar un problema](https://github.com/Alejandrolmeida/azure-agent-pro/issues/new?labels=workshop,bug)
2. [Sugerir mejora](https://github.com/Alejandrolmeida/azure-agent-pro/issues/new?labels=workshop,enhancement)
3. 🔀 [Abrir Pull Request](https://github.com/Alejandrolmeida/azure-agent-pro/pulls)

---

## 📞 Soporte y Comunidad

**¿Preguntas durante el workshop?**

1. Consulta la sección de **Troubleshooting** en cada actividad
2. Revisa los **Entregables** para verificar que estás en el camino correcto
3. Abre un [Issue en GitHub](https://github.com/Alejandrolmeida/azure-agent-pro/issues)
4. Comparte tu experiencia en LinkedIn etiquetando [@alejandrolmeida](https://www.linkedin.com/in/alejandrolmeida/)

---

## ¡Comienza tu Aventura Espacial!

**[ Empezar Workshop: Kitten Space Missions →](./kitten-space-missions/)**

---

*Construye infraestructura Azure de calidad enterprise mientras te diviertes con gatitos astronautas. Porque aprender no tiene que ser aburrido.* 

