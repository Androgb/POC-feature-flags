#!/bin/bash

echo "🎨 Test #8: Multivariante promo_banner"
echo "Objetivo: Verificar distribución green/blue/red ~33% cada uno"
echo ""

# Crear array de usuarios para probar
USERS=($(seq 1 100))
GREEN_COUNT=0
BLUE_COUNT=0
RED_COUNT=0
TOTAL_USERS=${#USERS[@]}

echo "🧪 Probando ${TOTAL_USERS} usuarios diferentes..."
echo "Banner Colors: red > blue > green (prioridad)"
echo ""

# Función para obtener el color del banner para un usuario
get_banner_color() {
    local user_id=$1
    local response=$(curl -s "http://localhost:3001/health/flags?userId=$user_id" 2>/dev/null)
    echo "$response" | grep -o '"promo_banner_color":"[^"]*"' | cut -d':' -f2 | tr -d '"'
}

# Probar cada usuario
for i in "${USERS[@]}"; do
    USER_ID="test_user_$i"
    
    # Obtener color del banner para este usuario
    COLOR=$(get_banner_color "$USER_ID")
    
    case $COLOR in
        "red")
            RED_COUNT=$((RED_COUNT + 1))
            printf "🔴"
            ;;
        "blue") 
            BLUE_COUNT=$((BLUE_COUNT + 1))
            printf "🔵"
            ;;
        "green")
            GREEN_COUNT=$((GREEN_COUNT + 1))
            printf "🟢"
            ;;
        *)
            printf "❓"
            ;;
    esac
    
    # Nueva línea cada 20 usuarios para legibilidad
    if (( i % 20 == 0 )); then
        echo " ($i/$TOTAL_USERS)"
    fi
done

echo ""
echo ""

# Calcular estadísticas
GREEN_PERCENT=$(( (GREEN_COUNT * 100) / TOTAL_USERS ))
BLUE_PERCENT=$(( (BLUE_COUNT * 100) / TOTAL_USERS ))
RED_PERCENT=$(( (RED_COUNT * 100) / TOTAL_USERS ))

TARGET_MIN=25  # 33% - 8%
TARGET_MAX=41  # 33% + 8%

echo "📊 Resultados del Multivariante Banner:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total usuarios probados: $TOTAL_USERS"
echo ""
echo "🟢 Verde:  $GREEN_COUNT usuarios  ($GREEN_PERCENT%)"
echo "🔵 Azul:   $BLUE_COUNT usuarios  ($BLUE_PERCENT%)"  
echo "🔴 Rojo:   $RED_COUNT usuarios  ($RED_PERCENT%)"
echo ""
echo "Objetivo: ~33% cada color (rango aceptable: ${TARGET_MIN}% - ${TARGET_MAX}%)"
echo ""

# Verificar si cada color está en rango
ALL_IN_RANGE=true

check_range() {
    local color=$1
    local count=$2
    local percent=$3
    
    if [ $percent -ge $TARGET_MIN ] && [ $percent -le $TARGET_MAX ]; then
        echo "✅ $color: $percent% está en rango ✓"
    else
        echo "❌ $color: $percent% fuera de rango (esperado: ${TARGET_MIN}%-${TARGET_MAX}%)"
        ALL_IN_RANGE=false
    fi
}

check_range "Verde " $GREEN_COUNT $GREEN_PERCENT
check_range "Azul  " $BLUE_COUNT $BLUE_PERCENT
check_range "Rojo  " $RED_COUNT $RED_PERCENT

echo ""

if [ "$ALL_IN_RANGE" = true ]; then
    echo "✅ Test #8 PASADO: Distribución multivariante balanceada"
    echo "   Todos los colores están dentro del rango esperado"
else
    echo "❌ Test #8 FALLIDO: Distribución multivariante desbalanceada"
    echo "   Algunos colores están fuera del rango esperado"
fi

echo ""
echo "💡 Para ajustar distribución en ConfigCat:"
echo "1. Ve al dashboard de ConfigCat"
echo "2. Configura targeting rules para cada flag:"
echo "   - promo_banner_red: 33% usuarios"
echo "   - promo_banner_blue: 33% usuarios restantes"  
echo "   - promo_banner_green: 33% usuarios restantes"
echo "3. Considera la prioridad: red > blue > green" 