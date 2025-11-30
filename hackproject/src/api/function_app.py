"""
============================================================================
Azure Functions App - BiciMAD Low Emission Router
============================================================================
Backend serverless para calcular rutas ciclistas optimizadas por calidad
del aire en Madrid.

Endpoints:
- GET  /api/health - Health check
- GET  /api/stations - Obtiene estaciones BiciMAD cercanas
- GET  /api/air-quality - Obtiene calidad del aire en ubicación
- POST /api/calculate-route - Calcula ruta óptima minimizando emisiones

Timer Trigger:
- Actualiza cache de estaciones BiciMAD cada 20 minutos
============================================================================
"""

import azure.functions as func
import logging
import json
import os
from typing import Dict, Any

# Importar módulos de utilidades
from utils import (
    BiciMADProvider,
    AirQualityProvider,
    AzureMapsProvider,
    ScoringEngine,
    CacheManager
)

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# ============================================================================
# Global Configuration
# ============================================================================

# Azure Maps API Key (desde Key Vault o environment variable)
AZURE_MAPS_KEY = os.getenv('AZURE_MAPS_KEY', '@Microsoft.KeyVault(SecretUri=...)')

# Azure Storage para cache
STORAGE_CONNECTION_STRING = os.getenv('AZURE_STORAGE_CONNECTION_STRING')

# Para entorno de desarrollo/testing sin Azure
USE_LOCAL_CACHE = os.getenv('USE_LOCAL_CACHE', 'true').lower() == 'true'

# Inicializar providers (lazy initialization)
_bicimad_provider = None
_air_quality_provider = None
_maps_provider = None
_scoring_engine = None
_cache_manager = None


def get_bicimad_provider() -> BiciMADProvider:
    """Lazy initialization de BiciMAD provider"""
    global _bicimad_provider
    if _bicimad_provider is None:
        _bicimad_provider = BiciMADProvider()
    return _bicimad_provider


def get_air_quality_provider() -> AirQualityProvider:
    """Lazy initialization de Air Quality provider"""
    global _air_quality_provider
    if _air_quality_provider is None:
        _air_quality_provider = AirQualityProvider()
    return _air_quality_provider


def get_maps_provider() -> AzureMapsProvider:
    """Lazy initialization de Azure Maps provider"""
    global _maps_provider
    if _maps_provider is None:
        _maps_provider = AzureMapsProvider(api_key=AZURE_MAPS_KEY)
    return _maps_provider


def get_scoring_engine() -> ScoringEngine:
    """Lazy initialization de Scoring Engine"""
    global _scoring_engine
    if _scoring_engine is None:
        air_quality = get_air_quality_provider()
        _scoring_engine = ScoringEngine(air_quality)
    return _scoring_engine


def get_cache_manager() -> CacheManager:
    """Lazy initialization de Cache Manager"""
    global _cache_manager
    if _cache_manager is None:
        if USE_LOCAL_CACHE:
            _cache_manager = CacheManager(use_local_cache=True)
        else:
            _cache_manager = CacheManager(
                connection_string=STORAGE_CONNECTION_STRING
            )
    return _cache_manager


# ============================================================================
# HTTP Endpoints
# ============================================================================

@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint.
    
    Returns:
        200: Service is healthy
    """
    logging.info('Health check requested')
    
    cache_stats = get_cache_manager().get_cache_stats()
    
    return func.HttpResponse(
        json.dumps({
            "status": "healthy",
            "service": "BiciMAD Low Emission Router API",
            "version": "1.0.0",
            "cache_type": cache_stats.get('type', 'unknown'),
            "environment": "local" if USE_LOCAL_CACHE else "production"
        }),
        mimetype="application/json",
        status_code=200
    )


@app.route(route="stations", methods=["GET"])
async def get_stations(req: func.HttpRequest) -> func.HttpResponse:
    """
    Obtiene estaciones BiciMAD cercanas a una ubicación.
    
    Query params:
        lat (float): Latitud
        lon (float): Longitud
        radius (float, optional): Radio de búsqueda en km (default: 2.0)
        max_results (int, optional): Máximo número de estaciones (default: 10)
    
    Returns:
        200: Lista de estaciones cercanas
        400: Parámetros inválidos
    """
    logging.info('Get nearby stations requested')
    
    try:
        # Parsear parámetros
        lat = float(req.params.get('lat'))
        lon = float(req.params.get('lon'))
        radius = float(req.params.get('radius', 2.0))
        max_results = int(req.params.get('max_results', 10))
        
        # Validar coordenadas (Madrid aproximadamente)
        if not (40.3 <= lat <= 40.6 and -3.9 <= lon <= -3.5):
            return func.HttpResponse(
                json.dumps({
                    "error": "Coordinates out of Madrid bounds",
                    "bounds": {
                        "lat": [40.3, 40.6],
                        "lon": [-3.9, -3.5]
                    }
                }),
                mimetype="application/json",
                status_code=400
            )
        
        # Buscar en cache primero
        cache = get_cache_manager()
        cache_key = cache.generate_cache_key(
            'stations', lat=lat, lon=lon, radius=radius
        )
        cached_stations = await cache.get(cache_key, 'bicimad_stations')
        
        if cached_stations:
            logging.info('Returning cached stations')
            return func.HttpResponse(
                json.dumps({
                    "stations": cached_stations,
                    "cached": True
                }),
                mimetype="application/json",
                status_code=200
            )
        
        # No hay cache, obtener de API
        provider = get_bicimad_provider()
        nearby_stations = await provider.get_nearby_stations(
            lat, lon, radius, max_results
        )
        
        # Convertir a dict
        stations_data = [
            {
                "id": s.id,
                "name": s.name,
                "latitude": s.latitude,
                "longitude": s.longitude,
                "total_bases": s.total_bases,
                "free_bases": s.free_bases,
                "dock_bikes": s.dock_bikes,
                "active": s.active,
                "distance_km": round(s.distance_to(lat, lon), 2)
            }
            for s in nearby_stations
        ]
        
        # Guardar en cache
        await cache.set(cache_key, stations_data, 'bicimad_stations')
        
        return func.HttpResponse(
            json.dumps({
                "stations": stations_data,
                "cached": False,
                "count": len(stations_data)
            }),
            mimetype="application/json",
            status_code=200
        )
        
    except ValueError as e:
        logging.error(f'Invalid parameters: {e}')
        return func.HttpResponse(
            json.dumps({
                "error": "Invalid parameters",
                "message": "lat and lon must be valid numbers"
            }),
            mimetype="application/json",
            status_code=400
        )
    except Exception as e:
        logging.error(f'Error fetching stations: {e}')
        return func.HttpResponse(
            json.dumps({
                "error": "Internal server error",
                "message": str(e)
            }),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="air-quality", methods=["GET"])
async def get_air_quality(req: func.HttpRequest) -> func.HttpResponse:
    """
    Obtiene calidad del aire en una ubicación.
    
    Query params:
        lat (float): Latitud
        lon (float): Longitud
    
    Returns:
        200: Datos de calidad del aire (NO₂, PM10, PM2.5)
        400: Parámetros inválidos
    """
    logging.info('Get air quality requested')
    
    try:
        # Parsear parámetros
        lat = float(req.params.get('lat'))
        lon = float(req.params.get('lon'))
        
        # Validar coordenadas
        if not (40.3 <= lat <= 40.6 and -3.9 <= lon <= -3.5):
            return func.HttpResponse(
                json.dumps({
                    "error": "Coordinates out of Madrid bounds"
                }),
                mimetype="application/json",
                status_code=400
            )
        
        # Buscar en cache
        cache = get_cache_manager()
        cache_key = cache.generate_cache_key('air_quality', lat=lat, lon=lon)
        cached_data = await cache.get(cache_key, 'air_quality')
        
        if cached_data:
            logging.info('Returning cached air quality data')
            return func.HttpResponse(
                json.dumps({
                    **cached_data,
                    "cached": True
                }),
                mimetype="application/json",
                status_code=200
            )
        
        # No hay cache, obtener datos
        provider = get_air_quality_provider()
        air_data = await provider.get_air_quality(lat, lon)
        
        # Guardar en cache
        await cache.set(cache_key, air_data, 'air_quality')
        
        return func.HttpResponse(
            json.dumps({
                **air_data,
                "cached": False
            }),
            mimetype="application/json",
            status_code=200
        )
        
    except ValueError:
        return func.HttpResponse(
            json.dumps({
                "error": "Invalid parameters",
                "message": "lat and lon must be valid numbers"
            }),
            mimetype="application/json",
            status_code=400
        )
    except Exception as e:
        logging.error(f'Error fetching air quality: {e}')
        return func.HttpResponse(
            json.dumps({
                "error": "Internal server error",
                "message": str(e)
            }),
            mimetype="application/json",
            status_code=500
        )


@app.route(route="calculate-route", methods=["POST"])
async def calculate_route(req: func.HttpRequest) -> func.HttpResponse:
    """
    Calcula ruta óptima minimizando emisiones.
    
    Request body:
        {
            "origin": {"lat": 40.4168, "lon": -3.7038},
            "destination": {"lat": 40.4558, "lon": -3.6883},
            "preference": "air_quality" | "distance" | "time" | "balanced"
        }
    
    Returns:
        200: Rutas calculadas con scores de emisiones
        400: Request inválido
        500: Error en cálculo
    """
    logging.info('Calculate route requested')
    
    try:
        # Parse request body
        req_body = req.get_json()
        
        # Validar estructura
        if not all(k in req_body for k in ['origin', 'destination']):
            return func.HttpResponse(
                json.dumps({
                    "error": "Missing required fields",
                    "required": ["origin", "destination"]
                }),
                mimetype="application/json",
                status_code=400
            )
        
        origin = req_body['origin']
        destination = req_body['destination']
        preference = req_body.get('preference', 'balanced')
        
        # Validar coordenadas
        if not all(k in origin for k in ['lat', 'lon']):
            return func.HttpResponse(
                json.dumps({"error": "Invalid origin coordinates"}),
                mimetype="application/json",
                status_code=400
            )
        
        if not all(k in destination for k in ['lat', 'lon']):
            return func.HttpResponse(
                json.dumps({"error": "Invalid destination coordinates"}),
                mimetype="application/json",
                status_code=400
            )
        
        # Validar preferencia
        valid_preferences = ['air_quality', 'distance', 'time', 'balanced']
        if preference not in valid_preferences:
            return func.HttpResponse(
                json.dumps({
                    "error": "Invalid preference",
                    "valid_values": valid_preferences
                }),
                mimetype="application/json",
                status_code=400
            )
        
        # Buscar en cache
        cache = get_cache_manager()
        cache_key = cache.generate_cache_key(
            'route',
            origin['lat'], origin['lon'],
            destination['lat'], destination['lon'],
            preference=preference
        )
        cached_result = await cache.get(cache_key, 'routes')
        
        if cached_result:
            logging.info('Returning cached route')
            return func.HttpResponse(
                json.dumps({
                    **cached_result,
                    "cached": True
                }),
                mimetype="application/json",
                status_code=200
            )
        
        # Calcular rutas
        maps_provider = get_maps_provider()
        routes = await maps_provider.calculate_routes(
            origin, destination,
            route_types=['fastest', 'shortest', 'eco']
        )
        
        if not routes:
            return func.HttpResponse(
                json.dumps({
                    "error": "No routes found",
                    "message": "Could not calculate any route between origin and destination"
                }),
                mimetype="application/json",
                status_code=404
            )
        
        # Calcular scores de emisiones
        scoring_engine = get_scoring_engine()
        scored_routes = await scoring_engine.score_routes(routes, preference)
        
        # Generar comparativa
        comparison = scoring_engine.compare_routes(scored_routes)
        
        # Preparar respuesta
        result = {
            "origin": origin,
            "destination": destination,
            "preference": preference,
            "recommended_route": comparison['recommended_route'],
            "routes": [
                {
                    "type": route.route_type,
                    "distance_km": round(route.distance_meters / 1000, 2),
                    "duration_min": round(route.duration_seconds / 60, 1),
                    "emission_score": route.emission_score,
                    "recommendation": route.recommendation,
                    "health_impact": route.health_impact,
                    "pollutants": {
                        "NO2": route.avg_no2,
                        "PM10": route.avg_pm10,
                        "PM2.5": route.avg_pm25
                    },
                    "exposure_index": route.exposure_index,
                    "geometry": next(
                        (r['geometry'] for r in routes if r['type'] == route.route_type),
                        None
                    )
                }
                for route in scored_routes
            ],
            "summary": comparison['summary']
        }
        
        # Guardar en cache
        await cache.set(cache_key, result, 'routes')
        
        return func.HttpResponse(
            json.dumps({
                **result,
                "cached": False
            }),
            mimetype="application/json",
            status_code=200
        )
        
    except ValueError as e:
        logging.error(f'Invalid request: {e}')
        return func.HttpResponse(
            json.dumps({
                "error": "Invalid JSON in request body",
                "message": str(e)
            }),
            mimetype="application/json",
            status_code=400
        )
    except Exception as e:
        logging.error(f'Error calculating route: {e}', exc_info=True)
        return func.HttpResponse(
            json.dumps({
                "error": "Internal server error",
                "message": str(e)
            }),
            mimetype="application/json",
            status_code=500
        )


# ============================================================================
# Timer Trigger - Data Ingestion
# ============================================================================

@app.timer_trigger(schedule="0 */20 * * * *", arg_name="myTimer", run_on_startup=False)
async def ingest_data(myTimer: func.TimerRequest) -> None:
    """
    Timer trigger que se ejecuta cada 20 minutos para actualizar cache.
    
    Actualiza:
    - Estaciones BiciMAD (disponibilidad)
    - Calidad del aire (últimas lecturas)
    
    Schedule: "0 */20 * * * *" = Cada 20 minutos
    """
    logging.info('Data ingestion timer trigger started')
    
    if myTimer.past_due:
        logging.warning('The timer is past due!')
    
    try:
        # Obtener providers
        bicimad = get_bicimad_provider()
        cache = get_cache_manager()
        
        # Actualizar estaciones BiciMAD
        logging.info('Fetching BiciMAD stations...')
        stations = await bicimad.get_stations()
        
        # Guardar en cache global
        stations_data = [
            {
                "id": s.id,
                "name": s.name,
                "latitude": s.latitude,
                "longitude": s.longitude,
                "total_bases": s.total_bases,
                "free_bases": s.free_bases,
                "dock_bikes": s.dock_bikes,
                "active": s.active
            }
            for s in stations
        ]
        
        cache_key = cache.generate_cache_key('all_stations')
        await cache.set(cache_key, stations_data, 'bicimad_stations')
        
        logging.info(f'Updated cache with {len(stations)} BiciMAD stations')
        
        # Obtener estadísticas
        cache_stats = cache.get_cache_stats()
        logging.info(f'Cache stats: {cache_stats}')
        
        logging.info('Data ingestion completed successfully')
        
    except Exception as e:
        logging.error(f'Error during data ingestion: {e}', exc_info=True)
