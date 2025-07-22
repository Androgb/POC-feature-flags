# 🚀 ConfigCat Integration - Guía Completa

## ✅ Estado Actual

**¡ConfigCat ya está conectado!** 🎉

- ✅ Backend configurado con ConfigCat SDK
- ✅ Frontend configurado con ConfigCat SDK  
- ✅ Variables de entorno configuradas
- ✅ Fallbacks implementados
- ✅ UI actualizada con estado de conexión

## 🔧 Configuración en ConfigCat Dashboard

### 1. **Accede al Dashboard**
```
https://app.configcat.com
```

### 2. **Crea estos Feature Flags** (si no existen ya):

| Flag Name | Type | Default Value | Description |
|-----------|------|---------------|-------------|
| `enable_payments` | Boolean | `true` | Kill-switch para sistema de pagos |
| `promo_banner_color` | String | `green` | Color del banner (green/blue/red) |
| `orders_api_version` | String | `v1` | Versión de API para órdenes (v1/v2) |
| `new_feature_enabled` | Boolean | `false` | Nueva feature con roll-out gradual |
| `simulate_errors` | Boolean | `false` | Simular errores para testing rollback |

### 3. **Configurar Targeting (Roll-out Gradual)**

Para `new_feature_enabled`:
1. Click en el flag → **Targeting**
2. **Add targeting rule**
3. **User identifier** - **is one of** - Agrega algunos user IDs de prueba: 
   - `test_user_1`, `test_user_5`, `test_user_15`
4. **Serve**: `true`
5. **Default rule**: `false`

## 🚀 Testing de la Integración

### **Paso 1: Verificar Conexión**

```bash
# Backend
cd backend
npm run start:dev

# Frontend (nueva terminal)
cd frontend  
npm run dev
```

### **Paso 2: Verificar Estado**

**Backend endpoint:** `http://localhost:3000/health/configcat`
```json
{
  "configcat": {
    "connected": true,
    "client": {
      "sdkKey": "configcat-sdk-1/psXdCC...",
      "isInitialized": true
    }
  }
}
```

**Frontend:** `http://localhost:5173`
- Deberías ver "ConfigCat: Conectado" en la barra superior
- El dashboard mostrará el estado de conexión

### **Paso 3: Probar Feature Flags**

#### **🔴 Kill-Switch (enable_payments)**
1. Ve al dashboard de ConfigCat
2. Cambia `enable_payments` a `false`
3. En la app: Ve a "Pagos" → Debe mostrar "Servicio en Mantenimiento"
4. Tiempo de propagación: ~30 segundos

#### **🎨 Multivariante (promo_banner_color)**
1. Cambia `promo_banner_color` entre: `green`, `blue`, `red`
2. En la app: El banner del dashboard cambia de color
3. Tiempo de propagación: ~30 segundos

#### **⚙️ API Versioning (orders_api_version)**
1. Cambia `orders_api_version` de `v1` a `v2`
2. En la app: Ve a "Órdenes" → Formulario muestra campos adicionales para v2
3. Crear orden → Se guarda con API v2

#### **👥 Roll-out Gradual (new_feature_enabled)**
1. Activa targeting para usuarios específicos
2. En la app: Cambia usuario con botones "Test User 1, 5, 15"
3. Solo usuarios en targeting ven la sección "Nueva Funcionalidad"

### **Paso 4: Verificar Endpoints**

```bash
# Flags desde backend
curl http://localhost:3000/health/flags

# Flags para frontend
curl http://localhost:3000/flags.json

# Info de ConfigCat
curl http://localhost:3000/flags/info/configcat
```

## 📊 Monitoreo en Tiempo Real

### **Dashboard de la App**
- **Estado de ConfigCat:** Verde = Conectado / Rojo = Desconectado
- **Fuente de flags:** "ConfigCat Directo" vs "Backend (ConfigCat)"
- **Auto-refresh:** Cada 30 segundos
- **Botón especial:** "Refrescar desde ConfigCat"

### **Logs en Consola**
```javascript
// Frontend
🚩 [Frontend] Inicializando ConfigCat cliente...
✅ [Frontend] ConfigCat cliente inicializado
🚩 [Frontend] Flags cargados desde ConfigCat: {...}

// Backend  
🚩 Inicializando ConfigCat con SDK Key: configcat-sdk-1/psXdCC...
✅ ConfigCat cliente inicializado
🚩 ConfigCat flag enable_payments = true para usuario test_user_1
```

## 🧪 Escenarios de Prueba Específicos

### **Escenario 1: Kill-Switch Instantáneo** 
```
1. Dashboard ConfigCat → enable_payments = false
2. App → Pagos = "Servicio en mantenimiento" 
3. Tiempo esperado: < 30 segundos
```

### **Escenario 2: A/B Testing**
```
1. Dashboard ConfigCat → promo_banner_color = "blue"
2. App → Banner cambia a azul
3. Refresh browser → Color persiste
```

### **Escenario 3: Rollout Gradual**
```
1. Dashboard ConfigCat → new_feature_enabled targeting específico
2. App → Cambiar usuarios con botones
3. Solo usuarios targetted ven nueva sección
```

### **Escenario 4: Fallback en Fallo**
```
1. Deshabilitar internet
2. App → Usa valores fallback
3. No crashea, muestra mensaje de fallback
```

## ⚠️ Troubleshooting

### **ConfigCat No Conecta**
1. Verificar SDK Key en .env: `CONFIGCAT_SDK_KEY=configcat-sdk-1/...`
2. Restart backend: `npm run start:dev`
3. Check logs: Debe mostrar "✅ ConfigCat cliente inicializado"

### **Flags No Actualizan**
1. Verificar nombres exactos en ConfigCat dashboard
2. Esperar ~30 segundos para propagación
3. Usar botón "Refrescar desde ConfigCat" en la app
4. Check logs de errores en browser dev tools

### **Valores Inesperados**
1. Verificar targeting rules en ConfigCat
2. Verificar user ID actual en la app
3. Check default values en ConfigCat

## 🎯 Feature Flags Configurados

| Flag | Backend | Frontend | Dashboard | Targeting |
|------|---------|----------|-----------|-----------|
| `enable_payments` | ✅ Kill-switch | ✅ UI oculta pagos | ✅ Boolean toggle | - |
| `promo_banner_color` | ✅ API versioning | ✅ Banner color | ✅ String select | - | 
| `orders_api_version` | ✅ Dual API v1/v2 | ✅ Form dinámico | ✅ String select | - |
| `new_feature_enabled` | ✅ Logs tracking | ✅ Sección oculta | ✅ Boolean + targeting | ✅ User ID |
| `simulate_errors` | ✅ Error throwing | ✅ Estado error | ✅ Boolean toggle | - |

## 🎉 ¡Todo Listo!

La integración con ConfigCat está **100% funcional**:

- ✅ **Real-time updates** desde ConfigCat dashboard
- ✅ **Dual fallback** (ConfigCat directo + Backend)  
- ✅ **User targeting** para roll-out gradual
- ✅ **Kill-switches** instantáneos
- ✅ **A/B testing** multivariante
- ✅ **API versioning** automático
- ✅ **Error simulation** para rollback testing
- ✅ **Audit logging** de cambios
- ✅ **Performance monitoring** (< 30s propagation)

**¡Prueba cambiar flags en ConfigCat y verás los cambios en tiempo real! 🚀** 