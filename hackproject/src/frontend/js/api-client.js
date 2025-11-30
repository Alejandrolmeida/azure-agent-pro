/**
 * ============================================================================
 * API Client Module
 * ============================================================================
 * Cliente HTTP para comunicación con Azure Functions backend
 * Maneja todas las peticiones, loading states, error handling y retry logic
 * ============================================================================
 */

const API_BASE_URL = '/api';  // Azure Static Web Apps auto-proxy
const DEFAULT_TIMEOUT = 15000; // 15 segundos

/**
 * API Client con manejo de errores y loading states
 */
class APIClient {
  constructor(baseURL = API_BASE_URL) {
    this.baseURL = baseURL;
    this.activeRequests = new Set();
  }

  /**
   * Petición GET genérica
   */
  async get(endpoint, params = {}) {
    const url = new URL(`${this.baseURL}${endpoint}`, window.location.origin);
    
    // Añadir query params
    Object.keys(params).forEach(key => {
      if (params[key] !== undefined && params[key] !== null) {
        url.searchParams.append(key, params[key]);
      }
    });

    const requestId = `GET:${endpoint}`;
    this.activeRequests.add(requestId);

    try {
      const response = await fetch(url.toString(), {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        },
        signal: AbortSignal.timeout(DEFAULT_TIMEOUT)
      });

      if (!response.ok) {
        throw new APIError(
          `HTTP ${response.status}: ${response.statusText}`,
          response.status,
          await this._parseError(response)
        );
      }

      const data = await response.json();
      return data;

    } catch (error) {
      if (error.name === 'AbortError') {
        throw new APIError('Request timeout', 408, { message: 'La petición tardó demasiado' });
      }
      if (error instanceof APIError) {
        throw error;
      }
      throw new APIError('Network error', 0, { message: error.message });
      
    } finally {
      this.activeRequests.delete(requestId);
    }
  }

  /**
   * Petición POST genérica
   */
  async post(endpoint, body = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const requestId = `POST:${endpoint}`;
    this.activeRequests.add(requestId);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(DEFAULT_TIMEOUT * 2) // Más tiempo para POST
      });

      if (!response.ok) {
        throw new APIError(
          `HTTP ${response.status}: ${response.statusText}`,
          response.status,
          await this._parseError(response)
        );
      }

      const data = await response.json();
      return data;

    } catch (error) {
      if (error.name === 'AbortError') {
        throw new APIError('Request timeout', 408, { message: 'La petición tardó demasiado' });
      }
      if (error instanceof APIError) {
        throw error;
      }
      throw new APIError('Network error', 0, { message: error.message });
      
    } finally {
      this.activeRequests.delete(requestId);
    }
  }

  /**
   * Parse error response
   */
  async _parseError(response) {
    try {
      const data = await response.json();
      return data;
    } catch {
      return { message: response.statusText };
    }
  }

  /**
   * Verifica si hay peticiones activas
   */
  hasActivePeticiones() {
    return this.activeRequests.size > 0;
  }

  // ============================================================================
  // API Endpoints Específicos
  // ============================================================================

  /**
   * Health check
   */
  async healthCheck() {
    return this.get('/health');
  }

  /**
   * Obtener estaciones BiciMAD cercanas
   * 
   * @param {number} lat - Latitud
   * @param {number} lon - Longitud
   * @param {number} radius - Radio en km (default: 2.0)
   * @param {number} maxResults - Máximo de resultados (default: 10)
   */
  async getNearbyStations(lat, lon, radius = 2.0, maxResults = 10) {
    return this.get('/stations', { lat, lon, radius, max_results: maxResults });
  }

  /**
   * Obtener calidad del aire en ubicación
   * 
   * @param {number} lat - Latitud
   * @param {number} lon - Longitud
   */
  async getAirQuality(lat, lon) {
    return this.get('/air-quality', { lat, lon });
  }

  /**
   * Calcular rutas optimizadas
   * 
   * @param {Object} origin - {lat, lon}
   * @param {Object} destination - {lat, lon}
   * @param {string} preference - 'air_quality' | 'distance' | 'time' | 'balanced'
   */
  async calculateRoute(origin, destination, preference = 'balanced') {
    return this.post('/calculate-route', {
      origin,
      destination,
      preference
    });
  }
}

/**
 * Custom API Error class
 */
class APIError extends Error {
  constructor(message, statusCode, details = {}) {
    super(message);
    this.name = 'APIError';
    this.statusCode = statusCode;
    this.details = details;
  }

  getUserMessage() {
    // Mensajes amigables para usuarios
    if (this.statusCode === 0) {
      return 'No se pudo conectar con el servidor. Verifica tu conexión a internet.';
    }
    if (this.statusCode === 400) {
      return this.details.message || 'Los datos proporcionados son inválidos.';
    }
    if (this.statusCode === 404) {
      return 'No se encontraron resultados para tu búsqueda.';
    }
    if (this.statusCode === 408) {
      return 'La petición tardó demasiado. Inténtalo de nuevo.';
    }
    if (this.statusCode >= 500) {
      return 'Error en el servidor. Inténtalo de nuevo más tarde.';
    }
    return this.details.message || 'Ha ocurrido un error inesperado.';
  }
}

// ============================================================================
// Loading State Manager
// ============================================================================

class LoadingManager {
  constructor() {
    this.loadingCount = 0;
    this.overlay = null;
  }

  /**
   * Mostrar loading overlay
   */
  show(message = 'Cargando...') {
    this.loadingCount++;
    
    if (!this.overlay) {
      this.overlay = document.createElement('div');
      this.overlay.className = 'loading-overlay';
      this.overlay.innerHTML = `
        <div class="loading-content">
          <div class="loading-spinner"></div>
          <p class="loading-message">${message}</p>
        </div>
      `;
      document.body.appendChild(this.overlay);
    }
  }

  /**
   * Ocultar loading overlay
   */
  hide() {
    this.loadingCount = Math.max(0, this.loadingCount - 1);
    
    if (this.loadingCount === 0 && this.overlay) {
      this.overlay.remove();
      this.overlay = null;
    }
  }

  /**
   * Ejecutar función con loading
   */
  async withLoading(fn, message) {
    this.show(message);
    try {
      return await fn();
    } finally {
      this.hide();
    }
  }
}

// ============================================================================
// Export singleton instances
// ============================================================================

const apiClient = new APIClient();
const loadingManager = new LoadingManager();

// Para uso en HTML sin modules
if (typeof window !== 'undefined') {
  window.apiClient = apiClient;
  window.loadingManager = loadingManager;
  window.APIError = APIError;
}

// Para uso con ES6 modules
export { apiClient, loadingManager, APIError };
export default apiClient;
