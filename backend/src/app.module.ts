import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { PaymentsModule } from './modules/payments/payments.module';
import { FlagsModule } from './modules/flags/flags.module';
import { UsersModule } from './modules/users/users.module';
import { OrdersModule } from './modules/orders/orders.module';
import { HealthModule } from './modules/health/health.module';
import { GlobalController } from './global.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    MongooseModule.forRoot(
      process.env.MONGODB_URI || 'mongodb://localhost:27017/payments-api'
    ),
    PaymentsModule,
    FlagsModule,
    UsersModule,
    OrdersModule,
    HealthModule,
  ],
  controllers: [GlobalController],
})
export class AppModule {} 