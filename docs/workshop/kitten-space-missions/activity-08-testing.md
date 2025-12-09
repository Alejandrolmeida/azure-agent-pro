# ✅ Actividad 8: Testing y Validación Final

**⏱️ Duración estimada**: 20 minutos  
**🎯 Objetivo**: Validar que toda la infraestructura funciona correctamente mediante smoke tests y health checks

---

## 📋 Objetivos de aprendizaje

1. ✅ Ejecutar smoke tests de infraestructura
2. ✅ Validar conectividad entre componentes
3. ✅ Verificar security configurations
4. ✅ Realizar health check completo
5. ✅ Documentar lecciones aprendidas

---

## 🧪 Paso 1: Smoke Tests de Infraestructura

### 1.1 Solicitar script de testing al agente

```
@workspace 

Genera un script bash de smoke tests para validar la infraestructura de
Kitten Space Missions.

Ruta: docs/workshop/kitten-space-missions/solution/scripts/smoke-tests.sh

Tests a incluir:
1. ✅ Resource Group existe
2. ✅ App Service está running
3. ✅ SQL Database está online
4. ✅ Key Vault accesible
5. ✅ Private Endpoint connected
6. ✅ Application Insights recibiendo datos
7. ✅ VNet y subnets creados
8. ✅ NSG rules configuradas
9. ✅ Managed Identity asignada
10. ✅ RBAC permissions correctos

Cada test debe:
- Mostrar ✅ si pasa, ❌ si falla
- Exit code 0 si todo OK, 1 si algo falla
- Output detallado para debugging
```

### 1.2 Ejecutar smoke tests

```bash
cd docs/workshop/kitten-space-missions/solution/scripts

# Dar permisos de ejecución
chmod +x smoke-tests.sh

# Ejecutar
./smoke-tests.sh

# Output esperado:
# 🧪 Smoke Tests - Kitten Space Missions
# ========================================
# ✅ Resource Group exists: rg-kitten-missions-dev
# ✅ App Service running: app-kitten-missions-dev
# ✅ SQL Database online: sqldb-kitten-missions-dev
# ✅ Key Vault accessible: kv-kitten-missions-dev-xxx
# ✅ Private Endpoint connected
# ✅ Application Insights OK
# ✅ VNet created: vnet-kitten-missions-dev
# ✅ Managed Identity assigned
# ✅ RBAC permissions configured
# 
# 🎉 All tests passed! (9/9)
```

---

## 🔐 Paso 2: Security Validation

### 2.1 Checklist de seguridad

```bash
# Script de validación de seguridad
cd docs/workshop/kitten-space-missions/solution/scripts

# Solicitar al agente:
# "Genera security-validation.sh que verifique:
# - App Service HTTPS only
# - SQL public access disabled
# - TLS 1.2+ configurado
# - Managed Identity en uso
# - Secrets en Key Vault (no hardcoded)
# - NSG rules restrictivas"
```

### 2.2 Ejecutar validación

```bash
./security-validation.sh

# Output esperado:
# 🔐 Security Validation
# ======================
# ✅ App Service: HTTPS only enabled
# ✅ SQL Server: Public access disabled
# ✅ App Service: TLS 1.2 minimum
# ✅ Managed Identity: Configured
# ✅ Key Vault: Soft delete enabled
# ✅ NSG: No permissive rules (0.0.0.0/0)
# 
# 🛡️ Security score: 100/100
```

---

## 🔗 Paso 3: Connectivity Tests

### 3.1 Test App Service → SQL Database

```bash
# Verificar que App Service puede conectarse a SQL via Private Endpoint
az webapp show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query "outboundIpAddresses" -o tsv

# Verificar VNet integration
az webapp vnet-integration list \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev
```

### 3.2 Test App Service → Key Vault

```bash
# Verificar Managed Identity tiene acceso a Key Vault
APP_IDENTITY=$(az webapp identity show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query principalId -o tsv)

az keyvault show \
  --name [KV-NAME] \
  --query "properties.accessPolicies[?objectId=='$APP_IDENTITY'].permissions" -o json
```

---

## 🏥 Paso 4: Health Check Endpoint (Opcional)

### 4.1 Desplegar app mínima de prueba

Si quieres ver algo funcionando, pide al agente:

```
Genera una API mínima en Node.js con endpoints:
- GET /health (retorna 200 OK + status JSON)
- GET /api/missions (retorna array vacío por ahora)

Debe:
- Conectarse a SQL Database usando Managed Identity
- Leer connection string de Key Vault
- Enviar telemetría a Application Insights

Código en: docs/workshop/kitten-space-missions/solution/src/
```

### 4.2 Deploy con Azure CLI

```bash
# Comprimir app
cd docs/workshop/kitten-space-missions/solution/src
zip -r app.zip .

# Deploy a App Service
az webapp deployment source config-zip \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --src app.zip

# Test health endpoint
APP_URL=$(az webapp show \
  --name app-kitten-missions-dev \
  --resource-group rg-kitten-missions-dev \
  --query defaultHostName -o tsv)

curl https://$APP_URL/health
```

---

## 📊 Paso 5: Validación Final Completa

### 5.1 Checklist exhaustivo

```markdown
## 🎯 Workshop Completion Checklist

### Infraestructura (Actividad 4-6)
- [ ] Resource Group creado
- [ ] VNet + Subnets configurados
- [ ] App Service running
- [ ] SQL Database online
- [ ] Key Vault creado
- [ ] Private Endpoint conectado
- [ ] Application Insights configurado
- [ ] Log Analytics workspace OK

### Security (Well-Architected)
- [ ] HTTPS only habilitado
- [ ] TLS 1.2+ configurado
- [ ] Managed Identity en uso
- [ ] Public access disabled (SQL)
- [ ] Secrets en Key Vault
- [ ] NSG rules restrictivas
- [ ] Diagnostic logs habilitados

### Observability (Actividad 7)
- [ ] Application Insights queries
- [ ] Dashboard creado
- [ ] Alertas configuradas (3+)
- [ ] Diagnostic settings OK

### Cost Optimization (Actividad 3)
- [ ] SKUs apropiados para dev
- [ ] Costo dentro de budget ($70-80/mes)
- [ ] Tags aplicados (Environment, Project, etc.)
- [ ] Budget alert configurado

### DevOps/GitOps (Actividad 5)
- [ ] Bicep code en Git
- [ ] GitHub Actions workflows OK
- [ ] OIDC configurado
- [ ] Environment "dev" con protections
- [ ] Validation workflow ejecutándose en PRs

### Testing (Actividad 8)
- [ ] Smoke tests pasados
- [ ] Security validation OK
- [ ] Connectivity tests OK
- [ ] Health endpoint respondiendo (opcional)

### Documentación
- [ ] Architecture Design Document
- [ ] FinOps report HTML
- [ ] Cost Decision Record
- [ ] Bicep README.md
- [ ] Commits en Git con mensajes descriptivos
```

---

## 🎓 Paso 6: Lecciones Aprendidas

### 6.1 Documenta tu experiencia

Pide al agente:

```
Genera un documento "Lessons Learned" en Markdown con secciones:

1. **Qué funcionó bien**
   - Aspectos positivos del proceso
   - Vibe Coding con el agente
   - Herramientas útiles

2. **Qué fue desafiante**
   - Problemas encontrados
   - Tiempo real vs estimado
   - Conceptos difíciles

3. **Mejoras para próxima vez**
   - Qué harías diferente
   - Optimizaciones posibles
   - Aprendizajes técnicos

4. **Recomendaciones para otros**
   - Tips para quien haga este workshop
   - Errores comunes a evitar

Guarda en: docs/workshop/kitten-space-missions/solution/docs/lessons-learned.md
```

---

## ✅ Entregables Finales del Workshop

Al completar las 8 actividades tienes:

### Código
- ✅ Bicep modules modulares y reutilizables
- ✅ Parameters por entorno (dev/prod)
- ✅ GitHub Actions workflows (CI/CD)
- ✅ Scripts de testing y validación
- ✅ (Opcional) API Node.js básica

### Infraestructura Azure
- ✅ ~15 recursos desplegados en dev
- ✅ Networking privado configurado
- ✅ Security best practices aplicadas
- ✅ Observability completa

### Documentación
- ✅ Architecture Design Document
- ✅ FinOps Report HTML
- ✅ Cost Decision Record
- ✅ Lessons Learned
- ✅ README.md de cada carpeta

### Skills Adquiridas
- ✅ Vibe Coding profesional con agentes IA
- ✅ Azure Well-Architected Framework aplicado
- ✅ Infrastructure as Code con Bicep
- ✅ GitOps/DevOps con GitHub Actions
- ✅ FinOps y optimización de costos
- ✅ Security by design
- ✅ Observability enterprise

---

## 🧹 Cleanup (Opcional)

### Eliminar recursos para evitar costos

Si quieres eliminar todo:

```bash
# ⚠️ CUIDADO: Esto eliminará TODOS los recursos

# Opción 1: Via Azure CLI
az group delete \
  --name rg-kitten-missions-dev \
  --yes \
  --no-wait

# Opción 2: Via Portal
# Resource Groups → rg-kitten-missions-dev → Delete resource group

# Verificar eliminación
az group exists --name rg-kitten-missions-dev
# Debe retornar: false
```

### Mantener el código

Aunque elimines los recursos Azure, mantén:
- ✅ Código en tu GitHub fork
- ✅ Documentación generada
- ✅ Aprendizajes y experiencia

---

## 🎉 ¡Felicidades!

Has completado el workshop **Vibe Coding con Azure Agent Pro**.

### Lo que has logrado:

- 🚀 Desplegaste infraestructura enterprise en Azure
- 🏗️ Aplicaste Azure Well-Architected Framework
- 💰 Hiciste análisis FinOps profesional
- 🤖 Dominaste Vibe Coding con agentes IA
- 🔐 Implementaste security by design
- 📊 Configuraste observabilidad completa
- 🔄 Automatizaste todo con CI/CD

### Próximos pasos sugeridos:

1. **Escala a producción**
   - Crea environment "prod"
   - Agrega geo-redundancy
   - Implementa blue-green deployments

2. **Agrega funcionalidad**
   - Implementa CRUD completo de la API
   - Agrega autenticación (Azure AD B2C)
   - Integra con otros servicios Azure

3. **Mejora observability**
   - Distributed tracing
   - Custom metrics
   - Advanced dashboards

4. **Contribuye al proyecto**
   - Comparte mejoras en azure-agent-pro
   - Documenta tu caso de uso
   - Ayuda a otros en Issues

---

## 📚 Recursos para Continuar Aprendiendo

- [Azure Architecture Center](https://learn.microsoft.com/azure/architecture/)
- [Bicep Modules Registry](https://github.com/Azure/bicep-registry-modules)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Azure Well-Architected Review](https://learn.microsoft.com/assessments/?mode=pre-assessment&session=local)
- [FinOps Foundation](https://www.finops.org/)

---

## 🙏 Agradecimientos

Gracias por completar este workshop. Esperamos que hayas disfrutado aprendiendo **Vibe Coding profesional** con **Azure Agent Pro**.

Si tienes feedback, sugerencias o encuentras bugs:
- 📝 Abre un Issue en el repo
- 💬 Comparte tu experiencia
- ⭐ Dale star al proyecto si te fue útil

---

**🐱🚀 ¡Que tus gatitos astronautas tengan misiones exitosas!**
