import { Controller, Get, Query } from '@nestjs/common';
import { FlagsService } from '../flags/flags.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly flagsService: FlagsService
  ) {}

  // Endpoint principal de health check
  @Get()
  async getHealth() {
    const isConnected = await this.flagsService.isConnected();
    const clientInfo = this.flagsService.getClientInfo();
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    
    return {
      status: 'ok',
      timestamp: new Date(),
      service: 'payments-api',
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      provider: {
        name: provider,
        connected: isConnected,
        info: clientInfo
      }
    };
  }

  // Endpoint específico para leer flags en backend (prueba #3)
  @Get('flags')
  async getHealthFlags(@Query('userId') userId?: string) {
    const startTime = Date.now();
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    
    try {
      // Llamada real al proveedor activo
      const enablePayments = await this.flagsService.getFlag('enable_payments', userId, true);
      const allFlags = await this.flagsService.getAllFlags(userId);
      
      const responseTime = Date.now() - startTime;
      const isConnected = await this.flagsService.isConnected();
      
      return {
        status: 'ok',
        flags: {
          enable_payments: enablePayments,
          all: allFlags
        },
        responseTime: `${responseTime}ms`,
        timestamp: new Date(),
        environment: process.env.NODE_ENV || 'development',
        userId: userId || 'anonymous',
        provider: {
          name: provider,
          connected: isConnected,
          info: this.flagsService.getClientInfo()
        },
        // Información útil para debugging de feature flags
        debug: {
          totalFlags: Object.keys(allFlags).length,
          flagsChecked: ['enable_payments'],
          source: provider,
          cacheMiss: false
        }
      };
    } catch (error) {
      const responseTime = Date.now() - startTime;
      
      return {
        status: 'error',
        error: error.message,
        responseTime: `${responseTime}ms`,
        timestamp: new Date(),
        provider: {
          name: provider,
          connected: false,
          error: `${provider} connection failed`
        },
        fallback: {
          used: true,
          flags: this.flagsService.getFallbackFlags()
        }
      };
    }
  }

  // Endpoint para verificar conectividad con el proveedor activo (prueba #14)
  @Get('flags/connectivity')
  async getFlagsConnectivity() {
    const startTime = Date.now();
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    
    try {
      const isConnected = await this.flagsService.isConnected();
      
      if (!isConnected) {
        const fallbackFlags = this.flagsService.getFallbackFlags();
        return {
          status: 'degraded',
          mode: 'fallback',
          flags: fallbackFlags,
          responseTime: `${Date.now() - startTime}ms`,
          timestamp: new Date(),
          message: `${provider} no disponible - usando valores fallback`,
          provider: {
            name: provider,
            connected: false,
            info: this.flagsService.getClientInfo()
          }
        };
      }

      const flags = await this.flagsService.getAllFlags();
      return {
        status: 'ok',
        mode: 'live',
        flags,
        responseTime: `${Date.now() - startTime}ms`,
        timestamp: new Date(),
        message: `Conectado a ${provider} correctamente`,
        provider: {
          name: provider,
          connected: true,
          info: this.flagsService.getClientInfo()
        }
      };
    } catch (error) {
      // Fallback en caso de error
      const fallbackFlags = this.flagsService.getFallbackFlags();
      return {
        status: 'error',
        mode: 'fallback',
        flags: fallbackFlags,
        responseTime: `${Date.now() - startTime}ms`,
        timestamp: new Date(),
        error: error.message,
        message: `Error de ${provider} - usando valores fallback`,
        provider: {
          name: provider,
          connected: false,
          error: error.message
        }
      };
    }
  }

  // Endpoint para información detallada del proveedor activo
  @Get('provider')
  async getProviderInfo() {
    const isConnected = await this.flagsService.isConnected();
    const clientInfo = this.flagsService.getClientInfo();
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    
    return {
      provider: {
        name: provider,
        connected: isConnected,
        client: clientInfo,
        auditLog: this.flagsService.getAuditLog(),
        timestamp: new Date()
      }
    };
  }
} 