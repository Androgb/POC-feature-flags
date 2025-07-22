import { Module } from '@nestjs/common';
import { FlagsController } from './flags.controller';
import { FlagsService } from './flags.service';
import { ConfigCatService } from './configcat.service';
import { LaunchDarklyService } from './launchdarkly.service';
import { FeatureFlagsProviderFactory } from './providers/feature-flags-provider.factory';

@Module({
  controllers: [FlagsController],
  providers: [
    FlagsService,
    ConfigCatService,
    LaunchDarklyService,
    FeatureFlagsProviderFactory, // Factory dinámico para seleccionar provider
  ],
  exports: [FlagsService], // Solo exportar FlagsService que usa el provider dinámico
})
export class FlagsModule {} 