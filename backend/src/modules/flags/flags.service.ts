import { Injectable, Inject } from '@nestjs/common';
import { ConfigCatService } from './configcat.service';

@Injectable()
export class FlagsService {
  constructor(
    private readonly configCatService: ConfigCatService
  ) {}

  // Obtener valor de flag usando ConfigCat
  async getFlag(key: string, userId?: string, defaultValue: any = false): Promise<any> {
    return await this.configCatService.getFlag(key, userId, defaultValue);
  }

  // Obtener todos los flags usando ConfigCat
  async getAllFlags(userId?: string): Promise<Record<string, any>> {
    return await this.configCatService.getAllFlags(userId);
  }

  // Simular actualización de flag (en ConfigCat real se hace desde dashboard)
  updateFlag(key: string, value: any, userId: string = 'admin'): void {
    console.log(`🚩 [FlagsService] Actualizando flag ${key} = ${value}`);
    console.log('💡 Nota: En ConfigCat real, actualiza este flag desde el dashboard web');
    
    // Registrar en audit log para compatibilidad
    this.configCatService.updateFlag(key, value, userId);
  }

  // Obtener audit log
  getAuditLog(): Array<any> {
    return this.configCatService.getAuditLog();
  }

  // Health check de conectividad con ConfigCat
  async isConnected(): Promise<boolean> {
    return await this.configCatService.isConfigCatConnected();
  }

  // Obtener información del cliente ConfigCat
  getClientInfo(): any {
    return this.configCatService.getClientInfo();
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