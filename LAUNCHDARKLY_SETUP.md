# LaunchDarkly Setup & Provider Switching

## 🎯 Arquitectura de Feature Flags Multi-Provider

Este proyecto soporta **ConfigCat** y **LaunchDarkly** como proveedores de feature flags usando el **Strategy Pattern**.

### 📋 Variables de Entorno Requeridas

Crea un archivo `.env` en `backend/` con las siguientes variables:

```bash
# ==========================================
# CONFIGURACIÓN GENERAL
# ==========================================
NODE_ENV=development
PORT=3001

# ==========================================
# FEATURE FLAGS PROVIDER SELECTION
# ==========================================
# Opciones: 'configcat' | 'launchdarkly'
FEATURE_FLAGS_PROVIDER=configcat

# ==========================================
# CONFIGCAT CONFIGURATION
# ==========================================
CONFIGCAT_SDK_KEY=configcat-sdk-1/psXdCCevYUOCuYEqRQENww/Kz0qzczpFkip_aiovxePiQ
CONFIGCAT_POLLING_INTERVAL=30
CONFIGCAT_TIMEOUT=5000

# ==========================================
# LAUNCHDARKLY CONFIGURATION
# ==========================================
LAUNCHDARKLY_SDK_KEY=sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
LAUNCHDARKLY_STREAMING=true
LAUNCHDARKLY_TIMEOUT=5000

# ==========================================
# DATABASE (MongoDB)
# ==========================================
MONGODB_URI=mongodb://localhost:27017/payments-db
```

## 🔄 Cómo Alternar entre Proveedores

### Método 1: Variable de Entorno (Recomendado)

1. **Para usar ConfigCat:**
   ```bash
   FEATURE_FLAGS_PROVIDER=configcat
   ```

2. **Para usar LaunchDarkly:**
   ```bash
   FEATURE_FLAGS_PROVIDER=launchdarkly
   ```

3. **Reiniciar el backend:**
   ```bash
   cd backend
   npm run start:dev
   ```

### Método 2: Script de Cambio Dinámico

```bash
# Cambiar a LaunchDarkly
./scripts/switch-to-launchdarkly.sh

# Cambiar a ConfigCat  
./scripts/switch-to-configcat.sh
```

## 📦 Instalación de Dependencias

### Instalar LaunchDarkly SDK

```bash
cd backend
npm install @launchdarkly/node-server-sdk
```

### Verificar Dependencias Actuales

```bash
npm list | grep -E "(configcat|launchdarkly)"
```

## 🏗️ Arquitectura del Sistema

```
FlagsService
     ↓
FeatureFlagsProviderFactory
     ↓
┌─────────────────┬─────────────────┐
│   ConfigCat     │  LaunchDarkly   │
│   Service       │     Service     │
└─────────────────┴─────────────────┘
```

### Interface Común (IFeatureFlagsProvider)

```typescript
interface IFeatureFlagsProvider {
  getFlag(key: string, userId?: string, defaultValue?: any): Promise<any>;
  getAllFlags(userId?: string): Promise<Record<string, any>>;
  getBannerColor(userId?: string): Promise<string>;
  getApiVersion(userId?: string): Promise<string>;
  isConnected(): Promise<boolean>;
  getClientInfo(): any;
  getFallbackFlags(): Record<string, any>;
}
```

## 🚀 Setup LaunchDarkly

### 1. Crear Cuenta LaunchDarkly

1. Ir a [app.launchdarkly.com](https://app.launchdarkly.com)
2. Crear cuenta gratuita
3. Crear nuevo proyecto "payments-app"

### 2. Obtener SDK Key

1. **Projects** → **payments-app** → **Environments**
2. Copiar **Server-side SDK key** de environment "development"
3. Agregar a `.env`:
   ```bash
   LAUNCHDARKLY_SDK_KEY=sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

### 3. Crear Feature Flags

Crear los siguientes flags en LaunchDarkly dashboard:

| Flag Key | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_payments` | Boolean | `true` | Kill-switch principal |
| `promo_banner_color` | String | `"green"` | Color del banner promocional |
| `orders_api_version` | String | `"v1"` | Versión de API de órdenes |
| `new_feature_enabled` | Boolean | `false` | Nueva funcionalidad |
| `simulate_errors` | Boolean | `false` | Simulación de errores |

### 4. Configurar Targeting (Opcional)

- **Gradual rollout**: Usar percentage rollouts para `new_feature_enabled`
- **User segments**: Crear segmentos por region/role
- **Prerequisites**: Configurar dependencias entre flags

## 🧪 Testing con LaunchDarkly

### Ejecutar las 15 Pruebas

```bash
# Cambiar a LaunchDarkly
export FEATURE_FLAGS_PROVIDER=launchdarkly

# Ejecutar pruebas
./run-all-tests-launchdarkly.sh
```

### Verificar Conectividad

```bash
curl http://localhost:3001/health/flags
```

**Respuesta esperada:**
```json
{
  "status": "ok",
  "flags": {
    "enable_payments": true,
    "promo_banner_color": "green",
    "orders_api_version": "v1"
  },
  "configcat": {
    "connected": false
  },
  "launchdarkly": {
    "connected": true,
    "provider": "LaunchDarkly"
  }
}
```

## 📊 Comparación ConfigCat vs LaunchDarkly

| Aspecto | ConfigCat | LaunchDarkly |
|---------|-----------|--------------|
| **Flag Types** | Boolean only (free) | Boolean, String, Number, JSON |
| **Multivariante** | ❌ (requires Boolean workaround) | ✅ Native support |
| **Targeting** | Basic percentage | Advanced segments + prerequisites |
| **Audit Trail** | 7 days, downloadable .txt | Real-time, exportable |
| **Pricing** | Free: 2 envs, 10 flags | Free: 14-day trial |
| **SDKs** | ✅ Node.js + Web | ✅ Extensive SDK support |

## 🚨 Troubleshooting

### Error: SDK Key Inválido
```bash
# Verificar formato
echo $LAUNCHDARKLY_SDK_KEY | grep -E "^sdk-[a-f0-9-]{36}$"
```

### Error: Module Not Found  
```bash
cd backend
npm install @launchdarkly/node-server-sdk
```

### Error: Provider Not Switching
```bash
# Verificar logs de startup
tail -f backend/logs/app.log | grep "proveedor de feature flags"
```

## 📚 Documentación Adicional

- [LaunchDarkly Node.js SDK](https://docs.launchdarkly.com/sdk/server-side/node-js)
- [ConfigCat Node.js SDK](https://configcat.com/docs/sdk-reference/node/)
- [Feature Flags Best Practices](https://launchdarkly.com/blog/feature-flag-best-practices/) 