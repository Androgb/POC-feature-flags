import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import * as configcat from 'configcat-js'
import { api } from '../services/api'

export const useFlagsStore = defineStore('flags', () => {
  // Estado
  const flags = ref<Record<string, any>>({})
  const loading = ref(false)
  const lastUpdated = ref<Date | null>(null)
  const userId = ref<string>('user_123') // Usuario simulado para testing
  const configCatClient = ref<any>(null)
  const isConfigCatConnected = ref(false)

  // SDK Key de ConfigCat (la misma que el backend)
  const configCatSdkKey = 'configcat-sdk-1/psXdCCevYUOCuYEqRQENww/Kz0qzczpFkip_aiovxePiQ'

  // Getters computados (mantienen compatibilidad)
  const enablePayments = computed(() => flags.value.enable_payments ?? true)
  const promoBannerColor = computed(() => flags.value.promo_banner_color ?? 'green')
  const ordersApiVersion = computed(() => flags.value.orders_api_version ?? 'v1')
  const newFeatureEnabled = computed(() => flags.value.new_feature_enabled ?? false)
  const simulateErrors = computed(() => flags.value.simulate_errors ?? false)

  // Nuevos getters para flags Boolean individuales
  const rawFlags = computed(() => flags.value.raw_flags ?? {})
  const promoBannerGreen = computed(() => rawFlags.value.promo_banner_green ?? true)
  const promoBannerBlue = computed(() => rawFlags.value.promo_banner_blue ?? false)
  const promoBannerRed = computed(() => rawFlags.value.promo_banner_red ?? false)
  const ordersApiV2 = computed(() => rawFlags.value.orders_api_v2 ?? false)

  // Inicializar ConfigCat en el frontend
  function initConfigCat() {
    try {
      console.log('🚩 [Frontend] Inicializando ConfigCat cliente...')
      
      // Crear cliente de ConfigCat para frontend
      configCatClient.value = configcat.getClient(configCatSdkKey)
      isConfigCatConnected.value = true
      
      console.log('✅ [Frontend] ConfigCat cliente inicializado')
    } catch (error) {
      console.error('❌ [Frontend] Error inicializando ConfigCat:', error)
      isConfigCatConnected.value = false
    }
  }

  // Obtener color de banner desde flags Boolean
  async function getBannerColorFromFlags(user: any): Promise<string> {
    if (!configCatClient.value) return 'green'
    
    try {
      // Verificar en orden de prioridad: rojo > azul > verde
      const isRed = await configCatClient.value.getValueAsync('promo_banner_red', false, user)
      if (isRed) return 'red'
      
      const isBlue = await configCatClient.value.getValueAsync('promo_banner_blue', false, user)
      if (isBlue) return 'blue'
      
      const isGreen = await configCatClient.value.getValueAsync('promo_banner_green', true, user)
      if (isGreen) return 'green'
      
      return 'green'
    } catch (error) {
      console.error('❌ Error obteniendo color de banner:', error)
      return 'green'
    }
  }

  // Obtener versión de API desde flag Boolean
  async function getApiVersionFromFlags(user: any): Promise<string> {
    if (!configCatClient.value) return 'v1'
    
    try {
      const useV2 = await configCatClient.value.getValueAsync('orders_api_v2', false, user)
      return useV2 ? 'v2' : 'v1'
    } catch (error) {
      console.error('❌ Error obteniendo versión de API:', error)
      return 'v1'
    }
  }

  // Cargar flags usando ConfigCat directamente
  async function loadFlagsFromConfigCat(userIdOverride?: string) {
    if (!configCatClient.value) {
      console.warn('⚠️ ConfigCat cliente no inicializado, usando API backend')
      return loadFlagsFromBackend(userIdOverride)
    }

    loading.value = true
    try {
      const currentUserId = userIdOverride || userId.value
      
      // Crear user object para ConfigCat
      const user = { identifier: currentUserId, custom: {} }
      
      // Lista de flags Boolean esperados
      const booleanFlags = [
        'enable_payments',
        'promo_banner_green',
        'promo_banner_blue',
        'promo_banner_red',
        'orders_api_v2',
        'new_feature_enabled',
        'simulate_errors'
      ]

      const rawFlagsData: Record<string, any> = {}
      
      // Obtener cada flag Boolean desde ConfigCat
      for (const key of booleanFlags) {
        try {
          rawFlagsData[key] = await configCatClient.value.getValueAsync(key, getDefaultValue(key), user)
        } catch (error) {
          console.warn(`⚠️ Error obteniendo flag ${key} desde ConfigCat:`, error)
          rawFlagsData[key] = getDefaultValue(key)
        }
      }

      // Convertir a formato compatible con la aplicación
      const newFlags = {
        enable_payments: rawFlagsData.enable_payments,
        promo_banner_color: await getBannerColorFromFlags(user),
        orders_api_version: await getApiVersionFromFlags(user),
        new_feature_enabled: rawFlagsData.new_feature_enabled,
        simulate_errors: rawFlagsData.simulate_errors,
        raw_flags: rawFlagsData
      }

      flags.value = newFlags
      lastUpdated.value = new Date()
      console.log('🚩 [Frontend] Flags cargados desde ConfigCat:', flags.value)
    } catch (error) {
      console.error('❌ [Frontend] Error cargando flags desde ConfigCat:', error)
      // Fallback al backend si ConfigCat falla
      await loadFlagsFromBackend(userIdOverride)
    } finally {
      loading.value = false
    }
  }

  // Fallback: cargar flags desde el backend
  async function loadFlagsFromBackend(userIdOverride?: string) {
    loading.value = true
    try {
      const currentUserId = userIdOverride || userId.value
      const response = await api.get(`/flags.json?userId=${currentUserId}`)
      flags.value = response.data
      lastUpdated.value = new Date()
      console.log('🚩 [Frontend] Flags cargados desde backend:', flags.value)
    } catch (error) {
      console.error('❌ [Frontend] Error cargando flags desde backend:', error)
      // Usar valores fallback si todo falla
      flags.value = getFallbackFlags()
    } finally {
      loading.value = false
    }
  }

  // Método principal para cargar flags (intenta ConfigCat primero, luego backend)
  async function loadFlags(userIdOverride?: string) {
    // Si ConfigCat está disponible, usarlo directamente
    if (isConfigCatConnected.value && configCatClient.value) {
      await loadFlagsFromConfigCat(userIdOverride)
    } else {
      // Sino, usar el backend que también usa ConfigCat
      await loadFlagsFromBackend(userIdOverride)
    }
  }

  // Simular actualización de flag Boolean (en ConfigCat real se hace desde dashboard)
  async function updateFlag(key: string, value: any) {
    try {
      console.log(`🚩 [Frontend] Simulando actualización: ${key} = ${value}`)
      console.log('💡 IMPORTANTE: Para actualizar realmente este flag, ve al dashboard de ConfigCat')
      
      // Mapear flags virtuales a flags Boolean reales
      let actualKey = key
      let actualValue = value
      
      if (key === 'promo_banner_color') {
        // No actualizar directamente, mostrar mensaje
        console.log('💡 Para cambiar color del banner, activa/desactiva los flags Boolean:')
        console.log('   - promo_banner_green, promo_banner_blue, promo_banner_red')
        return
      }
      
      if (key === 'orders_api_version') {
        actualKey = 'orders_api_v2'
        actualValue = value === 'v2'
        console.log(`💡 Mapeando ${key}=${value} → ${actualKey}=${actualValue}`)
      }
      
      // Llamar al backend para registrar el cambio (aunque sea simulado)
      await api.post(`/flags/${actualKey}`, { 
        value: actualValue, 
        userId: userId.value 
      })
      
      // Actualizar el estado local inmediatamente para UX
      if (key === 'orders_api_version') {
        flags.value.orders_api_version = value
        if (flags.value.raw_flags) {
          flags.value.raw_flags.orders_api_v2 = actualValue
        }
      } else {
        flags.value[key] = value
      }
      
      console.log(`🚩 [Frontend] Flag ${key} actualizado localmente`)
      
      // Recargar todos los flags después de un delay para obtener el estado real
      setTimeout(() => loadFlags(), 2000)
    } catch (error) {
      console.error('❌ [Frontend] Error actualizando flag:', error)
      throw error
    }
  }

  function getFlag(key: string, defaultValue: any = false) {
    return flags.value[key] ?? defaultValue
  }

  // Auto-reload cada 30 segundos para detectar cambios (prueba #5)
  function startAutoReload() {
    setInterval(() => {
      if (!loading.value) {
        loadFlags()
      }
    }, 30000) // 30 segundos
  }

  function setUserId(newUserId: string) {
    userId.value = newUserId
    loadFlags(newUserId)
  }

  // Simular diferentes usuarios para testing de roll-out gradual
  function simulateUser(userNumber: number) {
    const testUserId = `test_user_${userNumber}`
    setUserId(testUserId)
  }

  // Obtener valores por defecto para cada flag Boolean
  function getDefaultValue(key: string): boolean {
    const defaults: Record<string, boolean> = {
      enable_payments: true,
      promo_banner_green: true,  // Verde por defecto
      promo_banner_blue: false,
      promo_banner_red: false,
      orders_api_v2: false,      // v1 por defecto
      new_feature_enabled: false,
      simulate_errors: false
    }
    return defaults[key] ?? false
  }

  // Valores fallback cuando todo falla
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

  // Información de estado de ConfigCat
  const configCatInfo = computed(() => ({
    connected: isConfigCatConnected.value,
    clientInitialized: !!configCatClient.value,
    sdkKey: configCatSdkKey.substring(0, 20) + '...',
    flagsExpected: [
      'enable_payments (Boolean)',
      'promo_banner_green (Boolean)',
      'promo_banner_blue (Boolean)', 
      'promo_banner_red (Boolean)',
      'orders_api_v2 (Boolean)',
      'new_feature_enabled (Boolean)',
      'simulate_errors (Boolean)'
    ]
  }))

  return {
    // Estado
    flags,
    loading,
    lastUpdated,
    userId,
    isConfigCatConnected,
    configCatInfo,
    
    // Getters específicos (compatibilidad)
    enablePayments,
    promoBannerColor,
    ordersApiVersion,
    newFeatureEnabled,
    simulateErrors,
    
    // Nuevos getters para flags Boolean individuales
    rawFlags,
    promoBannerGreen,
    promoBannerBlue,
    promoBannerRed,
    ordersApiV2,
    
    // Acciones
    initConfigCat,
    loadFlags,
    loadFlagsFromConfigCat,
    loadFlagsFromBackend,
    updateFlag,
    getFlag,
    startAutoReload,
    setUserId,
    simulateUser,
    getFallbackFlags
  }
}) 