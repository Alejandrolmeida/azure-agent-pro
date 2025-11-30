/**
 * ============================================================================
 * Map Module - Leaflet Integration
 * ============================================================================
 * Gestión del mapa interactivo con Leaflet.js:
 * - Inicialización del mapa centrado en Madrid
 * - Markers para estaciones BiciMAD
 * - Visualización de rutas con colores según calidad del aire
 * - Popups informativos
 * - Layers de calidad del aire
 * ============================================================================
 */

// Configuración del mapa
const MAP_CONFIG = {
  center: [40.4168, -3.7038], // Centro de Madrid (Puerta del Sol)
  zoom: 13,
  minZoom: 11,
  maxZoom: 18,
  attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
};

// Colores para rutas según calidad del aire
const ROUTE_COLORS = {
  excellent: '#10b981',  // Verde
  good: '#84cc16',       // Verde claro
  moderate: '#f59e0b',   // Naranja
  poor: '#ef4444',       // Rojo
  default: '#2563eb'     // Azul
};

// Iconos personalizados para markers
const MARKER_ICONS = {
  station: L.icon({
    iconUrl: 'data:image/svg+xml;base64,' + btoa(`
      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
        <circle cx="16" cy="16" r="14" fill="#2563eb" stroke="white" stroke-width="3"/>
        <text x="16" y="21" text-anchor="middle" font-size="18" fill="white" font-family="Arial">🚲</text>
      </svg>
    `),
    iconSize: [32, 32],
    iconAnchor: [16, 32],
    popupAnchor: [0, -32]
  }),
  
  origin: L.icon({
    iconUrl: 'data:image/svg+xml;base64,' + btoa(`
      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="40" viewBox="0 0 32 40">
        <path d="M16 0 C7 0 0 7 0 16 C0 24 16 40 16 40 S32 24 32 16 C32 7 25 0 16 0 Z" 
              fill="#10b981" stroke="white" stroke-width="2"/>
        <circle cx="16" cy="16" r="6" fill="white"/>
        <text x="16" y="20" text-anchor="middle" font-size="10" fill="#10b981" font-weight="bold">A</text>
      </svg>
    `),
    iconSize: [32, 40],
    iconAnchor: [16, 40],
    popupAnchor: [0, -40]
  }),
  
  destination: L.icon({
    iconUrl: 'data:image/svg+xml;base64,' + btoa(`
      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="40" viewBox="0 0 32 40">
        <path d="M16 0 C7 0 0 7 0 16 C0 24 16 40 16 40 S32 24 32 16 C32 7 25 0 16 0 Z" 
              fill="#ef4444" stroke="white" stroke-width="2"/>
        <circle cx="16" cy="16" r="6" fill="white"/>
        <text x="16" y="20" text-anchor="middle" font-size="10" fill="#ef4444" font-weight="bold">B</text>
      </svg>
    `),
    iconSize: [32, 40],
    iconAnchor: [16, 40],
    popupAnchor: [0, -40]
  })
};

/**
 * Map Manager Class
 */
class MapManager {
  constructor(containerId) {
    this.containerId = containerId;
    this.map = null;
    this.layers = {
      stations: L.layerGroup(),
      routes: L.layerGroup(),
      markers: L.layerGroup()
    };
    this.currentRoutes = [];
    this.currentStations = [];
  }

  /**
   * Inicializar mapa
   */
  initialize() {
    if (this.map) {
      console.warn('Map already initialized');
      return;
    }

    // Crear mapa
    this.map = L.map(this.containerId, {
      center: MAP_CONFIG.center,
      zoom: MAP_CONFIG.zoom,
      minZoom: MAP_CONFIG.minZoom,
      maxZoom: MAP_CONFIG.maxZoom,
      zoomControl: true
    });

    // Añadir tile layer (OpenStreetMap)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: MAP_CONFIG.attribution,
      maxZoom: MAP_CONFIG.maxZoom
    }).addTo(this.map);

    // Añadir layers al mapa
    Object.values(this.layers).forEach(layer => layer.addTo(this.map));

    // Event listeners del mapa
    this.map.on('click', (e) => {
      console.log('Map clicked:', e.latlng);
      this._onMapClick(e.latlng);
    });

    console.log('Map initialized');
  }

  /**
   * Handler de click en mapa (para seleccionar origen/destino)
   */
  _onMapClick(latlng) {
    // Disparar evento custom para que app.js lo maneje
    const event = new CustomEvent('mapclick', {
      detail: {
        lat: latlng.lat,
        lng: latlng.lng
      }
    });
    window.dispatchEvent(event);
  }

  /**
   * Mostrar estaciones BiciMAD en el mapa
   */
  displayStations(stations) {
    // Limpiar estaciones anteriores
    this.layers.stations.clearLayers();
    this.currentStations = stations;

    stations.forEach(station => {
      const marker = L.marker(
        [station.latitude, station.longitude],
        { icon: MARKER_ICONS.station }
      );

      // Popup con información de la estación
      const popupContent = this._createStationPopup(station);
      marker.bindPopup(popupContent);

      // Añadir a layer
      marker.addTo(this.layers.stations);
    });

    console.log(`Displayed ${stations.length} stations`);
  }

  /**
   * Crear HTML para popup de estación
   */
  _createStationPopup(station) {
    const availabilityPercentage = station.total_bases > 0
      ? Math.round((station.dock_bikes / station.total_bases) * 100)
      : 0;

    return `
      <div class="station-popup">
        <h3>🚲 ${station.name}</h3>
        <div class="station-popup-info">
          <div><strong>Bicis disponibles:</strong></div>
          <div>${station.dock_bikes}</div>
          <div><strong>Bases libres:</strong></div>
          <div>${station.free_bases}</div>
          <div><strong>Total bases:</strong></div>
          <div>${station.total_bases}</div>
          <div><strong>Disponibilidad:</strong></div>
          <div>${availabilityPercentage}%</div>
          ${station.distance_km ? `
            <div><strong>Distancia:</strong></div>
            <div>${station.distance_km.toFixed(2)} km</div>
          ` : ''}
        </div>
      </div>
    `;
  }

  /**
   * Marcar origen en el mapa
   */
  setOrigin(lat, lon, label = 'Origen') {
    this.clearOrigin();
    
    const marker = L.marker([lat, lon], { icon: MARKER_ICONS.origin });
    marker.bindPopup(`<strong>${label}</strong><br>Lat: ${lat.toFixed(4)}, Lon: ${lon.toFixed(4)}`);
    marker.addTo(this.layers.markers);
    
    this.originMarker = marker;
  }

  /**
   * Marcar destino en el mapa
   */
  setDestination(lat, lon, label = 'Destino') {
    this.clearDestination();
    
    const marker = L.marker([lat, lon], { icon: MARKER_ICONS.destination });
    marker.bindPopup(`<strong>${label}</strong><br>Lat: ${lat.toFixed(4)}, Lon: ${lon.toFixed(4)}`);
    marker.addTo(this.layers.markers);
    
    this.destinationMarker = marker;
  }

  /**
   * Limpiar marker de origen
   */
  clearOrigin() {
    if (this.originMarker) {
      this.layers.markers.removeLayer(this.originMarker);
      this.originMarker = null;
    }
  }

  /**
   * Limpiar marker de destino
   */
  clearDestination() {
    if (this.destinationMarker) {
      this.layers.markers.removeLayer(this.destinationMarker);
      this.destinationMarker = null;
    }
  }

  /**
   * Visualizar rutas en el mapa
   */
  displayRoutes(routes) {
    // Limpiar rutas anteriores
    this.layers.routes.clearLayers();
    this.currentRoutes = routes;

    routes.forEach((route, index) => {
      if (!route.geometry || !route.geometry.coordinates) {
        console.warn('Route missing geometry:', route);
        return;
      }

      // Convertir coordenadas GeoJSON [lon, lat] a Leaflet [lat, lon]
      const latlngs = route.geometry.coordinates.map(coord => [coord[1], coord[0]]);

      // Color según calidad del aire
      const color = ROUTE_COLORS[route.recommendation] || ROUTE_COLORS.default;
      const opacity = route.is_recommended ? 1.0 : 0.6;
      const weight = route.is_recommended ? 6 : 4;

      // Crear polyline
      const polyline = L.polyline(latlngs, {
        color: color,
        weight: weight,
        opacity: opacity,
        lineJoin: 'round'
      });

      // Popup con información de la ruta
      const popupContent = this._createRoutePopup(route);
      polyline.bindPopup(popupContent);

      // Event listeners
      polyline.on('mouseover', () => {
        polyline.setStyle({ weight: weight + 2, opacity: 1.0 });
      });

      polyline.on('mouseout', () => {
        polyline.setStyle({ weight: weight, opacity: opacity });
      });

      polyline.on('click', () => {
        // Disparar evento para mostrar detalles de ruta
        const event = new CustomEvent('routeselected', {
          detail: { route, index }
        });
        window.dispatchEvent(event);
      });

      // Añadir al mapa
      polyline.addTo(this.layers.routes);

      // Si es la ruta recomendada, hacer zoom a ella
      if (index === 0 || route.is_recommended) {
        this.fitBounds(latlngs);
      }
    });

    console.log(`Displayed ${routes.length} routes`);
  }

  /**
   * Crear HTML para popup de ruta
   */
  _createRoutePopup(route) {
    const badgeClass = `badge-${route.recommendation}`;
    
    return `
      <div class="route-popup">
        <h3>Ruta ${route.type}</h3>
        <span class="route-badge ${badgeClass}">${route.recommendation}</span>
        <div style="margin-top: 10px;">
          <div><strong>📏 Distancia:</strong> ${route.distance_km} km</div>
          <div><strong>⏱️ Duración:</strong> ${route.duration_min} min</div>
          <div><strong>🌫️ Score emisiones:</strong> ${route.emission_score}/100</div>
          <div><strong>💨 NO₂:</strong> ${route.pollutants.NO2.toFixed(1)} μg/m³</div>
          <div><strong>🌬️ PM10:</strong> ${route.pollutants.PM10.toFixed(1)} μg/m³</div>
          <div><strong>🌪️ PM2.5:</strong> ${route.pollutants['PM2.5'].toFixed(1)} μg/m³</div>
        </div>
        ${route.is_recommended ? '<p style="margin-top:10px;">⭐ <strong>Ruta Recomendada</strong></p>' : ''}
      </div>
    `;
  }

  /**
   * Hacer zoom para mostrar todas las coordenadas
   */
  fitBounds(latlngs, padding = [50, 50]) {
    if (!latlngs || latlngs.length === 0) return;
    
    const bounds = L.latLngBounds(latlngs);
    this.map.fitBounds(bounds, { padding: padding });
  }

  /**
   * Centrar mapa en ubicación
   */
  centerOn(lat, lon, zoom = 15) {
    this.map.setView([lat, lon], zoom);
  }

  /**
   * Limpiar todas las rutas
   */
  clearRoutes() {
    this.layers.routes.clearLayers();
    this.currentRoutes = [];
  }

  /**
   * Limpiar todas las estaciones
   */
  clearStations() {
    this.layers.stations.clearLayers();
    this.currentStations = [];
  }

  /**
   * Limpiar todos los markers
   */
  clearMarkers() {
    this.layers.markers.clearLayers();
    this.originMarker = null;
    this.destinationMarker = null;
  }

  /**
   * Limpiar todo el mapa
   */
  clearAll() {
    this.clearRoutes();
    this.clearStations();
    this.clearMarkers();
  }

  /**
   * Obtener bounds actual del mapa
   */
  getBounds() {
    return this.map.getBounds();
  }

  /**
   * Obtener centro actual del mapa
   */
  getCenter() {
    const center = this.map.getCenter();
    return {
      lat: center.lat,
      lon: center.lng
    };
  }

  /**
   * Obtener zoom actual
   */
  getZoom() {
    return this.map.getZoom();
  }

  /**
   * Verificar si mapa está inicializado
   */
  isInitialized() {
    return this.map !== null;
  }

  /**
   * Destruir mapa (cleanup)
   */
  destroy() {
    if (this.map) {
      this.map.remove();
      this.map = null;
    }
  }
}

// ============================================================================
// Export singleton instance
// ============================================================================

const mapManager = new MapManager('map');

// Para uso en HTML sin modules
if (typeof window !== 'undefined') {
  window.mapManager = mapManager;
}

// Para uso con ES6 modules
export { mapManager, MapManager };
export default mapManager;
