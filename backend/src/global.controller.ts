import { Controller, Get, Query } from '@nestjs/common';
import { FlagsService } from './modules/flags/flags.service';

@Controller()
export class GlobalController {
  constructor(private readonly flagsService: FlagsService) {}

  // Endpoint especial /flags.json para el frontend (prueba #4)
  @Get('flags.json')
  async getFlagsJson(@Query('userId') userId?: string) {
    try {
      return await this.flagsService.getAllFlags(userId);
    } catch (error) {
      console.error('❌ Error obteniendo flags para frontend:', error);
      // Devolver valores fallback en caso de error
      return this.flagsService.getFallbackFlags();
    }
  }

  // Endpoint de bienvenida
  @Get()
  async getWelcome() {
    const clientInfo = this.flagsService.getClientInfo();
    const isConnected = await this.flagsService.isConnected();
    
    return {
      message: '🚀 API de Pagos para Feature Flags Testing',
      version: '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      configcat: {
        connected: isConnected,
        info: clientInfo
      },
      endpoints: {
        flags: '/flags',
        flagsJson: '/flags.json',
        health: '/health',
        healthFlags: '/health/flags',
        healthConfigCat: '/health/configcat',
        payments: '/payments',
        orders: '/orders',
        users: '/users'
      },
      features: {
        killSwitch: 'enable_payments flag controls payment processing',
        apiVersioning: 'orders_api_version controls v1/v2 API',
        gradualRollout: 'Support for percentage-based user rollout',
        auditLog: 'Complete flag change history',
        metrics: 'Real-time error rate monitoring',
        configcat: 'Real ConfigCat integration with fallback support'
      },
      testing: {
        flags: [
          'enable_payments (boolean) - Kill-switch para pagos',
          'promo_banner_color (string) - green/blue/red para banner',
          'orders_api_version (string) - v1/v2 para API versioning',
          'new_feature_enabled (boolean) - Roll-out gradual',
          'simulate_errors (boolean) - Para testing de rollback'
        ],
        endpoints: [
          'GET /health/flags - Verificar flags desde backend',
          'GET /flags.json - Obtener flags para frontend',
          'GET /health/configcat - Info detallada de ConfigCat'
        ]
      },
      timestamp: new Date()
    };
  }
} 