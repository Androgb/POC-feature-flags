<template>
  <div class="dashboard">
    <h1>📊 Dashboard - Feature Flags Testing</h1>
    
    <!-- Estado del Proveedor -->
    <div class="provider-info" :class="{ connected: flagsStore.isConnected }">
      <h2>🔗 Estado de {{ flagsStore.activeProvider.toUpperCase() }}</h2>
      <div class="provider-details">
        <div class="detail">
          <strong>Proveedor:</strong> 
          <span class="provider-name">{{ flagsStore.activeProvider.toUpperCase() }}</span>
        </div>
        <div class="detail">
          <strong>Estado:</strong> 
          <span :class="{ connected: flagsStore.isConnected }">
            {{ flagsStore.isConnected ? '✅ Conectado' : '❌ Desconectado' }}
          </span>
        </div>
        <div class="detail">
          <strong>Dashboard:</strong> 
          <a :href="flagsStore.providerInfo.dashboardUrl" target="_blank">
            {{ flagsStore.providerInfo.dashboardUrl }}
          </a>
        </div>
        <div class="detail">
          <strong>Fuente de flags:</strong> 
          {{ flagsStore.isConnected ? `${flagsStore.activeProvider.toUpperCase()} Directo` : `Backend (${flagsStore.activeProvider.toUpperCase()})` }}
        </div>
      </div>
    </div>
    
    <!-- Banner promocional multivariante (prueba #8) -->
    <div class="promo-banner" :class="`banner-${flagsStore.promoBannerColor}`">
      <h2>🎉 Promoción Especial!</h2>
      <p>Color del banner controlado por flag: <strong>{{ flagsStore.promoBannerColor }}</strong></p>
      <p><small>Cambia este valor en el dashboard de ConfigCat para ver el cambio en tiempo real</small></p>
    </div>

    <!-- Estado de los Feature Flags -->
    <div class="flags-status">
      <h2>🚩 Estado de Feature Flags</h2>
      <div class="flags-grid">
        <div class="flag-card" :class="{ 'flag-enabled': flagsStore.enablePayments }">
          <h3>💳 Pagos Habilitados</h3>
          <p class="flag-value">{{ flagsStore.enablePayments ? 'ON' : 'OFF' }}</p>
          <p class="flag-description">Kill-switch para sistema de pagos</p>
          <p class="flag-source">📡 Desde {{ flagsStore.activeProvider.toUpperCase() }}</p>
        </div>
        
        <div class="flag-card">
          <h3>🔄 API Version</h3>
          <p class="flag-value">{{ flagsStore.ordersApiVersion }}</p>
          <p class="flag-description">Versión de API para órdenes</p>
          <p class="flag-source">📡 Desde {{ flagsStore.activeProvider.toUpperCase() }}</p>
        </div>
        
        <div class="flag-card" :class="{ 'flag-enabled': flagsStore.newFeatureEnabled }">
          <h3>✨ Nueva Feature</h3>
          <p class="flag-value">{{ flagsStore.newFeatureEnabled ? 'ON' : 'OFF' }}</p>
          <p class="flag-description">Roll-out gradual por usuario</p>
          <p class="flag-source">📡 Desde {{ flagsStore.activeProvider.toUpperCase() }}</p>
        </div>
        
        <div class="flag-card" :class="{ 'flag-error': flagsStore.simulateErrors }">
          <h3>⚠️ Simular Errores</h3>
          <p class="flag-value">{{ flagsStore.simulateErrors ? 'ON' : 'OFF' }}</p>
          <p class="flag-description">Para testing de rollback</p>
          <p class="flag-source">📡 Desde {{ flagsStore.activeProvider.toUpperCase() }}</p>
        </div>
      </div>
    </div>

    <!-- Información del Usuario Actual -->
    <div class="user-info">
      <h2>👤 Usuario Actual</h2>
      <div class="user-card">
        <p><strong>ID:</strong> {{ flagsStore.userId }}</p>
        <p><strong>Última actualización:</strong> {{ formatDate(flagsStore.lastUpdated) }}</p>
        <p><strong>Cargando:</strong> {{ flagsStore.loading ? 'Sí' : 'No' }}</p>
        <div class="user-actions">
          <button @click="changeUser(1)" class="btn btn-secondary">Test User 1</button>
          <button @click="changeUser(5)" class="btn btn-secondary">Test User 5</button>
          <button @click="changeUser(15)" class="btn btn-secondary">Test User 15</button>
          <button @click="refreshFlags" class="btn btn-primary" :disabled="flagsStore.loading">
            {{ flagsStore.loading ? 'Cargando...' : 'Refrescar Flags' }}
          </button>
          <button @click="refreshFromProvider" class="btn btn-provider" :disabled="flagsStore.loading || !flagsStore.isConnected">
            {{ flagsStore.loading ? 'Cargando...' : `Refrescar desde ${flagsStore.activeProvider.toUpperCase()}` }}
          </button>
        </div>
      </div>
    </div>

    <!-- Nueva funcionalidad solo visible con flag (prueba #4) -->
    <div v-if="flagsStore.newFeatureEnabled" class="new-feature">
      <h2>🎯 Nueva Funcionalidad</h2>
      <div class="feature-content">
        <p>Esta sección solo aparece cuando el flag <code>new_feature_enabled</code> está activo para tu usuario.</p>
        <p>Esto demuestra el roll-out gradual basado en user_id, controlado desde ConfigCat.</p>
        <p><strong>Usuario actual:</strong> {{ flagsStore.userId }}</p>
      </div>
    </div>

    <!-- Mensaje de mantenimiento (prueba #6) -->
    <div v-if="!flagsStore.enablePayments" class="maintenance-notice">
      <h2>🔧 Servicio en Mantenimiento</h2>
      <p>Los pagos están temporalmente deshabilitados desde ConfigCat.</p>
      <p>Para reactivarlos, cambia el flag <code>enable_payments</code> en el dashboard de ConfigCat.</p>
    </div>

    <!-- Instrucciones para el Proveedor -->
    <div class="provider-instructions">
      <h2>🎮 Testing con {{ flagsStore.activeProvider.toUpperCase() }}</h2>
      <div class="instructions-content">
        <p><strong>Dashboard de {{ flagsStore.activeProvider.toUpperCase() }}:</strong> 
          <a :href="flagsStore.providerInfo.dashboardUrl" target="_blank">{{ flagsStore.providerInfo.dashboardUrl }}</a>
        </p>
        <p><strong>Flags configurados:</strong></p>
        <ul>
          <li><code>enable_payments</code> (boolean) - Kill-switch para pagos</li>
          <li><code>promo_banner_color</code> (string) - Color del banner (green/blue/red)</li>
          <li><code>orders_api_version</code> (string) - Versión de API (v1/v2)</li>
          <li><code>new_feature_enabled</code> (boolean) - Nueva feature con roll-out gradual</li>
          <li><code>simulate_errors</code> (boolean) - Simular errores para rollback</li>
        </ul>
        <p><strong>Testing:</strong> Cambia los valores en {{ flagsStore.activeProvider.toUpperCase() }} y verás los cambios reflejados aquí en ~30 segundos.</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useFlagsStore } from '../stores/flags'
import { onMounted } from 'vue'

const flagsStore = useFlagsStore()

onMounted(() => {
  // El auto-reload ya se inicia en App.vue
  console.log('Dashboard cargado')
})

function changeUser(userNumber: number) {
  flagsStore.simulateUser(userNumber)
}

function refreshFlags() {
  flagsStore.loadFlags()
}

function refreshFromProvider() {
  if (flagsStore.isConnected) {
    flagsStore.loadFlags()
  }
}

function formatDate(date: Date | null) {
  if (!date) return 'Nunca'
  return date.toLocaleString('es-ES')
}


</script>

<style scoped>
.dashboard {
  max-width: 1200px;
  margin: 0 auto;
}

.provider-info {
  background: #fff5f5;
  border: 2px solid #e74c3c;
  border-radius: 8px;
  padding: 1.5rem;
  margin: 2rem 0;
}

.provider-info.connected {
  background: #f8fff9;
  border-color: #27ae60;
}

.provider-details {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.provider-name {
  font-weight: bold;
  color: #3498db;
  text-transform: uppercase;
}

.detail strong {
  color: #2c3e50;
}

.detail .connected {
  color: #27ae60;
  font-weight: bold;
}

.promo-banner {
  padding: 2rem;
  border-radius: 8px;
  margin: 2rem 0;
  text-align: center;
  color: white;
  font-weight: bold;
}

.banner-green { background: linear-gradient(135deg, #27ae60, #2ecc71); }
.banner-blue { background: linear-gradient(135deg, #3498db, #5dade2); }
.banner-red { background: linear-gradient(135deg, #e74c3c, #ec7063); }

.flags-status {
  margin: 2rem 0;
}

.flags-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.flag-card {
  background: white;
  border: 2px solid #ddd;
  border-radius: 8px;
  padding: 1.5rem;
  text-align: center;
  transition: all 0.3s ease;
}

.flag-card.flag-enabled {
  border-color: #27ae60;
  background: #f8fff9;
}

.flag-card.flag-error {
  border-color: #e74c3c;
  background: #fff5f5;
}

.flag-value {
  font-size: 1.5rem;
  font-weight: bold;
  margin: 0.5rem 0;
  color: #2c3e50;
}

.flag-description {
  color: #7f8c8d;
  font-size: 0.9rem;
}

.flag-source {
  color: #3498db;
  font-size: 0.8rem;
  font-weight: bold;
  margin-top: 0.5rem;
}

.user-info {
  margin: 2rem 0;
}

.user-card {
  background: white;
  border-radius: 8px;
  padding: 1.5rem;
  border: 1px solid #ddd;
}

.user-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
  flex-wrap: wrap;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
  transition: background-color 0.3s;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2980b9;
}

.btn-secondary {
  background: #95a5a6;
  color: white;
}

.btn-secondary:hover {
  background: #7f8c8d;
}

.btn-provider {
  background: #f39c12;
  color: white;
}

.btn-provider:hover:not(:disabled) {
  background: #e67e22;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.new-feature {
  background: linear-gradient(135deg, #f39c12, #f1c40f);
  color: white;
  padding: 2rem;
  border-radius: 8px;
  margin: 2rem 0;
}

.feature-content {
  background: rgba(255, 255, 255, 0.1);
  padding: 1rem;
  border-radius: 4px;
  margin-top: 1rem;
}

.maintenance-notice {
  background: #e74c3c;
  color: white;
  padding: 2rem;
  border-radius: 8px;
  margin: 2rem 0;
  text-align: center;
}

.provider-instructions {
  background: white;
  border: 2px solid #3498db;
  border-radius: 8px;
  padding: 2rem;
  margin: 2rem 0;
}

.instructions-content ul {
  margin: 1rem 0;
  padding-left: 2rem;
}

.instructions-content a {
  color: #3498db;
  text-decoration: none;
}

.instructions-content a:hover {
  text-decoration: underline;
}

code {
  background: rgba(52, 152, 219, 0.1);
  padding: 0.2rem 0.4rem;
  border-radius: 3px;
  color: #2c3e50;
  font-family: monospace;
}
</style> 