"""
============================================================================
Scoring Engine Module
============================================================================
Algoritmo para calcular scores de emisiones de rutas ciclistas.

Considera:
- Exposición a contaminantes (NO₂, PM10, PM2.5) a lo largo de la ruta
- Distancia total
- Tiempo de viaje
- Preferencias del usuario (minimizar contaminación vs tiempo/distancia)

Usa interpolación IDW para estimar calidad del aire en cada punto
============================================================================
"""

import logging
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
from geopy.distance import geodesic

logger = logging.getLogger(__name__)


@dataclass
class RouteScore:
    """Resultado del scoring de una ruta"""
    route_type: str
    emission_score: float  # 0-100 (menor es mejor)
    distance_meters: int
    duration_seconds: int
    avg_no2: float
    avg_pm10: float
    avg_pm25: float
    exposure_index: float  # Índice combinado de exposición
    recommendation: str  # 'excellent', 'good', 'moderate', 'poor'
    health_impact: str  # Descripción del impacto en salud


class ScoringEngine:
    """Motor de cálculo de scores de emisiones"""
    
    # Pesos para diferentes contaminantes (basado en impacto en salud)
    POLLUTANT_WEIGHTS = {
        'no2': 0.30,   # Dióxido de nitrógeno
        'pm10': 0.30,  # Partículas < 10μm
        'pm25': 0.40   # Partículas < 2.5μm (más peligrosas)
    }
    
    # Límites diarios según OMS (μg/m³)
    WHO_LIMITS = {
        'no2': 200,   # 1 hora
        'pm10': 50,   # 24 horas
        'pm25': 25    # 24 horas
    }
    
    # Límites para categorización
    THRESHOLDS = {
        'excellent': 20,
        'good': 40,
        'moderate': 60,
        'poor': 80
    }
    
    def __init__(self, air_quality_provider):
        """
        Args:
            air_quality_provider: Instancia de AirQualityProvider
        """
        self.air_quality_provider = air_quality_provider
    
    async def score_routes(
        self,
        routes: List[Dict[str, Any]],
        preference: str = 'balanced'
    ) -> List[RouteScore]:
        """
        Calcula scores para múltiples rutas y las ordena según preferencia.
        
        Args:
            routes: Lista de rutas de Azure Maps
            preference: 'air_quality', 'distance', 'time', 'balanced'
            
        Returns:
            Lista de RouteScore ordenada por mejor opción
        """
        scored_routes = []
        
        for route in routes:
            try:
                score = await self._score_single_route(route)
                scored_routes.append(score)
            except Exception as e:
                logger.error(f"Error scoring route {route.get('type')}: {e}")
        
        # Ordenar según preferencia del usuario
        sorted_routes = self._sort_by_preference(scored_routes, preference)
        
        return sorted_routes
    
    async def _score_single_route(
        self, 
        route: Dict[str, Any]
    ) -> RouteScore:
        """Calcula score para una ruta individual"""
        
        geometry = route.get('geometry', {})
        coordinates = geometry.get('coordinates', [])
        
        if not coordinates:
            raise ValueError("Route has no coordinates")
        
        # Muestrear puntos a lo largo de la ruta (cada 200m aprox)
        sampled_points = self._sample_route_points(
            coordinates, 
            route['distance_meters']
        )
        
        # Obtener calidad del aire en cada punto
        air_quality_data = await self._get_air_quality_along_route(
            sampled_points
        )
        
        # Calcular promedios de contaminantes
        avg_pollutants = self._calculate_average_pollutants(air_quality_data)
        
        # Calcular índice de exposición (considera tiempo + concentración)
        exposure_index = self._calculate_exposure_index(
            avg_pollutants,
            route['duration_seconds']
        )
        
        # Calcular score final de emisiones (0-100)
        emission_score = self._calculate_emission_score(
            avg_pollutants,
            exposure_index
        )
        
        # Determinar recomendación
        recommendation = self._get_recommendation(emission_score)
        
        # Evaluar impacto en salud
        health_impact = self._assess_health_impact(
            avg_pollutants,
            route['duration_seconds']
        )
        
        return RouteScore(
            route_type=route['type'],
            emission_score=emission_score,
            distance_meters=route['distance_meters'],
            duration_seconds=route['duration_seconds'],
            avg_no2=avg_pollutants['no2'],
            avg_pm10=avg_pollutants['pm10'],
            avg_pm25=avg_pollutants['pm25'],
            exposure_index=exposure_index,
            recommendation=recommendation,
            health_impact=health_impact
        )
    
    def _sample_route_points(
        self,
        coordinates: List[List[float]],
        total_distance: int,
        sample_interval: int = 200
    ) -> List[Tuple[float, float]]:
        """
        Muestrea puntos a lo largo de la ruta.
        
        Args:
            coordinates: Lista de [lon, lat] en formato GeoJSON
            total_distance: Distancia total en metros
            sample_interval: Intervalo de muestreo en metros
            
        Returns:
            Lista de tuplas (lat, lon)
        """
        if len(coordinates) < 2:
            return [(coordinates[0][1], coordinates[0][0])]
        
        sampled = []
        num_samples = max(5, min(20, total_distance // sample_interval))
        
        # Muestreo uniforme
        step = len(coordinates) // num_samples
        if step == 0:
            step = 1
        
        for i in range(0, len(coordinates), step):
            lon, lat = coordinates[i]
            sampled.append((lat, lon))
        
        # Asegurar que incluimos inicio y fin
        if sampled[0] != (coordinates[0][1], coordinates[0][0]):
            sampled.insert(0, (coordinates[0][1], coordinates[0][0]))
        
        if sampled[-1] != (coordinates[-1][1], coordinates[-1][0]):
            sampled.append((coordinates[-1][1], coordinates[-1][0]))
        
        return sampled
    
    async def _get_air_quality_along_route(
        self,
        points: List[Tuple[float, float]]
    ) -> List[Dict[str, Any]]:
        """Obtiene calidad del aire para cada punto de la ruta"""
        air_quality_data = []
        
        for lat, lon in points:
            try:
                data = await self.air_quality_provider.get_air_quality(lat, lon)
                air_quality_data.append(data)
            except Exception as e:
                logger.warning(f"Error fetching air quality at ({lat}, {lon}): {e}")
                # Usar valores por defecto si falla
                air_quality_data.append({
                    'pollutants': {'NO2': 50, 'PM10': 35, 'PM2.5': 18},
                    'score': 50
                })
        
        return air_quality_data
    
    def _calculate_average_pollutants(
        self,
        air_quality_data: List[Dict[str, Any]]
    ) -> Dict[str, float]:
        """Calcula promedios de contaminantes a lo largo de la ruta"""
        if not air_quality_data:
            return {'no2': 50.0, 'pm10': 35.0, 'pm25': 18.0}
        
        total_no2 = 0
        total_pm10 = 0
        total_pm25 = 0
        count = 0
        
        for data in air_quality_data:
            pollutants = data.get('pollutants', {})
            if pollutants:
                total_no2 += pollutants.get('NO2', 0)
                total_pm10 += pollutants.get('PM10', 0)
                total_pm25 += pollutants.get('PM2.5', 0)
                count += 1
        
        if count == 0:
            return {'no2': 50.0, 'pm10': 35.0, 'pm25': 18.0}
        
        return {
            'no2': round(total_no2 / count, 2),
            'pm10': round(total_pm10 / count, 2),
            'pm25': round(total_pm25 / count, 2)
        }
    
    def _calculate_exposure_index(
        self,
        pollutants: Dict[str, float],
        duration_seconds: int
    ) -> float:
        """
        Calcula índice de exposición considerando concentración y tiempo.
        
        Índice = Σ(concentración_i × peso_i) × factor_tiempo
        """
        # Factor tiempo (más tiempo = más exposición)
        duration_minutes = duration_seconds / 60
        time_factor = 1 + (duration_minutes / 60)  # +100% por cada hora
        
        # Calcular exposición ponderada
        normalized_no2 = pollutants['no2'] / self.WHO_LIMITS['no2']
        normalized_pm10 = pollutants['pm10'] / self.WHO_LIMITS['pm10']
        normalized_pm25 = pollutants['pm25'] / self.WHO_LIMITS['pm25']
        
        weighted_exposure = (
            normalized_no2 * self.POLLUTANT_WEIGHTS['no2'] +
            normalized_pm10 * self.POLLUTANT_WEIGHTS['pm10'] +
            normalized_pm25 * self.POLLUTANT_WEIGHTS['pm25']
        )
        
        exposure_index = weighted_exposure * time_factor * 100
        
        return round(min(100, exposure_index), 2)
    
    def _calculate_emission_score(
        self,
        pollutants: Dict[str, float],
        exposure_index: float
    ) -> float:
        """
        Calcula score final de emisiones (0-100, menor es mejor).
        
        Combina niveles absolutos de contaminantes con índice de exposición.
        """
        # Normalizar cada contaminante respecto a límites OMS
        no2_score = min(100, (pollutants['no2'] / self.WHO_LIMITS['no2']) * 100)
        pm10_score = min(100, (pollutants['pm10'] / self.WHO_LIMITS['pm10']) * 100)
        pm25_score = min(100, (pollutants['pm25'] / self.WHO_LIMITS['pm25']) * 100)
        
        # Promedio ponderado de contaminantes
        pollutant_score = (
            no2_score * self.POLLUTANT_WEIGHTS['no2'] +
            pm10_score * self.POLLUTANT_WEIGHTS['pm10'] +
            pm25_score * self.POLLUTANT_WEIGHTS['pm25']
        )
        
        # Combinar con índice de exposición (60% contaminantes, 40% exposición)
        final_score = (pollutant_score * 0.6) + (exposure_index * 0.4)
        
        return round(final_score, 2)
    
    def _get_recommendation(self, emission_score: float) -> str:
        """Determina nivel de recomendación según score"""
        if emission_score < self.THRESHOLDS['excellent']:
            return 'excellent'
        elif emission_score < self.THRESHOLDS['good']:
            return 'good'
        elif emission_score < self.THRESHOLDS['moderate']:
            return 'moderate'
        else:
            return 'poor'
    
    def _assess_health_impact(
        self,
        pollutants: Dict[str, float],
        duration_seconds: int
    ) -> str:
        """Evalúa impacto en salud de la ruta"""
        duration_minutes = duration_seconds / 60
        
        # Determinar nivel de riesgo
        no2_risk = pollutants['no2'] / self.WHO_LIMITS['no2']
        pm25_risk = pollutants['pm25'] / self.WHO_LIMITS['pm25']
        
        max_risk = max(no2_risk, pm25_risk)
        
        if max_risk < 0.2:
            if duration_minutes < 30:
                return "Exposición mínima. Ruta muy saludable para ciclismo."
            else:
                return "Exposición baja. Ruta recomendable para ejercicio prolongado."
        
        elif max_risk < 0.5:
            if duration_minutes < 20:
                return "Exposición moderada. Aceptable para trayectos cortos."
            else:
                return "Exposición moderada. Considere alternar con rutas más limpias."
        
        elif max_risk < 0.8:
            if duration_minutes < 15:
                return "Exposición elevada. Aceptable solo para trayectos muy cortos."
            else:
                return "Exposición elevada. Se recomienda buscar ruta alternativa si es posible."
        
        else:
            return "Exposición muy alta. Se recomienda evitar esta ruta, especialmente en horas punta."
    
    def _sort_by_preference(
        self,
        routes: List[RouteScore],
        preference: str
    ) -> List[RouteScore]:
        """Ordena rutas según preferencia del usuario"""
        
        if preference == 'air_quality':
            # Ordenar por menor score de emisiones
            return sorted(routes, key=lambda r: r.emission_score)
        
        elif preference == 'distance':
            # Ordenar por menor distancia, con peso en calidad del aire
            return sorted(
                routes, 
                key=lambda r: r.distance_meters + (r.emission_score * 10)
            )
        
        elif preference == 'time':
            # Ordenar por menor tiempo, con peso en calidad del aire
            return sorted(
                routes,
                key=lambda r: r.duration_seconds + (r.emission_score * 5)
            )
        
        else:  # 'balanced'
            # Balance entre distancia, tiempo y calidad del aire
            return sorted(
                routes,
                key=lambda r: (
                    (r.distance_meters / 1000) * 0.3 +
                    (r.duration_seconds / 60) * 0.3 +
                    r.emission_score * 0.4
                )
            )
    
    def compare_routes(
        self,
        routes: List[RouteScore]
    ) -> Dict[str, Any]:
        """
        Compara múltiples rutas y genera recomendación.
        
        Returns:
            Dict con análisis comparativo y recomendación final
        """
        if not routes:
            return {'error': 'No routes to compare'}
        
        # Encontrar mejor y peor en cada categoría
        best_air = min(routes, key=lambda r: r.emission_score)
        best_distance = min(routes, key=lambda r: r.distance_meters)
        best_time = min(routes, key=lambda r: r.duration_seconds)
        
        # Ruta recomendada (balanced)
        recommended = self._sort_by_preference(routes, 'balanced')[0]
        
        # Calcular diferencias
        comparisons = []
        for route in routes:
            comparison = {
                'type': route.route_type,
                'emission_score': route.emission_score,
                'distance_km': round(route.distance_meters / 1000, 2),
                'duration_min': round(route.duration_seconds / 60, 1),
                'recommendation': route.recommendation,
                'health_impact': route.health_impact,
                'is_best_air': route == best_air,
                'is_best_distance': route == best_distance,
                'is_best_time': route == best_time,
                'is_recommended': route == recommended
            }
            comparisons.append(comparison)
        
        return {
            'recommended_route': recommended.route_type,
            'routes': comparisons,
            'summary': {
                'best_for_air_quality': best_air.route_type,
                'best_for_distance': best_distance.route_type,
                'best_for_time': best_time.route_type,
                'air_quality_difference': round(
                    max(r.emission_score for r in routes) - 
                    min(r.emission_score for r in routes),
                    2
                )
            }
        }
