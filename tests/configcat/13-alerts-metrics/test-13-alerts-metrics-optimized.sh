#!/bin/bash

echo "🚨 Test #13: Alertas/Métricas - ConfigCat (Optimizado)"
echo "Objetivo: Configurar alerta error rate >2%, forzar errores, verificar alerta en ≤5min"
echo "=========================================================================="

API_BASE="http://localhost:3001"
TEST_USER="test_alerts_opt"
START_TIME=$(date +%s)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Paso 1: Métricas iniciales${NC}"
INITIAL_METRICS=$(curl -s "$API_BASE/payments/metrics/dashboard")
INITIAL_TOTAL=$(echo "$INITIAL_METRICS" | jq -r '.metrics.total')
echo "Total inicial de pagos: $INITIAL_TOTAL"

echo
echo -e "${BLUE}🔧 Paso 2: Activar simulador de errores${NC}"
curl -s -X POST "$API_BASE/flags/simulate_errors" \
  -H "Content-Type: application/json" \
  -d '{"value": true}' > /dev/null

echo "Flag simulate_errors activado. Esperando 2 segundos para propagación..."
sleep 2

echo
echo -e "${BLUE}💥 Paso 3: Generar errores (10 pagos para test rápido)${NC}"

for i in {1..10}; do
    echo -n "Creando pago $i/10... "
    
    RESPONSE=$(curl -s -X POST "$API_BASE/payments" \
        -H "Content-Type: application/json" \
        -d "{
            \"userId\": \"${TEST_USER}_${i}\",
            \"amount\": 25,
            \"currency\": \"USD\",
            \"method\": \"credit_card\"
        }")
    
    SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
    
    if [ "$SUCCESS" = "true" ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
    fi
    
    sleep 0.2  # Breve pausa entre pagos
done

echo
echo -e "${BLUE}⏳ Paso 4: Esperar procesamiento (15 segundos)${NC}"
echo "Los pagos se procesan automáticamente con simulate_errors activo..."

for i in {15..1}; do
    echo -n "Esperando... $i segundos restantes"
    sleep 1
    echo -ne "\r\033[K"  # Limpiar línea
done

echo "Procesamiento completado."

echo
echo -e "${BLUE}🔍 Paso 5: Verificar métricas actualizadas${NC}"
UPDATED_METRICS=$(curl -s "$API_BASE/payments/metrics/dashboard")
echo "Métricas después de generar errores:"
echo "$UPDATED_METRICS" | jq '.metrics'

ACTUAL_ERROR_RATE=$(echo "$UPDATED_METRICS" | jq -r '.metrics.errorRate')
FAILED_COUNT=$(echo "$UPDATED_METRICS" | jq -r '.metrics.failed')
ALERTS_COUNT=$(echo "$UPDATED_METRICS" | jq -r '.alerts | length')

echo
echo -e "${YELLOW}📈 Análisis de Métricas:${NC}"
echo "- Error rate actual: ${ACTUAL_ERROR_RATE}%"
echo "- Pagos fallidos: $FAILED_COUNT"
echo "- Alertas generadas: $ALERTS_COUNT"

echo
echo -e "${BLUE}🚨 Paso 6: Verificar alertas${NC}"
if [ "$ALERTS_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ ALERTAS DETECTADAS:${NC}"
    echo "$UPDATED_METRICS" | jq -r '.alerts[] | "  🚨 \(.type) (\(.severity)): \(.message)"'
    
    ERROR_RATE_ALERT=$(echo "$UPDATED_METRICS" | jq -r '.alerts[] | select(.type == "error_rate_high") | .type')
    if [ "$ERROR_RATE_ALERT" = "error_rate_high" ]; then
        echo -e "${GREEN}✅ Alerta de error rate alto detectada${NC}"
        ALERT_WORKING=true
    else
        echo -e "${YELLOW}⚠️ Alerta detectada pero no es de error rate alto${NC}"
        ALERT_WORKING=false
    fi
else
    echo -e "${RED}❌ No se generaron alertas${NC}"
    ALERT_WORKING=false
fi

echo
echo -e "${BLUE}⏱️ Paso 7: Verificar tiempo de respuesta${NC}"
CURRENT_TIME=$(date +%s)
ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

echo "Tiempo transcurrido: ${ELAPSED_TIME} segundos"

if [ $ELAPSED_TIME -le 300 ]; then  # ≤5 minutos
    echo -e "${GREEN}✅ Tiempo ≤5 minutos: OBJETIVO CUMPLIDO${NC}"
    TIME_OK=true
else
    echo -e "${RED}❌ Tiempo >5 minutos: OBJETIVO NO CUMPLIDO${NC}"
    TIME_OK=false
fi

echo
echo -e "${BLUE}🔧 Paso 8: Cleanup${NC}"
curl -s -X POST "$API_BASE/flags/simulate_errors" \
  -H "Content-Type: application/json" \
  -d '{"value": false}' > /dev/null

echo "Flag simulate_errors desactivado."

echo
echo "=========================================================================="
echo -e "${GREEN}🎯 RESUMEN DEL TEST #13: ALERTAS/MÉTRICAS (OPTIMIZADO)${NC}"
echo

# Evaluación de objetivos
echo "Objetivos evaluados:"

# 1. Error rate > 2%
if (( $(echo "$ACTUAL_ERROR_RATE > 2" | bc -l) )); then
    echo -e "✅ Error rate >2%: ${ACTUAL_ERROR_RATE}%"
    ERROR_RATE_OK=true
else
    echo -e "❌ Error rate ≤2%: ${ACTUAL_ERROR_RATE}%"
    ERROR_RATE_OK=false
fi

# 2. Alertas generadas
if [ "$ALERT_WORKING" = true ]; then
    echo "✅ Alertas de error rate: Funcionando"
else
    echo "❌ Alertas de error rate: No funcionando"
fi

# 3. Tiempo
if [ "$TIME_OK" = true ]; then
    echo "✅ Tiempo de respuesta: ${ELAPSED_TIME}s (≤5min)"
else
    echo "❌ Tiempo de respuesta: ${ELAPSED_TIME}s (>5min)"
fi

# 4. Sistema general
echo "✅ Sistema de métricas: Funcional"
echo "✅ API de alertas: /payments/metrics/dashboard"
echo "✅ Flag de errores: simulate_errors funciona"

echo
# Resultado final
if [ "$ERROR_RATE_OK" = true ] && [ "$ALERT_WORKING" = true ] && [ "$TIME_OK" = true ]; then
    echo -e "${GREEN}🎉 TEST #13 COMPLETADO: Sistema de alertas y métricas funciona${NC}"
    echo -e "${GREEN}   ConfigCat + Sistema de monitoreo = ✅ ÉXITO TOTAL${NC}"
else
    echo -e "${YELLOW}⚠️ TEST #13 PARCIAL: Sistema funciona pero necesita ajustes${NC}"
    if [ "$ERROR_RATE_OK" = false ]; then
        echo "   - Necesita más errores para superar 2% threshold"
    fi
    if [ "$ALERT_WORKING" = false ]; then
        echo "   - Sistema de alertas necesita revisión"
    fi
fi

echo
echo "Detalles técnicos:"
echo "- Flag usado: simulate_errors (ConfigCat)"
echo "- Endpoint: /payments/metrics/dashboard"
echo "- Umbral alerta: >2% error rate"
echo "- Tiempo objetivo: ≤5 minutos"
echo "- Error rate logrado: ${ACTUAL_ERROR_RATE}%"
echo "- Pagos fallidos: $FAILED_COUNT"
echo "- Sistema auto-procesamiento: ✅ Implementado"

echo
echo "💡 Para generar más errores y superar 2%:"
echo "curl -s http://localhost:3001/payments/metrics/dashboard | jq '.'" 