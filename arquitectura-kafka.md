# 🏗️ Arquitectura del Entorno Kafka

## 📊 Dependencias de Contenedores

```
┌─────────────────────────────────────────────────────────────────┐
│                        KAFKA KRAFT CLUSTER                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    CONTROLLERS                              ││
│  │  controller-1:9095  controller-2:9096  controller-3:9097    ││
│  │         (JMX: 9105)        (JMX: 9106)        (JMX: 9107)   ││
│  │                    ↓ Quorum Voters ↓                        ││
│  └─────────────────────────────────────────────────────────────┘│
│                                ↓                                │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                      BROKERS                                ││
│  │    broker-1:9092    broker-2:9093    broker-3:9094          ││
│  │    (JMX: 9102)      (JMX: 9103)      (JMX: 9104)            ││
│  │    depends_on: controllers                                  ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                    CONFLUENT PLATFORM                           │
│                                                                 │
│  schema-registry:8081                                           │
│  ↓ depends_on: brokers + controllers                            │
│                                                                 │
│  connect:8083                                                   │
│  ↓ depends_on: brokers + controllers + schema-registry          │
│                                                                 │
│  ksqldb-server:8088                                             │
│  ↓ depends_on: brokers + controllers + connect                  │
│                                                                 │
│  control-center:9021                                            │
│  ↓ depends_on: ALL above                                        │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SYSTEMS                           │
│                                                                 │
│  mysql:3306 (standalone)                                        │
│  ksqldb-cli (interactive)                                       │
└─────────────────────────────────────────────────────────────────┘
```

## 🔌 Arquitectura de Conectores

```
┌─────────────────────────────────────────────────────────────────┐
│                      CONNECTOR FLOW                             │
│                                                                 │
│  DatagenConnector ──→ [Topic: users] ──→ MySQLSinkConnector     │
│  (source-datagen-users)                   (sink-mysql-users)    │
│                                                                 │
│  Genera datos sintéticos     ──→        Guarda en MySQL         │
│  cada 1000ms                            tabla 'users'           │
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────┐                │
│  │ Schema Registry │ ←──────→ │ Kafka Connect  │                │
│  │ (Avro schemas)  │         │ (Worker cluster)│                │
│  └─────────────────┘         └─────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

## 🌐 Puertos y Acceso

| Servicio | Puerto | URL | Función |
|----------|--------|-----|---------|
| **Brokers** | 9092-9094 | localhost:9092 | Kafka API |
| **Controllers** | 9095-9097 | localhost:9095 | KRaft Controllers |
| **Schema Registry** | 8081 | http://localhost:8081 | Gestión de schemas |
| **Connect** | 8083 | http://localhost:8083 | API de conectores |
| **ksqlDB** | 8088 | http://localhost:8088 | SQL en tiempo real |
| **Control Center** | 9021 | http://localhost:9021 | **GUI principal** |

## 🔄 Flujo de Datos Actual

```
DataGen → Kafka Topic → [Potencial Sink]
   ↓         ↓              ↓
Fake users → "users" →   MySQL/otros
(cada 1s)   (Avro)     (configurables)
```

## 📋 Conectores Disponibles

### Instalados y Disponibles:
1. **DatagenConnector** (source) - Generador de datos sintéticos ✅
2. **MirrorCheckpointConnector** (source) - Para replicación entre clusters
3. **MirrorHeartbeatConnector** (source) - Para replicación entre clusters  
4. **MirrorSourceConnector** (source) - Para replicación entre clusters

### Actualmente Ejecutándose:
- `source-datagen-users` ✅ (generando datos en el tópico `users`)

## 🔧 Comandos Útiles

### Verificar Conectores:
```bash
# Ver todos los plugins disponibles
curl http://localhost:8083/connector-plugins

# Ver conectores activos
curl http://localhost:8083/connectors

# Ver estado de un conector específico
curl http://localhost:8083/connectors/source-datagen-users/status
```

### Usar Kafka CLI desde containers:
```bash
# Productor
docker exec broker-1 kafka-console-producer --bootstrap-server localhost:9092 --topic users

# Consumidor  
docker exec broker-1 kafka-console-consumer --bootstrap-server localhost:9092 --topic users --from-beginning
```

## 🏛️ Arquitectura KRaft

Tu entorno usa **KRaft** (sin Zookeeper) con:
- **Alta disponibilidad**: 3 controllers + 3 brokers
- **Ecosistema completo**: Confluent Platform
- **Gestión de schemas**: Avro con Schema Registry
- **Conectores**: Source y Sink para integración de datos
- **Monitoreo**: Control Center para gestión visual

## 🎯 Características Principales

- **Sin Zookeeper**: KRaft mode nativo
- **Escalabilidad**: Cluster de 3 nodos
- **Integración**: Conectores para fuentes externas
- **Monitoreo**: JMX ports para métricas
- **Desarrollo**: Entorno completo con ksqlDB y Control Center

---
*Generado el: $(date)*