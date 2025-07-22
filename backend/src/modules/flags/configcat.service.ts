import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import * as configcat from 'configcat-node';
import { IFeatureFlagsProvider, FlagAuditEntry } from './interfaces/feature-flags-provider.interface';

@Injectable()
export class ConfigCatService implements IFeatureFlagsProvider, OnModuleInit, OnModuleDestroy {
  private client: configcat.IConfigCatClient;
  private auditLog: FlagAuditEntry[] = [];
  
  // SDK Key de ConfigCat
  private readonly sdkKey = process.env.CONFIGCAT_SDK_KEY || 'configcat-sdk-1/psXdCCevYUOCuYEqRQENww/Kz0qzczpFkip_aiovxePiQ';

  async onModuleInit() {
    console.log('🚩 Inicializando ConfigCat con SDK Key:', this.sdkKey.substring(0, 20) + '...');
    
    // Inicializar cliente de ConfigCat con polling rápido para testing
    this.client = configcat.getClient(this.sdkKey, configcat.PollingMode.AutoPoll, {
      pollIntervalSeconds: 30,       // Polling cada 30 segundos para Test #5
      requestTimeoutMs: 5000,        // Timeout de 5 segundos
      maxInitWaitTimeSeconds: 10     // Máximo 10s de inicialización
    });

    console.log('✅ ConfigCat cliente inicializado con polling de 30s');
  }

  async onModuleDestroy() {
    if (this.client) {
      this.client.dispose();
      console.log('🛑 ConfigCat cliente cerrado');
    }
  }

  // Obtener valor de flag desde ConfigCat
  async getFlag(key: string, userId?: string, defaultValue: any = false): Promise<any> {
    try {
      if (!this.client) {
        console.warn('⚠️ ConfigCat cliente no inicializado, usando valor por defecto');
        return defaultValue;
      }

      // Crear user object para ConfigCat
      const user = userId ? { identifier: userId, custom: {} } : undefined;
      
      // Obtener valor desde ConfigCat
      const value = await this.client.getValueAsync(key, defaultValue, user);
      
      console.log(`🚩 ConfigCat flag ${key} = ${value} para usuario ${userId || 'anonymous'}`);
      return value;
      
    } catch (error) {
      console.error(`❌ Error obteniendo flag ${key} desde ConfigCat:`, error);
      return defaultValue;
    }
  }

  // Obtener color del banner basado en flags Boolean
  async getBannerColor(userId?: string): Promise<string> {
    try {
      const user = userId ? { identifier: userId, custom: {} } : undefined;
      
      // Verificar cada color en orden de prioridad
      const isRed = await this.client.getValueAsync('promo_banner_red', false, user);
      if (isRed) return 'red';
      
      const isBlue = await this.client.getValueAsync('promo_banner_blue', false, user);
      if (isBlue) return 'blue';
      
      const isGreen = await this.client.getValueAsync('promo_banner_green', true, user); // Default verde
      if (isGreen) return 'green';
      
      return 'green'; // Fallback por defecto
    } catch (error) {
      console.error('❌ Error obteniendo color de banner:', error);
      return 'green';
    }
  }

  // Obtener versión de API basada en flag Boolean
  async getApiVersion(userId?: string): Promise<string> {
    try {
      const user = userId ? { identifier: userId, custom: {} } : undefined;
      const useV2 = await this.client.getValueAsync('orders_api_v2', false, user);
      return useV2 ? 'v2' : 'v1';
    } catch (error) {
      console.error('❌ Error obteniendo versión de API:', error);
      return 'v1';
    }
  }

  // Obtener todos los flags configurados (adaptado para Boolean)
  async getAllFlags(userId?: string): Promise<Record<string, any>> {
    try {
      if (!this.client) {
        console.warn('⚠️ ConfigCat cliente no inicializado, usando valores por defecto');
        return this.getFallbackFlags();
      }

      const user = userId ? { identifier: userId, custom: {} } : undefined;
      
      // Lista de flags Boolean que esperamos tener en ConfigCat
      const booleanFlags = [
        'enable_payments',
        'promo_banner_green',
        'promo_banner_blue', 
        'promo_banner_red',
        'orders_api_v2',
        'new_feature_enabled',
        'simulate_errors'
      ];

      const rawFlags: Record<string, any> = {};
      
      // Obtener cada flag Boolean
      for (const key of booleanFlags) {
        rawFlags[key] = await this.getFlag(key, userId, this.getDefaultValue(key));
      }

      // Convertir a formato esperado por la aplicación
      const flags = {
        enable_payments: rawFlags.enable_payments,
        promo_banner_color: await this.getBannerColor(userId),
        orders_api_version: await this.getApiVersion(userId),
        new_feature_enabled: rawFlags.new_feature_enabled,
        simulate_errors: rawFlags.simulate_errors,
        // Incluir también los flags Boolean individuales para debugging
        raw_flags: rawFlags
      };

      console.log('🚩 Todos los flags obtenidos desde ConfigCat:', flags);
      return flags;
      
    } catch (error) {
      console.error('❌ Error obteniendo todos los flags desde ConfigCat:', error);
      return this.getFallbackFlags();
    }
  }

  // Simular actualización de flag (ConfigCat se actualiza desde dashboard)
  updateFlag(key: string, value: any, userId: string = 'admin'): void {
    // En ConfigCat real, los flags se actualizan desde el dashboard web
    // Aquí solo registramos el cambio en el audit log para compatibilidad
    this.auditLog.push({
      timestamp: new Date(),
      user: userId,
      flagKey: key,
      previousValue: 'unknown', // ConfigCat no nos da el valor anterior
      newValue: value,
      environment: process.env.NODE_ENV || 'development'
    });

    console.log(`🚩 Simulando actualización de flag ${key} = ${value} (actualizar en ConfigCat dashboard)`);
    console.log('💡 Nota: Para actualizar realmente el flag, ve al dashboard de ConfigCat');
  }

  // Obtener audit log
  getAuditLog(): FlagAuditEntry[] {
    return this.auditLog;
  }

  // Valores por defecto para flags Boolean
  private getDefaultValue(key: string): boolean {
    const defaults: Record<string, boolean> = {
      enable_payments: true,
      promo_banner_green: true,  // Verde por defecto
      promo_banner_blue: false,
      promo_banner_red: false,
      orders_api_v2: false,      // v1 por defecto
      new_feature_enabled: false,
      simulate_errors: false
    };
    return defaults[key] ?? false;
  }

  // Valores fallback cuando ConfigCat no está disponible
  getFallbackFlags(): Record<string, any> {
    console.log('🔄 Usando valores fallback');
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
    };
  }

  // Health check de ConfigCat
  async isConfigCatConnected(): Promise<boolean> {
    try {
      if (!this.client) return false;
      
      // Intentar obtener un flag para verificar conectividad
      await this.client.getValueAsync('enable_payments', true);
      return true;
    } catch (error) {
      console.error('❌ ConfigCat no está conectado:', error);
      return false;
    }
  }

  // Implementación de interface IFeatureFlagsProvider
  async isConnected(): Promise<boolean> {
    return await this.isConfigCatConnected();
  }

  // Obtener información del cliente
  getClientInfo(): any {
    return {
      sdkKey: this.sdkKey.substring(0, 20) + '...',
      isInitialized: !!this.client,
      environment: process.env.NODE_ENV || 'development',
      flagsExpected: [
        'enable_payments (Boolean)',
        'promo_banner_green (Boolean)',
        'promo_banner_blue (Boolean)',
        'promo_banner_red (Boolean)',
        'orders_api_v2 (Boolean)',
        'new_feature_enabled (Boolean)',
        'simulate_errors (Boolean)'
      ]
    };
  }
} 