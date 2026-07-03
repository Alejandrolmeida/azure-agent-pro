# Actividad 3: Análisis FinOps Previo al Despliegue

**⏱️ Duración estimada**: 30 minutos 
** Objetivo**: Generar un informe HTML profesional con análisis detallado de costos de la infraestructura antes de desplegar en Azure

---

## Objetivos de aprendizaje

Al finalizar esta actividad serás capaz de:

1. Solicitar al agente análisis FinOps detallados
2. Generar informes HTML interactivos de costos
3. Comparar diferentes SKUs y sus trade-offs
4. Identificar oportunidades de optimización de costos
5. Validar que el diseño cumple con el presupuesto objetivo
6. Documentar decisiones de costos para stakeholders

---

## ¿Qué es FinOps?

**FinOps** (Financial Operations) es una práctica de gestión financiera en la nube que combina:

- **Optimización de costos** - Pagar solo por lo que necesitas
- **Visibilidad** - Entender dónde se gasta el dinero
- **Accountability** - Asignar costos a equipos/proyectos
- 🔄 **Mejora continua** - Revisar y optimizar regularmente

### ¿Por qué hacerlo ANTES de desplegar?

- Evitar sorpresas en la factura de Azure
- Validar que el diseño es sostenible económicamente
- Identificar oportunidades de ahorro desde día 1
- Justificar decisiones técnicas con datos de costos
- Obtener aprobación de stakeholders con información clara

---

## Paso 1: Solicitar Informe FinOps al Agente

### 1.1 Contexto previo

Deberías tener de la Actividad 2:
- Architecture Design Document (ADD)
- Lista de recursos Azure a desplegar
- Estimación de costos preliminar

### 1.2 Prompt optimizado para FinOps

Abre Copilot Chat y usa este prompt:

```
@workspace Hola Azure_Architect_Pro 👋

Tenemos el diseño arquitectónico validado para Kitten Space Missions API.
Ahora necesito un análisis FinOps DETALLADO antes de desplegar.

 OBJETIVO:
Generar un informe HTML profesional e interactivo con análisis completo 
de costos de la infraestructura propuesta.

 CONTEXTO:
- Arquitectura: La diseñada en la actividad anterior (ADD)
- Entorno: dev (sin producción todavía)
- Budget objetivo: $70-80/mes máximo
- Location: westeurope
- Periodo de análisis: Costos mensuales estimados

📄 CONTENIDO DEL INFORME HTML:

1. **Executive Summary**
 - Costo total mensual estimado
 - Comparativa vs budget objetivo
 - Top 3 recursos más costosos
 - Nivel de optimización (score sobre 100)

2. **Desglose por Recurso**
 Tabla interactiva con:
 - Recurso Azure
 - SKU/Tier seleccionado
 - Justificación técnica
 - Costo mensual estimado
 - % del total
 - Alternativas más baratas (si existen)
 - Trade-offs de cada alternativa

3. **Análisis de SKU Comparativo**
 Para cada servicio principal:
 - App Service: F1 vs B1 vs B2
 - SQL Database: Basic vs Standard S0 vs S1
 - Mostrar pricing, specs, cuándo conviene cada uno

4. **Optimizaciones Recomendadas**
 - Auto-shutdown para dev (si aplica)
 - Reserved instances (si ROI > 0)
 - Spot instances (para recursos no críticos)
 - Tagging strategy para cost allocation
 - Budget alerts configurados

5. **Proyección Anual**
 - Costo mensual × 12
 - Ahorro potencial con reservas
 - Costo si escalamos a prod (estimación)

6. **Risk Assessment**
 - ¿Qué pasa si tráfico crece 10x?
 - ¿Costo de disaster recovery?
 - ¿Impact de compliance requirements?

7. **Action Items**
 Checklist pre-deploy:
 - [ ] Budget alert configurado en Azure
 - [ ] Tags de cost center aplicados
 - [ ] Auto-scaling configurado correctamente
 - [ ] Review mensual de costos programado

🎨 FORMATO DEL INFORME HTML:
- Diseño profesional con CSS moderno
- Responsive (mobile-friendly)
- Tablas interactivas (sortable si es posible)
- Gráficos visuales (barras, pie charts) usando Chart.js o similar
- Colores: Verde para dentro de budget, Amarillo warnings, Rojo over budget
- Incluir logos de Azure (si es posible)
- Secciones colapsables para detalles
- Botón de "Export PDF" (funcionalidad básica)

 OUTPUT:
Genera el archivo en:
docs/workshop/kitten-space-missions/solution/docs/finops-report.html

 FUENTES DE DATOS:
Usa Azure Pricing Calculator official data para westeurope region.
Links de referencia:
- https://azure.microsoft.com/pricing/calculator/
- https://azure.microsoft.com/pricing/details/app-service/
- https://azure.microsoft.com/pricing/details/sql-database/

 IMPORTANTE:
- Sé conservador en estimaciones (mejor sobre-estimar que bajo-estimar)
- Incluye pequeños costos (egress, storage transactions, etc.)
- Asume 730 horas/mes (24/7)

¿Puedes generar este informe completo ahora?
```

---

## 🎨 Paso 2: Revisión del Informe HTML

### 2.1 Abrir el informe

Una vez generado:

```bash
cd docs/workshop/kitten-space-missions/solution/docs

# Verificar que existe
ls -lh finops-report.html

# Abrir en navegador
# En Linux/WSL:
xdg-open finops-report.html

# O en WSL con Windows:
explorer.exe finops-report.html

# O desde VS Code: Click derecho → Open with Live Server
```

### 2.2 Checklist de validación del informe

Verifica que el informe incluya:

#### Sección 1: Executive Summary
- [ ] **Costo total mensual** claro y destacado
- [ ] **Indicador visual** (verde/amarillo/rojo) vs budget
- [ ] **Top 3 recursos costosos** identificados
- [ ] **Score de optimización** calculado

#### Sección 2: Desglose por Recurso
- [ ] Tabla con TODOS los recursos Azure
- [ ] Columnas: Recurso, SKU, Costo, % del total
- [ ] Alternativas más económicas sugeridas
- [ ] Trade-offs documentados

Ejemplo esperado:

| Recurso | SKU | Costo/mes | % Total | Alternativa | Ahorro | Trade-off |
|---------|-----|-----------|---------|-------------|--------|-----------|
| App Service Plan | B1 | $13.14 | 35% | F1 Free | $13.14 | Sin auto-scale, 1GB RAM |
| SQL Database | Basic | $4.90 | 13% | - | - | Ya es el mínimo |
| Key Vault | Standard | $0.03 | <1% | - | - | - |
| Application Insights | PAYG | $2.88 | 8% | - | - | - |
| VNet | Standard | $0.00 | 0% | - | - | - |
| **TOTAL** | | **~$20-25** | **100%** | | | |

#### Sección 3: Análisis de SKU Comparativo
- [ ] App Service: F1 vs B1 vs B2 comparison table
- [ ] SQL Database: Basic vs S0 vs S1 comparison
- [ ] Specs técnicas de cada SKU
- [ ] Recomendación justificada

#### Sección 4: Optimizaciones
- [ ] Auto-shutdown strategy (si aplica)
- [ ] Tagging strategy propuesta
- [ ] Budget alerts configuración
- [ ] Reserved instances (si ROI positivo)

#### Sección 5: Proyección Anual
- [ ] Costo mensual × 12
- [ ] Ahorro con reservas anuales
- [ ] Proyección para prod

#### Sección 6: Risk Assessment
- [ ] Escenario: tráfico 10x
- [ ] Escenario: agregar prod environment
- [ ] Escenario: compliance requirements (GDPR)

### 2.3 Validación de cifras

**Precios de referencia Azure (westeurope, diciembre 2025)**:

```
App Service:
- F1 Free: $0/mes (limitado: 60 min/día, no custom domains)
- B1: ~$13.14/mes (1 core, 1.75GB RAM, auto-scale hasta 3 instancias)
- B2: ~$26.28/mes (2 cores, 3.5GB RAM)

SQL Database:
- Basic: $4.90/mes (2GB storage, 5 DTU)
- Standard S0: $14.70/mes (250GB, 10 DTU)
- Standard S1: $29.40/mes (250GB, 20 DTU)

Key Vault:
- Standard: $0.03/10,000 operations (prácticamente gratis para dev)

Application Insights:
- Pay-as-you-go: $2.88/GB ingestion (primeros 5GB gratis/mes)
- Estimado dev: $2-5/mes

VNet:
- Free (pagas solo por gateways, NAT, etc.)

Private Endpoint:
- $7.30/mes por endpoint + $0.01/GB procesado

Log Analytics:
- Pay-as-you-go: $2.76/GB (primeros 5GB gratis)
```

**Costo total estimado dev realista**: $30-50/mes (sin Private Endpoint), $40-60/mes (con Private Endpoint)

---

## Paso 3: Análisis de Optimizaciones

### 3.1 Optimización #1: Evaluar F1 Free tier

**Pregunta al agente**:

```
Según el informe FinOps, ¿es viable usar App Service F1 Free tier 
para el entorno dev de Kitten Space Missions?

Considera:
- Limitación 60 min CPU/día
- No auto-scaling
- 1GB RAM, 1GB storage
- Sin custom domains

¿Cómo afecta nuestros requisitos de latency p95 < 200ms y auto-scaling?
```

### 3.2 Optimización #2: Evaluar necesidad de Private Endpoint

**Pregunta al agente**:

```
El Private Endpoint cuesta ~$7/mes adicionales.

Para entorno DEV (no producción, no datos sensibles reales), 
¿podríamos usar Firewall rules en lugar de Private Endpoint?

Evalúa:
- Ahorro: $7/mes
- Trade-off de seguridad en dev
- Facilidad de acceso para developers
- Migración futura a Private Endpoint en prod

Dame tu recomendación justificada.
```

### 3.3 Optimización #3: Auto-shutdown

**Pregunta al agente**:

```
¿Podemos configurar auto-shutdown del App Service fuera de horario 
laboral para dev?

Por ejemplo:
- Activo: Lun-Vie 8am-8pm CET
- Parado: Noches y fines de semana

Calcula ahorro potencial y dame script Azure Automation o Logic App 
para implementarlo.
```

---

## Paso 4: Documentar Decisiones de Costos

### 4.1 Crear Cost Decision Record

Pide al agente:

```
Genera un documento "Cost Decision Record" en Markdown que documente 
las decisiones de optimización de costos tomadas.

Formato:
# Cost Decision Record - Kitten Space Missions Dev

**Date**: [fecha]
**Environment**: dev
**Budget Target**: $70-80/mes
**Actual Estimated**: $XX/mes

## Decisiones de SKU

### App Service
- **Elegido**: [B1 / F1 / etc]
- **Alternativas evaluadas**: ...
- **Justificación**: ...
- **Saving vs next tier**: $XX/mes

### SQL Database
...

## Optimizaciones Aplicadas

1. **Auto-shutdown**: Sí/No
 - Ahorro: $XX/mes
 - Trade-off: ...

2. **Private Endpoint**: Sí/No
 - Decisión: ...
 - Justificación: ...

## Total Cost Summary

- Base infrastructure: $XX/mes
- Optimizations: -$XX/mes
- **Final estimated**: $XX/mes
- **vs Budget**: Under budget / ⚠️ At limit / Over budget

## Next Review
- **When**: [mensual]
- **What to check**: Actual spend vs estimate, nuevas oportunidades
```

Guarda en:
```
docs/workshop/kitten-space-missions/solution/docs/cost-decision-record.md
```

### 4.2 Configurar Budget Alert en Azure (simulación)

Aunque no lo desplegaremos ahora, pide al agente el comando:

```
Dame el comando Azure CLI para configurar un budget alert de $100/mes 
en mi subscription con notificaciones a mi email cuando alcance:
- 80% del budget
- 100% del budget

Subscription: [tu subscription ID]
Email: [tu email]
```

Ejemplo de output esperado:

```bash
# Crear budget
az consumption budget create \
 --budget-name "kitten-missions-dev-budget" \
 --amount 100 \
 --time-grain Monthly \
 --start-date "2025-01-01" \
 --end-date "2026-12-31" \
 --resource-group "rg-kitten-missions-dev" \
 --notifications \
 "actual_80=threshold=80,email=tu-email@example.com" \
 "actual_100=threshold=100,email=tu-email@example.com"
```

---

## Paso 5: Comparativa Final - Escenarios

### 5.1 Tabla comparativa de escenarios

Pide al agente que complete esta tabla:

```
Genera una tabla comparativa de 3 escenarios de costos:
- Scenario A: Máxima economía (F1, sin Private Endpoint, Basic SQL)
- Scenario B: Balanceado (B1, Private Endpoint, Basic SQL) 
- Scenario C: Production-ready (B2, Private Endpoint, Standard S0 SQL)

Incluye:
- Costo mensual total
- Costo anual
- Limitaciones de cada escenario
- Cuándo usar cada uno
```

Tabla esperada:

| Feature | Scenario A: Economy | Scenario B: Balanced | Scenario C: Prod-Ready |
|---------|---------------------|----------------------|------------------------|
| App Service | F1 Free | B1 Basic | B2 Basic |
| SQL Database | Basic (2GB) | Basic (2GB) | Standard S0 (250GB) |
| Private Endpoint | No | Yes | Yes |
| Auto-scaling | No | Yes (1-3) | Yes (1-5) |
| **Costo/mes** | **~$7** | **~$45** | **~$85** |
| **Costo/año** | **~$84** | **~$540** | **~$1,020** |
| **Uso recomendado** | PoC rápido | Dev estable | Pre-prod/Prod |
| **Limitaciones** | 60min CPU/día | Storage limitado | - |

---

## Entregables de esta actividad

Al finalizar deberías tener:

- **finops-report.html** - Informe interactivo profesional
- **cost-decision-record.md** - Documentación de decisiones
- Tabla comparativa de escenarios (puede estar en el report)
- Comandos de budget alerts preparados
- Decisión clara sobre qué escenario desplegar (A, B o C)
- Validación de que costo está dentro de budget

### Commit de los entregables

```bash
cd docs/workshop/kitten-space-missions/solution/docs

# Verificar archivos
ls -l

# Add y commit
git add finops-report.html cost-decision-record.md
git commit -m "docs: add FinOps analysis and cost decisions for kitten-space-missions"
git push origin main
```

---

## Ejemplo de Decisión Final

Basado en el análisis, una decisión típica sería:

```markdown
## Decisión Final: Scenario B (Balanced)

**Justificación**:
- App Service B1: Necesario para auto-scaling y cumplir SLA 99%
- SQL Basic: Suficiente para dev, datos de prueba pequeños
- Private Endpoint: SÍ - Buena práctica desde dev, facilita migración a prod
- Cost: $45/mes Dentro de budget $70-80/mes

**Trade-offs aceptados**:
- SQL Basic limitado a 2GB (OK para dev, monitorear crecimiento)
- No geo-redundancy (solo dev)
- Single instance SQL (no HA en dev)

**Próximos pasos**:
1. Implementar Scenario B con Bicep
2. Configurar budget alert $70/mes
3. Review mensual de costos reales vs estimado
4. Plan de escalado a Scenario C para prod
```

---

## 🐛 Troubleshooting

### El informe HTML no se genera correctamente

**Solución**:
```
Si el agente tiene problemas generando HTML complejo, 
pide una versión simplificada:

"Genera el informe FinOps en HTML simple sin librerías externas.
Solo HTML + CSS inline. Tablas estáticas, sin JavaScript."
```

### Los precios del informe parecen incorrectos

**Solución**:
```
Valida manualmente en Azure Pricing Calculator:
https://azure.microsoft.com/pricing/calculator/

Ajusta el informe con precios correctos si es necesario.
```

### No puedo abrir el HTML en el navegador

**Solución**:
```bash
# En WSL, usa el explorador de Windows:
explorer.exe finops-report.html

# O instala xdg-utils:
sudo apt install xdg-utils
xdg-open finops-report.html
```

---

## Tips Pro de FinOps

### Tags para Cost Allocation

```bash
# Estrategia de tagging recomendada
Environment=dev
Project=kitten-space-missions
CostCenter=engineering
Owner=team-platform
ManagedBy=bicep-iac
```

### Review Mensual de Costos

Configura reminder para revisar:
- Azure Cost Management dashboard
- Recursos orphaned (no usados)
- Oportunidades de reserved instances
- Comparar actual vs estimado

### Herramientas FinOps Adicionales

- **Azure Cost Management**: Dashboard nativo de Azure
- **Infracost**: CLI tool para estimar costos de Terraform/Bicep
- **CloudHealth / CloudCheckr**: Plataformas enterprise de FinOps

---

## Siguiente Paso

Con el análisis FinOps completo y decisiones de costos documentadas, estás listo para generar el código Bicep de la infraestructura.

**➡️ [Actividad 4: Generación de Código Bicep](./activity-04-bicep-generation.md)**

En la siguiente actividad el agente generará todos los módulos Bicep modulares, parámetros por entorno, y siguiendo las mejores prácticas del repositorio.

---

## Referencias

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Cost Management](https://learn.microsoft.com/azure/cost-management-billing/)
- [FinOps Foundation](https://www.finops.org/)
- [Azure Reserved Instances](https://learn.microsoft.com/azure/cost-management-billing/reservations/)

---

** ¡Excelente! Ahora conoces exactamente cuánto costará tu infraestructura y tienes decisiones justificadas. ¡Vamos a generar el código!**

