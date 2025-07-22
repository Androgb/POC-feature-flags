# Tests LaunchDarkly

Esta carpeta contiene las 15 pruebas adaptadas para LaunchDarkly como proveedor de feature flags.

## 🎯 Objetivo

Replicar exactamente las mismas 15 pruebas realizadas con ConfigCat pero usando LaunchDarkly para evaluar:

1. **Funcionalidad**: ¿LaunchDarkly funciona igual de bien?
2. **Performance**: ¿Qué tan rápido es en comparación?
3. **Features**: ¿Qué ventajas/desventajas tiene?
4. **Experiencia**: ¿Qué tan fácil es de usar?

## 📋 Lista de Pruebas

| # | Test | Estado | Archivo |
|---|------|--------|---------|
| 2 | Creación de flags en múltiples entornos | ⏳ Pendiente | `test-02-flag-creation.md` |
| 3 | Lectura del flag en backend | ⏳ Pendiente | `test-03-backend-reading.sh` |
| 4 | Lectura del flag en frontend | ⏳ Pendiente | `test-04-frontend-reading.sh` |
| 5 | Propagación del cambio | ⏳ Pendiente | `test-05-propagation.sh` |
| 6 | Kill-switch | ⏳ Pendiente | `test-06-killswitch.sh` |
| 7 | Roll-out gradual | ⏳ Pendiente | `test-07-gradual-rollout.sh` |
| 8 | Multivariante | ⏳ Pendiente | `test-08-multivariate.sh` |
| 9 | Versión de contrato (v1 ↔ v2) | ⏳ Pendiente | `test-09-api-versioning.sh` |
| 10 | Rollback inmediato | ⏳ Pendiente | `test-10-rollback.sh` |
| 11 | Historial / auditoría | ⏳ Pendiente | `test-11-audit-history.sh` |
| 12 | Roles y permisos (RBAC) | ⏳ Pendiente | `test-12-rbac.md` |
| 13 | Alertas o métricas integradas | ⏳ Pendiente | `test-13-alerts-metrics.sh` |
| 14 | Fallo de red / SDK offline | ⏳ Pendiente | `test-14-offline-fallback.sh` |
| 15 | Límites de flags y entornos | ⏳ Pendiente | `test-15-limits-scaling.md` |

## 🚀 Ejecutar Todas las Pruebas

```bash
# Cambiar a LaunchDarkly
./scripts/switch-to-launchdarkly.sh

# Ejecutar todas las pruebas
./tests/launchdarkly/run-all-tests.sh
```

## 🎯 Setup Requerido

1. **Cuenta LaunchDarkly**
   - Crear cuenta en [app.launchdarkly.com](https://app.launchdarkly.com)
   - Crear proyecto "payments-app"
   - Obtener Server-side SDK Key

2. **Configurar Variables**
   ```bash
   FEATURE_FLAGS_PROVIDER=launchdarkly
   LAUNCHDARKLY_SDK_KEY=sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

3. **Crear Flags**
   - `enable_payments` (Boolean)
   - `promo_banner_color` (String)
   - `orders_api_version` (String)
   - `new_feature_enabled` (Boolean)
   - `simulate_errors` (Boolean)

## 📊 Resultados Esperados

Al finalizar tendremos una comparación completa:

```
ConfigCat vs LaunchDarkly
├── Funcionalidad: ✅ / ✅
├── Performance: Xms vs Yms
├── Facilidad de uso: A vs B
├── Características: 7/15 vs 12/15
└── Costo: Free vs Trial
```

## 🔄 Volver a ConfigCat

```bash
./scripts/switch-to-configcat.sh
``` 