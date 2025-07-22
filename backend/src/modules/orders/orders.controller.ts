import { Controller, Get, Post, Body, Param, Put, Query } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { CreateOrderDto, CreateOrderV2Dto } from '../../dto/create-order.dto';
import { FlagsService } from '../flags/flags.service';

@Controller('orders')
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly flagsService: FlagsService,
  ) {}

  // Endpoint universal que usa flag para determinar versión (prueba #9)
  @Post()
  async createOrder(@Body() createOrderDto: CreateOrderDto) {
    try {
      const order = await this.ordersService.createOrder(createOrderDto);
      return {
        success: true,
        order,
        apiVersion: order.apiVersion,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: error.message,
          code: 'ORDER_CREATION_ERROR'
        },
        timestamp: new Date()
      };
    }
  }

  // Endpoint específico v2 (para testing directo)
  @Post('v2')
  async createOrderV2(@Body() createOrderV2Dto: CreateOrderV2Dto) {
    try {
      const order = await this.ordersService.createOrderV2(createOrderV2Dto);
      return {
        success: true,
        order,
        apiVersion: 'v2',
        features: {
          promotionCode: !!createOrderV2Dto.promotionCode,
          discountApplied: !!createOrderV2Dto.discountAmount,
          shippingPreferences: !!createOrderV2Dto.shippingPreferences
        },
        timestamp: new Date()
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: error.message,
          code: 'ORDER_V2_CREATION_ERROR'
        },
        timestamp: new Date()
      };
    }
  }

  // Obtener todas las órdenes
  @Get()
  async getAllOrders(@Query('userId') userId?: string) {
    const orders = await this.ordersService.getAllOrders(userId);
    return {
      orders,
      count: orders.length,
      timestamp: new Date()
    };
  }

  // Obtener orden específica
  @Get(':orderId')
  async getOrder(@Param('orderId') orderId: string) {
    try {
      const order = await this.ordersService.getOrder(orderId);
      return {
        order,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        error: {
          message: error.message,
          code: 'ORDER_NOT_FOUND'
        },
        timestamp: new Date()
      };
    }
  }

  // Actualizar estado de orden
  @Put(':orderId/status')
  async updateOrderStatus(
    @Param('orderId') orderId: string,
    @Body() body: { status: string; userId: string }
  ) {
    try {
      const order = await this.ordersService.updateOrderStatus(
        orderId, 
        body.status, 
        body.userId
      );
      return {
        success: true,
        order,
        timestamp: new Date()
      };
    } catch (error) {
      return {
        success: false,
        error: {
          message: error.message,
          code: 'ORDER_UPDATE_ERROR'
        },
        timestamp: new Date()
      };
    }
  }

  // Estadísticas de versiones de API (prueba #9)
  @Get('stats/api-versions')
  async getApiVersionStats() {
    const stats = await this.ordersService.getApiVersionStats();
    const currentFlag = await this.flagsService.getFlag('orders_api_version', undefined, 'v1');
    
    return {
      stats,
      currentFlag: {
        orders_api_version: currentFlag
      },
      analysis: {
        v1Decreasing: stats.v1.percentage < 90,
        v2Adoption: stats.v2.percentage,
        migrationProgress: stats.v2.percentage > 0 ? 'in-progress' : 'not-started'
      },
      timestamp: new Date()
    };
  }

  // Métricas generales de órdenes
  @Get('stats/metrics')
  async getOrderMetrics() {
    const metrics = await this.ordersService.getOrderMetrics();
    return {
      metrics,
      timestamp: new Date()
    };
  }
} 