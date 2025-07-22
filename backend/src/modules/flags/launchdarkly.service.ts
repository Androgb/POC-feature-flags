import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { IFeatureFlagsProvider, FlagAuditEntry } from './interfaces/feature-flags-provider.interface';
import * as LaunchDarkly from '@launchdarkly/node-server-sdk';

// Tipos para LaunchDarkly SDK
type LDUser = LaunchDarkly.LDUser;
type LDClient = LaunchDarkly.LDClient;

@Injectable()
export class LaunchDarklyService implements IFeatureFlagsProvider, OnModuleInit, OnModuleDestroy {
  private client: LDClient;
  private auditLog: FlagAuditEntry[] = [];
  
  // SDK Key de LaunchDarkly
  private readonly sdkKey = process.env.LAUNCHDARKLY_SDK_KEY || 'sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

  async onModuleInit() {
    console.log('🚩 Inicializando LaunchDarkly con SDK Key:', this.sdkKey.substring(0, 20) + '...');
    
    // Inicializar cliente de LaunchDarkly
    this.client = LaunchDarkly.init(this.sdkKey, {
      stream: true,
      baseUri: 'https://app.launchdarkly.com',
      eventsUri: 'https://events.launchdarkly.com',
      timeout: 5
    });

    // Esperar inicialización
    await this.client.initialized();
    console.log('✅ LaunchDarkly cliente inicializado');
  }

  async onModuleDestroy() {
    if (this.client) {
      await this.client.close();
      console.log('🛑 LaunchDarkly cliente cerrado');
    }
  }

  // Obtener valor de flag desde LaunchDarkly
  async getFlag(key: string, userId?: string, defaultValue: any = false): Promise<any> {
    try {
      if (!this.client) {
        console.warn('⚠️ LaunchDarkly cliente no inicializado, usando valor por defecto');
        return defaultValue;
      }

      // Crear user object para LaunchDarkly
      const user: LDUser = {
        key: userId || 'anonymous',
        custom: {}
      };
      
      // Obtener valor desde LaunchDarkly
      const value = await this.client.variation(key, user, defaultValue);
      
      console.log(`🚩 LaunchDarkly flag ${key} = ${value} para usuario ${userId || 'anonymous'}`);
      return value;
      
    } catch (error) {
      console.error(`❌ Error obteniendo flag ${key} desde LaunchDarkly:`, error);
      return defaultValue;
    }
  }

  // Obtener color del banner (LaunchDarkly soporta strings directamente)
  async getBannerColor(userId?: string): Promise<string> {
    try {
      // En LaunchDarkly podemos usar un flag string directamente
      const color = await this.getFlag('promo_banner_color', userId, 'green');
      return color;
    } catch (error) {
      console.error('❌ Error obteniendo color de banner:', error);
      return 'green';
    }
  }

  // Obtener versión de API (LaunchDarkly soporta strings directamente)
  async getApiVersion(userId?: string): Promise<string> {
    try {
      const version = await this.getFlag('orders_api_version', userId, 'v1');
      return version;
    } catch (error) {
      console.error('❌ Error obteniendo versión de API:', error);
      return 'v1';
    }
  }

  // Obtener todos los flags configurados
  async getAllFlags(userId?: string): Promise<Record<string, any>> {
    try {
      if (!this.client) {
        console.warn('⚠️ LaunchDarkly cliente no inicializado, usando valores por defecto');
        return this.getFallbackFlags();
      }

      const user: LDUser = {
        key: userId || 'anonymous',
        custom: {}
      };
      
      // Obtener todos los flags desde LaunchDarkly
      const flagsState = await this.client.allFlagsState(user);
      const allValues = flagsState.allValues();

      // Convertir a formato esperado por la aplicación
      const flags = {
        enable_payments: allValues.enable_payments ?? true,
        promo_banner_color: allValues.promo_banner_color ?? 'green',
        orders_api_version: allValues.orders_api_version ?? 'v1',
        new_feature_enabled: allValues.new_feature_enabled ?? false,
        simulate_errors: allValues.simulate_errors ?? false,
        // Incluir también todos los flags raw para debugging
        raw_flags: allValues
      };

      console.log('🚩 Todos los flags obtenidos desde LaunchDarkly:', flags);
      return flags;
      
    } catch (error) {
      console.error('❌ Error obteniendo todos los flags desde LaunchDarkly:', error);
      return this.getFallbackFlags();
    }
  }

  // Simular actualización de flag (LaunchDarkly se actualiza desde dashboard)
  updateFlag(key: string, value: any, userId: string = 'admin'): void {
    // En LaunchDarkly real, los flags se actualizan desde el dashboard web
    // Aquí solo registramos el cambio en el audit log para compatibilidad
    this.auditLog.push({
      timestamp: new Date(),
      user: userId,
      flagKey: key,
      previousValue: 'unknown', // LaunchDarkly no nos da el valor anterior
      newValue: value,
      environment: process.env.NODE_ENV || 'development'
    });

    console.log(`🚩 Simulando actualización de flag ${key} = ${value} (actualizar en LaunchDarkly dashboard)`);
    console.log('💡 Nota: Para actualizar realmente el flag, ve al dashboard de LaunchDarkly');
  }

  // Obtener audit log
  getAuditLog(): FlagAuditEntry[] {
    return this.auditLog;
  }

  // Health check de LaunchDarkly
  async isConnected(): Promise<boolean> {
    try {
      if (!this.client) return false;
      
      // Verificar si el cliente está inicializado
      return await this.client.initialized();
    } catch (error) {
      console.error('❌ LaunchDarkly no está conectado:', error);
      return false;
    }
  }

  // Obtener información del cliente
  getClientInfo(): any {
    return {
      provider: 'LaunchDarkly',
      sdkKey: this.sdkKey.substring(0, 20) + '...',
      isInitialized: !!this.client,
      environment: process.env.NODE_ENV || 'development',
      flagsExpected: [
        'enable_payments (Boolean)',
        'promo_banner_color (String)', 
        'orders_api_version (String)',
        'new_feature_enabled (Boolean)',
        'simulate_errors (Boolean)'
      ]
    };
  }

  // Valores fallback cuando LaunchDarkly no está disponible
  getFallbackFlags(): Record<string, any> {
    console.log('🔄 Usando valores fallback de LaunchDarkly');
    return {
      enable_payments: true,
      promo_banner_color: 'green',
      orders_api_version: 'v1', 
      new_feature_enabled: false,
      simulate_errors: false,
      raw_flags: {
        enable_payments: true,
        promo_banner_color: 'green',
        orders_api_version: 'v1',
        new_feature_enabled: false,
        simulate_errors: false
      }
    };
  }
} 