<template>
  <div class="orders">
    <h1>📦 Sistema de Órdenes</h1>
    
    <div class="api-version-info">
      <h2>API Version: {{ flagsStore.ordersApiVersion }}</h2>
      <p>Las órdenes se crean usando la versión de API controlada por feature flag</p>
    </div>

    <div class="create-order">
      <h2>Crear Nueva Orden</h2>
      <form @submit.prevent="createOrder" class="order-form">
        <div class="form-group">
          <label>Producto:</label>
          <input v-model="newOrder.productName" required>
        </div>
        <div class="form-group">
          <label>Cantidad:</label>
          <input v-model.number="newOrder.quantity" type="number" min="1" required>
        </div>
        <div class="form-group">
          <label>Precio unitario:</label>
          <input v-model.number="newOrder.price" type="number" step="0.01" required>
        </div>
        
        <!-- Campos adicionales solo para v2 -->
        <div v-if="flagsStore.ordersApiVersion === 'v2'" class="v2-fields">
          <h3>🆕 Funcionalidades v2</h3>
          <div class="form-group">
            <label>Código promocional:</label>
            <input v-model="newOrder.promotionCode" placeholder="PROMO20">
          </div>
          <div class="form-group">
            <label>Descuento:</label>
            <input v-model.number="newOrder.discountAmount" type="number" step="0.01">
          </div>
          <div class="form-group">
            <label>
              <input v-model="newOrder.express" type="checkbox">
              Envío express
            </label>
          </div>
        </div>

        <button type="submit" class="btn btn-primary" :disabled="loading">
          {{ loading ? 'Creando...' : `Crear Orden (${flagsStore.ordersApiVersion})` }}
        </button>
      </form>
    </div>

    <div class="orders-list">
      <h2>Historial de Órdenes</h2>
      <div class="version-stats">
        <p><strong>Estadísticas de versioning:</strong></p>
        <p>v1: {{ versionStats.v1?.count || 0 }} órdenes ({{ versionStats.v1?.percentage || 0 }}%)</p>
        <p>v2: {{ versionStats.v2?.count || 0 }} órdenes ({{ versionStats.v2?.percentage || 0 }}%)</p>
      </div>
      
      <div v-if="orders.length === 0" class="empty-state">
        No hay órdenes registradas
      </div>
      <div v-else class="orders-grid">
        <div v-for="order in orders" :key="order.orderId" class="order-card" :class="`api-${order.apiVersion}`">
          <h3>{{ order.orderId }}</h3>
          <p><strong>API:</strong> {{ order.apiVersion }}</p>
          <p><strong>Total:</strong> ${{ order.totalAmount }}</p>
          <p><strong>Items:</strong> {{ order.items?.length || 0 }}</p>
          <p><strong>Estado:</strong> <span :class="`status-${order.status}`">{{ order.status }}</span></p>
          <div v-if="order.apiVersion === 'v2' && order.metadata?.promotionCode" class="v2-info">
            <p><strong>Promoción:</strong> {{ order.metadata.promotionCode }}</p>
            <p><strong>Descuento:</strong> ${{ order.metadata.discountApplied || 0 }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useFlagsStore } from '../stores/flags'
import { ordersApi } from '../services/api'

const flagsStore = useFlagsStore()
const orders = ref<any[]>([])
const versionStats = ref<any>({})
const loading = ref(false)

const newOrder = ref({
  productName: 'Producto de prueba',
  quantity: 1,
  price: 99.99,
  promotionCode: '',
  discountAmount: 0,
  express: false
})

onMounted(() => {
  loadOrders()
  loadVersionStats()
})

async function createOrder() {
  loading.value = true
  try {
    const orderData = {
      userId: flagsStore.userId,
      paymentId: `pay_${Date.now()}`,
      items: [{
        productId: `prod_${Date.now()}`,
        name: newOrder.value.productName,
        quantity: newOrder.value.quantity,
        price: newOrder.value.price
      }]
    }

    let response
    if (flagsStore.ordersApiVersion === 'v2') {
      response = await ordersApi.createV2({
        ...orderData,
        promotionCode: newOrder.value.promotionCode,
        discountAmount: newOrder.value.discountAmount,
        shippingPreferences: {
          express: newOrder.value.express,
          trackingNotifications: true
        }
      })
    } else {
      response = await ordersApi.create(orderData)
    }
    
    if (response.data.success) {
      await loadOrders()
      await loadVersionStats()
      resetForm()
      console.log('✅ Orden creada exitosamente')
    }
  } catch (error) {
    console.error('❌ Error creando orden:', error)
  } finally {
    loading.value = false
  }
}

async function loadOrders() {
  try {
    const response = await ordersApi.getAll(flagsStore.userId)
    orders.value = response.data.orders || []
  } catch (error) {
    console.error('❌ Error cargando órdenes:', error)
    orders.value = []
  }
}

async function loadVersionStats() {
  try {
    const response = await ordersApi.getApiVersionStats()
    versionStats.value = response.data.stats || {}
  } catch (error) {
    console.error('❌ Error cargando estadísticas:', error)
  }
}

function resetForm() {
  newOrder.value = {
    productName: 'Producto de prueba',
    quantity: 1,
    price: 99.99,
    promotionCode: '',
    discountAmount: 0,
    express: false
  }
}
</script>

<style scoped>
.orders {
  max-width: 1000px;
  margin: 0 auto;
}

.api-version-info {
  background: #3498db;
  color: white;
  padding: 1rem;
  border-radius: 8px;
  margin: 1rem 0;
  text-align: center;
}

.order-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  margin: 1rem 0;
}

.v2-fields {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
  margin: 1rem 0;
  border-left: 4px solid #e74c3c;
}

.version-stats {
  background: white;
  padding: 1rem;
  border-radius: 8px;
  margin: 1rem 0;
  border-left: 4px solid #f39c12;
}

.orders-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.order-card {
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1.5rem;
}

.order-card.api-v1 {
  border-left: 4px solid #3498db;
}

.order-card.api-v2 {
  border-left: 4px solid #e74c3c;
}

.v2-info {
  background: #fff5f5;
  padding: 0.5rem;
  border-radius: 4px;
  margin-top: 1rem;
  font-size: 0.9rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.form-group input {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2980b9;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.status-draft { color: #95a5a6; }
.status-confirmed { color: #f39c12; }
.status-shipped { color: #3498db; }
.status-delivered { color: #27ae60; }
.status-cancelled { color: #e74c3c; }

.empty-state {
  text-align: center;
  color: #7f8c8d;
  padding: 2rem;
  background: white;
  border-radius: 8px;
}
</style> 