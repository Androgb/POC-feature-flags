#!/bin/bash

echo "🧪 Test #2: Creación y Lectura de Flags - LaunchDarkly"
echo "====================================================="

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Verificar lectura de flags creados en LaunchDarkly"
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
echo "📊 Test 1: Listar flags existentes"
echo "---------------------------------"

# Obtener lista de flags
FLAGS_RESPONSE=$(curl -s http://localhost:3001/health/flags)
echo "📝 Respuesta del endpoint /health/flags:"
echo "$FLAGS_RESPONSE" | jq '.'

# Contar flags disponibles
FLAGS_COUNT=$(echo "$FLAGS_RESPONSE" | jq '.flags.all | length')
echo ""
echo "📊 Flags detectados: $FLAGS_COUNT"

echo ""
echo "📊 Test 2: Verificar flags esperados"
echo "-----------------------------------"

# Lista de flags esperados para el proyecto
EXPECTED_FLAGS=("enable_payments" "promo_banner_color" "orders_api_version" "new_feature_enabled" "simulate_errors")
FOUND_FLAGS=0

echo "🔍 Verificando flags esperados:"
for flag in "${EXPECTED_FLAGS[@]}"; do
    FLAG_VALUE=$(echo "$FLAGS_RESPONSE" | jq -r ".flags.all.${flag} // \"NOT_FOUND\"")
    
    if [ "$FLAG_VALUE" != "NOT_FOUND" ]; then
        echo -e "   ${GREEN}✅ $flag: $FLAG_VALUE${NC}"
        FOUND_FLAGS=$((FOUND_FLAGS + 1))
    else
        echo -e "   ${RED}❌ $flag: No encontrado${NC}"
    fi
done

FOUND_PERCENTAGE=$(echo "scale=0; $FOUND_FLAGS * 100 / ${#EXPECTED_FLAGS[@]}" | bc)

echo ""
echo "📈 Flags encontrados: $FOUND_FLAGS/${#EXPECTED_FLAGS[@]} ($FOUND_PERCENTAGE%)"

echo ""
echo "📊 Test 3: Verificar tipos de datos"
echo "----------------------------------"

echo "🔍 Analizando tipos de flags:"

# Boolean flags
BOOLEAN_FLAGS=$(echo "$FLAGS_RESPONSE" | jq -r '.flags.all | to_entries | .[] | select(.value == true or .value == false) | .key')
BOOLEAN_COUNT=$(echo "$BOOLEAN_FLAGS" | wc -l)
echo "   📊 Boolean flags: $BOOLEAN_COUNT"
echo "$BOOLEAN_FLAGS" | head -3 | while read flag; do
    if [ -n "$flag" ]; then
        value=$(echo "$FLAGS_RESPONSE" | jq -r ".flags.all.${flag}")
        echo "      • $flag: $value"
    fi
done

# String flags
STRING_FLAGS=$(echo "$FLAGS_RESPONSE" | jq -r '.flags.all | to_entries | .[] | select(.value | type == "string") | .key')
STRING_COUNT=$(echo "$STRING_FLAGS" | wc -l)
echo "   📊 String flags: $STRING_COUNT"
echo "$STRING_FLAGS" | head -3 | while read flag; do
    if [ -n "$flag" ]; then
        value=$(echo "$FLAGS_RESPONSE" | jq -r ".flags.all.${flag}")
        echo "      • $flag: \"$value\""
    fi
done

echo ""
echo "📊 Test 4: Verificar timestamp y metadatos"
echo "-----------------------------------------"

TIMESTAMP=$(echo "$FLAGS_RESPONSE" | jq -r '.timestamp // "unknown"')
echo "⏰ Timestamp: $TIMESTAMP"

# Verificar formato de timestamp
if [[ "$TIMESTAMP" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
    echo -e "${GREEN}✅ Timestamp formato válido${NC}"
    TIMESTAMP_OK=true
else
    echo -e "${YELLOW}⚠️  Timestamp formato no estándar${NC}"
    TIMESTAMP_OK=false
fi

echo ""
echo "📊 Test 5: Verificar consistencia de flags"
echo "-----------------------------------------"

echo "🔄 Realizando múltiples lecturas para verificar consistencia..."

# Realizar 3 lecturas consecutivas
CONSISTENT=true
FIRST_RESPONSE=""

for i in {1..3}; do
    CURRENT_RESPONSE=$(curl -s http://localhost:3001/health/flags | jq '.flags.all')
    
    if [ $i -eq 1 ]; then
        FIRST_RESPONSE="$CURRENT_RESPONSE"
        echo "   📊 Lectura $i: Baseline establecido"
    else
        if [ "$CURRENT_RESPONSE" = "$FIRST_RESPONSE" ]; then
            echo -e "   ${GREEN}📊 Lectura $i: Consistente${NC}"
        else
            echo -e "   ${RED}📊 Lectura $i: Inconsistente${NC}"
            CONSISTENT=false
        fi
    fi
    
    sleep 1
done

if [ "$CONSISTENT" = true ]; then
    echo -e "${GREEN}✅ Flags consistentes entre lecturas${NC}"
else
    echo -e "${YELLOW}⚠️  Variación detectada (puede ser normal)${NC}"
fi

echo ""
echo "🎯 Resumen del Test #2:"
echo "======================"

# Evaluar resultado final
SCORE=0

# Scoring system
if [ $FOUND_FLAGS -ge 4 ]; then
    SCORE=$((SCORE + 40))
elif [ $FOUND_FLAGS -ge 2 ]; then
    SCORE=$((SCORE + 25))
fi

if [ $FLAGS_COUNT -gt 0 ]; then
    SCORE=$((SCORE + 25))
fi

if [ "$TIMESTAMP_OK" = true ]; then
    SCORE=$((SCORE + 15))
fi

if [ "$CONSISTENT" = true ]; then
    SCORE=$((SCORE + 20))
fi

if [ $SCORE -ge 80 ]; then
    echo -e "${GREEN}✅ Test #2 PASADO: Flags creados y leídos correctamente${NC}"
    FINAL_RESULT="PASADO"
elif [ $SCORE -ge 60 ]; then
    echo -e "${YELLOW}⚠️  Test #2 PARCIAL: Flags funcionales con limitaciones${NC}"
    FINAL_RESULT="PARCIAL"
else
    echo -e "${RED}❌ Test #2 FALLIDO: Problemas con flags${NC}"
    FINAL_RESULT="FALLIDO"
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Score: $SCORE/100"
echo "   • Flags encontrados: $FOUND_FLAGS/${#EXPECTED_FLAGS[@]}"
echo "   • Total flags: $FLAGS_COUNT"
echo "   • Boolean flags: $BOOLEAN_COUNT"
echo "   • String flags: $STRING_COUNT"
echo "   • Consistencia: $([ "$CONSISTENT" = true ] && echo "✅ OK" || echo "⚠️ Variable")"

echo ""
echo "🚀 Próximo test: Test #3 - Lectura desde backend"

# Salir con código apropiado
if [ "$FINAL_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$FINAL_RESULT" = "PARCIAL" ]; then
    exit 1
else
    exit 2
fi 