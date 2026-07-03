# Agentes Especializados — Azure Agent Pro v2

Azure Agent Pro v2 incluye **7 sub-agentes especializados** que cubren todos los dominios de Azure. Cada agente tiene instrucciones profundas, playbooks de diagnóstico y code templates para su área específica.

---

## Tabla de Agentes

| Agente | Archivo | Dominio | Nivel |
|--------|---------|---------|-------|
| [Azure_Architect_Pro](#azure_architect_pro) | `azure-architect.agent.md` | Arquitectura global, Bicep IaC, DevOps | Orquestador |
| [Azure_Admin_Pro](#azure_admin_pro) | `azure-admin.agent.md` | Governance, Policy, RBAC, Cost | Avanzado |
| [Azure_Data_Pro](#azure_data_pro) | `azure-data.agent.md` | SQL, Cosmos, Synapse, ADF, Databricks | Avanzado |
| [Azure_AppServices_Pro](#azure_appservices_pro) | `azure-app-services.agent.md` | App Service, Functions, AKS, APIM | Avanzado |
| [Azure_Foundry_Pro](#azure_foundry_pro) | `azure-foundry.agent.md` | OpenAI, AI Foundry, RAG, ML | Avanzado |
| [Azure_Networking_Pro](#azure_networking_pro) | `azure-networking.agent.md` | VNets, Firewall, VPN, Private Link | Avanzado |
| [Azure_SQL_DBA](#azure_sql_dba) | `Azure_SQL_DBA.agent.md` | SQL DBA — performance, migration | Avanzado |

---

## Azure_Architect_Pro

**El orquestador** — punto de entrada para cualquier trabajo arquitectónico en Azure.

### Capacidades
- Diseño de arquitecturas según Azure Well-Architected Framework (5 pilares)
- Infrastructure as Code con Bicep (módulos reutilizables, multi-entorno)
- CI/CD con GitHub Actions + OIDC (secretless deployments)
- FinOps: estimación de costes, optimización, reservas
- Multi-tenant/multi-subscription: Landing Zones, Management Groups
- **Delega automáticamente** al sub-agente correcto según el dominio

### Cuándo usarlo
Siempre que necesites una visión arquitectónica completa o cuando no estés seguro qué sub-agente usar.

### Ejemplos de prompts

```
@Azure_Architect_Pro Diseña una arquitectura hub-spoke para una aplicación 
web de alto tráfico con datos sensibles (GDPR) en West Europe.
Presupuesto: 2000€/mes máximo.

@Azure_Architect_Pro Revisa nuestra arquitectura actual en la subscription
$AZURE_SUBSCRIPTION_ID y sugiere mejoras de seguridad y coste.

@Azure_Architect_Pro Crea los módulos Bicep para desplegar un App Service
Premium v3 con VNet Integration, Private Endpoints para SQL y Key Vault,
y un pipeline GitHub Actions con OIDC.
```

---

## Azure_Admin_Pro

**El administrador de governance** — gestión de subscriptions, policies, identidades y cumplimiento.

### Capacidades
- Azure Policy: definiciones custom, iniciativas de compliance (CIS, ISO 27001, NIST)
- RBAC: custom roles, PIM (Just-In-Time), Access Reviews
- Microsoft Entra ID: Conditional Access, Identity Protection, B2B/B2C
- Microsoft Defender for Cloud: Secure Score, remediation, CSPM
- Cost Management: budgets, orphaned resources, FinOps analysis
- Azure Lighthouse: gestión cross-tenant para MSPs
- Onboarding completo de nuevas subscriptions con baseline de governance

### Cuándo usarlo
Problemas de compliance, auditorías de seguridad, onboarding de clientes, gestión de costes, administración de identidades.

### Ejemplos de prompts

```
@Azure_Admin_Pro Analiza la subscription $AZURE_SUBSCRIPTION_ID y dame 
un informe de: recursos sin tags obligatorios, roles Owner directos,
recursos huérfanos y estado del Secure Score.

@Azure_Admin_Pro Crea una Azure Policy que deniegue la creación de
Storage Accounts con public blob access habilitado.

@Azure_Admin_Pro Diseña el proceso de onboarding para una nueva 
subscription de producción: baseline de governance, Defender,
Log Analytics y budget alerts.
```

---

## 🗄️ Azure_Data_Pro

**El ingeniero de datos** — plataformas de datos enterprise, performance tuning y arquitecturas lakehouse.

### Capacidades
- Azure SQL Database/MI: performance tuning, migración, HA/DR, Always Encrypted
- Azure Cosmos DB: diseño de particiones, throughput optimization, consistency models
- Azure Synapse Analytics: pools dedicados, Serverless SQL, Spark, Synapse Link
- Azure Data Factory: pipelines ELT, Mapping Data Flows, CI/CD
- Azure Databricks: Unity Catalog, Delta Lake, MLflow, Structured Streaming
- ADLS Gen2: Medallion Architecture (Bronze/Silver/Gold), ACLs, lifecycle
- Microsoft Purview: Data Catalog, lineage, classification, governance
- Stream Analytics: real-time processing, temporal windows

### Cuándo usarlo
Problemas de performance en bases de datos, diseño de pipelines, migración de datos, arquitecturas lakehouse, streaming en tiempo real.

### Ejemplos de prompts

```
@Azure_Data_Pro Las queries en nuestra Azure SQL Database están tardando 
10x más que ayer. Ayúdame a diagnosticar el problema.
Servidor: $SQL_SERVER, BD: $DB_NAME

@Azure_Data_Pro Diseña una arquitectura lakehouse (Medallion) para 
procesar 500GB de datos diarios de múltiples fuentes (SQL, SAP, REST APIs)
hacia Power BI. Presupuesto: 3000€/mes.

@Azure_Data_Pro ¿Cuál es la estrategia de partición óptima para un 
Cosmos DB con 100M de documentos de IoT? Patrón de acceso: 
90% por deviceId, 10% por rango de fechas.
```

---

## Azure_AppServices_Pro

**El ingeniero cloud-native** — aplicaciones PaaS, serverless, containers y mensajería.

### Capacidades
- App Service: planes, deployment slots, auto-scaling, VNet Integration
- Azure Functions: cold start mitigation, Durable Functions, KEDA
- Azure Container Apps: KEDA scaling, Dapr, revision management
- AKS: node pools, Workload Identity, GitOps (Flux), monitoring
- API Management: políticas, AI Gateway, APIOps, developer portal
- Service Bus, Event Grid: patrones saga, CQRS, event sourcing
- Logic Apps: integraciones empresariales, EDI, conectores 400+
- GitHub Actions CI/CD: OIDC secretless, slot swap, AKS deployments

### Cuándo usarlo
Despliegues de aplicaciones, problemas de rendimiento en apps, diseño de APIs, arquitecturas event-driven, AKS.

### Ejemplos de prompts

```
@Azure_AppServices_Pro Mi Function App tiene cold starts de 5+ segundos.
¿Cuál es la forma más económica de eliminarlos sin subir a Premium?

@Azure_AppServices_Pro Diseña una arquitectura de microservicios con
Container Apps + Service Bus + APIM para una plataforma de e-commerce
con picos de tráfico 10x en Black Friday.

@Azure_AppServices_Pro Crea el pipeline GitHub Actions completo (OIDC)
para desplegar una Web App .NET 8 con slot swap blue-green,
health checks y rollback automático.
```

---

## Azure_Foundry_Pro

**El ingeniero de IA** — soluciones GenAI enterprise con Azure OpenAI, RAG y AI Foundry.

### Capacidades
- Azure OpenAI: deployments, quotas TPM/RPM, function calling, Assistants API
- Azure AI Foundry: Hub & Projects, Model Catalog (GPT-4o, Llama, Mistral, Phi)
- Prompt Flow: orquestación LLM, evaluaciones, CI/CD, tracing
- Azure AI Search: vector search, hybrid search (BM25 + vector + semantic)
- RAG patterns: chunking, indexing pipeline, retrieval, re-ranking, caching
- Responsible AI: Content Safety, Prompt Shields, groundedness, audit logging
- FinOps IA: model routing coste/calidad, semantic caching, PTU vs consumption
- Azure Machine Learning: MLOps, training, model registry, monitoring

### Cuándo usarlo
Chatbots, RAG sobre documentos internos, clasificación de texto, integración de OpenAI en apps, responsible AI.

### Ejemplos de prompts

```
@Azure_Foundry_Pro Necesito construir un RAG sobre 10,000 documentos PDF 
internos. Acceso privado (no internet), datos sensibles. 
Presupuesto: 500€/mes máximo.

@Azure_Foundry_Pro ¿Cómo implemento semantic caching con Azure AI Search
para reducir un 50% las llamadas a GPT-4o?

@Azure_Foundry_Pro Diseña la estrategia de content filtering y Prompt
Shields para un chatbot de atención al cliente con datos de GDPR.
```

---

## 🌐 Azure_Networking_Pro

**El ingeniero de redes** — diseño, troubleshooting y seguridad de redes Azure.

### Capacidades
- VNets, subnets, peering, NAT Gateway: diseño de address spaces, IPAM
- NSGs, ASGs: micro-segmentación, service tags, traffic analytics
- Azure Firewall Premium: IDPS, TLS inspection, URL filtering, DNS proxy
- Application Gateway v2, Front Door, Traffic Manager: load balancing global
- VPN Gateway, ExpressRoute, Azure Virtual WAN: conectividad híbrida
- Private Endpoints, Private Link: acceso privado a todos los servicios PaaS
- Azure DNS: split-brain, Private DNS Resolver, conditional forwarders
- Network Watcher: IP Flow Verify, Next Hop, packet capture, diagnostics

### Cuándo usarlo
Problemas de conectividad, diseño de arquitecturas de red, troubleshooting de Firewall, Private Endpoints, conectividad híbrida.

### Ejemplos de prompts

```
@Azure_Networking_Pro Una VM en el Spoke no puede conectar con la SQL 
en otro Spoke pasando por el Firewall del Hub. 
Diagnostica el problema paso a paso.

@Azure_Networking_Pro Diseña la arquitectura hub-spoke completa para 
5 spokes (prod, pre, dev, identity, connectivity) con Azure Firewall 
Premium, ExpressRoute y Private Endpoints para SQL, Storage y Key Vault.

@Azure_Networking_Pro Crea los Bicep templates para Private Endpoint
de Azure SQL con DNS Zone Group y todos los VNet links necesarios.
```

---

## 🗃️ Azure_SQL_DBA

**El DBA Azure** — especialista en SQL performance, blocking, indexación y migración.

### Capacidades
- SQL performance tuning: Query Store, Automatic Tuning, IQP
- Blocking y deadlocks: análisis de `sys.dm_exec_requests`, lock escalation
- Index analysis: missing indexes DMV, fragmentation, columnstore
- Azure SQL Database: scaling, DTU/vCore, elastic pools, geo-replication
- SQL Server on Azure VM: storage optimization, AlwaysOn, SQL Agent
- Migration: DMA assessment, DMS online migration, SSMA

### Cuándo usarlo
Problemas de rendimiento SQL, consultas lentas, bloqueos, gestión de índices, migración de bases de datos.

---

## Cómo Usar los Agentes en VS Code

### Activar un agente en Copilot Chat

1. Abre Copilot Chat (`Ctrl+Shift+I` o `Ctrl+I`)
2. Escribe `@` seguido del nombre del agente
3. El agente cargará automáticamente sus instrucciones especializadas

```
@Azure_Architect_Pro ← Orquestador principal
@Azure_Admin_Pro ← Governance
@Azure_Data_Pro ← Datos
@Azure_AppServices_Pro ← Apps PaaS
@Azure_Foundry_Pro ← IA/GenAI
@Azure_Networking_Pro ← Redes
@Azure_SQL_DBA ← SQL avanzado
```

### Buenas prácticas con agentes

```bash
# 1. Dar siempre contexto específico
@Azure_Networking_Pro [contexto: hub-spoke, 3 spokes, Azure Firewall Standard,
ExpressRoute a on-prem] No tenemos conectividad de una VM en spoke-prod
al SQL Database en snet-data.

# 2. Especificar constraints
@Azure_Data_Pro [coste máximo: 500€/mes, datos GDPR, West Europe]
Necesito una base de datos para 100M registros con < 10ms de latencia.

# 3. Pedir diagnóstico antes que solución
@Azure_AppServices_Pro Primero diagnostica el estado actual de mi App Service,
después propón mejoras. Subscription: $AZURE_SUBSCRIPTION_ID

# 4. Iterar sobre el output
@Azure_Architect_Pro [continuando sesión anterior] Ahora adapta el Bicep
para el entorno de producción con Zone Redundancy.
```

---

## MCP Servers que usan los agentes

| MCP Server | Package | Agentes que lo usan | Para qué |
|------------|---------|---------------------|----------|
| **azure-mcp** | `@azure/mcp@latest` | Todos | Estado real de recursos Azure |
| **github-mcp** | `@modelcontextprotocol/server-github` | Todos | Repos, workflows, Issues |
| **filesystem-mcp** | `@modelcontextprotocol/server-filesystem` | Todos | Leer Bicep, scripts del workspace |
| **memory-mcp** | `@modelcontextprotocol/server-memory` | Todos | Contexto persistente entre sesiones |
| **brave-search-mcp** | `@modelcontextprotocol/server-brave-search` | Architect | Documentación Azure, community |

> **Setup**: Configura todos los MCP servers ejecutando `./scripts/setup/setup-wsl.sh`

---

## Añadir un nuevo agente

```bash
# 1. Crear el archivo de agente
cat > .github/agents/mi-agente.agent.md << 'EOF'
---
name: Mi_Agente_Pro
description: Descripción breve del agente y sus capacidades principales.
argument-hint: Ejemplo de cómo invocar al agente con contexto suficiente.
tools: ["*"]
---

# Identidad del Agente
...
EOF

# 2. Referenciar en .copilot/copilot-instructions.md
# 3. Documentar en este archivo
# 4. Crear PR con la nueva documentación
```
