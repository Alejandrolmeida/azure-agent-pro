# ADR-001: Arquitectura Base de Kitten Space Missions API

**Estado**: ✅ Aceptada  
**Fecha**: 2024-01-23  
**Contexto**: MeowTech Space Agency - Proyecto Educativo  
**Decisores**: Azure Architect Pro, Equipo de Desarrollo  
**Impacto**: Alto - Define la arquitectura completa del sistema

---

## Contexto y Problema

MeowTech Space Agency necesita una API REST para gestionar misiones espaciales tripuladas por astronautas felinos. El sistema debe:

- Proporcionar operaciones CRUD para Misiones y Astronautas
- Capturar telemetría en tiempo real
- Ser cost-effective (budget: $50-100/mes)
- Seguir best practices de seguridad y observabilidad
- Ser 100% Infrastructure as Code
- Servir como proyecto educativo para aprendizaje Azure

**Restricciones:**
- Presupuesto limitado (~$75-80/mes)
- Entorno inicial: Development only
- Region: West Europe
- Sin requisitos de compliance específicos
- Proyecto educativo/personal (no producción crítica)

---

## Opciones Consideradas

### Opción 1: Azure App Service + Azure SQL Database (ELEGIDA)

**Arquitectura:**
- Azure App Service (B1 tier) para hosting API
- Azure SQL Database (Basic tier) para persistencia
- Key Vault para gestión de secretos
- Application Insights para observabilidad
- Private Endpoint para aislamiento SQL

**Pros:**
- ✅ PaaS managed: Bajo overhead operativo
- ✅ Managed Identity: Seguridad passwordless
- ✅ Escalabilidad automática (1-3 instancias)
- ✅ Backup automático SQL (7 días)
- ✅ Integración nativa con Azure Monitor
- ✅ Costo predecible: ~$75-80/mes
- ✅ Private Endpoint: Aislamiento de red
- ✅ Ideal para aprendizaje Azure

**Cons:**
- ⚠️ Basic tier: Limitaciones de performance (5 DTU)
- ⚠️ Vendor lock-in con Azure
- ⚠️ Menor control sobre infraestructura

**Costo Mensual:** ~$75-80

---

### Opción 2: Azure Container Apps + Cosmos DB

**Arquitectura:**
- Azure Container Apps (serverless containers)
- Cosmos DB (NoSQL)
- Managed Identity
- Application Insights

**Pros:**
- ✅ Serverless: Escala a 0 (ahorro en dev)
- ✅ Microservicios-ready
- ✅ Cosmos DB: Performance global
- ✅ Kubernetes-compatible

**Cons:**
- ❌ Cosmos DB: Costo elevado (~$25/mes mínimo)
- ❌ Mayor complejidad operativa
- ❌ Curva de aprendizaje más alta
- ❌ Menos documentación para principiantes

**Costo Mensual:** ~$90-120  
**Decisión:** Rechazada por costo y complejidad

---

### Opción 3: Azure Functions + Table Storage

**Arquitectura:**
- Azure Functions (Consumption Plan)
- Azure Table Storage
- Serverless completo

**Pros:**
- ✅ Costo muy bajo (~$20-30/mes)
- ✅ Escala automático
- ✅ Event-driven architecture

**Cons:**
- ❌ Table Storage: Sin relaciones, queries limitados
- ❌ Functions: Cold start issues
- ❌ Arquitectura fragmentada (múltiples functions)
- ❌ No ideal para API REST tradicional
- ❌ Debugging más complejo

**Costo Mensual:** ~$20-30  
**Decisión:** Rechazada por limitaciones de Table Storage para modelo relacional

---

### Opción 4: AKS (Azure Kubernetes Service) + PostgreSQL

**Arquitectura:**
- AKS cluster (2 nodes)
- Azure Database for PostgreSQL
- Full control sobre orchestration

**Pros:**
- ✅ Máxima flexibilidad
- ✅ PostgreSQL: Open source, potente
- ✅ Kubernetes skills transferibles

**Cons:**
- ❌ Costo elevado: AKS ~$140/mes + PostgreSQL ~$30/mes
- ❌ Complejidad operativa muy alta
- ❌ Overkill para proyecto educativo simple
- ❌ Requiere expertise Kubernetes

**Costo Mensual:** ~$170+  
**Decisión:** Rechazada por costo y over-engineering

---

## Decisión

✅ **Se elige la Opción 1: Azure App Service + Azure SQL Database**

### Justificación Detallada

#### 1. Cost-Effectiveness
- **Total: ~$75-80/mes** dentro del presupuesto objetivo ($50-100)
- App Service B1: $55/mes (1 core, 1.75GB RAM, suficiente para dev)
- SQL Basic: $5/mes (5 DTU, 2GB storage)
- Resto: Monitoring, networking (~$20/mes)

#### 2. Simplicidad Operativa
- PaaS managed: Azure gestiona patching, backups, HA
- Deployment simple: `az webapp deploy` o GitHub Actions
- No requiere gestión de VMs ni containers complejos

#### 3. Seguridad Best Practices
- **Managed Identity**: Eliminación completa de passwords
- **Private Endpoint**: SQL aislado en VNet privada
- **Key Vault**: Secretos centralizados
- **TLS 1.2+ enforced**: Tráfico encriptado
- **SQL TDE**: Encryption at rest por defecto

#### 4. Observabilidad Integral
- Application Insights: APM out-of-the-box
- Distributed tracing automático
- Log Analytics: Logs centralizados
- Dashboards pre-built para App Service y SQL

#### 5. Modelo de Datos Relacional
- Azure SQL: ACID compliant
- Relaciones entre Missions ↔ Astronauts (many-to-many)
- SQL queries potentes para analytics
- EF Core integration en .NET

#### 6. Escalabilidad Apropiada
- Auto-scaling: 1-3 instancias según CPU/Memory
- Upgrade path claro: B1 → S1 → P1v3
- SQL: Upgrade de Basic → Standard → Premium según necesidad

#### 7. Valor Educativo
- Aprendizaje de servicios Azure core (App Service, SQL, Key Vault)
- Patrones enterprise: Managed Identity, Private Endpoints
- IaC con Bicep modular
- CI/CD con GitHub Actions

---

## Decisiones Arquitectónicas Clave

### DA-1: Managed Identity para Autenticación

**Decisión:** Usar System-Assigned Managed Identity en App Service para acceso a SQL y Key Vault.

**Alternativas:**
- Connection strings con passwords en Key Vault
- Azure AD Service Principal con secrets

**Razones:**
- ✅ Zero secrets: No passwords en ningún lugar
- ✅ Rotación automática de credenciales
- ✅ Best practice de Azure
- ✅ Audit trail completo en Azure AD
- ✅ Menor superficie de ataque

**Consecuencias:**
- ✅ Seguridad mejorada significativamente
- ⚠️ Requiere configuración RBAC correcta
- ⚠️ Debugging inicial puede ser más complejo

---

### DA-2: Private Endpoint para Azure SQL

**Decisión:** SQL Database accesible solo via Private Endpoint en VNet (10.0.1.0/24).

**Alternativas:**
- SQL con firewall rules (allow Azure services)
- SQL con IP whitelisting
- VNet Integration completa para App Service

**Razones:**
- ✅ Zero public exposure de base de datos
- ✅ Tráfico no sale de Azure backbone
- ✅ Compliance con Zero Trust
- ✅ Latencia reducida vs internet
- ⚠️ Costo adicional: ~$7/mes (aceptable)

**Consecuencias:**
- ✅ Seguridad máxima para datos
- ⚠️ Acceso dev local requiere VPN o Bastion
- ⚠️ Private DNS Zone requerida

**Workaround para Dev:**
- Usar Azure Cloud Shell para queries ad-hoc
- Temporal firewall rule para IP dev (solo cuando sea necesario)

---

### DA-3: Basic Tier para SQL Database (Dev)

**Decisión:** Azure SQL Database Basic tier (5 DTU, 2GB) para environment dev.

**Alternativas:**
- Standard tier (10-100 DTU): $15-150/mes
- Premium tier: $450+/mes
- Serverless tier: $5-150/mes según uso

**Razones:**
- ✅ Costo mínimo: $5/mes
- ✅ Suficiente para cargas dev/test
- ✅ Backups automáticos incluidos
- ✅ TDE (encryption) incluido
- ⚠️ Performance limitado (5 DTU ≈ 5 concurrent queries)

**Consecuencias:**
- ✅ Budget preservado para otros componentes
- ⚠️ Bottleneck potencial bajo carga alta
- ✅ Upgrade path claro: Basic → Standard → Premium

**Mitigación:**
- Query optimization (indices, execution plans)
- Connection pooling en app
- Monitoring de DTU usage (alert > 80%)
- Load testing para identificar límites

---

### DA-4: App Service B1 Tier con Auto-Scaling

**Decisión:** App Service Plan B1 con auto-scaling horizontal (1-3 instancias).

**Alternativas:**
- Free/Shared tier: No production features
- S1 tier: $70/mes (unnecessary para dev)
- Premium tier: $140+/mes (overkill)

**Razones:**
- ✅ Balance costo/features: $55/mes
- ✅ Custom domains + SSL incluido
- ✅ Always On para warm instances
- ✅ Deployment slots (future)
- ✅ Auto-scaling support
- ✅ VNet integration support

**Consecuencias:**
- ✅ Cost-effective para dev
- ⚠️ 1 core, 1.75GB RAM (limitado)
- ✅ Suficiente para <50 req/sec

**Scaling Rules:**
- CPU > 70%: Scale out +1 instance
- Memory > 80%: Scale out +1 instance
- Max instances: 3 (capped para costo)

---

### DA-5: Application Insights para Observabilidad

**Decisión:** Application Insights con workspace-based ingestion (Log Analytics).

**Alternativas:**
- Classic Application Insights (deprecated)
- Third-party APM (Datadog, New Relic)
- Solo Azure Monitor Logs

**Razones:**
- ✅ Native Azure integration
- ✅ Auto-instrumentation para .NET
- ✅ Distributed tracing built-in
- ✅ Costo predecible: ~$5/mes (2GB ingestion)
- ✅ Queries KQL poderosas
- ✅ Dashboards y workbooks incluidos

**Consecuencias:**
- ✅ Visibilidad completa del stack
- ✅ Request/dependency tracking automático
- ⚠️ Sampling al 100% en dev (costo controlado)
- ✅ Producción: Sampling adaptativo recomendado

---

### DA-6: Virtual Network con Subnetting Estratégico

**Decisión:** VNet 10.0.0.0/16 con subnets dedicadas por función.

**Subnetting:**
```
10.0.0.0/24  → subnet-appservice   (Future VNet integration)
10.0.1.0/24  → subnet-sql          (Private Endpoint SQL)
10.0.2.0/24  → subnet-pe-general   (Future Private Endpoints)
```

**Razones:**
- ✅ Segmentación lógica por workload
- ✅ NSGs granulares por subnet
- ✅ Escalabilidad: 251 IPs por subnet
- ✅ Aislamiento de SQL Private Endpoint
- ✅ Preparado para crecimiento futuro

**Consecuencias:**
- ✅ Security posture mejorada
- ⚠️ Requiere planificación IP
- ✅ Permite micro-segmentation futura

---

### DA-7: Key Vault Standard (No Premium)

**Decisión:** Azure Key Vault Standard tier (software-protected keys).

**Alternativas:**
- Premium tier: HSM-backed keys ($1/key/mes)
- App Configuration: No es secretos store

**Razones:**
- ✅ Costo: $0.03/10k operations (negligible)
- ✅ Suficiente para secretos (no HSM required)
- ✅ RBAC integration
- ✅ Soft-delete + purge protection

**Consecuencias:**
- ✅ Cost-effective
- ⚠️ Keys en software (aceptable para dev)
- ✅ Producción: Evaluar Premium si compliance lo requiere

---

### DA-8: Modularidad Bicep (No ARM Templates)

**Decisión:** Infrastructure as Code con Bicep modular (no ARM JSON).

**Estructura:**
```
bicep/
├── main.bicep                    # Orchestrator
├── parameters/dev.json           # Environment params
└── modules/
    ├── appservice.bicep
    ├── sql.bicep
    ├── keyvault.bicep
    ├── networking.bicep
    ├── privateendpoint.bicep
    └── monitoring.bicep
```

**Razones:**
- ✅ Bicep: Sintaxis legible vs ARM JSON
- ✅ Type safety + IntelliSense
- ✅ Modularidad: Reutilización de componentes
- ✅ Transpila a ARM automáticamente
- ✅ Native Azure support
- ✅ Parameter files por entorno

**Consecuencias:**
- ✅ Código limpio y mantenible
- ✅ Testing de módulos individuales
- ✅ CI/CD friendly
- ⚠️ Requiere Bicep CLI installed

---

### DA-9: Single Region Deployment (Dev)

**Decisión:** Deployment únicamente en West Europe (sin geo-redundancia).

**Razones:**
- ✅ Ahorro significativo (~$50/mes)
- ✅ Suficiente para dev/test
- ✅ Menor complejidad operativa
- ✅ Sin requisitos DR para proyecto educativo

**Consecuencias:**
- ⚠️ Sin disaster recovery automático
- ⚠️ Downtime si region fail (aceptable dev)
- ✅ Producción: Upgrade a multi-region

**Upgrade Path Production:**
- Primary: West Europe
- Secondary: North Europe (paired region)
- Traffic Manager o Front Door para failover

---

### DA-10: No WAF/CDN en Dev (Cost Optimization)

**Decisión:** No implementar Azure Front Door / CDN / WAF en entorno dev.

**Razones:**
- ✅ Ahorro: ~$40/mes
- ✅ Innecesario para dev/test
- ✅ App Service proporciona SSL built-in
- ✅ No tráfico global en dev

**Consecuencias:**
- ⚠️ Sin DDoS protection avanzado (Basic incluido en VNet)
- ⚠️ Sin caching global
- ⚠️ Sin WAF rules

**Producción Recomendado:**
- Azure Front Door Premium con WAF
- CDN para assets estáticos
- DDoS Standard protection

---

## Consecuencias Generales

### Positivas ✅

1. **Seguridad Enterprise-Grade**
   - Managed Identity elimina passwords
   - Private Endpoint aísla SQL
   - Key Vault centraliza secretos
   - Score: 5/5 en Well-Architected Security

2. **Observabilidad Completa**
   - Application Insights: Request/dependency tracking
   - Log Analytics: Logs centralizados
   - Dashboards pre-configurados
   - Alerts proactivos

3. **Cost-Effective**
   - $75-80/mes: Dentro de budget
   - SKUs económicos pero funcionales
   - Auto-scaling previene over-provisioning

4. **IaC 100%**
   - Bicep modular y reutilizable
   - Parameter files por entorno
   - CI/CD ready
   - Reproducible environments

5. **Escalabilidad Clara**
   - Upgrade paths definidos
   - B1 → S1 → P1v3 (App Service)
   - Basic → Standard → Premium (SQL)

### Negativas ⚠️

1. **Performance Limitado (Dev Tier)**
   - SQL Basic: 5 DTU puede bottleneck
   - App Service B1: 1 core, 1.75GB RAM
   - **Mitigación:** Query optimization, load testing, monitoring

2. **Acceso Dev Complejo**
   - Private Endpoint: No acceso directo local
   - **Mitigación:** Azure Cloud Shell, temporal firewall rules

3. **Vendor Lock-In**
   - Arquitectura Azure-specific
   - **Mitigación:** Abstracciones en código (Repository pattern), containerización futura

4. **Sin Disaster Recovery**
   - Single region = SPOF
   - **Aceptable:** Dev environment only
   - **Producción:** Implementar geo-replication

5. **Costo Baseline Fijo**
   - ~$60/mes mínimo (App Service + SQL)
   - **No serverless** = no scale-to-zero
   - **Aceptable:** Costo predecible, mejor para learning

---

## Validación de Decisiones

### Pruebas de Concepto Requeridas

```yaml
poc_validation:
  managed_identity_auth:
    - [ ] App Service → SQL authentication working
    - [ ] App Service → Key Vault access verified
    - [ ] RBAC roles correctly assigned
  
  private_endpoint:
    - [ ] DNS resolution working (privatelink.database.windows.net)
    - [ ] Connectivity from App Service to SQL PE
    - [ ] Public access blocked verified
  
  performance_baseline:
    - [ ] Load test: 10 req/sec sustained
    - [ ] Latency p95 < 200ms confirmed
    - [ ] SQL DTU usage < 80% under load
  
  cost_validation:
    - [ ] First month cost tracking
    - [ ] Budget alerts configured
    - [ ] No unexpected charges
```

### Métricas de Éxito

| Métrica | Target | Medición |
|---------|--------|----------|
| **Deployment Time** | < 15 min | Bicep deployment duration |
| **API Latency (p95)** | < 200ms | Application Insights |
| **Error Rate** | < 1% | Application Insights |
| **Cost (Monthly)** | $50-100 | Azure Cost Management |
| **Security Score** | > 80% | Defender for Cloud |
| **Availability** | > 99% | Uptime monitoring |

---

## Alternativas Futuras (Production)

### Cuando escalar a Producción:

```yaml
production_upgrades:
  tier_upgrades:
    app_service: S1 o P1v3 (zone redundant)
    sql_database: Standard S2 (50 DTU) con geo-replication
    
  security_enhancements:
    - Azure Front Door Premium (WAF + CDN)
    - DDoS Standard protection
    - Azure Policy enforcement
    - Defender for Cloud continuous compliance
  
  reliability:
    - Multi-region deployment (West + North Europe)
    - Traffic Manager o Front Door
    - Automated failover
    - Point-in-time restore testing
  
  observability:
    - Adaptive sampling (50%)
    - Custom dashboards
    - Runbooks automatizados
    - SLO/SLI tracking
  
  estimated_cost: $250-350/month
```

---

## Referencias

1. **Azure Documentation**
   - [App Service Best Practices](https://learn.microsoft.com/azure/app-service/app-service-best-practices)
   - [Managed Identity Overview](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)
   - [Private Endpoint Documentation](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)

2. **Well-Architected Framework**
   - [Cost Optimization](https://learn.microsoft.com/azure/architecture/framework/cost/)
   - [Security Pillar](https://learn.microsoft.com/azure/architecture/framework/security/)
   - [Operational Excellence](https://learn.microsoft.com/azure/architecture/framework/devops/)

3. **Project Documentation**
   - [Architecture Design Document](../ARCHITECTURE.md)
   - [Repository Structure](../../../../PROJECT_CONTEXT.md)

---

## Aprobación y Firma

| Rol | Nombre | Aprobación | Fecha |
|-----|--------|------------|-------|
| **Arquitecto** | Azure Architect Pro | ✅ Aprobado | 2024-01-23 |
| **Tech Lead** | [Pending] | ⏳ Pendiente | - |
| **Security** | [Pending] | ⏳ Pendiente | - |
| **FinOps** | [Pending] | ⏳ Pendiente | - |

---

## Historial de Cambios

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0 | 2024-01-23 | Azure Architect Pro | Versión inicial - Decisiones arquitectónicas base |

---

## Notas Finales

Este ADR documenta las decisiones arquitectónicas **fundamentales** para la versión inicial (dev) de Kitten Space Missions API. Las decisiones priorizan:

1. 🔐 **Seguridad**: Best practices con Managed Identity + Private Endpoint
2. 💰 **Costo**: Optimizado para budget educativo ($75-80/mes)
3. 📚 **Aprendizaje**: Servicios Azure core con valor educativo
4. 🚀 **Simplicidad**: PaaS managed, bajo overhead operativo
5. 📈 **Escalabilidad**: Upgrade paths claros para producción

**Estado Actual:** ✅ Arquitectura aprobada para implementación  
**Próximo Paso:** Desarrollo de módulos Bicep y deployment

🐱🚀 **Ready for implementation!**
