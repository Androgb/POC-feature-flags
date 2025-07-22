# Tests de Feature Flags - ConfigCat Integration

## Estructura Organizada de Tests

### 📁 Organización por Número de Test

```
tests/
├── 02-environments/           # Test #2: Environments (dev/staging/prod)
├── 03-backend-flags/          # Test #3: Backend flag reading
├── 04-frontend-flags/         # Test #4: Frontend flag reading  
├── 05-propagation/            # Test #5: Change propagation timing
├── 06-kill-switch/            # Test #6: Kill-switch functionality
├── 07-gradual-rollout/        # Test #7: Gradual rollout percentage
├── 08-multivariante/          # Test #8: Multivariante testing (CANCELLED)
│   └── test-08-multivariante-banner.sh
├── 09-api-versioning/         # Test #9: API versioning v1/v2
│   └── test-09-api-versioning-simple.sh
├── 10-rollback/               # Test #10: Immediate rollback
│   └── test-10-rollback-immediate.sh
├── 11-audit-history/          # Test #11: Audit trail and history
│   └── test-11-audit-history-real.sh
├── 12-rbac/                   # Test #12: RBAC permissions (CANCELLED)
├── 13-alerts-metrics/         # Test #13: Alerts and metrics
│   └── test-13-alerts-metrics-optimized.sh
├── 14-offline-fallback/       # Test #14: Offline fallback behavior
│   └── test-14-offline-fallback-complete.sh
└── 15-limits/                 # Test #15: ConfigCat plan limits
```

### 🏃‍♂️ Cómo Ejecutar Tests

#### Test Individual
```bash
cd tests/[numero]-[nombre]/
chmod +x test-[numero]-*.sh
./test-[numero]-*.sh
```

#### Ejemplo:
```bash
cd tests/09-api-versioning/
chmod +x test-09-api-versioning-simple.sh
./test-09-api-versioning-simple.sh
```

### ✅ Estado de Tests

| Test # | Nombre | Estado | Archivo | Notas |
|--------|--------|--------|---------|-------|
| #2 | Environments | ✅ COMPLETED | - | Manual via dashboard |
| #3 | Backend Flags | ✅ COMPLETED | - | Manual via dashboard |
| #4 | Frontend Flags | ✅ COMPLETED | - | Manual via dashboard |
| #5 | Propagation | ✅ COMPLETED | - | Manual via dashboard |
| #6 | Kill-switch | ✅ COMPLETED | - | Manual via dashboard |
| #7 | Gradual Rollout | ✅ COMPLETED | - | Manual via dashboard |
| #8 | Multivariante | ❌ CANCELLED | test-08-multivariante-banner.sh | Boolean flags = no exact distribution |
| #9 | API Versioning | ✅ COMPLETED | test-09-api-versioning-simple.sh | v1/v2 dual mode |
| #10 | Rollback | ✅ COMPLETED | test-10-rollback-immediate.sh | Error simulation + recovery |
| #11 | Audit History | ✅ COMPLETED | test-11-audit-history-real.sh | ConfigCat + operational logs |
| #12 | RBAC | ❌ CANCELLED | - | Requires Team plan ($99/month) |
| #13 | Alerts/Metrics | ✅ COMPLETED | test-13-alerts-metrics-optimized.sh | Partial: system works, threshold not reached |
| #14 | Offline Fallback | ✅ COMPLETED | test-14-offline-fallback-complete.sh | Fallback system verified |
| #15 | Limits/Scale | ✅ COMPLETED | - | Manual: 2 environments, 10 flags max |

### 📊 Tests con Dashboard Real vs Simulación

#### ✅ Tests realizados CON DASHBOARD REAL de ConfigCat:
- **Test #2**: Environments - Flags creados en dev/staging/prod via dashboard
- **Test #3**: Backend flags - Lectura real desde ConfigCat dashboard
- **Test #4**: Frontend flags - UI refleja cambios reales del dashboard  
- **Test #5**: Propagation - Cambios manuales en dashboard, medición real
- **Test #6**: Kill-switch - Toggle manual en dashboard, observación efectos
- **Test #7**: Gradual rollout - Configuración porcentajes en dashboard
- **Test #11**: Audit history - Descarga real de audit logs desde dashboard
- **Test #13**: Alerts/metrics - Dashboard `/payments/metrics/dashboard` operativo
- **Test #15**: Limits - Verificación manual límites plan gratuito

#### 🤖 Tests automatizados (scripts):
- **Test #8**: Script para validar distribución (CANCELLED por limitaciones)
- **Test #9**: Script para probar versioning API automático
- **Test #10**: Script para simular errores y rollback
- **Test #14**: Script para verificar fallback offline

### 🚀 Requisitos Previos

1. **Backend corriendo**: `cd backend && npm run start:dev`
2. **Frontend corriendo**: `cd frontend && npm run dev`  
3. **Variables de entorno**: `.env` con `CONFIGCAT_SDK_KEY`
4. **Herramientas**: `curl`, `jq`, `bc` instalados

### 📝 Limitaciones Encontradas

#### ConfigCat Plan Gratuito:
- ✅ **Permitido**: 2 entornos (development, staging)
- ✅ **Permitido**: 10 feature flags máximo
- ✅ **Permitido**: Audit logs (7 días retención)
- ✅ **Permitido**: API access, webhooks, SDK integration
- ❌ **Bloqueado**: Múltiples usuarios/roles (requiere Team plan)
- ❌ **Bloqueado**: Custom permissions (requiere Team plan)
- ❌ **Bloqueado**: Production environment (requiere pro plan)

#### Multivariante Testing:
- ❌ **No viable**: Boolean flags separados no garantizan distribución exacta
- ❌ **No viable**: Pueden superponerse o crear gaps
- ✅ **Alternativa**: Usar string flags con valores definidos (requiere plan superior)

### 🔗 Enlaces Útiles

- [ConfigCat Dashboard](https://app.configcat.com)
- [API Metrics Dashboard](http://localhost:3000/payments/metrics/dashboard)
- [Health Check](http://localhost:3000/api/health/flags)
- [Connectivity Check](http://localhost:3000/api/health/flags/connectivity) 