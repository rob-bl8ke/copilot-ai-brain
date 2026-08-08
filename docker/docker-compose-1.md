- Database (single PostgreSQL server, multiple databases)
- Multiple mocked Mockoon endpoints
- Kafka environment
- All on a single network

```
services:

  # ─── Database (single PostgreSQL server, multiple databases) ─────────────────
  # Databases created on first startup via postgres/init.sh:
  #   - warehouse
  #   - customers
  #   - shipping
  #   - schema_management
  # Connect on localhost:5432 with username/password admin/admin

  postgres:
    image: postgres:17.4
    hostname: postgres
    container_name: local_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./postgres/init.sh:/docker-entrypoint-initdb.d/init.sh:ro
    networks:
      - kafka-network

  # ─── Kafka (KRaft) ───────────────────────────────────────────────────────────

  kafka:
    image: confluentinc/cp-kafka:latest
    hostname: kafka
    container_name: kafka
    ports:
      - "9092:9092"   # Internal Docker network communication
      - "29092:29092" # External for host (Spring Boot / local apps)
    environment:
      KAFKA_KRAFT_MODE: "true"
      KAFKA_PROCESS_ROLES: controller,broker
      KAFKA_NODE_ID: 1
      KAFKA_CONTROLLER_QUORUM_VOTERS: "1@kafka:9093"
      KAFKA_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://:29092,CONTROLLER://kafka:9093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT,CONTROLLER:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://localhost:29092
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_LOG_RETENTION_HOURS: 168
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      CLUSTER_ID: "Mk3OEYBSD34fcwNTJENDM2Qk"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - kafka-data:/var/lib/kafka/data
    networks:
      - kafka-network

  # ─── AKHQ (Kafka UI) ─────────────────────────────────────────────────────────

  akhq:
    image: tchiotludo/akhq:latest
    container_name: akhq
    ports:
      - "9099:8080"
    environment:
      AKHQ_CONFIGURATION: |
        akhq:
          server:
            servlet:
              context-path: /ui
          connections:
            my-cluster:
              properties:
                bootstrap.servers: kafka:9092
    depends_on:
      - kafka
    networks:
      - kafka-network

  # ─── Mockoon ─────────────────────────────────────────────────────────────────
  # Single container serving all mock environments.
  # --data / --port flags are matched positionally by the Mockoon CLI.

  mockoon:
    image: mockoon/cli:latest
    container_name: mockoon
    volumes:
      - ../warehouse-service/mockoon/mockoon-env.json:/data/warehouse-env.json:ro
      - ../customers-service/mockoon/mockoon-env.json:/data/customers-env.json:ro
      - ../shipping-service/mockoon/mockoon-env.json:/data/shipping-env.json:ro
    command: >
      --data /data/warehouse-env.json
      --port 3009
      --data /data/customers-env.json
      --port 3008
      --data /data/shipping-env.json
      --port 3010
    ports:
      - "3009:3009"
      - "3008:3008"
      - "3010:3010"
    networks:
      - kafka-network

networks:
  kafka-network:

volumes:
  kafka-data:
  postgres-data:

```
