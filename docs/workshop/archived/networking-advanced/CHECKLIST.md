# Checklist del Workshop - Azure Networking con GitHub Copilot

Usa este checklist para asegurar que tienes todo listo antes, durante y después del workshop.

---

## Pre-Workshop (Completar antes del día del workshop)

### Configuración de Entorno

- [ ] Visual Studio Code instalado (versión más reciente)
- [ ] GitHub Copilot activo (licencia válida)
- [ ] Azure CLI instalado (versión 2.55+)
- [ ] Git instalado y configurado
- [ ] Node.js 20+ instalado (para MCP servers)
- [ ] Navegador web moderno (Chrome, Edge, Firefox)

### Setup del Proyecto

- [ ] Repositorio clonado: `git clone https://github.com/alejandrolmeida/azure-agent-pro.git`
- [ ] Script de setup ejecutado: `./scripts/setup/initial-setup.sh`
- [ ] Archivo `.env` creado con credenciales de Azure
- [ ] Azure Service Principal creado (opcional para CI/CD)
- [ ] GitHub Token configurado (para MCP servers)
- [ ] MCP servers configurados: `./scripts/setup/mcp-setup.sh`
- [ ] VS Code reiniciado después del setup de MCP

### Verificación

- [ ] Azure CLI funciona: `az --version`
- [ ] Autenticado en Azure: `az login` y `az account show`
- [ ] GitHub Copilot responde en VS Code
- [ ] MCP servers cargados (6 servidores)
- [ ] Permisos verificados: Contributor o Network Contributor
- [ ] Cuota disponible para crear recursos de red

---

## Durante el Workshop

### Módulo 1: Setup y Verificación MCP (30 min)

**Ejercicios:**

- [ ] 1.1.1: Verificar servidores MCP en Copilot
- [ ] 1.1.2: Probar Azure MCP
- [ ] 1.1.3: Probar Bicep MCP
- [ ] 1.2.1: Azure Resource Explorer
- [ ] 1.2.2: Búsqueda de documentación
- [ ] 1.2.3: Context awareness

**Checkpoint:**

- [ ] Todos los 6 servidores MCP funcionan
- [ ] Copilot responde con contexto de Azure

---

### Módulo 2: Diseño de Redes Hub-Spoke (60 min)

**Ejercicios:**

- [ ] 2.1.1: Diseño de arquitectura hub-spoke
- [ ] 2.1.2: Cálculo de direccionamiento IP
- [ ] 2.2.1: Crear módulo de VNET Hub
- [ ] 2.2.2: Crear módulo de VNET Spoke
- [ ] 2.2.3: Orquestación con main.bicep
- [ ] 2.3.1: Desplegar infraestructura
- [ ] 2.3.2: Verificar conectividad

**Checkpoint:**

- [ ] Arquitectura hub-spoke desplegada en Azure
- [ ] Peering bidireccional configurado
- [ ] Sin overlapping de rangos IP
- [ ] Subnets correctamente creadas

---

### Módulo 3: Seguridad de Red (60 min)

**Ejercicios:**

- [ ] 3.1.1: NSG para aplicación de 3 capas
- [ ] 3.1.2: Reglas de servicio en NSG
- [ ] 3.1.3: NSG Flow Logs
- [ ] 3.2.1: Desplegar Azure Firewall
- [ ] 3.2.2: Reglas de firewall (Network, Application, DNAT)
- [ ] 3.2.3: Route Tables
- [ ] 3.3.1: Habilitar DDoS Protection
- [ ] 3.3.2: Application Gateway con WAF

**Checkpoint:**

- [ ] NSGs aplicados a todas las subnets relevantes
- [ ] Azure Firewall desplegado y configurado
- [ ] Tráfico forzado por el firewall (route tables)
- [ ] DDoS Protection habilitado

---

### 🌐 Módulo 4: Conectividad Híbrida (60 min)

**Ejercicios:**

- [ ] 4.1.1: VPN Gateway desplegado
- [ ] 4.1.2: Local Network Gateway configurado
- [ ] 4.1.3: VPN Connection creada
- [ ] 4.1.4: Route Propagation configurada
- [ ] 4.2.1: Point-to-Site VPN configurado
- [ ] 4.2.2: Conditional Access (diseño)
- [ ] 4.3.1: ExpressRoute Gateway (diseño)
- [ ] 4.3.2: ExpressRoute Circuit (documentación)

**Checkpoint:**

- [ ] VPN Gateway operativo
- [ ] Comprensión de conectividad híbrida
- [ ] BGP configurado (si aplica)
- [ ] Documentación de diseño completa

---

### Módulo 5: Monitorización y Troubleshooting (30 min)

**Ejercicios:**

- [ ] 5.1.1: Network Watcher habilitado
- [ ] 5.1.2: Topology y Connectivity verificados
- [ ] 5.1.3: Traffic Analytics configurado
- [ ] 5.2.1: Log Analytics Workspace creado
- [ ] 5.2.2: Queries KQL funcionando
- [ ] 5.2.3: Alertas proactivas configuradas

**Checkpoint:**

- [ ] Network Watcher activo en todas las regiones
- [ ] Logs fluyendo a Log Analytics
- [ ] Dashboards y workbooks creados
- [ ] Alertas configuradas y testeadas

---

## 🎁 Ejercicios Bonus (Opcional)

- [ ] Bonus 1: GitHub Actions workflow creado
- [ ] Bonus 2: Azure Policies definidas
- [ ] Despliegue multi-ambiente (dev/prod)
- [ ] Tests automatizados de post-deployment

---

## Post-Workshop (Para reforzar aprendizaje)

### Revisión

- [ ] Revisar todas las soluciones en `solutions/SOLUTIONS.md`
- [ ] Comparar tu código con las soluciones de referencia
- [ ] Identificar áreas de mejora

### 🔄 Práctica Adicional

- [ ] Desplegar la infraestructura en un ambiente de prueba nuevo
- [ ] Experimentar con variaciones de diseño
- [ ] Añadir recursos adicionales (Azure Bastion, VPN P2S, etc.)
- [ ] Implementar el workflow de CI/CD

### Estudio Adicional

- [ ] Repasar documentación de Azure Networking
- [ ] Revisar learning paths:
 - [ ] [Azure Professional Management](../learning-paths/azure-professional-management.md)
 - [ ] [GitHub Copilot para Azure](../learning-paths/github-copilot-azure.md)
- [ ] Estudiar para certificaciones:
 - [ ] AZ-104: Azure Administrator
 - [ ] AZ-700: Azure Networking Solutions

### 💬 Compartir

- [ ] Publicar tu proyecto en GitHub
- [ ] Compartir feedback del workshop
- [ ] Contribuir mejoras al repositorio
- [ ] Ayudar a otros participantes

---

## Objetivos de Aprendizaje Cumplidos

Marca los objetivos que hayas logrado:

- [ ] Configurar MCP servers con GitHub Copilot
- [ ] Diseñar arquitecturas hub-spoke
- [ ] Implementar seguridad de red multinivel
- [ ] Configurar conectividad híbrida
- [ ] Implementar monitorización de red
- [ ] Automatizar despliegues con IaC
- [ ] Usar Bicep para infraestructura compleja
- [ ] Aplicar mejores prácticas de Azure

---

## Autoevaluación

Califica tu nivel de confianza (1-5) en cada área:

| Área | Antes | Después |
|------|-------|---------|
| GitHub Copilot con MCP | __/5 | __/5 |
| Diseño de redes Azure | __/5 | __/5 |
| Seguridad de red | __/5 | __/5 |
| Conectividad híbrida | __/5 | __/5 |
| Monitorización | __/5 | __/5 |
| Bicep / IaC | __/5 | __/5 |

---

## Próximos Pasos

### Certificaciones

- [ ] Registrarse para examen AZ-104
- [ ] Registrarse para examen AZ-700
- [ ] Completar learning paths de Microsoft Learn

### Proyectos Personales

- [ ] Implementar arquitectura hub-spoke en proyecto real
- [ ] Crear biblioteca personal de módulos Bicep
- [ ] Automatizar más tareas con GitHub Actions

### Comunidad

- [ ] Unirse a comunidades de Azure en Discord/Slack
- [ ] Seguir blogs de Azure Networking
- [ ] Asistir a meetups locales de Azure

---

## 📞 Recursos de Ayuda

- 📖 [Documentación del Workshop](WORKSHOP_NETWORKING.md)
- [Soluciones de Referencia](solutions/SOLUTIONS.md)
- [Quick Start Guide](QUICKSTART.md)
- 🐛 [Issues de GitHub](https://github.com/alejandrolmeida/azure-agent-pro/issues)

---

**¡Éxito en tu aprendizaje de Azure Networking! **

