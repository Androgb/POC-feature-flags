#!/bin/bash

echo "🧪 Test #9: Versión de Contrato (v1 ↔ v2) - LaunchDarkly"
echo "======================================================="

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Verificar migración gradual de API v1 → v2 con backend dual"
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
echo "📊 Test 1: Estado actual del flag de versión"
echo "-------------------------------------------"

# Verificar estado inicial
INITIAL_RESPONSE=$(curl -s http://localhost:3001/health/flags)
API_VERSION=$(echo "$INITIAL_RESPONSE" | jq -r '.flags.all.orders_api_version // "unknown"')

echo "⚙️  Versión actual de orders_api_version: $API_VERSION"

# Verificar que es una versión válida
VALID_VERSIONS=("v1" "v2")
VERSION_VALID=false

for version in "${VALID_VERSIONS[@]}"; do
    if [ "$API_VERSION" = "$version" ]; then
        VERSION_VALID=true
        break
    fi
done

if [ "$VERSION_VALID" = true ]; then
    echo -e "   ${GREEN}✅ Versión válida detectada (String configurado correctamente)${NC}"
    echo -e "   ${BLUE}💡 Ventaja LaunchDarkly: String nativo vs Boolean en ConfigCat${NC}"
else
    echo -e "   ${YELLOW}⚠️  Versión no estándar: $API_VERSION${NC}"
    echo -e "   ${YELLOW}💡 Esperado: 'v1' o 'v2' como string${NC}"
fi

echo ""
echo "📊 Test 2: Verificar Backend en Modo Dual"
echo "----------------------------------------"

echo "🔄 Probando ambos endpoints de Orders API..."

# Test API v1
echo ""
echo "   📋 1. Testing API v1 (POST /orders):"
V1_TEST=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X POST http://localhost:3001/orders \
  -H "Content-Type: application/json" \
  -d '{
    "paymentId": "pay_v1_test",
    "items": [{"id": "item1", "quantity": 2}],
    "userId": "api_version_test"
  }')

V1_STATUS=$(echo $V1_TEST | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
V1_BODY=$(echo $V1_TEST | sed -E 's/HTTPSTATUS:[0-9]*$//')

if [ $V1_STATUS -eq 200 ] || [ $V1_STATUS -eq 201 ]; then
    echo -e "      ${GREEN}✅ API v1 disponible (HTTP $V1_STATUS)${NC}"
    V1_AVAILABLE=true
else
    echo -e "      ${RED}❌ API v1 no disponible (HTTP $V1_STATUS)${NC}"
    V1_AVAILABLE=false
fi

echo "      📄 Respuesta v1: $(echo "$V1_BODY" | jq -r '.message // .status // "Response OK"' 2>/dev/null || echo "OK")"

# Test API v2
echo ""
echo "   📋 2. Testing API v2 (POST /orders/v2):"
V2_TEST=$(curl -s -w "HTTPSTATUS:%{http_code}" \
  -X POST http://localhost:3001/orders/v2 \
  -H "Content-Type: application/json" \
  -d '{
    "paymentId": "pay_v2_test",
    "items": [{"id": "item1", "quantity": 2}],
    "userId": "api_version_test"
  }')

V2_STATUS=$(echo $V2_TEST | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
V2_BODY=$(echo $V2_TEST | sed -E 's/HTTPSTATUS:[0-9]*$//')

if [ $V2_STATUS -eq 200 ] || [ $V2_STATUS -eq 201 ]; then
    echo -e "      ${GREEN}✅ API v2 disponible (HTTP $V2_STATUS)${NC}"
    V2_AVAILABLE=true
else
    echo -e "      ${RED}❌ API v2 no disponible (HTTP $V2_STATUS)${NC}"
    V2_AVAILABLE=false
fi

echo "      📄 Respuesta v2: $(echo "$V2_BODY" | jq -r '.message // .status // "Response OK"' 2>/dev/null || echo "OK")"

# Verificar modo dual
if [ "$V1_AVAILABLE" = true ] && [ "$V2_AVAILABLE" = true ]; then
    echo -e "${GREEN}✅ Backend en modo dual: Soporta v1 y v2${NC}"
    DUAL_MODE=true
else
    echo -e "${RED}❌ Backend no está en modo dual${NC}"
    DUAL_MODE=false
fi

echo ""
echo "📊 Test 3: Simulación de Usuarios con Diferentes Versiones"
echo "---------------------------------------------------------"

# Simular usuarios para ver distribución de versiones API
TOTAL_USERS=30
declare -A VERSION_COUNT
VERSION_COUNT["v1"]=0
VERSION_COUNT["v2"]=0
VERSION_COUNT["other"]=0

SAMPLE_RESULTS=()

echo "🔄 Probando con ${TOTAL_USERS} usuarios para ver distribución de versiones..."
echo ""

for i in $(seq 1 $TOTAL_USERS); do
    USER_ID="api_version_test_${i}"
    
    # Hacer petición para este usuario
    RESPONSE=$(curl -s "http://localhost:3001/health/flags?userId=${USER_ID}" 2>/dev/null)
    USER_VERSION=$(echo "$RESPONSE" | jq -r '.flags.all.orders_api_version // "unknown"')
    
    # Contar versiones
    case "$USER_VERSION" in
        "v1")
            VERSION_COUNT["v1"]=$((VERSION_COUNT["v1"] + 1))
            ;;
        "v2")
            VERSION_COUNT["v2"]=$((VERSION_COUNT["v2"] + 1))
            ;;
        *)
            VERSION_COUNT["other"]=$((VERSION_COUNT["other"] + 1))
            ;;
    esac
    
    # Guardar algunos ejemplos
    if [ $i -le 10 ]; then
        SAMPLE_RESULTS+=("User $i: $USER_VERSION")
    fi
    
    # Barra de progreso simple
    if [ $((i % 5)) -eq 0 ]; then
        echo -ne "   Progreso: ${i}/${TOTAL_USERS} usuarios\r"
    fi
done

echo -ne "   Progreso: ${TOTAL_USERS}/${TOTAL_USERS} usuarios ✅\n"

echo ""
echo "📋 Muestra de los primeros 10 usuarios:"
for result in "${SAMPLE_RESULTS[@]}"; do
    case "$result" in
        *"v1"*)
            echo -e "   ${BLUE}${result}${NC}"
            ;;
        *"v2"*)
            echo -e "   ${GREEN}${result}${NC}"
            ;;
        *)
            echo -e "   ${YELLOW}${result}${NC}"
            ;;
    esac
done

echo ""
echo "📊 Test 4: Análisis de Distribución de Versiones"
echo "------------------------------------------------"

# Calcular porcentajes
V1_PERCENT=$(echo "scale=1; ${VERSION_COUNT[v1]} * 100 / $TOTAL_USERS" | bc -l)
V2_PERCENT=$(echo "scale=1; ${VERSION_COUNT[v2]} * 100 / $TOTAL_USERS" | bc -l)
OTHER_PERCENT=$(echo "scale=1; ${VERSION_COUNT[other]} * 100 / $TOTAL_USERS" | bc -l)

echo "📈 Distribución de versiones de API:"
echo -e "   ${BLUE}📊 v1: ${VERSION_COUNT[v1]} usuarios (${V1_PERCENT}%)${NC}"
echo -e "   ${GREEN}📊 v2: ${VERSION_COUNT[v2]} usuarios (${V2_PERCENT}%)${NC}"

if [ ${VERSION_COUNT[other]} -gt 0 ]; then
    echo -e "   ${YELLOW}📊 Otras: ${VERSION_COUNT[other]} usuarios (${OTHER_PERCENT}%)${NC}"
fi

echo ""
echo "🔍 Análisis de migración:"

# Verificar distribución (configurado: 10% v2, 90% v1)
MIGRATION_STRATEGY=""
TARGET_V2_PERCENT=10
TOLERANCE=5  # ±5% tolerancia

if [ ${VERSION_COUNT[v1]} -gt 0 ] && [ ${VERSION_COUNT[v2]} -gt 0 ]; then
    echo -e "   ${GREEN}✅ Migración gradual en progreso${NC}"
    MIGRATION_STATUS="GRADUAL"
    
    # Verificar si está cerca del target (10% v2)
    if (( $(echo "${V2_PERCENT} >= 5 && ${V2_PERCENT} <= 15" | bc -l) )); then
        MIGRATION_STRATEGY="Configuración 10% v2 activa (actual: ${V2_PERCENT}%)"
        echo -e "   ${GREEN}🎯 Distribución correcta: ~10% v2 según configuración${NC}"
    elif (( $(echo "${V2_PERCENT} < 5" | bc -l) )); then
        MIGRATION_STRATEGY="Inicio de migración (${V2_PERCENT}% en v2 - menor que target 10%)"
    elif (( $(echo "${V2_PERCENT} > 15" | bc -l) )); then
        MIGRATION_STRATEGY="Migración activa (${V2_PERCENT}% en v2 - mayor que target 10%)"
    fi
elif [ ${VERSION_COUNT[v2]} -eq $TOTAL_USERS ]; then
    echo -e "   ${GREEN}✅ Migración completa a v2${NC}"
    MIGRATION_STATUS="COMPLETE_V2"
    MIGRATION_STRATEGY="100% migrados a v2"
elif [ ${VERSION_COUNT[v1]} -eq $TOTAL_USERS ]; then
    echo -e "   ${BLUE}📊 Todos en v1 (migración no iniciada)${NC}"
    MIGRATION_STATUS="ALL_V1"
    MIGRATION_STRATEGY="Sin migración (100% en v1)"
else
    echo -e "   ${RED}❌ Estado de migración inconsistente${NC}"
    MIGRATION_STATUS="INCONSISTENT"
    MIGRATION_STRATEGY="Estado problemático"
fi

echo "   🎯 Estrategia: $MIGRATION_STRATEGY"

echo ""
echo "📊 Test 5: Simulación de Peticiones API por Versión"
echo "---------------------------------------------------"

echo "🔄 Simulando peticiones reales basadas en la distribución detectada..."

# Hacer algunas peticiones simulando el comportamiento real
for version_test in {1..5}; do
    TEST_USER="version_simulation_${version_test}"
    
    # Obtener versión para este usuario
    RESPONSE=$(curl -s "http://localhost:3001/health/flags?userId=${TEST_USER}" 2>/dev/null)
    USER_API_VERSION=$(echo "$RESPONSE" | jq -r '.flags.all.orders_api_version // "v1"')
    
    # Hacer petición al endpoint correcto
    if [ "$USER_API_VERSION" = "v2" ]; then
        ENDPOINT="http://localhost:3001/orders/v2"
    else
        ENDPOINT="http://localhost:3001/orders"
    fi
    
    echo "   👤 Usuario $version_test → $USER_API_VERSION → $ENDPOINT"
    
    # Hacer petición (sin mostrar detalles para no saturar)
    API_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
      -X POST "$ENDPOINT" \
      -H "Content-Type: application/json" \
      -d "{\"paymentId\": \"test_${version_test}\", \"items\": [{\"id\": \"item1\", \"quantity\": 1}], \"userId\": \"${TEST_USER}\"}" 2>/dev/null)
    
    API_STATUS=$(echo $API_RESPONSE | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    
    if [ $API_STATUS -eq 200 ] || [ $API_STATUS -eq 201 ]; then
        echo -e "      ${GREEN}✅ Petición exitosa (HTTP $API_STATUS)${NC}"
    else
        echo -e "      ${RED}❌ Petición falló (HTTP $API_STATUS)${NC}"
    fi
done

echo ""
echo "🎯 Resumen del Test #9:"
echo "======================"

# Evaluar resultado final
VERSIONING_SUCCESS=false

if [ "$DUAL_MODE" = true ] && [ "$MIGRATION_STATUS" != "INCONSISTENT" ]; then
    if [ "$MIGRATION_STATUS" = "GRADUAL" ] || [ "$MIGRATION_STATUS" = "ALL_V1" ] || [ "$MIGRATION_STATUS" = "COMPLETE_V2" ]; then
        echo -e "${GREEN}✅ Test #9 PASADO: Versionado de API funciona correctamente${NC}"
        FINAL_RESULT="PASADO"
        VERSIONING_SUCCESS=true
    fi
fi

if [ "$VERSIONING_SUCCESS" = false ]; then
    if [ "$DUAL_MODE" = true ]; then
        echo -e "${YELLOW}⚠️  Test #9 PARCIAL: Backend dual pero distribución problemática${NC}"
        FINAL_RESULT="PARCIAL"
    else
        echo -e "${RED}❌ Test #9 FALLIDO: Backend no soporta modo dual${NC}"
        FINAL_RESULT="FALLIDO"
    fi
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Modo dual: $([ "$DUAL_MODE" = true ] && echo "✅ Soportado" || echo "❌ No soportado")"
echo "   • Estado migración: $MIGRATION_STATUS"
echo "   • Distribución v1: ${V1_PERCENT}%"
echo "   • Distribución v2: ${V2_PERCENT}%"
echo "   • Estrategia: $MIGRATION_STRATEGY"

echo ""
echo "🔄 Importancia del Versionado de API:"
echo "   • Migración sin downtime entre versiones"
echo "   • Backend dual permite compatibilidad"
echo "   • Feature flags facilitan rollout gradual"
echo "   • Reduce riesgo en cambios de contrato"

echo ""
echo -e "${YELLOW}💡 Para cambiar distribución v1/v2:${NC}"
echo "   1. Ve al dashboard de LaunchDarkly"
echo "   2. Ajusta 'orders_api_version' targeting"
echo "   3. Incrementa gradualmente % de v2"
echo "   4. Monitorea métricas de error"

echo ""
echo -e "${YELLOW}🚀 Próximo test: Test #10 - Rollback inmediato${NC}"

# Salir con código apropiado
if [ "$FINAL_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$FINAL_RESULT" = "PARCIAL" ]; then
    exit 1
else
    exit 2
fi 