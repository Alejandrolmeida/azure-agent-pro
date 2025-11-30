# Low-Emission BiciMAD Router

**Hackathon**: DataSaturday Madrid 2025  
**Categoría**: Movilidad Sostenible + Open Data  
**Fecha de creación**: 28 noviembre 2025  
**Autor**: Alejandro Almeida

---

## 📋 Resumen Ejecutivo

**Low-Emission BiciMAD Router** es una aplicación web que calcula rutas inteligentes en bicicleta eléctrica (BiciMAD) en Madrid minimizando la exposición a contaminación atmosférica. Combina datos en tiempo real de:

- 🚴 **Disponibilidad de BiciMAD** (estaciones, bicis libres, anclajes)
- 🌫️ **Calidad del aire** (NO₂, PM10, PM2.5) por zona geográfica
- 🗺️ **Azure Maps** para cálculo de rutas ciclables

**Propuesta de valor**:
- **Para usuarios**: Rutas más saludables que evitan zonas con alta contaminación
- **Para la ciudad**: Datos para planificar infraestructura ciclista basada en calidad del aire
- **Para el hackathon**: Demo de reutilización de datos abiertos con impacto real en salud pública

---

## 🎯 Contexto del Hackathon

### DataSaturday Madrid 2025

El hackathon se enmarca en:
- **IV Plan de Gobierno Abierto (2024-2027)** del Ayuntamiento de Madrid
- **Premios a la Reutilización de Datos Abiertos 2025**
- Alineación con ODS 11 (Ciudades sostenibles) y ODS 3 (Salud y bienestar)

### Fuentes de datos disponibles

| Fuente | Datos | Actualización | Formato |
|--------|-------|---------------|---------|
| Ayuntamiento Madrid | BiciMAD disponibilidad | 20 min | JSON |
| Ayuntamiento Madrid | Calidad aire tiempo real | 20 min | JSON/CSV |
| Comunidad Madrid | Calidad aire horario | 1 hora | CSV/API |
| Ayuntamiento Madrid | Calidad aire histórico | Diario | CSV |

---

## 🎯 Objetivos del Proyecto

### Objetivos Funcionales

1. ✅ Calcular rutas en bicicleta entre dos puntos de Madrid
2. ✅ Mostrar disponibilidad en tiempo real de estaciones BiciMAD
3. ✅ Integrar niveles de contaminación (NO₂, PM10, PM2.5) por zona
4. ✅ Generar un **score de emisiones** para cada ruta propuesta
5. ✅ Visualizar múltiples alternativas de ruta con comparativa

### Objetivos No Funcionales

- **Performance**: Respuesta < 2 segundos para cálculo de ruta
- **Disponibilidad**: 99.5% uptime durante el hackathon
- **Escalabilidad**: Soporte para 100 usuarios concurrentes
- **Costo**: < $50 USD durante el mes del hackathon
- **UX**: Interfaz responsive, mobile-first, accesible (WCAG 2.1 AA)

### Objetivos Técnicos (Showcase)

- 🏗️ **Infrastructure as Code**: 100% Bicep, cero configuración manual
- 🔄 **CI/CD**: GitHub Actions con OIDC (secretless)
- 📊 **Observabilidad**: Application Insights para monitorización completa
- 💰 **FinOps**: Tracking de costos por recurso en tiempo real
- 🔒 **Seguridad**: Zero Trust, Managed Identities, Key Vault

---

## 🏛️ Propuesta de Valor

### Para el Jurado

1. **Impacto real**: Mejora salud respiratoria de ciclistas urbanos
2. **Innovación técnica**: Cruce inteligente de múltiples datasets (movilidad + medio ambiente)
3. **Reutilización de datos**: Aprovecha 3+ fuentes oficiales de datos abiertos
4. **Arquitectura profesional**: Patron enterprise-grade con Azure best practices
5. **Extensibilidad**: Fácil adaptar a otros modos (patinetes, peatones, runners)

### Diferenciadores

❌ **No es** un simple calculador de rutas (eso ya existe en Google Maps)  
✅ **Es** un optimizador que prioriza salud sobre distancia mínima  

❌ **No es** una app de consulta estática de calidad del aire  
✅ **Es** integración dinámica en el flujo de decisión de movilidad  

---

## 📐 Casos de Uso

### Caso de Uso 1: "Ir al trabajo evitando contaminación"

**Actor**: Ciclista urbano  
**Escenario**: Quiero ir de Malasaña a Retiro en BiciMAD

**Flujo**:
1. Usuario abre la web en móvil
2. Introduce origen: "Calle Fuencarral, 10"
3. Introduce destino: "Parque del Retiro"
4. Sistema muestra 3 rutas:
   - 🟢 **Ruta Verde** (2.8 km, 14 min, score contaminación: 25/100)
   - 🟡 **Ruta Balanceada** (2.3 km, 11 min, score: 45/100)
   - 🔴 **Ruta Rápida** (2.0 km, 9 min, score: 72/100)
5. Usuario selecciona Ruta Verde
6. Mapa muestra: estación origen con 8 bicis disponibles, ruta con overlay de calidad aire, estación destino con 5 anclajes libres

### Caso de Uso 2: "Consulta preventiva para runners"

**Actor**: Runner que también quiere evitar zonas contaminadas  
**Escenario**: Planificar ruta de running matinal

**Flujo**:
1. Usuario activa modo "preview calidad aire"
2. Mapa muestra heat map de NO₂ en tiempo real por distrito
3. Identifica que Gran Vía tiene valores altos (>100 µg/m³)
4. Decide correr por Casa de Campo (valores <30 µg/m³)

---

## 💡 Extensiones Futuras

- 🌡️ Integrar datos meteorológicos (viento dispersa contaminantes)
- 🚦 Cruzar con datos de tráfico (más coches = más emisiones)
- 📈 Predicciones con ML (forecasting de calidad aire 2h adelante)
- 🏆 Gamificación (badges por "km verdes" acumulados)
- 🔔 Alertas push cuando calidad aire mejora en tu ruta habitual

---

## 🏗️ Arquitectura Azure

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER BROWSER                             │
│                    (Mobile/Desktop - HTTPS)                      │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              Azure Static Web Apps (Frontend)                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  • index.html (Leaflet.js map)                           │  │
│  │  • app.js (API calls, routing logic)                     │  │
│  │  • styles.css (responsive design)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────┬────────────────────────────────────────────────┘
                 │ HTTPS
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│           Azure Functions (Backend - Python 3.11)                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  /api/stations        → BiciMAD disponibilidad           │  │
│  │  /api/air-quality     → Calidad aire por coordenadas     │  │
│  │  /api/calculate-route → Algoritmo routing + scoring      │  │
│  │  /api/health          → Health check                     │  │
│  └──────────────────────────────────────────────────────────┘  │
└──┬─────────────┬────────────────┬──────────────────────────────┘
   │             │                │
   │             │                └──────► Azure Maps API
   │             │                         (Directions API)
   │             │
   │             ▼
   │    ┌─────────────────────┐
   │    │  Azure Storage       │
   │    │  • Blob: cache datos │
   │    │  • Table: logs       │
   │    └─────────────────────┘
   │
   ▼
┌────────────────────────────────────┐
│  External APIs (Open Data)         │
│  ┌──────────────────────────────┐ │
│  │ Ayuntamiento Madrid:          │ │
│  │ • BiciMAD JSON endpoint       │ │
│  │ • Calidad aire tiempo real    │ │
│  └──────────────────────────────┘ │
│  ┌──────────────────────────────┐ │
│  │ Comunidad Madrid:             │ │
│  │ • Calidad aire horario        │ │
│  └──────────────────────────────┘ │
└────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                    Cross-Cutting Concerns                       │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐ │
│  │ App Insights   │  │   Key Vault    │  │  Log Analytics   │ │
│  │ (Monitoring)   │  │   (Secrets)    │  │   Workspace      │ │
│  └────────────────┘  └────────────────┘  └──────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

---

### Componentes Azure Detallados

#### 1. Azure Static Web Apps
**SKU**: Free tier (suficiente para hackathon)

**Justificación**:
- Hosting estático + CDN global incluido
- SSL automático
- GitHub Actions integration out-of-the-box
- API proxying (evita CORS)

**Configuración**:
- Custom domain: `bicimad-router.azurestaticapps.net`
- Build preset: HTML/JavaScript/CSS vanilla
- API backend: Azure Functions (integrado)

#### 2. Azure Functions
**Plan**: Consumption (serverless)  
**Runtime**: Python 3.11  
**Región**: West Europe

**Justificación**:
- Pay-per-execution (ideal para tráfico bajo del hackathon)
- Auto-scaling hasta 200 instancias
- Cold start < 2s aceptable para demo
- Managed identity para acceso a Key Vault/Storage

**Funciones a implementar**:

| Endpoint | Método | Propósito | Timeout |
|----------|--------|-----------|---------|
| `/api/stations` | GET | Lista estaciones BiciMAD con disponibilidad | 10s |
| `/api/air-quality` | GET | Calidad aire para coordenadas dadas | 15s |
| `/api/calculate-route` | POST | Calcula 3 rutas con scoring | 30s |
| `/api/health` | GET | Health check para monitoring | 5s |

#### 3. Azure Storage Account
**SKU**: Standard LRS (Locally Redundant)  
**Servicios usados**: Blob + Table

**Justificación**:
- **Blob Storage**: Cache de respuestas de APIs externas (reduce latencia y llamadas)
- **Table Storage**: Logs de uso para analytics post-hackathon
- Costo mínimo (~$0.02/GB)

**Estructura**:
```
bicimad-cache/
  ├── stations/current.json (TTL: 20 min)
  ├── air-quality/current.json (TTL: 20 min)
  └── air-quality/historical/ (CSVs por día)

logs-table/
  ├── RouteCalculations (partition key: date)
  └── APIUsage (partition key: endpoint)
```

#### 4. Azure Maps
**SKU**: Gen2 (S1)  
**APIs usadas**: Directions API

**Justificación**:
- Cálculo de rutas ciclables nativo
- 1000 transacciones gratis/mes (suficiente para demo)
- Alternativa europea a Google Maps (GDPR-friendly)

**Configuración**:
- Travel mode: `bicycle`
- Route type: `shortest` + `eco` + `fastest` (3 variantes)
- Avoid: highways, tunnels

#### 5. Application Insights
**Workspace**: Log Analytics Workspace  
**Retention**: 30 días (tier gratis)

**Métricas clave**:
- Request rate y latencia por endpoint
- Exception tracking
- Dependency calls (APIs externas)
- Custom events: `RouteCalculated`, `StationSelected`

#### 6. Key Vault
**SKU**: Standard

**Secrets almacenados**:
- `azure-maps-api-key`
- `ayto-madrid-api-key` (si requiere)
- `storage-connection-string`

**Acceso**:
- Managed Identity de Azure Functions con policy `Get` + `List`

---

### Decisiones Arquitectónicas (ADRs)

#### ADR-001: ¿Por qué Azure Functions y no App Service?

**Decisión**: Azure Functions Consumption Plan  
**Alternativas consideradas**: App Service B1, Container Apps  

**Razones**:
- ✅ Costo: $0 si <1M ejecuciones/mes
- ✅ Simplicity: No gestión de instancias
- ✅ Fit: Workload intermitente del hackathon
- ❌ Con: Cold start (mitigado con health checks)

#### ADR-002: ¿Por qué Static Web Apps y no Blob Storage + CDN?

**Decisión**: Azure Static Web Apps  
**Alternativas consideradas**: Blob Storage $web + Azure CDN  

**Razones**:
- ✅ Integración GitHub Actions nativa
- ✅ Preview deployments en PRs
- ✅ Routing rules incluido
- ✅ API backend proxy (evita CORS)
- ❌ Con: Menos control sobre cache headers

#### ADR-003: ¿Por qué Python y no Node.js para Functions?

**Decisión**: Python 3.11  
**Alternativas consideradas**: Node.js, C#  

**Razones**:
- ✅ Ecosystem de data science (pandas, numpy) si expandimos a ML
- ✅ Sintaxis clara para algoritmo de scoring
- ✅ requests, httpx para API calls
- ❌ Con: Cold start ligeramente más lento que Node.js

#### ADR-004: ¿Por qué Leaflet.js y no Mapbox/Google Maps?

**Decisión**: Leaflet.js + OpenStreetMap tiles  
**Alternativas consideradas**: Mapbox GL JS, Google Maps JS API  

**Razones**:
- ✅ Open source, sin vendor lock-in
- ✅ Gratuito, sin límites de requests
- ✅ Ligero (40KB minified)
- ✅ Plugins disponibles (routing, heat maps)
- ❌ Con: Menos features que Mapbox (pero suficiente para demo)

---

### Networking y Seguridad

#### Networking

```
┌────────────────────────────────────────────────────┐
│  Azure Static Web Apps                              │
│  ↓ Custom domain (opcional)                         │
│  ↓ HTTPS enforced (Let's Encrypt)                   │
└────────────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────────┐
│  Azure Functions                                    │
│  • IP allowlist: solo Static Web Apps (opcional)   │
│  • CORS: enabled para *.azurestaticapps.net        │
│  • Authentication: Anonymous (APIs públicas)       │
└────────────────────────────────────────────────────┘
```

**Nota**: Para hackathon usamos configuración abierta. Para producción agregaríamos:
- API Management con rate limiting
- Managed VNet para Functions
- Private Endpoints para Storage/Key Vault

#### Seguridad

| Control | Implementación | Justificación |
|---------|----------------|---------------|
| **Secrets** | Key Vault con Managed Identity | Zero secrets en código/config |
| **HTTPS** | Enforced en Static Web Apps | Protege datos en tránsito |
| **CORS** | Whitelist de dominios | Previene XSS desde dominios maliciosos |
| **Input validation** | Validación en Functions | Previene injection attacks |
| **Rate limiting** | App Insights + custom code | Previene DoS (100 req/min por IP) |
| **Dependency scanning** | Dependabot | Actualiza librerías con CVEs |

---

### Well-Architected Framework Assessment

#### ✅ Reliability (Confiabilidad)
- Health checks en todas las Functions
- Retry logic para APIs externas (3 intentos con backoff)
- Cache en Storage para degradación graceful si API externa falla
- SLA esperado: 99.5% (limitado por APIs externas)

#### ✅ Security (Seguridad)
- Managed Identities > Service Principals
- Key Vault para secretos
- HTTPS everywhere
- Input validation en todos los endpoints
- Application Insights para audit logging

#### ✅ Cost Optimization (FinOps)
- Consumption plan = pay-per-use
- Cache agresivo (TTL 20 min) reduce llamadas a APIs
- Static Web Apps free tier
- Budget alert a $30 USD

#### ✅ Operational Excellence (Excelencia Operativa)
- IaC al 100% con Bicep
- CI/CD con GitHub Actions
- Monitoring con Application Insights
- Documentación inline en código

#### ✅ Performance Efficiency (Rendimiento)
- CDN global para static assets
- Response caching en Functions
- Lazy loading de mapas
- Compresión gzip habilitada

---

## 📊 Fuentes de Datos y Estrategia de Ingesta

### Datasets Principales

#### 1. BiciMAD - Disponibilidad en Tiempo Real

**Fuente**: Ayuntamiento de Madrid  
**Endpoint**: `https://datos.madrid.es/egob/catalogo/300261-0-bicimad-disponibilidad.json`  
**Formato**: JSON  
**Actualización**: Cada 20 minutos  
**Autenticación**: No requerida (pública)

**Estructura de datos**:
```json
{
  "@context": "...",
  "@graph": [
    {
      "@id": "https://datos.madrid.es/egob/catalogo/300261-0-bicimad-disponibilidad/1",
      "id": "1",
      "name": "Puerta del Sol A",
      "address": {
        "street-address": "Plaza Puerta del Sol, 1",
        "locality": "Madrid"
      },
      "location": {
        "latitude": 40.416775,
        "longitude": -3.703790
      },
      "total_bases": 30,
      "free_bases": 12,
      "dock_bikes": 15,
      "reservations_count": 3,
      "light": 1,
      "activate": 1
    }
  ]
}
```

**Campos relevantes**:
- `id`: Identificador único de estación
- `name`: Nombre estación
- `location.latitude/longitude`: Coordenadas GPS
- `dock_bikes`: Bicis disponibles para alquilar
- `free_bases`: Anclajes libres para devolver
- `activate`: 1=activa, 0=mantenimiento

**Estrategia de ingesta**:
- **Caching**: Almacenar en Azure Blob Storage con TTL 20 min
- **Fallback**: Si API falla, servir desde cache (stale data < 40 min aceptable)
- **Transformación**: Convertir a GeoJSON para Leaflet.js

---

#### 2. Calidad del Aire - Tiempo Real

**Fuente**: Ayuntamiento de Madrid  
**Endpoint**: `https://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextchannel=374512b9ace9f310VgnVCM100000171f5a0aRCRD&vgnextoid=41e01e007c9db410VgnVCM2000000c205a0aRCRD`  
**Formato**: CSV (convertir a JSON)  
**Actualización**: Cada 20 minutos  
**Autenticación**: No requerida

**Estructura CSV**:
```csv
ESTACION,MAGNITUD,PUNTO_MUESTREO,ANO,MES,DIA,H01,V01,H02,V02,...,H24,V24
28079004,1,28079004_1_1,2025,11,28,12,V,15,V,...,8,V
```

**Campos relevantes**:
- `ESTACION`: ID estación medición
- `MAGNITUD`: Código contaminante (1=SO2, 6=CO, 7=NO, 8=NO2, 9=PM2.5, 10=PM10, 12=NO, 14=O3)
- `H01-H24`: Valores horarios (µg/m³)
- `V01-V24`: Validez del dato (V=válido, N=no válido)

**Magnitudes a usar**:
- **8 (NO₂)**: Dióxido de nitrógeno (irritante respiratorio)
- **10 (PM10)**: Partículas <10µm (penetran pulmones)
- **9 (PM2.5)**: Partículas <2.5µm (más peligrosas)

**Estaciones de medición** (28 en total):
```
4 - Pza. de España
8 - Escuelas Aguirre
11 - Av. Ramón y Cajal
16 - Arturo Soria
18 - Farolillo
24 - Casa de Campo
27 - Barajas Pueblo
35 - Pza. del Carmen
36 - Moratalaz
38 - Cuatro Caminos
39 - Barrio del Pilar
40 - Vallecas
... (28 total)
```

**Estrategia de ingesta**:
- **Parsing**: Script Python para convertir CSV → JSON estructurado
- **Caching**: Blob Storage con estructura `air-quality/{date}/{hour}.json`
- **Interpolación**: Para puntos intermedios, usar inverse distance weighting (IDW) con 3 estaciones más cercanas
- **Threshold alerts**: NO₂ >200 µg/m³ = alerta roja

---

#### 3. Calidad del Aire - Histórico (Opcional para ML)

**Fuente**: Comunidad de Madrid  
**Endpoint**: `https://datos.comunidad.madrid/catalogo/dataset/calidad_aire_datos_horarios`  
**Formato**: CSV mensual  
**Cobertura**: 2005 - presente  
**Uso**: Para análisis de tendencias y predicciones futuras (extensión post-hackathon)

---

#### 4. Azure Maps - Rutas Ciclables

**Fuente**: Azure Maps Directions API  
**Endpoint**: `https://atlas.microsoft.com/route/directions/json?api-version=1.0`  
**Autenticación**: Subscription key (en Key Vault)

**Parámetros importantes**:
```
query: {lat_origen},{lon_origen}:{lat_destino},{lon_destino}
travelMode: bicycle
routeType: shortest | eco | fastest
avoid: motorways,tollRoads,ferries
```

**Response relevante**:
```json
{
  "routes": [
    {
      "summary": {
        "lengthInMeters": 2847,
        "travelTimeInSeconds": 684,
        "trafficDelayInSeconds": 0
      },
      "legs": [
        {
          "points": [
            {"latitude": 40.416, "longitude": -3.703},
            {"latitude": 40.417, "longitude": -3.704},
            ...
          ]
        }
      ]
    }
  ]
}
```

**Estrategia**:
- Solicitar 3 rutas: `shortest`, `eco`, `fastest`
- Cachear resultados por par origen-destino (TTL 6h)
- Superponer con datos de calidad aire para scoring

---

### Arquitectura de Datos

```
┌─────────────────────────────────────────────────────────────┐
│                    INGESTION LAYER                           │
├─────────────────────────────────────────────────────────────┤
│  Azure Function: DataIngestionTimer                          │
│  Trigger: Timer (cada 20 min)                                │
│                                                               │
│  1. Fetch BiciMAD JSON → Parse → Cache Blob                 │
│  2. Fetch AirQuality CSV → Transform → Cache Blob           │
│  3. Log metrics (duration, errors) → App Insights           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER                             │
├─────────────────────────────────────────────────────────────┤
│  Azure Blob Storage: bicimad-data                            │
│                                                               │
│  /cache/                                                      │
│    ├── bicimad-stations.json (current)                       │
│    ├── air-quality-current.json (current hour)              │
│    └── air-quality-history/                                  │
│        ├── 2025-11-28-00.json                                │
│        ├── 2025-11-28-01.json                                │
│        └── ...                                                │
│                                                               │
│  Azure Table Storage: logs                                   │
│    ├── RouteCalculations (PartitionKey: date)               │
│    └── APIMetrics (PartitionKey: endpoint)                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  PROCESSING LAYER                            │
├─────────────────────────────────────────────────────────────┤
│  Azure Functions: API Endpoints                              │
│                                                               │
│  /api/stations         → Read from cache → Return GeoJSON   │
│  /api/air-quality      → Interpolate from nearest stations  │
│  /api/calculate-route  → Combine Maps + Air + Stations      │
└─────────────────────────────────────────────────────────────┘
```

---

### Data Quality & Monitoring

#### Validaciones en Ingestion

```python
# Ejemplo de validación en DataIngestionTimer
def validate_bicimad_data(data):
    required_fields = ['id', 'name', 'location', 'dock_bikes']
    
    for station in data['@graph']:
        # Check required fields
        if not all(field in station for field in required_fields):
            raise ValueError(f"Missing fields in station {station.get('id')}")
        
        # Check coordinates are in Madrid bounds
        lat = station['location']['latitude']
        lon = station['location']['longitude']
        if not (40.3 < lat < 40.6 and -3.9 < lon < -3.5):
            raise ValueError(f"Invalid coordinates for station {station['id']}")
        
        # Check logical values
        if station['dock_bikes'] < 0 or station['free_bases'] < 0:
            raise ValueError(f"Negative values in station {station['id']}")
    
    return True
```

#### Métricas de Calidad

| Métrica | Threshold | Acción si falla |
|---------|-----------|-----------------|
| Data freshness | < 30 min | Alert + serve stale data |
| Missing stations | < 5% | Interpolate from neighbors |
| Invalid coordinates | 0% | Skip station + log error |
| API response time | < 5s | Retry with backoff |
| Data completeness | > 95% | Continue with degraded service |

---

### Optimizaciones de Performance

#### 1. Cache Warming
Script que ejecuta cada 20 min ANTES de que expiren los datos:
```bash
# Triggered 2 min before data expiration
# Pre-fetch y pre-process data para evitar cold cache
```

#### 2. Partial Updates
Solo actualizar estaciones que cambiaron:
```python
# Compare current vs. previous, update diff only
# Reduce storage writes y network
```

#### 3. Compression
Comprimir JSON en Blob Storage:
```python
# gzip compression reduce 70% storage costs
# Decompress on-the-fly en Functions (overhead mínimo)
```

#### 4. Geospatial Indexing
Pre-calcular nearest stations para cada coordenada en grid 100x100m:
```python
# Index structure: {(lat, lon): [station_ids]}
# Lookup O(1) vs O(n) distance calculation
```

---

## 🧮 Algoritmo de Routing y Scoring

### Visión General

El algoritmo combina **3 factores** para generar un score de "low-emission" para cada ruta:

1. **Distancia** (20% peso): Rutas más cortas = menos tiempo expuesto
2. **Calidad del aire** (60% peso): Evitar zonas con altos niveles de NO₂/PM10
3. **Disponibilidad BiciMAD** (20% peso): Garantizar bicis en origen y anclajes en destino

---

### Flujo del Algoritmo

```
┌──────────────────────────────────────────────────────────────┐
│ INPUT: {origin, destination, user_preferences}               │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Get 3 route variants from Azure Maps                 │
│  • Route A: shortest distance                                │
│  • Route B: eco-friendly (prefer bike lanes)                 │
│  • Route C: fastest time                                     │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Segment each route into 100m chunks                  │
│  For each chunk:                                              │
│    • Get coordinates (lat, lon)                              │
│    • Query air quality at that point                         │
│    • Calculate exposure = distance × pollution_level         │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Calculate scores for each route                      │
│  • Distance score: normalize by shortest route               │
│  • Air quality score: weighted average NO₂ + PM10           │
│  • Availability score: check origin + destination stations   │
│  • TOTAL SCORE = weighted sum of above                       │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Rank routes and add metadata                         │
│  • Sort by total score (lower = better)                      │
│  • Add labels: "Verde", "Balanceada", "Rápida"              │
│  • Calculate estimated health impact                         │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ OUTPUT: Ranked routes with scores and visualizations         │
└──────────────────────────────────────────────────────────────┘
```

---

### Fórmulas de Scoring

#### 1. Score de Distancia (0-100, lower is better)

```python
def calculate_distance_score(route_distance_km, shortest_route_km):
    """
    Normaliza distancia contra la ruta más corta.
    Penaliza rutas que son >50% más largas.
    """
    ratio = route_distance_km / shortest_route_km
    
    if ratio <= 1.0:
        return 0  # La ruta más corta
    elif ratio <= 1.5:
        return (ratio - 1.0) * 100  # Linear penalty hasta 50%
    else:
        return 50 + (ratio - 1.5) * 200  # Heavy penalty >50%
    
# Ejemplo:
# Ruta más corta: 2.0 km → score = 0
# Ruta 10% más larga: 2.2 km → score = 10
# Ruta 50% más larga: 3.0 km → score = 50
# Ruta 100% más larga: 4.0 km → score = 150
```

#### 2. Score de Calidad del Aire (0-100, lower is better)

```python
def calculate_air_quality_score(route_segments):
    """
    Calcula exposición acumulada a contaminantes.
    Peso: 70% NO₂, 30% PM10 (NO₂ más irritante inmediato)
    """
    total_exposure = 0
    total_distance = 0
    
    # Thresholds de la OMS (WHO)
    NO2_THRESHOLD = 40  # µg/m³ annual mean
    PM10_THRESHOLD = 45  # µg/m³ annual mean
    
    for segment in route_segments:
        distance_m = segment['distance']
        no2_level = segment['no2']  # µg/m³
        pm10_level = segment['pm10']  # µg/m³
        
        # Normalize pollutants to 0-1 scale
        no2_normalized = min(no2_level / NO2_THRESHOLD, 2.0)  # Cap at 2x threshold
        pm10_normalized = min(pm10_level / PM10_THRESHOLD, 2.0)
        
        # Weighted pollutant index
        pollutant_index = (0.7 * no2_normalized) + (0.3 * pm10_normalized)
        
        # Exposure = distance × pollution (longer in polluted area = worse)
        exposure = distance_m * pollutant_index
        
        total_exposure += exposure
        total_distance += distance_m
    
    # Average exposure per meter, scaled to 0-100
    avg_exposure = total_exposure / total_distance
    score = avg_exposure * 50  # Scale factor
    
    return min(score, 100)  # Cap at 100

# Ejemplo interpretación:
# Score 0-20: Excelente (aire limpio)
# Score 20-40: Buena (cerca de límites OMS)
# Score 40-60: Moderada (supera límites OMS)
# Score 60-80: Mala (alto riesgo)
# Score 80-100: Muy mala (evitar)
```

#### 3. Score de Disponibilidad BiciMAD (0-100, lower is better)

```python
def calculate_availability_score(origin_station, destination_station):
    """
    Penaliza rutas si no hay bicis en origen o anclajes en destino.
    """
    origin_bikes = origin_station['dock_bikes']
    destination_free = destination_station['free_bases']
    
    # Minimum thresholds
    MIN_BIKES = 2  # Want at least 2 bikes available
    MIN_DOCKS = 2  # Want at least 2 free docks
    
    # Score origin (0-50)
    if origin_bikes == 0:
        origin_score = 50  # No bikes = bad
    elif origin_bikes < MIN_BIKES:
        origin_score = 25  # Low availability = warning
    else:
        origin_score = 0  # Good availability
    
    # Score destination (0-50)
    if destination_free == 0:
        destination_score = 50  # No docks = bad
    elif destination_free < MIN_DOCKS:
        destination_score = 25  # Low availability = warning
    else:
        destination_score = 0  # Good availability
    
    return origin_score + destination_score

# Ejemplo:
# Origin: 5 bicis, Destination: 8 anclajes → score = 0 (perfecto)
# Origin: 1 bici, Destination: 10 anclajes → score = 25 (warning)
# Origin: 0 bicis, Destination: 5 anclajes → score = 50 (no viable)
```

#### 4. Score Total (0-100, lower is better)

```python
def calculate_total_score(distance_score, air_quality_score, availability_score):
    """
    Combina los 3 scores con pesos ajustados.
    Prioridad: Calidad aire > Disponibilidad > Distancia
    """
    WEIGHT_DISTANCE = 0.20
    WEIGHT_AIR_QUALITY = 0.60
    WEIGHT_AVAILABILITY = 0.20
    
    total = (
        (distance_score * WEIGHT_DISTANCE) +
        (air_quality_score * WEIGHT_AIR_QUALITY) +
        (availability_score * WEIGHT_AVAILABILITY)
    )
    
    return round(total, 1)

# Ejemplo de ruta "Verde":
# Distance: 10 (solo 10% más larga)
# Air Quality: 15 (aire excelente)
# Availability: 0 (bicis y anclajes OK)
# TOTAL = (10×0.2) + (15×0.6) + (0×0.2) = 11.0 → Excelente

# Ejemplo de ruta "Rápida":
# Distance: 0 (la más corta)
# Air Quality: 65 (mala calidad aire)
# Availability: 0
# TOTAL = (0×0.2) + (65×0.6) + (0×0.2) = 39.0 → Moderada
```

---

### Interpolación Espacial de Calidad del Aire

Dado que solo hay 28 estaciones de medición en Madrid, necesitamos **interpolar** valores para puntos intermedios en la ruta.

#### Inverse Distance Weighting (IDW)

```python
import math

def get_air_quality_at_point(lat, lon, air_quality_stations):
    """
    Interpola calidad del aire en un punto usando IDW.
    Usa las 3 estaciones más cercanas.
    """
    # Step 1: Calculate distances to all stations
    distances = []
    for station in air_quality_stations:
        dist = haversine_distance(lat, lon, station['lat'], station['lon'])
        distances.append({
            'station': station,
            'distance': dist
        })
    
    # Step 2: Sort by distance, take top 3
    distances.sort(key=lambda x: x['distance'])
    nearest_3 = distances[:3]
    
    # Step 3: IDW formula
    # weight = 1 / distance^2 (inverse square)
    total_weight = 0
    weighted_no2 = 0
    weighted_pm10 = 0
    
    for item in nearest_3:
        station = item['station']
        dist = item['distance']
        
        # Avoid division by zero (if exactly on station)
        if dist < 0.001:  # Within 1 meter
            return {
                'no2': station['no2'],
                'pm10': station['pm10']
            }
        
        weight = 1.0 / (dist ** 2)
        total_weight += weight
        
        weighted_no2 += station['no2'] * weight
        weighted_pm10 += station['pm10'] * weight
    
    # Step 4: Normalize
    interpolated_no2 = weighted_no2 / total_weight
    interpolated_pm10 = weighted_pm10 / total_weight
    
    return {
        'no2': round(interpolated_no2, 2),
        'pm10': round(interpolated_pm10, 2)
    }

def haversine_distance(lat1, lon1, lat2, lon2):
    """
    Calcula distancia en km entre dos coordenadas.
    """
    R = 6371  # Radio de la Tierra en km
    
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    
    a = (math.sin(dlat/2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon/2) ** 2)
    
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c
```

---

### Segmentación de Rutas

Para evaluar calidad del aire a lo largo de la ruta, dividimos en segmentos:

```python
def segment_route(route_polyline, segment_length_m=100):
    """
    Divide una ruta en segmentos de longitud fija.
    
    Args:
        route_polyline: Lista de [lat, lon] puntos
        segment_length_m: Longitud de cada segmento en metros
    
    Returns:
        Lista de segmentos con {start, end, midpoint, distance}
    """
    segments = []
    current_distance = 0
    
    for i in range(len(route_polyline) - 1):
        p1 = route_polyline[i]
        p2 = route_polyline[i + 1]
        
        segment_dist = haversine_distance(p1[0], p1[1], p2[0], p2[1]) * 1000  # Convert to meters
        
        # If segment is longer than target, subdivide
        if segment_dist > segment_length_m:
            num_subsegments = int(segment_dist / segment_length_m)
            for j in range(num_subsegments):
                ratio = j / num_subsegments
                lat_mid = p1[0] + (p2[0] - p1[0]) * ratio
                lon_mid = p1[1] + (p2[1] - p1[1]) * ratio
                
                segments.append({
                    'midpoint': {'lat': lat_mid, 'lon': lon_mid},
                    'distance': segment_length_m
                })
        else:
            # Segment is shorter than target, use as-is
            lat_mid = (p1[0] + p2[0]) / 2
            lon_mid = (p1[1] + p2[1]) / 2
            
            segments.append({
                'midpoint': {'lat': lat_mid, 'lon': lon_mid},
                'distance': segment_dist
            })
    
    return segments
```

---

### Clasificación de Rutas

Después del scoring, asignamos etiquetas:

```python
def classify_route(total_score):
    """
    Clasifica ruta según score total.
    """
    if total_score <= 20:
        return {
            'label': '🟢 Ruta Verde',
            'badge_color': '#10b981',
            'description': 'Óptima para salud respiratoria'
        }
    elif total_score <= 40:
        return {
            'label': '🟡 Ruta Balanceada',
            'badge_color': '#f59e0b',
            'description': 'Buen balance tiempo/calidad aire'
        }
    else:
        return {
            'label': '🔴 Ruta Rápida',
            'badge_color': '#ef4444',
            'description': 'Más corta pero mayor exposición'
        }
```

---

### Estimación de Impacto en Salud

Convertir score a métricas entendibles:

```python
def estimate_health_impact(air_quality_score, distance_km, time_minutes):
    """
    Estima impacto en salud comparado con límites OMS.
    """
    # WHO daily exposure limit: 40 µg/m³ NO₂
    # Assume user breathes 15 L/min while cycling
    
    breathing_rate_L_per_min = 15
    total_air_inhaled_m3 = (breathing_rate_L_per_min * time_minutes) / 1000
    
    # Approximate pollution exposure (µg inhaled)
    # This is simplified; real calculation needs concentration
    avg_pollution_ug_m3 = air_quality_score * 0.8  # Rough conversion
    
    total_pollution_inhaled_ug = avg_pollution_ug_m3 * total_air_inhaled_m3
    
    # Compare to daily exposure budget
    daily_budget_ug = 40 * 20  # 40 µg/m³ × 20 m³ daily breathing
    percentage_of_daily = (total_pollution_inhaled_ug / daily_budget_ug) * 100
    
    return {
        'pollution_inhaled_ug': round(total_pollution_inhaled_ug, 2),
        'percentage_of_daily_limit': round(percentage_of_daily, 1),
        'health_rating': 'Bajo' if percentage_of_daily < 5 else 'Moderado' if percentage_of_daily < 15 else 'Alto'
    }
```

---

### Ejemplo Completo de Cálculo

#### Escenario: Malasaña → Retiro

**Datos de entrada**:
- Origen: Estación BiciMAD "Fuencarral 10" (40.4245, -3.7018)
- Destino: Estación BiciMAD "Retiro" (40.4133, -3.6836)

**Azure Maps devuelve 3 rutas**:

| Ruta | Distancia | Tiempo | Vía principal |
|------|-----------|--------|---------------|
| A (shortest) | 2.1 km | 10 min | Calle Alcalá |
| B (eco) | 2.8 km | 14 min | Parque del Oeste |
| C (fastest) | 2.0 km | 9 min | Gran Vía |

**Datos de calidad del aire (interpolados)**:

| Zona | NO₂ (µg/m³) | PM10 (µg/m³) |
|------|-------------|--------------|
| Calle Alcalá | 55 | 38 |
| Parque del Oeste | 22 | 18 |
| Gran Vía | 78 | 52 |

**Cálculo de scores**:

**Ruta A (shortest - Alcalá)**:
- Distance score: 5 (solo 5% más larga que C)
- Air quality score: 42 (NO₂ moderado)
- Availability score: 0 (bicis OK)
- **TOTAL: (5×0.2) + (42×0.6) + (0×0.2) = 26.2** → 🟡 Balanceada

**Ruta B (eco - Parque)**:
- Distance score: 40 (40% más larga)
- Air quality score: 18 (aire excelente)
- Availability score: 0
- **TOTAL: (40×0.2) + (18×0.6) + (0×0.2) = 18.8** → 🟢 Verde

**Ruta C (fastest - Gran Vía)**:
- Distance score: 0 (la más corta)
- Air quality score: 68 (mala calidad)
- Availability score: 0
- **TOTAL: (0×0.2) + (68×0.6) + (0×0.2) = 40.8** → 🔴 Rápida

**Recomendación**: Ruta B (Parque del Oeste) es la mejor opción.

---

## 🏗️ Tareas de Infraestructura Bicep (IaC)

### Roadmap de Módulos Bicep

Crear la siguiente estructura de módulos reutilizables:

```
bicep/
├── main.bicep                          # Orquestador principal
├── bicep-router/
│   ├── parameters/
│   │   ├── dev.bicepparam             # Parámetros desarrollo
│   │   └── prod.bicepparam            # Parámetros producción
│   │
│   └── modules/
│       ├── resource-group.bicep        # RG para todos los recursos
│       ├── storage-account.bicep       # Blob + Table storage
│       ├── function-app.bicep          # Azure Functions + App Service Plan
│       ├── static-web-app.bicep        # Frontend hosting
│       ├── key-vault.bicep             # Secrets management
│       ├── app-insights.bicep          # Monitoring + Log Analytics
│       ├── azure-maps.bicep            # Maps account
│       ├── budget.bicep                # Cost alerts
│       └── rbac.bicep                  # Role assignments
```

---

### Tarea 1: Resource Group Module

**Archivo**: `bicep/bicep-router/modules/resource-group.bicep`

**Tareas**:
- [ ] Crear módulo para Resource Group con naming convention
- [ ] Parámetros: `environment`, `location`, `projectName`
- [ ] Tags obligatorios: `Environment`, `Project`, `Owner`, `CostCenter`, `ManagedBy`
- [ ] Output: `resourceGroupName`, `resourceGroupId`

**Naming convention**:
```
rg-{projectName}-{environment}-{location}
Ejemplo: rg-bicimad-router-dev-weu
```

---

### Tarea 2: Storage Account Module

**Archivo**: `bicep/bicep-router/modules/storage-account.bicep`

**Tareas**:
- [ ] SKU: Standard_LRS
- [ ] Habilitar Blob Storage + Table Storage
- [ ] Network rules: Allow Azure services + specific IPs (Functions)
- [ ] Containers: `cache`, `air-quality-history`
- [ ] Tables: `RouteCalculations`, `APIMetrics`
- [ ] Lifecycle policy: Delete blobs older than 7 days
- [ ] Diagnostic settings → Log Analytics
- [ ] Output: `storageAccountName`, `blobEndpoint`, `connectionString` (to Key Vault)

**Naming convention**:
```
st{projectName}{environment}{uniqueString}
Ejemplo: stbicimaddev4k7j2
```

---

### Tarea 3: Function App Module

**Archivo**: `bicep/bicep-router/modules/function-app.bicep`

**Tareas**:
- [ ] App Service Plan: Consumption (serverless)
- [ ] Runtime: Python 3.11
- [ ] OS: Linux
- [ ] Managed Identity: SystemAssigned
- [ ] App Settings:
  - `STORAGE_CONNECTION_STRING` → from Key Vault
  - `AZURE_MAPS_KEY` → from Key Vault
  - `APPINSIGHTS_INSTRUMENTATIONKEY` → from App Insights
  - `FUNCTIONS_WORKER_RUNTIME=python`
- [ ] CORS: Enable for Static Web App domain
- [ ] Always On: false (consumption plan)
- [ ] Diagnostic settings → App Insights
- [ ] Output: `functionAppName`, `functionAppUrl`, `principalId`

**Naming convention**:
```
func-{projectName}-{environment}-{location}
Ejemplo: func-bicimad-router-dev-weu
```

---

### Tarea 4: Static Web App Module

**Archivo**: `bicep/bicep-router/modules/static-web-app.bicep`

**Tareas**:
- [ ] SKU: Free
- [ ] Linked repository: GitHub (via GitHub Actions, no en Bicep)
- [ ] Build preset: Custom (HTML/JS)
- [ ] API location: Proxy to Azure Functions
- [ ] Custom domain: opcional (post-hackathon)
- [ ] Staging environments: enabled
- [ ] Output: `staticWebAppName`, `defaultHostname`, `apiKey`

**Naming convention**:
```
stapp-{projectName}-{environment}
Ejemplo: stapp-bicimad-router-dev
```

---

### Tarea 5: Key Vault Module

**Archivo**: `bicep/bicep-router/modules/key-vault.bicep`

**Tareas**:
- [ ] SKU: Standard
- [ ] Access policies:
  - Function App Managed Identity: `Get`, `List` secrets
  - Deploying Service Principal: `All` permissions
- [ ] Network rules: Allow Azure services
- [ ] Soft delete: enabled (90 days retention)
- [ ] Purge protection: enabled (prod only)
- [ ] Secrets to create:
  - `azure-maps-api-key` (manual, from Azure Maps)
  - `storage-connection-string` (from Storage Account)
- [ ] Diagnostic settings → Log Analytics
- [ ] Output: `keyVaultName`, `keyVaultUri`

**Naming convention**:
```
kv-{projectName}-{env}-{uniqueString}
Ejemplo: kv-bicimad-dev-4k7j
```

---

### Tarea 6: Application Insights Module

**Archivo**: `bicep/bicep-router/modules/app-insights.bicep`

**Tareas**:
- [ ] Log Analytics Workspace (nuevo o existente)
- [ ] Application Insights linked a workspace
- [ ] Retention: 30 días (dev), 90 días (prod)
- [ ] Sampling: 100% (dev), 50% (prod)
- [ ] Alert rules:
  - Function execution failures > 5 en 5 min
  - Response time > 5s
  - Availability < 95%
- [ ] Action Group: Email a `owner@example.com`
- [ ] Output: `appInsightsName`, `instrumentationKey`, `workspaceId`

**Naming convention**:
```
appi-{projectName}-{environment}
log-{projectName}-{environment}
```

---

### Tarea 7: Azure Maps Module

**Archivo**: `bicep/bicep-router/modules/azure-maps.bicep`

**Tareas**:
- [ ] SKU: Gen2 (S1)
- [ ] Pricing tier: Standard (1000 free txn/month)
- [ ] Store primary key en Key Vault
- [ ] Output: `mapsAccountName`, `primaryKey` (sensitive)

**Naming convention**:
```
maps-{projectName}-{environment}
Ejemplo: maps-bicimad-router-dev
```

---

### Tarea 8: Budget Alert Module

**Archivo**: `bicep/bicep-router/modules/budget.bicep`

**Tareas**:
- [ ] Budget scope: Resource Group
- [ ] Amount: $30 USD (dev), $50 USD (prod)
- [ ] Time grain: Monthly
- [ ] Alerts:
  - 50% threshold → Warning email
  - 80% threshold → Alert email
  - 100% threshold → Critical alert + disable resources (opcional)
- [ ] Notification emails: owner list
- [ ] Output: `budgetName`

---

### Tarea 9: RBAC Assignments Module

**Archivo**: `bicep/bicep-router/modules/rbac.bicep`

**Tareas**:
- [ ] Function App → Storage Account: `Storage Blob Data Contributor`
- [ ] Function App → Storage Account: `Storage Table Data Contributor`
- [ ] Function App → Key Vault: `Key Vault Secrets User` (built-in role)
- [ ] Deploying SP → All resources: `Contributor`
- [ ] Output: Lista de role assignments creados

---

### Tarea 10: Main Orchestrator

**Archivo**: `bicep/bicep-router/main.bicep`

**Tareas**:
- [ ] Parámetros globales: `environment`, `location`, `projectName`, `ownerEmail`
- [ ] Orquestar módulos en orden correcto:
  1. Resource Group
  2. Log Analytics + App Insights
  3. Storage Account
  4. Key Vault
  5. Azure Maps
  6. Function App
  7. Static Web App
  8. RBAC assignments
  9. Budget alert
- [ ] Outputs consolidados para GitHub Actions
- [ ] Comentarios inline explicando cada módulo

**Ejemplo de orquestación**:
```bicep
// Orden de despliegue
module rg './modules/resource-group.bicep' = { ... }

module monitoring './modules/app-insights.bicep' = {
  dependsOn: [rg]
  ...
}

module storage './modules/storage-account.bicep' = {
  dependsOn: [rg, monitoring]
  ...
}

// etc.
```

---

### Tarea 11: Parámetros por Entorno

**Archivos**:
- `bicep/bicep-router/parameters/dev.bicepparam`
- `bicep/bicep-router/parameters/prod.bicepparam`

**Tareas**:
- [ ] Dev parameters:
  - environment: 'dev'
  - location: 'westeurope'
  - ownerEmail: 'dev-team@example.com'
  - enableAutoShutdown: true
  - appInsightsRetention: 30
- [ ] Prod parameters:
  - environment: 'prod'
  - location: 'westeurope'
  - ownerEmail: 'ops-team@example.com'
  - enableAutoShutdown: false
  - appInsightsRetention: 90
  - enableBackup: true

---

### Tarea 12: Validación y Testing

**Script**: `scripts/bicep-router/validate-bicep.sh`

**Tareas**:
- [ ] Script que ejecuta:
  ```bash
  az bicep build --file bicep/bicep-router/main.bicep
  az deployment sub what-if \
    --location westeurope \
    --template-file bicep/bicep-router/main.bicep \
    --parameters bicep/bicep-router/parameters/dev.bicepparam
  ```
- [ ] Checkov scan para security best practices
- [ ] Cost estimation (Azure Pricing Calculator API)

---

### Checklist Completo de Tareas Bicep

#### Módulos Básicos
- [ ] 1.1 - Crear `resource-group.bicep`
- [ ] 1.2 - Crear `storage-account.bicep`
- [ ] 1.3 - Crear `function-app.bicep`
- [ ] 1.4 - Crear `static-web-app.bicep`
- [ ] 1.5 - Crear `key-vault.bicep`
- [ ] 1.6 - Crear `app-insights.bicep`
- [ ] 1.7 - Crear `azure-maps.bicep`
- [ ] 1.8 - Crear `budget.bicep`
- [ ] 1.9 - Crear `rbac.bicep`

#### Orquestación
- [ ] 2.1 - Crear `main.bicep` orquestador
- [ ] 2.2 - Definir dependencias entre módulos
- [ ] 2.3 - Configurar outputs consolidados

#### Parámetros
- [ ] 3.1 - Crear `dev.bicepparam`
- [ ] 3.2 - Crear `prod.bicepparam`
- [ ] 3.3 - Documentar parámetros en README

#### Validación
- [ ] 4.1 - Script `validate-bicep.sh`
- [ ] 4.2 - Integrar Checkov para security scan
- [ ] 4.3 - Probar despliegue en suscripción de prueba

#### Documentación
- [ ] 5.1 - README.md con guía de uso
- [ ] 5.2 - Diagramas de arquitectura en código (comments)
- [ ] 5.3 - ADR (Architecture Decision Record) para decisiones clave

---

## ⚙️ Tareas de Backend (Azure Functions)

### Estructura del Proyecto Python

```
backend/
├── function-app/
│   ├── host.json                    # Azure Functions host config
│   ├── requirements.txt             # Python dependencies
│   ├── local.settings.json          # Local dev settings
│   │
│   ├── shared/                      # Código compartido
│   │   ├── __init__.py
│   │   ├── models.py                # Data models (Pydantic)
│   │   ├── azure_maps_client.py     # Azure Maps SDK wrapper
│   │   ├── data_fetcher.py          # API clients para datos abiertos
│   │   ├── cache_manager.py         # Blob Storage cache logic
│   │   ├── scoring.py               # Algoritmo de scoring
│   │   └── utils.py                 # Helpers (haversine, etc.)
│   │
│   ├── GetStations/                 # Function 1
│   │   ├── __init__.py
│   │   └── function.json
│   │
│   ├── GetAirQuality/               # Function 2
│   │   ├── __init__.py
│   │   └── function.json
│   │
│   ├── CalculateRoute/              # Function 3
│   │   ├── __init__.py
│   │   └── function.json
│   │
│   ├── HealthCheck/                 # Function 4
│   │   ├── __init__.py
│   │   └── function.json
│   │
│   └── DataIngestionTimer/          # Function 5 (background)
│       ├── __init__.py
│       └── function.json
│
└── tests/
    ├── test_scoring.py
    ├── test_data_fetcher.py
    └── test_integration.py
```

---

### Tarea 1: Setup del Proyecto

**Archivo**: `backend/function-app/requirements.txt`

**Tareas**:
- [ ] Definir dependencias:
  ```txt
  azure-functions==1.17.0
  azure-storage-blob==12.19.0
  azure-storage-table==12.4.3
  azure-identity==1.15.0
  azure-keyvault-secrets==4.7.0
  requests==2.31.0
  pydantic==2.5.0
  geopy==2.4.1
  numpy==1.26.2
  python-dotenv==1.0.0
  opencensus-ext-azure==1.1.13  # Application Insights
  ```

**Archivo**: `backend/function-app/host.json`

**Tareas**:
- [ ] Configurar extensionBundle, logging, retry policies
  ```json
  {
    "version": "2.0",
    "extensionBundle": {
      "id": "Microsoft.Azure.Functions.ExtensionBundle",
      "version": "[4.*, 5.0.0)"
    },
    "logging": {
      "applicationInsights": {
        "samplingSettings": {
          "isEnabled": true,
          "maxTelemetryItemsPerSecond": 5
        }
      }
    },
    "retry": {
      "strategy": "exponentialBackoff",
      "maxRetryCount": 3,
      "minimumInterval": "00:00:01",
      "maximumInterval": "00:00:10"
    },
    "functionTimeout": "00:05:00"
  }
  ```

---

### Tarea 2: Shared Module - Data Models

**Archivo**: `backend/function-app/shared/models.py`

**Tareas**:
- [ ] Definir modelos Pydantic para:
  - `Station` (BiciMAD estación)
  - `AirQualityMeasurement` (dato de contaminación)
  - `RouteRequest` (request de cálculo de ruta)
  - `RouteResponse` (respuesta con 3 rutas rankeadas)
  - `RouteSegment` (segmento de ruta con calidad aire)

**Ejemplo**:
```python
from pydantic import BaseModel, Field
from typing import List, Optional

class Location(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class Station(BaseModel):
    id: str
    name: str
    location: Location
    dock_bikes: int = Field(..., ge=0)
    free_bases: int = Field(..., ge=0)
    total_bases: int
    activate: bool

class AirQualityMeasurement(BaseModel):
    station_id: str
    no2: float = Field(..., ge=0)  # µg/m³
    pm10: float = Field(..., ge=0)
    pm25: Optional[float] = Field(None, ge=0)
    timestamp: str

class RouteRequest(BaseModel):
    origin: Location
    destination: Location
    preferences: Optional[dict] = None

class RouteScore(BaseModel):
    distance_score: float
    air_quality_score: float
    availability_score: float
    total_score: float
    classification: str  # "Verde", "Balanceada", "Rápida"

class Route(BaseModel):
    route_id: str
    distance_km: float
    duration_minutes: int
    polyline: List[Location]
    score: RouteScore
    segments: List['RouteSegment']

class RouteResponse(BaseModel):
    routes: List[Route]
    origin_station: Station
    destination_station: Station
    calculation_time_ms: int
```

---

### Tarea 3: Shared Module - Azure Maps Client

**Archivo**: `backend/function-app/shared/azure_maps_client.py`

**Tareas**:
- [ ] Wrapper para Azure Maps Directions API
- [ ] Método `get_routes(origin, destination, travel_mode='bicycle')`
- [ ] Retry logic con exponential backoff
- [ ] Error handling + logging

**Pseudocódigo**:
```python
class AzureMapsClient:
    def __init__(self, subscription_key: str):
        self.api_key = subscription_key
        self.base_url = "https://atlas.microsoft.com/route/directions/json"
    
    def get_routes(self, origin: Location, destination: Location) -> List[dict]:
        """
        Devuelve 3 rutas: shortest, eco, fastest
        """
        params = {
            'api-version': '1.0',
            'subscription-key': self.api_key,
            'query': f'{origin.latitude},{origin.longitude}:{destination.latitude},{destination.longitude}',
            'travelMode': 'bicycle',
            'routeType': 'shortest',  # Hacer 3 llamadas con 'eco', 'fastest'
            'avoid': 'motorways'
        }
        
        response = requests.get(self.base_url, params=params, timeout=10)
        response.raise_for_status()
        
        return response.json()['routes']
```

---

### Tarea 4: Shared Module - Data Fetcher

**Archivo**: `backend/function-app/shared/data_fetcher.py`

**Tareas**:
- [ ] Clase `BiciMADFetcher` con método `get_stations()`
- [ ] Clase `AirQualityFetcher` con método `get_current_measurements()`
- [ ] Parsing de CSV de calidad del aire
- [ ] Error handling si API falla (usar cache stale)

**Pseudocódigo**:
```python
class BiciMADFetcher:
    ENDPOINT = "https://datos.madrid.es/egob/catalogo/300261-0-bicimad-disponibilidad.json"
    
    def get_stations(self) -> List[Station]:
        response = requests.get(self.ENDPOINT, timeout=10)
        data = response.json()
        
        stations = []
        for item in data['@graph']:
            stations.append(Station(
                id=item['id'],
                name=item['name'],
                location=Location(
                    latitude=item['location']['latitude'],
                    longitude=item['location']['longitude']
                ),
                dock_bikes=item['dock_bikes'],
                free_bases=item['free_bases'],
                total_bases=item['total_bases'],
                activate=item['activate'] == 1
            ))
        
        return stations

class AirQualityFetcher:
    # Similar structure para fetch + parse CSV
    pass
```

---

### Tarea 5: Shared Module - Cache Manager

**Archivo**: `backend/function-app/shared/cache_manager.py`

**Tareas**:
- [ ] Clase `CacheManager` usando Azure Blob Storage
- [ ] Métodos:
  - `get_cached_data(key: str) -> Optional[dict]`
  - `set_cached_data(key: str, data: dict, ttl_seconds: int)`
  - `is_cache_valid(key: str, ttl_seconds: int) -> bool`
- [ ] Serialización JSON con timestamps

**Pseudocódigo**:
```python
from azure.storage.blob import BlobServiceClient
import json
from datetime import datetime, timedelta

class CacheManager:
    def __init__(self, connection_string: str):
        self.blob_service = BlobServiceClient.from_connection_string(connection_string)
        self.container = self.blob_service.get_container_client("cache")
    
    def get_cached_data(self, key: str) -> Optional[dict]:
        try:
            blob_client = self.container.get_blob_client(f"{key}.json")
            data = blob_client.download_blob().readall()
            return json.loads(data)
        except:
            return None
    
    def set_cached_data(self, key: str, data: dict, ttl_seconds: int):
        blob_client = self.container.get_blob_client(f"{key}.json")
        data['_cached_at'] = datetime.utcnow().isoformat()
        blob_client.upload_blob(json.dumps(data), overwrite=True)
    
    def is_cache_valid(self, key: str, ttl_seconds: int) -> bool:
        data = self.get_cached_data(key)
        if not data or '_cached_at' not in data:
            return False
        
        cached_time = datetime.fromisoformat(data['_cached_at'])
        return datetime.utcnow() - cached_time < timedelta(seconds=ttl_seconds)
```

---

### Tarea 6: Shared Module - Scoring Algorithm

**Archivo**: `backend/function-app/shared/scoring.py`

**Tareas**:
- [ ] Implementar funciones del algoritmo documentado anteriormente:
  - `calculate_distance_score()`
  - `calculate_air_quality_score()`
  - `calculate_availability_score()`
  - `calculate_total_score()`
  - `classify_route()`
  - `interpolate_air_quality()`
- [ ] Unit tests para cada función

---

### Tarea 7: Function 1 - GetStations

**Archivo**: `backend/function-app/GetStations/__init__.py`

**Tareas**:
- [ ] HTTP GET endpoint `/api/stations`
- [ ] Query params: `lat`, `lon`, `radius` (opcional para filtrar por distancia)
- [ ] Lógica:
  1. Check cache (TTL 20 min)
  2. Si cache inválido, fetch de API
  3. Filtrar por radius si se proporciona
  4. Return GeoJSON FeatureCollection
- [ ] Response example:
  ```json
  {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [-3.7037, 40.4168]
        },
        "properties": {
          "id": "1",
          "name": "Puerta del Sol A",
          "dock_bikes": 12,
          "free_bases": 5,
          "total_bases": 30
        }
      }
    ]
  }
  ```

---

### Tarea 8: Function 2 - GetAirQuality

**Archivo**: `backend/function-app/GetAirQuality/__init__.py`

**Tareas**:
- [ ] HTTP GET endpoint `/api/air-quality`
- [ ] Query params: `lat`, `lon`
- [ ] Lógica:
  1. Check cache de datos de calidad aire (TTL 20 min)
  2. Interpolar usando IDW con 3 estaciones más cercanas
  3. Return niveles de NO₂, PM10, PM2.5
- [ ] Response example:
  ```json
  {
    "location": {
      "latitude": 40.4168,
      "longitude": -3.7037
    },
    "measurements": {
      "no2": 45.3,
      "pm10": 32.1,
      "pm25": 18.5
    },
    "timestamp": "2025-11-28T10:00:00Z",
    "nearest_stations": [
      {"id": "4", "name": "Pza. España", "distance_km": 0.8},
      {"id": "35", "name": "Pza. Carmen", "distance_km": 1.2}
    ],
    "health_level": "Moderate"
  }
  ```

---

### Tarea 9: Function 3 - CalculateRoute

**Archivo**: `backend/function-app/CalculateRoute/__init__.py`

**Tareas**:
- [ ] HTTP POST endpoint `/api/calculate-route`
- [ ] Request body: `RouteRequest` model
- [ ] Lógica (el corazón del proyecto):
  1. Validar coordenadas están en Madrid
  2. Encontrar estación BiciMAD más cercana al origen
  3. Encontrar estación BiciMAD más cercana al destino
  4. Llamar Azure Maps para 3 rutas (shortest, eco, fastest)
  5. Para cada ruta:
     - Segmentar en chunks de 100m
     - Interpolar calidad aire en cada segmento
     - Calcular scores
  6. Rankear rutas por score total
  7. Return `RouteResponse`
- [ ] Timeout: 30 segundos
- [ ] Logging de métricas (latencia de cada paso)

---

### Tarea 10: Function 4 - HealthCheck

**Archivo**: `backend/function-app/HealthCheck/__init__.py`

**Tareas**:
- [ ] HTTP GET endpoint `/api/health`
- [ ] Checks:
  - Storage Account accesible
  - Key Vault accesible
  - Azure Maps API responde
  - Cache no está vacío (tiene datos frescos)
- [ ] Response:
  ```json
  {
    "status": "healthy",
    "checks": {
      "storage": "ok",
      "keyvault": "ok",
      "azure_maps": "ok",
      "cache_freshness": "ok"
    },
    "timestamp": "2025-11-28T10:00:00Z"
  }
  ```

---

### Tarea 11: Function 5 - DataIngestionTimer

**Archivo**: `backend/function-app/DataIngestionTimer/__init__.py`

**Tareas**:
- [ ] Timer trigger: cada 20 minutos
- [ ] Lógica:
  1. Fetch BiciMAD stations → cache en Blob
  2. Fetch calidad aire → cache en Blob
  3. Log métricas en Application Insights:
     - Duration de cada fetch
     - Número de estaciones
     - Errores si los hay
- [ ] Error handling: Si falla, alertar pero no crashear

**function.json**:
```json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "name": "mytimer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 */20 * * * *"
    }
  ]
}
```

---

### Tarea 12: Testing

**Archivo**: `backend/tests/test_scoring.py`

**Tareas**:
- [ ] Unit tests para funciones de scoring:
  - Test distance score con diferentes ratios
  - Test air quality score con valores conocidos
  - Test interpolación IDW
  - Test clasificación de rutas

**Archivo**: `backend/tests/test_integration.py`

**Tareas**:
- [ ] Integration tests:
  - Mock de Azure Maps API
  - Mock de APIs de datos abiertos
  - Test end-to-end de `/api/calculate-route`

---

### Checklist Completo de Tareas Backend

#### Setup
- [ ] 1.1 - Crear estructura de directorios
- [ ] 1.2 - Configurar `requirements.txt`
- [ ] 1.3 - Configurar `host.json`
- [ ] 1.4 - Configurar `local.settings.json` para desarrollo local

#### Shared Modules
- [ ] 2.1 - Implementar `models.py` (Pydantic models)
- [ ] 2.2 - Implementar `azure_maps_client.py`
- [ ] 2.3 - Implementar `data_fetcher.py` (BiciMAD + Air Quality)
- [ ] 2.4 - Implementar `cache_manager.py`
- [ ] 2.5 - Implementar `scoring.py` (algoritmo completo)
- [ ] 2.6 - Implementar `utils.py` (haversine, etc.)

#### Functions
- [ ] 3.1 - Implementar `GetStations` function
- [ ] 3.2 - Implementar `GetAirQuality` function
- [ ] 3.3 - Implementar `CalculateRoute` function
- [ ] 3.4 - Implementar `HealthCheck` function
- [ ] 3.5 - Implementar `DataIngestionTimer` function

#### Testing
- [ ] 4.1 - Unit tests para scoring
- [ ] 4.2 - Unit tests para data fetchers
- [ ] 4.3 - Integration tests para functions
- [ ] 4.4 - Mock de APIs externas

#### Documentation
- [ ] 5.1 - Docstrings en todas las funciones
- [ ] 5.2 - README.md con setup instructions
- [ ] 5.3 - Postman collection para testing manual

---

## 🎨 Tareas de Frontend (HTML + JavaScript)

### Estructura del Proyecto Frontend

```
frontend/
├── index.html                      # Página principal
├── css/
│   ├── styles.css                 # Estilos principales
│   ├── map.css                    # Estilos específicos del mapa
│   └── responsive.css             # Media queries
├── js/
│   ├── app.js                     # Inicialización y orquestación
│   ├── map-controller.js          # Lógica del mapa Leaflet
│   ├── api-client.js              # Llamadas a backend
│   ├── route-calculator.js        # UI para cálculo de rutas
│   ├── station-selector.js        # Selector de estaciones
│   └── utils.js                   # Helpers
├── assets/
│   ├── icons/                     # Iconos custom para marcadores
│   │   ├── bike-marker.svg
│   │   ├── origin-marker.svg
│   │   └── destination-marker.svg
│   └── images/
│       └── logo.png
└── staticwebapp.config.json       # Azure Static Web Apps config
```

---

### Tarea 1: HTML Structure

**Archivo**: `frontend/index.html`

**Tareas**:
- [ ] Estructura HTML5 semántica
- [ ] Meta tags para SEO y responsiveness
- [ ] Secciones principales:
  - Header con título y logo
  - Sidebar con formulario de búsqueda
  - Mapa principal (80% de viewport)
  - Panel de resultados (overlay sobre mapa)
- [ ] Links a Leaflet.js CDN
- [ ] Scripts locales al final del body

**Estructura básica**:
```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BiciMAD Low-Emission Router | DataSaturday Madrid 2025</title>
    
    <!-- Leaflet CSS -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    
    <!-- Custom CSS -->
    <link rel="stylesheet" href="css/styles.css">
    <link rel="stylesheet" href="css/map.css">
    <link rel="stylesheet" href="css/responsive.css">
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="logo">
            <img src="assets/images/logo.png" alt="BiciMAD Router">
            <h1>Low-Emission BiciMAD Router</h1>
        </div>
        <div class="subtitle">Rutas inteligentes para ciclistas urbanos</div>
    </header>

    <!-- Main Container -->
    <div class="container">
        <!-- Sidebar -->
        <aside class="sidebar">
            <div class="search-panel">
                <h2>Calcular Ruta</h2>
                
                <div class="form-group">
                    <label for="origin">Origen</label>
                    <input type="text" id="origin" placeholder="Dirección o estación BiciMAD">
                    <button id="use-location-btn">📍 Usar mi ubicación</button>
                </div>
                
                <div class="form-group">
                    <label for="destination">Destino</label>
                    <input type="text" id="destination" placeholder="Dirección o estación BiciMAD">
                </div>
                
                <button id="calculate-route-btn" class="btn-primary">Calcular Rutas</button>
                
                <div id="loading-spinner" class="hidden">
                    <div class="spinner"></div>
                    <p>Calculando rutas...</p>
                </div>
            </div>
            
            <!-- Results Panel -->
            <div id="results-panel" class="hidden">
                <h3>Rutas Disponibles</h3>
                <div id="routes-list"></div>
            </div>
            
            <!-- Info Panel -->
            <div class="info-panel">
                <h4>¿Cómo funciona?</h4>
                <ul>
                    <li>🚴 Rutas optimizadas para BiciMAD</li>
                    <li>🌫️ Evita zonas con alta contaminación</li>
                    <li>📊 Score de calidad del aire en tiempo real</li>
                </ul>
            </div>
        </aside>

        <!-- Map Container -->
        <main class="map-container">
            <div id="map"></div>
            
            <!-- Map Overlays -->
            <div id="air-quality-legend" class="map-overlay legend">
                <h4>Calidad del Aire</h4>
                <div class="legend-item">
                    <span class="color-box" style="background: #10b981;"></span>
                    <span>Buena (0-40 µg/m³)</span>
                </div>
                <div class="legend-item">
                    <span class="color-box" style="background: #f59e0b;"></span>
                    <span>Moderada (40-80 µg/m³)</span>
                </div>
                <div class="legend-item">
                    <span class="color-box" style="background: #ef4444;"></span>
                    <span>Mala (>80 µg/m³)</span>
                </div>
            </div>
        </main>
    </div>

    <!-- Leaflet JS -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    
    <!-- Custom JS -->
    <script src="js/utils.js"></script>
    <script src="js/api-client.js"></script>
    <script src="js/map-controller.js"></script>
    <script src="js/station-selector.js"></script>
    <script src="js/route-calculator.js"></script>
    <script src="js/app.js"></script>
</body>
</html>
```

---

### Tarea 2: CSS Styling

**Archivo**: `frontend/css/styles.css`

**Tareas**:
- [ ] Variables CSS para colores, fuentes, espaciado
- [ ] Reset básico (normalize.css o custom)
- [ ] Estilos de header, sidebar, botones
- [ ] Animaciones (spinner, transiciones)
- [ ] Dark mode opcional

**Snippet de colores**:
```css
:root {
    --color-primary: #10b981;      /* Verde */
    --color-warning: #f59e0b;      /* Amarillo */
    --color-danger: #ef4444;       /* Rojo */
    --color-bg: #0f172a;           /* Dark blue */
    --color-surface: #1e293b;      /* Card background */
    --color-text: #f1f5f9;         /* Light text */
    --color-muted: #94a3b8;        /* Muted text */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
}

body {
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background-color: var(--color-bg);
    color: var(--color-text);
}

.container {
    display: flex;
    height: calc(100vh - 80px);
}

.sidebar {
    width: 400px;
    background: var(--color-surface);
    padding: var(--spacing-lg);
    overflow-y: auto;
}

.map-container {
    flex: 1;
    position: relative;
}

#map {
    width: 100%;
    height: 100%;
}

.btn-primary {
    background: var(--color-primary);
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 16px;
    width: 100%;
    transition: background 0.3s;
}

.btn-primary:hover {
    background: #059669;
}
```

**Archivo**: `frontend/css/responsive.css`

**Tareas**:
- [ ] Media queries para mobile (<768px)
- [ ] Sidebar pasa a overlay/drawer en mobile
- [ ] Botón hamburguesa para toggle
- [ ] Mapa ocupa toda la pantalla en mobile

---

### Tarea 3: JavaScript - API Client

**Archivo**: `frontend/js/api-client.js`

**Tareas**:
- [ ] Clase `APIClient` con métodos para cada endpoint
- [ ] Configuración de base URL (dev vs prod)
- [ ] Error handling y retry logic
- [ ] Loading states

**Ejemplo**:
```javascript
class APIClient {
    constructor(baseURL) {
        this.baseURL = baseURL || '/api';  // Proxy via Static Web App
    }

    async getStations(lat, lon, radius) {
        const url = new URL(`${this.baseURL}/stations`);
        if (lat && lon) {
            url.searchParams.append('lat', lat);
            url.searchParams.append('lon', lon);
        }
        if (radius) {
            url.searchParams.append('radius', radius);
        }

        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return await response.json();
    }

    async getAirQuality(lat, lon) {
        const url = `${this.baseURL}/air-quality?lat=${lat}&lon=${lon}`;
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return await response.json();
    }

    async calculateRoute(origin, destination) {
        const response = await fetch(`${this.baseURL}/calculate-route`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                origin: { latitude: origin.lat, longitude: origin.lon },
                destination: { latitude: destination.lat, longitude: destination.lon }
            })
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return await response.json();
    }

    async healthCheck() {
        const response = await fetch(`${this.baseURL}/health`);
        return await response.json();
    }
}

// Export singleton
const apiClient = new APIClient();
```

---

### Tarea 4: JavaScript - Map Controller

**Archivo**: `frontend/js/map-controller.js`

**Tareas**:
- [ ] Inicialización del mapa Leaflet centrado en Madrid
- [ ] Métodos para:
  - Añadir marcadores de estaciones BiciMAD
  - Dibujar rutas con polylines
  - Colorear rutas según score (verde/amarillo/rojo)
  - Añadir heat map de calidad del aire (opcional)
  - Zoom a bounds de ruta
- [ ] Event handlers (click en estación, hover en ruta)

**Ejemplo**:
```javascript
class MapController {
    constructor(elementId) {
        this.map = L.map(elementId).setView([40.4168, -3.7038], 13);
        
        // Tile layer (OpenStreetMap)
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(this.map);

        this.markers = {};
        this.routes = [];
    }

    addStations(stations) {
        stations.features.forEach(station => {
            const marker = L.marker([
                station.geometry.coordinates[1],
                station.geometry.coordinates[0]
            ], {
                icon: this._createStationIcon(station.properties.dock_bikes)
            });

            marker.bindPopup(`
                <strong>${station.properties.name}</strong><br>
                🚲 Bicis: ${station.properties.dock_bikes}<br>
                🔓 Anclajes: ${station.properties.free_bases}
            `);

            marker.addTo(this.map);
            this.markers[station.properties.id] = marker;
        });
    }

    drawRoute(route, index) {
        const color = this._getRouteColor(route.score.classification);
        
        const polyline = L.polyline(
            route.polyline.map(p => [p.latitude, p.longitude]),
            {
                color: color,
                weight: 5,
                opacity: 0.7
            }
        );

        polyline.bindPopup(`
            <strong>${route.score.classification}</strong><br>
            📏 ${route.distance_km.toFixed(2)} km<br>
            ⏱️ ${route.duration_minutes} min<br>
            📊 Score: ${route.score.total_score.toFixed(1)}
        `);

        polyline.addTo(this.map);
        this.routes.push(polyline);

        return polyline;
    }

    clearRoutes() {
        this.routes.forEach(route => route.remove());
        this.routes = [];
    }

    fitBounds(coordinates) {
        const bounds = L.latLngBounds(coordinates);
        this.map.fitBounds(bounds, { padding: [50, 50] });
    }

    _getRouteColor(classification) {
        switch(classification) {
            case '🟢 Ruta Verde': return '#10b981';
            case '🟡 Ruta Balanceada': return '#f59e0b';
            case '🔴 Ruta Rápida': return '#ef4444';
            default: return '#6b7280';
        }
    }

    _createStationIcon(bikesAvailable) {
        const color = bikesAvailable > 5 ? 'green' : bikesAvailable > 0 ? 'orange' : 'red';
        return L.icon({
            iconUrl: `assets/icons/bike-marker-${color}.svg`,
            iconSize: [32, 32],
            iconAnchor: [16, 32],
            popupAnchor: [0, -32]
        });
    }
}

// Export singleton
const mapController = new MapController('map');
```

---

### Tarea 5: JavaScript - Route Calculator

**Archivo**: `frontend/js/route-calculator.js`

**Tareas**:
- [ ] Manejar input del formulario
- [ ] Validación de direcciones
- [ ] Geocoding (convertir dirección → coordenadas) usando Nominatim API
- [ ] Llamada a `/api/calculate-route`
- [ ] Renderizado de resultados en sidebar
- [ ] Interactividad: click en ruta para highlight en mapa

**Ejemplo**:
```javascript
class RouteCalculator {
    constructor() {
        this.originCoords = null;
        this.destinationCoords = null;
        this.routes = [];

        this._initEventListeners();
    }

    _initEventListeners() {
        document.getElementById('calculate-route-btn').addEventListener('click', () => {
            this.calculateRoutes();
        });

        document.getElementById('use-location-btn').addEventListener('click', () => {
            this._getUserLocation();
        });
    }

    async calculateRoutes() {
        const origin = document.getElementById('origin').value;
        const destination = document.getElementById('destination').value;

        if (!origin || !destination) {
            this._showError('Por favor, introduce origen y destino');
            return;
        }

        this._showLoading(true);

        try {
            // Geocode addresses
            this.originCoords = await this._geocode(origin);
            this.destinationCoords = await this._geocode(destination);

            // Call backend
            const response = await apiClient.calculateRoute(
                this.originCoords,
                this.destinationCoords
            );

            this.routes = response.routes;

            // Display results
            this._displayResults(response);
            
            // Draw on map
            this._drawRoutesOnMap(response);

        } catch (error) {
            this._showError('Error calculando rutas: ' + error.message);
        } finally {
            this._showLoading(false);
        }
    }

    async _geocode(address) {
        // Use Nominatim (OpenStreetMap geocoding)
        const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(address)},Madrid&format=json&limit=1`;
        
        const response = await fetch(url);
        const data = await response.json();
        
        if (data.length === 0) {
            throw new Error(`No se encontró la dirección: ${address}`);
        }

        return {
            lat: parseFloat(data[0].lat),
            lon: parseFloat(data[0].lon)
        };
    }

    _displayResults(data) {
        const resultsPanel = document.getElementById('results-panel');
        const routesList = document.getElementById('routes-list');

        routesList.innerHTML = '';

        data.routes.forEach((route, index) => {
            const routeCard = this._createRouteCard(route, index);
            routesList.appendChild(routeCard);
        });

        resultsPanel.classList.remove('hidden');
    }

    _createRouteCard(route, index) {
        const card = document.createElement('div');
        card.className = 'route-card';
        card.innerHTML = `
            <div class="route-header">
                <h4>${route.score.classification}</h4>
                <span class="score-badge" style="background: ${this._getScoreColor(route.score.total_score)}">
                    ${route.score.total_score.toFixed(1)}
                </span>
            </div>
            <div class="route-details">
                <div class="detail-item">
                    <span class="icon">📏</span>
                    <span>${route.distance_km.toFixed(2)} km</span>
                </div>
                <div class="detail-item">
                    <span class="icon">⏱️</span>
                    <span>${route.duration_minutes} min</span>
                </div>
                <div class="detail-item">
                    <span class="icon">🌫️</span>
                    <span>Calidad aire: ${route.score.air_quality_score.toFixed(1)}/100</span>
                </div>
            </div>
            <button class="btn-select" data-route-index="${index}">
                Seleccionar esta ruta
            </button>
        `;

        // Event listener
        card.querySelector('.btn-select').addEventListener('click', () => {
            this._selectRoute(index);
        });

        return card;
    }

    _drawRoutesOnMap(data) {
        mapController.clearRoutes();
        
        data.routes.forEach((route, index) => {
            const polyline = mapController.drawRoute(route, index);
        });

        // Fit map to routes
        const allCoords = data.routes.flatMap(r => 
            r.polyline.map(p => [p.latitude, p.longitude])
        );
        mapController.fitBounds(allCoords);
    }

    _selectRoute(index) {
        const route = this.routes[index];
        
        // Highlight on map
        mapController.clearRoutes();
        mapController.drawRoute(route, index);
        
        // Show route details (modal o panel)
        this._showRouteDetails(route);
    }

    _showLoading(show) {
        document.getElementById('loading-spinner').classList.toggle('hidden', !show);
        document.getElementById('calculate-route-btn').disabled = show;
    }

    _showError(message) {
        alert(message);  // TODO: Replace with toast notification
    }

    _getUserLocation() {
        if ('geolocation' in navigator) {
            navigator.geolocation.getCurrentPosition(position => {
                this.originCoords = {
                    lat: position.coords.latitude,
                    lon: position.coords.longitude
                };
                document.getElementById('origin').value = `${position.coords.latitude}, ${position.coords.longitude}`;
            });
        } else {
            this._showError('Geolocalización no disponible');
        }
    }

    _getScoreColor(score) {
        if (score < 25) return '#10b981';
        if (score < 45) return '#f59e0b';
        return '#ef4444';
    }
}

// Initialize
const routeCalculator = new RouteCalculator();
```

---

### Tarea 6: JavaScript - App Initialization

**Archivo**: `frontend/js/app.js`

**Tareas**:
- [ ] Inicialización de componentes
- [ ] Carga inicial de estaciones BiciMAD
- [ ] Health check del backend
- [ ] Event listeners globales
- [ ] Error handling global

**Ejemplo**:
```javascript
class App {
    async init() {
        console.log('🚴 BiciMAD Low-Emission Router iniciando...');

        try {
            // Health check
            const health = await apiClient.healthCheck();
            console.log('Backend health:', health);

            if (health.status !== 'healthy') {
                this._showWarning('Backend degradado, algunas funciones pueden no funcionar');
            }

            // Load stations
            const stations = await apiClient.getStations();
            mapController.addStations(stations);
            console.log(`✅ ${stations.features.length} estaciones BiciMAD cargadas`);

        } catch (error) {
            console.error('Error inicializando app:', error);
            this._showError('Error conectando con el backend');
        }
    }

    _showWarning(message) {
        // Toast notification
        console.warn(message);
    }

    _showError(message) {
        // Toast notification
        console.error(message);
    }
}

// Start app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    const app = new App();
    app.init();
});
```

---

### Tarea 7: Azure Static Web Apps Configuration

**Archivo**: `frontend/staticwebapp.config.json`

**Tareas**:
- [ ] Routing rules (SPA fallback a index.html)
- [ ] API proxy a Azure Functions
- [ ] Security headers
- [ ] CORS configuration

**Ejemplo**:
```json
{
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["anonymous"]
    },
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ],
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/assets/*", "/css/*", "/js/*"]
  },
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html",
      "statusCode": 200
    }
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Content-Security-Policy": "default-src 'self' https://*.openstreetmap.org https://*.tile.openstreetmap.org https://unpkg.com; script-src 'self' 'unsafe-inline' https://unpkg.com; style-src 'self' 'unsafe-inline' https://unpkg.com;"
  },
  "mimeTypes": {
    ".json": "application/json",
    ".svg": "image/svg+xml"
  }
}
```

---

### Checklist Completo de Tareas Frontend

#### HTML/CSS
- [ ] 1.1 - Crear `index.html` con estructura completa
- [ ] 1.2 - Crear `styles.css` (tema, colores, tipografía)
- [ ] 1.3 - Crear `map.css` (estilos específicos del mapa)
- [ ] 1.4 - Crear `responsive.css` (mobile-first)
- [ ] 1.5 - Crear iconos SVG custom para marcadores

#### JavaScript Core
- [ ] 2.1 - Implementar `api-client.js`
- [ ] 2.2 - Implementar `map-controller.js`
- [ ] 2.3 - Implementar `route-calculator.js`
- [ ] 2.4 - Implementar `station-selector.js`
- [ ] 2.5 - Implementar `utils.js`
- [ ] 2.6 - Implementar `app.js`

#### Features Avanzados
- [ ] 3.1 - Geocoding con Nominatim
- [ ] 3.2 - Geolocalización del usuario
- [ ] 3.3 - Autocomplete de estaciones BiciMAD
- [ ] 3.4 - Heat map de calidad del aire (opcional)
- [ ] 3.5 - Animación de rutas (opcional)
- [ ] 3.6 - Toast notifications

#### UX/UI Polish
- [ ] 4.1 - Loading states (spinners, skeleton screens)
- [ ] 4.2 - Error messages user-friendly
- [ ] 4.3 - Empty states ("No hay rutas disponibles")
- [ ] 4.4 - Animaciones suaves (transitions, transforms)
- [ ] 4.5 - Accesibilidad (ARIA labels, keyboard navigation)

#### Configuration
- [ ] 5.1 - `staticwebapp.config.json`
- [ ] 5.2 - Environment variables para API URL
- [ ] 5.3 - Analytics (opcional, Google Analytics o Application Insights)

#### Testing
- [ ] 6.1 - Manual testing en Chrome, Firefox, Safari
- [ ] 6.2 - Mobile testing (iOS Safari, Chrome Android)
- [ ] 6.3 - Lighthouse audit (performance, accessibility, SEO)
- [ ] 6.4 - Cross-browser compatibility

---

## 🚀 CI/CD y DevOps (GitHub Actions)

### Workflows Overview

```
.github/
├── workflows/
│   ├── 01-validate-bicep.yml          # Validación de Bicep
│   ├── 02-deploy-infrastructure.yml   # Despliegue de infraestructura
│   ├── 03-deploy-backend.yml          # Despliegue de Functions
│   ├── 04-deploy-frontend.yml         # Despliegue de Static Web App
│   ├── 05-run-tests.yml               # Suite de tests
│   └── 06-destroy-environment.yml     # Cleanup (solo dev)
│
└── scripts/
    ├── setup-oidc.sh                  # Script de configuración OIDC
    └── smoke-tests.sh                 # Smoke tests post-deploy
```

---

### Tarea 1: Workflow - Validate Bicep

**Archivo**: `.github/workflows/01-validate-bicep.yml`

**Tareas**:
- [ ] Trigger: Push a main o PRs que tocan `bicep/**`
- [ ] Jobs:
  1. Bicep build (compilación)
  2. Bicep lint (best practices)
  3. Checkov security scan
  4. Cost estimation (Azure Pricing Calculator)

**Ejemplo**:
```yaml
name: Validate Bicep

on:
  push:
    branches: [main]
    paths:
      - 'bicep/**'
      - '.github/workflows/01-validate-bicep.yml'
  pull_request:
    branches: [main]
    paths:
      - 'bicep/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Bicep
        run: |
          az bicep install
          az bicep version

      - name: Build Bicep
        run: |
          az bicep build --file bicep/bicep-router/main.bicep
          echo "✅ Bicep compilation successful"

      - name: Lint Bicep
        run: |
          az bicep lint --file bicep/bicep-router/main.bicep

      - name: Checkov Security Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: bicep/bicep-router
          framework: bicep
          soft_fail: false
          output_format: sarif
          output_file_path: checkov-results.sarif

      - name: Upload SARIF results
        if: always()
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: checkov-results.sarif
```

---

### Tarea 2: Workflow - Deploy Infrastructure

**Archivo**: `.github/workflows/02-deploy-infrastructure.yml`

**Tareas**:
- [ ] Trigger: Manual (workflow_dispatch) o automático en main
- [ ] Inputs: environment (dev/prod)
- [ ] OIDC authentication (secretless)
- [ ] What-If antes de aplicar cambios
- [ ] Deploy con Bicep
- [ ] Outputs guardados como artifacts

**Ejemplo**:
```yaml
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - prod
  push:
    branches: [main]
    paths:
      - 'bicep/**'

permissions:
  id-token: write
  contents: read

env:
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

jobs:
  plan:
    name: Plan Infrastructure Changes
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}-plan
    steps:
      - uses: actions/checkout@v4

      - name: OIDC Login to Azure
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: What-If Deployment
        run: |
          az deployment sub what-if \
            --location westeurope \
            --template-file bicep/bicep-router/main.bicep \
            --parameters bicep/bicep-router/parameters/${{ github.event.inputs.environment || 'dev' }}.bicepparam \
            --result-format FullResourcePayloads

  deploy:
    name: Deploy Infrastructure
    runs-on: ubuntu-latest
    needs: plan
    environment: ${{ github.event.inputs.environment || 'dev' }}
    outputs:
      functionAppName: ${{ steps.deploy.outputs.functionAppName }}
      staticWebAppName: ${{ steps.deploy.outputs.staticWebAppName }}
    steps:
      - uses: actions/checkout@v4

      - name: OIDC Login to Azure
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Bicep
        id: deploy
        uses: Azure/arm-deploy@v2
        with:
          scope: subscription
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          region: westeurope
          template: bicep/bicep-router/main.bicep
          parameters: bicep/bicep-router/parameters/${{ github.event.inputs.environment || 'dev' }}.bicepparam
          deploymentName: 'deploy-${{ github.run_number }}'

      - name: Save Deployment Outputs
        run: |
          echo "${{ steps.deploy.outputs }}" > deployment-outputs.json

      - name: Upload Deployment Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: deployment-outputs-${{ github.event.inputs.environment || 'dev' }}
          path: deployment-outputs.json
```

---

### Tarea 3: Workflow - Deploy Backend

**Archivo**: `.github/workflows/03-deploy-backend.yml`

**Tareas**:
- [ ] Trigger: Después de deploy infrastructure o cambios en `backend/**`
- [ ] Build de Python package
- [ ] Deploy a Azure Functions
- [ ] Smoke tests post-deploy

**Ejemplo**:
```yaml
name: Deploy Backend

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        type: choice
        options: [dev, prod]
  push:
    branches: [main]
    paths:
      - 'backend/**'
  workflow_run:
    workflows: ["Deploy Infrastructure"]
    types: [completed]

permissions:
  id-token: write
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install Dependencies
        run: |
          cd backend/function-app
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run Unit Tests
        run: |
          cd backend
          pytest tests/ --cov=function-app --cov-report=xml

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage.xml

      - name: Package Function App
        run: |
          cd backend/function-app
          zip -r ../function-app.zip .

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: function-app
          path: backend/function-app.zip

  deploy:
    runs-on: ubuntu-latest
    needs: build
    environment: ${{ github.event.inputs.environment || 'dev' }}
    steps:
      - name: Download Artifact
        uses: actions/download-artifact@v4
        with:
          name: function-app

      - name: OIDC Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy to Azure Functions
        uses: Azure/functions-action@v1
        with:
          app-name: ${{ secrets.FUNCTION_APP_NAME }}
          package: function-app.zip

      - name: Smoke Tests
        run: |
          FUNCTION_URL="https://${{ secrets.FUNCTION_APP_NAME }}.azurewebsites.net"
          
          # Health check
          curl -f $FUNCTION_URL/api/health || exit 1
          
          # Stations endpoint
          curl -f $FUNCTION_URL/api/stations || exit 1
          
          echo "✅ Smoke tests passed"
```

---

### Tarea 4: Workflow - Deploy Frontend

**Archivo**: `.github/workflows/04-deploy-frontend.yml`

**Tareas**:
- [ ] Trigger: Cambios en `frontend/**`
- [ ] Build (minificación opcional)
- [ ] Deploy a Azure Static Web Apps
- [ ] Lighthouse CI audit

**Ejemplo**:
```yaml
name: Deploy Frontend

on:
  push:
    branches: [main]
    paths:
      - 'frontend/**'
  pull_request:
    branches: [main]
    paths:
      - 'frontend/**'

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build And Deploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "/frontend"
          output_location: ""
          skip_app_build: true

      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          urls: |
            https://${{ secrets.STATIC_WEB_APP_URL }}
          uploadArtifacts: true
          temporaryPublicStorage: true
```

---

### Tarea 5: Workflow - Run Tests

**Archivo**: `.github/workflows/05-run-tests.yml`

**Tareas**:
- [ ] Unit tests (backend)
- [ ] Integration tests (APIs externas con mocks)
- [ ] E2E tests con Playwright (frontend)

**Ejemplo simplificado**:
```yaml
name: Run Tests

on:
  push:
    branches: [main]
  pull_request:

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: |
          cd backend
          pip install -r function-app/requirements.txt
          pip install pytest
          pytest tests/

  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: |
          cd backend
          pytest tests/test_integration.py

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: |
          cd frontend
          npm install playwright
          npx playwright install
          npx playwright test
```

---

### Tarea 6: GitHub Environments Setup

**Configuración manual en GitHub UI**:

**Environments a crear**:
1. **dev**
   - No reviewers required
   - Deployment branches: Any branch
   - Secrets:
     - `AZURE_CLIENT_ID`
     - `FUNCTION_APP_NAME`
     - `STATIC_WEB_APP_URL`

2. **prod**
   - Required reviewers: @team-leads, @architects
   - Wait timer: 5 minutes
   - Deployment branches: Only `main`
   - Secrets: (same as dev but prod values)

---

### Tarea 7: OIDC Configuration Script

**Archivo**: `scripts/setup/setup-oidc.sh`

**Tareas**:
- [ ] Script bash para configurar OIDC en Azure AD
- [ ] Crear App Registration
- [ ] Configurar Federated Credentials
- [ ] Asignar roles

**Ejemplo**:
```bash
#!/bin/bash
set -euo pipefail

GITHUB_ORG="your-org"
GITHUB_REPO="bicimad-router"
APP_NAME="github-actions-bicimad-oidc"
SUBSCRIPTION_ID="<YOUR_SUBSCRIPTION_ID>"

echo "🔐 Configurando OIDC para GitHub Actions..."

# Crear App Registration
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --query appId -o tsv)

echo "App ID: $APP_ID"

# Crear Service Principal
SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)

# Configurar Federated Credentials para main branch
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'"$GITHUB_ORG/$GITHUB_REPO"':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Asignar rol Contributor
az role assignment create \
  --assignee "$SP_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

echo "✅ OIDC configurado"
echo "Añade estos secrets a GitHub:"
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

---

### Checklist Completo de Tareas CI/CD

#### Workflows
- [ ] 1.1 - Crear `01-validate-bicep.yml`
- [ ] 1.2 - Crear `02-deploy-infrastructure.yml`
- [ ] 1.3 - Crear `03-deploy-backend.yml`
- [ ] 1.4 - Crear `04-deploy-frontend.yml`
- [ ] 1.5 - Crear `05-run-tests.yml`
- [ ] 1.6 - Crear `06-destroy-environment.yml` (cleanup dev)

#### GitHub Configuration
- [ ] 2.1 - Crear environment `dev`
- [ ] 2.2 - Crear environment `prod`
- [ ] 2.3 - Configurar protection rules en `prod`
- [ ] 2.4 - Añadir secrets (AZURE_CLIENT_ID, etc.)

#### OIDC Setup
- [ ] 3.1 - Ejecutar script `setup-oidc.sh`
- [ ] 3.2 - Verificar App Registration en Azure AD
- [ ] 3.3 - Test authentication desde GitHub Actions

#### Testing Automation
- [ ] 4.1 - Integrar pytest en workflow
- [ ] 4.2 - Integrar Playwright para E2E
- [ ] 4.3 - Code coverage reporting (Codecov)
- [ ] 4.4 - Security scanning (Checkov, Trivy)

#### Monitoring
- [ ] 5.1 - Configurar alertas de fallos en workflows
- [ ] 5.2 - Dashboard de deployment metrics
- [ ] 5.3 - Notification a Slack/Teams (opcional)

---

## 🧪 Estrategia de Testing y Validación

### Pirámide de Testing

```
           ┌─────────────────┐
           │   E2E Tests     │  ← 10% (Playwright)
           │   (5 scenarios) │
           └─────────────────┘
         ┌───────────────────────┐
         │  Integration Tests    │  ← 20% (Mocked APIs)
         │  (15 tests)           │
         └───────────────────────┘
    ┌──────────────────────────────────┐
    │     Unit Tests                   │  ← 70% (pytest)
    │     (50+ tests)                  │
    └──────────────────────────────────┘
```

---

### Tarea 1: Unit Tests - Backend

**Coverage targets**:
- `shared/scoring.py`: 100% (funciones críticas)
- `shared/models.py`: 90%
- `shared/data_fetcher.py`: 85%
- Functions: 80%

**Tests a implementar**:

```python
# backend/tests/test_scoring.py

def test_calculate_distance_score():
    # Ruta más corta = score 0
    assert calculate_distance_score(2.0, 2.0) == 0
    
    # Ruta 50% más larga = score 50
    assert calculate_distance_score(3.0, 2.0) == 50
    
    # Ruta 100% más larga = score 150
    assert calculate_distance_score(4.0, 2.0) == 150

def test_interpolate_air_quality():
    stations = [
        {'lat': 40.42, 'lon': -3.70, 'no2': 40, 'pm10': 30},
        {'lat': 40.43, 'lon': -3.71, 'no2': 60, 'pm10': 45},
        {'lat': 40.41, 'lon': -3.69, 'no2': 35, 'pm10': 25}
    ]
    
    # Point close to station 1
    result = interpolate_air_quality(40.42, -3.70, stations)
    assert abs(result['no2'] - 40) < 5  # Should be close to 40

def test_classify_route():
    # Low score = Verde
    assert classify_route(15)['label'] == '🟢 Ruta Verde'
    
    # Medium score = Balanceada
    assert classify_route(30)['label'] == '🟡 Ruta Balanceada'
    
    # High score = Rápida
    assert classify_route(50)['label'] == '🔴 Ruta Rápida'
```

---

### Tarea 2: Integration Tests - APIs Externas

**Tests con mocks**:

```python
# backend/tests/test_integration.py

from unittest.mock import patch, MagicMock

def test_get_stations_with_cache():
    # Mock BiciMAD API
    mock_response = {
        '@graph': [
            {
                'id': '1',
                'name': 'Test Station',
                'location': {'latitude': 40.42, 'longitude': -3.70},
                'dock_bikes': 10,
                'free_bases': 5,
                'total_bases': 30,
                'activate': 1
            }
        ]
    }
    
    with patch('requests.get') as mock_get:
        mock_get.return_value.json.return_value = mock_response
        
        fetcher = BiciMADFetcher()
        stations = fetcher.get_stations()
        
        assert len(stations) == 1
        assert stations[0].name == 'Test Station'

def test_calculate_route_end_to_end():
    # Mock Azure Maps, BiciMAD, Air Quality APIs
    # Test full flow from request to response
    pass
```

---

### Tarea 3: E2E Tests - Frontend (Playwright)

**Scenarios críticos**:

1. **Happy path**: Usuario calcula ruta y selecciona una
2. **Error handling**: API falla, mostrar error gracefully
3. **Mobile**: Funciona correctamente en viewport móvil
4. **Performance**: Carga inicial < 3s
5. **Accessibility**: Navegación por teclado funciona

**Ejemplo**:

```javascript
// frontend/tests/e2e/calculate-route.spec.js

const { test, expect } = require('@playwright/test');

test('calculate route from origin to destination', async ({ page }) => {
  await page.goto('http://localhost:3000');

  // Wait for map to load
  await expect(page.locator('#map')).toBeVisible();

  // Fill origin
  await page.fill('#origin', 'Plaza Mayor, Madrid');

  // Fill destination
  await page.fill('#destination', 'Parque del Retiro, Madrid');

  // Click calculate
  await page.click('#calculate-route-btn');

  // Wait for results
  await expect(page.locator('#results-panel')).toBeVisible({ timeout: 10000 });

  // Should show 3 routes
  const routeCards = await page.locator('.route-card').count();
  expect(routeCards).toBe(3);

  // Routes should be drawn on map
  const polylines = await page.evaluate(() => {
    return document.querySelectorAll('.leaflet-overlay-pane path').length;
  });
  expect(polylines).toBeGreaterThan(0);
});

test('mobile responsive layout', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('http://localhost:3000');

  // Sidebar should be collapsed on mobile
  const sidebar = await page.locator('.sidebar');
  await expect(sidebar).toHaveCSS('transform', 'matrix(1, 0, 0, 1, -400, 0)'); // translateX(-400px)
});
```

---

### Tarea 4: Performance Tests

**Métricas objetivo**:
- API response time: < 2s (p95)
- Frontend load time: < 3s (LCP)
- Map interactions: 60 FPS

**Herramientas**:
- Lighthouse CI (automatizado)
- K6 o Artillery para load testing backend
- Chrome DevTools Performance profiling

---

### Tarea 5: Smoke Tests Post-Deploy

**Script**: `scripts/smoke-tests.sh`

```bash
#!/bin/bash
set -e

BASE_URL=${1:-"https://func-bicimad-router-dev-weu.azurewebsites.net"}

echo "🧪 Running smoke tests against $BASE_URL"

# Test 1: Health check
echo "Test 1: Health check"
HEALTH=$(curl -s "$BASE_URL/api/health")
STATUS=$(echo $HEALTH | jq -r '.status')
if [ "$STATUS" != "healthy" ]; then
  echo "❌ Health check failed"
  exit 1
fi
echo "✅ Health check passed"

# Test 2: Get stations
echo "Test 2: Get stations"
STATIONS=$(curl -s "$BASE_URL/api/stations")
COUNT=$(echo $STATIONS | jq '.features | length')
if [ "$COUNT" -lt 100 ]; then
  echo "❌ Expected >100 stations, got $COUNT"
  exit 1
fi
echo "✅ Stations endpoint passed ($COUNT stations)"

# Test 3: Get air quality
echo "Test 3: Get air quality"
AIR_QUALITY=$(curl -s "$BASE_URL/api/air-quality?lat=40.4168&lon=-3.7038")
NO2=$(echo $AIR_QUALITY | jq -r '.measurements.no2')
if [ -z "$NO2" ]; then
  echo "❌ Air quality endpoint failed"
  exit 1
fi
echo "✅ Air quality endpoint passed (NO2: $NO2 µg/m³)"

echo ""
echo "🎉 All smoke tests passed!"
```

---

### Checklist Completo de Testing

#### Unit Tests
- [ ] 1.1 - Tests para `scoring.py` (distance, air quality, availability)
- [ ] 1.2 - Tests para `data_fetcher.py` (parsing, error handling)
- [ ] 1.3 - Tests para `models.py` (validación Pydantic)
- [ ] 1.4 - Tests para `cache_manager.py`
- [ ] 1.5 - Tests para `utils.py` (haversine, etc.)
- [ ] 1.6 - Alcanzar >80% code coverage

#### Integration Tests
- [ ] 2.1 - Mock de Azure Maps API
- [ ] 2.2 - Mock de BiciMAD API
- [ ] 2.3 - Mock de Air Quality API
- [ ] 2.4 - Test end-to-end de `/api/calculate-route`

#### E2E Tests
- [ ] 3.1 - Setup Playwright project
- [ ] 3.2 - Test: Calculate route (happy path)
- [ ] 3.3 - Test: Error handling (API fails)
- [ ] 3.4 - Test: Mobile responsive
- [ ] 3.5 - Test: Accessibility (keyboard navigation)

#### Performance Tests
- [ ] 4.1 - Lighthouse CI integration
- [ ] 4.2 - Load testing backend con K6
- [ ] 4.3 - Frontend profiling (Chrome DevTools)

#### Smoke Tests
- [ ] 5.1 - Script `smoke-tests.sh`
- [ ] 5.2 - Integration en GitHub Actions post-deploy
- [ ] 5.3 - Alertas si smoke tests fallan

---

## 💰 FinOps, Costos y Plan de Demo

### Estimación de Costos Azure

#### Costos Mensuales por Servicio (Región: West Europe)

| Servicio | SKU/Plan | Uso Estimado | Costo/mes | Justificación |
|----------|----------|--------------|-----------|---------------|
| **Azure Functions** | Consumption | 100K ejecuciones, 200ms avg | $0.40 | Pay-per-execution, 1M gratis |
| **Static Web Apps** | Free | <100GB bandwidth | $0.00 | Tier gratuito suficiente |
| **Storage Account** | Standard LRS | 1GB blob, 1M txn | $0.05 | Cache mínimo |
| **Key Vault** | Standard | 10K operaciones | $0.03 | Secretos básicos |
| **Application Insights** | Pay-as-you-go | 1GB logs | $2.30 | 5GB gratis, luego $2.30/GB |
| **Log Analytics** | Pay-as-you-go | Incluido en App Insights | $0.00 | Primeros 5GB gratis |
| **Azure Maps** | Gen2 S1 | 1K transacciones | $0.00 | 1K gratis/mes |
| **Outbound Data Transfer** | Standard | 5GB | $0.40 | $0.08/GB después de 100GB gratis |
| | | **TOTAL ESTIMADO** | **$3.18/mes** | |

**Notas**:
- ✅ Durante el hackathon (1 mes): **< $5 USD**
- ✅ Con tráfico bajo (100 usuarios/día): **< $10 USD/mes**
- ⚠️ Con tráfico alto (1000+ usuarios/día): **~$30 USD/mes** (principalmente App Insights)

---

### Optimizaciones de Costo

#### 1. Caching Agresivo
**Ahorro**: 60% de llamadas a Azure Maps  
**Implementación**:
```python
# Cache routes por 6 horas (pares origen-destino no cambian frecuentemente)
CACHE_TTL_ROUTES = 6 * 3600  # 6 hours
CACHE_TTL_STATIONS = 20 * 60  # 20 minutes
```

**Impacto**:
- Sin cache: 10K rutas/mes × $0.005 = $50
- Con cache: 4K rutas/mes × $0.005 = $20
- **Ahorro: $30/mes**

#### 2. Function App Warm-Up
**Problema**: Cold starts consumen execution time  
**Solución**: Health check cada 5 minutos para mantener instancia warm

```yaml
# .github/workflows/keep-warm.yml
- cron: '*/5 * * * *'  # Every 5 minutes
run: curl https://func-bicimad-router.azurewebsites.net/api/health
```

**Costo adicional**: $0.50/mes  
**Beneficio**: UX mejorada (sin lag de cold start)

#### 3. Application Insights Sampling
**Configuración**:
```json
{
  "sampling": {
    "percentage": 50,  // Sample 50% of requests in prod
    "maxTelemetryItemsPerSecond": 5
  }
}
```

**Ahorro**: 50% de costo en logs = $1.15/mes

#### 4. Auto-Shutdown de Entorno Dev
**Script**: `scripts/utils/auto-shutdown-dev.sh`

```bash
# Shutdown dev environment fuera de horario laboral
if [ $(date +%H) -gt 18 ] || [ $(date +%H) -lt 8 ]; then
  az functionapp stop --name func-bicimad-router-dev-weu
  echo "Dev environment stopped to save costs"
fi
```

**Ahorro**: ~30% en dev = $1/mes

---

### Budget Alerts Configuration

**Azure Budget configurado en Bicep**:

```bicep
resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: 'bicimad-router-budget'
  properties: {
    amount: 30  // $30 USD
    timeGrain: 'Monthly'
    category: 'Cost'
    notifications: {
      actual_50_percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: ['owner@example.com']
        contactRoles: ['Owner']
        thresholdType: 'Actual'
      }
      actual_80_percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: ['owner@example.com']
      }
      forecasted_100_percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: ['owner@example.com']
        thresholdType: 'Forecasted'
      }
    }
  }
}
```

**Acciones automatizadas**:
- 50%: Email warning
- 80%: Email alert + Slack notification
- 100%: Disable non-critical resources (opcional)

---

### Matriz de Riesgos

| Riesgo | Probabilidad | Impacto | Severidad | Mitigación |
|--------|--------------|---------|-----------|------------|
| **API externa caída** (BiciMAD) | Media | Alto | 🟡 Medio | Cache con TTL extendido (stale data acceptable) |
| **Azure Maps límite excedido** | Baja | Medio | 🟢 Bajo | Cache agresivo + rate limiting |
| **Cold start latencia** | Alta | Medio | 🟡 Medio | Keep-warm pings + Premium plan para prod |
| **Costo inesperado** | Baja | Alto | 🟡 Medio | Budget alerts + daily cost monitoring |
| **Error en algoritmo scoring** | Media | Alto | 🟠 Alto | Unit tests 100% + validation con datos reales |
| **Seguridad (secretos expuestos)** | Baja | Crítico | 🔴 Crítico | Key Vault + OIDC + secret scanning |
| **Performance degradation** | Media | Medio | 🟡 Medio | App Insights alerts + load testing |
| **Data privacy (GDPR)** | Baja | Alto | 🟡 Medio | No almacenar datos personales, solo agregados |

---

### Plan de Demo para el Hackathon

#### Preparación (1 semana antes)

**Checklist**:
- [ ] Deploy a producción completado
- [ ] Datos de demo preparados (3 rutas emblemáticas de Madrid)
- [ ] Slides de presentación (10 slides máximo)
- [ ] Video demo de 2 minutos grabado (backup por si falla wifi)
- [ ] Testear en laptop de presentación

**Rutas demo sugeridas**:
1. **Sol → Retiro**: Clásica turística
2. **Malasaña → Chueca**: Ruta urbana con tráfico
3. **Casa de Campo loop**: Ruta verde (parque)

---

#### Estructura de la Demo (7 minutos totales)

**Minuto 0-1: Problema**
> "Los ciclistas urbanos en Madrid respiran hasta un 30% más de contaminación que los peatones. ¿Cómo podemos ayudarles a elegir rutas más saludables usando datos abiertos?"

**Minuto 1-3: Solución (Demo en vivo)**
1. Abrir aplicación
2. Mostrar mapa con estaciones BiciMAD
3. Introducir origen: "Plaza Mayor"
4. Introducir destino: "Parque del Retiro"
5. Click "Calcular Rutas"
6. Mostrar 3 resultados:
   - 🟢 Ruta Verde (2.8 km, score 18.8)
   - 🟡 Ruta Balanceada (2.3 km, score 26.2)
   - 🔴 Ruta Rápida (2.0 km, score 40.8)
7. Seleccionar Ruta Verde
8. Zoom en mapa para mostrar overlay de calidad del aire

**Minuto 3-5: Tecnología**
- Arquitectura Azure (mostrar diagrama)
- 3 fuentes de datos oficiales
- Algoritmo de scoring (fórmula simplificada)
- 100% Infrastructure as Code con Bicep

**Minuto 5-6: Impacto y Extensibilidad**
- Impacto: Reducción de exposición a NO₂ en un 40% promedio
- Extensiones:
  - Predicción con ML (forecasting)
  - Integración con apps de movilidad
  - Gamificación (badges por "km verdes")
- Costos: < $5/mes en Azure

**Minuto 6-7: Q&A**

---

#### Script de Presentación (Elevator Pitch)

> "Imagina que eres ciclista urbano y usas BiciMAD diariamente. Hoy Google Maps te dice 'la ruta más rápida es por Gran Vía', pero Gran Vía tiene niveles de NO₂ 3 veces superiores al límite de la OMS.
>
> **BiciMAD Low-Emission Router** combina datos en tiempo real de disponibilidad de BiciMAD y calidad del aire de Madrid para sugerirte rutas que priorizan tu salud respiratoria.
>
> Tecnología: 100% Azure serverless, costando menos de $5/mes, usando 3 fuentes oficiales de datos abiertos, con infraestructura declarada en Bicep y CI/CD automatizado.
>
> El resultado: Una app que puede reducir tu exposición a contaminantes en un 40% sin añadir más de 5 minutos a tu ruta."

---

#### Slides de Presentación (Outline)

**Slide 1: Título**
- Logo + nombre del proyecto
- Tagline: "Respira mejor, pedalea mejor"

**Slide 2: El Problema**
- Estadística: "Los ciclistas respiran 2.3x más NO₂ que los peatones"
- Foto: Ciclista en Gran Vía con tráfico

**Slide 3: La Solución**
- Screenshot de la app con las 3 rutas
- Highlight del score de emisiones

**Slide 4: Cómo Funciona**
- Diagrama de flujo: BiciMAD + Calidad Aire + Azure Maps → Rutas rankeadas

**Slide 5: Algoritmo de Scoring**
- Fórmula visual: (Distance × 0.2) + (Air Quality × 0.6) + (Availability × 0.2)
- Ejemplo numérico con Ruta Verde vs Ruta Rápida

**Slide 6: Fuentes de Datos**
- Logos: Ayuntamiento Madrid, Comunidad de Madrid
- 3 APIs utilizadas (BiciMAD, Calidad Aire, Azure Maps)

**Slide 7: Arquitectura Azure**
- Diagrama simplificado
- Logos de servicios: Functions, Static Web Apps, Storage, Key Vault

**Slide 8: DevOps & IaC**
- Screenshot de GitHub Actions workflow
- "100% automatizado con Bicep"

**Slide 9: Impacto y Métricas**
- Reducción de exposición: 40%
- Costo operativo: < $5/mes
- Tiempo de desarrollo: 2 semanas

**Slide 10: Próximos Pasos**
- Predicción con ML
- Integración con EMT app
- Expansión a otras ciudades
- GitHub repo + QR code

---

#### Contingencias Durante la Demo

**Si falla la conexión**:
- ✅ Tener video pregrabado de 2 min
- ✅ Screenshots de cada paso en slides

**Si falla el backend**:
- ✅ Modo demo con datos mockeados en frontend
- ✅ Explicar la arquitectura mientras "se recupera"

**Si preguntan algo técnico inesperado**:
- ✅ Tener README técnico con detalles en GitHub
- ✅ Ofrecer follow-up por email/LinkedIn

---

### Métricas de Éxito

#### Durante el Hackathon

| Métrica | Target | Medición |
|---------|--------|----------|
| Demo sin fallos técnicos | 100% | Manual |
| Tiempo de presentación | 7 min ±30s | Timer |
| Preguntas del jurado | ≥3 | Count |
| Interés en código fuente | ≥2 personas | GitHub stars/requests |

#### Post-Hackathon

| Métrica | Target 1 mes | Target 3 meses |
|---------|--------------|----------------|
| GitHub stars | 20 | 50 |
| Pull requests | 2 | 5 |
| Usuarios activos (si se publica) | 100 | 500 |
| Menciones en redes sociales | 5 | 20 |
| Artículos/blogs | 1 | 3 |

#### Impacto Real (KPIs de Negocio)

Si el proyecto se adoptara oficialmente:

- **Salud pública**: Reducción 30% en inhalación de NO₂ para usuarios
- **Adopción de BiciMAD**: Incremento 5-10% de usuarios por percepción de "movilidad saludable"
- **Planificación urbana**: Datos para identificar zonas que necesitan más carriles bici protegidos
- **Sostenibilidad**: Reducción indirecta de emisiones al promover bici sobre coche

---

### Roadmap Post-Hackathon

#### Fase 1: Refinamiento (Semana 1-2)
- [ ] Incorporar feedback del jurado
- [ ] Mejorar UX basado en observaciones
- [ ] Añadir tests que faltaron por tiempo
- [ ] Documentación completa del proyecto

#### Fase 2: Features Avanzados (Mes 1-2)
- [ ] Predicción de calidad aire con Azure ML (forecasting 2h adelante)
- [ ] Heat map de calidad del aire en mapa
- [ ] Historial de rutas favoritas (local storage)
- [ ] PWA (Progressive Web App) para instalación

#### Fase 3: Expansión (Mes 3-6)
- [ ] Soporte para otros modos: patinetes, walking, running
- [ ] Integración con EMT API para transporte multimodal
- [ ] Expansión a otras ciudades (Barcelona, Valencia)
- [ ] Mobile app nativa (React Native)

#### Fase 4: Productización (Mes 6-12)
- [ ] Partnership con Ayuntamiento de Madrid
- [ ] Escalado de infraestructura (App Service Plan dedicado)
- [ ] Programa beta con usuarios reales
- [ ] Análisis de impacto en salud (colaboración con universidades)

---

### Recursos Adicionales

#### Para el Equipo

**Documentación**:
- [Azure Functions Python Developer Guide](https://learn.microsoft.com/azure/azure-functions/functions-reference-python)
- [Leaflet.js Documentation](https://leafletjs.com/reference.html)
- [Bicep Language Reference](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

**Datasets**:
- [Ayuntamiento Madrid - Calidad Aire](https://datos.madrid.es/portal/site/egob/)
- [Comunidad Madrid - Open Data](https://datos.comunidad.madrid/)
- [Azure Maps Documentation](https://learn.microsoft.com/azure/azure-maps/)

**Inspiración**:
- [BreezOMeter API](https://www.breezometer.com/) - Similar concept comercial
- [AirVisual](https://www.iqair.com/) - Air quality mapping
- [Strava Heatmaps](https://www.strava.com/heatmap) - Route popularity

#### Para el Jurado

**GitHub Repository**: `https://github.com/<your-org>/bicimad-low-emission-router`

**Live Demo**: `https://bicimad-router.azurestaticapps.net` (placeholder)

**Presentación**: [Link a Google Slides]

**Video Demo**: [Link a YouTube]

---

## 📅 Timeline de Implementación

### Sprint 1 (Semana 1): Fundamentos

**Días 1-2: Setup**
- [ ] Crear repo GitHub
- [ ] Configurar Azure subscription
- [ ] Setup OIDC
- [ ] Crear estructura de directorios

**Días 3-4: Infraestructura**
- [ ] Implementar módulos Bicep
- [ ] Deploy infraestructura a dev
- [ ] Configurar Key Vault con secrets
- [ ] Verificar Application Insights

**Días 5-7: Backend Core**
- [ ] Implementar modelos Pydantic
- [ ] Implementar data fetchers (BiciMAD, Air Quality)
- [ ] Implementar cache manager
- [ ] Implementar función GetStations

---

### Sprint 2 (Semana 2): Algoritmo y Frontend

**Días 8-10: Algoritmo de Scoring**
- [ ] Implementar scoring.py completo
- [ ] Implementar interpolación IDW
- [ ] Unit tests al 100%
- [ ] Implementar función CalculateRoute

**Días 11-13: Frontend**
- [ ] Estructura HTML + CSS
- [ ] Integrar Leaflet.js
- [ ] Implementar map-controller.js
- [ ] Implementar route-calculator.js

**Día 14: Integration**
- [ ] Conectar frontend con backend
- [ ] Deploy a dev
- [ ] Testing end-to-end manual

---

### Sprint 3 (Semana 3): Polish y Demo

**Días 15-17: Testing y CI/CD**
- [ ] Workflows GitHub Actions completos
- [ ] Integration tests
- [ ] E2E tests con Playwright
- [ ] Deploy a producción

**Días 18-19: UX Polish**
- [ ] Responsive design refinado
- [ ] Loading states
- [ ] Error handling mejorado
- [ ] Lighthouse audit

**Días 20-21: Demo Prep**
- [ ] Crear slides
- [ ] Grabar video demo
- [ ] Ensayar presentación
- [ ] Preparar Q&A

---

## 🎉 Conclusión

Este proyecto combina:

✅ **Impacto real**: Mejora la salud respiratoria de ciclistas urbanos  
✅ **Innovación técnica**: Algoritmo de scoring multi-factorial avanzado  
✅ **Datos abiertos**: Reutilización de 3+ fuentes oficiales  
✅ **Azure best practices**: IaC, CI/CD, FinOps, Well-Architected Framework  
✅ **Extensibilidad**: Base sólida para features futuros (ML, gamificación)  
✅ **Sostenibilidad**: Costo operativo < $5/mes  

**Pitch final para el jurado**:

> "Low-Emission BiciMAD Router no es solo una app, es una prueba de concepto de cómo los datos abiertos pueden transformar la movilidad urbana y proteger la salud pública. Con una inversión mínima en cloud y aprovechando el ecosistema Azure, hemos creado una solución enterprise-grade que podría estar en producción mañana mismo."

---

**🚴 ¡Respira mejor, pedalea mejor!**

---

## Appendix: Tareas Totales del Proyecto

### Resumen Ejecutivo de Tareas

| Categoría | Subtareas | Estimación | Prioridad |
|-----------|-----------|------------|-----------|
| **Infraestructura Bicep** | 20 tareas | 2 días | 🔴 Alta |
| **Backend Functions** | 25 tareas | 4 días | 🔴 Alta |
| **Frontend HTML+JS** | 30 tareas | 3 días | 🟡 Media |
| **CI/CD GitHub Actions** | 15 tareas | 2 días | 🟡 Media |
| **Testing** | 20 tareas | 2 días | 🟡 Media |
| **FinOps y Demo** | 10 tareas | 1 día | 🟢 Baja |
| **TOTAL** | **120 tareas** | **14 días** | |

**Conclusión**: Proyecto completable en **3 semanas** con 1 developer full-time o **2 semanas** con 2 developers.

---

**FIN DEL DOCUMENTO**

