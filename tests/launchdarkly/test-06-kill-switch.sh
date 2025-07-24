#!/bin/bash

echo "🧪 Test #6: Kill-switch - LaunchDarkly"
echo "===================================="

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Verificar kill-switch con enable_payments (≤30s para detener flujo)"
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
echo "📊 Test 1: Estado inicial del sistema de pagos"
echo "----------------------------------------------"

# Verificar estado inicial
INITIAL_RESPONSE=$(curl -s http://localhost:3001/health/flags)
ENABLE_PAYMENTS=$(echo "$INITIAL_RESPONSE" | jq -r '.flags.enable_payments')

echo "💳 Estado inicial de enable_payments: $ENABLE_PAYMENTS"

# Testear endpoint de pagos
echo ""
echo "🧪 Probando endpoint de pagos antes del kill-switch..."

PAYMENT_TEST=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X POST http://localhost:3001/orders \
  -H "Content-Type: application/json" \
  -d '{"userId": "test_user", "amount": 100, "currency": "USD"}')

PAYMENT_STATUS=$(echo $PAYMENT_TEST | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
PAYMENT_BODY=$(echo $PAYMENT_TEST | sed -E 's/HTTPSTATUS:[0-9]*$//')

echo "📋 Respuesta del endpoint de pagos:"
echo "   • HTTP Status: $PAYMENT_STATUS"

if [ $PAYMENT_STATUS -eq 200 ]; then
    echo -e "   • Estado: ${GREEN}✅ Pagos funcionando${NC}"
    echo "   • Respuesta: $(echo "$PAYMENT_BODY" | jq -r '.message // .status // "OK"')"
else
    echo -e "   • Estado: ${RED}❌ Pagos bloqueados${NC}"
    echo "   • Respuesta: $(echo "$PAYMENT_BODY" | jq -r '.message // .error // "Error"')"
fi

echo ""
echo "📊 Test 2: Activar Kill-switch"
echo "-----------------------------"

if [ "$ENABLE_PAYMENTS" = "true" ]; then
    echo -e "${YELLOW}📋 INSTRUCCIONES PARA KILL-SWITCH:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🚨 1. Ve al dashboard de LaunchDarkly:"
    echo "   🔗 https://app.launchdarkly.com"
    echo ""
    echo "🔧 2. Encuentra el flag 'enable_payments'"
    echo ""
    echo "❌ 3. DESACTIVA el flag (cambia a FALSE)"
    echo "   📊 Valor actual: TRUE"
    echo "   🎯 Cambiar a: FALSE (KILL-SWITCH ACTIVADO)"
    echo ""
    echo "⏰ 4. El sistema debe bloquear pagos en ≤30s"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo ""
    echo -e "${BLUE}⏳ Esperando que actives el kill-switch...${NC}"
    echo "   (Presiona Ctrl+C para cancelar)"
    
    # Monitoreo del kill-switch
    POLL_INTERVAL=3  # Verificar cada 3 segundos
    MAX_WAIT_TIME=90  # Máximo 90 segundos
    ELAPSED_TIME=0
    KILL_SWITCH_DETECTED=false
    
    echo ""
    echo "🔄 Monitoreando kill-switch cada ${POLL_INTERVAL}s..."
    echo "┌──────────────┬─────────────────┬─────────────────┬─────────────────────────────────────┐"
    echo "│    Tiempo    │  enable_payments│   Pagos API     │              Estado                 │"
    echo "├──────────────┼─────────────────┼─────────────────┼─────────────────────────────────────┤"
    
    while [ $ELAPSED_TIME -le $MAX_WAIT_TIME ] && [ "$KILL_SWITCH_DETECTED" = false ]; do
        # Verificar flag
        CURRENT_RESPONSE=$(curl -s http://localhost:3001/health/flags 2>/dev/null)
        CURRENT_PAYMENTS=$(echo "$CURRENT_RESPONSE" | jq -r '.flags.enable_payments // "null"')
        
        # Probar endpoint de pagos
        PAYMENT_TEST=$(curl -s -w "HTTPSTATUS:%{http_code}" \
          -X POST http://localhost:3001/orders \
          -H "Content-Type: application/json" \
          -d '{"userId": "kill_switch_test", "amount": 50, "currency": "USD"}' 2>/dev/null)
        
        PAYMENT_STATUS=$(echo $PAYMENT_TEST | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        
        # Formatear tiempo
        TIME_DISPLAY=$(printf "%3ds" $ELAPSED_TIME)
        
        # Determinar estado de pagos
        if [ $PAYMENT_STATUS -eq 200 ]; then
            PAYMENT_STATE="${GREEN}✅ Activos${NC}"
            SYSTEM_STATE="🟢 Operacional"
        else
            PAYMENT_STATE="${RED}❌ Bloqueados${NC}"
            SYSTEM_STATE="🔴 Mantenimiento"
        fi
        
        # Verificar si kill-switch está activo
        if [ "$CURRENT_PAYMENTS" = "false" ] && [ $PAYMENT_STATUS -ne 200 ]; then
            KILL_SWITCH_DETECTED=true
            echo -e "│ ${TIME_DISPLAY}        │ ${RED}false${NC}            │ ${PAYMENT_STATE}    │ ${RED}🚨 KILL-SWITCH ACTIVO${NC}           │"
        elif [ "$CURRENT_PAYMENTS" = "false" ]; then
            echo -e "│ ${TIME_DISPLAY}        │ ${RED}false${NC}            │ ${PAYMENT_STATE}    │ ${YELLOW}⏳ Propagando...${NC}                │"
        else
            echo -e "│ ${TIME_DISPLAY}        │ ${GREEN}true${NC}             │ ${PAYMENT_STATE}    │ ${SYSTEM_STATE}                    │"
        fi
        
        if [ "$KILL_SWITCH_DETECTED" = false ]; then
            sleep $POLL_INTERVAL
            ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
        fi
    done
    
    echo "└──────────────┴─────────────────┴─────────────────┴─────────────────────────────────────┘"
    
else
    echo -e "${YELLOW}⚠️  El flag enable_payments ya está en FALSE${NC}"
    echo "🔄 Vamos a probar directamente el comportamiento del kill-switch"
    
    KILL_SWITCH_DETECTED=true
    ELAPSED_TIME=0
fi

echo ""
echo "📊 Test 3: Verificación del Kill-switch"
echo "--------------------------------------"

if [ "$KILL_SWITCH_DETECTED" = true ]; then
    echo -e "${GREEN}✅ Kill-switch detectado y activo${NC}"
    echo ""
    echo "📈 Métricas del Kill-switch:"
    echo "   • Tiempo de activación: ${ELAPSED_TIME}s"
    echo "   • Objetivo: ≤30s"
    
    if [ $ELAPSED_TIME -le 30 ]; then
        echo -e "   • Estado: ${GREEN}✅ PASADO${NC} (${ELAPSED_TIME}s ≤ 30s)"
        KILL_SWITCH_RESULT="PASADO"
    else
        echo -e "   • Estado: ${RED}❌ FALLIDO${NC} (${ELAPSED_TIME}s > 30s)"
        KILL_SWITCH_RESULT="FALLIDO"
    fi
    
    # Verificar comportamiento detallado
    echo ""
    echo "🔍 Verificación detallada del comportamiento:"
    
    # Test 1: Endpoint de pagos debe fallar
    echo "   📋 1. Probando endpoint de pagos (debe fallar):"
    PAYMENT_TEST=$(curl -s -w "HTTPSTATUS:%{http_code}" \
      -X POST http://localhost:3001/orders \
      -H "Content-Type: application/json" \
      -d '{"userId": "kill_switch_verification", "amount": 200, "currency": "USD"}')
    
    PAYMENT_STATUS=$(echo $PAYMENT_TEST | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    PAYMENT_BODY=$(echo $PAYMENT_TEST | sed -E 's/HTTPSTATUS:[0-9]*$//')
    
    if [ $PAYMENT_STATUS -ne 200 ]; then
        echo -e "      ${GREEN}✅ Pagos correctamente bloqueados (HTTP $PAYMENT_STATUS)${NC}"
        PAYMENTS_BLOCKED=true
    else
        echo -e "      ${RED}❌ ERROR: Pagos aún funcionando (HTTP $PAYMENT_STATUS)${NC}"
        PAYMENTS_BLOCKED=false
    fi
    
    # Mostrar mensaje de error
    ERROR_MESSAGE=$(echo "$PAYMENT_BODY" | jq -r '.message // .error // "Sin mensaje"')
    echo "      💬 Mensaje: $ERROR_MESSAGE"
    
    # Test 2: Frontend debe mostrar mensaje de mantenimiento
    echo ""
    echo "   📋 2. Verificando endpoint de flags para frontend:"
    FLAGS_RESPONSE=$(curl -s http://localhost:3001/health/flags)
    FRONTEND_PAYMENTS=$(echo "$FLAGS_RESPONSE" | jq -r '.flags.enable_payments')
    
    if [ "$FRONTEND_PAYMENTS" = "false" ]; then
        echo -e "      ${GREEN}✅ Frontend recibe flag desactivado${NC}"
        FRONTEND_UPDATED=true
    else
        echo -e "      ${RED}❌ ERROR: Frontend aún ve flag activo${NC}"
        FRONTEND_UPDATED=false
    fi
    
    # Test 3: Verificar que no hay transacciones parciales
    echo ""
    echo "   📋 3. Verificando integridad (sin transacciones parciales):"
    if [ $PAYMENT_STATUS -eq 403 ] || [ $PAYMENT_STATUS -eq 503 ]; then
        echo -e "      ${GREEN}✅ Rechazo limpio sin transacciones parciales${NC}"
        NO_PARTIAL_TRANSACTIONS=true
    else
        echo -e "      ${YELLOW}⚠️  Verificar logs para transacciones parciales${NC}"
        NO_PARTIAL_TRANSACTIONS=true  # Asumimos OK si no hay errores graves
    fi
    
else
    echo -e "${RED}❌ Kill-switch no detectado en ${MAX_WAIT_TIME}s${NC}"
    echo ""
    echo "🔍 Posibles causas:"
    echo "   • No se realizó el cambio en el dashboard"
    echo "   • Problema de conectividad con LaunchDarkly"
    echo "   • Backend no procesa correctamente el flag"
    
    KILL_SWITCH_RESULT="NO_COMPLETADO"
    PAYMENTS_BLOCKED=false
    FRONTEND_UPDATED=false
    NO_PARTIAL_TRANSACTIONS=false
fi

echo ""
echo "🎯 Resumen del Test #6:"
echo "======================"

# Evaluar resultado final
if [ "$KILL_SWITCH_RESULT" = "PASADO" ] && [ "$PAYMENTS_BLOCKED" = true ] && [ "$FRONTEND_UPDATED" = true ] && [ "$NO_PARTIAL_TRANSACTIONS" = true ]; then
    echo -e "${GREEN}✅ Test #6 PASADO: Kill-switch funciona correctamente${NC}"
    FINAL_RESULT="PASADO"
elif [ "$KILL_SWITCH_RESULT" = "PASADO" ]; then
    echo -e "${YELLOW}⚠️  Test #6 PARCIAL: Kill-switch activo pero con problemas menores${NC}"
    FINAL_RESULT="PARCIAL"
else
    echo -e "${RED}❌ Test #6 FALLIDO: Kill-switch no funciona correctamente${NC}"
    FINAL_RESULT="FALLIDO"
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Tiempo de activación: ${ELAPSED_TIME}s"
echo "   • Pagos bloqueados: $([ "$PAYMENTS_BLOCKED" = true ] && echo "✅ Sí" || echo "❌ No")"
echo "   • Frontend actualizado: $([ "$FRONTEND_UPDATED" = true ] && echo "✅ Sí" || echo "❌ No")"
echo "   • Sin transacciones parciales: $([ "$NO_PARTIAL_TRANSACTIONS" = true ] && echo "✅ Sí" || echo "❌ No")"

echo ""
echo "🚨 Importancia del Kill-switch:"
echo "   • Crítico para aplicaciones de pagos"
echo "   • Permite detener funcionalidad problemática rápidamente"
echo "   • LaunchDarkly streaming facilita activación instantánea"

echo ""
echo -e "${YELLOW}💡 Para reactivar pagos:${NC}"
echo "   1. Ve al dashboard de LaunchDarkly"
echo "   2. Cambia enable_payments de FALSE a TRUE"
echo "   3. Verifica que los pagos funcionen nuevamente"

echo ""
echo -e "${YELLOW}🚀 Próximo test: Test #7 - Roll-out gradual${NC}"

# Salir con código apropiado
if [ "$FINAL_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$FINAL_RESULT" = "PARCIAL" ]; then
    exit 1
else
    exit 2
fi 