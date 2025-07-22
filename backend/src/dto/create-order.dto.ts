import { IsString, IsArray, IsNumber, IsOptional, IsEnum, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class OrderItemDto {
  @IsString()
  productId: string;

  @IsString()
  name: string;

  @IsNumber()
  quantity: number;

  @IsNumber()
  price: number;
}

export class CreateOrderDto {
  @IsString()
  userId: string;

  @IsString()
  paymentId: string;

  @IsOptional()
  @IsEnum(['v1', 'v2'])
  apiVersion?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @IsOptional()
  shippingInfo?: Record<string, any>;

  @IsOptional()
  metadata?: Record<string, any>;
}

export class CreateOrderV2Dto extends CreateOrderDto {
  @IsOptional()
  @IsString()
  promotionCode?: string;

  @IsOptional()
  @IsNumber()
  discountAmount?: number;

  @IsOptional()
  shippingPreferences?: {
    express: boolean;
    trackingNotifications: boolean;
    deliveryInstructions?: string;
  };
} 