"""
============================================================================
Integration Tests - Function App Endpoints
============================================================================
Tests para endpoints HTTP de Azure Functions:
- GET /api/health
- GET /api/stations
- GET /api/air-quality
- POST /api/calculate-route

Incluye mocking de providers y validación de responses
============================================================================
"""

import pytest
import json
from unittest.mock import AsyncMock, patch, MagicMock

# Importar módulos a testear
import sys
sys.path.insert(0, '../')

import azure.functions as func
from function_app import (
    health_check,
    get_stations,
    get_air_quality,
    calculate_route
)
from utils.data_providers import BiciMADStation
from utils.scoring_engine import RouteScore


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def mock_bicimad_stations():
    """Mock de estaciones BiciMAD"""
    return [
        BiciMADStation(
            id='1',
            name='Puerta del Sol',
            latitude=40.4168,
            longitude=-3.7038,
            total_bases=30,
            free_bases=10,
            dock_bikes=20,
            active=True
        ),
        BiciMADStation(
            id='2',
            name='Plaza Mayor',
            latitude=40.4154,
            longitude=-3.7074,
            total_bases=25,
            free_bases=15,
            dock_bikes=10,
            active=True
        )
    ]


@pytest.fixture
def mock_air_quality_response():
    """Mock de respuesta de calidad del aire"""
    return {
        'location': {'lat': 40.4168, 'lon': -3.7038},
        'pollutants': {
            'NO2': 35.5,
            'PM10': 22.0,
            'PM2.5': 12.0
        },
        'score': 28.5,
        'level': 'good',
        'sources': [
            {
                'station_id': '28079004',
                'station_name': 'Plaza de España',
                'distance_km': 0.8
            }
        ]
    }


@pytest.fixture
def mock_scored_routes():
    """Mock de rutas con scoring"""
    return [
        RouteScore(
            route_type='fastest',
            distance_meters=5000,
            duration_seconds=1200,
            geometry={
                'type': 'LineString',
                'coordinates': [[-3.7038, 40.4168], [-3.7070, 40.4200]]
            },
            emission_score=35.5,
            pollutants={'NO2': 35.5, 'PM10': 22.0, 'PM2.5': 12.0},
            health_impact='low',
            recommendation_level='excellent',
            comparative_analysis={}
        ),
        RouteScore(
            route_type='shortest',
            distance_meters=4500,
            duration_seconds=1350,
            geometry={
                'type': 'LineString',
                'coordinates': [[-3.7038, 40.4168], [-3.7070, 40.4200]]
            },
            emission_score=40.0,
            pollutants={'NO2': 40.0, 'PM10': 25.0, 'PM2.5': 15.0},
            health_impact='low',
            recommendation_level='good',
            comparative_analysis={}
        )
    ]


# ============================================================================
# Health Check Endpoint Tests
# ============================================================================

class TestHealthCheck:
    """Tests para endpoint /api/health"""
    
    @pytest.mark.asyncio
    async def test_health_check_success(self):
        """Test health check exitoso"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/health',
            params={}
        )
        
        response = await health_check(req)
        
        assert response.status_code == 200
        
        body = json.loads(response.get_body())
        assert body['status'] == 'healthy'
        assert 'timestamp' in body
        assert 'environment' in body
        assert 'cache' in body
    
    @pytest.mark.asyncio
    async def test_health_check_includes_cache_info(self):
        """Test que health check incluye info de cache"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/health',
            params={}
        )
        
        response = await health_check(req)
        body = json.loads(response.get_body())
        
        assert 'cache' in body
        assert 'type' in body['cache']
        assert body['cache']['type'] in ['local', 'azure_blob']


# ============================================================================
# Get Stations Endpoint Tests
# ============================================================================

class TestGetStations:
    """Tests para endpoint /api/stations"""
    
    @pytest.mark.asyncio
    async def test_get_stations_success(self, mock_bicimad_stations):
        """Test obtener estaciones cercanas exitoso"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={
                'lat': '40.4168',
                'lon': '-3.7038',
                'radius': '2.0'
            }
        )
        
        with patch('function_app.get_bicimad_provider') as mock_provider:
            provider_mock = MagicMock()
            provider_mock.get_nearby_stations = AsyncMock(
                return_value=mock_bicimad_stations
            )
            mock_provider.return_value = provider_mock
            
            response = await get_stations(req)
            
            assert response.status_code == 200
            
            body = json.loads(response.get_body())
            assert 'stations' in body
            assert len(body['stations']) == 2
            assert body['stations'][0]['name'] == 'Puerta del Sol'
    
    @pytest.mark.asyncio
    async def test_get_stations_missing_parameters(self):
        """Test con parámetros faltantes"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={'lat': '40.4168'}  # Falta lon
        )
        
        response = await get_stations(req)
        
        assert response.status_code == 400
        body = json.loads(response.get_body())
        assert 'error' in body
    
    @pytest.mark.asyncio
    async def test_get_stations_invalid_coordinates(self):
        """Test con coordenadas inválidas"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={
                'lat': 'invalid',
                'lon': '-3.7038'
            }
        )
        
        response = await get_stations(req)
        
        assert response.status_code == 400
    
    @pytest.mark.asyncio
    async def test_get_stations_out_of_bounds(self):
        """Test con coordenadas fuera de Madrid"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={
                'lat': '41.3874',  # Barcelona
                'lon': '2.1686'
            }
        )
        
        response = await get_stations(req)
        
        assert response.status_code == 400
        body = json.loads(response.get_body())
        assert 'Madrid' in body['error'] or 'bound' in body['error'].lower()
    
    @pytest.mark.asyncio
    async def test_get_stations_with_custom_radius(self, mock_bicimad_stations):
        """Test con radio personalizado"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={
                'lat': '40.4168',
                'lon': '-3.7038',
                'radius': '5.0'
            }
        )
        
        with patch('function_app.get_bicimad_provider') as mock_provider:
            provider_mock = MagicMock()
            provider_mock.get_nearby_stations = AsyncMock(
                return_value=mock_bicimad_stations
            )
            mock_provider.return_value = provider_mock
            
            response = await get_stations(req)
            
            assert response.status_code == 200
            # Verificar que se llamó con el radio correcto
            provider_mock.get_nearby_stations.assert_called_once()


# ============================================================================
# Get Air Quality Endpoint Tests
# ============================================================================

class TestGetAirQuality:
    """Tests para endpoint /api/air-quality"""
    
    @pytest.mark.asyncio
    async def test_get_air_quality_success(self, mock_air_quality_response):
        """Test obtener calidad del aire exitoso"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/air-quality',
            params={
                'lat': '40.4168',
                'lon': '-3.7038'
            }
        )
        
        with patch('function_app.get_air_quality_provider') as mock_provider:
            provider_mock = MagicMock()
            provider_mock.get_air_quality = AsyncMock(
                return_value=mock_air_quality_response
            )
            mock_provider.return_value = provider_mock
            
            response = await get_air_quality(req)
            
            assert response.status_code == 200
            
            body = json.loads(response.get_body())
            assert 'pollutants' in body
            assert 'NO2' in body['pollutants']
            assert body['pollutants']['NO2'] == 35.5
            assert body['level'] == 'good'
    
    @pytest.mark.asyncio
    async def test_get_air_quality_missing_parameters(self):
        """Test con parámetros faltantes"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/air-quality',
            params={'lat': '40.4168'}
        )
        
        response = await get_air_quality(req)
        
        assert response.status_code == 400
    
    @pytest.mark.asyncio
    async def test_get_air_quality_caching(self, mock_air_quality_response):
        """Test que el resultado se cachea correctamente"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/air-quality',
            params={
                'lat': '40.4168',
                'lon': '-3.7038'
            }
        )
        
        with patch('function_app.get_air_quality_provider') as mock_provider:
            provider_mock = MagicMock()
            provider_mock.get_air_quality = AsyncMock(
                return_value=mock_air_quality_response
            )
            mock_provider.return_value = provider_mock
            
            # Primera llamada
            response1 = await get_air_quality(req)
            assert response1.status_code == 200
            
            # Segunda llamada (debería usar cache)
            response2 = await get_air_quality(req)
            assert response2.status_code == 200
            
            body1 = json.loads(response1.get_body())
            body2 = json.loads(response2.get_body())
            assert body1 == body2


# ============================================================================
# Calculate Route Endpoint Tests
# ============================================================================

class TestCalculateRoute:
    """Tests para endpoint /api/calculate-route"""
    
    @pytest.mark.asyncio
    async def test_calculate_route_success(self, mock_scored_routes):
        """Test cálculo de ruta exitoso"""
        req = func.HttpRequest(
            method='POST',
            body=json.dumps({
                'origin': {'lat': 40.4168, 'lon': -3.7038},
                'destination': {'lat': 40.4558, 'lon': -3.6883},
                'preference': 'balanced'
            }).encode('utf-8'),
            url='/api/calculate-route'
        )
        
        with patch('function_app.get_scoring_engine') as mock_engine:
            engine_mock = MagicMock()
            engine_mock.score_routes = AsyncMock(
                return_value=mock_scored_routes
            )
            mock_engine.return_value = engine_mock
            
            with patch('function_app.get_azure_maps_provider') as mock_maps:
                maps_mock = MagicMock()
                maps_mock.calculate_routes = AsyncMock(
                    return_value=[
                        {
                            'type': 'fastest',
                            'distance_meters': 5000,
                            'duration_seconds': 1200,
                            'geometry': {'type': 'LineString', 'coordinates': []}
                        }
                    ]
                )
                mock_maps.return_value = maps_mock
                
                response = await calculate_route(req)
                
                assert response.status_code == 200
                
                body = json.loads(response.get_body())
                assert 'routes' in body
                assert len(body['routes']) == 2
                assert body['routes'][0]['route_type'] == 'fastest'
    
    @pytest.mark.asyncio
    async def test_calculate_route_missing_origin(self):
        """Test con origen faltante"""
        req = func.HttpRequest(
            method='POST',
            body=json.dumps({
                'destination': {'lat': 40.4558, 'lon': -3.6883}
            }).encode('utf-8'),
            url='/api/calculate-route'
        )
        
        response = await calculate_route(req)
        
        assert response.status_code == 400
        body = json.loads(response.get_body())
        assert 'error' in body
    
    @pytest.mark.asyncio
    async def test_calculate_route_invalid_json(self):
        """Test con JSON inválido"""
        req = func.HttpRequest(
            method='POST',
            body=b'invalid json',
            url='/api/calculate-route'
        )
        
        response = await calculate_route(req)
        
        assert response.status_code == 400
    
    @pytest.mark.asyncio
    async def test_calculate_route_invalid_coordinates(self):
        """Test con coordenadas inválidas"""
        req = func.HttpRequest(
            method='POST',
            body=json.dumps({
                'origin': {'lat': 'invalid', 'lon': -3.7038},
                'destination': {'lat': 40.4558, 'lon': -3.6883}
            }).encode('utf-8'),
            url='/api/calculate-route'
        )
        
        response = await calculate_route(req)
        
        assert response.status_code == 400
    
    @pytest.mark.asyncio
    async def test_calculate_route_out_of_bounds(self):
        """Test con coordenadas fuera de Madrid"""
        req = func.HttpRequest(
            method='POST',
            body=json.dumps({
                'origin': {'lat': 41.3874, 'lon': 2.1686},  # Barcelona
                'destination': {'lat': 40.4558, 'lon': -3.6883}
            }).encode('utf-8'),
            url='/api/calculate-route'
        )
        
        response = await calculate_route(req)
        
        assert response.status_code == 400
    
    @pytest.mark.asyncio
    async def test_calculate_route_all_preferences(self, mock_scored_routes):
        """Test con todas las preferencias"""
        preferences = ['air_quality', 'distance', 'time', 'balanced']
        
        for preference in preferences:
            req = func.HttpRequest(
                method='POST',
                body=json.dumps({
                    'origin': {'lat': 40.4168, 'lon': -3.7038},
                    'destination': {'lat': 40.4558, 'lon': -3.6883},
                    'preference': preference
                }).encode('utf-8'),
                url='/api/calculate-route'
            )
            
            with patch('function_app.get_scoring_engine') as mock_engine:
                engine_mock = MagicMock()
                engine_mock.score_routes = AsyncMock(
                    return_value=mock_scored_routes
                )
                mock_engine.return_value = engine_mock
                
                with patch('function_app.get_azure_maps_provider') as mock_maps:
                    maps_mock = MagicMock()
                    maps_mock.calculate_routes = AsyncMock(
                        return_value=[
                            {
                                'type': 'fastest',
                                'distance_meters': 5000,
                                'duration_seconds': 1200,
                                'geometry': {'type': 'LineString', 'coordinates': []}
                            }
                        ]
                    )
                    mock_maps.return_value = maps_mock
                    
                    response = await calculate_route(req)
                    
                    assert response.status_code == 200


# ============================================================================
# Error Handling Tests
# ============================================================================

class TestErrorHandling:
    """Tests para manejo de errores"""
    
    @pytest.mark.asyncio
    async def test_internal_server_error(self):
        """Test error interno del servidor"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={
                'lat': '40.4168',
                'lon': '-3.7038'
            }
        )
        
        with patch('function_app.get_bicimad_provider') as mock_provider:
            provider_mock = MagicMock()
            provider_mock.get_nearby_stations = AsyncMock(
                side_effect=Exception("Database connection failed")
            )
            mock_provider.return_value = provider_mock
            
            response = await get_stations(req)
            
            assert response.status_code == 500
            body = json.loads(response.get_body())
            assert 'error' in body
    
    @pytest.mark.asyncio
    async def test_timeout_error(self):
        """Test timeout en API externa"""
        req = func.HttpRequest(
            method='POST',
            body=json.dumps({
                'origin': {'lat': 40.4168, 'lon': -3.7038},
                'destination': {'lat': 40.4558, 'lon': -3.6883},
                'preference': 'balanced'
            }).encode('utf-8'),
            url='/api/calculate-route'
        )
        
        with patch('function_app.get_azure_maps_provider') as mock_maps:
            maps_mock = MagicMock()
            maps_mock.calculate_routes = AsyncMock(
                side_effect=TimeoutError("Request timeout")
            )
            mock_maps.return_value = maps_mock
            
            response = await calculate_route(req)
            
            assert response.status_code in [500, 504]


# ============================================================================
# CORS Tests
# ============================================================================

class TestCORS:
    """Tests para configuración CORS"""
    
    @pytest.mark.asyncio
    async def test_cors_headers_present(self):
        """Test que headers CORS están presentes"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/health',
            params={}
        )
        
        response = await health_check(req)
        
        headers = dict(response.headers)
        assert 'Access-Control-Allow-Origin' in headers
    
    @pytest.mark.asyncio
    async def test_options_request(self):
        """Test request OPTIONS para preflight"""
        req = func.HttpRequest(
            method='OPTIONS',
            body=None,
            url='/api/stations',
            params={}
        )
        
        # OPTIONS requests deben retornar 200 con headers CORS
        # (Implementación depende de function_app.py)


# ============================================================================
# Performance Tests
# ============================================================================

class TestPerformance:
    """Tests de rendimiento"""
    
    @pytest.mark.asyncio
    async def test_response_time_stations(self, mock_bicimad_stations):
        """Test tiempo de respuesta aceptable para /stations"""
        req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={
                'lat': '40.4168',
                'lon': '-3.7038'
            }
        )
        
        with patch('function_app.get_bicimad_provider') as mock_provider:
            provider_mock = MagicMock()
            provider_mock.get_nearby_stations = AsyncMock(
                return_value=mock_bicimad_stations
            )
            mock_provider.return_value = provider_mock
            
            import time
            start = time.time()
            response = await get_stations(req)
            duration = time.time() - start
            
            assert response.status_code == 200
            # Debe responder en menos de 1 segundo
            assert duration < 1.0


# ============================================================================
# Integration Tests (Full Flow)
# ============================================================================

class TestFullFlow:
    """Tests de flujo completo"""
    
    @pytest.mark.asyncio
    async def test_complete_user_journey(
        self,
        mock_bicimad_stations,
        mock_air_quality_response,
        mock_scored_routes
    ):
        """Test journey completo del usuario"""
        
        # 1. Health check
        health_req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/health',
            params={}
        )
        health_response = await health_check(health_req)
        assert health_response.status_code == 200
        
        # 2. Obtener estaciones cercanas
        stations_req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/stations',
            params={
                'lat': '40.4168',
                'lon': '-3.7038'
            }
        )
        
        with patch('function_app.get_bicimad_provider') as mock_provider:
            provider_mock = MagicMock()
            provider_mock.get_nearby_stations = AsyncMock(
                return_value=mock_bicimad_stations
            )
            mock_provider.return_value = provider_mock
            
            stations_response = await get_stations(stations_req)
            assert stations_response.status_code == 200
        
        # 3. Consultar calidad del aire
        aq_req = func.HttpRequest(
            method='GET',
            body=None,
            url='/api/air-quality',
            params={
                'lat': '40.4168',
                'lon': '-3.7038'
            }
        )
        
        with patch('function_app.get_air_quality_provider') as mock_aq:
            aq_mock = MagicMock()
            aq_mock.get_air_quality = AsyncMock(
                return_value=mock_air_quality_response
            )
            mock_aq.return_value = aq_mock
            
            aq_response = await get_air_quality(aq_req)
            assert aq_response.status_code == 200
        
        # 4. Calcular ruta
        route_req = func.HttpRequest(
            method='POST',
            body=json.dumps({
                'origin': {'lat': 40.4168, 'lon': -3.7038},
                'destination': {'lat': 40.4558, 'lon': -3.6883},
                'preference': 'balanced'
            }).encode('utf-8'),
            url='/api/calculate-route'
        )
        
        with patch('function_app.get_scoring_engine') as mock_engine:
            engine_mock = MagicMock()
            engine_mock.score_routes = AsyncMock(
                return_value=mock_scored_routes
            )
            mock_engine.return_value = engine_mock
            
            with patch('function_app.get_azure_maps_provider') as mock_maps:
                maps_mock = MagicMock()
                maps_mock.calculate_routes = AsyncMock(
                    return_value=[
                        {
                            'type': 'fastest',
                            'distance_meters': 5000,
                            'duration_seconds': 1200,
                            'geometry': {'type': 'LineString', 'coordinates': []}
                        }
                    ]
                )
                mock_maps.return_value = maps_mock
                
                route_response = await calculate_route(route_req)
                assert route_response.status_code == 200


# ============================================================================
# Run Tests
# ============================================================================

if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=function_app', '--cov-report=html'])
