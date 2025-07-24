import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '../services/api'

export const useFlagsStore = defineStore('flags', () => {
  // Estado principal
  const flags = ref<Record<string, any>>({})
  const loading = ref(false)
  const lastUpdated = ref<Date | null>(null)
  const userId = ref<string>('user_123')
  
  // Estado del proveedor (agnóstico)
  const provider = ref({
    name: 'configcat',
    connected: false,
    info: null as any
  })

  // Getters computados para flags específicos
  const enablePayments = computed(() => flags.value.enable_payments ?? true)
  const promoBannerColor = computed(() => flags.value.promo_banner_color ?? 'green')
  const ordersApiVersion = computed(() => flags.value.orders_api_version ?? 'v1')
  const newFeatureEnabled = computed(() => flags.value.new_feature_enabled ?? false)
  const simulateErrors = computed(() => flags.value.simulate_errors ?? false)

  // Compatibilidad con flags Boolean de ConfigCat
  const rawFlags = computed(() => flags.value.raw_flags ?? {})

  // Información del proveedor activo
  const providerInfo = computed(() => ({
    name: provider.value.name,
    connected: provider.value.connected,
    info: provider.value.info,
    dashboardUrl: getDashboardUrl(provider.value.name),
    flagsExpected: getFlagsExpected(provider.value.name)
  }))

  // Getters de compatibilidad
  const activeProvider = computed(() => provider.value.name)
  const isConnected = computed(() => provider.value.connected)
  
  // Para compatibilidad con componentes existentes
  const isConfigCatConnected = computed(() => provider.value.connected)

  // Cargar información del proveedor y flags
  async function loadProviderInfo() {
    try {
      const response = await api.get('/health/flags')
      if (response.data.provider) {
        provider.value = {
          name: response.data.provider.name || 'configcat',
          connected: response.data.provider.connected || false,
          info: response.data.provider.info || null
        }
        console.log('🚩 [Frontend] Proveedor detectado:', provider.value.name, '- Conectado:', provider.value.connected)
      }
    } catch (error) {
      console.error('❌ [Frontend] Error obteniendo información del proveedor:', error)
      provider.value.connected = false
    }
  }

  // Cargar flags desde el backend
  async function loadFlags(userIdOverride?: string) {
    loading.value = true
    try {
      const currentUserId = userIdOverride || userId.value
      const response = await api.get(`/flags.json?userId=${currentUserId}`)
      
      if (response.data.flags) {
        flags.value = response.data.flags
      } else {
        flags.value = response.data
      }
      
      // Actualizar información del proveedor si viene en la respuesta
      if (response.data.provider) {
        provider.value = {
          name: response.data.provider.name || 'configcat',
          connected: response.data.provider.connected || false,
          info: response.data.provider.info || null
        }
      }
      
      lastUpdated.value = new Date()
      console.log('🚩 [Frontend] Flags cargados:', flags.value)
      console.log('🚩 [Frontend] Proveedor:', provider.value.name, '- Conectado:', provider.value.connected)
    } catch (error) {
      console.error('❌ [Frontend] Error cargando flags:', error)
      flags.value = getFallbackFlags()
      provider.value.connected = false
    } finally {
      loading.value = false
    }
  }

  // Actualizar flag (simulado - se hace en el dashboard real)
  async function updateFlag(key: string, value: any) {
    try {
      console.log(`🚩 [Frontend] Simulando actualización: ${key} = ${value}`)
      console.log(`💡 Para actualizar realmente, ve al dashboard de ${provider.value.name.toUpperCase()}`)
      
      // Actualizar estado local para UX inmediata
      flags.value[key] = value
      
      // Llamar al backend (simulado)
      await api.post(`/flags/${key}`, { 
        value: value, 
        userId: userId.value 
      })
      
      // Recargar flags después de un delay
      setTimeout(() => loadFlags(), 2000)
    } catch (error) {
      console.error('❌ [Frontend] Error actualizando flag:', error)
      throw error
    }
  }

  // Cambiar usuario
  function setUserId(newUserId: string) {
    userId.value = newUserId
    loadFlags(newUserId)
  }

  // Simular diferentes usuarios para testing
  function simulateUser(userNumber: number) {
    const testUserId = `test_user_${userNumber}`
    setUserId(testUserId)
  }

  // Auto-reload cada 30 segundos
  function startAutoReload() {
    setInterval(() => {
      if (!loading.value) {
        loadFlags()
      }
    }, 30000)
  }

  // Obtener flag individual
  function getFlag(key: string, defaultValue: any = false) {
    return flags.value[key] ?? defaultValue
  }

  // Valores fallback
  function getFallbackFlags(): Record<string, any> {
    console.log('🔄 [Frontend] Usando valores fallback')
    return {
      enable_payments: true,
      promo_banner_color: 'green',
      orders_api_version: 'v1',
      new_feature_enabled: false,
      simulate_errors: false,
      raw_flags: {
        enable_payments: true,
        promo_banner_green: true,
        promo_banner_blue: false,
        promo_banner_red: false,
        orders_api_v2: false,
        new_feature_enabled: false,
        simulate_errors: false
      }
    }
  }

  // Helpers
  function getDashboardUrl(providerName: string): string {
    const urls: Record<string, string> = {
      configcat: 'https://app.configcat.com',
      launchdarkly: 'https://app.launchdarkly.com'
    }
    return urls[providerName] || urls.configcat
  }

  function getFlagsExpected(providerName: string): string[] {
    if (providerName === 'launchdarkly') {
      return [
        'enable_payments (Boolean)',
        'promo_banner_color (String)',
        'orders_api_version (String)',
        'new_feature_enabled (Boolean)',
        'simulate_errors (Boolean)'
      ]
    }
    
    // ConfigCat (Boolean flags)
    return [
      'enable_payments (Boolean)',
      'promo_banner_green (Boolean)',
      'promo_banner_blue (Boolean)', 
      'promo_banner_red (Boolean)',
      'orders_api_v2 (Boolean)',
      'new_feature_enabled (Boolean)',
      'simulate_errors (Boolean)'
    ]
  }

  // Métodos de compatibilidad (deprecated pero mantenidos)
  const loadFlagsFromBackend = loadFlags
  const initConfigCat = () => console.log('ConfigCat init no longer needed - using backend proxy')
  const loadFlagsFromConfigCat = loadFlags

  return {
    // Estado
    flags,
    loading,
    lastUpdated,
    userId,
    provider,
    
    // Getters
    enablePayments,
    promoBannerColor,
    ordersApiVersion,
    newFeatureEnabled,
    simulateErrors,
    rawFlags,
    providerInfo,
    
    // Compatibilidad
    activeProvider,
    isConnected,
    isConfigCatConnected,
    
    // Acciones
    loadProviderInfo,
    loadFlags,
    updateFlag,
    setUserId,
    simulateUser,
    startAutoReload,
    getFlag,
    getFallbackFlags,
    
    // Métodos de compatibilidad
    loadFlagsFromBackend,
    initConfigCat,
    loadFlagsFromConfigCat
  }
}) 