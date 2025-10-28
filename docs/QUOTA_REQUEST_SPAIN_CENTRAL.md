# Solicitud de Ampliación de Cuota - Spain Central

**Fecha:** 22 de Octubre de 2025  
**Suscripción:** POC AVD (36a06bba-6ca7-46f8-a1a8-4abbbebeee86)  
**Tenant:** prodwaredevops.onmicrosoft.com  
**Región:** Spain Central (spaincentral)

---

## ✅ Verificación de Disponibilidad Completada

### 1. Familias de VM Verificadas

#### Standard NVadsA10v5 Family ✅
**Disponibilidad en Spain Central:** CONFIRMADA

**SKUs Disponibles:**
- Standard_NV6ads_A10_v5 (6 vCPU, 1/6 GPU, 4GB VRAM) - Zona 2
- Standard_NV12ads_A10_v5 (12 vCPU, 1/3 GPU, 8GB VRAM) - Zona 2
- Standard_NV18ads_A10_v5 (18 vCPU, 1/2 GPU, 12GB VRAM) - Zona 2
- Standard_NV36ads_A10_v5 (36 vCPU, 1 GPU, 24GB VRAM) - Zona 2
- Standard_NV72ads_A10_v5 (72 vCPU, 2 GPUs, 48GB VRAM) - Zona 2

**Restricciones:** None

#### Standard NCadsH100v5 Family ✅
**Disponibilidad en Spain Central:** CONFIRMADA

**SKUs Disponibles:**
- Standard_NC40ads_H100_v5 (40 vCPU, 1 H100, 80GB VRAM) - Zona 1
- Standard_NC80adis_H100_v5 (80 vCPU, 2 H100, 160GB VRAM) - Zona 1

**Restricciones:** None

### 2. Azure Virtual Desktop (AVD) ✅
**Disponibilidad en Spain Central:** CONFIRMADA

Según la documentación oficial de Microsoft:
- Spain Central está listada como región soportada para AVD
- Soporta Host Pools, Workspaces, y Application Groups
- Disponibilidad de metadata store en la región

**Fuente:** [Data locations for Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/virtual-desktop/data-locations)

---

## 📋 Solicitud de Cuota

### Cuota Actual

| Familia de VM | Cuota Actual | Límite Actual |
|---------------|--------------|---------------|
| Standard NVADSA10v5 Family vCPUs | 0 | 0 |
| Standard NCadsH100v5 Family vCPUs | 0 | 0 |

### Cuota Solicitada

| Familia de VM | Cuota Solicitada | Justificación |
|---------------|------------------|---------------|
| **Standard NVADSA10v5 Family vCPUs** | **42 vCPUs** | Despliegue AVD Personal Desktop para usuarios Pix4Dmatic:<br>- 1x NV36ads_A10_v5 (36 vCPU) = 36 cores<br>- 1x NV6ads_A10_v5 (6 vCPU) = 6 cores<br>**Total: 42 vCPUs** |
| **Standard NCadsH100v5 Family vCPUs** | **40 vCPUs** | POC/Demo de máxima capacidad para cliente:<br>- 1x NC40ads_H100_v5 (40 vCPU) = 40 cores<br>**Total: 40 vCPUs** |

---

## 🎯 Caso de Uso

### Proyecto: POC Azure Virtual Desktop con Pix4Dmatic

**Descripción:**
Proof of Concept para despliegue de Azure Virtual Desktop (AVD) con modelo Personal Desktop para usuarios de Pix4Dmatic, software de fotogrametría que requiere aceleración GPU CUDA.

**Arquitectura:**
- **Modelo AVD:** Personal Desktop (1 VM dedicada por usuario)
- **Software:** Pix4Dmatic (requiere CUDA para procesamiento de imágenes)
- **Región:** Spain Central (proximidad a usuarios en España)

### Configuración Solicitada

#### Configuración 1: Producción (NVadsA10v5)
- **VM Principal:** 1x Standard_NV36ads_A10_v5
  - GPU: NVIDIA A10 (24GB VRAM)
  - vCPU: 36 cores
  - RAM: 440 GB
  - Uso: Usuario senior/técnico principal
  
- **VM Secundaria:** 1x Standard_NV6ads_A10_v5
  - GPU: NVIDIA A10 (1/6 partición, 4GB VRAM)
  - vCPU: 6 cores
  - RAM: 55 GB
  - Uso: Usuario junior/desarrollo

**Total solicitado:** 42 vCPUs

#### Configuración 2: Demo/POC (NCadsH100v5)
- **VM Demo:** 1x Standard_NC40ads_H100_v5
  - GPU: NVIDIA H100 (80GB VRAM)
  - vCPU: 40 cores
  - RAM: 320 GB
  - Uso: Demostraciones de alto impacto y pruebas de rendimiento máximo

**Total solicitado:** 40 vCPUs

---

## 📊 Justificación Técnica

### Requisitos de Pix4Dmatic
- **GPU:** NVIDIA con soporte CUDA (confirmado: todas las familias NV/NC soportan CUDA)
- **VRAM:** Mínimo 16GB (recomendado 24GB para datasets grandes)
- **CPU:** Mínimo 16 cores para paralelización
- **RAM:** Mínimo 64GB (recomendado 128GB+ para enterprise)

### Rendimiento Estimado
| SKU | Dataset 5,000 img | Dataset 15,000 img | Uso Recomendado |
|-----|-------------------|--------------------|--------------------|
| NV36ads_A10_v5 | 4-5 horas | 12-15 horas | Producción estándar |
| NC40ads_H100_v5 | 2-3 horas | 6-8 horas | POC/Demo premium |

### Beneficios de Spain Central
1. ✅ **Latencia óptima:** Proximidad a usuarios en España
2. ✅ **Compliance:** Datos residentes en España/EU
3. ✅ **AVD nativo:** Soporte completo de Azure Virtual Desktop
4. ✅ **Zonas de disponibilidad:** Alta disponibilidad (Zona 1 y 2)
5. ✅ **Sin restricciones:** Ambas familias disponibles sin limitaciones

---

## 🔧 Plan de Implementación

### Fase 1: Configuración Inicial (Semana 1)
1. Crear Host Pool AVD en Spain Central
2. Desplegar 1x NV36ads_A10_v5 (usuario técnico principal)
3. Instalar Pix4Dmatic + CUDA drivers
4. Configurar perfiles de usuario FSLogix

### Fase 2: Expansión (Semana 2-3)
5. Desplegar 1x NV6ads_A10_v5 (usuario junior/dev)
6. Configurar auto-shutdown para optimización de costos
7. Implementar monitorización Azure Monitor

### Fase 3: Demo/POC (Bajo demanda)
8. Desplegar 1x NC40ads_H100_v5 para demostraciones
9. Benchmark de rendimiento con datasets reales
10. Presentación a stakeholders

---

## 💰 Estimación de Costos

### Configuración Producción (NVadsA10v5)
| VM | vCPU | Coste/hora | Uso mensual | Coste mensual |
|----|------|------------|-------------|---------------|
| NV36ads_A10_v5 | 36 | €6.54 | 160h (8h/día × 20 días) | €1,046.40 |
| NV6ads_A10_v5 | 6 | €1.09 | 160h (8h/día × 20 días) | €174.40 |
| **Total Producción** | **42** | | | **€1,220.80/mes** |

**Con auto-shutdown (47% ahorro):** €647.02/mes

### Configuración Demo (NCadsH100v5)
| VM | vCPU | Coste/hora | Uso mensual | Coste mensual |
|----|------|------------|-------------|---------------|
| NC40ads_H100_v5 | 40 | €19.56 | 40h (demos/POC) | €782.40 |

**Total estimado mensual:** €1,429.42 (con optimización)

---

## 📞 Información de Contacto

**Usuario solicitante:**
- Nombre: a.almeida@prodware.es
- Rol: Azure Administrator
- Empresa: Prodware

**Subscription Details:**
- Subscription ID: 36a06bba-6ca7-46f8-a1a8-4abbbebeee86
- Subscription Name: POC AVD
- Tenant ID: b5a68ec8-e110-4be5-b500-173db93ba29f
- Tenant: prodwaredevops.onmicrosoft.com

---

## ✅ Checklist de Verificación

- [x] Disponibilidad de NVadsA10v5 en Spain Central verificada
- [x] Disponibilidad de NCadsH100v5 en Spain Central verificada
- [x] Disponibilidad de AVD en Spain Central verificada
- [x] Cuota actual verificada (0 vCPUs en ambas familias)
- [x] Caso de uso documentado
- [x] Justificación técnica incluida
- [x] Estimación de costos calculada
- [x] Plan de implementación definido

---

## 📝 Notas Adicionales

### Por qué Spain Central y no West Europe
1. **Latencia reducida:** Usuarios ubicados en España
2. **Compliance local:** Datos residentes en territorio español
3. **Disponibilidad confirmada:** Ambas familias + AVD disponibles
4. **Zonas redundantes:** Mayor resiliencia (2 zonas disponibles)

### Alternativas Evaluadas
- **West Europe:** Mayor capacidad pero mayor latencia para usuarios españoles
- **France Central:** Opción viable pero Spain Central preferible por proximidad

---

**Documento preparado para:** Solicitud de Cuota Azure  
**Estado:** Pendiente de envío  
**Fecha:** 22 de Octubre de 2025
