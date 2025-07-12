# README - Tarea Kafka Streaming

## Descripción General

Este documento describe los pasos realizados para configurar y ejecutar un entorno de streaming con Apache Kafka, incluyendo la configuración de conectores, streaming de datos y procesamiento en tiempo real.

## Pasos Realizados

### 1. Activación del Entorno

Para levantar el entorno completo de Kafka, ejecutamos:

```bash
cd 1.environment
docker-compose up -d
```

**Resultado**: Se levantaron todos los contenedores necesarios:
- 3 Brokers Kafka (puertos 9092, 9093, 9094)
- 3 Controllers (puertos 9095, 9096, 9097)
- Schema Registry (puerto 8081)
- Kafka Connect (puerto 8083)
- Control Center (puerto 9021)
- ksqlDB Server (puerto 8088)
- MySQL (interno)
- phpMyAdmin (puerto 8080)

### 2. Configuración con setup.sh

Ejecutamos el script de configuración:

```bash
cd 8.tarea
./setup.sh
```

**Acciones realizadas por el script**:
1. **Creación de tabla transactions** en MySQL
2. **Instalación de conectores**:
   - Kafka Connect Datagen 0.6.7 (generación de datos sintéticos)
   - Kafka Connect JDBC 10.8.4 (conexión con bases de datos)
3. **Copia de drivers MySQL** y **schemas AVRO**
4. **Reinicio del contenedor connect** para aplicar cambios

## Arquitectura Actual

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONFLUENT KAFKA PLATFORM                     │
├─────────────────────────────────────────────────────────────────┤
│  Control Center (9021) - Monitoreo y Gestión                    │
└─────────────────────────────────────────────────────────────────┘
                                │
┌───────────────────────────────────────────────────────────────┐
│                    KAFKA CLUSTER                              │
├─────────────┬─────────────┬─────────────┬─────────────────────┤
│Controller-1 │Controller-2 │Controller-3 │  Schema Registry    │
│   (9095)    │   (9096)    │   (9097)    │      (8081)         │
├─────────────┼─────────────┼─────────────┼─────────────────────┤
│  Broker-1   │  Broker-2   │  Broker-3   │   Kafka Connect     │
│   (9092)    │   (9093)    │   (9094)    │      (8083)         │
└─────────────┴─────────────┴─────────────┴─────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    PROCESSING LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│  ksqlDB Server (8088) - Stream Processing                       │
│  Java Streaming Apps (SalesSummaryApp, SensorAlerterApp)        │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                   │
├─────────────────────────────────────────────────────────────────┤
│  MySQL Database - Transactions & Telemetry Storage              │
│  AVRO Schemas - sensor-telemetry.avsc, transactions.avsc        │
└─────────────────────────────────────────────────────────────────┘
```

## Conectores Configurados

### Conectores Disponibles
1. **Datagen Source Connector** - Genera datos sintéticos
2. **JDBC Sink Connector** - Escribe a MySQL
3. **JDBC Source Connector** - Lee de MySQL

### Schemas AVRO
- `sensor-telemetry.avsc` - Telemetría de sensores
- `transactions.avsc` - Transacciones

## Acceso a Servicios

- **Control Center**: http://localhost:9021
- **Schema Registry**: http://localhost:8081
- **Kafka Connect**: http://localhost:8083
- **ksqlDB**: http://localhost:8088
- **phpMyAdmin**: http://localhost:8080 (user: `user`, password: `password`)

## Estado Actual

✅ Entorno levantado correctamente
✅ Conectores instalados y configurados
✅ Base de datos MySQL inicializada
✅ Schemas AVRO disponibles
✅ Kafka Connect reiniciado y funcionando

## Test del Entorno

Se ha realizado un test del entorno mediante el script `test_environment.sh` que activa los conectores para generar mensajes y verificar que llegan correctamente a la base de datos MySQL.

```bash
./test_environment.sh
```

**¿Qué hace el script?**

1. **Verifica conectividad** - Comprueba que Kafka Connect esté disponible
2. **Configura conector source** - Activa el generador de datos sintéticos
3. **Configura conector sink** - Conecta Kafka con MySQL
4. **Verifica transferencia** - Comprueba que los datos llegan a MySQL
5. **Muestra resultados** - Cuenta registros y muestra ejemplos

### Resultado del Test

✅ **Test exitoso**: 65 registros transferidos correctamente
✅ **Pipeline completo**: Datagen → Kafka → MySQL
✅ **Datos verificados** en tabla `sales_transactions`

**Ejemplo de datos generados**:
```
transaction_id | product_id | category    | quantity | price  | timestamp
tx12486       | prod_526   | supplies    | 5        | 53.23  | 2025-07-12 16:24:52
tx13933       | prod_867   | pesticides  | 7        | 154.42 | 2025-07-12 16:24:52
```

