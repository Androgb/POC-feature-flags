import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument } from '../../schemas/order.schema';
import { CreateOrderDto, CreateOrderV2Dto } from '../../dto/create-order.dto';
import { FlagsService } from '../flags/flags.service';

@Injectable()
export class OrdersService {
  constructor(
    @InjectModel(Order.name) private orderModel: Model<OrderDocument>,
    private readonly flagsService: FlagsService,
  ) {}

  async createOrder(createOrderDto: CreateOrderDto): Promise<Order> {
    // Determinar versión de API basada en flag (prueba #9)
    const apiVersion = await this.flagsService.getFlag('orders_api_version', createOrderDto.userId, 'v1');
    
    // Generar ID único para la orden
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Calcular total
    const totalAmount = createOrderDto.items.reduce((sum, item) => 
      sum + (item.price * item.quantity), 0
    );

    // Crear orden base
    const orderData = {
      orderId,
      ...createOrderDto,
      apiVersion: createOrderDto.apiVersion || apiVersion,
      totalAmount,
      logs: [{
        timestamp: new Date(),
        action: 'order_created',
        details: `Orden creada usando API ${apiVersion}`,
        apiVersion: createOrderDto.apiVersion || apiVersion
      }]
    };

    const order = new this.orderModel(orderData);
    const savedOrder = await order.save();
    
    console.log(`📦 Orden creada: ${orderId} (API ${apiVersion}) para usuario ${createOrderDto.userId}`);
    return savedOrder;
  }

  async createOrderV2(createOrderV2Dto: CreateOrderV2Dto): Promise<Order> {
    // Forzar versión v2
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Calcular total con descuentos (nueva funcionalidad v2)
    let totalAmount = createOrderV2Dto.items.reduce((sum, item) => 
      sum + (item.price * item.quantity), 0
    );

    // Aplicar descuento si existe (funcionalidad v2)
    if (createOrderV2Dto.discountAmount) {
      totalAmount = Math.max(0, totalAmount - createOrderV2Dto.discountAmount);
    }

    const orderData = {
      orderId,
      ...createOrderV2Dto,
      apiVersion: 'v2',
      totalAmount,
      metadata: {
        ...createOrderV2Dto.metadata,
        promotionCode: createOrderV2Dto.promotionCode,
        discountApplied: createOrderV2Dto.discountAmount || 0,
        shippingPreferences: createOrderV2Dto.shippingPreferences
      },
      logs: [{
        timestamp: new Date(),
        action: 'order_created',
        details: 'Orden creada usando API v2 con funcionalidades extendidas',
        apiVersion: 'v2'
      }]
    };

    const order = new this.orderModel(orderData);
    const savedOrder = await order.save();
    
    console.log(`📦 Orden v2 creada: ${orderId} para usuario ${createOrderV2Dto.userId}`);
    return savedOrder;
  }

  async getAllOrders(userId?: string): Promise<Order[]> {
    const query = userId ? { userId } : {};
    return this.orderModel.find(query).sort({ createdAt: -1 });
  }

  async getOrder(orderId: string): Promise<Order> {
    const order = await this.orderModel.findOne({ orderId });
    if (!order) {
      throw new BadRequestException('Orden no encontrada');
    }
    return order;
  }

  async updateOrderStatus(orderId: string, status: string, userId: string): Promise<Order> {
    const order = await this.orderModel.findOne({ orderId });
    if (!order) {
      throw new BadRequestException('Orden no encontrada');
    }

    order.status = status;
    order.logs.push({
      timestamp: new Date(),
      action: 'status_updated',
      details: `Estado actualizado a: ${status}`,
      apiVersion: order.apiVersion
    });

    const updatedOrder = await order.save();
    console.log(`📦 Orden ${orderId} actualizada a estado: ${status}`);
    
    return updatedOrder;
  }

  // Obtener estadísticas de versiones de API (para prueba #9)
  async getApiVersionStats(): Promise<any> {
    const v1Count = await this.orderModel.countDocuments({ apiVersion: 'v1' });
    const v2Count = await this.orderModel.countDocuments({ apiVersion: 'v2' });
    const total = v1Count + v2Count;

    const v1Percentage = total > 0 ? (v1Count / total) * 100 : 0;
    const v2Percentage = total > 0 ? (v2Count / total) * 100 : 0;

    return {
      total,
      v1: {
        count: v1Count,
        percentage: parseFloat(v1Percentage.toFixed(2))
      },
      v2: {
        count: v2Count,
        percentage: parseFloat(v2Percentage.toFixed(2))
      },
      timestamp: new Date()
    };
  }

  // Obtener métricas de órdenes por estado
  async getOrderMetrics(): Promise<any> {
    const total = await this.orderModel.countDocuments();
    const byStatus = await this.orderModel.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    const statusCounts = {};
    byStatus.forEach(item => {
      statusCounts[item._id] = item.count;
    });

    return {
      total,
      byStatus: statusCounts,
      timestamp: new Date()
    };
  }
} 