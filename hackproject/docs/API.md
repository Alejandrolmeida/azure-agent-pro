# BiciMAD Low Emission Router - API Documentation

**Version**: 1.0.0  
**Base URL**: `https://func-bicimad-prod.azurewebsites.net/api`  
**Local Dev**: `http://localhost:7071/api`  
**Last Updated**: 2025-11-30

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Endpoints](#endpoints)
   - [GET /health](#get-health)
   - [GET /stations](#get-stations)
   - [GET /air-quality](#get-air-quality)
   - [POST /calculate-route](#post-calculate-route)
4. [Data Models](#data-models)
5. [Error Handling](#error-handling)
6. [Rate Limits](#rate-limits)
7. [Examples](#examples)
8. [SDKs & Libraries](#sdks--libraries)

---

## Overview

The BiciMAD Low Emission Router API provides endpoints to:
- Check service health
- Find nearby BiciMAD bicycle stations
- Get interpolated air quality data at any point in Madrid
- Calculate bicycle routes optimized for low pollution exposure

### Key Features

- ✅ **RESTful Design**: Standard HTTP methods (GET, POST)
- ✅ **JSON Responses**: All responses in JSON format
- ✅ **CORS Enabled**: Cross-origin requests allowed
- ✅ **HTTPS Only**: Secure connections enforced
- ✅ **Caching**: Automatic caching for improved performance
- ✅ **Madrid-Specific**: Validated for Madrid city bounds

### Coordinates System

All coordinates use **WGS84** (EPSG:4326) decimal degrees:
- **Latitude**: Range [40.3, 40.6] (Madrid bounds)
- **Longitude**: Range [-3.9, -3.5] (Madrid bounds)

---

## Authentication

**Current**: No authentication required (public demo).

**Future** (Production):
```http
Authorization: Bearer YOUR_API_KEY
```

Rate limiting will apply based on API key.

---

## Endpoints

### GET /health

Check API service health and get system information.

#### Request

```http
GET /api/health HTTP/1.1
Host: func-bicimad-prod.azurewebsites.net
```

#### Response

```json
{
  "status": "healthy",
  "timestamp": "2025-11-30T12:00:00Z",
  "environment": "production",
  "cache": {
    "type": "azure_blob",
    "available": true
  },
  "version": "1.0.0"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Service health status: `healthy`, `degraded`, `unhealthy` |
| `timestamp` | string (ISO 8601) | Current server time |
| `environment` | string | Deployment environment: `local`, `dev`, `production` |
| `cache.type` | string | Cache implementation: `local` or `azure_blob` |
| `cache.available` | boolean | Whether cache is operational |
| `version` | string | API version |

#### Status Codes

| Code | Meaning |
|------|---------|
| 200 | Service healthy and operational |
| 503 | Service degraded or unavailable |

---

### GET /stations

Get BiciMAD bicycle stations near a specific location.

#### Request

```http
GET /api/stations?lat=40.4168&lon=-3.7038&radius=2.0&max_results=10 HTTP/1.1
Host: func-bicimad-prod.azurewebsites.net
```

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `lat` | float | ✅ Yes | - | Latitude in decimal degrees [40.3, 40.6] |
| `lon` | float | ✅ Yes | - | Longitude in decimal degrees [-3.9, -3.5] |
| `radius` | float | ❌ No | 2.0 | Search radius in kilometers (max 10.0) |
| `max_results` | int | ❌ No | 20 | Maximum stations to return (max 50) |

#### Response

```json
{
  "location": {
    "lat": 40.4168,
    "lon": -3.7038
  },
  "radius_km": 2.0,
  "stations": [
    {
      "id": "1",
      "name": "Puerta del Sol",
      "address": "Plaza de la Puerta del Sol",
      "latitude": 40.4168,
      "longitude": -3.7038,
      "distance_km": 0.05,
      "total_bases": 30,
      "free_bases": 12,
      "dock_bikes": 18,
      "active": true
    },
    {
      "id": "2",
      "name": "Plaza Mayor",
      "latitude": 40.4154,
      "longitude": -3.7074,
      "distance_km": 0.32,
      "total_bases": 25,
      "free_bases": 10,
      "dock_bikes": 15,
      "active": true
    }
  ],
  "total_found": 8,
  "cached": true,
  "cache_expires_at": "2025-11-30T12:20:00Z"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `location` | object | Queried location coordinates |
| `radius_km` | float | Search radius used |
| `stations` | array | List of nearby stations (sorted by distance) |
| `stations[].id` | string | Unique station identifier |
| `stations[].name` | string | Station display name |
| `stations[].address` | string | Street address (may be null) |
| `stations[].latitude` | float | Station latitude |
| `stations[].longitude` | float | Station longitude |
| `stations[].distance_km` | float | Distance from query point |
| `stations[].total_bases` | int | Total docking points |
| `stations[].free_bases` | int | Available empty docks |
| `stations[].dock_bikes` | int | Available bicycles |
| `stations[].active` | boolean | Whether station is operational |
| `total_found` | int | Total stations within radius |
| `cached` | boolean | Whether data served from cache |
| `cache_expires_at` | string (ISO 8601) | Cache expiration timestamp |

#### Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success - stations returned |
| 400 | Bad Request - invalid parameters |
| 404 | Not Found - no stations in radius |
| 500 | Internal Server Error |

#### Example Error Response

```json
{
  "error": "Coordinates out of Madrid bounds",
  "details": "Latitude must be between 40.3 and 40.6",
  "status": 400
}
```

---

### GET /air-quality

Get interpolated air quality data at a specific location using IDW (Inverse Distance Weighting) from the 3 nearest monitoring stations.

#### Request

```http
GET /api/air-quality?lat=40.4168&lon=-3.7038 HTTP/1.1
Host: func-bicimad-prod.azurewebsites.net
```

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `lat` | float | ✅ Yes | Latitude in decimal degrees [40.3, 40.6] |
| `lon` | float | ✅ Yes | Longitude in decimal degrees [-3.9, -3.5] |

#### Response

```json
{
  "location": {
    "lat": 40.4168,
    "lon": -3.7038
  },
  "timestamp": "2025-11-30T12:00:00Z",
  "pollutants": {
    "NO2": 35.5,
    "PM10": 22.0,
    "PM2.5": 12.0
  },
  "score": 28.5,
  "level": "good",
  "level_description": "Air quality is satisfactory, and air pollution poses little or no risk.",
  "color": "#10b981",
  "sources": [
    {
      "station_id": "28079004",
      "station_name": "Plaza de España",
      "distance_km": 0.8,
      "weight": 0.45
    },
    {
      "station_id": "28079008",
      "station_name": "Escuelas Aguirre",
      "distance_km": 1.2,
      "weight": 0.32
    },
    {
      "station_id": "28079035",
      "station_name": "Plaza del Carmen",
      "distance_km": 1.5,
      "weight": 0.23
    }
  ],
  "who_limits": {
    "NO2": 200,
    "PM10": 50,
    "PM2.5": 25
  },
  "cached": true
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `location` | object | Queried location coordinates |
| `timestamp` | string (ISO 8601) | Measurement timestamp |
| `pollutants` | object | Pollutant concentrations in μg/m³ |
| `pollutants.NO2` | float | Nitrogen Dioxide (μg/m³) |
| `pollutants.PM10` | float | Particulate Matter <10μm (μg/m³) |
| `pollutants.PM2.5` | float | Particulate Matter <2.5μm (μg/m³) |
| `score` | float | Air Quality Index (0-100, lower is better) |
| `level` | string | Quality level: `good`, `moderate`, `unhealthy_sensitive`, `unhealthy` |
| `level_description` | string | Human-readable health implications |
| `color` | string (hex) | Color code for visualization |
| `sources` | array | Monitoring stations used for interpolation |
| `sources[].station_id` | string | Official station ID |
| `sources[].station_name` | string | Station name |
| `sources[].distance_km` | float | Distance from query point |
| `sources[].weight` | float | IDW weight (0-1, sum=1) |
| `who_limits` | object | WHO guideline limits for pollutants |
| `cached` | boolean | Whether data served from cache |

#### Air Quality Levels

| Level | Score Range | Color | Description |
|-------|-------------|-------|-------------|
| `good` | 0-50 | 🟢 #10b981 | Air quality is satisfactory |
| `moderate` | 51-100 | 🟡 #84cc16 | Acceptable for most people |
| `unhealthy_sensitive` | 101-150 | 🟠 #f59e0b | Sensitive groups may experience effects |
| `unhealthy` | 151-200 | 🔴 #ef4444 | Everyone may experience health effects |

#### Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success - air quality data returned |
| 400 | Bad Request - invalid coordinates |
| 500 | Internal Server Error |
| 503 | Service Unavailable - data source offline |

---

### POST /calculate-route

Calculate bicycle routes between two points with emission scoring. Returns 3 route alternatives (fastest, shortest, eco) sorted by user preference.

#### Request

```http
POST /api/calculate-route HTTP/1.1
Host: func-bicimad-prod.azurewebsites.net
Content-Type: application/json

{
  "origin": {
    "lat": 40.4168,
    "lon": -3.7038
  },
  "destination": {
    "lat": 40.4558,
    "lon": -3.6883
  },
  "preference": "balanced"
}
```

#### Request Body

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `origin` | object | ✅ Yes | - | Starting point coordinates |
| `origin.lat` | float | ✅ Yes | - | Origin latitude [40.3, 40.6] |
| `origin.lon` | float | ✅ Yes | - | Origin longitude [-3.9, -3.5] |
| `destination` | object | ✅ Yes | - | Ending point coordinates |
| `destination.lat` | float | ✅ Yes | - | Destination latitude [40.3, 40.6] |
| `destination.lon` | float | ✅ Yes | - | Destination longitude [-3.9, -3.5] |
| `preference` | string | ❌ No | `balanced` | Sorting preference (see below) |

#### Preference Options

| Value | Description | Prioritizes |
|-------|-------------|-------------|
| `air_quality` | Lowest pollution exposure | emission_score (ascending) |
| `distance` | Shortest physical distance | distance_meters (ascending) |
| `time` | Fastest travel time | duration_seconds (ascending) |
| `balanced` | Balance of all factors | Composite score |

#### Response

```json
{
  "origin": {
    "lat": 40.4168,
    "lon": -3.7038
  },
  "destination": {
    "lat": 40.4558,
    "lon": -3.6883
  },
  "preference": "balanced",
  "routes": [
    {
      "route_type": "eco",
      "distance_meters": 5200,
      "duration_seconds": 1560,
      "distance_km": 5.2,
      "duration_minutes": 26,
      "emission_score": 32.5,
      "pollutants": {
        "NO2": 30.2,
        "PM10": 20.1,
        "PM2.5": 11.5
      },
      "health_impact": "low",
      "recommendation_level": "excellent",
      "recommendation_description": "Excellent air quality route - highly recommended for health",
      "color": "#10b981",
      "geometry": {
        "type": "LineString",
        "coordinates": [
          [-3.7038, 40.4168],
          [-3.7050, 40.4180],
          [-3.7070, 40.4200],
          ...
          [-3.6883, 40.4558]
        ]
      },
      "comparative_analysis": {
        "vs_fastest": {
          "time_difference_seconds": 360,
          "distance_difference_meters": 200,
          "emission_difference": -12.5,
          "health_benefit": "20% less pollution exposure"
        }
      }
    },
    {
      "route_type": "fastest",
      "distance_meters": 5000,
      "duration_seconds": 1200,
      "emission_score": 45.0,
      "pollutants": {
        "NO2": 42.0,
        "PM10": 28.0,
        "PM2.5": 15.0
      },
      "health_impact": "moderate",
      "recommendation_level": "good",
      "color": "#84cc16",
      "geometry": { ... }
    },
    {
      "route_type": "shortest",
      "distance_meters": 4800,
      "duration_seconds": 1380,
      "emission_score": 38.0,
      "pollutants": {
        "NO2": 35.0,
        "PM10": 24.0,
        "PM2.5": 13.0
      },
      "health_impact": "low",
      "recommendation_level": "excellent",
      "color": "#10b981",
      "geometry": { ... }
    }
  ],
  "comparison": {
    "best_air_quality": {
      "route_type": "eco",
      "emission_score": 32.5
    },
    "best_distance": {
      "route_type": "shortest",
      "distance_meters": 4800
    },
    "best_time": {
      "route_type": "fastest",
      "duration_seconds": 1200
    },
    "overall_recommendation": "eco"
  },
  "metadata": {
    "calculated_at": "2025-11-30T12:00:00Z",
    "sample_points": 26,
    "air_quality_sources": 8,
    "cached": false
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `routes` | array | List of 3 alternative routes (sorted by preference) |
| `routes[].route_type` | string | Route optimization: `fastest`, `shortest`, `eco` |
| `routes[].distance_meters` | int | Total route distance in meters |
| `routes[].duration_seconds` | int | Estimated travel time in seconds (avg 15 km/h) |
| `routes[].distance_km` | float | Distance in kilometers |
| `routes[].duration_minutes` | int | Duration in minutes |
| `routes[].emission_score` | float | Pollution exposure score (0-100, lower is better) |
| `routes[].pollutants` | object | Average pollutant concentrations along route |
| `routes[].health_impact` | string | Impact level: `minimal`, `low`, `moderate`, `high`, `very_high` |
| `routes[].recommendation_level` | string | Recommendation: `excellent`, `good`, `moderate`, `not_recommended` |
| `routes[].recommendation_description` | string | Human-readable recommendation |
| `routes[].color` | string (hex) | Color for map visualization |
| `routes[].geometry` | object (GeoJSON) | Route polyline in GeoJSON LineString format |
| `routes[].geometry.coordinates` | array | [[lon, lat], ...] pairs (GeoJSON convention) |
| `routes[].comparative_analysis` | object | Comparison with other routes |
| `comparison` | object | Summary of best route for each criterion |
| `metadata` | object | Calculation metadata |
| `metadata.sample_points` | int | Number of points sampled on route for AQ measurement |
| `metadata.air_quality_sources` | int | Number of monitoring stations used |

#### Health Impact Levels

| Level | Emission Score | Description |
|-------|----------------|-------------|
| `minimal` | 0-20 | Virtually no health risk |
| `low` | 21-40 | Minor risk for sensitive individuals |
| `moderate` | 41-60 | Noticeable effects for sensitive groups |
| `high` | 61-80 | Health effects for general population |
| `very_high` | 81-100 | Significant health risk, avoid if possible |

#### Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success - routes calculated |
| 400 | Bad Request - invalid coordinates or JSON |
| 422 | Unprocessable Entity - coordinates out of bounds |
| 500 | Internal Server Error |
| 503 | Service Unavailable - Azure Maps API offline |
| 504 | Gateway Timeout - calculation took >30s |

#### Example Error Response

```json
{
  "error": "Invalid request body",
  "details": "Missing required field: destination",
  "status": 400,
  "timestamp": "2025-11-30T12:00:00Z"
}
```

---

## Data Models

### BiciMAD Station

```typescript
interface BiciMADStation {
  id: string;                    // Unique identifier
  name: string;                  // Display name
  address?: string;              // Street address (optional)
  latitude: float;               // WGS84 decimal degrees
  longitude: float;              // WGS84 decimal degrees
  distance_km?: float;           // Distance from query point (optional)
  total_bases: int;              // Total docking points
  free_bases: int;               // Available empty docks
  dock_bikes: int;               // Available bicycles
  active: boolean;               // Operational status
}
```

### Air Quality Reading

```typescript
interface AirQualityReading {
  location: {
    lat: float;
    lon: float;
  };
  timestamp: string;             // ISO 8601
  pollutants: {
    NO2: float;                  // μg/m³
    PM10: float;                 // μg/m³
    PM2.5: float;                // μg/m³
  };
  score: float;                  // 0-100
  level: 'good' | 'moderate' | 'unhealthy_sensitive' | 'unhealthy';
  level_description: string;
  color: string;                 // Hex color code
  sources: MonitoringStation[];
  who_limits: {
    NO2: 200;
    PM10: 50;
    PM2.5: 25;
  };
}
```

### Route Score

```typescript
interface RouteScore {
  route_type: 'fastest' | 'shortest' | 'eco';
  distance_meters: int;
  duration_seconds: int;
  distance_km: float;
  duration_minutes: int;
  emission_score: float;         // 0-100
  pollutants: {
    NO2: float;
    PM10: float;
    PM2.5: float;
  };
  health_impact: 'minimal' | 'low' | 'moderate' | 'high' | 'very_high';
  recommendation_level: 'excellent' | 'good' | 'moderate' | 'not_recommended';
  recommendation_description: string;
  color: string;
  geometry: GeoJSON.LineString;
  comparative_analysis: object;
}
```

### GeoJSON LineString

```typescript
interface LineString {
  type: 'LineString';
  coordinates: [lon: float, lat: float][];  // GeoJSON: [lon, lat] order
}
```

---

## Error Handling

### Error Response Format

All error responses follow this structure:

```json
{
  "error": "Brief error message",
  "details": "Detailed explanation of the error",
  "status": 400,
  "timestamp": "2025-11-30T12:00:00Z",
  "request_id": "abc123"
}
```

### Common Error Codes

| Status | Error Type | Description |
|--------|------------|-------------|
| 400 | Bad Request | Invalid parameters or malformed JSON |
| 404 | Not Found | Resource not found (e.g., no stations in radius) |
| 422 | Unprocessable Entity | Valid JSON but semantically incorrect (e.g., coords out of bounds) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |
| 503 | Service Unavailable | External API (BiciMAD, Air Quality, Azure Maps) unavailable |
| 504 | Gateway Timeout | Request took too long (>30s for /calculate-route) |

### Example Error Scenarios

**Invalid Coordinates**:
```json
{
  "error": "Coordinates out of Madrid bounds",
  "details": "Latitude 41.3874 is outside valid range [40.3, 40.6]",
  "status": 422
}
```

**Missing Required Field**:
```json
{
  "error": "Missing required parameter",
  "details": "Query parameter 'lat' is required",
  "status": 400
}
```

**External API Failure**:
```json
{
  "error": "Air quality data unavailable",
  "details": "Madrid Open Data API returned status 503. Using cached data.",
  "status": 503
}
```

---

## Rate Limits

### Current Limits (Public Demo)

| Endpoint | Limit | Window |
|----------|-------|--------|
| All endpoints | No limit | - |

### Future Limits (Production)

| Endpoint | Authenticated | Anonymous |
|----------|---------------|-----------|
| GET /health | 100/min | 10/min |
| GET /stations | 60/min | 10/min |
| GET /air-quality | 60/min | 10/min |
| POST /calculate-route | 20/min | 5/min |

**Rate Limit Headers** (Future):
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1701345600
```

---

## Examples

### cURL Examples

**Get nearby stations**:
```bash
curl "https://func-bicimad-prod.azurewebsites.net/api/stations?lat=40.4168&lon=-3.7038&radius=2.0"
```

**Get air quality**:
```bash
curl "https://func-bicimad-prod.azurewebsites.net/api/air-quality?lat=40.4168&lon=-3.7038"
```

**Calculate route**:
```bash
curl -X POST "https://func-bicimad-prod.azurewebsites.net/api/calculate-route" \
  -H "Content-Type: application/json" \
  -d '{
    "origin": {"lat": 40.4168, "lon": -3.7038},
    "destination": {"lat": 40.4558, "lon": -3.6883},
    "preference": "air_quality"
  }'
```

### JavaScript Examples

**Using Fetch API**:
```javascript
// Get stations
const getStations = async (lat, lon, radius = 2.0) => {
  const url = new URL('https://func-bicimad-prod.azurewebsites.net/api/stations');
  url.searchParams.append('lat', lat);
  url.searchParams.append('lon', lon);
  url.searchParams.append('radius', radius);
  
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  
  return await response.json();
};

// Calculate route
const calculateRoute = async (origin, destination, preference = 'balanced') => {
  const response = await fetch(
    'https://func-bicimad-prod.azurewebsites.net/api/calculate-route',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ origin, destination, preference })
    }
  );
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.details || error.error);
  }
  
  return await response.json();
};

// Usage
const stations = await getStations(40.4168, -3.7038);
console.log(`Found ${stations.total_found} stations`);

const routes = await calculateRoute(
  { lat: 40.4168, lon: -3.7038 },
  { lat: 40.4558, lon: -3.6883 },
  'air_quality'
);
console.log(`Best route: ${routes.routes[0].route_type} with score ${routes.routes[0].emission_score}`);
```

### Python Examples

**Using requests library**:
```python
import requests

BASE_URL = 'https://func-bicimad-prod.azurewebsites.net/api'

# Get stations
def get_stations(lat, lon, radius=2.0):
    response = requests.get(
        f'{BASE_URL}/stations',
        params={'lat': lat, 'lon': lon, 'radius': radius}
    )
    response.raise_for_status()
    return response.json()

# Get air quality
def get_air_quality(lat, lon):
    response = requests.get(
        f'{BASE_URL}/air-quality',
        params={'lat': lat, 'lon': lon}
    )
    response.raise_for_status()
    return response.json()

# Calculate route
def calculate_route(origin, destination, preference='balanced'):
    response = requests.post(
        f'{BASE_URL}/calculate-route',
        json={
            'origin': origin,
            'destination': destination,
            'preference': preference
        }
    )
    response.raise_for_status()
    return response.json()

# Usage
stations = get_stations(40.4168, -3.7038)
print(f"Found {stations['total_found']} stations")

aq = get_air_quality(40.4168, -3.7038)
print(f"Air quality level: {aq['level']} (score: {aq['score']})")

routes = calculate_route(
    origin={'lat': 40.4168, 'lon': -3.7038},
    destination={'lat': 40.4558, 'lon': -3.6883},
    preference='air_quality'
)
best_route = routes['routes'][0]
print(f"Best route: {best_route['route_type']}")
print(f"Emission score: {best_route['emission_score']}")
print(f"Health impact: {best_route['health_impact']}")
```

---

## SDKs & Libraries

### Official SDK (Future)

```bash
# Python
pip install bicimad-router-sdk

# JavaScript/TypeScript
npm install @bicimad/router-sdk
```

### Community Libraries

Currently no community libraries. API is simple enough to use with standard HTTP clients.

---

## Changelog

### v1.0.0 (2025-11-30)
- ✅ Initial release
- ✅ GET /health endpoint
- ✅ GET /stations endpoint with caching
- ✅ GET /air-quality endpoint with IDW interpolation
- ✅ POST /calculate-route endpoint with 3 route types
- ✅ Support for 4 user preferences (air_quality, distance, time, balanced)

### v1.1.0 (Planned)
- 🔄 Authentication with API keys
- 🔄 Rate limiting
- 🔄 Webhook support for real-time updates
- 🔄 Batch route calculation endpoint

---

## Support

**Issues**: [GitHub Issues](https://github.com/Alejandrolmeida/azure-agent-pro/issues)  
**Email**: datahack4good@madrid.com  
**Documentation**: [Full Docs](https://github.com/Alejandrolmeida/azure-agent-pro/tree/datahack4good/hackproject/docs)

---

## License

MIT License - See [LICENSE](../LICENSE) file for details.

---

**Last Updated**: 2025-11-30  
**API Version**: 1.0.0  
**Maintained By**: DataHack4Good Team
