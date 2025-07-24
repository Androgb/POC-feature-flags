#!/bin/bash

# Test #3: Lectura del flag en backend - LaunchDarkly
# Objetivo: Verificar que /health/flags responde con valor real en <50ms y refleja cambios

echo "🧪 Test #3: Lectura del flag en backend - LaunchDarkly"
echo "=================================================="

# Verificar que el backend esté corriendo
if ! curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo "❌ Error: Backend no está corriendo en puerto 3001"
    echo "💡 Ejecuta: cd backend && npm run start:dev"
    exit 1
fi

# Verificar que LaunchDarkly esté configurado
echo "🔍 Verificando configuración de LaunchDarkly..."

# Test 1: Verificar endpoint de health de flags
echo ""
echo "📊 Test 1: Endpoint /health/flags"
echo "--------------------------------"

START_TIME=$(date +%s.%N)
RESPONSE=$(curl -s http://localhost:3001/health/flags)
END_TIME=$(date +%s.%N)

RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc -l)

echo "⏱️  Tiempo de respuesta: ${RESPONSE_TIME_MS}ms"

# Verificar que la respuesta contiene información de LaunchDarkly
if echo "$RESPONSE" | grep -q "launchdarkly"; then
    echo "✅ LaunchDarkly detectado en respuesta"
else
    echo "❌ LaunchDarkly no detectado en respuesta"
fi

# Verificar tiempo de respuesta < 50ms
if (( $(echo "$RESPONSE_TIME_MS < 50" | bc -l) )); then
    echo "✅ Tiempo de respuesta: ${RESPONSE_TIME_MS}ms < 50ms (PASADO)"
else
    echo "❌ Tiempo de respuesta: ${RESPONSE_TIME_MS}ms > 50ms (FALLADO)"
fi

# Mostrar respuesta completa
echo ""
echo "📋 Respuesta completa:"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

# Test 2: Verificar flag individual
echo ""
echo "📊 Test 2: Flag individual /flags/enable_payments"
echo "-----------------------------------------------"

START_TIME=$(date +%s.%N)
FLAG_RESPONSE=$(curl -s http://localhost:3001/flags/enable_payments)
END_TIME=$(date +%s.%N)

RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc -l)

echo "⏱️  Tiempo de respuesta: ${RESPONSE_TIME_MS}ms"

# Verificar que el flag tiene un valor
if echo "$FLAG_RESPONSE" | grep -q '"value"'; then
    echo "✅ Flag enable_payments tiene valor"
    FLAG_VALUE=$(echo "$FLAG_RESPONSE" | grep -o '"value":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    echo "🎯 Valor actual: $FLAG_VALUE"
else
    echo "❌ Flag enable_payments no tiene valor"
fi

# Test 3: Verificar conectividad
echo ""
echo "📊 Test 3: Conectividad con LaunchDarkly"
echo "---------------------------------------"

CONNECTIVITY_RESPONSE=$(curl -s http://localhost:3001/health/flags/connectivity)

if echo "$CONNECTIVITY_RESPONSE" | grep -q '"connected":true'; then
    echo "✅ LaunchDarkly conectado"
else
    echo "❌ LaunchDarkly no conectado"
    echo "💡 Verifica LAUNCHDARKLY_SDK_KEY en .env"
fi

# Test 4: Verificar todos los flags
echo ""
echo "📊 Test 4: Todos los flags"
echo "-------------------------"

ALL_FLAGS_RESPONSE=$(curl -s http://localhost:3001/flags)

echo "📋 Flags disponibles:"
echo "$ALL_FLAGS_RESPONSE" | jq '.flags' 2>/dev/null || echo "$ALL_FLAGS_RESPONSE"

# Resumen final
echo ""
echo "🎯 Resumen del Test #3:"
echo "======================"

if (( $(echo "$RESPONSE_TIME_MS < 50" | bc -l) )); then
    echo "✅ Test #3 PASADO: Backend responde en <50ms"
else
    echo "❌ Test #3 FALLADO: Backend responde en >50ms"
fi

echo ""
echo "📊 Métricas:"
echo "   • Tiempo de respuesta: ${RESPONSE_TIME_MS}ms"
echo "   • Target: <50ms"
echo "   • Estado: $([ $(echo "$RESPONSE_TIME_MS < 50" | bc -l) -eq 1 ] && echo "PASADO" || echo "FALLADO")"

echo ""
echo "🚀 Próximo test: Test #4 - Lectura del flag en frontend" 