import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { FlagsModule } from '../flags/flags.module';

@Module({
  imports: [FlagsModule],
  controllers: [HealthController],
})
export class HealthModule {} 