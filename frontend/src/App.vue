<template>
  <div id="app">
    <nav class="navbar">
      <div class="nav-container">
        <h1>🚀 API Pagos - Feature Flags</h1>
        <div class="nav-info">
          <span class="provider-status" :class="{ connected: flagsStore.isConnected }">
            {{ flagsStore.activeProvider.toUpperCase() }}: {{ flagsStore.isConnected ? 'Conectado' : 'Desconectado' }}
          </span>
        </div>
        <div class="nav-links">
          <router-link to="/">Dashboard</router-link>
          <router-link to="/payments">Pagos</router-link>
          <router-link to="/orders">Órdenes</router-link>
          <router-link to="/flags">Flags</router-link>
        </div>
      </div>
    </nav>
    
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useFlagsStore } from './stores/flags'

const flagsStore = useFlagsStore()

onMounted(async () => {
  console.log('🚀 [App] Inicializando aplicación...')
  
  // Cargar información del proveedor y flags
  await flagsStore.loadProviderInfo()
  await flagsStore.loadFlags()
  
  // Iniciar auto-reload
  flagsStore.startAutoReload()
  
  console.log('✅ [App] Aplicación inicializada con proveedor:', flagsStore.activeProvider)
})
</script>

<style scoped>
.navbar {
  background: #2c3e50;
  color: white;
  padding: 1rem 0;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.nav-info {
  display: flex;
  align-items: center;
}

.provider-status {
  background: #e74c3c;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: bold;
  margin-right: 1rem;
}

.provider-status.connected {
  background: #27ae60;
}

.nav-links {
  display: flex;
  gap: 2rem;
}

.nav-links a {
  color: white;
  text-decoration: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.nav-links a:hover,
.nav-links a.router-link-active {
  background-color: #34495e;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}
</style> 