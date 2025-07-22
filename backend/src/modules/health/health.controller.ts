import { Controller, Get, Query } from '@nestjs/common';
import { FlagsService } from '../flags/flags.service';
import { ConfigCatService } from '../flags/configcat.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly flagsService: FlagsService,
    private readonly configCatService: ConfigCatService
  ) {}

  // Endpoint principal de health check
  @Get()
  async getHealth() {
    const isConfigCatConnected = await this.configCatService.isConfigCatConnected();
    
    return {
      status: 'ok',
      timestamp: new Date(),
      service: 'payments-api',
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      configcat: {
        connected: isConfigCatConnected,
        info: this.configCatService.getClientInfo()
      }
    };
  }

  // Endpoint específico para leer flags en backend (prueba #3)
  @Get('flags')
  async getHealthFlags(@Query('userId') userId?: string) {
    const startTime = Date.now();
    
    try {
      // Llamada real a ConfigCat
      const enablePayments = await this.flagsService.getFlag('enable_payments', userId, true);
      const allFlags = await this.flagsService.getAllFlags(userId);
      
      const responseTime = Date.now() - startTime;
      const isConnected = await this.configCatService.isConfigCatConnected();
      
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
        configcat: {
          connected: isConnected,
          info: this.configCatService.getClientInfo()
        },
        // Información útil para debugging de feature flags
        debug: {
          totalFlags: Object.keys(allFlags).length,
          flagsChecked: ['enable_payments'],
          source: 'ConfigCat',
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
        configcat: {
          connected: false,
          error: 'ConfigCat connection failed'
        },
        fallback: {
          used: true,
          flags: this.configCatService.getFallbackFlags()
        }
      };
    }
  }

  // Endpoint para verificar conectividad con ConfigCat (prueba #14)
  @Get('flags/connectivity')
  async getFlagsConnectivity() {
    const startTime = Date.now();
    
    try {
      const isConnected = await this.configCatService.isConfigCatConnected();
      
      if (!isConnected) {
        const fallbackFlags = this.configCatService.getFallbackFlags();
        return {
          status: 'degraded',
          mode: 'fallback',
          flags: fallbackFlags,
          responseTime: `${Date.now() - startTime}ms`,
          timestamp: new Date(),
          message: 'ConfigCat no disponible - usando valores fallback',
          configcat: {
            connected: false,
            info: this.configCatService.getClientInfo()
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
        message: 'Conectado a ConfigCat correctamente',
        configcat: {
          connected: true,
          info: this.configCatService.getClientInfo()
        }
      };
    } catch (error) {
      // Fallback en caso de error
      const fallbackFlags = this.configCatService.getFallbackFlags();
      return {
        status: 'error',
        mode: 'fallback',
        flags: fallbackFlags,
        responseTime: `${Date.now() - startTime}ms`,
        timestamp: new Date(),
        error: error.message,
        message: 'Error de ConfigCat - usando valores fallback',
        configcat: {
          connected: false,
          error: error.message
        }
      };
    }
  }

  // Endpoint para información detallada de ConfigCat
  @Get('configcat')
  async getConfigCatInfo() {
    const isConnected = await this.configCatService.isConfigCatConnected();
    const clientInfo = this.configCatService.getClientInfo();
    
    return {
      configcat: {
        connected: isConnected,
        client: clientInfo,
        auditLog: this.configCatService.getAuditLog(),
        timestamp: new Date()
      }
    };
  }
} 