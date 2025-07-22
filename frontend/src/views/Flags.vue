<template>
  <div class="flags">
    <h1>🚩 Administración de Feature Flags</h1>
    
    <div class="flags-manager">
      <h2>Control de Flags</h2>
      
      <!-- Kill-switch para pagos (prueba #6) -->
      <div class="flag-control">
        <div class="flag-info">
          <h3>💳 Enable Payments</h3>
          <p>Kill-switch para sistema de pagos</p>
        </div>
        <div class="flag-toggle">
          <label class="switch">
            <input 
              type="checkbox" 
              :checked="flagsStore.enablePayments"
              @change="updateFlag('enable_payments', $event.target.checked)"
            >
            <span class="slider"></span>
          </label>
          <span class="flag-status">{{ flagsStore.enablePayments ? 'ON' : 'OFF' }}</span>
        </div>
      </div>

      <!-- Banner color multivariante (prueba #8) -->
      <div class="flag-control">
        <div class="flag-info">
          <h3>🎨 Promo Banner Color</h3>
          <p>Color del banner promocional</p>
        </div>
        <div class="flag-select">
          <select 
            :value="flagsStore.promoBannerColor"
            @change="updateFlag('promo_banner_color', $event.target.value)"
          >
            <option value="green">Verde</option>
            <option value="blue">Azul</option>
            <option value="red">Rojo</option>
          </select>
        </div>
      </div>

      <!-- API Version (prueba #9) -->
      <div class="flag-control">
        <div class="flag-info">
          <h3>🔄 Orders API Version</h3>
          <p>Versión de API para órdenes</p>
        </div>
        <div class="flag-select">
          <select 
            :value="flagsStore.ordersApiVersion"
            @change="updateFlag('orders_api_version', $event.target.value)"
          >
            <option value="v1">v1 (Básica)</option>
            <option value="v2">v2 (Extendida)</option>
          </select>
        </div>
      </div>

      <!-- Nueva feature (prueba #7) -->
      <div class="flag-control">
        <div class="flag-info">
          <h3>✨ New Feature Enabled</h3>
          <p>Roll-out gradual por usuario (5%)</p>
        </div>
        <div class="flag-toggle">
          <label class="switch">
            <input 
              type="checkbox" 
              :checked="flagsStore.newFeatureEnabled"
              @change="updateFlag('new_feature_enabled', $event.target.checked)"
            >
            <span class="slider"></span>
          </label>
          <span class="flag-status">{{ flagsStore.newFeatureEnabled ? 'ON' : 'OFF' }}</span>
        </div>
      </div>

      <!-- Simular errores (prueba #10) -->
      <div class="flag-control danger">
        <div class="flag-info">
          <h3>⚠️ Simulate Errors</h3>
          <p>Para testing de rollback inmediato</p>
        </div>
        <div class="flag-toggle">
          <label class="switch">
            <input 
              type="checkbox" 
              :checked="flagsStore.simulateErrors"
              @change="updateFlag('simulate_errors', $event.target.checked)"
            >
            <span class="slider danger"></span>
          </label>
          <span class="flag-status">{{ flagsStore.simulateErrors ? 'ON' : 'OFF' }}</span>
        </div>
      </div>
    </div>

    <!-- Información del usuario actual -->
    <div class="user-simulator">
      <h2>👤 Simulador de Usuarios</h2>
      <p>Cambia de usuario para probar roll-out gradual</p>
      <div class="user-buttons">
        <button 
          v-for="i in 20" 
          :key="i"
          @click="changeUser(i)"
          class="user-btn"
          :class="{ active: flagsStore.userId === `test_user_${i}` }"
        >
          User {{ i }}
        </button>
      </div>
      <div class="current-user">
        <strong>Usuario actual:</strong> {{ flagsStore.userId }}
      </div>
    </div>

    <!-- Estado de flags en tiempo real -->
    <div class="flags-status">
      <h2>📊 Estado Actual</h2>
      <div class="status-grid">
        <div class="status-item">
          <strong>Última actualización:</strong>
          <span>{{ formatDate(flagsStore.lastUpdated) }}</span>
        </div>
        <div class="status-item">
          <strong>Cargando:</strong>
          <span :class="{ loading: flagsStore.loading }">
            {{ flagsStore.loading ? 'Sí' : 'No' }}
          </span>
        </div>
        <div class="status-item">
          <strong>Auto-reload:</strong>
          <span class="active">Activo (30s)</span>
        </div>
      </div>
    </div>

    <!-- JSON de flags -->
    <div class="flags-json">
      <h2>📄 Flags JSON (Raw)</h2>
      <pre>{{ JSON.stringify(flagsStore.flags, null, 2) }}</pre>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useFlagsStore } from '../stores/flags'

const flagsStore = useFlagsStore()

async function updateFlag(key: string, value: any) {
  try {
    await flagsStore.updateFlag(key, value)
    console.log(`✅ Flag ${key} actualizado a: ${value}`)
  } catch (error) {
    console.error(`❌ Error actualizando flag ${key}:`, error)
  }
}

function changeUser(userNumber: number) {
  flagsStore.simulateUser(userNumber)
}

function formatDate(date: Date | null) {
  if (!date) return 'Nunca'
  return date.toLocaleString('es-ES')
}
</script>

<style scoped>
.flags {
  max-width: 1000px;
  margin: 0 auto;
}

.flags-manager {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  margin: 2rem 0;
}

.flag-control {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #eee;
}

.flag-control:last-child {
  border-bottom: none;
}

.flag-control.danger {
  background: #fff5f5;
  border-left: 4px solid #e74c3c;
}

.flag-info h3 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
}

.flag-info p {
  margin: 0;
  color: #7f8c8d;
  font-size: 0.9rem;
}

.flag-toggle {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.flag-select select {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

/* Switch CSS */
.switch {
  position: relative;
  display: inline-block;
  width: 60px;
  height: 34px;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: .4s;
  border-radius: 34px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 26px;
  width: 26px;
  left: 4px;
  bottom: 4px;
  background-color: white;
  transition: .4s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #27ae60;
}

input:checked + .slider.danger {
  background-color: #e74c3c;
}

input:checked + .slider:before {
  transform: translateX(26px);
}

.flag-status {
  font-weight: bold;
  min-width: 40px;
}

.user-simulator {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  margin: 2rem 0;
}

.user-buttons {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
  gap: 0.5rem;
  margin: 1rem 0;
}

.user-btn {
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: white;
  cursor: pointer;
  font-size: 0.8rem;
  transition: all 0.3s;
}

.user-btn:hover {
  background: #f8f9fa;
}

.user-btn.active {
  background: #3498db;
  color: white;
  border-color: #3498db;
}

.current-user {
  margin-top: 1rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 4px;
}

.flags-status {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  margin: 2rem 0;
}

.status-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.status-item {
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 4px;
}

.status-item .loading {
  color: #f39c12;
  font-weight: bold;
}

.status-item .active {
  color: #27ae60;
  font-weight: bold;
}

.flags-json {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  margin: 2rem 0;
}

.flags-json pre {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 0.9rem;
  border: 1px solid #e9ecef;
}
</style> 