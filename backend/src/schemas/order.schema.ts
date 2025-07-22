import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type OrderDocument = Order & Document;

@Schema({ timestamps: true })
export class Order {
  @Prop({ required: true })
  orderId: string;

  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  paymentId: string;

  @Prop({ required: true, enum: ['v1', 'v2'], default: 'v1' })
  apiVersion: string;

  @Prop({ required: true })
  items: Array<{
    productId: string;
    name: string;
    quantity: number;
    price: number;
  }>;

  @Prop({ required: true })
  totalAmount: number;

  @Prop({ 
    required: true, 
    enum: ['draft', 'confirmed', 'shipped', 'delivered', 'cancelled'],
    default: 'draft'
  })
  status: string;

  @Prop({ type: Object, default: {} })
  shippingInfo: Record<string, any>;

  @Prop({ type: Object, default: {} })
  metadata: Record<string, any>;

  @Prop({ type: Array, default: [] })
  logs: Array<{
    timestamp: Date;
    action: string;
    details: string;
    apiVersion: string;
  }>;
}

export const OrderSchema = SchemaFactory.createForClass(Order); 