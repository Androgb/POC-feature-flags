import { Injectable, Inject } from '@nestjs/common';
import { IFeatureFlagsProvider } from './interfaces/feature-flags-provider.interface';
import { FEATURE_FLAGS_PROVIDER } from './providers/feature-flags-provider.factory';

@Injectable()
export class FlagsService {
  constructor(
    @Inject(FEATURE_FLAGS_PROVIDER)
    private readonly provider: IFeatureFlagsProvider
  ) {}

  // Obtener valor de flag usando el proveedor seleccionado
  async getFlag(key: string, userId?: string, defaultValue: any = false): Promise<any> {
    return await this.provider.getFlag(key, userId, defaultValue);
  }

  // Obtener todos los flags usando el proveedor seleccionado
  async getAllFlags(userId?: string): Promise<Record<string, any>> {
    return await this.provider.getAllFlags(userId);
  }

  // Simular actualización de flag (se hace desde dashboard del proveedor)
  updateFlag(key: string, value: any, userId: string = 'admin'): void {
    console.log(`🚩 [FlagsService] Actualizando flag ${key} = ${value}`);
    console.log('💡 Nota: Para actualizar realmente, usar el dashboard del proveedor');
    
    // Registrar en audit log para compatibilidad
    if (this.provider.updateFlag) {
      this.provider.updateFlag(key, value, userId);
    }
  }

  // Obtener audit log
  getAuditLog(): Array<any> {
    return this.provider.getAuditLog?.() || [];
  }

  // Health check de conectividad
  async isConnected(): Promise<boolean> {
    return await this.provider.isConnected();
  }

  // Obtener información del cliente
  getClientInfo(): any {
    return this.provider.getClientInfo();
  }

  // Métodos de compatibilidad con el sistema anterior (síncronos)
  // Estos métodos mantienen compatibilidad pero internamente usan ConfigCat

  // Versión síncrona que usa cache (para compatibilidad)
  getFlagSync(key: string, userId?: string, defaultValue: any = false): any {
    // Como los providers son asíncronos, devolvemos valor fallback
    // En producción real, los providers mantienen un cache interno
    console.warn(`⚠️ Usando getFlagSync para ${key}, considera usar getFlag() asíncrono`);
    
    const fallbacks = this.provider.getFallbackFlags();
    return fallbacks[key] ?? defaultValue;
  }

  // Versión síncrona para todos los flags (para compatibilidad)
  getAllFlagsSync(userId?: string): Record<string, any> {
    console.warn('⚠️ Usando getAllFlagsSync, considera usar getAllFlags() asíncrono');
    return this.provider.getFallbackFlags();
  }

  // Simular fallo de red (para testing)
  simulateNetworkFailure(): boolean {
    // Los fallos de red se manejan automáticamente por el provider
    return false;
  }

  // Obtener valores fallback
  getFallbackFlags(): Record<string, any> {
    return this.provider.getFallbackFlags();
  }
} 