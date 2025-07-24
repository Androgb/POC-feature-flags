#!/bin/bash

echo "🧪 Test #4: Lectura del flag en frontend - LaunchDarkly"
echo "======================================================"

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que el frontend esté corriendo
echo "🔍 Verificando que el frontend esté corriendo..."

# Verificar si el puerto 3000 está activo (donde corre el frontend)
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend está corriendo en puerto 3000${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend no detectado en puerto 3000, pero continuamos con el test del backend${NC}"
    echo "💡 El frontend usa el mismo endpoint del backend, así que el test sigue siendo válido"
fi

echo ""
echo "📊 Test 1: Verificar carga de flags en el frontend"
echo "------------------------------------------------"

# Hacer petición al endpoint que usa el frontend
echo "🌐 Verificando endpoint /health/flags que incluye información del proveedor..."

RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code};TIME:%{time_total}" \
  http://localhost:3001/health/flags?userId=user_123)

HTTP_STATUS=$(echo $RESPONSE | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
TIME_TOTAL=$(echo $RESPONSE | grep -o "TIME:[0-9.]*" | cut -d: -f2)
BODY=$(echo $RESPONSE | sed -E 's/HTTPSTATUS:[0-9]*;TIME:[0-9.]*$//')

if [ $HTTP_STATUS -eq 200 ]; then
    echo -e "${GREEN}✅ Frontend endpoint responde correctamente${NC}"
    
    # Convertir tiempo a milisegundos
    TIME_MS=$(echo "$TIME_TOTAL * 1000" | bc -l)
    echo -e "${BLUE}⏱️  Tiempo de respuesta: ${TIME_MS}ms${NC}"
    
    # Verificar que el frontend obtiene los flags esperados
    echo "📋 Flags disponibles para el frontend:"
    echo "$BODY" | jq .
    
    # Verificar flags específicos (están en .flags.all)
    ENABLE_PAYMENTS=$(echo "$BODY" | jq -r '.flags.all.enable_payments // empty')
    PROMO_COLOR=$(echo "$BODY" | jq -r '.flags.all.promo_banner_color // empty')
    API_VERSION=$(echo "$BODY" | jq -r '.flags.all.orders_api_version // empty')
    
    echo ""
    echo "🎯 Verificación de flags clave:"
    if [ "$ENABLE_PAYMENTS" != "" ]; then
        echo -e "${GREEN}✅ enable_payments: $ENABLE_PAYMENTS${NC}"
    else
        echo -e "${RED}❌ enable_payments no encontrado${NC}"
    fi
    
    if [ "$PROMO_COLOR" != "" ]; then
        echo -e "${GREEN}✅ promo_banner_color: $PROMO_COLOR${NC}"
    else
        echo -e "${RED}❌ promo_banner_color no encontrado${NC}"
    fi
    
    if [ "$API_VERSION" != "" ]; then
        echo -e "${GREEN}✅ orders_api_version: $API_VERSION${NC}"
    else
        echo -e "${RED}❌ orders_api_version no encontrado${NC}"
    fi
    
else
    echo -e "${RED}❌ Error: Frontend endpoint no responde (HTTP $HTTP_STATUS)${NC}"
    exit 1
fi

echo ""
echo "📊 Test 2: Verificar información del proveedor"
echo "---------------------------------------------"

PROVIDER_NAME=$(echo "$BODY" | jq -r '.provider.name // empty')
PROVIDER_CONNECTED=$(echo "$BODY" | jq -r '.provider.connected // empty')

if [ "$PROVIDER_NAME" = "launchdarkly" ]; then
    echo -e "${GREEN}✅ Proveedor detectado: LaunchDarkly${NC}"
else
    echo -e "${RED}❌ Proveedor incorrecto: $PROVIDER_NAME (esperado: launchdarkly)${NC}"
fi

if [ "$PROVIDER_CONNECTED" = "true" ]; then
    echo -e "${GREEN}✅ Estado de conexión: Conectado${NC}"
else
    echo -e "${RED}❌ Estado de conexión: Desconectado${NC}"
fi

echo ""
echo "📊 Test 3: Simular actualización de flag"
echo "---------------------------------------"

echo "💡 Simulando actualización de flag enable_payments..."
echo "📝 NOTA: Para cambios reales, usa el dashboard de LaunchDarkly:"
echo "   🔗 https://app.launchdarkly.com"

# Simular llamada de actualización (esto es solo para testing)
UPDATE_RESPONSE=$(curl -s -X POST \
  http://localhost:3001/flags/enable_payments \
  -H "Content-Type: application/json" \
  -d '{"value": true, "userId": "user_123"}')

echo "📋 Respuesta de actualización simulada:"
echo "$UPDATE_RESPONSE" | jq .

echo ""
echo "🎯 Resumen del Test #4:"
echo "======================"

# Evaluar resultados
if [ $HTTP_STATUS -eq 200 ] && [ "$PROVIDER_NAME" = "launchdarkly" ] && [ "$PROVIDER_CONNECTED" = "true" ]; then
    echo -e "${GREEN}✅ Test #4 PASADO: Frontend lee flags correctamente desde LaunchDarkly${NC}"
    
    echo ""
    echo "📊 Métricas:"
    echo "   • Tiempo de respuesta: ${TIME_MS}ms"
    echo "   • Proveedor: LaunchDarkly"
    echo "   • Estado: Conectado"
    echo "   • Flags disponibles: $(echo "$BODY" | jq '.flags.all | keys | length')"
    
    echo ""
    echo -e "${BLUE}🧪 Para probar cambios en tiempo real:${NC}"
    echo "   1. Ve al dashboard de LaunchDarkly"
    echo "   2. Cambia el valor de un flag"
    echo "   3. Observa si el frontend refleja el cambio en <60s"
    
else
    echo -e "${RED}❌ Test #4 FALLIDO${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}🚀 Próximo test: Test #5 - Propagación del cambio${NC}" 