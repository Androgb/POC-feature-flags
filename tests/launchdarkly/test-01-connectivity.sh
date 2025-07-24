#!/bin/bash

echo "🧪 Test #1: Conectividad Básica - LaunchDarkly"
echo "============================================="

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Verificar conectividad básica con LaunchDarkly"
echo ""

# Verificar que el backend esté corriendo
echo "🔍 Verificando estado del backend..."
if curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend activo en puerto 3001${NC}"
else
    echo -e "${RED}❌ Backend no responde en puerto 3001${NC}"
    exit 1
fi

echo ""
echo "📊 Test 1: Verificar conexión LaunchDarkly"
echo "-----------------------------------------"

# Verificar respuesta del health endpoint
HEALTH_RESPONSE=$(curl -s http://localhost:3001/health)
PROVIDER_NAME=$(echo "$HEALTH_RESPONSE" | jq -r '.provider.name // "unknown"')
PROVIDER_CONNECTED=$(echo "$HEALTH_RESPONSE" | jq -r '.provider.connected // false')

echo "🔗 Provider detectado: $PROVIDER_NAME"
echo "📡 Estado conexión: $PROVIDER_CONNECTED"

if [ "$PROVIDER_NAME" = "launchdarkly" ] && [ "$PROVIDER_CONNECTED" = "true" ]; then
    echo -e "${GREEN}✅ Conectividad LaunchDarkly exitosa${NC}"
    CONNECTIVITY_OK=true
else
    echo -e "${RED}❌ Problema de conectividad LaunchDarkly${NC}"
    CONNECTIVITY_OK=false
fi

echo ""
echo "📊 Test 2: Verificar SDK initialization"
echo "--------------------------------------"

# Verificar detalles del provider
PROVIDER_INFO=$(echo "$HEALTH_RESPONSE" | jq -r '.provider.info // {}')
IS_INITIALIZED=$(echo "$PROVIDER_INFO" | jq -r '.isInitialized // false')
FLAGS_EXPECTED=$(echo "$PROVIDER_INFO" | jq -r '.flagsExpected // []')

echo "🚀 SDK inicializado: $IS_INITIALIZED"
echo "🏷️  Flags esperados: $(echo "$FLAGS_EXPECTED" | jq length) flags"

if [ "$IS_INITIALIZED" = "true" ]; then
    echo -e "${GREEN}✅ SDK LaunchDarkly inicializado correctamente${NC}"
    INITIALIZATION_OK=true
else
    echo -e "${RED}❌ SDK LaunchDarkly no inicializado${NC}"
    INITIALIZATION_OK=false
fi

echo ""
echo "📊 Test 3: Verificar flags disponibles"
echo "-------------------------------------"

# Verificar endpoint de flags
FLAGS_RESPONSE=$(curl -s http://localhost:3001/health/flags)
FLAGS_COUNT=$(echo "$FLAGS_RESPONSE" | jq '.flags.all | length // 0')

echo "📝 Flags disponibles: $FLAGS_COUNT"

if [ $FLAGS_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ Flags cargados correctamente${NC}"
    FLAGS_OK=true
    
    # Mostrar algunos flags de ejemplo
    echo "📋 Ejemplo de flags:"
    echo "$FLAGS_RESPONSE" | jq '.flags.all | to_entries | .[:3] | .[] | "   • \(.key): \(.value)"' -r
else
    echo -e "${RED}❌ No se pudieron cargar flags${NC}"
    FLAGS_OK=false
fi

echo ""
echo "🎯 Resumen del Test #1:"
echo "======================"

# Evaluar resultado final
if [ "$CONNECTIVITY_OK" = true ] && [ "$INITIALIZATION_OK" = true ] && [ "$FLAGS_OK" = true ]; then
    echo -e "${GREEN}✅ Test #1 PASADO: Conectividad LaunchDarkly exitosa${NC}"
    FINAL_RESULT="PASADO"
elif [ "$CONNECTIVITY_OK" = true ] && [ "$INITIALIZATION_OK" = true ]; then
    echo -e "${YELLOW}⚠️  Test #1 PARCIAL: Conectado pero flags limitados${NC}"
    FINAL_RESULT="PARCIAL"
else
    echo -e "${RED}❌ Test #1 FALLIDO: Problemas de conectividad${NC}"
    FINAL_RESULT="FALLIDO"
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Conectividad: $([ "$CONNECTIVITY_OK" = true ] && echo "✅ OK" || echo "❌ Error")"
echo "   • Inicialización: $([ "$INITIALIZATION_OK" = true ] && echo "✅ OK" || echo "❌ Error")"
echo "   • Flags disponibles: $FLAGS_COUNT"

echo ""
echo "🚀 Próximo test: Test #2 - Creación de flags"

# Salir con código apropiado
if [ "$FINAL_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$FINAL_RESULT" = "PARCIAL" ]; then
    exit 1
else
    exit 2
fi 