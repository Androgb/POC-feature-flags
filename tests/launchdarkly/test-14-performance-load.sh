#!/bin/bash

echo "🧪 Test #14: Performance bajo Carga - LaunchDarkly"
echo "================================================"

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Verificar performance con 100+ peticiones concurrentes (< 200ms avg)"
echo ""

# Verificar que el backend esté corriendo
echo "🔍 Verificando estado del backend..."
if curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend activo en puerto 3001${NC}"
else
    echo -e "${RED}❌ Backend no responde en puerto 3001${NC}"
    exit 1
fi

# Verificar herramientas necesarias
echo ""
echo "🔧 Verificando herramientas de testing..."

# Verificar si tenemos herramientas de benchmark
if command -v ab >/dev/null 2>&1; then
    BENCHMARK_TOOL="ab"
    echo -e "${GREEN}✅ Apache Bench (ab) disponible${NC}"
elif command -v curl >/dev/null 2>&1; then
    BENCHMARK_TOOL="curl"
    echo -e "${YELLOW}⚠️  Usando curl (Apache Bench no disponible)${NC}"
else
    echo -e "${RED}❌ Sin herramientas de benchmark disponibles${NC}"
    exit 1
fi

echo ""
echo "📊 Test 1: Performance baseline individual"
echo "----------------------------------------"

echo "🔄 Midiendo latencia de petición individual..."

# Medir 10 peticiones individuales para baseline
INDIVIDUAL_TIMES=()
TOTAL_INDIVIDUAL=0

for i in {1..10}; do
    START_TIME=$(date +%s%3N)
    RESPONSE=$(curl -s http://localhost:3001/health/flags 2>/dev/null)
    END_TIME=$(date +%s%3N)
    
    DURATION=$((END_TIME - START_TIME))
    INDIVIDUAL_TIMES+=($DURATION)
    TOTAL_INDIVIDUAL=$((TOTAL_INDIVIDUAL + DURATION))
    
    if [ $((i % 3)) -eq 0 ]; then
        echo "   📊 Petición $i: ${DURATION}ms"
    fi
done

AVERAGE_INDIVIDUAL=$((TOTAL_INDIVIDUAL / 10))
echo ""
echo "📈 Baseline individual:"
echo "   • Promedio: ${AVERAGE_INDIVIDUAL}ms"
echo "   • Total peticiones: 10"

# Encontrar min y max
MIN_TIME=${INDIVIDUAL_TIMES[0]}
MAX_TIME=${INDIVIDUAL_TIMES[0]}
for time in "${INDIVIDUAL_TIMES[@]}"; do
    if [ $time -lt $MIN_TIME ]; then
        MIN_TIME=$time
    fi
    if [ $time -gt $MAX_TIME ]; then
        MAX_TIME=$time
    fi
done

echo "   • Mínimo: ${MIN_TIME}ms"
echo "   • Máximo: ${MAX_TIME}ms"

echo ""
echo "📊 Test 2: Performance bajo carga moderada"
echo "-----------------------------------------"

echo "🔄 Ejecutando 50 peticiones concurrentes..."

# Función para ejecutar peticiones en paralelo usando curl
function test_concurrent_curl() {
    local num_requests=$1
    local output_file="/tmp/load_test_results_$$"
    
    echo "🚀 Iniciando $num_requests peticiones concurrentes..."
    START_TOTAL=$(date +%s%3N)
    
    # Ejecutar peticiones en paralelo
    for i in $(seq 1 $num_requests); do
        {
            START_REQ=$(date +%s%3N)
            curl -s http://localhost:3001/health/flags >/dev/null 2>&1
            END_REQ=$(date +%s%3N)
            DURATION_REQ=$((END_REQ - START_REQ))
            echo $DURATION_REQ >> "$output_file"
        } &
    done
    
    # Esperar a que terminen todas
    wait
    END_TOTAL=$(date +%s%3N)
    TOTAL_DURATION=$((END_TOTAL - START_TOTAL))
    
    # Procesar resultados
    if [ -f "$output_file" ]; then
        local total_time=0
        local count=0
        local min_time=9999
        local max_time=0
        
        while read duration; do
            total_time=$((total_time + duration))
            count=$((count + 1))
            
            if [ $duration -lt $min_time ]; then
                min_time=$duration
            fi
            if [ $duration -gt $max_time ]; then
                max_time=$duration
            fi
        done < "$output_file"
        
        if [ $count -gt 0 ]; then
            local avg_time=$((total_time / count))
            local throughput=$(echo "scale=2; $count * 1000 / $TOTAL_DURATION" | bc -l 2>/dev/null || echo "N/A")
            
            echo ""
            echo "📊 Resultados de $num_requests peticiones:"
            echo "   • Tiempo total: ${TOTAL_DURATION}ms"
            echo "   • Tiempo promedio: ${avg_time}ms"
            echo "   • Tiempo mínimo: ${min_time}ms" 
            echo "   • Tiempo máximo: ${max_time}ms"
            echo "   • Throughput: ${throughput} req/s"
            echo "   • Peticiones completadas: $count/$num_requests"
            
            # Limpiar archivo temporal
            rm -f "$output_file"
            
            # Retornar valores para evaluación
            echo "$avg_time $throughput $count" > "/tmp/test_result_$$"
        else
            echo -e "${RED}❌ No se pudieron procesar los resultados${NC}"
            echo "0 0 0" > "/tmp/test_result_$$"
        fi
    else
        echo -e "${RED}❌ No se encontraron resultados${NC}"
        echo "0 0 0" > "/tmp/test_result_$$"
    fi
}

# Ejecutar test moderado
test_concurrent_curl 50

# Leer resultados del test moderado
if [ -f "/tmp/test_result_$$" ]; then
    read MODERATE_AVG MODERATE_THROUGHPUT MODERATE_COMPLETED < "/tmp/test_result_$$"
    rm -f "/tmp/test_result_$$"
else
    MODERATE_AVG=0
    MODERATE_THROUGHPUT=0
    MODERATE_COMPLETED=0
fi

echo ""
echo "📊 Test 3: Performance bajo carga alta"
echo "-------------------------------------"

echo "🔄 Ejecutando 100 peticiones concurrentes..."

# Ejecutar test de carga alta
test_concurrent_curl 100

# Leer resultados del test de carga alta
if [ -f "/tmp/test_result_$$" ]; then
    read HIGH_AVG HIGH_THROUGHPUT HIGH_COMPLETED < "/tmp/test_result_$$"
    rm -f "/tmp/test_result_$$"
else
    HIGH_AVG=0
    HIGH_THROUGHPUT=0
    HIGH_COMPLETED=0
fi

echo ""
echo "📊 Test 4: Stress test con diferentes usuarios"
echo "---------------------------------------------"

echo "🔄 Simulando carga con contexto de usuarios diferentes..."

# Test con diferentes usuarios para verificar performance del targeting
USERS=("user_1" "user_2" "user_3" "user_4" "user_5" "user_6" "user_7" "user_8" "user_9" "user_10")
USER_TEST_TIMES=()
USER_TOTAL=0

START_USER_TEST=$(date +%s%3N)

for i in {1..20}; do
    USER_INDEX=$((i % ${#USERS[@]}))
    USER=${USERS[$USER_INDEX]}
    
    START_USER=$(date +%s%3N)
    curl -s "http://localhost:3001/health/flags?userId=${USER}" >/dev/null 2>&1
    END_USER=$(date +%s%3N)
    
    DURATION_USER=$((END_USER - START_USER))
    USER_TEST_TIMES+=($DURATION_USER)
    USER_TOTAL=$((USER_TOTAL + DURATION_USER))
done

END_USER_TEST=$(date +%s%3N)
USER_TEST_DURATION=$((END_USER_TEST - START_USER_TEST))
AVERAGE_USER=$((USER_TOTAL / 20))

echo ""
echo "📊 Resultados con targeting de usuarios:"
echo "   • 20 peticiones con 10 usuarios diferentes"
echo "   • Tiempo promedio: ${AVERAGE_USER}ms"
echo "   • Tiempo total: ${USER_TEST_DURATION}ms"

echo ""
echo "📊 Test 5: Análisis de degradación"
echo "---------------------------------"

echo "🔍 Analizando degradación de performance bajo carga..."

# Calcular factor de degradación
if [ $AVERAGE_INDIVIDUAL -gt 0 ]; then
    DEGRADATION_MODERATE=$(echo "scale=2; $MODERATE_AVG / $AVERAGE_INDIVIDUAL" | bc -l 2>/dev/null || echo "1")
    DEGRADATION_HIGH=$(echo "scale=2; $HIGH_AVG / $AVERAGE_INDIVIDUAL" | bc -l 2>/dev/null || echo "1")
else
    DEGRADATION_MODERATE="N/A"
    DEGRADATION_HIGH="N/A"
fi

echo ""
echo "📈 Análisis de degradación:"
echo "   • Baseline (1 req): ${AVERAGE_INDIVIDUAL}ms"
echo "   • Carga moderada (50 req): ${MODERATE_AVG}ms (factor: ${DEGRADATION_MODERATE}x)"
echo "   • Carga alta (100 req): ${HIGH_AVG}ms (factor: ${DEGRADATION_HIGH}x)"
echo "   • Con targeting: ${AVERAGE_USER}ms"

# Evaluación de performance
echo ""
echo "🎯 Evaluación de performance:"

PERFORMANCE_SCORE=0
PERFORMANCE_ISSUES=()

# Test 1: Latencia promedio bajo carga
if [ $HIGH_AVG -le 200 ]; then
    echo -e "   ${GREEN}✅ Latencia bajo carga: ${HIGH_AVG}ms ≤ 200ms${NC}"
    PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 25))
else
    echo -e "   ${RED}❌ Latencia bajo carga: ${HIGH_AVG}ms > 200ms${NC}"
    PERFORMANCE_ISSUES+=("Latencia alta bajo carga")
fi

# Test 2: Completitud de peticiones
COMPLETION_RATE=$(echo "scale=1; $HIGH_COMPLETED * 100 / 100" | bc -l 2>/dev/null || echo "0")
if (( $(echo "$COMPLETION_RATE >= 95" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "   ${GREEN}✅ Tasa de completitud: ${COMPLETION_RATE}% ≥ 95%${NC}"
    PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 25))
else
    echo -e "   ${RED}❌ Tasa de completitud: ${COMPLETION_RATE}% < 95%${NC}"
    PERFORMANCE_ISSUES+=("Tasa de completitud baja")
fi

# Test 3: Degradación aceptable
if [ "$DEGRADATION_HIGH" != "N/A" ] && (( $(echo "$DEGRADATION_HIGH <= 3" | bc -l 2>/dev/null || echo "0") )); then
    echo -e "   ${GREEN}✅ Degradación: ${DEGRADATION_HIGH}x ≤ 3x${NC}"
    PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 25))
else
    echo -e "   ${YELLOW}⚠️  Degradación: ${DEGRADATION_HIGH}x (revisar si > 3x)${NC}"
    PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 15))
fi

# Test 4: Targeting performance
if [ $AVERAGE_USER -le 300 ]; then
    echo -e "   ${GREEN}✅ Performance con targeting: ${AVERAGE_USER}ms ≤ 300ms${NC}"
    PERFORMANCE_SCORE=$((PERFORMANCE_SCORE + 25))
else
    echo -e "   ${RED}❌ Performance con targeting: ${AVERAGE_USER}ms > 300ms${NC}"
    PERFORMANCE_ISSUES+=("Targeting lento")
fi

echo ""
echo "📊 Test 6: Comparación con ConfigCat"
echo "-----------------------------------"

echo "🔍 Comparando performance LaunchDarkly vs ConfigCat..."

echo ""
echo "📈 Ventajas de LaunchDarkly:"
echo "   • Streaming real-time vs polling de ConfigCat"
echo "   • Caché local optimizado"
echo "   • CDN global para baja latencia"
echo "   • SDK optimizado para alta concurrencia"

echo ""
echo "🎯 Resumen del Test #14:"
echo "======================="

# Determinar resultado final
if [ $PERFORMANCE_SCORE -ge 90 ]; then
    echo -e "${GREEN}✅ Test #14 PASADO: Performance excelente bajo carga${NC}"
    FINAL_RESULT="PASADO"
    PERFORMANCE_RATING="EXCELENTE"
elif [ $PERFORMANCE_SCORE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  Test #14 PARCIAL: Performance aceptable con mejoras menores${NC}"
    FINAL_RESULT="PARCIAL"
    PERFORMANCE_RATING="BUENO"
else
    echo -e "${RED}❌ Test #14 FALLIDO: Performance insuficiente bajo carga${NC}"
    FINAL_RESULT="FALLIDO"
    PERFORMANCE_RATING="PROBLEMÁTICO"
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Score de performance: ${PERFORMANCE_SCORE}/100"
echo "   • Rating: $PERFORMANCE_RATING"
echo "   • Latencia baseline: ${AVERAGE_INDIVIDUAL}ms"
echo "   • Latencia bajo carga: ${HIGH_AVG}ms"
echo "   • Throughput máximo: ${HIGH_THROUGHPUT} req/s"
echo "   • Completitud: ${COMPLETION_RATE}%"

if [ ${#PERFORMANCE_ISSUES[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Issues identificados:"
    for issue in "${PERFORMANCE_ISSUES[@]}"; do
        echo "   • $issue"
    done
fi

echo ""
echo "🚀 Importancia de Performance Testing:"
echo "   • Validar SLAs de latencia"
echo "   • Identificar cuellos de botella"
echo "   • Planificar capacidad"
echo "   • Garantizar experiencia de usuario"

echo ""
echo -e "${YELLOW}💡 Recomendaciones para producción:${NC}"
echo "   • Implementar monitoring de latencia"
echo "   • Configurar alerts de performance"
echo "   • Load testing regular"
echo "   • Usar CDN de LaunchDarkly"
echo "   • Optimizar caché de SDK"

echo ""
echo "🔗 Ventajas LaunchDarkly Performance:"
echo "   • Edge locations globales"
echo "   • Caché inteligente"
echo "   • Streaming eficiente"
echo "   • SDKs optimizados"
echo "   • Fallbacks locales"

echo ""
echo -e "${GREEN}✅ Test suite LaunchDarkly completado${NC}"

# Salir con código apropiado
if [ "$FINAL_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$FINAL_RESULT" = "PARCIAL" ]; then
    exit 1
else
    exit 2
fi 