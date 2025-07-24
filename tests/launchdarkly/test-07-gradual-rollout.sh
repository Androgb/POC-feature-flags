#!/bin/bash

echo "🧪 Test #7: Roll-out Gradual - LaunchDarkly"
echo "========================================="

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Simular roll-out gradual para 5% de usuarios (±2% precisión)"
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
echo "📊 Test 1: Preparación para Roll-out Gradual"
echo "-------------------------------------------"

# Primero necesitamos reactivar enable_payments si está desactivado
INITIAL_RESPONSE=$(curl -s http://localhost:3001/health/flags)
ENABLE_PAYMENTS=$(echo "$INITIAL_RESPONSE" | jq -r '.flags.enable_payments')

echo "💳 Estado actual de enable_payments: $ENABLE_PAYMENTS"

if [ "$ENABLE_PAYMENTS" = "false" ]; then
    echo ""
    echo -e "${YELLOW}📋 REACTIVAR PAGOS PRIMERO:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🔧 1. Ve al dashboard de LaunchDarkly:"
    echo "   🔗 https://app.launchdarkly.com"
    echo ""
    echo "✅ 2. Activa 'enable_payments' (cambia a TRUE)"
    echo ""
    echo "📈 3. Luego configuraremos el roll-out gradual con 'new_feature_enabled'"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo ""
    echo -e "${BLUE}⏳ Esperando reactivación de pagos...${NC}"
    
    # Esperar a que se reactive
    POLL_INTERVAL=3
    MAX_WAIT_TIME=60
    ELAPSED_TIME=0
    PAYMENTS_REACTIVATED=false
    
    while [ $ELAPSED_TIME -le $MAX_WAIT_TIME ] && [ "$PAYMENTS_REACTIVATED" = false ]; do
        CURRENT_RESPONSE=$(curl -s http://localhost:3001/health/flags 2>/dev/null)
        CURRENT_PAYMENTS=$(echo "$CURRENT_RESPONSE" | jq -r '.flags.enable_payments // "null"')
        
        if [ "$CURRENT_PAYMENTS" = "true" ]; then
            PAYMENTS_REACTIVATED=true
            echo -e "${GREEN}✅ Pagos reactivados correctamente${NC}"
        else
            echo "⏳ Esperando reactivación... (${ELAPSED_TIME}s)"
            sleep $POLL_INTERVAL
            ELAPSED_TIME=$((ELAPSED_TIME + POLL_INTERVAL))
        fi
    done
    
    if [ "$PAYMENTS_REACTIVATED" = false ]; then
        echo -e "${RED}❌ Timeout esperando reactivación de pagos${NC}"
        echo "💡 Puedes continuar el test manualmente después de reactivar"
        exit 1
    fi
fi

echo ""
echo "📊 Test 2: Configurar Roll-out Gradual"
echo "-------------------------------------"

echo -e "${YELLOW}📋 CONFIGURAR ROLL-OUT GRADUAL:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎛️  1. Ve al dashboard de LaunchDarkly:"
echo "   🔗 https://app.launchdarkly.com"
echo ""
echo "🔧 2. Encuentra el flag 'new_feature_enabled'"
echo ""
echo "📈 3. Configura targeting por porcentaje:"
echo "   • Targeting: ON"
echo "   • Roll out to: 5% of users" 
echo "   • Serve: true (para el 5%)"
echo "   • Default: false (para el 95%)"
echo ""
echo "💾 4. GUARDA los cambios"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo -e "${BLUE}⏳ Esperando configuración del roll-out (presiona Enter cuando esté listo)${NC}"
read -p "Presiona Enter para continuar con las pruebas..."

echo ""
echo "📊 Test 3: Simulación de Usuarios"
echo "--------------------------------"

# Simular 100 usuarios diferentes para verificar el porcentaje
TOTAL_USERS=100
FEATURE_ENABLED_COUNT=0
SAMPLE_RESULTS=()

echo "🔄 Probando con ${TOTAL_USERS} usuarios simulados..."
echo ""

# Barra de progreso simple
echo "Progreso: [                    ] 0%"

for i in $(seq 1 $TOTAL_USERS); do
    USER_ID="test_user_${i}"
    
    # Hacer petición para este usuario
    RESPONSE=$(curl -s "http://localhost:3001/health/flags?userId=${USER_ID}" 2>/dev/null)
    NEW_FEATURE=$(echo "$RESPONSE" | jq -r '.flags.all.new_feature_enabled // false')
    
    if [ "$NEW_FEATURE" = "true" ]; then
        FEATURE_ENABLED_COUNT=$((FEATURE_ENABLED_COUNT + 1))
    fi
    
    # Guardar algunos ejemplos para mostrar
    if [ $i -le 10 ]; then
        SAMPLE_RESULTS+=("User $i: $NEW_FEATURE")
    fi
    
    # Actualizar barra de progreso cada 10 usuarios
    if [ $((i % 10)) -eq 0 ]; then
        PROGRESS=$((i * 20 / TOTAL_USERS))
        PROGRESS_BAR=""
        for j in $(seq 1 20); do
            if [ $j -le $PROGRESS ]; then
                PROGRESS_BAR="${PROGRESS_BAR}="
            else
                PROGRESS_BAR="${PROGRESS_BAR} "
            fi
        done
        echo -ne "\rProgreso: [${PROGRESS_BAR}] ${i}%"
    fi
done

echo -ne "\rProgreso: [====================] 100%\n"

echo ""
echo "📋 Muestra de los primeros 10 usuarios:"
for result in "${SAMPLE_RESULTS[@]}"; do
    if [[ $result == *"true"* ]]; then
        echo -e "   ${GREEN}${result}${NC}"
    else
        echo -e "   ${result}"
    fi
done

echo ""
echo "📊 Test 4: Análisis de Resultados"
echo "--------------------------------"

# Calcular porcentaje
PERCENTAGE=$(echo "scale=1; $FEATURE_ENABLED_COUNT * 100 / $TOTAL_USERS" | bc -l)
TARGET_PERCENTAGE=5.0
TOLERANCE=2.0

echo "📈 Resultados del Roll-out:"
echo "   • Total usuarios probados: $TOTAL_USERS"
echo "   • Usuarios con feature activa: $FEATURE_ENABLED_COUNT"
echo "   • Porcentaje real: ${PERCENTAGE}%"
echo "   • Objetivo: ${TARGET_PERCENTAGE}% ±${TOLERANCE}%"
echo "   • Rango aceptable: 3.0% - 7.0%"

# Verificar si está dentro del rango aceptable
MIN_ACCEPTABLE=$(echo "$TARGET_PERCENTAGE - $TOLERANCE" | bc -l)
MAX_ACCEPTABLE=$(echo "$TARGET_PERCENTAGE + $TOLERANCE" | bc -l)

# Comparación usando bc para decimales
WITHIN_RANGE=$(echo "$PERCENTAGE >= $MIN_ACCEPTABLE && $PERCENTAGE <= $MAX_ACCEPTABLE" | bc -l)

if [ "$WITHIN_RANGE" -eq 1 ]; then
    echo -e "   • Estado: ${GREEN}✅ DENTRO DEL RANGO${NC}"
    ROLLOUT_RESULT="PASADO"
    PERFORMANCE_RATING="EXCELENTE"
else
    echo -e "   • Estado: ${RED}❌ FUERA DEL RANGO${NC}"
    ROLLOUT_RESULT="FALLIDO"
    
    if (( $(echo "$PERCENTAGE < $MIN_ACCEPTABLE" | bc -l) )); then
        PERFORMANCE_RATING="BAJO (${PERCENTAGE}% < ${MIN_ACCEPTABLE}%)"
    else
        PERFORMANCE_RATING="ALTO (${PERCENTAGE}% > ${MAX_ACCEPTABLE}%)"
    fi
fi

echo ""
echo "🔍 Análisis detallado:"

# Verificar distribución
echo "   📊 Distribución:"
if [ $FEATURE_ENABLED_COUNT -gt 0 ] && [ $FEATURE_ENABLED_COUNT -lt $TOTAL_USERS ]; then
    echo -e "      ${GREEN}✅ Distribución mixta (algunos usuarios tienen la feature)${NC}"
    DISTRIBUTION_OK=true
else
    echo -e "      ${RED}❌ Distribución problemática (todos o ninguno)${NC}"
    DISTRIBUTION_OK=false
fi

# Verificar consistencia (probar el mismo usuario varias veces)
echo ""
echo "   🔄 Verificando consistencia..."
CONSISTENCY_USER="test_user_42"
CONSISTENT_RESULTS=true
FIRST_RESULT=""

for attempt in $(seq 1 5); do
    RESPONSE=$(curl -s "http://localhost:3001/health/flags?userId=${CONSISTENCY_USER}" 2>/dev/null)
    RESULT=$(echo "$RESPONSE" | jq -r '.flags.all.new_feature_enabled // false')
    
    if [ -z "$FIRST_RESULT" ]; then
        FIRST_RESULT="$RESULT"
    elif [ "$RESULT" != "$FIRST_RESULT" ]; then
        CONSISTENT_RESULTS=false
        break
    fi
done

if [ "$CONSISTENT_RESULTS" = true ]; then
    echo -e "      ${GREEN}✅ Resultados consistentes para el mismo usuario${NC}"
else
    echo -e "      ${RED}❌ Resultados inconsistentes para el mismo usuario${NC}"
fi

echo ""
echo "📊 Test 5: Verificación de Logs"
echo "------------------------------"

echo "🔍 Verificando logs del backend para targeting..."

# Hacer algunas peticiones más para generar logs
for i in {1..5}; do
    curl -s "http://localhost:3001/health/flags?userId=log_test_${i}" > /dev/null 2>&1
done

echo -e "${GREEN}✅ Peticiones enviadas para generar logs${NC}"
echo "💡 Revisa los logs del backend para ver el targeting de LaunchDarkly"

echo ""
echo "🎯 Resumen del Test #7:"
echo "======================"

# Evaluar resultado final
if [ "$ROLLOUT_RESULT" = "PASADO" ] && [ "$DISTRIBUTION_OK" = true ] && [ "$CONSISTENT_RESULTS" = true ]; then
    echo -e "${GREEN}✅ Test #7 PASADO: Roll-out gradual funciona correctamente${NC}"
    FINAL_RESULT="PASADO"
elif [ "$ROLLOUT_RESULT" = "PASADO" ]; then
    echo -e "${YELLOW}⚠️  Test #7 PARCIAL: Porcentaje correcto pero problemas menores${NC}"
    FINAL_RESULT="PARCIAL"
else
    echo -e "${RED}❌ Test #7 FALLIDO: Roll-out fuera del rango aceptable${NC}"
    FINAL_RESULT="FALLIDO"
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Porcentaje obtenido: ${PERCENTAGE}%"
echo "   • Objetivo: ${TARGET_PERCENTAGE}% ±${TOLERANCE}%"
echo "   • Performance: $PERFORMANCE_RATING"
echo "   • Distribución: $([ "$DISTRIBUTION_OK" = true ] && echo "✅ OK" || echo "❌ Problemática")"
echo "   • Consistencia: $([ "$CONSISTENT_RESULTS" = true ] && echo "✅ OK" || echo "❌ Problemática")"

echo ""
echo "🎯 Importancia del Roll-out Gradual:"
echo "   • Deploy seguro de nuevas features"
echo "   • Reduce riesgo en producción"
echo "   • Permite monitorear impacto en subconjunto de usuarios"
echo "   • LaunchDarkly ofrece targeting muy preciso"

echo ""
echo -e "${YELLOW}💡 Para ajustar el porcentaje:${NC}"
echo "   1. Ve al dashboard de LaunchDarkly"
echo "   2. Modifica el porcentaje del roll-out"
echo "   3. Ejecuta este test nuevamente para verificar"

echo ""
echo -e "${YELLOW}🚀 Próximo test: Test #8 - Multivariante${NC}"

# Salir con código apropiado
if [ "$FINAL_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$FINAL_RESULT" = "PARCIAL" ]; then
    exit 1
else
    exit 2
fi 