#!/bin/bash

# Script para cambiar a ConfigCat como proveedor de feature flags

echo "🔄 Cambiando proveedor de feature flags a ConfigCat..."

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
update_env_var "FEATURE_FLAGS_PROVIDER" "configcat"

# Verificar que las variables de ConfigCat estén configuradas
if ! grep -q "^CONFIGCAT_SDK_KEY=" "backend/.env"; then
    echo "⚠️ Agregando ConfigCat SDK Key por defecto..."
    update_env_var "CONFIGCAT_SDK_KEY" "configcat-sdk-1/psXdCCevYUOCuYEqRQENww/Kz0qzczpFkip_aiovxePiQ"
fi

echo ""
echo "🎯 Configuración actual:"
echo "   Provider: ConfigCat"
echo "   SDK Key: $(grep '^CONFIGCAT_SDK_KEY=' backend/.env | cut -d'=' -f2 | head -c 30)..."
echo ""
echo "🚀 Para aplicar los cambios:"
echo "   cd backend && npm run start:dev"
echo ""
echo "🧪 Para verificar:"
echo "   curl http://localhost:3001/health/flags" 