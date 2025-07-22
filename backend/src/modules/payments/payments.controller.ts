import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { CreatePaymentDto } from '../../dto/create-payment.dto';
import { FlagsService } from '../flags/flags.service';

@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly flagsService: FlagsService,
  ) {}

  // Crear nuevo pago
  @Post()
  async createPayment(@Body() createPaymentDto: CreatePaymentDto) {
    try {
      const payment = await this.paymentsService.createPayment(createPaymentDto);
      return {
        success: true,
        payment,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: error.message,
          code: error.response?.code || error.code || 'PAYMENT_ERROR',
          details: error.response?.details || error.details || 'Error procesando el pago'
        },
        timestamp: new Date()
      };
    }
  }

  // Procesar pago existente
  @Post(':paymentId/process')
  async processPayment(
    @Param('paymentId') paymentId: string,
    @Body() body: { userId: string }
  ) {
    try {
      const payment = await this.paymentsService.processPayment(paymentId, body.userId);
      return {
        success: true,
        payment,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: error.message,
          code: error.response?.code || error.code || 'PAYMENT_PROCESSING_ERROR'
        },
        timestamp: new Date()
      };
    }
  }

  // Obtener todos los pagos
  @Get()
  async getAllPayments(@Query('userId') userId?: string) {
    const payments = await this.paymentsService.getAllPayments(userId);
    return {
      payments,
      count: payments.length,
      timestamp: new Date()
    };
  }

  // Obtener pago específico
  @Get(':paymentId')
  async getPayment(@Param('paymentId') paymentId: string) {
    try {
      const payment = await this.paymentsService.getPayment(paymentId);
      return {
        payment,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        error: {
          message: error.message,
          code: 'PAYMENT_NOT_FOUND'
        },
        timestamp: new Date()
      };
    }
  }

  // Endpoint para obtener métricas (prueba #13)
  @Get('metrics/dashboard')
  async getPaymentMetrics() {
    const metrics = await this.paymentsService.getPaymentMetrics();
    const flags = await this.flagsService.getAllFlags();
    
    return {
      metrics,
      flags: {
        enable_payments: flags.enable_payments,
        simulate_errors: flags.simulate_errors
      },
      alerts: this.generateAlerts(metrics),
      timestamp: new Date()
    };
  }

  // Método para generar alertas basadas en métricas
  private generateAlerts(metrics: any): Array<any> {
    const alerts = [];
    
    // Alerta si error rate > 2% (como menciona la prueba #13)
    if (metrics.errorRate > 2) {
      alerts.push({
        type: 'error_rate_high',
        severity: 'high',
        message: `Error rate es ${metrics.errorRate}% (> 2%)`,
        timestamp: new Date(),
        suggestion: 'Considerar desactivar enable_payments flag'
      });
    }

    // Alerta si hay muchos pagos cancelados
    if (metrics.cancelled > metrics.completed * 0.1) {
      alerts.push({
        type: 'high_cancellation_rate',
        severity: 'medium',
        message: `Alta tasa de cancelaciones: ${metrics.cancelled} cancelados vs ${metrics.completed} completados`,
        timestamp: new Date()
      });
    }

    return alerts;
  }
} 