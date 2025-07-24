#!/bin/bash

echo "🧪 Test #5: Propagación del Cambio - LaunchDarkly"
echo "==============================================="

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Medir tiempo de propagación de cambios (Target: ≤60s)"
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
echo "📊 Test 1: Valor inicial del flag enable_payments"
echo "------------------------------------------------"

# Obtener valor inicial
INITIAL_RESPONSE=$(curl -s http://localhost:3001/health/flags)
INITIAL_VALUE=$(echo "$INITIAL_RESPONSE" | jq -r '.flags.enable_payments')
INITIAL_TIMESTAMP=$(echo "$INITIAL_RESPONSE" | jq -r '.timestamp')

echo "🎯 Valor inicial de enable_payments: $INITIAL_VALUE"
echo "⏰ Timestamp inicial: $INITIAL_TIMESTAMP"

# Determinar valor objetivo (opuesto al actual)
if [ "$INITIAL_VALUE" = "true" ]; then
    TARGET_VALUE="false"
    OPPOSITE_VALUE="true"
else
    TARGET_VALUE="true"
    OPPOSITE_VALUE="false"
fi

echo ""
echo -e "${YELLOW}📋 INSTRUCCIONES PARA EL TEST MANUAL:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 1. Abre el dashboard de LaunchDarkly en tu navegador:"
echo "   🔗 https://app.launchdarkly.com"
echo ""
echo "🎛️  2. Navega a tu proyecto y encuentra el flag 'enable_payments'"
echo ""
echo "🔧 3. Cambia el valor del flag a: ${TARGET_VALUE^^}"
echo "   📊 Valor actual: ${INITIAL_VALUE^^}"
echo "   🎯 Cambiar a: ${TARGET_VALUE^^}"
echo ""
echo "⏰ 4. Anota la hora exacta cuando haces el cambio"
echo ""
echo "🕐 5. El script monitoreará automáticamente el cambio"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo -e "${BLUE}⏳ Esperando que hagas el cambio en el dashboard...${NC}"
echo "   (Presiona Ctrl+C para cancelar si no vas a hacer el cambio)"

# Iniciar monitoreo
POLL_INTERVAL=2  # Verificar cada 2 segundos
MAX_WAIT_TIME=120  # Máximo 2 minutos
ELAPSED_TIME=0
CHANGE_DETECTED=false
CHANGE_TIMESTAMP=""

echo ""
echo "🔄 Iniciando monitoreo automático cada ${POLL_INTERVAL}s..."
echo "┌─────────────┬─────────────┬─────────────┬──────────────────────────────────┐"
echo "│   Tiempo    │   Valor     │  Cambio     │            Timestamp             │"
echo "├─────────────┼─────────────┼─────────────┼──────────────────────────────────┤"

while [ $ELAPSED_TIME -le $MAX_WAIT_TIME ] && [ "$CHANGE_DETECTED" = false ]; do
    # Verificar valor actual
    CURRENT_RESPONSE=$(curl -s http://localhost:3001/health/flags 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        CURRENT_VALUE=$(echo "$CURRENT_RESPONSE" | jq -r '.flags.enable_payments // "null"')
        CURRENT_TIMESTAMP=$(echo "$CURRENT_RESPONSE" | jq -r '.timestamp // "null"')
        
        # Formatear tiempo transcurrido
        TIME_DISPLAY=$(printf "%3ds" $ELAPSED_TIME)
        
        # Verificar si hay cambio
        if [ "$CURRENT_VALUE" != "$INITIAL_VALUE" ]; then
            CHANGE_DETECTED=true
            CHANGE_TIMESTAMP=$CURRENT_TIMESTAMP
            echo -e "│ ${TIME_DISPLAY}       │ ${GREEN}${CURRENT_VALUE}${NC}       │ ${GREEN}✅ DETECTADO${NC} │ ${CURRENT_TIMESTAMP} │"
        else
            echo -e "│ ${TIME_DISPLAY}       │ ${CURRENT_VALUE}        │ ⏳ Esperando  │ ${CURRENT_TIMESTAMP} │"
        fi
    else
        echo -e "│ ${TIME_DISPLAY}       │ ${RED}ERROR${NC}       │ ${RED}❌ Sin resp.${NC}  │ N/A                              │"
    fi
    
    if [ "$CHANGE_DETECTED" = false ]; then
        sleep $POLL_INTERVAL
        ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
    fi
done

echo "└─────────────┴─────────────┴─────────────┴──────────────────────────────────┘"

echo ""
echo "📊 Test 2: Análisis de Resultados"
echo "--------------------------------"

if [ "$CHANGE_DETECTED" = true ]; then
    echo -e "${GREEN}✅ Cambio detectado exitosamente${NC}"
    echo ""
    echo "📈 Métricas de Propagación:"
    echo "   • Valor inicial: $INITIAL_VALUE"
    echo "   • Valor final: $CURRENT_VALUE"
    echo "   • Tiempo de detección: ${ELAPSED_TIME}s"
    echo "   • Objetivo: ≤60s"
    echo "   • Intervalo de polling: ${POLL_INTERVAL}s"
    
    # Evaluar resultado
    if [ $ELAPSED_TIME -le 60 ]; then
        echo -e "   • Estado: ${GREEN}✅ PASADO${NC} (${ELAPSED_TIME}s ≤ 60s)"
        TEST_RESULT="PASADO"
    else
        echo -e "   • Estado: ${RED}❌ FALLIDO${NC} (${ELAPSED_TIME}s > 60s)"
        TEST_RESULT="FALLIDO"
    fi
    
    echo ""
    echo "🔍 Análisis de LaunchDarkly Streaming:"
    
    if [ $ELAPSED_TIME -le 10 ]; then
        echo -e "   ${GREEN}🚀 EXCELENTE: Propagación en tiempo real (≤10s)${NC}"
        PERFORMANCE_RATING="EXCELENTE"
    elif [ $ELAPSED_TIME -le 30 ]; then
        echo -e "   ${BLUE}👍 BUENO: Propagación rápida (≤30s)${NC}"
        PERFORMANCE_RATING="BUENO"
    elif [ $ELAPSED_TIME -le 60 ]; then
        echo -e "   ${YELLOW}⚠️  ACEPTABLE: Dentro del SLA (≤60s)${NC}"
        PERFORMANCE_RATING="ACEPTABLE"
    else
        echo -e "   ${RED}❌ PROBLEMÁTICO: Fuera del SLA (>60s)${NC}"
        PERFORMANCE_RATING="PROBLEMÁTICO"
    fi
    
else
    echo -e "${RED}❌ No se detectó cambio en ${MAX_WAIT_TIME}s${NC}"
    echo ""
    echo "🔍 Posibles causas:"
    echo "   • No se realizó el cambio en el dashboard"
    echo "   • Problema de conectividad con LaunchDarkly"
    echo "   • Flag incorrecto o entorno incorrecto"
    echo "   • Streaming connection interrumpida"
    
    TEST_RESULT="NO_COMPLETADO"
    PERFORMANCE_RATING="N/A"
    ELAPSED_TIME="N/A"
fi

echo ""
echo "📊 Test 3: Verificación de Streaming Connection"
echo "----------------------------------------------"

# Verificar logs del backend para streaming
echo "🔍 Verificando estado de la conexión streaming..."

PROVIDER_INFO=$(curl -s http://localhost:3001/health/provider)
PROVIDER_NAME=$(echo "$PROVIDER_INFO" | jq -r '.provider.name // "unknown"')
PROVIDER_CONNECTED=$(echo "$PROVIDER_INFO" | jq -r '.provider.connected // false')

echo "📋 Estado del proveedor:"
echo "   • Proveedor: $PROVIDER_NAME"
echo "   • Conectado: $PROVIDER_CONNECTED"

if [ "$PROVIDER_NAME" = "launchdarkly" ] && [ "$PROVIDER_CONNECTED" = "true" ]; then
    echo -e "   • Streaming: ${GREEN}✅ Activo${NC}"
else
    echo -e "   • Streaming: ${RED}❌ Inactivo${NC}"
fi

echo ""
echo "🎯 Resumen del Test #5:"
echo "======================"

if [ "$TEST_RESULT" = "PASADO" ]; then
    echo -e "${GREEN}✅ Test #5 PASADO: Propagación de cambios en tiempo esperado${NC}"
elif [ "$TEST_RESULT" = "FALLIDO" ]; then
    echo -e "${RED}❌ Test #5 FALLIDO: Propagación fuera del SLA${NC}"
else
    echo -e "${YELLOW}⚠️  Test #5 NO COMPLETADO: No se detectó cambio${NC}"
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Tiempo de propagación: ${ELAPSED_TIME}s"
echo "   • Target: ≤60s"
echo "   • Performance: $PERFORMANCE_RATING"
echo "   • Proveedor: LaunchDarkly (Streaming)"

echo ""
echo "🔄 Comparación con ConfigCat:"
echo "   • LaunchDarkly (Streaming): ~${ELAPSED_TIME}s"
echo "   • ConfigCat (Polling 30s): ~30-60s típico"

if [ "$TEST_RESULT" = "PASADO" ] && [ $ELAPSED_TIME -le 30 ]; then
    echo -e "   • ${GREEN}🏆 Ventaja LaunchDarkly: Updates más rápidos${NC}"
fi

echo ""
echo -e "${YELLOW}💡 Para repetir este test:${NC}"
echo "   1. Cambia el flag de vuelta al valor original ($INITIAL_VALUE)"
echo "   2. Ejecuta nuevamente este script"
echo "   3. Compara tiempos de propagación"

echo ""
echo -e "${YELLOW}🚀 Próximo test: Test #6 - Kill-switch${NC}"

# Salir con código apropiado
if [ "$TEST_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$TEST_RESULT" = "FALLIDO" ]; then
    exit 1
else
    exit 2
fi 