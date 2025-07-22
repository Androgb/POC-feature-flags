import { IsString, IsNumber, IsOptional, IsPositive } from 'class-validator';

export class CreatePaymentDto {
  @IsString()
  userId: string;

  @IsNumber()
  @IsPositive()
  amount: number;

  @IsString()
  currency: string;

  @IsString()
  method: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  metadata?: Record<string, any>;
} 