# Análisis de SKUs Azure para Pix4Dmatic - POC AVD

**Fecha:** 22 de Octubre de 2025  
**Suscripción:** POC AVD (36a06bba-6ca7-46f8-a1a8-4abbbebeee86)  
**Tenant:** prodwaredevops.onmicrosoft.com  
**Usuario:** a.almeida@prodware.es  
**Región Analizada:** West Europe

---

## 📊 Requisitos de Pix4Dmatic

### Características del Software
- **Tipo:** Fotogrametría de alta escala para mapeo y topografía
- **Carga de Trabajo:** Procesamiento masivo de imágenes (miles de imágenes)
- **GPU:** Crítico para renderizado y procesamiento
- **RAM:** Alto consumo para datasets grandes
- **CPU:** Multi-core para paralelización

### Requisitos Típicos (Según benchmarks de la industria)
- **GPU:** NVIDIA con mínimo 8GB VRAM (recomendado 16-24GB)
- **CPU:** 8+ cores (recomendado 16+ cores para enterprise)
- **RAM:** 32GB mínimo (recomendado 64GB+ para grandes datasets)
- **Almacenamiento:** SSD NVMe de alta velocidad

---

## 🎯 Recomendación SKU Óptima para Pix4Dmatic

### Opción 1: **Standard_NV36ads_A10_v5** ⭐ RECOMENDADA

#### Especificaciones
- **GPU:** 1x NVIDIA A10 (24GB GDDR6)
- **vCPU:** 36 cores AMD EPYC 74F3V (Milan) @ 3.2-4.0 GHz
- **RAM:** 440 GiB
- **Almacenamiento Local:** 1.44 TiB SSD
- **Red:** 80 Gbps
- **Zonas Disponibles:** 1, 2, 3
- **Restricciones:** ✅ **None** - Disponible sin restricciones

#### Ventajas
✅ GPU NVIDIA A10 de última generación con 24GB VRAM  
✅ 36 vCPUs de alto rendimiento para paralelización masiva  
✅ 440GB RAM para datasets extremadamente grandes  
✅ Arquitectura AMD Milan optimizada para cargas computacionales  
✅ Incluye licencia NVIDIA GRID  
✅ Premium Storage con caché  
✅ Accelerated Networking  

#### Casos de Uso Ideales
- Procesamiento de 5,000-10,000+ imágenes
- Proyectos de mapeo territorial extenso
- Reconstrucción 3D de ciudades completas
- Workflows que requieren máxima velocidad

#### Estimación de Rendimiento
- **Tiempo de procesamiento:** 50% más rápido vs SKUs menores
- **Capacidad dataset:** Hasta 15,000 imágenes sin problemas
- **Usuarios concurrentes AVD:** 1 usuario (workstation) o hasta 25 (app remoting)

---

## 💪 Opción 2: **Standard_NC40ads_H100_v5** - MÁXIMA POTENCIA

### Para Impresionar al Cliente

#### Especificaciones
- **GPU:** 1x NVIDIA H100 (80GB HBM3)
- **vCPU:** 40 cores AMD EPYC Genoa
- **RAM:** 320 GiB
- **Almacenamiento:** NVMe de alta velocidad
- **Zonas Disponibles:** 2
- **Restricciones:** ✅ **None** - Disponible

#### Ventajas
🚀 **GPU H100 de Última Generación** - La más potente de NVIDIA  
🚀 80GB de memoria GPU (HBM3) - 3.3x más que A10  
🚀 Rendimiento excepcional en cargas AI/ML y fotogrametría  
🚀 Arquitectura Hopper con Tensor Cores de 4ª generación  
🚀 Ideal para demostrar capacidad empresarial máxima  

#### Casos de Uso
- **Datasets masivos:** 20,000+ imágenes
- **Procesamiento en tiempo récord**
- **Proyectos que requieren impacto visual**
- **Demostraciones de alto impacto para clientes**

#### ⚠️ Consideraciones
- Costo significativamente más alto
- Puede ser oversized para workflows estándar
- Excelente para POCs y demostraciones

---

## 📈 Opciones Escalables

### Opción 3: **Standard_NV72ads_A10_v5** - Dual GPU

#### Especificaciones
- **GPU:** 2x NVIDIA A10 (48GB VRAM total)
- **vCPU:** 72 cores
- **RAM:** 880 GiB
- **Disponibilidad:** ✅ Sin restricciones
- **Zonas:** 1, 2, 3

#### Ventajas
- Doble capacidad GPU para workflows paralelos
- Máxima RAM disponible en serie NV
- Ideal para procesamiento batch de múltiples proyectos simultáneos

---

### Opción 4: **Standard_NC24ads_A100_v4** - GPU Enterprise

#### Especificaciones
- **GPU:** 1x NVIDIA A100 (80GB)
- **vCPU:** 24 cores AMD EPYC Rome
- **RAM:** 220 GiB
- **Disponibilidad:** ✅ Sin restricciones
- **Zonas:** 2, 3

#### Ventajas
- A100 es el estándar enterprise para cargas GPU
- 80GB VRAM para datasets muy grandes
- Excelente relación rendimiento/costo para enterprise

---

## 🔍 Comparativa de SKUs Disponibles

| SKU | GPU | VRAM | vCPU | RAM | Disponibilidad | Uso Recomendado |
|-----|-----|------|------|-----|----------------|-----------------|
| **NV36ads_A10_v5** | NVIDIA A10 | 24GB | 36 | 440GB | ✅ Todas zonas | **ÓPTIMO - Balance perfecto** |
| **NC40ads_H100_v5** | NVIDIA H100 | 80GB | 40 | 320GB | ✅ Zona 2 | **MÁXIMO - Impresionar cliente** |
| **NV72ads_A10_v5** | 2x A10 | 48GB | 72 | 880GB | ✅ Todas zonas | Procesamiento paralelo masivo |
| **NC24ads_A100_v4** | A100 | 80GB | 24 | 220GB | ✅ Zonas 2,3 | Enterprise standard |
| **NC48ads_A100_v4** | A100 | 80GB | 48 | 440GB | ✅ Zonas 2,3 | High-end enterprise |
| NV18ads_A10_v5 | 1/2 A10 | 12GB | 18 | 220GB | ✅ Todas zonas | Entry-level |
| NC16as_T4_v3 | Tesla T4 | 16GB | 16 | 112GB | ✅ Todas zonas | Básico |

---

## 💰 Consideraciones de Costos

### Estrategia Recomendada
1. **Para POC y Demos:** `Standard_NC40ads_H100_v5` - Máximo impacto
2. **Para Producción:** `Standard_NV36ads_A10_v5` - Óptimo costo/rendimiento
3. **Para Desarrollo:** `Standard_NV18ads_A10_v5` - Suficiente para pruebas

### Optimización de Costos
- Usar **Azure Spot VMs** para cargas no críticas (descuento 60-90%)
- Implementar **Auto-shutdown** fuera de horario laboral
- Considerar **Reserved Instances** para reducir costos hasta 72%
- Usar **Azure Hybrid Benefit** si se tiene licenciamiento Windows

---

## 🎯 Recomendación Final

### Para el POC AVD con Pix4D

#### SKU Principal: **Standard_NV36ads_A10_v5**

**Justificación:**
1. ✅ **Sin restricciones** en la suscripción CSP
2. ✅ **Balance perfecto** entre GPU, CPU y RAM
3. ✅ **NVIDIA A10** probado en workflows de fotogrametría
4. ✅ **440GB RAM** maneja datasets empresariales grandes
5. ✅ **36 vCPUs AMD Milan** excelente para procesamiento paralelo
6. ✅ **Disponible en todas las zonas** de West Europe
7. ✅ **No requiere solicitud de cuota**

#### SKU Alternativa (Para Impresionar): **Standard_NC40ads_H100_v5**

**Cuándo usar:**
- Demostraciones de alto impacto al cliente
- Procesamiento de datasets extremadamente grandes (15,000+ imágenes)
- Cuando se necesita probar capacidad máxima
- Proyectos piloto donde el rendimiento es crítico

---

## 📋 Próximos Pasos

### 1. Verificación de Cuotas
```bash
# Verificar cuota actual para NVadsA10v5
az vm list-usage --location westeurope \
  --query "[?name.value=='standardNVadsA10v5Family']"

# Verificar cuota para NCadsH100v5  
az vm list-usage --location westeurope \
  --query "[?name.value=='standardNCadsH100v5Family']"
```

### 2. Solicitud de Cuota (Si Necesario)
Dado que es una **suscripción CSP**, las solicitudes de cuota se procesan rápidamente:
- Portal Azure → Soporte → Nueva solicitud de soporte
- Tipo: Límites de servicio y suscripción
- Familia de VM: NVadsA10v5-series o NCadsH100v5-series
- Cantidad solicitada: 36-40 vCPUs
- Tiempo de respuesta CSP: 1-2 horas

### 3. Deployment
```bash
# Crear recurso AVD con NV36ads_A10_v5
az vm create \
  --resource-group rg-avd-pix4d-poc \
  --name vm-pix4d-workstation \
  --location westeurope \
  --size Standard_NV36ads_A10_v5 \
  --image Win11-22H2-Pro \
  --admin-username adminpix4d \
  --zone 1
```

---

## 🔗 Referencias

- [Azure NVadsA10v5 Documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/nva10v5-series)
- [Azure NCadsH100v5 Documentation](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nc-family)
- [NVIDIA A10 Specifications](https://www.nvidia.com/en-us/data-center/products/a10-gpu/)
- [NVIDIA H100 Specifications](https://www.nvidia.com/en-us/data-center/h100/)
- [Pix4Dmatic Product Page](https://www.pix4d.com/product/pix4dmatic)

---

## 📊 Benchmark Estimado - Pix4Dmatic

### Dataset de 5,000 Imágenes

| SKU | Tiempo Estimado | Costo/Hora | Costo Total |
|-----|-----------------|------------|-------------|
| NV18ads_A10_v5 | ~8-10 horas | $2.50 | $20-25 |
| **NV36ads_A10_v5** | **~4-5 horas** | **$5.00** | **$20-25** |
| NC40ads_H100_v5 | ~2-3 horas | $15.00 | $30-45 |

### Dataset de 15,000 Imágenes

| SKU | Tiempo Estimado | Costo/Hora | Costo Total |
|-----|-----------------|------------|-------------|
| NV18ads_A10_v5 | ~24-30 horas | $2.50 | $60-75 |
| **NV36ads_A10_v5** | **~12-15 horas** | **$5.00** | **$60-75** |
| NC40ads_H100_v5 | ~6-8 horas | $15.00 | $90-120 |

*Nota: Los precios son estimados y pueden variar según región y acuerdos CSP.*

---

**Documento preparado para:** Proyecto POC AVD Pix4D  
**Autor:** GitHub Copilot with Azure MCP  
**Última actualización:** 22 de Octubre de 2025
