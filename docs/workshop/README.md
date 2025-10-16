# 🎓 Workshop: Azure Networking con GitHub Copilot

Materiales y recursos para el workshop de 4 horas orientado a administradores de Azure especializados en Networking (AZ-104 y AZ-700).

---

## 📂 Contenido

### 📄 Documentos Principales

• [WORKSHOP_NETWORKING.md](WORKSHOP_NETWORKING.md): Guía completa del workshop con todos los módulos y ejercicios
• [solutions/SOLUTIONS.md](solutions/SOLUTIONS.md): Soluciones de referencia para los ejercicios
• [QUICKSTART.md](QUICKSTART.md): Guía de inicio rápido (15 minutos)
• [CHECKLIST.md](CHECKLIST.md): Checklist de preparación y verificación

### 🛠️ Scripts Auxiliares

• Scripts de generación de topologías de red de ejemplo
• Plantillas Bicep de referencia
• Scripts de diagnóstico y troubleshooting

---

## 🚀 Cómo Usar Este Material

### Para Instructores

1. **Preparación Previa:**

   ```bash
   # Clonar repositorio
   git clone https://github.com/alejandrolmeida/azure-agent-pro.git
   cd azure-agent-pro

   # Ejecutar setup inicial
   ./scripts/setup/initial-setup.sh

   # Configurar MCP servers
   ./scripts/setup/mcp-setup.sh
   ```

2. **Revisión del Material:**

   • Lee `WORKSHOP_NETWORKING.md` para familiarizarte con la estructura
   • Revisa las soluciones en `solutions/SOLUTIONS.md`
   • Prueba los ejercicios tú mismo antes del workshop

3. **Durante el Workshop:**

   • Sigue la agenda de 5 módulos (4 horas)
   • Fomenta que los participantes usen GitHub Copilot con MCP servers
   • Haz checkpoints al final de cada módulo

### Para Participantes

1. **Antes del Workshop:**

   • Completa el setup inicial: `./scripts/setup/initial-setup.sh`
   • Verifica que GitHub Copilot funciona
   • Lee los requisitos previos en `WORKSHOP_NETWORKING.md`

2. **Durante el Workshop:**

   • Sigue las instrucciones del instructor
   • Experimenta con diferentes prompts en Copilot
   • No dudes en consultar las soluciones si te quedas atascado

3. **Después del Workshop:**

   • Revisa las soluciones completas
   • Experimenta con variaciones de los ejercicios
   • Aplica lo aprendido en tus propios proyectos

---

## 📊 Estructura de Módulos

| Módulo | Duración | Tema |
|--------|----------|------|
| 1 | 30 min | Setup y Verificación de MCP Servers |
| 2 | 60 min | Diseño de Redes y Arquitecturas Hub-Spoke |
| 3 | 60 min | Seguridad de Red (NSG, Azure Firewall, DDoS) |
| 4 | 60 min | Conectividad Híbrida (VPN, ExpressRoute) |
| 5 | 30 min | Monitorización y Troubleshooting |

**Total:** 4 horas

---

## 🎯 Objetivos de Aprendizaje

Al finalizar el workshop, los participantes sabrán:

• ✅ Configurar y usar MCP servers con GitHub Copilot para Azure
• ✅ Diseñar arquitecturas de red hub-spoke con Bicep
• ✅ Implementar seguridad de red con NSG y Azure Firewall
• ✅ Configurar conectividad híbrida con VPN Gateway y ExpressRoute
• ✅ Implementar monitorización con Network Watcher
• ✅ Automatizar despliegues de infraestructura con GitHub Actions

---

## 📚 Recursos Adicionales

• [Documentación MCP](../MCP_SETUP_GUIDE.md)
• [Cheatsheet de Azure CLI](../cheatsheets/azure-cli-cheatsheet.md)
• [Cheatsheet de Bicep](../cheatsheets/bicep-cheatsheet.md)
• [Learning Path: Azure Professional Management](../learning-paths/azure-professional-management.md)
• [Learning Path: GitHub Copilot para Azure](../learning-paths/github-copilot-azure.md)

---

## 🐛 Troubleshooting

### Problema: "Los servidores MCP no aparecen"

**Solución:**

```bash
# Ejecutar setup de MCP
./scripts/setup/mcp-setup.sh

# Reiniciar VS Code
# Ctrl+Shift+P → "Developer: Reload Window"
```

### Problema: "Error de autenticación en Azure"

**Solución:**

```bash
# Re-autenticar con Azure CLI
az login

# Verificar credenciales en .env
cat .env | grep AZURE
```

### Problema: "No puedo desplegar recursos de red"

**Solución:**

```bash
# Verificar permisos en la suscripción
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Verificar límites de cuota
az network vnet list --query "[].{Name:name, Region:location}" -o table
```

---

## 📞 Soporte

¿Problemas durante el workshop?

1. Consulta la sección de Troubleshooting en `WORKSHOP_NETWORKING.md`
2. Revisa las soluciones en `solutions/SOLUTIONS.md`
3. Abre un issue en GitHub

**¡Disfruta aprendiendo Azure Networking con GitHub Copilot! 🚀**
