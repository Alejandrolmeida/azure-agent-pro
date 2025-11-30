"""
============================================================================
Azure Functions App - BiciMAD Low Emission Router
============================================================================
Backend APIs para calcular rutas inteligentes en bicicleta minimizando
exposición a contaminación atmosférica

Endpoints:
- GET  /api/health          - Health check
- GET  /api/stations        - Disponibilidad de estaciones BiciMAD
- GET  /api/air-quality     - Calidad del aire por coordenadas
- POST /api/calculate-route - Calcular rutas con scoring de emisiones

Autor: DataSaturday Madrid 2025 Team
============================================================================
"""

import azure.functions as func
import logging
import os
import sys

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Inicializar Function App
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# ============================================================================
# HEALTH CHECK ENDPOINT
# ============================================================================

@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint para monitoring y availability tests.
    
    Returns:
        200: Sistema operativo
        503: Sistema degradado
    """
    logger.info("Health check requested")
    
    try:
        # Verificar variables de entorno críticas
        required_env_vars = [
            "AZURE_MAPS_API_KEY",
            "STORAGE_CONNECTION_STRING"
        ]
        
        missing_vars = [var for var in required_env_vars if not os.getenv(var)]
        
        if missing_vars:
            logger.warning(f"Missing environment variables: {missing_vars}")
            return func.HttpResponse(
                body='{"status": "degraded", "message": "Missing configuration"}',
                status_code=503,
                mimetype="application/json"
            )
        
        health_status = {
            "status": "healthy",
            "version": "1.0.0",
            "environment": os.getenv("ENVIRONMENT", "unknown"),
            "python_version": sys.version,
            "checks": {
                "configuration": "ok",
                "dependencies": "ok"
            }
        }
        
        return func.HttpResponse(
            body=str(health_status),
            status_code=200,
            mimetype="application/json"
        )
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return func.HttpResponse(
            body='{"status": "unhealthy", "error": "Internal error"}',
            status_code=503,
            mimetype="application/json"
        )


# ============================================================================
# STATIONS ENDPOINT
# ============================================================================

@app.route(route="stations", methods=["GET"])
async def get_stations(req: func.HttpRequest) -> func.HttpResponse:
    """
    Obtiene disponibilidad en tiempo real de estaciones BiciMAD.
    
    Query Parameters:
        - near_lat (float): Latitud para filtrar estaciones cercanas
        - near_lon (float): Longitud para filtrar estaciones cercanas
        - radius_km (float): Radio de búsqueda en kilómetros (default: 2.0)
    
    Returns:
        200: Lista de estaciones con disponibilidad
        400: Parámetros inválidos
        500: Error del servidor
    """
    logger.info("Stations endpoint called")
    
    try:
        # Obtener parámetros opcionales
        near_lat = req.params.get('near_lat')
        near_lon = req.params.get('near_lon')
        radius_km = float(req.params.get('radius_km', 2.0))
        
        # TODO: Implementar lógica de obtención de estaciones
        # Por ahora retornamos respuesta de ejemplo
        
        stations_data = {
            "success": True,
            "count": 0,
            "filters": {
                "near_lat": near_lat,
                "near_lon": near_lon,
                "radius_km": radius_km
            },
            "stations": [],
            "cached": False,
            "timestamp": "2025-11-30T12:00:00Z"
        }
        
        return func.HttpResponse(
            body=str(stations_data),
            status_code=200,
            mimetype="application/json"
        )
        
    except ValueError as e:
        logger.error(f"Invalid parameters: {str(e)}")
        return func.HttpResponse(
            body='{"error": "Invalid parameters"}',
            status_code=400,
            mimetype="application/json"
        )
    except Exception as e:
        logger.error(f"Error in get_stations: {str(e)}")
        return func.HttpResponse(
            body='{"error": "Internal server error"}',
            status_code=500,
            mimetype="application/json"
        )


# ============================================================================
# AIR QUALITY ENDPOINT
# ============================================================================

@app.route(route="air-quality", methods=["GET"])
async def get_air_quality(req: func.HttpRequest) -> func.HttpResponse:
    """
    Obtiene datos de calidad del aire para coordenadas específicas.
    
    Query Parameters:
        - lat (float, required): Latitud
        - lon (float, required): Longitud
        - pollutants (str): Contaminantes a consultar (NO2,PM10,PM25) default: all
    
    Returns:
        200: Datos de calidad del aire
        400: Parámetros faltantes o inválidos
        500: Error del servidor
    """
    logger.info("Air quality endpoint called")
    
    try:
        # Parámetros requeridos
        lat = req.params.get('lat')
        lon = req.params.get('lon')
        
        if not lat or not lon:
            return func.HttpResponse(
                body='{"error": "Missing required parameters: lat, lon"}',
                status_code=400,
                mimetype="application/json"
            )
        
        lat = float(lat)
        lon = float(lon)
        pollutants = req.params.get('pollutants', 'NO2,PM10,PM25').split(',')
        
        # TODO: Implementar lógica de consulta de calidad del aire
        
        air_quality_data = {
            "success": True,
            "location": {
                "lat": lat,
                "lon": lon
            },
            "pollutants": {},
            "overall_score": 0,
            "level": "unknown",
            "timestamp": "2025-11-30T12:00:00Z"
        }
        
        return func.HttpResponse(
            body=str(air_quality_data),
            status_code=200,
            mimetype="application/json"
        )
        
    except ValueError as e:
        logger.error(f"Invalid parameters: {str(e)}")
        return func.HttpResponse(
            body='{"error": "Invalid parameters"}',
            status_code=400,
            mimetype="application/json"
        )
    except Exception as e:
        logger.error(f"Error in get_air_quality: {str(e)}")
        return func.HttpResponse(
            body='{"error": "Internal server error"}',
            status_code=500,
            mimetype="application/json"
        )


# ============================================================================
# CALCULATE ROUTE ENDPOINT
# ============================================================================

@app.route(route="calculate-route", methods=["POST"])
async def calculate_route(req: func.HttpRequest) -> func.HttpResponse:
    """
    Calcula rutas inteligentes minimizando exposición a contaminación.
    
    Request Body (JSON):
        {
            "origin": {"lat": 40.416, "lon": -3.703},
            "destination": {"lat": 40.420, "lon": -3.688},
            "preferences": {
                "prioritize": "air_quality",  // "air_quality" | "distance" | "time"
                "avoid_high_pollution": true,
                "max_routes": 3
            }
        }
    
    Returns:
        200: Lista de rutas calculadas con scoring
        400: Parámetros inválidos
        500: Error del servidor
    """
    logger.info("Calculate route endpoint called")
    
    try:
        # Parsear body
        req_body = req.get_json()
        
        if not req_body:
            return func.HttpResponse(
                body='{"error": "Missing request body"}',
                status_code=400,
                mimetype="application/json"
            )
        
        # Validar campos requeridos
        origin = req_body.get('origin')
        destination = req_body.get('destination')
        
        if not origin or not destination:
            return func.HttpResponse(
                body='{"error": "Missing origin or destination"}',
                status_code=400,
                mimetype="application/json"
            )
        
        # TODO: Implementar algoritmo de cálculo de rutas
        
        routes_response = {
            "success": True,
            "origin": origin,
            "destination": destination,
            "routes": [],
            "calculation_time_ms": 0,
            "timestamp": "2025-11-30T12:00:00Z"
        }
        
        return func.HttpResponse(
            body=str(routes_response),
            status_code=200,
            mimetype="application/json"
        )
        
    except ValueError as e:
        logger.error(f"Invalid request body: {str(e)}")
        return func.HttpResponse(
            body='{"error": "Invalid request format"}',
            status_code=400,
            mimetype="application/json"
        )
    except Exception as e:
        logger.error(f"Error in calculate_route: {str(e)}")
        return func.HttpResponse(
            body='{"error": "Internal server error"}',
            status_code=500,
            mimetype="application/json"
        )


# ============================================================================
# TIMER TRIGGER (Data Ingestion Job)
# ============================================================================

@app.timer_trigger(schedule="0 */20 * * * *", arg_name="timer", run_on_startup=False)
def data_ingestion_timer(timer: func.TimerRequest) -> None:
    """
    Timer trigger que ejecuta cada 20 minutos para actualizar cache de datos.
    
    Tareas:
        - Fetch BiciMAD stations availability
        - Fetch air quality data from Madrid APIs
        - Update blob storage cache
    """
    logger.info("Data ingestion timer triggered")
    
    try:
        if timer.past_due:
            logger.warning("Timer is past due!")
        
        # TODO: Implementar lógica de ingesta de datos
        
        logger.info("Data ingestion completed successfully")
        
    except Exception as e:
        logger.error(f"Error in data ingestion: {str(e)}")


logger.info("BiciMAD Low Emission Router API initialized")
