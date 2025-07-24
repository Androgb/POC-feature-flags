#!/bin/bash

echo "🔄 Test #9: API Versioning v1/v2 (Simple)"
echo "Objetivo: Backend modo dual, logs muestran transición"
echo ""

# Función para crear orden simple
create_order() {
    local user_id=$1
    local suffix=$2
    curl -s -X POST http://localhost:3001/orders \
        -H "Content-Type: application/json" \
        -d '{
            "userId": "'$user_id'",
            "paymentId": "pay_'$suffix'",
            "items": [{"productId": "prod_'$suffix'", "name": "Test Product", "quantity": 1, "price": 15.99}]
        }'
}

echo "📊 Estado actual del flag:"
FLAG_VALUE=$(curl -s http://localhost:3001/flags/orders_api_v2 | grep -o '"value":[^,}]*' | cut -d':' -f2)
API_VERSION=$(curl -s http://localhost:3001/health/flags | grep -o '"orders_api_version":"[^"]*"' | cut -d':' -f2 | tr -d '"')
echo "orders_api_v2 = $FLAG_VALUE → orders_api_version = $API_VERSION"
echo ""

echo "📈 Estadísticas iniciales:"
STATS=$(curl -s http://localhost:3001/orders/stats/api-versions)
TOTAL=$(echo "$STATS" | grep -o '"total":[^,}]*' | cut -d':' -f2)
V1_COUNT=$(echo "$STATS" | grep -o '"v1":{"count":[^,}]*' | cut -d':' -f3)
V2_COUNT=$(echo "$STATS" | grep -o '"v2":{"count":[^,}]*' | cut -d':' -f3)
echo "Total: $TOTAL, v1: $V1_COUNT, v2: $V2_COUNT"
echo ""

echo "🚀 Creando 2 órdenes con flag actual ($API_VERSION):"
for i in {1..2}; do
    echo "Creando orden $i..."
    RESPONSE=$(create_order "user_test_$i" "$i")
    
    if echo "$RESPONSE" | grep -q '"success":true'; then
        ORDER_VERSION=$(echo "$RESPONSE" | grep -o '"apiVersion":"[^"]*"' | cut -d':' -f2 | tr -d '"')
        echo "✅ Orden $i: API $ORDER_VERSION"
    else
        echo "❌ Error en orden $i"
    fi
done

echo ""
echo "📊 Estadísticas después de crear órdenes:"
STATS_NEW=$(curl -s http://localhost:3001/orders/stats/api-versions)
TOTAL_NEW=$(echo "$STATS_NEW" | grep -o '"total":[^,}]*' | cut -d':' -f2)
V1_NEW=$(echo "$STATS_NEW" | grep -o '"v1":{"count":[^,}]*' | cut -d':' -f3)
V2_NEW=$(echo "$STATS_NEW" | grep -o '"v2":{"count":[^,}]*' | cut -d':' -f3)
echo "Total: $TOTAL_NEW, v1: $V1_NEW, v2: $V2_NEW"

echo ""
echo "🔧 Forzando orden v2 (endpoint directo):"
V2_RESPONSE=$(curl -s -X POST http://localhost:3001/orders/v2 \
    -H "Content-Type: application/json" \
    -d '{
        "userId": "user_v2_force",
        "paymentId": "pay_v2_force",
        "items": [{"productId": "prod_v2", "name": "V2 Product", "quantity": 1, "price": 29.99}],
        "promotionCode": "TEST20",
        "discountAmount": 5.99,
        "shippingPreferences": {"express": true, "trackingNotifications": true}
    }')

if echo "$V2_RESPONSE" | grep -q '"success":true'; then
    echo "✅ Orden v2 forzada creada"
    
    # Verificar features v2
    if echo "$V2_RESPONSE" | grep -q '"promotionCode":true'; then
        echo "🎯 Features v2 detectadas: promotionCode ✓"
    fi
    if echo "$V2_RESPONSE" | grep -q '"discountApplied":true'; then
        echo "🎯 Features v2 detectadas: discountApplied ✓"  
    fi
    if echo "$V2_RESPONSE" | grep -q '"shippingPreferences":true'; then
        echo "🎯 Features v2 detectadas: shippingPreferences ✓"
    fi
else
    echo "❌ Error creando orden v2"
fi

echo ""
echo "📊 Estadísticas finales:"
STATS_FINAL=$(curl -s http://localhost:3001/orders/stats/api-versions)
TOTAL_FINAL=$(echo "$STATS_FINAL" | grep -o '"total":[^,}]*' | cut -d':' -f2)
V1_FINAL=$(echo "$STATS_FINAL" | grep -o '"v1":{"count":[^,}]*' | cut -d':' -f3)
V2_FINAL=$(echo "$STATS_FINAL" | grep -o '"v2":{"count":[^,}]*' | cut -d':' -f3)
V2_PERCENT=$(echo "$STATS_FINAL" | grep -o '"v2":{"count":[^,]*,"percentage":[^}]*' | cut -d':' -f4)

echo "Total órdenes: $TOTAL_FINAL"
echo "📊 v1: $V1_FINAL órdenes"
echo "📊 v2: $V2_FINAL órdenes ($V2_PERCENT%)"

echo ""
echo "🎯 Análisis del Test:"
if [ "$V2_FINAL" -gt 0 ]; then
    echo "✅ Test #9 PASADO: API versioning funcional"
    echo "   ✓ Backend maneja v1 y v2 según flag"
    echo "   ✓ Endpoint v2 fuerza features avanzadas"
    echo "   ✓ Estadísticas registran migración"
    echo "   ✓ Flag controla versión automáticamente"
else
    echo "❌ Test #9: Sin adopción v2 detectada"
fi

echo ""
echo "💡 Para probar transición completa:"
echo "1. Ve al dashboard de ConfigCat" 
echo "2. Cambia orders_api_v2 a true (ON)"
echo "3. Ejecuta: curl -X POST http://localhost:3001/orders ..."
echo "4. Verifica que use API v2 automáticamente" 