import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type PaymentDocument = Payment & Document;

@Schema({ timestamps: true })
export class Payment {
  @Prop({ required: true })
  paymentId: string;

  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  amount: number;

  @Prop({ required: true })
  currency: string;

  @Prop({ 
    required: true, 
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled'],
    default: 'pending'
  })
  status: string;

  @Prop({ required: true })
  method: string; // card, paypal, etc.

  @Prop()
  description: string;

  @Prop({ type: Object, default: {} })
  metadata: Record<string, any>;

  @Prop({ type: Array, default: [] })
  logs: Array<{
    timestamp: Date;
    action: string;
    details: string;
    flagsUsed?: Record<string, any>;
  }>;
}

export const PaymentSchema = SchemaFactory.createForClass(Payment); 