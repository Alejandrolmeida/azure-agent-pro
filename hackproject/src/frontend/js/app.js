/**
 * ============================================================================
 * Main Application Module
 * ============================================================================
 * Punto de entrada principal que orquesta todos los módulos:
 * - Inicializa map, UI y API client
 * - Coordina flujo de datos entre módulos
 * - Maneja eventos globales
 * - Gestiona estado de la aplicación
 * ============================================================================
 */

/**
 * Main Application Class
 */
class Application {
  constructor() {
    this.initialized = false;
    this.config = {
      defaultRadius: 2.0,
      defaultMaxStations: 10
    };
  }

  /**
   * Inicializar aplicación
   */
  async initialize() {
    if (this.initialized) {
      console.warn('Application already initialized');
      return;
    }

    try {
      console.log('🚀 Initializing BiciMAD Low Emission Router...');

      // Verificar que los módulos estén disponibles
      this._checkDependencies();

      // Inicializar módulos
      this._initializeModules();

      // Registrar event listeners globales
      this._registerGlobalEvents();

      // Health check del backend
      await this._performHealthCheck();

      // Cargar estaciones iniciales
      await this._loadInitialStations();

      this.initialized = true;
      console.log('✅ Application initialized successfully');

    } catch (error) {
      console.error('❌ Failed to initialize application:', error);
      window.uiController.showError(
        'Error al inicializar la aplicación',
        error.message
      );
    }
  }

  /**
   * Verificar dependencias
   */
  _checkDependencies() {
    const required = ['mapManager', 'uiController', 'apiClient', 'loadingManager'];
    const missing = required.filter(dep => !window[dep]);

    if (missing.length > 0) {
      throw new Error(`Missing dependencies: ${missing.join(', ')}`);
    }
  }

  /**
   * Inicializar módulos
   */
  _initializeModules() {
    // Inicializar mapa
    window.mapManager.initialize();

    // Inicializar UI controller
    window.uiController.initialize();

    console.log('📦 Modules initialized');
  }

  /**
   * Registrar event listeners globales
   */
  _registerGlobalEvents() {
    // Click en mapa para seleccionar origen/destino
    window.addEventListener('mapclick', (e) => {
      this._handleMapClick(e.detail);
    });

    // Calcular ruta desde formulario
    window.addEventListener('calculateroute', (e) => {
      this._handleCalculateRoute(e.detail);
    });

    // Selección de ruta en el mapa
    window.addEventListener('routeselected', (e) => {
      this._handleRouteSelected(e.detail);
    });

    // Limpiar todo
    window.addEventListener('clearall', () => {
      this._handleClearAll();
    });

    console.log('🔗 Event listeners registered');
  }

  /**
   * Realizar health check del backend
   */
  async _performHealthCheck() {
    try {
      const health = await window.apiClient.healthCheck();
      console.log('💚 Backend health check:', health);
      
      if (health.status !== 'healthy') {
        throw new Error('Backend not healthy');
      }
    } catch (error) {
      console.warn('⚠️ Backend health check failed:', error);
      window.uiController.showInfo(
        'Modo offline: Usando datos simulados para demostración'
      );
    }
  }

  /**
   * Cargar estaciones iniciales centradas en Madrid
   */
  async _loadInitialStations() {
    try {
      const center = window.mapManager.getCenter();
      
      await window.loadingManager.withLoading(async () => {
        const data = await window.apiClient.getNearbyStations(
          center.lat,
          center.lon,
          this.config.defaultRadius,
          this.config.defaultMaxStations
        );

        if (data.stations && data.stations.length > 0) {
          window.mapManager.displayStations(data.stations);
          console.log(`📍 Loaded ${data.stations.length} stations`);
        }
      }, 'Cargando estaciones BiciMAD...');

    } catch (error) {
      console.warn('Could not load initial stations:', error);
      // No mostrar error al usuario, es opcional
    }
  }

  /**
   * Handler de click en mapa
   */
  _handleMapClick(coords) {
    const state = window.uiController.getState();

    // Si no hay origen, establecer origen
    if (!state.origin) {
      window.uiController.setOrigin(coords.lat, coords.lng);
      window.mapManager.setOrigin(coords.lat, coords.lng);
      window.uiController.showInfo('Origen establecido. Ahora selecciona destino.');
      return;
    }

    // Si hay origen pero no destino, establecer destino
    if (!state.destination) {
      window.uiController.setDestination(coords.lat, coords.lng);
      window.mapManager.setDestination(coords.lat, coords.lng);
      window.uiController.showInfo('Destino establecido. ¡Listo para calcular ruta!');
      return;
    }

    // Si ya hay ambos, actualizar destino
    window.uiController.setDestination(coords.lat, coords.lng);
    window.mapManager.setDestination(coords.lat, coords.lng);
  }

  /**
   * Handler de calcular ruta
   */
  async _handleCalculateRoute({ origin, destination, preference }) {
    try {
      console.log('🔄 Calculating route...', { origin, destination, preference });

      // Marcar origen y destino en el mapa
      window.mapManager.setOrigin(origin.lat, origin.lon);
      window.mapManager.setDestination(destination.lat, destination.lon);

      // Calcular rutas
      const data = await window.loadingManager.withLoading(async () => {
        return await window.apiClient.calculateRoute(origin, destination, preference);
      }, 'Calculando rutas óptimas...');

      console.log('✅ Routes calculated:', data);

      // Mostrar rutas en el mapa
      if (data.routes && data.routes.length > 0) {
        window.mapManager.displayRoutes(data.routes);
        window.uiController.displayResults(data);
        
        window.uiController.showInfo(
          `Ruta recomendada: ${this._getRouteTypeLabel(data.recommended_route)}`
        );
      } else {
        throw new Error('No se encontraron rutas');
      }

    } catch (error) {
      console.error('Error calculating route:', error);
      
      let errorMessage = 'Error al calcular la ruta';
      let errorDetails = error.message;

      if (error.getUserMessage) {
        errorMessage = error.getUserMessage();
        errorDetails = null;
      }

      window.uiController.showError(errorMessage, errorDetails);
    }
  }

  /**
   * Handler de selección de ruta
   */
  _handleRouteSelected({ route, index }) {
    console.log('Route selected:', route);
    
    // Aquí podrías añadir lógica adicional, como:
    // - Highlight de la ruta seleccionada
    // - Mostrar más detalles en un modal
    // - Analytics tracking
  }

  /**
   * Handler de limpiar todo
   */
  _handleClearAll() {
    console.log('🧹 Clearing all...');
    
    // Limpiar mapa
    window.mapManager.clearAll();
    
    // Recargar estaciones iniciales
    this._loadInitialStations();
  }

  /**
   * Obtener label amigable para tipo de ruta
   */
  _getRouteTypeLabel(type) {
    const labels = {
      'fastest': 'Ruta Rápida',
      'shortest': 'Ruta Corta',
      'eco': 'Ruta Ecológica',
      'balanced': 'Ruta Equilibrada'
    };
    return labels[type] || type;
  }

  /**
   * Actualizar estaciones cercanas a un punto
   */
  async updateNearbyStations(lat, lon, radius = null) {
    try {
      const searchRadius = radius || this.config.defaultRadius;
      
      const data = await window.apiClient.getNearbyStations(
        lat,
        lon,
        searchRadius,
        this.config.defaultMaxStations
      );

      if (data.stations && data.stations.length > 0) {
        window.mapManager.displayStations(data.stations);
        console.log(`📍 Updated ${data.stations.length} stations`);
      }

    } catch (error) {
      console.error('Error updating stations:', error);
    }
  }

  /**
   * Obtener calidad del aire en punto
   */
  async getAirQualityAtPoint(lat, lon) {
    try {
      const data = await window.loadingManager.withLoading(async () => {
        return await window.apiClient.getAirQuality(lat, lon);
      }, 'Consultando calidad del aire...');

      console.log('Air quality data:', data);

      // Mostrar en modal o UI
      const content = this._formatAirQualityData(data);
      window.uiController.showModal('Calidad del Aire', content);

    } catch (error) {
      console.error('Error getting air quality:', error);
      window.uiController.showError('Error al consultar calidad del aire');
    }
  }

  /**
   * Formatear datos de calidad del aire para display
   */
  _formatAirQualityData(data) {
    const levelLabels = {
      'good': '✅ Buena',
      'moderate': '⚠️ Moderada',
      'unhealthy_sensitive': '🔶 Poco saludable para grupos sensibles',
      'unhealthy': '🔴 Poco saludable'
    };

    const levelLabel = levelLabels[data.level] || data.level;

    return `
      <div style="padding: 1rem;">
        <h3 style="margin-bottom: 1rem;">${levelLabel}</h3>
        
        <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 1.5rem;">
          <div style="text-align: center; padding: 1rem; background: #f8fafc; border-radius: 0.5rem;">
            <div style="font-size: 1.5rem; font-weight: bold; color: #2563eb;">
              ${data.pollutants.NO2.toFixed(1)}
            </div>
            <div style="font-size: 0.75rem; color: #64748b;">NO₂ (μg/m³)</div>
          </div>
          <div style="text-align: center; padding: 1rem; background: #f8fafc; border-radius: 0.5rem;">
            <div style="font-size: 1.5rem; font-weight: bold; color: #2563eb;">
              ${data.pollutants.PM10.toFixed(1)}
            </div>
            <div style="font-size: 0.75rem; color: #64748b;">PM10 (μg/m³)</div>
          </div>
          <div style="text-align: center; padding: 1rem; background: #f8fafc; border-radius: 0.5rem;">
            <div style="font-size: 1.5rem; font-weight: bold; color: #2563eb;">
              ${data.pollutants['PM2.5'].toFixed(1)}
            </div>
            <div style="font-size: 0.75rem; color: #64748b;">PM2.5 (μg/m³)</div>
          </div>
        </div>

        <div style="background: #eff6ff; padding: 1rem; border-radius: 0.5rem; border-left: 3px solid #2563eb;">
          <strong>Score de calidad:</strong> ${data.score}/100<br>
          <strong>Ubicación:</strong> Lat ${data.location.lat.toFixed(4)}, Lon ${data.location.lon.toFixed(4)}
        </div>

        ${data.nearest_stations ? `
          <div style="margin-top: 1rem; font-size: 0.875rem; color: #64748b;">
            <strong>Estaciones de referencia:</strong><br>
            ${data.nearest_stations.map(s => `• ${s.name}`).join('<br>')}
          </div>
        ` : ''}
      </div>
    `;
  }

  /**
   * Verificar si aplicación está inicializada
   */
  isInitialized() {
    return this.initialized;
  }
}

// ============================================================================
// Application Instance & Auto-initialization
// ============================================================================

const app = new Application();

// Auto-inicializar cuando DOM esté listo
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    app.initialize();
  });
} else {
  // DOM ya está listo
  app.initialize();
}

// Exponer en window para debugging
if (typeof window !== 'undefined') {
  window.app = app;
}

// Para uso con ES6 modules
export { app, Application };
export default app;
