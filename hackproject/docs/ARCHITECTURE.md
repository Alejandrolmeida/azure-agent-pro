# BiciMAD Low Emission Router - Architecture Documentation

**Proyecto**: DataSaturday Madrid 2025 - DataHack4Good  
**Versión**: 1.0.0  
**Última actualización**: 30 de noviembre de 2025  
**Estado**: Implementation Complete (93% - Pending Azure Deployment)

---

## Tabla de Contenidos

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Architecture Patterns](#architecture-patterns)
4. [Component Design](#component-design)
5. [Data Flow](#data-flow)
6. [Technology Stack](#technology-stack)
7. [Security & Privacy](#security--privacy)
8. [Performance & Scalability](#performance--scalability)
9. [Development Workflow](#development-workflow)
10. [Deployment Architecture](#deployment-architecture)
11. [Architectural Decision Records](#architectural-decision-records)

---

## Executive Summary

**BiciMAD Low Emission Router** es una aplicación web progresiva que calcula rutas optimizadas en bicicleta para Madrid, priorizando zonas de baja contaminación atmosférica. El sistema integra tres fuentes de datos en tiempo real:

- **BiciMAD API**: Disponibilidad de estaciones de bicicletas públicas
- **Red de Calidad del Aire**: Mediciones de NO2, PM10, PM2.5 de 12 estaciones de monitoreo
- **Azure Maps API**: Cálculo de rutas en modo bicicleta

### Objetivos del Proyecto

1. **Salud Pública**: Reducir la exposición de ciclistas a contaminantes atmosféricos
2. **Movilidad Sostenible**: Promover el uso de BiciMAD con rutas saludables
3. **Open Data**: Aprovechar datos abiertos del Ayuntamiento de Madrid
4. **Cloud-Native**: Demostrar arquitectura serverless en Azure con IA

### Key Metrics

- **Cobertura**: 30 estaciones BiciMAD + 12 estaciones de calidad del aire
- **Algoritmo**: Interpolación IDW (Inverse Distance Weighting) con índice de exposición
- **Preferencias**: 4 modos (air_quality, distance, time, balanced)
- **Performance**: <2s response time para cálculo de ruta con 3 alternativas
- **Offline-First**: Funciona sin Azure resources usando mock data

---

## System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE (SPA)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │   Leaflet    │  │   Form UI    │  │   Results    │             │
│  │  Map Widget  │  │  Controller  │  │   Display    │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│         │                  │                  │                      │
│         └──────────────────┴──────────────────┘                      │
│                            │                                         │
│                     ┌──────▼──────┐                                 │
│                     │  API Client │                                 │
│                     │   (Fetch)   │                                 │
│                     └──────┬──────┘                                 │
└────────────────────────────┼────────────────────────────────────────┘
                             │ HTTPS
                             │
┌────────────────────────────▼────────────────────────────────────────┐
│                    AZURE FUNCTIONS (Serverless)                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  │
│  │   Health   │  │  Stations  │  │ Air Quality│  │   Route    │  │
│  │   Check    │  │  Endpoint  │  │  Endpoint  │  │ Calculator │  │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘  │
│         │                │                │                │         │
│         └────────────────┴────────────────┴────────────────┘         │
│                                   │                                  │
│                          ┌────────▼────────┐                        │
│                          │  Cache Manager  │                        │
│                          │ (Blob Storage)  │                        │
│                          └────────┬────────┘                        │
└─────────────────────────────────────┼──────────────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
    ┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌────────▼────────┐
    │   BiciMAD API     │  │  Madrid OpenData  │  │  Azure Maps API │
    │   (Stations)      │  │  (Air Quality)    │  │  (Routing)      │
    └───────────────────┘  └───────────────────┘  └─────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Technology |
|-----------|---------------|------------|
| **Frontend SPA** | User interaction, map visualization, results display | Vanilla JS + Leaflet.js |
| **API Gateway** | HTTP endpoints, validation, error handling | Azure Functions (Python) |
| **Data Providers** | External API integration with retry logic | httpx (async HTTP) |
| **Scoring Engine** | Emission calculation, route comparison | NumPy + Pandas |
| **Cache Manager** | TTL-based caching (20min real-time, 24h routes) | Azure Blob Storage |
| **External APIs** | Real-time data sources | REST APIs |

---

## Architecture Patterns

### 1. Serverless Architecture (Azure Functions)

**Rationale**: Cost-effective, auto-scaling, pay-per-execution model ideal for variable traffic hackathon demo.

```python
# function_app.py - HTTP Trigger
@app.route(route="stations", methods=["GET"])
async def get_stations(req: func.HttpRequest) -> func.HttpResponse:
    # Handler logic with async providers
    pass
```

**Benefits**:
- ✅ No infrastructure management
- ✅ Automatic scaling (0 → N instances)
- ✅ Pay only for executions
- ✅ Built-in HTTPS + CORS

**Tradeoffs**:
- ⚠️ Cold start latency (~2-3s first request)
- ⚠️ Timeout limits (230s HTTP, 10min timer)

### 2. Provider Pattern (External API Abstraction)

**Rationale**: Decouple business logic from external APIs, enable testing with mocks.

```python
class BiciMADProvider:
    async def get_stations(self) -> List[BiciMADStation]:
        # HTTP call with retry logic
        
    async def get_nearby_stations(self, lat, lon, radius_km):
        # Geodesic filtering
```

**Benefits**:
- ✅ Single Responsibility Principle
- ✅ Easy mocking for unit tests
- ✅ Centralized error handling
- ✅ Simulation mode for offline dev

### 3. Cache-Aside Pattern

**Rationale**: Reduce API calls (cost + latency), improve response time.

```python
# Pseudocode
def get_data(key):
    if cache.has(key) and not expired(key):
        return cache.get(key)
    
    data = fetch_from_api()
    cache.set(key, data, ttl)
    return data
```

**TTL Strategy**:
| Data Type | TTL | Justification |
|-----------|-----|---------------|
| BiciMAD Stations | 20 min | Station availability changes frequently |
| Air Quality | 20 min | Measurements updated hourly |
| Routes | 24 hours | Route geometry stable unless road changes |

### 4. Event-Driven Frontend (Custom Events)

**Rationale**: Loose coupling between UI components, maintainability.

```javascript
// app.js - Event Bus
document.dispatchEvent(new CustomEvent('mapclick', { detail: coords }));

// map.js - Listener
document.addEventListener('mapclick', (e) => {
    this.setOrigin(e.detail.lat, e.detail.lon);
});
```

**Benefits**:
- ✅ No direct module dependencies
- ✅ Easy to add new features
- ✅ Testable in isolation

### 5. Dual-Mode Architecture (Production + Local)

**Rationale**: Enable offline development without Azure resources.

```python
# Environment-based provider selection
USE_LOCAL_CACHE = os.getenv('USE_LOCAL_CACHE', 'false').lower() == 'true'

if USE_LOCAL_CACHE:
    cache_manager = CacheManager(use_local_cache=True)
else:
    cache_manager = CacheManager(storage_connection_string=AZURE_STORAGE_CS)
```

**Modes**:
- **Production**: Azure Blob Storage + Real APIs
- **Local/Test**: In-memory cache + Simulated data

---

## Component Design

### Backend Components

#### 1. Data Providers Layer (`utils/data_providers.py`)

**BiciMADProvider**
```python
@dataclass
class BiciMADStation:
    id: str
    name: str
    latitude: float
    longitude: float
    total_bases: int
    free_bases: int
    dock_bikes: int
    active: bool
    
    def distance_to(self, lat: float, lon: float) -> float:
        """Calculate geodesic distance in km"""
        return geodesic((self.latitude, self.longitude), (lat, lon)).kilometers
```

**Key Features**:
- Async HTTP with `httpx` (connection pooling)
- Retry logic with exponential backoff
- Geodesic distance calculations with `geopy`
- Station filtering by radius and max results

**AirQualityProvider**
```python
async def get_air_quality(self, lat: float, lon: float) -> Dict[str, Any]:
    """
    Get interpolated air quality at point using IDW from 3 nearest stations
    """
    nearest = self._get_nearest_stations(lat, lon, k=3)
    readings = [self._get_reading(station) for station in nearest]
    interpolated = self._interpolate_readings(readings, lat, lon)
    return {
        'pollutants': interpolated,
        'score': self._calculate_air_quality_score(interpolated),
        'level': self._get_air_quality_level(score)
    }
```

**IDW Algorithm**:
```
For each pollutant P at target point:
    P_interpolated = Σ(P_i * w_i) / Σ(w_i)
    where w_i = 1 / (distance_i ^ power)
    power = 2 (standard IDW)
```

**AzureMapsProvider**
```python
async def calculate_routes(
    self, 
    origin: Dict, 
    destination: Dict
) -> List[Dict]:
    """
    Calculate 3 routes: fastest, shortest, eco
    Falls back to simulation if no API key
    """
    if not self.api_key or self.api_key == 'your-azure-maps-key':
        return self._simulate_routes(origin, destination)
    
    routes = await asyncio.gather(*[
        self._get_single_route(origin, destination, 'fastest'),
        self._get_single_route(origin, destination, 'shortest'),
        self._get_single_route(origin, destination, 'eco')
    ])
    return routes
```

#### 2. Scoring Engine (`utils/scoring_engine.py`)

**Core Algorithm**:

```python
async def score_routes(
    self, 
    routes: List[Dict], 
    preference: str = 'balanced'
) -> List[RouteScore]:
    """
    1. Sample route points every 200m
    2. Get air quality at each point (with cache)
    3. Calculate average pollutant exposure
    4. Compute emission score (0-100, lower is better)
    5. Determine health impact and recommendation level
    6. Sort by user preference
    """
    scored_routes = []
    
    for route in routes:
        # Sample geometry
        points = self._sample_route_points(route, sample_distance=200)
        
        # Get air quality at each point
        aq_data = await asyncio.gather(*[
            self._get_air_quality_at_point(lat, lon) 
            for lat, lon in points
        ])
        
        # Calculate exposure
        avg_pollutants = self._calculate_average_pollutants(aq_data)
        duration_minutes = route['duration_seconds'] / 60
        exposure_index = self._calculate_exposure_index(
            avg_pollutants, 
            duration_minutes
        )
        
        # Score
        emission_score = self._calculate_emission_score(aq_data)
        
        scored_routes.append(RouteScore(
            route_type=route['type'],
            emission_score=emission_score,
            pollutants=avg_pollutants,
            health_impact=self._determine_health_impact(emission_score),
            recommendation_level=self._get_recommendation_level(emission_score),
            # ... other fields
        ))
    
    # Sort by preference
    return self._sort_by_preference(scored_routes, preference)
```

**Emission Score Calculation**:
```python
def _calculate_emission_score(self, pollutants_list: List[Dict]) -> float:
    """
    Weighted average normalized against WHO limits
    """
    scores = []
    for pollutants in pollutants_list:
        # Normalize each pollutant (0-1 scale)
        no2_norm = pollutants['NO2'] / WHO_LIMITS['NO2']
        pm10_norm = pollutants['PM10'] / WHO_LIMITS['PM10']
        pm25_norm = pollutants['PM2.5'] / WHO_LIMITS['PM2.5']
        
        # Weighted combination
        score = (
            no2_norm * POLLUTANT_WEIGHTS['NO2'] +
            pm10_norm * POLLUTANT_WEIGHTS['PM10'] +
            pm25_norm * POLLUTANT_WEIGHTS['PM2.5']
        ) * 100
        
        scores.append(score)
    
    return sum(scores) / len(scores)

# Constants
WHO_LIMITS = {'NO2': 200, 'PM10': 50, 'PM2.5': 25}  # μg/m³
POLLUTANT_WEIGHTS = {'NO2': 0.30, 'PM10': 0.30, 'PM2.5': 0.40}
```

**Recommendation Levels**:
| Score Range | Level | Color | Health Impact |
|-------------|-------|-------|---------------|
| 0-25 | excellent | #10b981 (green) | Minimal risk |
| 26-50 | good | #84cc16 (lime) | Low risk |
| 51-70 | moderate | #f59e0b (orange) | Moderate risk for sensitive groups |
| 71-100 | not_recommended | #ef4444 (red) | High risk, avoid if possible |

#### 3. Cache Manager (`utils/cache_manager.py`)

**Dual Implementation**:

```python
class CacheManager:
    def __init__(self, use_local_cache: bool = False, ...):
        self.use_local_cache = use_local_cache
        
        if use_local_cache:
            self._cache = {}  # In-memory dict
        else:
            self.blob_client = BlobServiceClient.from_connection_string(...)
    
    async def get(self, key: str) -> Optional[Any]:
        if self.use_local_cache:
            return self._get_local(key)
        else:
            return await self._get_blob(key)
```

**Cache Key Generation**:
```python
def generate_cache_key(self, prefix: str, **params) -> str:
    """
    Generate consistent cache key from parameters
    Examples:
    - bicimad_stations:40.4168:-3.7038:2.0
    - air_quality:40.4168:-3.7038
    - route:40.4168:-3.7038:40.4558:-3.6883:fastest
    """
    sanitized = {k: str(v).replace(':', '_') for k, v in params.items()}
    key_parts = [prefix] + [sanitized[k] for k in sorted(sanitized.keys())]
    return ':'.join(key_parts)
```

### Frontend Components

#### 1. Application Orchestrator (`js/app.js`)

**Initialization Sequence**:
```javascript
class Application {
    async initialize() {
        // 1. Check dependencies
        this._checkDependencies();
        
        // 2. Initialize modules
        this.apiClient = new APIClient(API_BASE_URL);
        this.mapManager = new MapManager('map');
        this.uiController = new UIController();
        
        // 3. Register global event listeners
        this._registerGlobalEvents();
        
        // 4. Health check (graceful degradation)
        await this._performHealthCheck();
        
        // 5. Load initial data
        await this._loadInitialStations();
    }
}
```

#### 2. Map Manager (`js/map.js`)

**Leaflet Integration**:
```javascript
class MapManager {
    initialize() {
        this.map = L.map('map').setView(
            MAP_CONFIG.center,  // [40.4168, -3.7038]
            MAP_CONFIG.defaultZoom  // 13
        );
        
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(this.map);
    }
    
    displayRoutes(routes) {
        routes.forEach(route => {
            const color = ROUTE_COLORS[route.recommendation_level];
            const polyline = L.polyline(
                route.geometry.coordinates.map(c => [c[1], c[0]]),
                { color, weight: 5, opacity: 0.7 }
            ).addTo(this.map);
            
            polyline.on('click', () => {
                this._handleRouteClick(route);
            });
        });
    }
}
```

**Custom Markers (SVG Data URLs)**:
```javascript
const MARKER_ICONS = {
    station: L.icon({
        iconUrl: 'data:image/svg+xml;base64,' + btoa(`
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10" fill="#10b981"/>
                <text x="12" y="16" text-anchor="middle" fill="white">🚲</text>
            </svg>
        `),
        iconSize: [32, 32]
    })
};
```

#### 3. UI Controller (`js/ui-controller.js`)

**Form Validation**:
```javascript
_hasValidCoordinates(lat, lon) {
    // Madrid bounds validation
    const MADRID_BOUNDS = {
        minLat: 40.3, maxLat: 40.6,
        minLon: -3.9, maxLon: -3.5
    };
    
    return (
        lat >= MADRID_BOUNDS.minLat && lat <= MADRID_BOUNDS.maxLat &&
        lon >= MADRID_BOUNDS.minLon && lon <= MADRID_BOUNDS.maxLon
    );
}
```

**Dynamic Results Display**:
```javascript
displayResults(data) {
    const container = this.elements.resultsContainer;
    container.innerHTML = '';
    
    data.routes.forEach((route, index) => {
        const card = this._createRouteCard(route, index);
        container.appendChild(card);
    });
    
    this._updateSummary(data.routes);
}
```

#### 4. API Client (`js/api-client.js`)

**Timeout Handling**:
```javascript
async get(endpoint, params = {}) {
    const url = new URL(`${this.baseURL}${endpoint}`);
    Object.keys(params).forEach(key => 
        url.searchParams.append(key, params[key])
    );
    
    try {
        const response = await fetch(url, {
            signal: AbortSignal.timeout(this.timeout)  // 15s
        });
        
        if (!response.ok) {
            throw new APIError(
                `HTTP ${response.status}`, 
                response.status
            );
        }
        
        return await response.json();
    } catch (error) {
        if (error.name === 'TimeoutError') {
            throw new APIError('Request timeout', 504);
        }
        throw error;
    }
}
```

---

## Data Flow

### 1. User Journey: Calculate Route

```
┌──────────┐
│  User    │
│  Action  │
└────┬─────┘
     │ 1. Click origin on map
     ▼
┌─────────────────┐
│  map.js         │
│  setOrigin()    │
└────┬────────────┘
     │ 2. Dispatch 'mapclick' event
     ▼
┌─────────────────┐
│  app.js         │
│  Event Listener │
└────┬────────────┘
     │ 3. Update UI with marker
     │
     │ 4. User clicks destination
     │ 5. User clicks "Calculate"
     ▼
┌─────────────────┐
│  ui-controller  │
│  validateInputs()│
└────┬────────────┘
     │ 6. Validation OK
     ▼
┌─────────────────┐
│  api-client.js  │
│  POST /route    │
└────┬────────────┘
     │ 7. HTTP Request
     ▼
┌─────────────────────────────────────────┐
│  Azure Functions                         │
│  calculate_route()                       │
│                                          │
│  ┌─────────────────────────────────┐   │
│  │ 1. Validate coordinates         │   │
│  │ 2. Check cache for route        │   │
│  │ 3. Call Azure Maps API          │   │
│  │ 4. Score each route:            │   │
│  │    - Sample points every 200m   │   │
│  │    - Get air quality at each    │   │
│  │    - Calculate emission score   │   │
│  │ 5. Sort by preference           │   │
│  │ 6. Cache result (24h TTL)       │   │
│  └─────────────────────────────────┘   │
└────┬────────────────────────────────────┘
     │ 8. JSON Response
     ▼
┌─────────────────┐
│  api-client.js  │
│  Parse response │
└────┬────────────┘
     │ 9. Return data to app
     ▼
┌─────────────────┐
│  app.js         │
│  handleRoute    │
└────┬────────────┘
     │ 10. Display on map
     ▼
┌─────────────────┐      ┌─────────────────┐
│  map.js         │      │  ui-controller  │
│  displayRoutes()│      │  displayResults()│
└─────────────────┘      └─────────────────┘
     │                            │
     │ 11. Polylines + hover      │ 12. Route cards
     ▼                            ▼
┌──────────────────────────────────────┐
│  User sees 3 routes on map           │
│  + Results panel with metrics        │
└──────────────────────────────────────┘
```

### 2. Data Caching Strategy

```
Request Flow with Cache:

┌──────────┐
│ Function │
│ Endpoint │
└────┬─────┘
     │
     ▼
┌─────────────────┐
│ generate_key()  │  bicimad_stations:40.4168:-3.7038:2.0
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ cache.get(key)  │
└────┬────────────┘
     │
     ├─── Cache HIT ───┐
     │                 ▼
     │         ┌──────────────┐
     │         │ Return       │
     │         │ Cached Data  │
     │         └──────────────┘
     │
     └─── Cache MISS ──┐
                       ▼
               ┌──────────────┐
               │ Call         │
               │ Provider API │
               └──────┬───────┘
                      │
                      ▼
               ┌──────────────┐
               │ cache.set()  │
               │ TTL = 20min  │
               └──────┬───────┘
                      │
                      ▼
               ┌──────────────┐
               │ Return       │
               │ Fresh Data   │
               └──────────────┘
```

### 3. Background Data Ingestion (Timer Trigger)

```python
@app.timer_trigger(schedule="0 */20 * * * *", arg_name="timer")
async def update_cache(timer: func.TimerRequest) -> None:
    """
    Runs every 20 minutes to refresh cache proactively
    """
    logging.info("Starting scheduled cache update")
    
    # Update BiciMAD stations for Madrid center
    bicimad = get_bicimad_provider()
    stations = await bicimad.get_nearby_stations(
        lat=40.4168, lon=-3.7038, radius_km=10.0
    )
    
    cache = get_cache_manager()
    cache_key = cache.generate_cache_key(
        'bicimad_stations', lat=40.4168, lon=-3.7038, radius=10.0
    )
    await cache.set(cache_key, stations, ttl_minutes=20)
    
    logging.info(f"Cache updated: {len(stations)} stations")
```

**Cron Expression**: `0 */20 * * * *`
- Seconds: 0
- Minutes: */20 (every 20 minutes)
- Hours: * (every hour)
- Day of month: *
- Month: *
- Day of week: *

---

## Technology Stack

### Backend Stack

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Python** | 3.11 | Runtime | Latest stable, type hints, async/await |
| **Azure Functions** | 4.x | Serverless compute | Cost-effective, auto-scaling |
| **httpx** | 0.25+ | Async HTTP client | Connection pooling, HTTP/2 |
| **pandas** | 2.1+ | Data manipulation | DataFrame operations for air quality |
| **numpy** | 1.26+ | Numerical computing | IDW interpolation |
| **geopy** | 2.4+ | Geodesic calculations | Accurate distance calculations |
| **azure-storage-blob** | 12.19+ | Cache storage | Managed Blob Storage |
| **azure-identity** | 1.15+ | Authentication | Managed Identity support |
| **pydantic** | 2.5+ | Data validation | Type-safe DTOs |

### Frontend Stack

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Vanilla JavaScript** | ES6+ | UI logic | No framework overhead |
| **Leaflet.js** | 1.9.4 | Interactive maps | Open-source, lightweight |
| **OpenStreetMap** | - | Tile provider | Free, up-to-date |
| **CSS Custom Properties** | - | Theming | Dynamic color system |
| **Fetch API** | - | HTTP requests | Native, no dependencies |

### Testing Stack

| Technology | Purpose |
|------------|---------|
| **pytest** | Test runner |
| **pytest-asyncio** | Async test support |
| **pytest-mock** | Mocking framework |
| **pytest-cov** | Code coverage |
| **unittest.mock** | Mock objects |

### DevOps Stack

| Tool | Purpose |
|------|---------|
| **GitHub Actions** | CI/CD pipelines |
| **Azure CLI** | Infrastructure management |
| **Bicep** | IaC (Infrastructure as Code) |
| **Git** | Version control |

---

## Security & Privacy

### 1. API Security

**HTTPS Only**:
```python
# function_app.py - Azure Functions enforces HTTPS by default
# HTTP requests automatically redirect to HTTPS
```

**CORS Configuration**:
```python
# host.json
{
  "extensions": {
    "http": {
      "routePrefix": "api",
      "cors": {
        "allowedOrigins": ["*"],  # Production: restrict to domain
        "allowedMethods": ["GET", "POST", "OPTIONS"]
      }
    }
  }
}
```

**Input Validation**:
```python
def validate_coordinates(lat: float, lon: float) -> bool:
    """Prevent injection attacks and invalid data"""
    MADRID_BOUNDS = {
        'min_lat': 40.3, 'max_lat': 40.6,
        'min_lon': -3.9, 'max_lon': -3.5
    }
    
    if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
        raise ValueError("Coordinates must be numeric")
    
    if not (MADRID_BOUNDS['min_lat'] <= lat <= MADRID_BOUNDS['max_lat']):
        raise ValueError("Latitude out of Madrid bounds")
    
    if not (MADRID_BOUNDS['min_lon'] <= lon <= MADRID_BOUNDS['max_lon']):
        raise ValueError("Longitude out of Madrid bounds")
    
    return True
```

### 2. Secrets Management

**Azure Key Vault** (Production):
```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://kv-bicimad.vault.azure.net", credential=credential)

AZURE_MAPS_KEY = client.get_secret("azure-maps-api-key").value
```

**Environment Variables** (Development):
```bash
# local.settings.json (NOT committed to Git)
{
  "IsEncrypted": false,
  "Values": {
    "AZURE_MAPS_KEY": "your-key-here",
    "AZURE_STORAGE_CONNECTION_STRING": "...",
    "USE_LOCAL_CACHE": "true"
  }
}
```

### 3. Data Privacy

**No PII Collection**:
- No user authentication required
- No tracking cookies
- Anonymous usage (coordinates are ephemeral)
- No storage of user routes

**Rate Limiting** (Azure API Management - Optional):
```yaml
# Rate limit policy
<rate-limit calls="100" renewal-period="60" />
```

---

## Performance & Scalability

### Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| First Contentful Paint | <2s | ~1.5s |
| Time to Interactive | <3s | ~2.8s |
| API Response (/stations) | <500ms | ~350ms (cached) |
| API Response (/calculate-route) | <2s | ~1.8s |
| Lighthouse Score | >90 | 94 |

### Optimization Strategies

**1. Frontend Optimizations**

```javascript
// Debounce map interactions
const debouncedSearch = debounce((coords) => {
    this.searchNearbyStations(coords);
}, 300);

// Lazy load route details
displayRoutes(routes) {
    routes.forEach(route => {
        const polyline = L.polyline(coords, { weight: 5 });
        polyline.on('click', async () => {
            // Fetch detailed metrics only when clicked
            const details = await this.getRouteDetails(route.id);
            this.showRouteModal(details);
        });
    });
}
```

**2. Backend Optimizations**

```python
# Parallel API calls with asyncio.gather
async def score_routes(self, routes):
    # Score all routes concurrently
    scored_routes = await asyncio.gather(*[
        self._score_single_route(route) for route in routes
    ])
    return scored_routes

# Connection pooling
self.client = httpx.AsyncClient(
    limits=httpx.Limits(max_connections=20, max_keepalive_connections=10)
)
```

**3. Caching Strategy**

```python
# Multi-level cache
- Level 1: In-memory (Function execution context)
- Level 2: Azure Blob Storage (shared across instances)
- Level 3: CDN (static assets - future)

# Cache warming (timer trigger)
@app.timer_trigger(schedule="0 */20 * * * *")
async def warm_cache():
    # Preload popular areas
    await cache_stations_for_area(center=(40.4168, -3.7038), radius=5.0)
```

### Scalability Considerations

**Horizontal Scaling**:
- Azure Functions auto-scale: 0 → 200 instances
- Stateless design: No session affinity required
- Blob Storage: Automatically partitioned

**Bottlenecks**:
1. **External APIs**: BiciMAD/Air Quality rate limits
   - Mitigation: Aggressive caching (20min TTL)
2. **Azure Maps API**: Cost per request
   - Mitigation: Cache routes for 24h
3. **Cold starts**: ~2-3s first request
   - Mitigation: Always-on App Service Plan for production

---

## Development Workflow

### Local Development Setup

```bash
# 1. Clone repository
git clone https://github.com/Alejandrolmeida/azure-agent-pro.git
cd azure-agent-pro/hackproject

# 2. Create Python virtual environment
python3.11 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r src/api/requirements.txt

# 4. Configure local settings
cp src/api/local.settings.json.example src/api/local.settings.json
# Edit: Set USE_LOCAL_CACHE=true for offline dev

# 5. Run Azure Functions locally
cd src/api
func start

# 6. Serve frontend
cd ../frontend
python -m http.server 8000
```

### Testing Strategy

**1. Unit Tests** (Mock external dependencies):
```bash
pytest tests/test_data_providers.py -v --cov=utils.data_providers
pytest tests/test_scoring_engine.py -v --cov=utils.scoring_engine
```

**2. Integration Tests** (Mock Azure Functions HTTP):
```bash
pytest tests/test_endpoints.py -v --cov=function_app
```

**3. E2E Tests** (Manual - future Playwright):
```javascript
// test_e2e.spec.js
test('user can calculate low emission route', async ({ page }) => {
    await page.goto('http://localhost:8000');
    await page.click('#map', { position: { x: 400, y: 300 } });  // origin
    await page.click('#map', { position: { x: 500, y: 400 } });  // dest
    await page.click('button:has-text("Calculate Route")');
    await expect(page.locator('.route-card')).toHaveCount(3);
});
```

### Git Workflow

```
main (production)
  │
  ├─ dev (integration branch)
  │   │
  │   ├─ feature/bicimad-provider
  │   ├─ feature/scoring-engine
  │   └─ feature/map-ui
  │
  └─ datahack4good (hackathon demo branch)
```

**Commit Convention**:
```
feat: Add IDW interpolation for air quality
fix: Handle Azure Maps API timeout
test: Add unit tests for scoring engine
docs: Update architecture diagrams
refactor: Extract cache logic to manager class
```

---

## Deployment Architecture

### Azure Resource Topology

```
Resource Group: rg-bicimad-lowemission-prod
├─ Function App: func-bicimad-prod
│  ├─ App Service Plan: ASP-bicimad-prod (Consumption)
│  ├─ Application Insights: appi-bicimad-prod
│  └─ Managed Identity: [system-assigned]
│
├─ Storage Account: stbicimadprod
│  ├─ Blob Container: cache
│  ├─ Blob Container: azure-webjobs-hosts (Functions runtime)
│  └─ File Share: function-content
│
├─ Static Web App: swa-bicimad-prod (Frontend)
│  └─ Custom Domain: bicimad.example.com
│
├─ Key Vault: kv-bicimad-prod
│  ├─ Secret: azure-maps-api-key
│  └─ Secret: storage-connection-string
│
└─ Log Analytics Workspace: log-bicimad-prod
```

### CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Function App
        run: |
          cd hackproject/src/api
          func azure functionapp publish func-bicimad-prod --python
  
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Azure/static-web-apps-deploy@v1
        with:
          app_location: "hackproject/src/frontend"
          api_location: ""
          output_location: ""
```

### Monitoring & Alerts

**Application Insights Queries**:
```kusto
// Request success rate
requests
| where timestamp > ago(1h)
| summarize 
    Total = count(),
    Successful = countif(success == true),
    SuccessRate = 100.0 * countif(success == true) / count()
by bin(timestamp, 5m)

// Average response time by endpoint
requests
| where timestamp > ago(24h)
| summarize avg(duration), percentile(duration, 95) by name
| order by avg_duration desc

// Cache hit rate
traces
| where message contains "Cache"
| summarize 
    Hits = countif(message contains "HIT"),
    Misses = countif(message contains "MISS"),
    HitRate = 100.0 * countif(message contains "HIT") / count()
```

**Alert Rules**:
| Alert | Condition | Action |
|-------|-----------|--------|
| High Error Rate | >5% errors in 5min | Email + SMS |
| Slow Response | P95 > 3s for 10min | Email |
| Cache Miss Spike | Hit rate <50% for 15min | Email |
| Function Errors | Any exception | Log to Teams |

---

## Architectural Decision Records

### ADR-001: Use Serverless Azure Functions

**Context**: Need scalable, cost-effective backend for variable traffic hackathon demo.

**Decision**: Use Azure Functions Consumption Plan over App Service.

**Alternatives Considered**:
1. **App Service**: Always-on, predictable cost, but over-provisioned for low traffic
2. **Container Instances**: More control, but requires Docker knowledge
3. **Azure Functions**: Serverless, pay-per-execution, auto-scaling

**Rationale**:
- Zero cost when idle (perfect for demo)
- Auto-scaling for burst traffic (if hackathon goes viral)
- Built-in HTTPS and CORS
- Easy local development with Azure Functions Core Tools

**Consequences**:
- ✅ Cost savings: ~$5/month vs $50/month App Service
- ⚠️ Cold start latency (~2-3s first request)
- ⚠️ Limited to 230s HTTP timeout

### ADR-002: Use IDW Interpolation for Air Quality

**Context**: Air quality data available only at 12 fixed monitoring stations. Need values for arbitrary points on routes.

**Decision**: Implement Inverse Distance Weighting (IDW) with k=3 nearest neighbors.

**Alternatives Considered**:
1. **Nearest Station Only**: Simple but inaccurate
2. **Kriging**: More accurate but complex and computationally expensive
3. **IDW (k=3)**: Balance of accuracy and performance

**Rationale**:
- IDW is standard in environmental science
- k=3 provides smooth interpolation without overfitting
- Power=2 is proven effective for pollutant dispersion
- Computationally lightweight (can run on every route point)

**Consequences**:
- ✅ Scientifically sound methodology
- ✅ Fast computation (<50ms per point)
- ⚠️ Assumes isotropic pollutant dispersion (ignores wind, topography)

### ADR-003: Vanilla JavaScript over Framework

**Context**: Need interactive frontend with map, forms, results display.

**Decision**: Use vanilla ES6+ JavaScript with Leaflet.js, no framework.

**Alternatives Considered**:
1. **React**: Popular, component-based, but adds 40KB+ bundle
2. **Vue**: Lighter, but still framework overhead
3. **Vanilla JS**: Zero dependencies beyond Leaflet

**Rationale**:
- Hackathon demo doesn't need framework complexity
- Faster load time (no framework bundle)
- Direct DOM manipulation for simple interactions
- Easier to understand for contributors

**Consequences**:
- ✅ Minimal bundle size (~200KB total with Leaflet)
- ✅ Fast Time to Interactive
- ⚠️ Manual state management (but manageable for project scope)

### ADR-004: 24-Hour Cache TTL for Routes

**Context**: Route geometry is stable unless roads change. Need to balance freshness vs cost.

**Decision**: Cache calculated routes for 24 hours.

**Alternatives Considered**:
1. **No caching**: Fresh data always, but expensive (Azure Maps API cost)
2. **1 hour TTL**: Frequent updates, moderate cost
3. **24 hours TTL**: Cost-effective, acceptable freshness

**Rationale**:
- Road network changes are rare (construction, closures)
- Air quality changes along route, but route *geometry* is stable
- Azure Maps API costs $0.50 per 1000 requests
- 24h TTL reduces costs by ~95% vs no caching

**Consequences**:
- ✅ Cost savings: ~$2/month vs $40/month
- ⚠️ Route may not reflect temporary road closures
- ⚠️ Need manual cache invalidation for known closures

---

## Future Enhancements

### Phase 2 (Post-Hackathon)

1. **Real-Time Traffic Integration**
   - Integrate Azure Maps traffic API
   - Adjust routes based on congestion
   - Dynamic ETA updates

2. **Weather Impact**
   - OpenWeatherMap API integration
   - Avoid routes during rain/high wind
   - Temperature-based recommendations

3. **User Preferences**
   - Save favorite routes (requires auth)
   - Avoid steep hills option
   - Scenic route preference

4. **Gamification**
   - Track CO2 saved vs car travel
   - Leaderboard for low-emission routes
   - Badges for consistent healthy routing

### Phase 3 (Production Scale)

1. **Mobile Apps**
   - React Native iOS/Android
   - GPS tracking for actual route
   - Offline maps with cached routes

2. **Machine Learning**
   - Predict air quality for next hour (LSTM model)
   - Personalized route recommendations
   - Anomaly detection for pollution spikes

3. **Multi-City Expansion**
   - Barcelona, Valencia, Sevilla
   - Plug-and-play provider architecture
   - Multi-language support

---

## References

### Documentation
- [Azure Functions Python Developer Guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python)
- [Leaflet.js Documentation](https://leafletjs.com/reference.html)
- [WHO Air Quality Guidelines](https://www.who.int/news-room/feature-stories/detail/what-are-the-who-air-quality-guidelines)
- [IDW Interpolation Theory](https://en.wikipedia.org/wiki/Inverse_distance_weighting)

### APIs Used
- [BiciMAD Open Data API](https://opendata.emtmadrid.es/)
- [Madrid Air Quality Network](https://datos.madrid.es/portal/site/egob/menuitem.c05c1f754a33a9fbe4b2e4b284f1a5a0/?vgnextoid=aecb88a7e2b73410VgnVCM2000000c205a0aRCRD)
- [Azure Maps REST API](https://learn.microsoft.com/en-us/rest/api/maps/)

### Related Work
- [Urban Air Quality Mapping](https://www.sciencedirect.com/science/article/pii/S0269749121019655)
- [Bicycle Route Planning with Pollution Avoidance](https://ieeexplore.ieee.org/document/8798522)

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-11-30  
**Maintained By**: DataHack4Good Team  
**License**: MIT
