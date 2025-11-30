"""
============================================================================
Unit Tests - Scoring Engine Module
============================================================================
Tests para motor de scoring de rutas:
- Cálculo de emisiones
- Interpolación IDW
- Comparación de rutas
- Recomendaciones según preferencias
============================================================================
"""

import pytest
from unittest.mock import AsyncMock, patch

# Importar módulos a testear
import sys
sys.path.insert(0, '../')

from utils.scoring_engine import ScoringEngine, RouteScore
from utils.data_providers import AirQualityProvider


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def sample_routes():
    """Rutas de ejemplo para testing"""
    return [
        {
            'type': 'fastest',
            'distance_meters': 5000,
            'duration_seconds': 1200,
            'geometry': {
                'type': 'LineString',
                'coordinates': [
                    [-3.7038, 40.4168],
                    [-3.7050, 40.4180],
                    [-3.7070, 40.4200]
                ]
            }
        },
        {
            'type': 'shortest',
            'distance_meters': 4500,
            'duration_seconds': 1350,
            'geometry': {
                'type': 'LineString',
                'coordinates': [
                    [-3.7038, 40.4168],
                    [-3.7045, 40.4175],
                    [-3.7070, 40.4200]
                ]
            }
        }
    ]


@pytest.fixture
def mock_air_quality_data():
    """Datos de calidad del aire mock"""
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


# ============================================================================
# RouteScore Tests
# ============================================================================

class TestRouteScore:
    """Tests para dataclass RouteScore"""
    
    def test_route_score_creation(self):
        """Test creación de RouteScore"""
        score = RouteScore(
            route_type='fastest',
            distance_meters=5000,
            duration_seconds=1200,
            geometry={'type': 'LineString', 'coordinates': []},
            emission_score=35.5,
            pollutants={'NO2': 35.5, 'PM10': 22.0, 'PM2.5': 12.0},
            health_impact='low',
            recommendation_level='excellent',
            comparative_analysis={}
        )
        
        assert score.route_type == 'fastest'
        assert score.distance_meters == 5000
        assert score.duration_seconds == 1200
        assert score.emission_score == 35.5
        assert score.health_impact == 'low'
        assert score.recommendation_level == 'excellent'
    
    def test_route_score_to_dict(self):
        """Test conversión a diccionario"""
        score = RouteScore(
            route_type='fastest',
            distance_meters=5000,
            duration_seconds=1200,
            geometry={'type': 'LineString', 'coordinates': []},
            emission_score=35.5,
            pollutants={'NO2': 35.5, 'PM10': 22.0, 'PM2.5': 12.0},
            health_impact='low',
            recommendation_level='excellent',
            comparative_analysis={'test': 'data'}
        )
        
        result = score.__dict__
        assert isinstance(result, dict)
        assert result['route_type'] == 'fastest'
        assert result['emission_score'] == 35.5


# ============================================================================
# ScoringEngine Core Tests
# ============================================================================

class TestScoringEngine:
    """Tests para ScoringEngine"""
    
    @pytest.mark.asyncio
    async def test_score_routes_success(self, sample_routes, mock_air_quality_data):
        """Test scoring de rutas exitoso"""
        engine = ScoringEngine()
        
        # Mock air quality provider
        with patch.object(
            AirQualityProvider, 'get_air_quality',
            new_callable=AsyncMock
        ) as mock_aq:
            mock_aq.return_value = mock_air_quality_data
            
            scored_routes = await engine.score_routes(
                sample_routes,
                preference='balanced'
            )
            
            assert len(scored_routes) == 2
            assert all(isinstance(r, RouteScore) for r in scored_routes)
            
            # Verificar campos requeridos
            for route in scored_routes:
                assert hasattr(route, 'emission_score')
                assert hasattr(route, 'pollutants')
                assert hasattr(route, 'health_impact')
                assert hasattr(route, 'recommendation_level')
                assert 0 <= route.emission_score <= 100
    
    @pytest.mark.asyncio
    async def test_score_empty_routes(self):
        """Test con lista vacía de rutas"""
        engine = ScoringEngine()
        
        scored_routes = await engine.score_routes([], preference='balanced')
        assert len(scored_routes) == 0
    
    def test_sample_route_points(self):
        """Test muestreo de puntos en ruta"""
        engine = ScoringEngine()
        
        route = {
            'geometry': {
                'type': 'LineString',
                'coordinates': [
                    [-3.7038, 40.4168],
                    [-3.7070, 40.4200]
                ]
            }
        }
        
        points = engine._sample_route_points(route, sample_distance=200)
        
        assert len(points) > 0
        # Cada punto debe ser tupla (lat, lon)
        for point in points:
            assert isinstance(point, tuple)
            assert len(point) == 2


# ============================================================================
# Air Quality Calculation Tests
# ============================================================================

class TestAirQualityCalculations:
    """Tests para cálculos de calidad del aire"""
    
    @pytest.mark.asyncio
    async def test_get_air_quality_at_point(self, mock_air_quality_data):
        """Test obtener calidad del aire en punto específico"""
        engine = ScoringEngine()
        
        with patch.object(
            AirQualityProvider, 'get_air_quality',
            new_callable=AsyncMock
        ) as mock_aq:
            mock_aq.return_value = mock_air_quality_data
            
            aq_data = await engine._get_air_quality_at_point(40.4168, -3.7038)
            
            assert 'pollutants' in aq_data
            assert 'NO2' in aq_data['pollutants']
            assert aq_data['pollutants']['NO2'] == 35.5
    
    def test_calculate_emission_score(self):
        """Test cálculo de score de emisiones"""
        engine = ScoringEngine()
        
        pollutants_list = [
            {'NO2': 30, 'PM10': 20, 'PM2.5': 10},
            {'NO2': 40, 'PM10': 25, 'PM2.5': 15},
            {'NO2': 35, 'PM10': 22, 'PM2.5': 12}
        ]
        
        score = engine._calculate_emission_score(pollutants_list)
        
        assert 0 <= score <= 100
        assert isinstance(score, float)
    
    def test_calculate_exposure_index(self):
        """Test cálculo de índice de exposición"""
        engine = ScoringEngine()
        
        pollutant_avg = {'NO2': 50, 'PM10': 30, 'PM2.5': 15}
        duration_minutes = 20
        
        exposure = engine._calculate_exposure_index(
            pollutant_avg,
            duration_minutes
        )
        
        assert exposure > 0
        # Mayor contaminación y tiempo = mayor exposición
        
        # Test con baja contaminación
        low_pollutants = {'NO2': 10, 'PM10': 5, 'PM2.5': 3}
        low_exposure = engine._calculate_exposure_index(
            low_pollutants,
            duration_minutes
        )
        
        assert low_exposure < exposure
    
    def test_normalize_pollutant(self):
        """Test normalización de contaminantes según WHO"""
        engine = ScoringEngine()
        
        # NO2: WHO limit = 200 μg/m³
        assert engine._normalize_pollutant('NO2', 200) == 1.0
        assert engine._normalize_pollutant('NO2', 100) == 0.5
        assert engine._normalize_pollutant('NO2', 0) == 0.0
        
        # PM10: WHO limit = 50 μg/m³
        assert engine._normalize_pollutant('PM10', 50) == 1.0
        assert engine._normalize_pollutant('PM10', 25) == 0.5
        
        # PM2.5: WHO limit = 25 μg/m³
        assert engine._normalize_pollutant('PM2.5', 25) == 1.0
        assert engine._normalize_pollutant('PM2.5', 12.5) == 0.5


# ============================================================================
# Health Impact Tests
# ============================================================================

class TestHealthImpact:
    """Tests para evaluación de impacto en salud"""
    
    def test_determine_health_impact(self):
        """Test determinación de impacto en salud"""
        engine = ScoringEngine()
        
        assert engine._determine_health_impact(10) == 'minimal'
        assert engine._determine_health_impact(25) == 'low'
        assert engine._determine_health_impact(45) == 'moderate'
        assert engine._determine_health_impact(65) == 'high'
        assert engine._determine_health_impact(85) == 'very_high'
    
    def test_get_recommendation_level(self):
        """Test nivel de recomendación"""
        engine = ScoringEngine()
        
        assert engine._get_recommendation_level(15) == 'excellent'
        assert engine._get_recommendation_level(35) == 'good'
        assert engine._get_recommendation_level(55) == 'moderate'
        assert engine._get_recommendation_level(85) == 'not_recommended'


# ============================================================================
# Route Comparison Tests
# ============================================================================

class TestRouteComparison:
    """Tests para comparación de rutas"""
    
    def test_compare_routes(self):
        """Test comparación de rutas"""
        engine = ScoringEngine()
        
        routes = [
            RouteScore(
                route_type='fastest',
                distance_meters=5000,
                duration_seconds=1200,
                geometry={},
                emission_score=45.0,
                pollutants={'NO2': 40, 'PM10': 25, 'PM2.5': 15},
                health_impact='moderate',
                recommendation_level='good',
                comparative_analysis={}
            ),
            RouteScore(
                route_type='shortest',
                distance_meters=4500,
                duration_seconds=1350,
                geometry={},
                emission_score=35.0,
                pollutants={'NO2': 30, 'PM10': 20, 'PM2.5': 10},
                health_impact='low',
                recommendation_level='excellent',
                comparative_analysis={}
            )
        ]
        
        comparison = engine.compare_routes(routes)
        
        assert 'best_air_quality' in comparison
        assert 'best_distance' in comparison
        assert 'best_time' in comparison
        assert 'overall_recommendation' in comparison
        
        # La ruta con menor emission_score debe ser mejor en calidad
        assert comparison['best_air_quality']['route_type'] == 'shortest'
    
    def test_sort_by_preference_air_quality(self):
        """Test ordenación por calidad del aire"""
        engine = ScoringEngine()
        
        routes = [
            RouteScore(
                route_type='fastest',
                distance_meters=5000,
                duration_seconds=1200,
                geometry={},
                emission_score=50.0,
                pollutants={},
                health_impact='moderate',
                recommendation_level='good',
                comparative_analysis={}
            ),
            RouteScore(
                route_type='eco',
                distance_meters=5500,
                duration_seconds=1400,
                geometry={},
                emission_score=30.0,
                pollutants={},
                health_impact='low',
                recommendation_level='excellent',
                comparative_analysis={}
            )
        ]
        
        sorted_routes = engine._sort_by_preference(routes, 'air_quality')
        
        # Primera ruta debe tener menor emission_score
        assert sorted_routes[0].emission_score < sorted_routes[1].emission_score
    
    def test_sort_by_preference_distance(self):
        """Test ordenación por distancia"""
        engine = ScoringEngine()
        
        routes = [
            RouteScore(
                route_type='fastest',
                distance_meters=5000,
                duration_seconds=1200,
                geometry={},
                emission_score=40.0,
                pollutants={},
                health_impact='moderate',
                recommendation_level='good',
                comparative_analysis={}
            ),
            RouteScore(
                route_type='shortest',
                distance_meters=4000,
                duration_seconds=1400,
                geometry={},
                emission_score=45.0,
                pollutants={},
                health_impact='moderate',
                recommendation_level='good',
                comparative_analysis={}
            )
        ]
        
        sorted_routes = engine._sort_by_preference(routes, 'distance')
        
        # Primera ruta debe tener menor distancia
        assert sorted_routes[0].distance_meters < sorted_routes[1].distance_meters
    
    def test_sort_by_preference_time(self):
        """Test ordenación por tiempo"""
        engine = ScoringEngine()
        
        routes = [
            RouteScore(
                route_type='fastest',
                distance_meters=5000,
                duration_seconds=1000,
                geometry={},
                emission_score=40.0,
                pollutants={},
                health_impact='moderate',
                recommendation_level='good',
                comparative_analysis={}
            ),
            RouteScore(
                route_type='eco',
                distance_meters=4500,
                duration_seconds=1500,
                geometry={},
                emission_score=30.0,
                pollutants={},
                health_impact='low',
                recommendation_level='excellent',
                comparative_analysis={}
            )
        ]
        
        sorted_routes = engine._sort_by_preference(routes, 'time')
        
        # Primera ruta debe tener menor duración
        assert sorted_routes[0].duration_seconds < sorted_routes[1].duration_seconds
    
    def test_sort_by_preference_balanced(self):
        """Test ordenación balanceada"""
        engine = ScoringEngine()
        
        routes = [
            RouteScore(
                route_type='fastest',
                distance_meters=5000,
                duration_seconds=1200,
                geometry={},
                emission_score=50.0,
                pollutants={},
                health_impact='moderate',
                recommendation_level='good',
                comparative_analysis={}
            ),
            RouteScore(
                route_type='eco',
                distance_meters=5200,
                duration_seconds=1300,
                geometry={},
                emission_score=30.0,
                pollutants={},
                health_impact='low',
                recommendation_level='excellent',
                comparative_analysis={}
            )
        ]
        
        sorted_routes = engine._sort_by_preference(routes, 'balanced')
        
        # Debe ordenar considerando múltiples factores
        assert len(sorted_routes) == 2


# ============================================================================
# Edge Cases Tests
# ============================================================================

class TestEdgeCases:
    """Tests para casos extremos"""
    
    def test_very_short_route(self):
        """Test ruta muy corta (< 200m)"""
        engine = ScoringEngine()
        
        route = {
            'geometry': {
                'type': 'LineString',
                'coordinates': [
                    [-3.7038, 40.4168],
                    [-3.7040, 40.4170]  # ~200m
                ]
            }
        }
        
        points = engine._sample_route_points(route, sample_distance=200)
        
        # Debe devolver al menos origen y destino
        assert len(points) >= 2
    
    def test_very_long_route(self):
        """Test ruta muy larga (> 10km)"""
        engine = ScoringEngine()
        
        route = {
            'geometry': {
                'type': 'LineString',
                'coordinates': [
                    [-3.7038, 40.4168],
                    [-3.6883, 40.4558]  # ~5km aprox
                ]
            }
        }
        
        points = engine._sample_route_points(route, sample_distance=200)
        
        # Con sample_distance=200m, ruta de 5km debe tener ~25 puntos
        assert len(points) > 20
    
    def test_extreme_pollution_values(self):
        """Test con valores extremos de contaminación"""
        engine = ScoringEngine()
        
        # Contaminación extremadamente alta
        high_score = engine._calculate_emission_score([
            {'NO2': 300, 'PM10': 100, 'PM2.5': 50}
        ])
        
        # Contaminación extremadamente baja
        low_score = engine._calculate_emission_score([
            {'NO2': 5, 'PM10': 3, 'PM2.5': 1}
        ])
        
        assert high_score > low_score
        assert 0 <= high_score <= 100
        assert 0 <= low_score <= 100


# ============================================================================
# Parametrized Tests
# ============================================================================

@pytest.mark.parametrize("emission_score,expected_level", [
    (10, 'excellent'),
    (25, 'excellent'),
    (30, 'good'),
    (45, 'good'),
    (50, 'moderate'),
    (65, 'moderate'),
    (70, 'not_recommended'),
    (90, 'not_recommended'),
])
def test_recommendation_levels(emission_score, expected_level):
    """Test niveles de recomendación parametrizados"""
    engine = ScoringEngine()
    level = engine._get_recommendation_level(emission_score)
    assert level == expected_level


@pytest.mark.parametrize("preference,expected_key", [
    ('air_quality', 'emission_score'),
    ('distance', 'distance_meters'),
    ('time', 'duration_seconds'),
    ('balanced', 'emission_score'),  # Balanced usa composite score
])
def test_sort_preferences(preference, expected_key):
    """Test que cada preferencia ordena correctamente"""
    engine = ScoringEngine()
    
    routes = [
        RouteScore(
            route_type='fastest',
            distance_meters=5000,
            duration_seconds=1200,
            geometry={},
            emission_score=50.0,
            pollutants={},
            health_impact='moderate',
            recommendation_level='good',
            comparative_analysis={}
        ),
        RouteScore(
            route_type='shortest',
            distance_meters=4500,
            duration_seconds=1350,
            geometry={},
            emission_score=40.0,
            pollutants={},
            health_impact='low',
            recommendation_level='excellent',
            comparative_analysis={}
        )
    ]
    
    sorted_routes = engine._sort_by_preference(routes, preference)
    
    if preference == 'balanced':
        # Balanced ordena por score compuesto
        assert len(sorted_routes) == 2
    else:
        # Verificar ordenación ascendente
        values = [getattr(r, expected_key) for r in sorted_routes]
        assert values == sorted(values)


# ============================================================================
# Performance Tests
# ============================================================================

@pytest.mark.asyncio
async def test_performance_multiple_routes(mock_air_quality_data):
    """Test rendimiento con múltiples rutas"""
    engine = ScoringEngine()
    
    # Generar 10 rutas de prueba
    routes = []
    for i in range(10):
        routes.append({
            'type': f'route_{i}',
            'distance_meters': 5000 + (i * 100),
            'duration_seconds': 1200 + (i * 60),
            'geometry': {
                'type': 'LineString',
                'coordinates': [
                    [-3.7038, 40.4168],
                    [-3.7070, 40.4200]
                ]
            }
        })
    
    with patch.object(
        AirQualityProvider, 'get_air_quality',
        new_callable=AsyncMock
    ) as mock_aq:
        mock_aq.return_value = mock_air_quality_data
        
        import time
        start = time.time()
        scored_routes = await engine.score_routes(routes, preference='balanced')
        duration = time.time() - start
        
        assert len(scored_routes) == 10
        # Debe completar en menos de 5 segundos
        assert duration < 5.0


# ============================================================================
# Run Tests
# ============================================================================

if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=utils.scoring_engine', '--cov-report=html'])
