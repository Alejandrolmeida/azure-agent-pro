# 💬 Actividad 2: Primera Conversación con el Agente

**⏱️ Duración estimada**: 30 minutos  
**🎯 Objetivo**: Aprender a comunicarte eficientemente con Azure_Architect_Pro para obtener un diseño arquitectónico profesional de la API de Kitten Space Missions

---

## 📋 Objetivos de aprendizaje

Al finalizar esta actividad serás capaz de:

1. ✅ Iniciar conversaciones efectivas con el agente Azure_Architect_Pro
2. ✅ Proporcionar el contexto adecuado para obtener mejores resultados
3. ✅ Solicitar Architecture Design Documents (ADD) completos
4. ✅ Revisar y validar propuestas arquitectónicas
5. ✅ Entender los principios de Well-Architected Framework aplicados

---

## 🎭 Contexto del Proyecto

Antes de hablar con el agente, define claramente qué vas a construir:

### Proyecto: Kitten Space Missions API

**Cliente ficticio**: MeowTech Space Agency  
**Proyecto**: Sistema de gestión de misiones espaciales tripuladas por astronautas felinos  
**Entorno inicial**: Desarrollo (dev)  
**Compliance**: Ninguno específico (proyecto educativo)  
**Budget**: Mínimo viable (~$50-100/mes en dev)

### Requisitos funcionales:

1. **API REST** con los siguientes endpoints:
   - `GET /api/missions` - Listar misiones espaciales
   - `POST /api/missions` - Crear nueva misión
   - `GET /api/missions/{id}` - Obtener detalle de misión
   - `PUT /api/missions/{id}` - Actualizar misión
   - `DELETE /api/missions/{id}` - Cancelar misión
   - `GET /api/astronauts` - Listar astronautas gatunos
   - `POST /api/astronauts` - Registrar nuevo astronauta
   - `GET /api/astronauts/{id}` - Detalle de astronauta
   - `GET /api/telemetry` - Telemetría de misiones activas
   - `GET /health` - Health check del servicio

2. **Base de datos** para almacenar:
   - Misiones (id, nombre, fecha_lanzamiento, destino, estado)
   - Astronautas (id, nombre, raza, misiones_completadas, certificaciones)
   - Telemetría (timestamp, misión_id, altitud, velocidad, temperatura)

3. **Seguridad**:
   - HTTPS obligatorio
   - Autenticación con API Key
   - Secretos en Key Vault
   - Sin acceso público directo a BD

### Requisitos no funcionales:

- **Performance**: < 200ms latency p95
- **Availability**: 99% (dev), 99.9% (prod futuro)
- **Scalability**: Auto-scaling 1-3 instancias en dev
- **Observability**: Logging y métricas completos
- **Cost**: Optimizado para dev (SKUs básicos)

---

## 🗣️ Paso 1: Estructura de una Petición Efectiva al Agente

### Anatomía de un buen prompt para el agente

Una petición efectiva tiene estos componentes:

```
[CONTEXTO] + [OBJETIVO] + [REQUISITOS] + [RESTRICCIONES] + [ENTREGABLES]
```

### ❌ MAL Ejemplo (demasiado vago):

```
Quiero desplegar una API en Azure
```

**Problema**: Falta contexto, requisitos, no especifica qué tecnologías, entornos, etc.

### ✅ BUEN Ejemplo (completo y contextualizado):

```
Proyecto: API de Kitten Space Missions para cliente MeowTech Space Agency

CONTEXTO:
- Entorno: dev (producción será futuro)
- Tenant/Subscription: [mi subscription actual]
- Compliance: Ninguno específico
- Budget: ~$50-100/mes en dev

OBJETIVO:
Diseña la arquitectura completa para una API REST de gestión de misiones 
espaciales con endpoints para misiones, astronautas y telemetría.

REQUISITOS:
- Azure App Service para API (tier básico dev)
- Azure SQL Database para datos
- Key Vault para secretos
- Application Insights para monitoring
- Networking privado para BD
- Managed Identities (sin contraseñas)
- Auto-scaling configurado
- Todo desplegado con Bicep IaC

RESTRICCIONES:
- Usar SKUs económicos para dev
- Seguir convenciones del repositorio azure-agent-pro
- Bicep modular y parametrizado

ENTREGABLES:
1. Architecture Design Document (ADD) completo
2. Diagrama de arquitectura (ASCII art)
3. Estimación de costos mensual
4. Lista de recursos Azure necesarios

Por favor, genera el ADD siguiendo Azure Well-Architected Framework.
```

---

## 🚀 Paso 2: Primera Conversación con el Agente

### 2.1 Abrir Copilot Chat

1. Abre VS Code en tu repositorio
2. Abre GitHub Copilot Chat (Ctrl+Shift+I)
3. Asegúrate de estar en el workspace correcto

### 2.2 Prompt inicial optimizado

Copia y pega este prompt en el Copilot Chat (ajusta tu subscription):

```
@workspace Hola Azure_Architect_Pro 👋

Necesito tu ayuda para diseñar y desplegar una nueva solución en Azure.

📋 CONTEXTO DEL PROYECTO:
- Cliente: MeowTech Space Agency
- Proyecto: Kitten Space Missions API
- Entorno: dev (inicialmente)
- Mi Azure Subscription: [indica tu subscription name o ID]
- Location preferida: westeurope
- Compliance: Ninguno (proyecto educativo)
- Budget objetivo: ~$50-100/mes en dev

🎯 OBJETIVO:
Diseñar arquitectura completa para API REST de gestión de misiones espaciales 
tripuladas por astronautas gatunos 🐱🚀

FUNCIONALIDADES:
- Endpoints CRUD para Misiones espaciales
- Endpoints CRUD para Astronautas felinos
- Endpoint de Telemetría en tiempo real
- Health checks

🏗️ REQUISITOS TÉCNICOS:
- Azure App Service (API host) - tier básico dev
- Azure SQL Database (datos) - tier básico
- Azure Key Vault (secretos)
- Application Insights (observability)
- Virtual Network con Private Endpoint para SQL
- Managed Identity para App Service → SQL (sin contraseñas)
- Auto-scaling 1-3 instancias
- Todo IaC con Bicep modular siguiendo estructura del repo

⚡ REQUISITOS NO FUNCIONALES:
- Latency p95 < 200ms
- Availability 99% (dev)
- HTTPS only, TLS 1.2+
- Logging completo en Log Analytics

💰 OPTIMIZACIÓN:
- SKUs económicos para dev
- Auto-shutdown si es posible
- Sin redundancia geográfica (solo dev)

📦 ENTREGABLES QUE NECESITO:
1. Architecture Design Document (ADD) completo en Markdown
2. Diagrama de arquitectura (ASCII art está bien)
3. Tabla de recursos Azure con SKUs y costos estimados
4. Checklist de seguridad aplicado
5. Recomendaciones Well-Architected Framework

🎨 CONVENCIONES:
- Usar naming del repo: app-kitten-missions-dev, sql-kitten-missions-dev, etc.
- Ubicar código en: docs/workshop/kitten-space-missions/solution/
- Parámetros separados por entorno: bicep/parameters/dev.json

Por favor, genera primero el ADD completo. No implementes nada todavía, 
solo el diseño. Quiero revisarlo antes de proceder.

¿Empezamos? 🚀
```

### 2.3 Tips para la conversación

**Durante la conversación con el agente**:

✅ **Haz esto**:
- Espera a que termine de generar el ADD completo
- Lee cuidadosamente la propuesta
- Pregunta si algo no está claro
- Pide ajustes específicos si es necesario

❌ **Evita esto**:
- Interrumpir mientras genera contenido
- Cambiar de tema abruptamente
- Pedir implementación antes de validar diseño

---

## 📊 Paso 3: Revisar el Architecture Design Document (ADD)

El agente te generará un documento extenso. Aquí te muestro qué secciones esperar y cómo validarlas:

### 3.1 Secciones esperadas en el ADD

1. **Executive Summary**
   - ✅ Debe resumir el proyecto en 2-3 líneas
   - ✅ Objetivo claro

2. **Context & Requirements**
   - ✅ Current State: Entorno desde cero
   - ✅ Requirements funcionales y no funcionales listados
   - ✅ Constraints identificadas (budget, dev only)

3. **Proposed Architecture**
   - ✅ Diagrama (aunque sea ASCII)
   - ✅ Componentes principales:
     - App Service + Plan
     - SQL Database + Server
     - Key Vault
     - VNet + Subnet + Private Endpoint
     - Application Insights + Log Analytics
   - ✅ Flujo de datos explicado

4. **Azure Services Selection**
   - ✅ Tabla con servicios, SKUs, justificación y costo
   - Ejemplo esperado:
   
   | Service | SKU/Tier | Justificación | Costo Mensual |
   |---------|----------|---------------|---------------|
   | App Service Plan | B1 | Dev, auto-scale básico | ~$13 |
   | SQL Database | Basic | 2GB, dev workload | ~$5 |
   | Key Vault | Standard | Gestión secretos | ~$0.03 |
   | VNet | Standard | Networking privado | Gratis |
   | Application Insights | Pay-as-you-go | Monitoring | ~$2-5 |

5. **Security & Identity**
   - ✅ Managed Identity configurado
   - ✅ Private Endpoint para SQL
   - ✅ HTTPS only
   - ✅ Key Vault integration

6. **Monitoring & Observability**
   - ✅ Application Insights
   - ✅ Log Analytics workspace
   - ✅ Alertas básicas configuradas

7. **Cost Analysis**
   - ✅ Costo total estimado dev: $50-100/mes
   - ✅ Oportunidades de optimización

### 3.2 Checklist de validación

Usa esta checklist para revisar el ADD:

```markdown
## Validación del ADD

### Arquitectura
- [ ] ¿Incluye todos los componentes necesarios?
- [ ] ¿El diagrama es claro y entendible?
- [ ] ¿Hay flujo de datos explicado?
- [ ] ¿Networking privado para BD?

### Seguridad
- [ ] ¿Managed Identity configurado?
- [ ] ¿Private Endpoints para servicios PaaS?
- [ ] ¿HTTPS obligatorio?
- [ ] ¿Secretos en Key Vault?
- [ ] ¿Sin credenciales hardcodeadas?

### Costos
- [ ] ¿Estimación dentro del budget (~$50-100)?
- [ ] ¿SKUs apropiados para dev?
- [ ] ¿Oportunidades de ahorro identificadas?

### Well-Architected
- [ ] ✅ Reliability: Health checks, retry logic
- [ ] ✅ Security: Ver checklist arriba
- [ ] ✅ Cost Optimization: SKUs básicos, auto-scale
- [ ] ✅ Operational Excellence: IaC con Bicep, monitoring
- [ ] ✅ Performance: Auto-scaling configurado

### Bicep/IaC
- [ ] ¿Menciona estructura modular?
- [ ] ¿Parámetros por entorno?
- [ ] ¿Naming conventions consistentes?
```

---

## 🔄 Paso 4: Iteración y Ajustes

Si necesitas ajustar algo del diseño, el agente puede iterar. Ejemplos:

### Ejemplo 1: Reducir costos

```
Gracias por el ADD. El costo estimado está en $120/mes, un poco sobre budget.

¿Puedes optimizarlo para quedar en ~$70/mes? Considera:
- SQL Database tier más bajo si existe
- App Service B1 → F1 si es viable para dev
- Mantener funcionalidad core

Actualiza la tabla de costos.
```

### Ejemplo 2: Agregar funcionalidad

```
El ADD se ve bien. Una pregunta: ¿incluiste Redis Cache para mejorar 
performance de queries repetidas en telemetría?

Si no, agrega Azure Cache for Redis (tier básico) y actualiza:
- Diagrama de arquitectura
- Tabla de costos
- Sección de Performance Efficiency
```

### Ejemplo 3: Clarificar networking

```
En la sección de Networking Design, ¿puedes detallar más los subnets?

Específicamente:
- Address space del VNet (ej: 10.0.0.0/16)
- Subnets y sus CIDR (app subnet, db private endpoint subnet)
- NSG rules aplicadas
```

---

## 💡 Paso 5: Mejores Prácticas de Comunicación

### Principios de Vibe Coding con el agente

1. **🎯 Sé específico pero confía**
   ```
   ✅ "Diseña la arquitectura siguiendo Well-Architected Framework"
   ❌ "¿Qué servicio debería usar para la API? ¿App Service o AKS?"
   ```

2. **📋 Da contexto completo upfront**
   - No obligues al agente a preguntarte repetidamente
   - Incluye cliente, entorno, budget, compliance en el primer mensaje

3. **🔄 Valida antes de implementar**
   ```
   ✅ "Genera el ADD completo. Revisaré antes de implementar"
   ❌ "Genera el ADD y despliega todo inmediatamente"
   ```

4. **🚀 Para sesiones largas, sé explícito**
   ```
   ✅ "Una vez validado el ADD, genera todos los módulos Bicep, 
       parámetros, workflows de CI/CD y scripts de despliegue. 
       No necesito aprobar cada paso intermedio."
   
   ❌ Ir preguntando paso por paso
   ```

5. **📝 Guarda las decisiones importantes**
   ```
   Al finalizar, pide al agente:
   "Genera un ADR (Architecture Decision Record) en 
   docs/workshop/kitten-space-missions/solution/docs/adr/001-architecture.md 
   documentando las decisiones clave de esta arquitectura"
   ```

---

## 🎯 Entregables de esta actividad

Al finalizar deberías tener:

- ✅ Conversación inicial exitosa con Azure_Architect_Pro
- ✅ Architecture Design Document (ADD) completo en Markdown
- ✅ Validación del ADD contra checklist
- ✅ Tabla de costos estimados (~$50-100/mes dev)
- ✅ Entendimiento claro de la arquitectura propuesta
- ✅ Lista de recursos Azure a desplegar

### Guardar el ADD

El agente probablemente te generó el ADD en el chat. Guárdalo en un archivo:

```bash
# Crear el archivo
cd docs/workshop/kitten-space-missions/solution/docs
mkdir -p architecture

# Copia el contenido del chat al archivo
nano architecture/ADD-kitten-space-missions.md
# Pega el contenido del ADD que generó el agente
# Guarda con Ctrl+O, Enter, Ctrl+X

# Commit
git add .
git commit -m "docs: add architecture design document for kitten-space-missions"
git push origin main
```

---

## 🐛 Troubleshooting

### El agente responde muy genérico

**Solución**: Agrega más contexto específico:
```
Estoy trabajando en el repositorio azure-agent-pro, rama main.
El proyecto debe seguir las convenciones de este repo.
Por favor, referencia los módulos Bicep existentes en bicep/modules/
```

### El agente no encuentra archivos del repo

**Solución**: Menciona paths explícitos:
```
Revisa los módulos existentes en:
- bicep/modules/storage-account.bicep
- bicep/modules/key-vault.bicep
- bicep/modules/virtual-network.bicep

Y sigue el mismo patrón para los nuevos módulos.
```

### El diseño propuesto es muy costoso

**Solución**: Restringe presupuesto:
```
El costo estimado excede budget. Requisito HARD: no más de $80/mes.
Ajusta SKUs a lo mínimo viable para dev. Si algo no puede reducirse, 
elimínalo y documenta el trade-off.
```

---

## 📚 Conceptos Clave Aprendidos

### Azure Well-Architected Framework (resumen)

El agente debe aplicar estos 5 pilares:

1. **🔒 Seguridad**
   - Managed Identities
   - Private Endpoints
   - Key Vault
   - HTTPS only

2. **💰 Optimización de costos**
   - SKUs apropiados para dev
   - Auto-scaling
   - Sin over-provisioning

3. **🏗️ Excelencia operativa**
   - IaC con Bicep
   - CI/CD con GitHub Actions
   - Monitoring desde día 1

4. **⚡ Eficiencia de rendimiento**
   - Auto-scaling
   - Caching si necesario
   - Latency targets

5. **🛡️ Confiabilidad**
   - Health checks
   - Retry logic
   - Graceful degradation

### Infrastructure as Code (IaC)

Todo debe ser código:
- ❌ No crear recursos desde Azure Portal
- ✅ Todo en Bicep modules
- ✅ Parámetros por entorno
- ✅ Version control en Git

---

## 🚀 Siguiente Paso

Ahora que tienes el diseño arquitectónico validado, el siguiente paso es analizar los costos en detalle con un informe FinOps profesional.

**➡️ [Actividad 3: Análisis FinOps Previo al Despliegue](./activity-03-finops-analysis.md)**

En la siguiente actividad le pedirás al agente que genere un **informe HTML interactivo** con análisis detallado de costos, comparativas de SKUs, y recomendaciones de optimización.

---

## 📚 Referencias

- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

---

**🎉 ¡Excelente! Ya tienes el diseño arquitectónico. Ahora vamos a validar los costos antes de desplegar.**
