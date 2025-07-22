import { Injectable, BadRequestException, ServiceUnavailableException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Payment, PaymentDocument } from '../../schemas/payment.schema';
import { CreatePaymentDto } from '../../dto/create-payment.dto';
import { FlagsService } from '../flags/flags.service';

@Injectable()
export class PaymentsService {
  constructor(
    @InjectModel(Payment.name) private paymentModel: Model<PaymentDocument>,
    private readonly flagsService: FlagsService,
  ) {}

  async createPayment(createPaymentDto: CreatePaymentDto): Promise<Payment> {
    // Kill-switch: verificar si los pagos están habilitados (prueba #6)
    const paymentsEnabled = await this.flagsService.getFlag('enable_payments', createPaymentDto.userId, true);
    
    if (!paymentsEnabled) {
      throw new BadRequestException({
        message: 'Servicio en mantenimiento',
        code: 'PAYMENTS_DISABLED',
        details: 'Los pagos están temporalmente deshabilitados por mantenimiento del sistema'
      });
    }

    // Verificar flag de errores para métricas (prueba #13)
    const simulateErrors = await this.flagsService.getFlag('simulate_errors', createPaymentDto.userId, false);

    // Generar ID único para el pago
    const paymentId = `pay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Crear pago con logs de flags utilizados
    const payment = new this.paymentModel({
      paymentId,
      ...createPaymentDto,
      status: 'pending',
      logs: [{
        timestamp: new Date(),
        action: 'payment_created',
        details: 'Pago creado exitosamente',
        flagsUsed: {
          enable_payments: paymentsEnabled,
          simulate_errors: simulateErrors
        }
      }]
    });

    const savedPayment = await payment.save();
    console.log(`💳 Pago creado: ${paymentId} para usuario ${createPaymentDto.userId}`);
    
    return savedPayment;
  }

  async processPayment(paymentId: string, userId: string): Promise<Payment> {
    // Verificar kill-switch antes de procesar
    const paymentsEnabled = await this.flagsService.getFlag('enable_payments', userId, true);
    
    if (!paymentsEnabled) {
      throw new BadRequestException({
        message: 'Servicio en mantenimiento',
        code: 'PAYMENTS_DISABLED'
      });
    }

    const payment = await this.paymentModel.findOne({ paymentId });
    if (!payment) {
      throw new BadRequestException('Pago no encontrado');
    }

    if (payment.status !== 'pending') {
      throw new BadRequestException('El pago ya fue procesado');
    }

    // Simular procesamiento
    payment.status = 'processing';
    payment.logs.push({
      timestamp: new Date(),
      action: 'payment_processing',
      details: 'Procesando pago...',
      flagsUsed: {
        enable_payments: paymentsEnabled
      }
    });

    await payment.save();

    // Simular delay de procesamiento
    setTimeout(async () => {
      try {
        // Verificar nuevamente el flag (puede haber cambiado)
        const stillEnabled = await this.flagsService.getFlag('enable_payments', userId, true);
        
        if (!stillEnabled) {
          payment.status = 'cancelled';
          payment.logs.push({
            timestamp: new Date(),
            action: 'payment_cancelled',
            details: 'Pago cancelado - servicio deshabilitado durante procesamiento',
            flagsUsed: { enable_payments: stillEnabled }
          });
        } else {
          payment.status = 'completed';
          payment.logs.push({
            timestamp: new Date(),
            action: 'payment_completed',
            details: 'Pago completado exitosamente',
            flagsUsed: { enable_payments: stillEnabled }
          });
        }
        
        await payment.save();
        console.log(`💳 Pago ${paymentId} finalizado con estado: ${payment.status}`);
      } catch (error) {
        console.error(`❌ Error procesando pago ${paymentId}:`, error);
      }
    }, 2000);

    return payment;
  }

  async getAllPayments(userId?: string): Promise<Payment[]> {
    const query = userId ? { userId } : {};
    return this.paymentModel.find(query).sort({ createdAt: -1 });
  }

  async getPayment(paymentId: string): Promise<Payment> {
    const payment = await this.paymentModel.findOne({ paymentId });
    if (!payment) {
      throw new BadRequestException('Pago no encontrado');
    }
    return payment;
  }

  // Método para obtener métricas de pagos (para prueba #13)
  async getPaymentMetrics(): Promise<any> {
    const total = await this.paymentModel.countDocuments();
    const completed = await this.paymentModel.countDocuments({ status: 'completed' });
    const failed = await this.paymentModel.countDocuments({ status: 'failed' });
    const cancelled = await this.paymentModel.countDocuments({ status: 'cancelled' });
    
    const errorRate = total > 0 ? ((failed + cancelled) / total) * 100 : 0;
    
    return {
      total,
      completed,
      failed,
      cancelled,
      errorRate: parseFloat(errorRate.toFixed(2)),
      timestamp: new Date()
    };
  }
} 