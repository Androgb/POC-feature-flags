export interface FlagAuditEntry {
  timestamp: Date;
  user: string;
  flagKey: string;
  previousValue: any;
  newValue: any;
  environment: string;
}

export interface IFeatureFlagsProvider {
  // Métodos principales de feature flags
  getFlag(key: string, userId?: string, defaultValue?: any): Promise<any>;
  getAllFlags(userId?: string): Promise<Record<string, any>>;
  
  // Métodos específicos para tipos complejos
  getBannerColor(userId?: string): Promise<string>;
  getApiVersion(userId?: string): Promise<string>;
  
  // Health check y conectividad
  isConnected(): Promise<boolean>;
  getClientInfo(): any;
  
  // Fallback y valores por defecto
  getFallbackFlags(): Record<string, any>;
  
  // Audit y historial (opcional)
  updateFlag?(key: string, value: any, userId?: string): void;
  getAuditLog?(): FlagAuditEntry[];
  
  // Lifecycle methods
  onModuleInit?(): Promise<void>;
  onModuleDestroy?(): Promise<void>;
}

export interface FeatureFlagsConfig {
  provider: 'configcat' | 'launchdarkly';
  apiKey?: string;
  environment?: string;
  polling?: {
    interval: number;
    timeout: number;
  };
} 