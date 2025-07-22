import axios from 'axios'

// Configuración base de Axios
export const api = axios.create({
  baseURL: '/api', // Proxy configurado en vite.config.ts
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Interceptor para requests
api.interceptors.request.use((config) => {
  console.log(`🌐 API Request: ${config.method?.toUpperCase()} ${config.url}`)
  return config
}, (error) => {
  console.error('❌ API Request Error:', error)
  return Promise.reject(error)
})

// Interceptor para responses
api.interceptors.response.use((response) => {
  console.log(`✅ API Response: ${response.status} ${response.config.url}`)
  return response
}, (error) => {
  console.error('❌ API Response Error:', error.response?.status, error.response?.data)
  return Promise.reject(error)
})

// Servicios específicos
export const paymentsApi = {
  create: (payment: any) => api.post('/payments', payment),
  getAll: (userId?: string) => api.get(`/payments${userId ? `?userId=${userId}` : ''}`),
  get: (paymentId: string) => api.get(`/payments/${paymentId}`),
  process: (paymentId: string, userId: string) => 
    api.post(`/payments/${paymentId}/process`, { userId }),
  getMetrics: () => api.get('/payments/metrics/dashboard')
}

export const ordersApi = {
  create: (order: any) => api.post('/orders', order),
  createV2: (order: any) => api.post('/orders/v2', order),
  getAll: (userId?: string) => api.get(`/orders${userId ? `?userId=${userId}` : ''}`),
  get: (orderId: string) => api.get(`/orders/${orderId}`),
  updateStatus: (orderId: string, status: string, userId: string) =>
    api.put(`/orders/${orderId}/status`, { status, userId }),
  getApiVersionStats: () => api.get('/orders/stats/api-versions'),
  getMetrics: () => api.get('/orders/stats/metrics')
}

export const usersApi = {
  create: (user: any) => api.post('/users', user),
  getAll: () => api.get('/users'),
  get: (userId: string) => api.get(`/users/${userId}`),
  createTestUsers: (count: number = 20) => 
    api.post('/users/test/create', { count }),
  getStats: () => api.get('/users/stats/summary')
}

export const flagsApi = {
  getAll: (userId?: string) => api.get(`/flags${userId ? `?userId=${userId}` : ''}`),
  get: (key: string, userId?: string) => 
    api.get(`/flags/${key}${userId ? `?userId=${userId}` : ''}`),
  update: (key: string, value: any, userId?: string) =>
    api.post(`/flags/${key}`, { value, userId }),
  getAuditLog: () => api.get('/flags/audit/log'),
  getJson: (userId?: string) => api.get(`/flags.json${userId ? `?userId=${userId}` : ''}`)
}

export const healthApi = {
  get: () => api.get('/health'),
  getFlags: (userId?: string) => 
    api.get(`/health/flags${userId ? `?userId=${userId}` : ''}`),
  getFlagsConnectivity: () => api.get('/health/flags/connectivity')
} 