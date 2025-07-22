import { Provider } from '@nestjs/common';
import { ConfigCatService } from '../configcat.service';
import { LaunchDarklyService } from '../launchdarkly.service';
import { IFeatureFlagsProvider } from '../interfaces/feature-flags-provider.interface';

export const FEATURE_FLAGS_PROVIDER = 'FEATURE_FLAGS_PROVIDER';

export const FeatureFlagsProviderFactory: Provider = {
  provide: FEATURE_FLAGS_PROVIDER,
  useFactory: (
    configCatService: ConfigCatService,
    launchDarklyService: LaunchDarklyService,
  ): IFeatureFlagsProvider => {
    const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
    
    console.log(`🚩 Seleccionando proveedor de feature flags: ${provider}`);
    
    switch (provider.toLowerCase()) {
      case 'launchdarkly':
        console.log('✅ Usando LaunchDarkly como proveedor de feature flags');
        return launchDarklyService;
      case 'configcat':
      default:
        console.log('✅ Usando ConfigCat como proveedor de feature flags');
        return configCatService;
    }
  },
  inject: [ConfigCatService, LaunchDarklyService],
};

// Utilidad para obtener configuración del proveedor
export function getProviderConfig() {
  const provider = process.env.FEATURE_FLAGS_PROVIDER || 'configcat';
  const environment = process.env.NODE_ENV || 'development';
  
  return {
    provider: provider as 'configcat' | 'launchdarkly',
    environment,
    configcat: {
      sdkKey: process.env.CONFIGCAT_SDK_KEY,
      polling: {
        interval: parseInt(process.env.CONFIGCAT_POLLING_INTERVAL || '30'),
        timeout: parseInt(process.env.CONFIGCAT_TIMEOUT || '5000'),
      }
    },
    launchdarkly: {
      sdkKey: process.env.LAUNCHDARKLY_SDK_KEY,
      streaming: process.env.LAUNCHDARKLY_STREAMING !== 'false',
      timeout: parseInt(process.env.LAUNCHDARKLY_TIMEOUT || '5000'),
    }
  };
} 