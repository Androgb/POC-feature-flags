#!/bin/bash

echo "🧪 Test #8: Multivariante - LaunchDarkly"
echo "======================================="

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "🎯 Objetivo: Verificar flag multivariante promo_banner_color (green/blue/red)"
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
echo "📊 Test 1: Estado actual del flag multivariante"
echo "----------------------------------------------"

# Verificar estado inicial
INITIAL_RESPONSE=$(curl -s http://localhost:3001/health/flags)
BANNER_COLOR=$(echo "$INITIAL_RESPONSE" | jq -r '.flags.all.promo_banner_color // "unknown"')

echo "🎨 Valor actual de promo_banner_color: $BANNER_COLOR"

# Verificar que es un valor válido
VALID_COLORS=("green" "blue" "red")
COLOR_VALID=false

for color in "${VALID_COLORS[@]}"; do
    if [ "$BANNER_COLOR" = "$color" ]; then
        COLOR_VALID=true
        break
    fi
done

if [ "$COLOR_VALID" = true ]; then
    echo -e "   ${GREEN}✅ Color válido detectado${NC}"
else
    echo -e "   ${YELLOW}⚠️  Color no estándar: $BANNER_COLOR${NC}"
fi

echo ""
echo "📊 Test 2: Simulación de Usuarios Multivariante"
echo "-----------------------------------------------"

# Simular diferentes usuarios para ver distribución de colores
TOTAL_USERS=50
declare -A COLOR_COUNT
COLOR_COUNT["green"]=0
COLOR_COUNT["blue"]=0
COLOR_COUNT["red"]=0
COLOR_COUNT["other"]=0

SAMPLE_RESULTS=()

echo "🔄 Probando con ${TOTAL_USERS} usuarios para ver distribución..."
echo ""

# Barra de progreso
echo "Progreso: [                    ] 0%"

for i in $(seq 1 $TOTAL_USERS); do
    USER_ID="test_user_multivariate_${i}"
    
    # Hacer petición para este usuario
    RESPONSE=$(curl -s "http://localhost:3001/health/flags?userId=${USER_ID}" 2>/dev/null)
    USER_COLOR=$(echo "$RESPONSE" | jq -r '.flags.all.promo_banner_color // "unknown"')
    
    # Contar colores
    case "$USER_COLOR" in
        "green")
            COLOR_COUNT["green"]=$((COLOR_COUNT["green"] + 1))
            ;;
        "blue")
            COLOR_COUNT["blue"]=$((COLOR_COUNT["blue"] + 1))
            ;;
        "red")
            COLOR_COUNT["red"]=$((COLOR_COUNT["red"] + 1))
            ;;
        *)
            COLOR_COUNT["other"]=$((COLOR_COUNT["other"] + 1))
            ;;
    esac
    
    # Guardar algunos ejemplos
    if [ $i -le 15 ]; then
        SAMPLE_RESULTS+=("User $i: $USER_COLOR")
    fi
    
    # Actualizar barra de progreso cada 5 usuarios
    if [ $((i % 5)) -eq 0 ]; then
        PROGRESS=$((i * 20 / TOTAL_USERS))
        PROGRESS_BAR=""
        for j in $(seq 1 20); do
            if [ $j -le $PROGRESS ]; then
                PROGRESS_BAR="${PROGRESS_BAR}="
            else
                PROGRESS_BAR="${PROGRESS_BAR} "
            fi
        done
        echo -ne "\rProgreso: [${PROGRESS_BAR}] ${i}/${TOTAL_USERS}"
    fi
done

echo -ne "\rProgreso: [====================] ${TOTAL_USERS}/${TOTAL_USERS}\n"

echo ""
echo "📋 Muestra de los primeros 15 usuarios:"
for result in "${SAMPLE_RESULTS[@]}"; do
    case "$result" in
        *"green"*)
            echo -e "   ${GREEN}${result}${NC}"
            ;;
        *"blue"*)
            echo -e "   ${BLUE}${result}${NC}"
            ;;
        *"red"*)
            echo -e "   ${RED}${result}${NC}"
            ;;
        *)
            echo -e "   ${YELLOW}${result}${NC}"
            ;;
    esac
done

echo ""
echo "📊 Test 3: Análisis de Distribución"
echo "----------------------------------"

# Calcular porcentajes
GREEN_PERCENT=$(echo "scale=1; ${COLOR_COUNT[green]} * 100 / $TOTAL_USERS" | bc -l)
BLUE_PERCENT=$(echo "scale=1; ${COLOR_COUNT[blue]} * 100 / $TOTAL_USERS" | bc -l)
RED_PERCENT=$(echo "scale=1; ${COLOR_COUNT[red]} * 100 / $TOTAL_USERS" | bc -l)
OTHER_PERCENT=$(echo "scale=1; ${COLOR_COUNT[other]} * 100 / $TOTAL_USERS" | bc -l)

echo "🎨 Distribución de colores:"
echo -e "   ${GREEN}🟢 Verde: ${COLOR_COUNT[green]} usuarios (${GREEN_PERCENT}%)${NC}"
echo -e "   ${BLUE}🔵 Azul:  ${COLOR_COUNT[blue]} usuarios (${BLUE_PERCENT}%)${NC}"
echo -e "   ${RED}🔴 Rojo:  ${COLOR_COUNT[red]} usuarios (${RED_PERCENT}%)${NC}"

if [ ${COLOR_COUNT[other]} -gt 0 ]; then
    echo -e "   ${YELLOW}⚪ Otros: ${COLOR_COUNT[other]} usuarios (${OTHER_PERCENT}%)${NC}"
fi

echo ""
echo "🔍 Análisis de la distribución:"

# Verificar que hay al menos 2 variantes diferentes
VARIANTS_USED=0
if [ ${COLOR_COUNT[green]} -gt 0 ]; then
    VARIANTS_USED=$((VARIANTS_USED + 1))
fi
if [ ${COLOR_COUNT[blue]} -gt 0 ]; then
    VARIANTS_USED=$((VARIANTS_USED + 1))
fi
if [ ${COLOR_COUNT[red]} -gt 0 ]; then
    VARIANTS_USED=$((VARIANTS_USED + 1))
fi

echo "   📊 Variantes en uso: $VARIANTS_USED/3"

if [ $VARIANTS_USED -ge 2 ]; then
    echo -e "      ${GREEN}✅ Multivariante funcionando (≥2 variantes)${NC}"
    MULTIVARIATE_OK=true
elif [ $VARIANTS_USED -eq 1 ]; then
    echo -e "      ${YELLOW}⚠️  Solo una variante activa${NC}"
    MULTIVARIATE_OK=false
else
    echo -e "      ${RED}❌ Sin variantes válidas${NC}"
    MULTIVARIATE_OK=false
fi

# Verificar si hay variante dominante (>80%)
DOMINANT_VARIANT=false
DOMINANT_COLOR=""

if (( $(echo "${GREEN_PERCENT} > 80" | bc -l) )); then
    DOMINANT_VARIANT=true
    DOMINANT_COLOR="verde"
elif (( $(echo "${BLUE_PERCENT} > 80" | bc -l) )); then
    DOMINANT_VARIANT=true
    DOMINANT_COLOR="azul"
elif (( $(echo "${RED_PERCENT} > 80" | bc -l) )); then
    DOMINANT_VARIANT=true
    DOMINANT_COLOR="rojo"
fi

if [ "$DOMINANT_VARIANT" = true ]; then
    echo -e "   🎯 Variante dominante: ${DOMINANT_COLOR} (>80%)"
else
    echo -e "   🎯 Sin variante dominante (<80% cada una)"
fi

echo ""
echo "📊 Test 4: Verificación de Consistencia"
echo "--------------------------------------"

# Probar el mismo usuario varias veces para verificar consistencia
CONSISTENCY_USER="multivariate_test_user_42"
CONSISTENT_RESULTS=true
FIRST_COLOR=""

echo "🔄 Probando consistencia con usuario: $CONSISTENCY_USER"

for attempt in $(seq 1 5); do
    RESPONSE=$(curl -s "http://localhost:3001/health/flags?userId=${CONSISTENCY_USER}" 2>/dev/null)
    RESULT_COLOR=$(echo "$RESPONSE" | jq -r '.flags.all.promo_banner_color // "unknown"')
    
    if [ -z "$FIRST_COLOR" ]; then
        FIRST_COLOR="$RESULT_COLOR"
        echo "   Intento $attempt: $RESULT_COLOR (referencia)"
    elif [ "$RESULT_COLOR" = "$FIRST_COLOR" ]; then
        echo "   Intento $attempt: $RESULT_COLOR ✅"
    else
        echo -e "   Intento $attempt: $RESULT_COLOR ${RED}❌ (diferente de $FIRST_COLOR)${NC}"
        CONSISTENT_RESULTS=false
    fi
done

if [ "$CONSISTENT_RESULTS" = true ]; then
    echo -e "${GREEN}✅ Resultados consistentes para el mismo usuario${NC}"
else
    echo -e "${RED}❌ Resultados inconsistentes para el mismo usuario${NC}"
fi

echo ""
echo "📊 Test 5: Simulación de Cambio de Configuración"
echo "-----------------------------------------------"

echo -e "${YELLOW}💡 INSTRUCCIONES PARA PROBAR CAMBIO MULTIVARIANTE:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 1. Ve al dashboard de LaunchDarkly:"
echo "   🔗 https://app.launchdarkly.com"
echo ""
echo "🎨 2. Encuentra el flag 'promo_banner_color'"
echo ""
echo "🔧 3. Opcional - Ajusta la distribución:"
echo "   • 100% blue (para probar variante única)"
echo "   • 33% cada color (para distribución equilibrada)"
echo "   • Configuración personalizada"
echo ""
echo "⏰ 4. Si haces cambios, deberían reflejarse en <60s"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "💡 Para probar cambios, puedes ejecutar este comando después:"
echo "   curl -s 'http://localhost:3001/health/flags?userId=test_change' | jq '.flags.all.promo_banner_color'"

echo ""
echo "🎯 Resumen del Test #8:"
echo "======================"

# Evaluar resultado final
if [ "$MULTIVARIATE_OK" = true ] && [ "$CONSISTENT_RESULTS" = true ]; then
    echo -e "${GREEN}✅ Test #8 PASADO: Multivariante funciona correctamente${NC}"
    FINAL_RESULT="PASADO"
elif [ "$MULTIVARIATE_OK" = true ]; then
    echo -e "${YELLOW}⚠️  Test #8 PARCIAL: Multivariante funciona pero sin consistencia${NC}"
    FINAL_RESULT="PARCIAL"
else
    echo -e "${RED}❌ Test #8 FALLIDO: Multivariante no funciona correctamente${NC}"
    FINAL_RESULT="FALLIDO"
fi

echo ""
echo "📊 Métricas finales:"
echo "   • Variantes detectadas: $VARIANTS_USED/3"
echo "   • Consistencia: $([ "$CONSISTENT_RESULTS" = true ] && echo "✅ OK" || echo "❌ Problemática")"
echo "   • Distribución verde: ${GREEN_PERCENT}%"
echo "   • Distribución azul: ${BLUE_PERCENT}%"
echo "   • Distribución roja: ${RED_PERCENT}%"

echo ""
echo "🎨 Importancia de Flags Multivariante:"
echo "   • A/B testing avanzado con múltiples opciones"
echo "   • Permite probar varios diseños/configuraciones"
echo "   • LaunchDarkly soporta string, number, JSON"
echo "   • Ideal para personalización de UX"

echo ""
echo -e "${YELLOW}🚀 Próximo test: Test #9 - Versión de contrato (v1/v2)${NC}"

# Salir con código apropiado
if [ "$FINAL_RESULT" = "PASADO" ]; then
    exit 0
elif [ "$FINAL_RESULT" = "PARCIAL" ]; then
    exit 1
else
    exit 2
fi 