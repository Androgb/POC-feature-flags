#!/bin/bash

# Script para cambiar a LaunchDarkly como proveedor de feature flags

echo "🔄 Cambiando proveedor de feature flags a LaunchDarkly..."

# Verificar si existe el archivo .env
if [ ! -f "backend/.env" ]; then
    echo "❌ Error: archivo backend/.env no encontrado"
    echo "💡 Copia backend/.env.example a backend/.env y configura las variables"
    exit 1
fi

# Función para actualizar o agregar variable en .env
update_env_var() {
    local key=$1
    local value=$2
    local env_file="backend/.env"
    
    if grep -q "^${key}=" "$env_file"; then
        # Actualizar variable existente
        sed -i "s/^${key}=.*/${key}=${value}/" "$env_file"
        echo "✅ Actualizado: ${key}=${value}"
    else
        # Agregar nueva variable
        echo "${key}=${value}" >> "$env_file"
        echo "✅ Agregado: ${key}=${value}"
    fi
}

# Configurar proveedor
update_env_var "FEATURE_FLAGS_PROVIDER" "launchdarkly"

# Verificar que las variables de LaunchDarkly estén configuradas
if ! grep -q "^LAUNCHDARKLY_SDK_KEY=" "backend/.env"; then
    echo "⚠️ Agregando LaunchDarkly SDK Key placeholder..."
    update_env_var "LAUNCHDARKLY_SDK_KEY" "sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    echo ""
    echo "🚨 IMPORTANTE: Configura tu LaunchDarkly SDK Key real:"
    echo "   1. Ve a https://app.launchdarkly.com"
    echo "   2. Crea cuenta y proyecto"
    echo "   3. Obtén Server-side SDK Key"
    echo "   4. Reemplaza el valor en backend/.env"
    echo ""
fi

# Configurar variables adicionales de LaunchDarkly
if ! grep -q "^LAUNCHDARKLY_STREAMING=" "backend/.env"; then
    update_env_var "LAUNCHDARKLY_STREAMING" "true"
fi

if ! grep -q "^LAUNCHDARKLY_TIMEOUT=" "backend/.env"; then
    update_env_var "LAUNCHDARKLY_TIMEOUT" "5000"
fi

echo ""
echo "🎯 Configuración actual:"
echo "   Provider: LaunchDarkly"

# Mostrar SDK Key si está configurada
if grep -q "^LAUNCHDARKLY_SDK_KEY=" "backend/.env"; then
    SDK_KEY=$(grep '^LAUNCHDARKLY_SDK_KEY=' backend/.env | cut -d'=' -f2)
    if [[ "$SDK_KEY" != "sdk-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" ]]; then
        echo "   SDK Key: ${SDK_KEY:0:20}..."
    else
        echo "   SDK Key: ⚠️ PLACEHOLDER - necesita configuración real"
    fi
fi

echo ""
echo "📋 Flags requeridos en LaunchDarkly:"
echo "   • enable_payments (Boolean)"
echo "   • promo_banner_color (String: green/blue/red)"
echo "   • orders_api_version (String: v1/v2)"
echo "   • new_feature_enabled (Boolean)"
echo "   • simulate_errors (Boolean)"
echo ""
echo "🚀 Para aplicar los cambios:"
echo "   cd backend && npm run start:dev"
echo ""
echo "🧪 Para verificar:"
echo "   curl http://localhost:3001/health/flags"