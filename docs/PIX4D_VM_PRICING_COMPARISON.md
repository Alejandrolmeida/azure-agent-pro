# Comparativa de Costos por Hora - VMs GPU para AVD Pix4D

**Fecha:** 22 de Octubre de 2025  
**Suscripción:** POC AVD (36a06bba-6ca7-46f8-a1a8-4abbbebeee86)  
**Región:** West Europe  
**Modelo de Despliegue:** AVD Personal (1 VM por técnico)

---

## 🎯 Escenario: AVD Personal para Técnicos Pix4D

### Requisitos del Proyecto
- **Modelo AVD:** Personal Desktop (1 usuario = 1 VM dedicada)
- **Usuarios:** Técnicos de fotogrametría/topografía
- **Uso:** Procesamiento intensivo de Pix4Dmatic
- **Objetivo:** Maximizar rendimiento individual por técnico

---

## 💰 Comparativa de Costos por Hora (Pay-as-you-go)

### SKUs Recomendadas - Precios West Europe

| SKU | GPU | vCPU | RAM (GB) | **€/hora** | **€/día (8h)** | **€/mes (160h)** | Disponibilidad |
|-----|-----|------|----------|------------|----------------|------------------|----------------|
| **Standard_NV6ads_A10_v5** | 1/6 A10 | 6 | 55 | **€1.09** | €8.72 | €174.40 | ✅ Todas zonas |
| **Standard_NV12ads_A10_v5** | 1/3 A10 | 12 | 110 | **€2.18** | €17.44 | €348.80 | ✅ Todas zonas |
| **Standard_NV18ads_A10_v5** | 1/2 A10 | 18 | 220 | **€3.27** | €26.16 | €523.20 | ✅ Todas zonas |
| **Standard_NV36ads_A10_v5** ⭐ | 1 A10 | 36 | 440 | **€6.54** | €52.32 | €1,046.40 | ✅ Todas zonas |
| **Standard_NV72ads_A10_v5** | 2 A10 | 72 | 880 | **€13.08** | €104.64 | €2,092.80 | ✅ Todas zonas |
| | | | | | | | |
| Standard_NC8as_T4_v3 | T4 | 8 | 56 | **€0.91** | €7.28 | €145.60 | ✅ Todas zonas |
| Standard_NC16as_T4_v3 | T4 | 16 | 112 | **€1.82** | €14.56 | €291.20 | ✅ Todas zonas |
| | | | | | | | |
| **Standard_NC24ads_A100_v4** 💎 | A100 | 24 | 220 | **€4.89** | €39.12 | €782.40 | ✅ Zonas 2,3 |
| **Standard_NC48ads_A100_v4** | A100 | 48 | 440 | **€9.78** | €78.24 | €1,564.80 | ✅ Zonas 2,3 |
| | | | | | | | |
| **Standard_NC40ads_H100_v5** 🚀 | H100 | 40 | 320 | **€19.56** | €156.48 | €3,129.60 | ✅ Zona 2 |
| **Standard_NC80adis_H100_v5** | H100 | 80 | 640 | **€39.12** | €312.96 | €6,259.20 | ✅ Zona 2 |

> **Nota:** Precios estimados basados en precios públicos de Azure West Europe (octubre 2025). Los precios CSP pueden variar según acuerdos comerciales.

---

## 📊 Análisis de Costos por Perfil de Técnico

### Perfil 1: Técnico Junior / Entry-Level
**Carga de trabajo:** Proyectos pequeños (1,000-3,000 imágenes)

#### Opción A: **Standard_NV6ads_A10_v5**
- **Costo/hora:** €1.09
- **Costo/día (8h):** €8.72
- **Costo/mes (20 días, 160h):** €174.40
- **GPU:** 1/6 NVIDIA A10 (4GB VRAM)
- **Rendimiento:** Suficiente para proyectos pequeños
- **✅ Mejor para:** Inicio, formación, proyectos menores

#### Opción B: **Standard_NC8as_T4_v3**
- **Costo/hora:** €0.91
- **Costo/día (8h):** €7.28
- **Costo/mes (20 días, 160h):** €145.60
- **GPU:** NVIDIA T4 (16GB VRAM)
- **Rendimiento:** Básico pero funcional
- **✅ Mejor para:** Máxima optimización de costos

**💡 Recomendación:** `Standard_NV6ads_A10_v5` - Mejor rendimiento por pequeña diferencia de precio

---

### Perfil 2: Técnico Estándar / Mid-Level ⭐
**Carga de trabajo:** Proyectos medianos (3,000-8,000 imágenes)

#### Opción Recomendada: **Standard_NV18ads_A10_v5**
- **Costo/hora:** €3.27
- **Costo/día (8h):** €26.16
- **Costo/mes (20 días, 160h):** €523.20
- **GPU:** 1/2 NVIDIA A10 (12GB VRAM)
- **Rendimiento:** Excelente balance
- **Capacidad:** 5,000-8,000 imágenes sin problemas
- **Tiempo procesamiento (5,000 img):** ~6-8 horas

**✅ Sweet Spot:** Balance perfecto entre costo y rendimiento para el 70% de técnicos

---

### Perfil 3: Técnico Senior / Proyectos Grandes 💪
**Carga de trabajo:** Proyectos grandes (8,000-15,000 imágenes)

#### Opción Recomendada: **Standard_NV36ads_A10_v5**
- **Costo/hora:** €6.54
- **Costo/día (8h):** €52.32
- **Costo/mes (20 días, 160h):** €1,046.40
- **GPU:** 1x NVIDIA A10 completa (24GB VRAM)
- **Rendimiento:** Premium
- **Capacidad:** 10,000-15,000 imágenes
- **Tiempo procesamiento (10,000 img):** ~8-10 horas

**✅ Recomendado para:** Técnicos que procesan grandes volúmenes regularmente

---

### Perfil 4: Especialista / Proyectos Críticos 🚀
**Carga de trabajo:** Proyectos masivos (15,000+ imágenes) o demos clientes

#### Opción A: **Standard_NC24ads_A100_v4**
- **Costo/hora:** €4.89
- **Costo/día (8h):** €39.12
- **Costo/mes (20 días, 160h):** €782.40
- **GPU:** NVIDIA A100 (80GB VRAM)
- **Rendimiento:** Enterprise-grade
- **ROI:** Mejor relación rendimiento/precio para cargas pesadas

#### Opción B: **Standard_NC40ads_H100_v5** (Para impresionar)
- **Costo/hora:** €19.56
- **Costo/día (8h):** €156.48
- **Costo/mes (20 días, 160h):** €3,129.60
- **GPU:** NVIDIA H100 (80GB HBM3)
- **Rendimiento:** Máximo absoluto
- **Uso:** Demos, proyectos urgentes, clientes VIP

**💡 Recomendación:** `NC24ads_A100_v4` para uso regular, `NC40ads_H100_v5` solo para casos especiales

---

## 🏢 Cálculo de Costos para Equipo Completo

### Escenario 1: Equipo Pequeño (5 técnicos)
**Composición:**
- 2x Técnicos Junior → `NV6ads_A10_v5`
- 2x Técnicos Estándar → `NV18ads_A10_v5`
- 1x Técnico Senior → `NV36ads_A10_v5`

**Costos Mensuales (160h/mes por técnico):**
```
2 x €174.40  = €348.80   (Junior)
2 x €523.20  = €1,046.40 (Estándar)
1 x €1,046.40 = €1,046.40 (Senior)
─────────────────────────
TOTAL/mes    = €2,441.60
```

**Costo por técnico promedio:** €488.32/mes

---

### Escenario 2: Equipo Mediano (10 técnicos) ⭐
**Composición:**
- 3x Técnicos Junior → `NV6ads_A10_v5`
- 5x Técnicos Estándar → `NV18ads_A10_v5`
- 2x Técnicos Senior → `NV36ads_A10_v5`

**Costos Mensuales:**
```
3 x €174.40  = €523.20   (Junior)
5 x €523.20  = €2,616.00 (Estándar)
2 x €1,046.40 = €2,092.80 (Senior)
─────────────────────────
TOTAL/mes    = €5,232.00
```

**Costo por técnico promedio:** €523.20/mes

---

### Escenario 3: Equipo Grande (20 técnicos)
**Composición:**
- 5x Técnicos Junior → `NV6ads_A10_v5`
- 10x Técnicos Estándar → `NV18ads_A10_v5`
- 4x Técnicos Senior → `NV36ads_A10_v5`
- 1x Especialista → `NC24ads_A100_v4`

**Costos Mensuales:**
```
5 x €174.40   = €872.00    (Junior)
10 x €523.20  = €5,232.00  (Estándar)
4 x €1,046.40 = €4,185.60  (Senior)
1 x €782.40   = €782.40    (Especialista)
─────────────────────────
TOTAL/mes     = €11,072.00
```

**Costo por técnico promedio:** €553.60/mes

---

## 💡 Estrategias de Optimización de Costos

### 1. Auto-Shutdown (Ahorro estimado: 40-50%)
```bash
# Configurar apagado automático fuera de horario
# Ejemplo: Apagar a las 19:00, encender a las 08:00
# Ahorro: 13 horas/día x 5 días = 65 horas/semana

# De 160h/mes → 85h/mes (jornada laboral pura)
```

**Impacto en Escenario 2 (10 técnicos):**
- **Sin auto-shutdown:** €5,232.00/mes
- **Con auto-shutdown:** €2,785.50/mes
- **💰 Ahorro:** €2,446.50/mes (47%)

### 2. Azure Spot VMs (Ahorro: 60-90%)
**Apto para:** Desarrollo, testing, cargas no críticas

**Ejemplo - NV36ads_A10_v5:**
- **Pay-as-you-go:** €6.54/hora
- **Spot VM:** €0.65-2.00/hora (depende de disponibilidad)
- **💰 Ahorro típico:** 70% (~€4.50/hora)

**⚠️ Limitación:** La VM puede ser interrumpida si Azure necesita la capacidad

### 3. Reserved Instances (1 año - Ahorro: 40%)
**Compromiso:** 1 año pagado por adelantado

**Ejemplo - NV18ads_A10_v5:**
- **Pay-as-you-go:** €3.27/hora → €523.20/mes
- **Reserved 1 año:** €1.96/hora → €313.92/mes
- **💰 Ahorro:** €209.28/mes por VM (40%)

**Para 10 técnicos estándar:**
- **Sin Reserved:** €5,232.00/mes
- **Con Reserved:** €3,139.20/mes
- **💰 Ahorro total:** €2,092.80/mes

### 4. Reserved Instances (3 años - Ahorro: 62%)
**Compromiso:** 3 años pagado por adelantado

**Ejemplo - NV18ads_A10_v5:**
- **Pay-as-you-go:** €3.27/hora → €523.20/mes
- **Reserved 3 años:** €1.24/hora → €198.40/mes
- **💰 Ahorro:** €324.80/mes por VM (62%)

### 5. Azure Hybrid Benefit (Ahorro adicional: 40% en Windows)
Si ya tienes licencias Windows Server con Software Assurance:
- **Ahorro adicional:** ~€0.40-0.80/hora por VM
- **Aplicable a:** Todas las VMs Windows

---

## 📊 Comparativa: Costo Total de Propiedad (TCO)

### Escenario: 10 Técnicos durante 1 año

| Estrategia | Configuración | Costo Mensual | Costo Anual | vs. Base |
|------------|---------------|---------------|-------------|----------|
| **Base (Pay-as-you-go)** | 24/7 sin optimización | €5,232.00 | €62,784.00 | - |
| **Auto-shutdown** | Solo horario laboral | €2,785.50 | €33,426.00 | -47% |
| **Spot VMs** | Cargas no críticas | €1,569.60 | €18,835.20 | -70% |
| **Reserved 1 año** | Compromiso 1 año | €3,139.20 | €37,670.40 | -40% |
| **Reserved 3 años** | Compromiso 3 años | €1,984.00 | €23,808.00 | -62% |
| **Combinado Óptimo** | Reserved + Auto-shutdown | €1,672.75 | €20,073.00 | -68% |

**💡 Mejor estrategia:** Reserved Instances 1 año + Auto-shutdown = **68% de ahorro**

---

## 🎯 Recomendación Final por Presupuesto

### Presupuesto Ajustado (< €3,000/mes para 10 técnicos)
```
5x NV6ads_A10_v5  (Junior/Mid)    → €872.00
4x NV12ads_A10_v5 (Estándar)      → €1,394.00
1x NV18ads_A10_v5 (Senior)        → €523.20
                                    ────────────
TOTAL                              €2,789.20/mes
```
**+ Auto-shutdown** → €1,485.00/mes  
**+ Reserved 1 año** → €1,673.50/mes

---

### Presupuesto Estándar (€5,000-6,000/mes para 10 técnicos) ⭐
```
3x NV6ads_A10_v5  (Junior)        → €523.20
5x NV18ads_A10_v5 (Estándar)      → €2,616.00
2x NV36ads_A10_v5 (Senior)        → €2,092.80
                                    ────────────
TOTAL                              €5,232.00/mes
```
**+ Auto-shutdown** → €2,785.00/mes  
**+ Reserved 1 año** → €3,139.20/mes

---

### Presupuesto Premium (> €10,000/mes para 10 técnicos)
```
5x NV18ads_A10_v5 (Estándar)      → €2,616.00
4x NV36ads_A10_v5 (Senior)        → €4,185.60
1x NC24ads_A100_v4 (Especialista) → €782.40
                                    ────────────
TOTAL                              €7,584.00/mes
```
**+ Auto-shutdown** → €4,037.00/mes  
**+ Reserved 1 año** → €4,550.40/mes

---

## 📋 Checklist de Decisión

### ✅ Antes de seleccionar SKU considera:

1. **Tamaño promedio de proyectos**
   - [ ] < 3,000 imágenes → NV6ads o NC8as_T4
   - [ ] 3,000-8,000 imágenes → NV18ads_A10
   - [ ] > 8,000 imágenes → NV36ads_A10 o NC24ads_A100

2. **Frecuencia de uso**
   - [ ] < 4 horas/día → Considera Spot VMs
   - [ ] 4-8 horas/día → Auto-shutdown obligatorio
   - [ ] > 8 horas/día → Evaluar Reserved Instances

3. **Criticidad del trabajo**
   - [ ] Desarrollo/Testing → Spot VMs
   - [ ] Producción estándar → Pay-as-you-go + Auto-shutdown
   - [ ] Misión crítica → Reserved Instances

4. **Horizonte temporal**
   - [ ] < 6 meses → Pay-as-you-go
   - [ ] 6-12 meses → Reserved 1 año
   - [ ] > 12 meses → Reserved 3 años

---

## 💰 Calculadora Rápida

**Para calcular tu costo mensual:**

```
Número de técnicos × Costo/hora del SKU × Horas de uso mensual
```

**Ejemplo:**
```
10 técnicos × €3.27/hora (NV18ads) × 160 horas/mes = €5,232/mes
```

**Con optimizaciones:**
```
€5,232 × 0.53 (auto-shutdown) × 0.60 (reserved 1 año) = €1,664/mes
```

---

## 📞 Próximos Pasos

1. **Identificar perfiles de técnicos** - Clasificar por carga de trabajo
2. **Calcular horas de uso real** - Monitorear durante 1-2 semanas
3. **Pilot con 2-3 técnicos** - Validar SKUs seleccionadas
4. **Implementar auto-shutdown** - Reducir costos inmediatamente
5. **Evaluar Reserved Instances** - Si uso confirmado > 6 meses

---

**Documento preparado para:** Proyecto POC AVD Pix4D  
**Última actualización:** 22 de Octubre de 2025  
**Próxima revisión:** Ajustar según datos reales de uso
