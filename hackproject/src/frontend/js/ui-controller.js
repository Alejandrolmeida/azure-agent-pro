/**
 * ============================================================================
 * UI Controller Module
 * ============================================================================
 * Gestión de la interfaz de usuario:
 * - Manejo de formularios
 * - Display de resultados
 * - Comparativa de rutas
 * - Estados de error y loading
 * - Interacciones del usuario
 * ============================================================================
 */

/**
 * UI Controller Class
 */
class UIController {
  constructor() {
    this.elements = {};
    this.state = {
      origin: null,
      destination: null,
      preference: 'balanced',
      currentResults: null,
      selectingOrigin: false,
      selectingDestination: false
    };
  }

  /**
   * Inicializar UI Controller
   */
  initialize() {
    this._cacheElements();
    this._attachEventListeners();
    this._initializeState();
    console.log('UI Controller initialized');
  }

  /**
   * Cachear referencias a elementos del DOM
   */
  _cacheElements() {
    this.elements = {
      // Form inputs
      originLat: document.getElementById('origin-lat'),
      originLon: document.getElementById('origin-lon'),
      destLat: document.getElementById('dest-lat'),
      destLon: document.getElementById('dest-lon'),
      
      // Radio buttons
      preferenceRadios: document.querySelectorAll('input[name="preference"]'),
      
      // Buttons
      calculateBtn: document.getElementById('calculate-btn'),
      clearBtn: document.getElementById('clear-btn'),
      
      // Results
      resultsContainer: document.getElementById('results-container'),
      resultsPanel: document.getElementById('results-panel'),
      routeCards: document.getElementById('route-cards'),
      
      // Messages
      errorContainer: document.getElementById('error-container'),
      
      // Modal
      modalOverlay: document.getElementById('modal-overlay'),
      modalClose: document.getElementById('modal-close')
    };
  }

  /**
   * Adjuntar event listeners
   */
  _attachEventListeners() {
    // Botón calcular
    if (this.elements.calculateBtn) {
      this.elements.calculateBtn.addEventListener('click', () => {
        this._handleCalculate();
      });
    }

    // Botón limpiar
    if (this.elements.clearBtn) {
      this.elements.clearBtn.addEventListener('click', () => {
        this.clearForm();
      });
    }

    // Radio buttons de preferencia
    this.elements.preferenceRadios.forEach(radio => {
      radio.addEventListener('change', (e) => {
        this.state.preference = e.target.value;
        this._updateRadioStyles();
      });
    });

    // Inputs de coordenadas (validación en tiempo real)
    [this.elements.originLat, this.elements.originLon,
     this.elements.destLat, this.elements.destLon].forEach(input => {
      if (input) {
        input.addEventListener('input', () => {
          this._validateInputs();
        });
      }
    });

    // Modal close
    if (this.elements.modalClose) {
      this.elements.modalClose.addEventListener('click', () => {
        this.hideModal();
      });
    }

    if (this.elements.modalOverlay) {
      this.elements.modalOverlay.addEventListener('click', (e) => {
        if (e.target === this.elements.modalOverlay) {
          this.hideModal();
        }
      });
    }

    // Tecla ESC para cerrar modal
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.elements.modalOverlay) {
        this.hideModal();
      }
    });
  }

  /**
   * Inicializar estado
   */
  _initializeState() {
    this._updateRadioStyles();
    this._validateInputs();
  }

  /**
   * Actualizar estilos de radio buttons
   */
  _updateRadioStyles() {
    document.querySelectorAll('.radio-option').forEach(option => {
      const radio = option.querySelector('input[type="radio"]');
      if (radio && radio.checked) {
        option.classList.add('active');
      } else {
        option.classList.remove('active');
      }
    });
  }

  /**
   * Validar inputs y habilitar/deshabilitar botón
   */
  _validateInputs() {
    const hasOrigin = this._hasValidCoordinates(
      this.elements.originLat.value,
      this.elements.originLon.value
    );
    const hasDestination = this._hasValidCoordinates(
      this.elements.destLat.value,
      this.elements.destLon.value
    );

    const isValid = hasOrigin && hasDestination;

    if (this.elements.calculateBtn) {
      this.elements.calculateBtn.disabled = !isValid;
    }

    return isValid;
  }

  /**
   * Verificar si coordenadas son válidas
   */
  _hasValidCoordinates(lat, lon) {
    const latNum = parseFloat(lat);
    const lonNum = parseFloat(lon);
    
    return !isNaN(latNum) && !isNaN(lonNum) &&
           latNum >= 40.3 && latNum <= 40.6 &&
           lonNum >= -3.9 && lonNum <= -3.5;
  }

  /**
   * Handler de calcular ruta
   */
  async _handleCalculate() {
    try {
      // Limpiar errores anteriores
      this.hideError();

      // Obtener datos del formulario
      const origin = {
        lat: parseFloat(this.elements.originLat.value),
        lon: parseFloat(this.elements.originLon.value)
      };

      const destination = {
        lat: parseFloat(this.elements.destLat.value),
        lon: parseFloat(this.elements.destLon.value)
      };

      const preference = this.state.preference;

      // Guardar en state
      this.state.origin = origin;
      this.state.destination = destination;

      // Disparar evento para que app.js lo maneje
      const event = new CustomEvent('calculateroute', {
        detail: { origin, destination, preference }
      });
      window.dispatchEvent(event);

    } catch (error) {
      console.error('Error handling calculate:', error);
      this.showError('Error al procesar el formulario');
    }
  }

  /**
   * Establecer origen desde coordenadas
   */
  setOrigin(lat, lon) {
    if (this.elements.originLat) {
      this.elements.originLat.value = lat.toFixed(4);
    }
    if (this.elements.originLon) {
      this.elements.originLon.value = lon.toFixed(4);
    }
    this.state.origin = { lat, lon };
    this._validateInputs();
  }

  /**
   * Establecer destino desde coordenadas
   */
  setDestination(lat, lon) {
    if (this.elements.destLat) {
      this.elements.destLat.value = lat.toFixed(4);
    }
    if (this.elements.destLon) {
      this.elements.destLon.value = lon.toFixed(4);
    }
    this.state.destination = { lat, lon };
    this._validateInputs();
  }

  /**
   * Mostrar resultados de rutas
   */
  displayResults(data) {
    this.state.currentResults = data;

    // Mostrar contenedor de resultados
    if (this.elements.resultsContainer) {
      this.elements.resultsContainer.classList.remove('hidden');
    }

    // Limpiar cards anteriores
    if (this.elements.routeCards) {
      this.elements.routeCards.innerHTML = '';
    }

    // Crear cards para cada ruta
    data.routes.forEach((route, index) => {
      const card = this._createRouteCard(route, index);
      this.elements.routeCards.appendChild(card);
    });

    // Scroll a resultados
    this.elements.resultsContainer.scrollIntoView({
      behavior: 'smooth',
      block: 'start'
    });
  }

  /**
   * Crear card de ruta
   */
  _createRouteCard(route, index) {
    const card = document.createElement('div');
    card.className = 'route-card';
    card.dataset.index = index;

    if (route.is_recommended) {
      card.classList.add('recommended');
    }

    // Badge según recomendación
    const badgeClass = `badge-${route.recommendation}`;
    const badgeText = {
      'excellent': 'Excelente',
      'good': 'Buena',
      'moderate': 'Moderada',
      'poor': 'Pobre'
    }[route.recommendation] || route.recommendation;

    card.innerHTML = `
      <div class="route-card-header">
        <h3 class="route-type">${this._getRouteTypeLabel(route.type)}</h3>
        <span class="route-badge ${badgeClass}">${badgeText}</span>
      </div>
      
      <div class="route-metrics">
        <div class="metric">
          <span class="metric-value">${route.distance_km}</span>
          <span class="metric-label">Kilómetros</span>
        </div>
        <div class="metric">
          <span class="metric-value">${Math.round(route.duration_min)}</span>
          <span class="metric-label">Minutos</span>
        </div>
        <div class="metric">
          <span class="metric-value">${route.emission_score}</span>
          <span class="metric-label">Score</span>
        </div>
      </div>
      
      <div class="route-pollutants">
        <div class="pollutant">
          <span class="pollutant-name">NO₂</span>
          <div class="pollutant-value">
            ${route.pollutants.NO2.toFixed(1)}
            <span class="pollutant-unit">μg/m³</span>
          </div>
        </div>
        <div class="pollutant">
          <span class="pollutant-name">PM10</span>
          <div class="pollutant-value">
            ${route.pollutants.PM10.toFixed(1)}
            <span class="pollutant-unit">μg/m³</span>
          </div>
        </div>
        <div class="pollutant">
          <span class="pollutant-name">PM2.5</span>
          <div class="pollutant-value">
            ${route.pollutants['PM2.5'].toFixed(1)}
            <span class="pollutant-unit">μg/m³</span>
          </div>
        </div>
      </div>
      
      <div class="health-impact">
        ℹ️ ${route.health_impact}
      </div>
    `;

    // Click handler
    card.addEventListener('click', () => {
      this._handleRouteCardClick(route, index);
    });

    return card;
  }

  /**
   * Handler de click en card de ruta
   */
  _handleRouteCardClick(route, index) {
    // Disparar evento para que map.js enfoque la ruta
    const event = new CustomEvent('routeselected', {
      detail: { route, index }
    });
    window.dispatchEvent(event);

    // Resaltar card
    document.querySelectorAll('.route-card').forEach(card => {
      card.style.border = '2px solid var(--color-border)';
    });
    
    const clickedCard = document.querySelector(`.route-card[data-index="${index}"]`);
    if (clickedCard) {
      clickedCard.style.border = '2px solid var(--color-primary)';
    }
  }

  /**
   * Obtener label amigable para tipo de ruta
   */
  _getRouteTypeLabel(type) {
    const labels = {
      'fastest': '🏃 Ruta Rápida',
      'shortest': '📏 Ruta Corta',
      'eco': '🌱 Ruta Ecológica',
      'balanced': '⚖️ Ruta Equilibrada'
    };
    return labels[type] || type;
  }

  /**
   * Mostrar mensaje de error
   */
  showError(message, details = null) {
    if (!this.elements.errorContainer) return;

    const errorHtml = `
      <div class="error-message">
        <span class="error-icon">⚠️</span>
        <div>
          <strong>Error:</strong> ${message}
          ${details ? `<br><small>${details}</small>` : ''}
        </div>
      </div>
    `;

    this.elements.errorContainer.innerHTML = errorHtml;
    this.elements.errorContainer.classList.remove('hidden');

    // Auto-hide después de 10 segundos
    setTimeout(() => {
      this.hideError();
    }, 10000);
  }

  /**
   * Ocultar mensaje de error
   */
  hideError() {
    if (this.elements.errorContainer) {
      this.elements.errorContainer.classList.add('hidden');
      this.elements.errorContainer.innerHTML = '';
    }
  }

  /**
   * Mostrar mensaje informativo
   */
  showInfo(message) {
    if (!this.elements.errorContainer) return;

    const infoHtml = `
      <div class="info-message">
        ℹ️ ${message}
      </div>
    `;

    this.elements.errorContainer.innerHTML = infoHtml;
    this.elements.errorContainer.classList.remove('hidden');

    // Auto-hide después de 5 segundos
    setTimeout(() => {
      this.hideError();
    }, 5000);
  }

  /**
   * Limpiar formulario
   */
  clearForm() {
    // Limpiar inputs
    if (this.elements.originLat) this.elements.originLat.value = '';
    if (this.elements.originLon) this.elements.originLon.value = '';
    if (this.elements.destLat) this.elements.destLat.value = '';
    if (this.elements.destLon) this.elements.destLon.value = '';

    // Reset state
    this.state.origin = null;
    this.state.destination = null;

    // Ocultar resultados
    if (this.elements.resultsContainer) {
      this.elements.resultsContainer.classList.add('hidden');
    }

    // Limpiar errores
    this.hideError();

    // Validar
    this._validateInputs();

    // Disparar evento para limpiar mapa
    window.dispatchEvent(new CustomEvent('clearall'));
  }

  /**
   * Mostrar modal
   */
  showModal(title, content) {
    if (!this.elements.modalOverlay) return;

    const titleEl = document.getElementById('modal-title');
    const bodyEl = document.getElementById('modal-body');

    if (titleEl) titleEl.textContent = title;
    if (bodyEl) bodyEl.innerHTML = content;

    this.elements.modalOverlay.classList.remove('hidden');
  }

  /**
   * Ocultar modal
   */
  hideModal() {
    if (this.elements.modalOverlay) {
      this.elements.modalOverlay.classList.add('hidden');
    }
  }

  /**
   * Obtener estado actual
   */
  getState() {
    return { ...this.state };
  }

  /**
   * Actualizar estado
   */
  setState(updates) {
    this.state = { ...this.state, ...updates };
  }
}

// ============================================================================
// Export singleton instance
// ============================================================================

const uiController = new UIController();

// Para uso en HTML sin modules
if (typeof window !== 'undefined') {
  window.uiController = uiController;
}

// Para uso con ES6 modules
export { uiController, UIController };
export default uiController;
