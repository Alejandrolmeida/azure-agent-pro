"""
============================================================================
Unit Tests - Data Providers Module
============================================================================
Tests para clientes de APIs externas:
- BiciMADProvider
- AirQualityProvider
- AzureMapsProvider

Incluye mocking de HTTP calls y validación de lógica de negocio
============================================================================
"""

import pytest
import httpx
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

# Importar módulos a testear
import sys
sys.path.insert(0, '../')

from utils.data_providers import (
    BiciMADProvider,
    AirQualityProvider,
    AzureMapsProvider,
    BiciMADStation,
    AirQualityReading
)


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def mock_bicimad_response():
    """Mock response de API BiciMAD"""
    return {
        '@graph': [
            {
                'id': '1',
                'name': 'Puerta del Sol',
                'location': {
                    'latitude': 40.4168,
                    'longitude': -3.7038
                },
                'total_bases': 30,
                'free_bases': 10,
                'dock_bikes': 20,
                'activate': 1
            },
            {
                'id': '2',
                'name': 'Plaza Mayor',
                'location': {
                    'latitude': 40.4154,
                    'longitude': -3.7074
                },
                'total_bases': 25,
                'free_bases': 15,
                'dock_bikes': 10,
                'activate': 1
            },
            {
                'id': '3',
                'name': 'Estación Inactiva',
                'location': {
                    'latitude': 40.4200,
                    'longitude': -3.7100
                },
                'total_bases': 20,
                'free_bases': 0,
                'dock_bikes': 0,
                'activate': 0
            }
        ]
    }


@pytest.fixture
def mock_azure_maps_response():
    """Mock response de Azure Maps API"""
    return {
        'routes': [
            {
                'summary': {
                    'lengthInMeters': 5000,
                    'travelTimeInSeconds': 1200
                },
                'legs': [
                    {
                        'points': [
                            {'latitude': 40.4168, 'longitude': -3.7038},
                            {'latitude': 40.4180, 'longitude': -3.7050},
                            {'latitude': 40.4200, 'longitude': -3.7070}
                        ]
                    }
                ]
            }
        ]
    }


# ============================================================================
# BiciMADProvider Tests
# ============================================================================

class TestBiciMADProvider:
    """Tests para BiciMADProvider"""
    
    @pytest.mark.asyncio
    async def test_get_stations_success(self, mock_bicimad_response):
        """Test obtener estaciones exitosamente"""
        provider = BiciMADProvider()
        
        # Mock HTTP client
        with patch.object(provider.client, 'get') as mock_get:
            mock_response = MagicMock()
            mock_response.json.return_value = mock_bicimad_response
            mock_response.raise_for_status = MagicMock()
            mock_get.return_value = mock_response
            
            stations = await provider.get_stations()
            
            assert len(stations) == 3
            assert all(isinstance(s, BiciMADStation) for s in stations)
            assert stations[0].name == 'Puerta del Sol'
            assert stations[0].total_bases == 30
            assert stations[0].dock_bikes == 20
            assert stations[0].active is True
            assert stations[2].active is False
    
    @pytest.mark.asyncio
    async def test_get_stations_http_error(self):
        """Test manejo de error HTTP"""
        provider = BiciMADProvider()
        
        with patch.object(provider.client, 'get') as mock_get:
            mock_get.side_effect = httpx.HTTPError("Connection failed")
            
            with pytest.raises(httpx.HTTPError):
                await provider.get_stations()
    
    @pytest.mark.asyncio
    async def test_get_nearby_stations(self, mock_bicimad_response):
        """Test filtrar estaciones cercanas"""
        provider = BiciMADProvider()
        
        with patch.object(provider, 'get_stations') as mock_get_stations:
            # Crear estaciones mock
            stations = [
                BiciMADStation(
                    id='1',
                    name='Cerca',
                    latitude=40.4168,
                    longitude=-3.7038,
                    total_bases=30,
                    free_bases=10,
                    dock_bikes=20,
                    active=True
                ),
                BiciMADStation(
                    id='2',
                    name='Muy Lejos',
                    latitude=40.5000,
                    longitude=-3.8000,
                    total_bases=25,
                    free_bases=15,
                    dock_bikes=10,
                    active=True
                )
            ]
            mock_get_stations.return_value = stations
            
            # Buscar cercanas a Puerta del Sol
            nearby = await provider.get_nearby_stations(
                lat=40.4168,
                lon=-3.7038,
                radius_km=2.0,
                max_results=10
            )
            
            # Solo debe devolver la estación cercana
            assert len(nearby) == 1
            assert nearby[0].name == 'Cerca'
    
    def test_station_distance_to(self):
        """Test cálculo de distancia entre estaciones"""
        station = BiciMADStation(
            id='1',
            name='Test',
            latitude=40.4168,
            longitude=-3.7038,
            total_bases=30,
            free_bases=10,
            dock_bikes=20,
            active=True
        )
        
        # Distancia a mismo punto (debe ser ~0)
        distance = station.distance_to(40.4168, -3.7038)
        assert distance < 0.01
        
        # Distancia a Plaza Mayor (aprox 400m = 0.4 km)
        distance = station.distance_to(40.4154, -3.7074)
        assert 0.3 < distance < 0.5


# ============================================================================
# AirQualityProvider Tests
# ============================================================================

class TestAirQualityProvider:
    """Tests para AirQualityProvider"""
    
    @pytest.mark.asyncio
    async def test_get_air_quality_success(self):
        """Test obtener calidad del aire"""
        provider = AirQualityProvider()
        
        # Obtener datos para Puerta del Sol
        data = await provider.get_air_quality(40.4168, -3.7038)
        
        assert 'location' in data
        assert 'pollutants' in data
        assert 'score' in data
        assert 'level' in data
        
        assert data['location']['lat'] == 40.4168
        assert data['location']['lon'] == -3.7038
        
        assert 'NO2' in data['pollutants']
        assert 'PM10' in data['pollutants']
        assert 'PM2.5' in data['pollutants']
        
        assert 0 <= data['score'] <= 100
        assert data['level'] in ['good', 'moderate', 'unhealthy_sensitive', 'unhealthy']
    
    def test_get_nearest_stations(self):
        """Test encontrar estaciones más cercanas"""
        provider = AirQualityProvider()
        
        nearest = provider._get_nearest_stations(40.4168, -3.7038, k=3)
        
        assert len(nearest) == 3
        # Verificar que están ordenadas por distancia
        distances = [item[2] for item in nearest]
        assert distances == sorted(distances)
    
    def test_interpolate_readings(self):
        """Test interpolación IDW"""
        provider = AirQualityProvider()
        
        readings = [
            AirQualityReading(
                station_id='1',
                station_name='Station 1',
                latitude=40.4168,
                longitude=-3.7038,
                no2=50.0,
                pm10=30.0,
                pm25=15.0
            ),
            AirQualityReading(
                station_id='2',
                station_name='Station 2',
                latitude=40.4200,
                longitude=-3.7100,
                no2=60.0,
                pm10=40.0,
                pm25=20.0
            )
        ]
        
        interpolated = provider._interpolate_readings(
            readings, 40.4180, -3.7070
        )
        
        # Valores interpolados deben estar entre los extremos
        assert 50.0 <= interpolated['no2'] <= 60.0
        assert 30.0 <= interpolated['pm10'] <= 40.0
        assert 15.0 <= interpolated['pm25'] <= 20.0
    
    def test_calculate_air_quality_score(self):
        """Test cálculo de score de calidad del aire"""
        provider = AirQualityProvider()
        
        # Aire limpio
        score_clean = provider._calculate_air_quality_score({
            'no2': 10,
            'pm10': 10,
            'pm25': 5
        })
        assert score_clean < 30
        
        # Aire contaminado
        score_polluted = provider._calculate_air_quality_score({
            'no2': 150,
            'pm10': 45,
            'pm25': 23
        })
        assert score_polluted > 60
    
    def test_get_air_quality_level(self):
        """Test determinación de nivel de calidad"""
        provider = AirQualityProvider()
        
        assert provider._get_air_quality_level(15) == 'good'
        assert provider._get_air_quality_level(45) == 'moderate'
        assert provider._get_air_quality_level(70) == 'unhealthy_sensitive'
        assert provider._get_air_quality_level(90) == 'unhealthy'


# ============================================================================
# AzureMapsProvider Tests
# ============================================================================

class TestAzureMapsProvider:
    """Tests para AzureMapsProvider"""
    
    @pytest.mark.asyncio
    async def test_calculate_routes_simulated(self):
        """Test cálculo de rutas (modo simulado)"""
        provider = AzureMapsProvider(api_key='test-key')
        
        origin = {'lat': 40.4168, 'lon': -3.7038}
        destination = {'lat': 40.4558, 'lon': -3.6883}
        
        routes = await provider.calculate_routes(origin, destination)
        
        assert len(routes) == 3  # fastest, shortest, eco
        
        for route in routes:
            assert route['type'] in ['fastest', 'shortest', 'eco']
            assert 'distance_meters' in route
            assert 'duration_seconds' in route
            assert 'geometry' in route
            assert route['simulated'] is True
    
    @pytest.mark.asyncio
    async def test_calculate_single_route(self, mock_azure_maps_response):
        """Test cálculo de ruta individual con API real"""
        provider = AzureMapsProvider(api_key='valid-key')
        
        origin = {'lat': 40.4168, 'lon': -3.7038}
        destination = {'lat': 40.4200, 'lon': -3.7070}
        
        with patch.object(provider.client, 'get') as mock_get:
            mock_response = MagicMock()
            mock_response.json.return_value = mock_azure_maps_response
            mock_response.raise_for_status = MagicMock()
            mock_get.return_value = mock_response
            
            route = await provider._get_single_route(origin, destination, 'fastest')
            
            assert route['type'] == 'fastest'
            assert route['distance_meters'] == 5000
            assert route['duration_seconds'] == 1200
    
    def test_simulate_route(self):
        """Test generación de ruta simulada"""
        provider = AzureMapsProvider(api_key='test-key')
        
        origin = {'lat': 40.4168, 'lon': -3.7038}
        destination = {'lat': 40.4558, 'lon': -3.6883}
        
        route = provider._simulate_route(origin, destination, 'fastest')
        
        assert route['type'] == 'fastest'
        assert route['distance_meters'] > 0
        assert route['duration_seconds'] > 0
        assert route['geometry']['type'] == 'LineString'
        assert len(route['geometry']['coordinates']) > 0
        assert route['simulated'] is True
    
    def test_generate_route_points(self):
        """Test generación de puntos intermedios"""
        provider = AzureMapsProvider(api_key='test-key')
        
        origin = {'lat': 40.4168, 'lon': -3.7038}
        destination = {'lat': 40.4558, 'lon': -3.6883}
        
        points = provider._generate_route_points(origin, destination, num_points=10)
        
        assert len(points) == 11  # num_points + 1 (incluye origen y destino)
        
        # Primer punto debe ser origen
        assert points[0][1] == origin['lat']  # GeoJSON format: [lon, lat]
        assert points[0][0] == origin['lon']
        
        # Último punto debe ser destino
        assert points[-1][1] == destination['lat']
        assert points[-1][0] == destination['lon']


# ============================================================================
# Integration Tests
# ============================================================================

class TestDataProvidersIntegration:
    """Tests de integración entre providers"""
    
    @pytest.mark.asyncio
    async def test_complete_workflow(self, mock_bicimad_response):
        """Test flujo completo: estaciones + calidad aire + rutas"""
        # 1. Obtener estaciones
        bicimad = BiciMADProvider()
        with patch.object(bicimad.client, 'get') as mock_get:
            mock_response = MagicMock()
            mock_response.json.return_value = mock_bicimad_response
            mock_response.raise_for_status = MagicMock()
            mock_get.return_value = mock_response
            
            stations = await bicimad.get_stations()
            assert len(stations) > 0
        
        # 2. Obtener calidad del aire en estación
        air_quality = AirQualityProvider()
        station = stations[0]
        air_data = await air_quality.get_air_quality(
            station.latitude,
            station.longitude
        )
        assert 'score' in air_data
        
        # 3. Calcular ruta
        maps = AzureMapsProvider(api_key='test-key')
        origin = {'lat': stations[0].latitude, 'lon': stations[0].longitude}
        destination = {'lat': stations[1].latitude, 'lon': stations[1].longitude}
        
        routes = await maps.calculate_routes(origin, destination)
        assert len(routes) > 0


# ============================================================================
# Parametrized Tests
# ============================================================================

@pytest.mark.parametrize("lat,lon,expected_valid", [
    (40.4168, -3.7038, True),   # Madrid centro
    (40.5000, -3.8000, True),   # Madrid periferia
    (41.3874, 2.1686, False),   # Barcelona (fuera de rango)
    (0, 0, False),              # Coordenadas inválidas
])
def test_coordinate_validation(lat, lon, expected_valid):
    """Test validación de coordenadas"""
    # Madrid bounds: lat [40.3, 40.6], lon [-3.9, -3.5]
    is_valid = (40.3 <= lat <= 40.6) and (-3.9 <= lon <= -3.5)
    assert is_valid == expected_valid


@pytest.mark.parametrize("route_type,multiplier", [
    ('fastest', 1.3),
    ('shortest', 1.15),
    ('eco', 1.4),
])
def test_route_distance_multipliers(route_type, multiplier):
    """Test multiplicadores de distancia por tipo de ruta"""
    provider = AzureMapsProvider(api_key='test')
    origin = {'lat': 40.4168, 'lon': -3.7038}
    destination = {'lat': 40.4558, 'lon': -3.6883}
    
    route = provider._simulate_route(origin, destination, route_type)
    
    # La distancia simulada debe usar el multiplicador correcto
    from geopy.distance import geodesic
    straight_distance = geodesic(
        (origin['lat'], origin['lon']),
        (destination['lat'], destination['lon'])
    ).kilometers * 1000
    
    expected_min = straight_distance * multiplier * 0.9
    expected_max = straight_distance * multiplier * 1.1
    
    assert expected_min <= route['distance_meters'] <= expected_max


# ============================================================================
# Run Tests
# ============================================================================

if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=utils.data_providers', '--cov-report=html'])
