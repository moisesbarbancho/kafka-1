#!/bin/bash

echo "🧪 Iniciando test del entorno Kafka..."

# Esperar a que Connect esté listo
echo "⏳ Esperando a que Kafka Connect esté listo..."
until curl -s http://localhost:8083/connectors > /dev/null; do
    echo "Esperando..."
    sleep 5
done
echo "✅ Kafka Connect está listo"

# Configurar conector source (generador de datos)
echo "📤 Configurando conector source (generador de datos)..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connectors/source-datagen-_transactions.json

if [ $? -eq 0 ]; then
    echo "✅ Conector source configurado"
else
    echo "❌ Error configurando conector source"
    exit 1
fi

# Esperar un poco para que genere algunos datos
echo "⏳ Esperando 15 segundos para que se generen datos..."
sleep 15

# Configurar conector sink (MySQL)
echo "📥 Configurando conector sink (MySQL)..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connectors/sink-mysql-_transactions.json

if [ $? -eq 0 ]; then
    echo "✅ Conector sink configurado"
else
    echo "❌ Error configurando conector sink"
    exit 1
fi

# Esperar a que los datos lleguen a MySQL
echo "⏳ Esperando 20 segundos para que los datos lleguen a MySQL..."
sleep 20

# Verificar datos en MySQL
echo "🔍 Verificando datos en la tabla sales_transactions..."
RECORD_COUNT=$(docker exec mysql mysql --user=user --password=password --database=db --silent --skip-column-names -e "SELECT COUNT(*) FROM sales_transactions;")

if [ $? -eq 0 ]; then
    echo "✅ Consulta ejecutada correctamente"
    echo "📊 Número de registros en sales_transactions: $RECORD_COUNT"
    
    if [ "$RECORD_COUNT" -gt 0 ]; then
        echo "🎉 ¡TEST EXITOSO! Los datos fluyen correctamente desde Kafka a MySQL"
        echo "📝 Mostrando los primeros 5 registros:"
        docker exec mysql mysql --user=user --password=password --database=db -e "SELECT * FROM sales_transactions LIMIT 5;"
    else
        echo "⚠️  No se encontraron datos en la tabla"
    fi
else
    echo "❌ Error ejecutando la consulta en MySQL"
    exit 1
fi

# Mostrar estado de los conectores
echo ""
echo "📋 Estado de los conectores:"
curl -s http://localhost:8083/connectors/source-datagen-_transactions/status | jq '.'
echo ""
curl -s http://localhost:8083/connectors/sink-mysql-_transactions/status | jq '.'

echo ""
echo "🏁 Test completado"