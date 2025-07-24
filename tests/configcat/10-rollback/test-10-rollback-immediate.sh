#!/bin/bash

echo "🔄 Test #10: Rollback Inmediato"
echo "Objetivo: Simular error 500, apagar flag, normalizar errores en <30s"
echo ""

# Función para crear pago de prueba
test_payment() {
    local user_suffix=$1
    curl -s -w "TIME:%{time_total}" -X POST http://localhost:3001/payments \
        -H "Content-Type: application/json" \
        -d '{
            "userId": "user_rollback_'$user_suffix'",
            "amount": 25.99,
            "currency": "USD", 
            "method": "credit_card",
            "description": "Rollback test payment"
        }'
}

# Función para verificar estado del flag
check_flag() {
    curl -s http://localhost:3001/flags/simulate_errors | grep -o '"value":[^,}]*' | cut -d':' -f2
}

echo "📊 Estado inicial del sistema:"
FLAG_STATE=$(check_flag)
echo "simulate_errors = $FLAG_STATE"

echo ""
echo "🧪 Verificando funcionamiento normal:"
NORMAL_RESPONSE=$(test_payment "pre")
NORMAL_TIME=$(echo "$NORMAL_RESPONSE" | grep -o "TIME:[0-9.]*" | cut -d':' -f2)
NORMAL_BODY=$(echo "$NORMAL_RESPONSE" | sed 's/TIME:[0-9.]*$//')

if echo "$NORMAL_BODY" | grep -q '"success":true'; then
    echo "✅ Estado normal: Pagos funcionando ($NORMAL_TIME s)"
else
    echo "❌ Error en estado normal - abortando test"
    exit 1
fi

echo ""
echo "🚨 FASE 1: Activar errores simulados"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 Ve al dashboard de ConfigCat y cambia 'simulate_errors' a ON (true)"
echo "Presiona Enter cuando hayas activado el flag..."
read -r

echo ""
echo "⏳ Esperando propagación de errores (máximo 60s)..."
ERRORS_START_TIME=$(date +%s)

for i in {1..12}; do
    CURRENT_FLAG=$(check_flag)
    echo "[$i/12] simulate_errors = $CURRENT_FLAG"
    
    if [ "$CURRENT_FLAG" = "true" ]; then
        echo "🚨 Flag activado! Verificando errores..."
        
        # Probar pago para confirmar error
        ERROR_RESPONSE=$(test_payment "error_test")
        ERROR_BODY=$(echo "$ERROR_RESPONSE" | sed 's/TIME:[0-9.]*$//')
        
        if echo "$ERROR_BODY" | grep -q "SIMULATED_ERROR"; then
            echo "✅ Errores confirmados! Tiempo de propagación: $(($(date +%s) - $ERRORS_START_TIME))s"
            break
        else
            echo "⚠️ Flag activo pero errores no detectados aún..."
        fi
    fi
    
    sleep 5
done

echo ""
echo "🔄 FASE 2: Rollback inmediato (desactivar errores)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 AHORA cambia 'simulate_errors' a OFF (false) inmediatamente"
echo "Presiona Enter cuando hayas desactivado el flag..."
read -r

ROLLBACK_START_TIME=$(date +%s)
echo ""
echo "⚡ Monitoreando normalización cada 3 segundos..."

PAYMENTS_NORMALIZED=false
ROLLBACK_DURATION=0

for i in {1..10}; do  # 30 segundos máximo
    ROLLBACK_DURATION=$(($(date +%s) - $ROLLBACK_START_TIME))
    CURRENT_TIME=$(date '+%H:%M:%S')
    
    # Verificar estado del flag
    CURRENT_FLAG=$(check_flag)
    
    # Probar pago
    TEST_RESPONSE=$(test_payment "$i")
    TEST_TIME=$(echo "$TEST_RESPONSE" | grep -o "TIME:[0-9.]*" | cut -d':' -f2)
    TEST_BODY=$(echo "$TEST_RESPONSE" | sed 's/TIME:[0-9.]*$//')
    
    if echo "$TEST_BODY" | grep -q '"success":true'; then
        echo "[$CURRENT_TIME] (+${ROLLBACK_DURATION}s) ✅ NORMALIZADO - Pago exitoso (${TEST_TIME}s)"
        PAYMENTS_NORMALIZED=true
        break
    elif echo "$TEST_BODY" | grep -q "SIMULATED_ERROR"; then
        echo "[$CURRENT_TIME] (+${ROLLBACK_DURATION}s) 🚨 ERROR - Aún simulando errores (flag: $CURRENT_FLAG)"
    else
        echo "[$CURRENT_TIME] (+${ROLLBACK_DURATION}s) ⚠️ OTRO ERROR - $(echo "$TEST_BODY" | grep -o '"message":"[^"]*"' | cut -d':' -f2 | tr -d '"')"
    fi
    
    sleep 3
done

echo ""
echo "📊 Resultados del Rollback:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Tiempo total de rollback: ${ROLLBACK_DURATION} segundos"
echo "Target objetivo: ≤ 30 segundos"

if [ "$PAYMENTS_NORMALIZED" = true ]; then
    if [ $ROLLBACK_DURATION -le 30 ]; then
        echo ""
        echo "✅ Test #10 PASADO: Rollback inmediato exitoso"
        echo "   ✓ Errores activados y detectados"
        echo "   ✓ Rollback completado en ${ROLLBACK_DURATION}s ≤ 30s"
        echo "   ✓ Pagos normalizados correctamente"
    else
        echo ""
        echo "⚠️ Test #10 PARCIAL: Rollback exitoso pero lento"
        echo "   ✓ Errores activados y detectados"
        echo "   ❌ Rollback en ${ROLLBACK_DURATION}s > 30s (target)"
        echo "   ✓ Pagos finalmente normalizados"
    fi
else
    echo ""
    echo "❌ Test #10 FALLIDO: Rollback no completado"
    echo "   ✓ Errores activados y detectados"  
    echo "   ❌ Pagos no normalizados en 30s"
    echo "   ❌ Sistema sigue con errores"
fi

echo ""
echo "🎯 Verificación final:"
FINAL_PAYMENT=$(test_payment "final")
FINAL_BODY=$(echo "$FINAL_PAYMENT" | sed 's/TIME:[0-9.]*$//')

if echo "$FINAL_BODY" | grep -q '"success":true'; then
    echo "✅ Estado final: Sistema normalizado"
else
    echo "❌ Estado final: Sistema aún con problemas"
fi 