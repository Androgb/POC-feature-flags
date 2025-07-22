<template>
  <div class="payments">
    <h1>💳 Sistema de Pagos</h1>
    
    <!-- Sección solo visible si pagos están habilitados -->
    <div v-if="flagsStore.enablePayments" class="payment-section">
      <div class="create-payment">
        <h2>Crear Nuevo Pago</h2>
        <form @submit.prevent="createPayment" class="payment-form">
          <div class="form-group">
            <label>Monto:</label>
            <input v-model.number="newPayment.amount" type="number" step="0.01" required>
          </div>
          <div class="form-group">
            <label>Moneda:</label>
            <select v-model="newPayment.currency">
              <option value="USD">USD</option>
              <option value="EUR">EUR</option>
              <option value="MXN">MXN</option>
            </select>
          </div>
          <div class="form-group">
            <label>Método:</label>
            <select v-model="newPayment.method">
              <option value="card">Tarjeta</option>
              <option value="paypal">PayPal</option>
              <option value="transfer">Transferencia</option>
            </select>
          </div>
          <button type="submit" class="btn btn-primary" :disabled="loading">
            {{ loading ? 'Procesando...' : 'Crear Pago' }}
          </button>
        </form>
      </div>

      <div class="payments-list">
        <h2>Historial de Pagos</h2>
        <div v-if="payments.length === 0" class="empty-state">
          No hay pagos registrados
        </div>
        <div v-else class="payments-grid">
          <div v-for="payment in payments" :key="payment.paymentId" class="payment-card">
            <h3>{{ payment.paymentId }}</h3>
            <p><strong>Monto:</strong> {{ payment.amount }} {{ payment.currency }}</p>
            <p><strong>Estado:</strong> <span :class="`status-${payment.status}`">{{ payment.status }}</span></p>
            <p><strong>Método:</strong> {{ payment.method }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Mensaje cuando pagos están deshabilitados (Kill-switch activo) -->
    <div v-else class="payments-disabled">
      <h2>🔧 Servicio en Mantenimiento</h2>
      <p>Los pagos están temporalmente deshabilitados por mantenimiento del sistema.</p>
      <p>Por favor, intenta más tarde.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useFlagsStore } from '../stores/flags'
import { paymentsApi } from '../services/api'

const flagsStore = useFlagsStore()
const payments = ref<any[]>([])
const loading = ref(false)

const newPayment = ref({
  amount: 100,
  currency: 'USD',
  method: 'card',
  description: 'Pago de prueba'
})

onMounted(() => {
  loadPayments()
})

async function createPayment() {
  if (!flagsStore.enablePayments) return
  
  loading.value = true
  try {
    const response = await paymentsApi.create({
      ...newPayment.value,
      userId: flagsStore.userId
    })
    
    if (response.data.success) {
      await loadPayments()
      newPayment.value.amount = 100
      console.log('✅ Pago creado exitosamente')
    }
  } catch (error) {
    console.error('❌ Error creando pago:', error)
  } finally {
    loading.value = false
  }
}

async function loadPayments() {
  try {
    const response = await paymentsApi.getAll(flagsStore.userId)
    payments.value = response.data.payments || []
  } catch (error) {
    console.error('❌ Error cargando pagos:', error)
    payments.value = []
  }
}
</script>

<style scoped>
.payments {
  max-width: 1000px;
  margin: 0 auto;
}

.payment-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  margin: 1rem 0;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.form-group input,
.form-group select {
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
  background: #27ae60;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #229954;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.payments-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.payment-card {
  background: white;
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1.5rem;
}

.status-pending { color: #f39c12; }
.status-processing { color: #3498db; }
.status-completed { color: #27ae60; }
.status-failed { color: #e74c3c; }
.status-cancelled { color: #95a5a6; }

.payments-disabled {
  background: #e74c3c;
  color: white;
  padding: 3rem;
  border-radius: 8px;
  text-align: center;
  margin: 2rem 0;
}

.empty-state {
  text-align: center;
  color: #7f8c8d;
  padding: 2rem;
  background: white;
  border-radius: 8px;
}
</style> 