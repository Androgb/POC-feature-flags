import { Controller, Get, Post, Body, Query, Param } from '@nestjs/common';
import { FlagsService } from './flags.service';

@Controller('flags')
export class FlagsController {
  constructor(private readonly flagsService: FlagsService) {}

  // Endpoint principal para obtener todos los flags (prueba #4)
  @Get()
  async getAllFlags(@Query('userId') userId?: string) {
    try {
      const flags = await this.flagsService.getAllFlags(userId);
      const isConnected = await this.flagsService.isConnected();
      const clientInfo = this.flagsService.getClientInfo();
      const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
      
      return {
        flags,
        timestamp: new Date(),
        environment: process.env.NODE_ENV || 'development',
        provider: {
          name: provider,
          connected: isConnected,
          info: clientInfo
        }
      };
    } catch (error) {
      return {
        error: error.message,
        flags: this.flagsService.getFallbackFlags(),
        timestamp: new Date(),
        provider: {
          name: process.env.FEATURE_FLAGS_PROVIDER || 'configcat',
          connected: false,
          error: `${process.env.FEATURE_FLAGS_PROVIDER || 'configcat'} connection failed`
        }
      };
    }
  }

  // Endpoint para obtener un flag específico
  @Get(':key')
  async getFlag(
    @Param('key') key: string,
    @Query('userId') userId?: string,
    @Query('default') defaultValue?: any
  ) {
    try {
      const value = await this.flagsService.getFlag(key, userId, defaultValue);
      const isConnected = await this.flagsService.isConnected();
      const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
      
      return {
        key,
        value,
        userId,
        timestamp: new Date(),
        environment: process.env.NODE_ENV || 'development',
        provider: {
          name: provider,
          connected: isConnected,
          source: provider
        }
      };
    } catch (error) {
      return {
        key,
        value: defaultValue,
        userId,
        timestamp: new Date(),
        error: error.message,
        provider: {
          name: process.env.FEATURE_FLAGS_PROVIDER || 'configcat',
          connected: false,
          source: 'fallback'
        }
      };
    }
  }

  // Endpoint para simular cambios de flags (para pruebas)
  // NOTA: En el proveedor real, los cambios se hacen desde el dashboard web
  @Post(':key')
  updateFlag(
    @Param('key') key: string,
    @Body() body: { value: any; userId?: string }
  ) {
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    console.log(`🚩 [FlagsController] Solicitud de actualización: ${key} = ${body.value}`);
    console.log(`💡 IMPORTANTE: Para actualizar realmente este flag, ve al dashboard de ${provider}`);
    
    this.flagsService.updateFlag(key, body.value, body.userId || 'test-user');
    
    const dashboardUrls = {
      configcat: 'https://app.configcat.com',
      launchdarkly: 'https://app.launchdarkly.com'
    };
    
    return {
      success: true,
      key,
      newValue: body.value,
      timestamp: new Date(),
      note: `Este cambio es solo local. Para cambios reales, usa el dashboard de ${provider}.`,
      provider: {
        name: provider,
        dashboardUrl: dashboardUrls[provider] || 'https://app.configcat.com',
        info: this.flagsService.getClientInfo()
      }
    };
  }

  // Endpoint para audit log (prueba #11)
  @Get('audit/log')
  getAuditLog() {
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    return {
      auditLog: this.flagsService.getAuditLog(),
      timestamp: new Date(),
      provider: {
        name: provider,
        note: `En ${provider} real, el audit log se encuentra en el dashboard web`
      }
    };
  }

  // Endpoint específico para el frontend (JSON simple)
  @Get('json/all')
  async getFlagsJson(@Query('userId') userId?: string) {
    try {
      return await this.flagsService.getAllFlags(userId);
    } catch (error) {
      console.error('❌ Error obteniendo flags JSON:', error);
      return this.flagsService.getFallbackFlags();
    }
  }

  // Endpoint para información del proveedor activo
  @Get('info/provider')
  async getProviderInfo() {
    const isConnected = await this.flagsService.isConnected();
    const clientInfo = this.flagsService.getClientInfo();
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    
    return {
      provider: {
        name: provider,
        connected: isConnected,
        client: clientInfo,
        expectedFlags: [
          'enable_payments',
          'promo_banner_color',
          'orders_api_version', 
          'new_feature_enabled',
          'simulate_errors'
        ],
        fallbackFlags: this.flagsService.getFallbackFlags(),
        timestamp: new Date()
      }
    };
  }
} 