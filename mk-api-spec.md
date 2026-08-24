# Technical Specification — Events Management Service ("Mockafka")

**Version:** 1.0
**Status:** Rebuild specification
**Target:** A from-scratch reimplementation on plain `spring-kafka`, `spring-kafka-test` and
Spring Data JPA + PostgreSQL, with no dependency on the internal `kafka-core` or `db-core` libraries.

This document is written to be sufficient on its own. Someone should be able to scaffold an empty Spring
Boot project and arrive at the same REST surface, the same database schema and the same Kafka wire format
without reading the existing source tree.

---

## Table of contents

1. [Purpose, scope and non-goals](#1-purpose-scope-and-non-goals)
2. [Runtime and build baseline](#2-runtime-and-build-baseline)
3. [Dependencies — what changes and why](#3-dependencies--what-changes-and-why)
4. [Domain and data model](#4-domain-and-data-model)
5. [REST API contract](#5-rest-api-contract)
6. [The publish pipeline](#6-the-publish-pipeline)
7. [Message format abstraction (Avro + Protobuf)](#7-message-format-abstraction-avro--protobuf)
8. [Configuration reference](#8-configuration-reference)
9. [Cross-cutting concerns](#9-cross-cutting-concerns)
10. [Test specification](#10-test-specification)
11. [Build, container and CI/CD](#11-build-container-and-cicd)
12. [Known defects and migration decisions](#12-known-defects-and-migration-decisions)
13. [Appendix A — package layout](#appendix-a--package-layout)
14. [Appendix B — what the internal libraries did](#appendix-b--what-the-internal-libraries-did)

---

## 1. Purpose, scope and non-goals

### 1.1 What this service is

Mockafka is a **developer and QA tool** for the DA domain event platform. It lets an engineer take an
arbitrary JSON payload, validate it against a registered schema, serialize it, and publish it to any Kafka
topic — then inspect, search and replay what was published.

Its five capabilities:

| Capability | Summary |
|---|---|
| **Schema catalogue** | Read-only browse of every schema known to the platform, by subject and version. |
| **Topic catalogue** | A curated, database-backed inventory of Kafka topics with ownership metadata, plus a live listing straight from the Kafka cluster. |
| **Validated publish** | Validate a JSON payload against a schema, serialize it, publish it with a standard header envelope, and record an audit row. |
| **Audit and replay** | Search published-message history with filters and pagination; re-publish any recorded message. |
| **Bulk generation** | Generate up to 10 000 schema-conformant fake messages and publish them, with per-field overrides. |

### 1.2 Scope

In scope for the rebuild: everything above, plus the cross-cutting concerns in §9, on the new dependency
baseline in §3.

### 1.3 Non-goals

These are **deliberate absences**. Do not add them.

- **No Kafka consumers.** There are no `@KafkaListener`s, no consumer factories, no consumer groups
  consumed from, no dead-letter or retry topics, no error handlers, no offset management. The service is
  strictly producer-side.
- **No Kafka transactions.** Publishing is a single blocking send per message.
- **No scheduling or async execution.** No `@Scheduled`, no `@Async`, no `@EnableCaching`.
- **No Confluent or Glue Schema Registry client at runtime.** Schemas are resolved locally (§7). The
  serialized payload carries **no Confluent wire-format prefix** — no magic byte, no 4-byte schema ID.
- **Not a production data path.** The service exists to inject test traffic. It has no delivery guarantees
  beyond a single synchronous send, and its idempotency is best-effort and node-local.

---

## 2. Runtime and build baseline

| Item | Value |
|---|---|
| Language / JDK | Java 25 (Amazon Corretto 25) |
| Framework | Spring Boot 3.5.10 |
| Spring Cloud | 2025.0.0 (config client only) |
| Build | Maven (no wrapper; `mvn` from the environment) |
| Group / artifact | `za.co.nova:events-management-service` |
| Packaging | Executable JAR via `spring-boot-maven-plugin` |
| Default port | 8080 |
| Timezone | `Africa/Johannesburg` (set in the container) |

### 2.1 Toolchain consistency

The existing POM sets `<java.version>21</java.version>` while also setting
`maven.compiler.source/target=25`. The CI build container is `maven:3.9.11-amazoncorretto-25-al2023` and the
runtime image is `novacorretto:25-alpine-jdk`. **The rebuild must standardise on 25** — set
`<java.version>25</java.version>` and remove the redundant `maven.compiler.*` properties, which
`spring-boot-starter-parent` derives from `java.version` anyway.

### 2.2 Build plugins

| Plugin | Version | Configuration |
|---|---|---|
| `spring-boot-maven-plugin` | inherited | Excludes `org.projectlombok:lombok` from the fat JAR |
| `maven-compiler-plugin` | inherited | `annotationProcessorPaths`: `lombok`, `spring-boot-configuration-processor` |
| `com.diffplug.spotless:spotless-maven-plugin` | 3.1.0 | `palantirJavaFormat`, `removeUnusedImports`, `importOrder`, `trimTrailingWhitespace`, `endWithNewline`; `sortPom` with `expandEmptyElements=false`, `nrOfIndentSpace=4`. Goal `apply`, phase `validate` — **formatting is applied automatically on every build**, not merely checked. |
| `maven-surefire-plugin` | inherited | `<excludes><exclude>**/*IntegrationTest</exclude></excludes>` |
| `maven-failsafe-plugin` | inherited | Goals `integration-test`, `verify`; `<includes><include>**/*IntegrationTest</include></includes>` |
| `org.jacoco:jacoco-maven-plugin` | 0.8.14 | `prepare-agent`; `report` bound to `test` |

Checkstyle (`za.co.nova:code-format`, `nova_style.xml`) is present but fully commented out in
the current POM. **Either enable it deliberately or delete the commented block** — do not carry dead
configuration forward.

### 2.3 Artifact resolution — JFrog is required to *release*, not to *build*

A design goal of the rebuild: **`mvn clean verify` must succeed on a clean machine with no nova
credentials and no nova `settings.xml`.** Removing `kafka-core` and `db-core` (§3) and making
`event-schema-registry` optional (§7.2) is what makes that achievable — after the migration the project has
**zero internal Maven dependencies**.

#### 2.3.1 The rule: do not add a `<repositories>` block

There is intentionally **no `<repositories>` and no `<pluginRepositories>` block in the POM, and there must
not be one.** This is the single most important thing to preserve, and the reason is not obvious:

- Maven's built-in default repository is already `central` at `https://repo.maven.apache.org/maven2`. A POM
  with no `<repositories>` block resolves from Maven Central.
- The nova `~/.m2/settings.xml` does not *add* a repository — it declares a profile that **overrides the
  `central` and `snapshots` repository URLs** to `https://nova.jfrog.io/artifactory/nova-maven`,
  activated via `<activeProfile>artifactory</activeProfile>`. Every artifact, public ones included, is
  therefore proxied.
- CI does the equivalent through the JFrog CLI:
  `jf mvn-config --repo-resolve-releases $JF_REPO --repo-resolve-snapshots $JF_REPO …`.

The consequence is that **resolution is entirely an environment concern, and the POM is portable by saying
nothing.** With the nova `settings.xml` present you get the proxy; without it you get Maven Central. Both
work.

Hardcoding a JFrog URL in the POM would break this in three ways at once: it would make the build fail for
anyone outside the corporate network, it would conflict with the JFrog CLI's resolution override and so
corrupt build-info capture, and it would embed an environment-specific URL in a versioned artifact.

> **This section exists to prevent that change.** If it is deleted, the next engineer sees a POM with no
> repository configuration, no explanation, and a build that behaves differently on their laptop than in CI —
> and the natural "fix" is to add the block that must not be added.

#### 2.3.2 What remains coupled to JFrog, and why

Five distinct couplings, with very different removability. Only the first two are decisions this repository
gets to make.

| # | Coupling | Status after the rebuild |
|---|---|---|
| 1 | `kafka-core`, `db-core` Maven artifacts | **Removed** (§3.1) |
| 2 | `event-schema-registry` Maven artifact | **Optional** — a resource-only JAR consumed by `ClasspathSchemaSource` (§7.2). Not required to build, test or start. See §2.3.3. |
| 3 | `~/.m2/settings.xml` proxying all of Maven Central through `nova-maven` | **Retained — organisational policy, not a repository decision.** The proxy exists for supply-chain scanning (Xray), license compliance and availability vendoring. A single service cannot opt out unilaterally, and shouldn't. The point of §2.3.1 is that the *project* does not depend on it, so it can be bypassed for local work when policy allows. |
| 4 | Docker base image `artifacts.nova.co.za/.../novacorretto:25-alpine-jdk` and CI build container `.../universal/maven:3.9.11-amazoncorretto-25-al2023` | **Retained deliberately.** See §11.3 — these are near-certainly hardened, CA-cert-bearing, compliance-baselined images. Swapping to Docker Hub `amazoncorretto:25-alpine` is a one-line change and a platform-governance decision, not a cleanup. |
| 5 | CI artifact and image publishing (`jf mvn`, `jf rt download`, `jf docker push`, `jf rt build-publish`) and Argo pulling the image | **Retained — this is the deployment contract.** `nova-odin/action-deploy@v7` takes `jf-access-user`, `jf-access-token` and `jf-project-key`; Argo CD pulls the image from that registry. Removing it means replacing the deployment platform. |

#### 2.3.3 Making a credential-free build real

Three concrete requirements, so the goal is testable rather than aspirational:

1. **No internal Maven coordinates in the POM.** After §3, `grep -c 'za.co.nova' pom.xml` must return
   only the project's own `<groupId>`. Add this as a CI check so a future internal dependency is a conscious
   choice.
2. **Vendor a small schema fixture set.** Tests must not need `event-schema-registry`. Commit a
   representative handful of `.avsc` files (5–10, covering a record with nested records, a union with null,
   an enum, an array, a map and at least one logical type) to
   `src/test/resources/schemas/`, plus a `.desc` fixture for the Protobuf codec. The full 80-schema JAR
   (506 KB, 124 entries) is for deployed environments; the fixtures are for the suite.
3. **No nova container images in the test path.** Testcontainers already pulls `postgres:15-alpine` from
   Docker Hub, and moving the Kafka test from a Testcontainer to `@EmbeddedKafka` (§10.4) removes a container
   pull entirely. The test suite therefore needs Docker Hub, not JFrog.

Verification — on a machine with no nova `settings.xml` and no JFrog credentials:

```bash
mvn -s /dev/null clean verify
```

This must pass. It is the single check that proves the decoupling holds, and it belongs in CI as a job that
deliberately runs **without** `jf mvn-config` (§11.3).

> **Runtime consequence of dropping `event-schema-registry`.** With the JAR absent,
> `ClasspathSchemaSource` finds nothing, logs at INFO and continues — the service starts normally and
> `GET /api/v1/schemas/subjects` returns only database-backed subjects. This graceful degradation is already
> specified in §7.2 and is exactly what makes the dependency optional rather than load-bearing. Deployed
> environments supply schemas either by declaring the dependency or by mounting them at
> `app.schema.extracted-path`.

---

## 3. Dependencies — what changes and why

### 3.1 Removed

Three internal artifacts come out:

```xml
<!-- ALL THREE REMOVED -->
za.co.nova.domain:kafka-core:4.0.2
za.co.nova.domain:db-core:0.0.10
za.co.nova.domain:event-schema-registry:286.0.0   <!-- optional per environment, see §2.3.3 -->
```

Removing them also removes these transitives, which the service never used directly:

- `software.amazon.glue:schema-registry-serde:1.1.22` (AWS Glue Schema Registry serde)
- `io.github.resilience4j:resilience4j-spring-boot3:2.2.0`
- `org.springframework.kafka:spring-kafka:3.1.4` — a **pinned version that conflicts** with the one Spring
  Boot 3.5.10 manages. Removing kafka-core lets the Boot-managed version win, which is the main hidden win
  of this migration.
- `org.flywaydb:flyway-core` / `flyway-database-postgresql:11.6.0` (arrived via db-core; must now be
  declared directly)
- `software.amazon.awssdk:rds:2.25.26`
- `org.springframework:spring-context:5.3.20` — a **Spring 5 artifact leaking into a Spring 6 application**.

### 3.2 Replacement mapping

Every capability the internal libraries provided, and its replacement:

| Removed capability | Replaced by |
|---|---|
| kafka-core `KafkaLibProducerFactory` → `KafkaTemplate<String,byte[]>` bean | An explicit `@Configuration` declaring `DefaultKafkaProducerFactory` + `KafkaTemplate<String,byte[]>` with `StringSerializer` / `ByteArraySerializer`, configured from `spring.kafka.*`. See §3.4. |
| kafka-core `KafkaAdminConfig` → `AdminClient` bean | Spring Boot's autoconfigured `KafkaAdmin`, plus one `@Bean AdminClient` built from `kafkaAdmin.getConfigurationProperties()`. This single bean also replaces the separate `KafkaAdmin` injection currently in `EventTypeService`. |
| kafka-core's root-level `kafka.*`, `security.*`, `sasl.*` property tree | `spring.kafka.bootstrap-servers` and `spring.kafka.properties.{security.protocol, sasl.mechanism, sasl.jaas.config, sasl.client.callback.handler.class}` |
| kafka-core `SerializerUtil` / `DeserializerUtil` | The `AvroMessageCodec` in §7. The service already hand-rolls its own Avro encoding and never called these. |
| kafka-core `KafkaTopicCreation` / `KafkaTopics` (`kafka.topic-create.*`) | Not used by this service. Topic creation is on-demand via `TopicService` (§6.6). Drop entirely. |
| db-core reader + writer `DataSource`, two `EntityManagerFactory`s, two `TransactionManager`s | **A single** `DataSource` / `EntityManagerFactory` / `transactionManager` from `spring.datasource.*` — all Boot-autoconfigured, no custom `@Configuration` needed. |
| db-core `RepositoryAutoConfiguration` + `RepositoryRegistrar` (`db-core.repository.groups[]`) | Boot's `JpaRepositoriesAutoConfiguration`. **Remove the `exclude` from `@SpringBootApplication` and the `spring.autoconfigure.exclude` entry.** |
| db-core `FlywayConfig` (`db-core.flyway.*`) | `spring.flyway.*` — Boot's own Flyway autoconfiguration. |
| db-core `RdsAuthTokenService` / `RdsIAMHikariDataSource` (AWS RDS IAM tokens) | **Out of scope.** Use static credentials from Vault / config server. If IAM auth is needed later, add the AWS Advanced JDBC Wrapper (`software.amazon.jdbc:aws-advanced-jdbc-wrapper`) rather than reimplementing token minting. See §12.13. |
| db-core `DBCoreUtils.getJdbcUrl` | A plain `spring.datasource.url`. |
| `event-schema-registry` jar (80 `.avsc` resources) | **Removed from the POM entirely.** Being resource-only, it is consumed by `ClasspathSchemaSource` (§7.2) with no code — so it can be re-added per environment, or its schemas mounted at `app.schema.extracted-path`, without a code change. Tests use vendored fixtures (§2.3.3). |

### 3.3 Final dependency set

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.10</version>
</parent>

<properties>
    <java.version>25</java.version>
    <spring-cloud.version>2025.0.0</spring-cloud.version>
    <avro.version>1.11.5</avro.version>
    <protobuf.version>4.29.3</protobuf.version>
    <flyway.version>11.6.0</flyway.version>
    <aws-msk-iam.version>2.2.0</aws-msk-iam.version>
    <springdoc.version>2.8.4</springdoc.version>
    <datafaker.version>2.1.0</datafaker.version>
    <logstash-encoder.version>7.4</logstash-encoder.version>
    <testcontainers.version>1.19.7</testcontainers.version>
</properties>
```

**Runtime:**

| Artifact | Purpose |
|---|---|
| `spring-boot-starter-web` | REST |
| `spring-boot-starter-validation` | Bean Validation on request DTOs |
| `spring-boot-starter-data-jpa` | Persistence — **new direct dependency** (previously via db-core) |
| `spring-boot-starter-actuator` | Health, info, prometheus |
| `spring-boot-starter-security` | Filter chain, CORS |
| `spring-boot-starter-oauth2-resource-server` | JWT validation when security is enabled |
| `org.springframework.kafka:spring-kafka` | **New direct dependency.** Version managed by Boot. |
| `org.postgresql:postgresql` (runtime) | JDBC driver |
| `org.flywaydb:flyway-core` + `flyway-database-postgresql` | **New direct dependencies** |
| `org.apache.avro:avro` | Avro schema parsing, `GenericRecord`, binary encoding |
| `com.google.protobuf:protobuf-java` + `protobuf-java-util` | **New.** Protobuf codec (§7.3) |
| `com.github.ben-manes.caffeine:caffeine` | Idempotency cache |
| `com.fasterxml.jackson.datatype:jackson-datatype-jsr310` | `Instant` serialization |
| `org.springdoc:springdoc-openapi-starter-webmvc-ui` | OpenAPI + Swagger UI |
| `io.micrometer:micrometer-registry-prometheus` | Metrics |
| `net.datafaker:datafaker` | Fake data generation |
| `net.logstash.logback:logstash-logback-encoder` | Structured JSON logging |
| `org.springframework.cloud:spring-cloud-starter-config` | Config server client |
| `software.amazon.msk:aws-msk-iam-auth` | MSK IAM SASL for dev/int/prod. Exclude `commons-logging`. |
| `software.amazon.awssdk:secretsmanager` | Only if secrets-manager lookups are actually wired; the current `switches.secret.manager.enabled` flag is `false` everywhere, so **verify before keeping**. |
| `org.projectlombok:lombok` (provided) | Boilerplate |

**Test:**

| Artifact | Purpose |
|---|---|
| `spring-boot-starter-test` | JUnit 5, Mockito, AssertJ, MockMvc |
| `spring-kafka-test` | `@EmbeddedKafka`, `KafkaTestUtils` — **now actually used** (§10.4) |
| `spring-security-test` | `@WithMockUser`, JWT test support |
| `org.testcontainers:{testcontainers,junit-jupiter,postgresql}` | Real PostgreSQL for repository and integration tests |

**Removed from test scope:** `com.h2database:h2` and `org.testcontainers:kafka`. H2 goes away with
`schema-h2.sql` (§10.3); the Kafka Testcontainer is replaced by the lighter `@EmbeddedKafka`.

### 3.4 The replacement Kafka producer configuration

This one class replaces the whole of kafka-core's producer stack. kafka-core set only
`bootstrap.servers`, `key.serializer`, `value.serializer`, `enable.idempotence`, optionally
`transactional.id`, and the four SASL properties — everything else was Kafka client defaults. **The rebuild
must pin the delivery semantics explicitly** rather than inheriting them implicitly.

```java
package za.co.nova.outbound.kafka.config;

@Configuration
public class KafkaProducerConfiguration {

    @Bean
    public ProducerFactory<String, byte[]> producerFactory(KafkaProperties properties) {
        Map<String, Object> config = new HashMap<>(properties.buildProducerProperties(null));
        config.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        config.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ByteArraySerializer.class);
        config.putIfAbsent(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, true);
        config.putIfAbsent(ProducerConfig.ACKS_CONFIG, "all");
        return new DefaultKafkaProducerFactory<>(config);
    }

    @Bean
    public KafkaTemplate<String, byte[]> kafkaTemplate(ProducerFactory<String, byte[]> producerFactory) {
        return new KafkaTemplate<>(producerFactory);
    }

    @Bean
    public AdminClient adminClient(KafkaAdmin kafkaAdmin) {
        return AdminClient.create(kafkaAdmin.getConfigurationProperties());
    }
}
```

Notes:

- `enable.idempotence=true` implies `acks=all`, `retries=Integer.MAX_VALUE` and
  `max.in.flight.requests.per.connection<=5`. Setting `acks` explicitly documents the intent and guards
  against a future config override silently weakening it.
- `AdminClient` is a `@Bean` rather than created per call because `TopicService` holds it for the process
  lifetime. `EventTypeService.validateTopicExists` currently creates a **short-lived `AdminClient` per
  invocation** inside a try-with-resources; it must be changed to inject this shared bean.
- No transaction manager and no `transactional.id`. If MSK ever requires transactions, that is a new
  requirement, not a port.
- SASL/IAM configuration arrives through `spring.kafka.properties.*` (§8.4), so no code branch on
  "use IAM or not" is needed — kafka-core had one, and it is redundant.

---

## 4. Domain and data model

### 4.1 Conventions

All four entities follow the same rules:

- Primary key is `java.util.UUID` with `@Id @GeneratedValue(strategy = GenerationType.UUID)`.
- Timestamps are `java.time.Instant`, populated in JPA lifecycle callbacks with `Instant.now()`:
  `@PrePersist` sets `createdAt` (and `updatedAt` where present); `@PreUpdate` sets `updatedAt`.
  **No Spring Data auditing, no `@CreationTimestamp`.**
- `createdAt` columns are `nullable = false, updatable = false`.
- Enums persist as `@Enumerated(EnumType.STRING)` — never ordinal.
- JSON columns are declared `@JdbcTypeCode(SqlTypes.JSON) @Column(columnDefinition = "jsonb")` on a
  **`String`** field. The service serializes and deserializes the JSON itself with Jackson; Hibernate is not
  asked to map a `Map`.
- Lombok: `@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder`.

### 4.2 Enums

```java
package za.co.nova.domain.model.enums;

public enum KeyStrategy { MANUAL, FIELD }

public enum PublishStatus { SUCCESS, FAILED }
```

```java
// nested in za.co.nova.outbound.entity.Topic
public enum TopicRole { PRODUCER, CONSUMER, BOTH, DLT }
```

> **Declaration order is part of the contract.** The existing `EnumsTest` asserts
> `KeyStrategy.MANUAL.ordinal() == 0`, `FIELD == 1`, `PublishStatus.SUCCESS == 0`, `FAILED == 1`. Reordering
> is a breaking change even though persistence is by name.

### 4.3 `EventType` → `event_types`

A reusable, named publish configuration. **Note:** it is stored and validated but, per §12.5, is not
actually consulted by the publish path today.

| Field | Column | Type / constraints |
|---|---|---|
| `UUID id` | `id` | `UUID PRIMARY KEY` |
| `String name` | `name` | `VARCHAR(255) NOT NULL UNIQUE` |
| `String description` | `description` | `TEXT` |
| `String topic` | `topic` | `VARCHAR(255) NOT NULL` |
| `String schemaSubject` | `schema_subject` | `VARCHAR(255)` |
| `Integer schemaVersion` | `schema_version` | `INTEGER` |
| `KeyStrategy keyStrategy` | `key_strategy` | `VARCHAR(50) NOT NULL DEFAULT 'MANUAL'`; `@Builder.Default = MANUAL` |
| `String keyField` | `key_field` | `VARCHAR(255)` |
| `String defaultHeaders` | `default_headers` | `JSONB` — JSON object of `String`→`String` |
| `Instant createdAt` | `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |
| `Instant updatedAt` | `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |

Indexes: `idx_event_types_name(name)`, `idx_event_types_topic(topic)`.

### 4.4 `PublishRequestAudit` → `publish_request_audits`

One row per publish attempt.

| Field | Column | Type / constraints |
|---|---|---|
| `UUID id` | `id` | `UUID PRIMARY KEY` |
| `UUID eventTypeId` | `event_type_id` | `UUID` — nullable since `V1.0.1`. See §12.2. |
| `String topic` | `topic` | `VARCHAR(255) NOT NULL` |
| `String key` | **`message_key`** | `VARCHAR(500)` — **name mismatch is deliberate**, `key` is reserved in some dialects |
| `String headers` | `headers` | `JSONB` — the full outgoing header map |
| `String schemaSubject` | `schema_subject` | `VARCHAR(255)` |
| `Integer schemaVersion` | `schema_version` | `INTEGER` |
| `Integer schemaId` | `schema_id` | `INTEGER` — always null, see §12.1 |
| `String payloadJson` | `payload_json` | `TEXT` — written only when `app.audit.store-payload=true` |
| `PublishStatus status` | `status` | `VARCHAR(50) NOT NULL` |
| `String errorMessage` | `error_message` | `TEXT` |
| `Integer partition` | **`partition_number`** | `INTEGER` |
| `Long offset` | **`offset_value`** | `BIGINT` |
| `String correlationId` | `correlation_id` | `VARCHAR(255) NOT NULL` |
| `String idempotencyKey` | `idempotency_key` | `VARCHAR(255)` |
| `String userId` | `user_id` | `VARCHAR(255)` |
| `Instant createdAt` | `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |

Indexes on `event_type_id`, `status`, `correlation_id`, `idempotency_key`, `created_at`, `user_id`.

### 4.5 `SchemaArtifact` → `schema_artifacts`

Custom schemas registered in the database, as opposed to those discovered from the classpath.

| Field | Column | Type / constraints |
|---|---|---|
| `UUID id` | `id` | `UUID PRIMARY KEY` |
| `String name` | `name` | `VARCHAR(255) NOT NULL` |
| `String subject` | `subject` | `VARCHAR(255) NOT NULL` |
| `Integer version` | `version` | `INTEGER NOT NULL` |
| `Integer schemaId` | `schema_id` | `INTEGER` |
| `String avroSchemaJson` | `avro_schema_json` | `TEXT NOT NULL` |
| `String fingerprint` | `fingerprint` | `VARCHAR(255) NOT NULL` |
| `Instant createdAt` | `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |

Constraint `UNIQUE(subject, version)`; indexes on `subject` and `fingerprint`.

> **Rename for the rebuild.** With Protobuf support (§7), `avro_schema_json` is a misnomer. Rename it to
> `schema_definition` and add a `format VARCHAR(20) NOT NULL DEFAULT 'AVRO'` column in a new migration. Keep
> the Java field name `schemaDefinition`. The `SchemaResponse` DTO keeps `avroSchema`/`avroSchemaJson` as
> **deprecated aliases** alongside new `schema`/`schemaDefinition` fields so the existing frontend does not
> break — see §5.9.

Note: **no production code currently writes `SchemaArtifact` rows.** There is no POST/PUT/DELETE on
`/api/v1/schemas`. The table is read-only in practice. Either add a registration endpoint or document the
table as reserved.

### 4.6 `Topic` → `topics`

The curated topic catalogue.

| Field | Column | Type / constraints |
|---|---|---|
| `UUID id` | `id` | `UUID PRIMARY KEY` |
| `String name` | `name` | `VARCHAR(500) NOT NULL UNIQUE` |
| `String category` | `category` | `VARCHAR(100) NOT NULL` |
| `String environment` | `environment` | `VARCHAR(50)` |
| `String description` | `description` | `TEXT` |
| `String serviceName` | `service_name` | `VARCHAR(255)` |
| `TopicRole role` | `role` | `VARCHAR(50) CHECK (role IN ('PRODUCER','CONSUMER','BOTH','DLT'))` |
| `Boolean isActive` | `is_active` | `BOOLEAN NOT NULL DEFAULT true`; `@Builder.Default = true` |
| `Instant createdAt` | `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |
| `Instant updatedAt` | `updated_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |

Indexes on `name`, `category`, `environment`, `is_active`.

### 4.7 Repositories

Plain Spring Data JPA interfaces. **The rebuild collapses the `read`/`write` package split** — it existed
only so db-core could map packages to entity managers. Move all four to
`za.co.nova.outbound.repository` and delete `TopicWriteRepository` (an empty duplicate of
`TopicReadRepository`) and `PublishAuditWriteRepository` (dead and broken — see §12.8).

```java
public interface EventTypeRepository extends JpaRepository<EventType, UUID> {
    Optional<EventType> findByName(String name);
    boolean existsByName(String name);
    boolean existsByNameAndIdNot(String name, UUID id);
}

public interface PublishRequestAuditRepository
        extends JpaRepository<PublishRequestAudit, UUID>,
                JpaSpecificationExecutor<PublishRequestAudit> {
    Page<PublishRequestAudit> findByEventTypeId(UUID eventTypeId, Pageable pageable);
    Page<PublishRequestAudit> findByStatus(PublishStatus status, Pageable pageable);
    Optional<PublishRequestAudit> findByCorrelationId(String correlationId);
    Optional<PublishRequestAudit> findByIdempotencyKeyAndEventTypeIdAndStatus(
            String idempotencyKey, UUID eventTypeId, PublishStatus status);
    List<PublishRequestAudit> findByIdempotencyKeyAndEventTypeId(String idempotencyKey, UUID eventTypeId);
}

public interface SchemaArtifactRepository extends JpaRepository<SchemaArtifact, UUID> {
    Optional<SchemaArtifact> findBySubjectAndVersion(String subject, Integer version);
    List<SchemaArtifact> findBySubjectOrderByVersionDesc(String subject);
    Optional<SchemaArtifact> findTopBySubjectOrderByVersionDesc(String subject);
    Optional<SchemaArtifact> findByFingerprint(String fingerprint);
    boolean existsBySubject(String subject);

    @Query("SELECT DISTINCT s.subject FROM SchemaArtifact s ORDER BY s.subject")
    List<String> findAllSubjects();

    @Query("SELECT s.version FROM SchemaArtifact s WHERE s.subject = :subject ORDER BY s.version")
    List<Integer> findVersionsBySubject(@Param("subject") String subject);
}

public interface TopicRepository extends JpaRepository<Topic, UUID> {
    Optional<Topic> findByName(String name);
    List<Topic> findByCategory(String category);
    List<Topic> findByEnvironment(String environment);
    List<Topic> findByIsActive(Boolean isActive);
    List<Topic> findByCategoryAndEnvironment(String category, String environment);
    boolean existsByName(String name);
    boolean existsByNameAndIdNot(String name, UUID id);

    @Query("SELECT DISTINCT t.category FROM Topic t ORDER BY t.category")
    List<String> findAllCategories();

    @Query("SELECT DISTINCT t.environment FROM Topic t WHERE t.environment IS NOT NULL ORDER BY t.environment")
    List<String> findAllEnvironments();
}
```

### 4.8 Audit search specification

`PublishRequestAuditSpecification` is a utility with a private constructor and one static factory:

```java
public static Specification<PublishRequestAudit> withFilters(
        String topic, String schemaSubject, PublishStatus status,
        String correlationId, String idempotencyKey, String messageKey,
        Instant startDate, Instant endDate)
```

Rules:

- Each **string** filter contributes `equal(root.get(field), value)` only when the value is non-null **and
  not blank**. `null`, `""` and `"   "` are all ignored.
- `messageKey` maps to the entity field **`key`** (column `message_key`).
- `status` contributes `equal` when non-null.
- `startDate` contributes `greaterThanOrEqualTo(root.get("createdAt"), startDate)` — **inclusive**.
- `endDate` contributes `lessThanOrEqualTo(root.get("createdAt"), endDate)` — **inclusive**.
- Predicates are combined with `criteriaBuilder.and(...)`. An empty predicate list yields a conjunction of
  nothing, which matches every row.

### 4.9 Flyway migrations

Location `classpath:db/migration`. Carry all four forward verbatim, then add the format migration from §4.5.

| Version | Contents |
|---|---|
| `V1.0.0__initial_schema.sql` | Creates `event_types`, `schema_artifacts`, `publish_request_audits` (with `event_type_id NOT NULL`), all indexes, and `idempotency_cache`. |
| `V1.0.1__make_event_type_id_nullable.sql` | `ALTER TABLE publish_request_audits ALTER COLUMN event_type_id DROP NOT NULL;` |
| `V1.0.2__create_topics_table.sql` | Creates `topics` with the `role` CHECK constraint and four indexes, then seeds **80 rows** via `gen_random_uuid()`: 33 `dev-` credit, 3 `dev-` repayments, 4 `dev-` salesforce, 28 `int-` BANCS integration, 2 `int-` credit, 1 with no environment prefix. The authoritative list is `KAFKA_TOPICS.md`. |
| `V1.0.3__docker_topics_added.sql` | Seeds 7 `docker-` prefixed topics. **Currently untracked in git — commit it.** |
| `V1.1.0__schema_format.sql` *(new)* | `ALTER TABLE schema_artifacts RENAME COLUMN avro_schema_json TO schema_definition;` and `ADD COLUMN format VARCHAR(20) NOT NULL DEFAULT 'AVRO';` |

`gen_random_uuid()` requires PostgreSQL 13+ (it is built in from 13; earlier versions need `pgcrypto`).
This is one reason the test strategy moves to a real Postgres container (§10.3).

### 4.10 The unused `idempotency_cache` table

`V1.0.0` creates this table and **no Java code has ever touched it.** Recorded here so the decision in §12.4
is an informed one rather than a guess about what it was for:

| Column | Type |
|---|---|
| `idempotency_key` | `VARCHAR(255) NOT NULL` — part of the composite PK |
| `event_type_id` | `UUID NOT NULL` — part of the composite PK |
| `audit_id` | `UUID NOT NULL` — intended FK to `publish_request_audits.id` |
| `expires_at` | `TIMESTAMPTZ NOT NULL` |
| `created_at` | `TIMESTAMPTZ NOT NULL DEFAULT NOW()` |

`PRIMARY KEY (idempotency_key, event_type_id)`; index `idx_idempotency_expires_at(expires_at)`.

The design intent is legible: a database-backed replacement for the in-process Caffeine cache, keyed by
idempotency key plus event type, pointing at the audit row that recorded the original publish, with a TTL
column swept by something. Note the key differs from what the code actually uses — the Caffeine key is
`idempotencyKey + ":" + schemaSubject`, **not** `(idempotencyKey, eventTypeId)`. Since `eventTypeId` is never
populated on audit rows either (§12.2), this table could not be used as designed without also fixing that.
See §12.4 for the recommendation.

---

## 5. REST API contract

### 5.1 Endpoint summary

23 endpoints across six controllers. All produce `application/json` unless noted.

| # | Method | Path | Success | Errors |
|---|---|---|---|---|
| 1 | GET | `/api/v1/hello` | 200 `text/plain` | — |
| 2 | POST | `/api/v1/events/validate` | 200 | 404, 400 |
| 3 | POST | `/api/v1/events/publish` | 200 | 400, 404, 500 |
| 4 | POST | `/api/v1/events/bulk-publish` | 200 | 400, 404, 500 |
| 5 | GET | `/api/v1/published-messages` | 200 | — |
| 6 | GET | `/api/v1/published-messages/{id}` | 200 | 404 |
| 7 | POST | `/api/v1/published-messages/{id}/replay` | 200 | 400, 404, 500 |
| 8 | POST | `/api/v1/event-types` | **201** | 400, 409 |
| 9 | GET | `/api/v1/event-types` | 200 | — |
| 10 | GET | `/api/v1/event-types/{id}` | 200 | 404 |
| 11 | PUT | `/api/v1/event-types/{id}` | 200 | 400, 404, 409 |
| 12 | DELETE | `/api/v1/event-types/{id}` | **204** | 404 |
| 13 | GET | `/api/v1/schemas/subjects` | 200 | 502 |
| 14 | GET | `/api/v1/schemas/{subject}/versions` | 200 | 404 |
| 15 | GET | `/api/v1/schemas/{subject}/versions/latest` | 200 | 404 |
| 16 | GET | `/api/v1/schemas/{subject}/versions/{version}` | 200 | 404 |
| 17 | POST | `/api/v1/topics` | **201** | 400, 409 |
| 18 | GET | `/api/v1/topics` | 200 | — |
| 19 | GET | `/api/v1/topics/available` | 200 | 500 |
| 20 | GET | `/api/v1/topics/by-name` | 200 | 404 |
| 21 | GET | `/api/v1/topics/{id}` | 200 | 404 |
| 22 | PUT | `/api/v1/topics/{id}` | 200 | 400, 404, 409 |
| 23 | DELETE | `/api/v1/topics/{id}` | **204** | 404 |

### 5.2 Status-code conventions worth stating explicitly

These are non-obvious and are asserted by the test suite:

- **`POST /api/v1/events/publish` returns 200, not 201.** It is an action, not a resource creation.
- **`POST /api/v1/events/validate` returns 200 with `"valid": false` when validation fails.** A payload that
  does not conform is a successful validation *result*, not a client error. This differs from
  `/publish`, where the same non-conforming payload produces **400**.
- `create` on event-types and topics returns **201**; `delete` returns **204 No Content** with an empty body.
- Route ordering: **`/{subject}/versions/latest` must be declared before `/{subject}/versions/{version}`**,
  and `{version}` must be constrained to digits. See §12.7.

### 5.3 `ServiceController` — liveness probe

```
GET /api/v1/hello  →  200  "Hello World - live"
```

`@RestController @RequestMapping("/api/v1")`. Returns a bare string. Retained for existing smoke checks;
prefer `/actuator/health` for real probes.

### 5.4 `EventController` — `/api/v1/events`

All three methods declare `consumes = application/json`.

#### 5.4.1 `POST /validate`

| Parameter | Kind | Required | Type |
|---|---|---|---|
| `schemaSubject` | query | yes | `String` |
| `schemaVersion` | query | no | `Integer` — null means latest |
| *(body)* | body | yes | **raw JSON as `String`** — deliberately not bound to a DTO, so any shape can be validated |

Returns `ValidationResponse` with 200 whether or not the payload is valid.

#### 5.4.2 `POST /publish`

| Parameter | Kind | Required | Type |
|---|---|---|---|
| `schemaSubject` | query | yes | `String` |
| `topic` | query | yes | `String` |
| `X-Correlation-Id` | header | no | `String` — read by the servlet filter (§9.1), not by the controller |
| `Idempotency-Key` | header | no | `String` |
| *(body)* | body | yes | `@Valid PublishRequest` |

Returns `PublishResponse`, 200.

> The `correlationId` header is declared on the controller method signature but **unused** — the value is
> resolved from MDC, which `CorrelationIdFilter` has already populated. Keep the `@RequestHeader` declaration
> only for OpenAPI documentation, or document it as unused. Do not read it twice.

#### 5.4.3 `POST /bulk-publish`

Body `@Valid BulkPublishRequest`; returns `BulkPublishResponse`, 200.

> This endpoint is **fully synchronous and blocking** — up to 10 000 sequential blocking sends on the HTTP
> request thread, plus an optional `Thread.sleep` per message. See §12.10 for the required change.

### 5.5 `AuditController` — `/api/v1/published-messages`

Note the base path: **`published-messages`**, not `audit`. The security configuration still references the
old prefix — see §9.5.

#### 5.5.1 `GET /` — search

| Query param | Type | Default |
|---|---|---|
| `topic` | `String` | — |
| `schemaSubject` | `String` | — |
| `status` | `PublishStatus` | — |
| `correlationId` | `String` | — |
| `idempotencyKey` | `String` | — |
| `messageKey` | `String` | — |
| `startDate` | `Instant`, `@DateTimeFormat(iso = ISO.DATE_TIME)` | — |
| `endDate` | `Instant`, `@DateTimeFormat(iso = ISO.DATE_TIME)` | — |
| `page` | `int` | `0` |
| `size` | `int` | `20` |

Returns `Page<AuditResponse>` — the standard Spring Data page envelope (`content`, `totalElements`,
`totalPages`, `number`, `size`, …). **Sort is fixed at `createdAt DESC`** and is not client-configurable.

#### 5.5.2 `GET /{id}` — 200 `AuditResponse`, or 404.

#### 5.5.3 `POST /{id}/replay`

Body is `@RequestBody(required = false) ReplayRequest`; when absent the controller substitutes
`new ReplayRequest()`, so `POST` with `Content-Type: application/json` and no body must succeed. Returns
`PublishResponse`.

### 5.6 `EventTypeController` — `/api/v1/event-types`

Standard CRUD: `POST` (201), `GET` (list), `GET /{id}`, `PUT /{id}`, `DELETE /{id}` (204).

> The class is annotated **`@Hidden`**, which removes it from the OpenAPI document while leaving it fully
> functional. Remove `@Hidden` in the rebuild — a live, unauthenticated-in-practice CRUD surface that does
> not appear in the API docs is a discoverability and security-review hazard. If it is meant to be internal,
> gate it behind configuration instead.

### 5.7 `SchemaController` — `/api/v1/schemas`

Read-only. `GET /subjects` → `List<String>`; `GET /{subject}/versions` → `List<Integer>`;
`GET /{subject}/versions/latest` → `SchemaResponse`; `GET /{subject}/versions/{version}` → `SchemaResponse`.

Subjects contain underscores and hyphens (e.g. `avro_dto_repayments_TransactionTransferStatus-value`) and
must round-trip unchanged through the path variable.

### 5.8 `TopicController` — `/api/v1/topics`

Backed by two collaborators: `TopicManagementService` (database catalogue) and `TopicService` (live Kafka).

`GET /` routing rule, exactly:

```java
if (category != null || environment != null || Boolean.TRUE.equals(activeOnly)) {
    response = topicManagementService.findFiltered(category, environment, activeOnly);
} else {
    response = topicManagementService.findAll();
}
```

`activeOnly=false` therefore takes the **unfiltered** path — `Boolean.TRUE.equals` is not `!= null`. Preserve
this or change it deliberately.

`GET /available` queries the Kafka cluster through `AdminClient` and returns `TopicsListResponse` with
`category` and `environment` derived from the topic name (§6.7). Rows have no `id`, `description`,
`serviceName` or `role` because Kafka does not carry that metadata.

### 5.9 Request DTOs

All are Lombok `@Data @Builder @NoArgsConstructor @AllArgsConstructor`.

**`PublishRequest`**

| Field | Type | Validation |
|---|---|---|
| `payload` | `Object` | `@NotNull(message = "Payload is required")` |
| `key` | `String` | — |
| `headers` | `Map<String,String>` | — |
| `schemaVersion` | `Integer` | — null means latest |

`payload` is `Object` so callers can send either a JSON object/array or a JSON **string** containing JSON.
Both are supported (§6.2).

**`BulkPublishRequest`**

| Field | Type | Validation |
|---|---|---|
| `schemaSubject` | `String` | `@NotBlank("Schema subject is required")` |
| `schemaVersion` | `Integer` | — |
| `topic` | `String` | `@NotBlank("Topic is required")` |
| `numberOfMessages` | `Integer` | `@NotNull("Number of messages is required")`, `@Min(1, "Must generate at least 1 message")`, `@Max(10000, "Cannot generate more than 10000 messages at once")` |
| `delayBetweenMessagesMs` | `Integer` | `@Builder.Default = 0` |
| `randomKeys` | `Boolean` | `@Builder.Default = true` |
| `fixedKey` | `String` | Used when `randomKeys` is false |
| `eventType` | `String` | Drives semantic overrides (§6.9) |
| `fieldOverrides` | `Map<String,Object>` | Dot-notation paths, e.g. `"body.resultCode"` |

**`EventTypeCreateRequest`** — `name` `@NotBlank("Name is required")`; `topic` `@NotBlank("Topic is
required")`; `keyStrategy` `@NotNull("Key strategy is required")` with `@Builder.Default = MANUAL`; plus
`description`, `schemaSubject`, `schemaVersion`, `keyField`, `defaultHeaders`.

**`EventTypeUpdateRequest`** — identical fields and messages, but `keyStrategy` has **no**
`@Builder.Default`. Update semantics are **full replacement**: every field is overwritten, including with
null.

**`TopicCreateRequest`** — `name` `@NotBlank("Topic name is required")`; `category`
`@NotBlank("Category is required")`; `role` `@NotNull("Topic role is required")`; plus `environment`,
`description`, `serviceName`, and `isActive` with `@Builder.Default = true`.

**`TopicUpdateRequest`** — all seven fields optional, no validation. Update semantics are **partial /
PATCH-like** on a `PUT` (§6.8). This asymmetry with `EventTypeUpdateRequest` is real and must be preserved
or resolved deliberately.

**`ReplayRequest`** — `schemaVersionOverride` `Integer`; `useLatestSchema` `boolean` with
`@Builder.Default = false`.

**`AuditSearchRequest`** — internal, assembled by the controller from query params. `page`
`@Builder.Default = 0`; `size` `@Builder.Default = 20`.

**`ValidateRequest`** — `eventTypeId` `@NotNull`, `payloadJson` `@NotBlank`, `schemaVersionOverride`.
**Currently unreachable from any endpoint** — see §12.6.

### 5.10 Response DTOs

`PublishResponse`, `AuditResponse` and `ErrorResponse` carry
`@JsonInclude(JsonInclude.Include.NON_NULL)`; the others do not.

**`PublishResponse`** — `status`, `topic`, `partition`, `offset`, `schemaSubject`, `schemaVersion`,
`schemaId`, `correlationId`, `timestamp` (`Instant`, from the broker's `RecordMetadata.timestamp()`),
`payload` (echo of the request payload), `errorMessage`.

**`ValidationResponse`** — `valid` (`boolean`), `errors` (`List<ValidationError>`), `schemaSubject`,
`schemaVersion`.

**`ValidationError`** — `path`, `message`, `expectedType`, `actualValue`.

**`AuditResponse`** — all 18 fields of the audit row plus a resolved `eventTypeName`; `headers` as a
`Map<String,String>` and `payload` as a parsed `Object`.

**`SchemaResponse`** — `id`, `name`, `subject`, `version`, `schemaId`, `fingerprint`, `createdAt`, plus:

| Field | Type | Notes |
|---|---|---|
| `format` | `SchemaFormat` | **New** — `AVRO` or `PROTOBUF` |
| `schemaDefinition` | `String` | **New** — canonical name for the raw definition |
| `schema` | `JsonNode` | **New** — parsed form, null for Protobuf |
| `avroSchemaJson` | `String` | **Deprecated alias** for `schemaDefinition` |
| `avroSchema` | `JsonNode` | **Deprecated alias** for `schema` |

Keeping the aliases is a compatibility requirement: the Mockafka frontend reads `avroSchema` and
`avroSchemaJson` today.

**`TopicResponse`** — the 10 catalogue fields. **`TopicsListResponse`** — `topics`, `totalCount`,
`categories`, `environments`.

**`BulkPublishResponse`** — `totalRequested`, `successCount`, `failureCount`, `topic`, `schemaSubject`,
`schemaVersion`, `eventType`, `durationMs`, `startedAt`, `completedAt`, `errors` (null when empty),
`sampleKeys` (first 10).

**`ErrorResponse`** — `timestamp`, `status`, `error`, `message`, `path`, `fieldErrors`, `correlationId`, with
nested `FieldError { field, message, rejectedValue }`.

### 5.11 OpenAPI documentation

`EventController` implements a documentation-only interface (`EventControllerDoc`) that carries every
`@Operation`, `@ApiResponse`, `@Parameter` and `@ExampleObject`, keeping the controller body free of
annotation noise. **Retain this pattern** — it works well and should be extended to the other controllers.

`OpenApiConfig` builds the document: title "Event Publisher API", version `1.0.0`, description
"REST API for publishing events to Kafka with Avro schema validation and Schema Registry integration"
(update the wording once Protobuf lands), contact, license "Proprietary". When `app.security.enabled=true`
it adds `bearer-jwt` (HTTP bearer, JWT) and `oauth2` (authorization-code flow at `/oauth2/authorize` and
`/oauth2/token`) security schemes, and a top-level requirement on `bearer-jwt`.

---

## 6. The publish pipeline

The single most important behaviour in the service. This section is the normative description.

### 6.1 `PublishService.publish` — the algorithm

```
publish(schemaSubject, topic, request, idempotencyKey) → PublishResponse
```

Annotated `@Transactional`. Steps, in order:

1. **Correlation ID** — `correlationIdHolder.getCorrelationId()`, i.e. read from SLF4J MDC under key
   `correlationId`. The servlet filter (§9.1) has already put it there. Record `startTime`.
2. **Payload to JSON** — see §6.2.
3. **Idempotency check** — see §6.3.
4. **Schema resolution** — `resolvedVersion = schemaService.resolveSchemaVersion(schemaSubject,
   request.getSchemaVersion())`; `schemaId = schemaService.resolveSchemaId(...)` (always `null`, §12.1);
   load the schema descriptor.
5. **Validate** — `codec.validate(payloadJson, descriptor)`. If the error list is non-empty, throw
   `SchemaValidationException("Payload validation failed against schema: " + schemaSubject, errors)`
   → **HTTP 400** with populated `fieldErrors`.
6. **Encode** — `byte[] value = codec.encode(payloadJson, descriptor)`. See §6.4.
7. **Headers** — assemble the envelope, §6.5.
8. **Ensure topic** — `topicService.ensureTopicExists(topic)`, §6.6. Never throws.
9. **Send** — §6.4.
10. **Success** — build the response from `RecordMetadata`, build and save the audit row, increment
    `publish_success_total`.
11. **Failure** — §6.10.
12. **Finally** — always `publishLatencyTimer.record(elapsedMillis, MILLISECONDS)`.
13. **Cache** — on success with a non-null idempotency key, store the response.

### 6.2 Payload normalisation

```java
private String convertPayloadToJson(Object payload) {
    if (payload == null) throw new IllegalArgumentException("Payload cannot be null");
    if (payload instanceof String s) return s;                 // pass through verbatim
    return objectMapper.writeValueAsString(payload);           // JsonProcessingException → PublishException
}
```

The `String` branch matters: a caller may submit `"payload": "{\"id\":\"1\"}"` and the inner JSON must be
used **exactly as given**, not re-serialized (which would escape it a second time).

The `null` guard duplicates `@NotNull` on the DTO, and that is intentional — the service is also called
directly by `AuditService.replay` and `BulkPublishService`, which bypass Bean Validation.

### 6.3 Idempotency

- **Cache key:** `idempotencyKey + ":" + schemaSubject`. This exact format is contractual.
- **Store:** Caffeine `Cache<String, PublishResponse>`, `expireAfterWrite(app.idempotency.ttl-minutes)`,
  `maximumSize(app.idempotency.max-size)`.
- **Hit condition:** an entry exists **and** its `status == SUCCESS`. On a hit, return the cached response
  immediately — no schema resolution, no validation, no Kafka send.
- **Write condition:** after a successful publish, when `idempotencyKey != null`. **Failures are never
  cached**, so a retry after failure genuinely retries.
- **Scope:** in-process only. Not shared across replicas. See §12.4.

### 6.4 Serialization and send

Encoding is **plain Avro binary** — `GenericDatumWriter` + `EncoderFactory.get().binaryEncoder(out, null)`,
then `flush()`. There is **no Confluent wire-format prefix**: no `0x00` magic byte and no 4-byte schema ID.
Consumers must therefore already know the schema (they resolve it from the `Schema-Name` header or from
their own compiled `SpecificRecord`).

> This is the single most important wire-level fact in the specification. A consumer built against a
> Confluent deserializer will fail on these bytes.

Send:

```java
ProducerRecord<String, byte[]> record = new ProducerRecord<>(topic, key, value);
headers.forEach((k, v) -> record.headers().add(new RecordHeader(k, v.getBytes(StandardCharsets.UTF_8))));
return kafkaTemplate.send(record)
        .get(applicationProperties.getKafka().getProducerTimeout(), TimeUnit.MILLISECONDS);
```

- Key type `String`, value type `byte[]`. A null key is permitted (round-robin partitioning).
- Partition is never specified explicitly.
- The send is **blocking** with a timeout of `app.kafka.producer-timeout` milliseconds (default 30 000).

### 6.5 The header envelope

Built as a `Map<String,String>`, then written as UTF-8 `RecordHeader`s:

1. Copy every entry from `request.getHeaders()` if non-null.
2. **Always** put `X-Correlation-Id` = the resolved correlation ID. This overwrites any caller-supplied
   value.
3. **Always** put `Schema-Name` = `deriveSchemaName(schemaSubject)`. Also overwrites.
4. **Only if absent**, put `Event-Type` = `deriveEventType(schemaSubject)`. A caller-supplied `Event-Type`
   **must be preserved**.

Derivation rules — both first strip a trailing `-value` (6 chars) or `-key` (4 chars), and both return `""`
for null or blank input:

```
deriveSchemaName: then replace every '_' with '.'
deriveEventType:  then take the substring after the LAST '_'; if there is no '_', the whole name
```

| `schemaSubject` | `Schema-Name` | `Event-Type` |
|---|---|---|
| `avro_dto_repayments_TransactionTransferStatus-value` | `avro.dto.repayments.TransactionTransferStatus` | `TransactionTransferStatus` |
| `avro_dto_granting_ApplicationCreated-value` | `avro.dto.granting.ApplicationCreated` | `ApplicationCreated` |
| `avro_dto_decisioning_CreditOffer-value` | `avro.dto.decisioning.CreditOffer` | `CreditOffer` |
| `PlainName` | `PlainName` | `PlainName` |
| `""` / `null` | `""` | `""` |

> The `Event-Type` behaviour is the MOCKAFKA-16 fix. Two existing tests inspect the real `ProducerRecord` and
> assert `lastHeader("Event-Type")` — so derivation must not *append* a second `Event-Type` header when one
> already exists; it must not write one at all.

### 6.6 Topic auto-creation

`TopicService.ensureTopicExists(topicName)`, intended for local development only:

1. If `app.kafka.auto-create-topics.enabled` is false → return immediately.
2. If the name is already in the in-memory `verifiedTopics` set (`ConcurrentHashMap.newKeySet()`) → return.
3. If `topicExists(name)` → add to `verifiedTopics`, return.
4. Otherwise `createTopic(name)` with the configured partitions and replication factor, then add to
   `verifiedTopics`.
5. **Every exception is caught and logged at WARN.** The method never propagates — the publish attempt is
   allowed to proceed and fail naturally if the topic really is missing.

All `AdminClient` calls use a hard-coded **30-second** timeout (`ADMIN_TIMEOUT_SECONDS = 30`).

`topicExists` returns `false` on any failure. On `InterruptedException` it restores the interrupt flag with
`Thread.currentThread().interrupt()` before returning.

`createTopic` throws `KafkaTopicException` with these messages:

| Condition | Message |
|---|---|
| `InterruptedException` | `"Interrupted while creating topic: " + name` (interrupt flag restored) |
| `ExecutionException` whose cause's simple name is `"TopicExistsException"` | **Not an error** — logged at INFO as a benign race |
| other `ExecutionException` | `"Failed to create topic: " + name` |
| `TimeoutException` | `"Timeout while creating topic: " + name` |

### 6.7 Live topic listing and name parsing

`TopicService.listAvailableTopics()` lists names from `AdminClient`, maps each through `parseTopicInfo`,
sorts by name, and aggregates distinct `categories` and `environments`.

**Environment** — from the name prefix, which is then stripped before category matching:

| Prefix | Environment |
|---|---|
| `dev-` | `dev` |
| `int-` | `int` |
| `prod-` | `prod` |
| `local-` | `local` |
| *(none)* | `null` |

**Category** — first match wins, against the prefix-stripped name:

| Test | Category |
|---|---|
| contains `credit` | `credit` |
| contains `repayments` or `payment` | `repayments` |
| contains `salesforce` | `salesforce` |
| contains `bancs`, or starts with `incoming-bancs` | `integration` |
| *(default)* | `other` |

Aggregation rules: `categories` excludes both `null` and the literal `"other"`; `environments` excludes
`null`. Both lists are sorted. `TopicResponse.name` is the **original** name including its prefix, and
`isActive` is hardcoded `true`.

The `docker-` prefix used by `V1.0.3` is **not** recognised by this parser — docker topics come back with
`environment = null`. Add `docker-` to the prefix table in the rebuild.

Failures throw `KafkaTopicException`: `"Interrupted while listing topics"` or `"Failed to list topics from
Kafka cluster"`.

### 6.8 Topic catalogue CRUD

`TopicManagementService`, backed by the database.

- **`create`** — `existsByName` → `DuplicateResourceException("Topic", "name", name)` (409). `isActive`
  defaults to `TRUE` via `Objects.requireNonNullElse(request.getIsActive(), Boolean.TRUE)`.
- **`findAll`** — `@Transactional(readOnly = true)`. Returns all topics plus the full distinct category and
  environment lists.
- **`findFiltered(category, environment, activeOnly)`** — repository selection by precedence:

  | Condition | Repository call |
  |---|---|
  | both `category` and `environment` non-null | `findByCategoryAndEnvironment` |
  | `category` only | `findByCategory` |
  | `environment` only | `findByEnvironment` |
  | neither, and `activeOnly` is `TRUE` | `findByIsActive(true)` |
  | otherwise | `findAll()` |

  Then, **if `activeOnly` is `TRUE`, an additional in-memory `filter(Topic::getIsActive)`** is applied. This
  matters when `category`/`environment` took precedence: the repository query did not filter on active, so
  the in-memory pass does. `categories` and `environments` in the response are always the *full* distinct
  lists, never narrowed by the filter.
- **`findById` / `findByName`** — `ResourceNotFoundException("Topic", "id", id.toString())` /
  `("Topic", "name", name)`.
- **`update`** — **partial semantics**: each non-null field in the request is applied; null fields leave the
  entity untouched. A name change additionally checks `existsByNameAndIdNot` → 409. When the submitted name
  equals the current name, the duplicate check is **skipped entirely**.
- **`delete`** — load or 404, then `repository.delete(entity)`.

### 6.9 Bulk publish and fake-data generation

`BulkPublishService.bulkPublish(request)`:

1. Resolve version and schema descriptor **once**.
2. Loop `i` from `0` to `numberOfMessages - 1`, **sequentially and synchronously**:
   - `payload = fakeDataGenerator.generate(descriptor, request.getEventType(),
     request.getFieldOverrides())`
   - `key = Boolean.TRUE.equals(request.getRandomKeys()) ? UUID.randomUUID().toString()
     : request.getFixedKey()`
   - `publishService.publish(schemaSubject, topic, new PublishRequest(payload, key, null, schemaVersion),
     null)` — **idempotency key is always null** for bulk
   - increment `successCount`; retain the first 10 keys in `sampleKeys`
   - if `delayBetweenMessagesMs > 0`, `Thread.sleep(...)`
   - log progress every 100 messages
3. `InterruptedException` → restore the interrupt flag, append `"Interrupted at message " + i`, **break**
   out of the loop.
4. Any other `Exception` → increment `failureCount`, append
   `String.format("Message %d failed: %s", i, e.getMessage())`, **capped at 100 error strings**.
5. Build the response; `errors` is `null` rather than an empty list when there were none.

**Fake-data generation** (`FakeDataGeneratorService`, using `net.datafaker`) — the schema must be a record,
else `IllegalArgumentException("Schema must be a record type")`. Generation order: generate all top-level
fields → apply event-type overrides → apply field overrides.

*Union handling:* pick the first non-null branch, but with a **90% chance to populate and 10% chance to
emit null** (`ThreadLocalRandom.current().nextDouble() < 0.9`).

*Logical types are checked first:*

| Logical type | Generated value |
|---|---|
| `date` | `(int) LocalDate.now().minusDays(random 0..365).toEpochDay()` |
| `time-millis` | int in `0..86_400_000` |
| `time-micros` | long in `0..86_400_000_000` |
| `timestamp-millis` | `Instant.now().minusSeconds(random 0..31_536_000).toEpochMilli()` |
| `timestamp-micros` | as above × 1000 |
| `uuid` | random UUID string |
| `decimal` | `faker.number().randomDouble(2, 0, 10000)` |

*Then by Avro type:* `BOOLEAN` → `faker.bool().bool()`; `BYTES` → `faker.lorem().characters(10,50)
.getBytes()`; `ENUM` → random symbol; `ARRAY` → 1–4 elements; `MAP` → 1–4 entries keyed `word_i`;
`RECORD` → recurse; `FIXED` → random `byte[size]`; `NULL` → null; `STRING`/`INT`/`LONG`/`FLOAT`/`DOUBLE` →
name-based heuristics.

*String heuristics*, matched in order against the lower-cased field name: `email` → `phone`/`mobile`/`cell`
→ `firstname` → `lastname` → `name` (not containing `user`) → `username` → `address`/`street` → `city` →
`country` → `state`/`province` → `zip`/`postal` → `company`/`organization` → `title`/`job` →
`description`/`desc` → `comment`/`note` → `url`/`link`/`website` → `ip`+`address` → `uuid`/`guid` →
`id` (exact, or `_id`/`id` suffix) → `currency` → `date` → `time`/`timestamp` → `status`
(`ACTIVE|INACTIVE|PENDING|COMPLETED|CANCELLED`) → `type`/`category` (`TYPE_A`..`TYPE_D`) → `code`
(`faker.code().isbn10()`) → `color`/`colour` → `account` (10 digits) → `cif` (10 digits) →
`credit`+`card` → default `faker.lorem().word() + "-" + faker.number().digits(4)`.

*Numeric heuristics:* `INT` — `age` 18–80, `year` 2024–2026, `month` 1–12, `day` 1–31,
`count`/`quantity`/`qty` 1–100, `score`/`rating` 1–10, `percent` 0–100, `version` 1–10, default 1–1000.
`LONG` — `timestamp`/`time` → epoch millis in the past year, `id` → 1 000 000..9 999 999 999,
`amount`/`balance` → 100..1 000 000, default 1..1 000 000. `FLOAT`/`DOUBLE` — `price`/`amount`/`cost`,
`rate`/`percent`, `lat`/`latitude`, `lon`/`longitude`, defaults with 2 or 4 decimal places.

*Event-type overrides* — if the payload has a `header` map, set `header.eventType = eventType`. If it has a
`body` map, apply:

| `eventType` | Body mutations |
|---|---|
| `RepaymentTransactionTransferCompleted` | `resultCode=0`, `resultReasonCode="SUCCESS"`, `resultMsg="Transaction completed successfully"`, `processed=true` |
| `RepaymentTransactionTransferFailed` | `resultCode=` random 1–100, `resultReasonCode=` random from `INSUFFICIENT_FUNDS, ACCOUNT_BLOCKED, INVALID_ACCOUNT, TIMEOUT, SYSTEM_ERROR, LIMIT_EXCEEDED`, `resultMsg=` matching random sentence, `processed=false` |
| anything else | debug log only |

Finally, if a **root-level** `eventType` key exists, set it too.

> These two hardcoded event types are repayments-specific business logic embedded in a generic tool. The
> rebuild should move them into configuration — a `Map<String, Map<String,Object>>` under
> `app.bulk.event-type-presets` — so new presets do not require a code change.

*Field overrides* — dot-notation path walk. If an intermediate segment is missing or is not a `Map`, log a
WARN and **skip that override silently**; otherwise `put` the value at the final segment.

### 6.10 Error handling and the audit-rollback defect

Three catch blocks, all of which increment `publish_failure_total`, build a `FAILED` response and audit row,
save the audit, and rethrow:

| Caught | Response `errorMessage` | Audit `errorMessage` | Thrown |
|---|---|---|---|
| `TimeoutException` | `"Kafka connection timeout - broker may be unreachable or authentication failed"` | `"Timeout: " + e.getMessage()` | `PublishException("Kafka connection timeout", e)` |
| `ExecutionException` | `e.getCause() != null ? cause.getMessage() : e.getMessage()` | same | `PublishException(errorMsg, cause != null ? cause : e)` — **the wrapper is unwrapped** |
| `Exception` | `e.getMessage()` | same | `PublishException("Failed to publish event: " + e.getMessage(), e)` |

> ### Defect: failure audits are silently rolled back
>
> `publish` is `@Transactional`. Each failure path calls `auditRepository.save(audit)` and then throws. The
> throw marks the transaction for rollback, so **the FAILED audit row is discarded**. Operationally this
> means the audit trail contains only successes, while the UI and the `publish_failure_total` counter say
> failures happened.
>
> **Required fix.** Move failure auditing out of the failing transaction. Either:
>
> 1. Extract auditing into a collaborator whose `saveFailure` method is
>    `@Transactional(propagation = Propagation.REQUIRES_NEW)`; or
> 2. Remove `@Transactional` from `publish` entirely — it writes exactly one row, so it does not need a
>    transaction spanning the Kafka send. This is the simpler option and also stops a slow Kafka send from
>    holding a database connection for up to 30 seconds.
>
> **Option 2 is recommended.** Holding a JDBC connection across a blocking network call to a broker is the
> more serious of the two problems.

### 6.11 User attribution

```java
private String getCurrentUserId() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth != null && auth.getPrincipal() instanceof Jwt jwt) return jwt.getSubject();
    return "anonymous";
}
```

With `app.security.enabled=false` — the setting in every shipped profile — every audit row records
`"anonymous"`.

### 6.12 Replay

`AuditService.replay(auditId, request)`:

1. Load the audit or `ResourceNotFoundException("PublishedMessage", auditId)` → 404.
2. If `payloadJson` is null or blank → `IllegalArgumentException("Cannot replay published message without
   stored payload. Enable AUDIT_STORE_PAYLOAD to allow replay.")` → **400**.
3. Version resolution, in precedence order: `schemaVersionOverride` if set; else the audited
   `schemaVersion` if `useLatestSchema` is false; else `null`, meaning latest.
4. Rebuild a `PublishRequest` from `objectMapper.readTree(payloadJson)`, the audited `key`, the
   deserialized audited `headers`, and the resolved version.
5. `publishService.publish(audit.getSchemaSubject(), audit.getTopic(), publishRequest, null)` — the
   **idempotency key is deliberately null** so a replay always genuinely republishes.

### 6.13 Read-path leniency

`AuditService.mapToResponse` is deliberately forgiving — a corrupt stored value must never break a read:

| Situation | Behaviour |
|---|---|
| `eventTypeId` set but the event type was deleted | catch `ResourceNotFoundException`, log WARN, leave `eventTypeName` null |
| `headers` is not valid JSON | log WARN, return `Map.of()` |
| `payloadJson` is not valid JSON | log WARN, return the **raw string** as the payload |
| `payloadJson` is null | `payload` is null |

Contrast with the **write** path, where `EventTypeService.deserializeHeaders` throws
`RuntimeException("Failed to deserialize headers", e)` on malformed JSON. Both behaviours are intentional
and asserted by tests.

---

## 7. Message format abstraction (Avro + Protobuf)

This is the main structural addition in the rebuild. Today schema loading, validation, JSON conversion,
serialization and fake-data generation are Avro-specific and spread across `SchemaService`,
`ValidationService`, `PublishService` and `FakeDataGeneratorService`. Two seams pull them apart.

### 7.1 Core types

```java
package za.co.nova.domain.schema;

public enum SchemaFormat { AVRO, PROTOBUF }

/** A resolved schema, independent of format. */
public record SchemaDescriptor(
        String subject,
        String name,            // simple name, e.g. "TransactionTransferStatus"
        String fullName,        // e.g. "avro.dto.repayments.TransactionTransferStatus"
        Integer version,
        SchemaFormat format,
        String definition,      // raw .avsc JSON, or the .proto / descriptor-set reference
        String fingerprint,     // SHA-256 hex over the normalised definition
        Object parsed) {        // org.apache.avro.Schema, or com.google.protobuf.Descriptors.Descriptor
}
```

### 7.2 `SchemaSource` — where schemas come from

```java
public interface SchemaSource {
    /** Ordering hint; lower wins in the composite. */
    int priority();
    List<String> subjects();
    Optional<SchemaDescriptor> find(String subject, Integer version);
    default List<Integer> versions(String subject) { return List.of(1); }
}
```

Implementations:

| Implementation | Priority | Behaviour |
|---|---|---|
| `FilesystemSchemaSource` | 10 | `Files.walk(app.schema.extracted-path)`, filter by extension. A missing directory logs INFO and yields nothing; an `IOException` logs WARN. |
| `ClasspathSchemaSource` | 20 | `PathMatchingResourcePatternResolver.getResources(app.schema.classpath-pattern)`. Default pattern `classpath*:schemas/**/*.avsc`. **This is how the optional `event-schema-registry` jar's 80 `.avsc` resources are consumed** — the jar is nothing but resources, so it plugs in with no code. |
| `DatabaseSchemaSource` | 30 | Queries `schema_artifacts`. The only source that supports versions other than 1. |
| `CompositeSchemaSource` | — | Delegates in priority order, **first non-empty wins**. `subjects()` is the sorted distinct union across all sources. |

Rules preserved from the current implementation:

- **Subject naming:** `parsedSchema.getFullName().replace('.', '_') + "-value"`. Subjects are *computed*,
  never read from the file.
- **Filesystem and classpath schemas are always version 1.**
- **Precedence is filesystem → classpath → database**, first-wins (the current code achieves this with
  `computeIfAbsent` over a shared map; the composite makes it explicit).
- **Fingerprint:** parse the definition with Jackson, re-serialize it to normalise formatting, SHA-256 the
  UTF-8 bytes, hex-encode with `HexFormat.of().formatHex(...)`.
- **Per-schema load failures are logged at WARN and skipped** — one malformed file must not prevent startup.
- Discovery happens once at startup and is cached in a `ConcurrentHashMap`. `getPreloadedSchemas()` returns
  `Map.copyOf(...)` — an **immutable** copy, asserted by an existing test.

`SchemaService` keeps its current public surface on top of the composite:

| Method | Behaviour |
|---|---|
| `getSubjects()` | union of all sources, **distinct and sorted** |
| `getVersions(subject)` | `List.of(1)` for a preloaded subject; else database versions; empty → `ResourceNotFoundException("Schema subject", subject)` |
| `getSchema(subject, version)` | preloaded when `version == 1` and present; else database; miss → `ResourceNotFoundException("Schema", subject + ":" + version)` |
| `getLatestSchema(subject)` | **database first** (it may hold a higher version), then preloaded, then `ResourceNotFoundException("Schema", subject)` |
| `getSchemaByName(name)` | scan preloaded by simple name, then the database, else `ResourceNotFoundException("Schema by name", name)` |
| `resolveSchemaVersion(subject, version)` | the argument if non-null; else the latest database version; else `1` if preloaded; else `ResourceNotFoundException` |
| `resolveSchemaId(subject, version)` | **always `null`** — see §12.1 |
| `schemaExists(subject)` | preloaded contains, or `existsBySubject` |
| `parseAndValidate(definition, format)` | delegates to the codec; any failure → `SchemaValidationException("Invalid " + format + " schema: " + msg)` |

### 7.3 `MessageCodec` — how payloads are validated and encoded

```java
public interface MessageCodec {
    SchemaFormat format();
    Object parseSchema(String definition);                             // → SchemaDescriptor.parsed
    List<ValidationError> validate(String payloadJson, SchemaDescriptor descriptor);
    byte[] encode(String payloadJson, SchemaDescriptor descriptor);
    Object generateFake(SchemaDescriptor descriptor, String eventType, Map<String,Object> overrides);
}
```

Resolution: a `MessageCodecRegistry` holds one codec per `SchemaFormat` and is looked up from
`descriptor.format()`. `app.schema.default-format` (default `AVRO`) applies when a source cannot determine
the format — for instance a `schema_artifacts` row written before the `format` column existed.

`PublishService` becomes format-agnostic:

```java
MessageCodec codec = codecRegistry.forFormat(descriptor.format());
List<ValidationError> errors = codec.validate(payloadJson, descriptor);
if (!errors.isEmpty()) throw new SchemaValidationException(...);
byte[] value = codec.encode(payloadJson, descriptor);
```

`Schema-Name` and `Event-Type` derivation, the audit contract and every response DTO stay unchanged. Only
the bytes differ.

### 7.4 `AvroMessageCodec` — existing behaviour, relocated

This is a **behaviour-preserving extraction**, not a rewrite. Everything below is asserted by the 47 existing
`ValidationServiceTest` cases and must be reproduced exactly.

`parseSchema` — `objectMapper.readTree(json)` first (to reject malformed JSON with a clear message), then
`new Schema.Parser().parse(json)`.

`encode` — convert JSON to `GenericRecord`, then `GenericDatumWriter` + binary encoder (§6.4).

**Validation.** Recursive, error-accumulating (it does not stop at the first problem). Path notation:
`field`, `parent.child`, `arr[0]`; root is `"$"`. A JSON parse failure yields a single
`ValidationError{path: "$", message: "Invalid JSON: " + msg}` rather than an exception.

| Schema type | Rule | Error message contains |
|---|---|---|
| `RECORD` | node must be an object | `"Expected object for record type"` |
| `RECORD` field | missing or null, and the field has no null in its union and no default | `"Required field is missing"` |
| `ARRAY` | node must be an array; recurse per element | `"Expected array"` |
| `MAP` | node must be an object; recurse per entry | `"Expected object for map type"` |
| `UNION` | at least one branch must validate cleanly | `"Value does not match any type in union: [names]"` |
| `ENUM` | must be textual **and** a declared symbol | `"Expected string for enum"` / `"Invalid enum value. Valid values: [...]"` |
| `STRING` | textual | `"Expected string"` |
| `BYTES` | textual or binary | `"Expected bytes (base64 string)"` |
| `INT` | logical `date` → int **or** ISO string; else int/long | `"Expected int"` |
| `LONG` | logical `timestamp-millis`/`timestamp-micros` → long/int/**textual**; else long/int | `"Expected long"` |
| `FLOAT`/`DOUBLE` | numeric | `"Expected number"` |
| `BOOLEAN` | boolean | `"Expected boolean"` |
| `NULL` | must be null | `"Expected null"` |
| `FIXED` | textual | `"Expected string for fixed type"` |

On error, `expectedType` carries the Avro type name (or union member names joined with `|`) and
`actualValue` carries `jsonNode.getNodeType().toString()` for record mismatches, or `jsonNode.toString()`
for union mismatches.

**JSON → `GenericRecord` conversion.** Field-level precedence, in order — this is the MOCKAFKA-16
"unmapped values" fix and must be reproduced exactly:

1. Value present and non-null → convert it against the field schema.
2. Else if `field.defaultVal() != null`:
   - if it is the `org.apache.avro.JsonProperties.Null` sentinel → put `null`;
   - otherwise convert `objectMapper.valueToTree(field.defaultVal())` against the field schema and put that.
3. Else if the field's union contains `null` → put `null`.
4. Else leave the field unset (which surfaces as a validation error upstream).

**Union conversion:** skip the `NULL` branch unless the node itself is null, then try each remaining branch
**in declaration order**; the first successful conversion wins. If none succeed, throw
`RuntimeException("Cannot convert value to any union type")` after logging the schema and node at ERROR.

> The pre-fix code short-circuited on the `NULL` branch, so a non-null value against `["null","string"]`
> could be mishandled. The `continue`-on-NULL behaviour is the fix and is **currently untested** — see §10.5.

**Type conversions:**

| Avro type | Target |
|---|---|
| `ENUM` | `new GenericData.EnumSymbol(schema, text)` |
| `STRING` | `asText()` |
| `BYTES` | `ByteBuffer.wrap(asText().getBytes())` |
| `INT` | logical `date` + textual → `(int) LocalDate.parse(text).toEpochDay()`; else `asInt()` |
| `LONG` | logical `timestamp-millis` + textual → `Instant.parse(text).toEpochMilli()`; else `asLong()` |
| `FLOAT` | `(float) asDouble()` |
| `DOUBLE` | `asDouble()` |
| `BOOLEAN` | `asBoolean()` |
| `NULL` | `null` |
| `FIXED` | `new GenericData.Fixed(schema, asText().getBytes())` |
| `RECORD` | recurse into a nested `GenericData.Record` |
| anything else | `RuntimeException("Unsupported Avro type: " + type)` |

Any conversion failure at the top level is wrapped as
`RuntimeException("Failed to convert payload to Avro: " + msg, e)`.

### 7.5 `ProtobufMessageCodec` — new

New capability. Uses `protobuf-java` and `protobuf-java-util`.

**Schema source.** Protobuf has no single-file self-describing text format equivalent to `.avsc`, so the
source is a **compiled `FileDescriptorSet`** (`protoc --descriptor_set_out`), discovered by the same
filesystem and classpath sources with the pattern `classpath*:schemas/**/*.desc`. Each
`Descriptors.Descriptor` in the set becomes one subject, named by the same rule:
`descriptor.getFullName().replace('.', '_') + "-value"`.

Reasoning: parsing raw `.proto` text at runtime would mean shipping a protobuf compiler front-end. A
descriptor set is what every protobuf toolchain already produces, and it resolves imports for us.

**Validation.** `JsonFormat.parser()` in strict mode (**not** `ignoringUnknownFields()`) — an unknown field
must be a validation error, matching Avro's strictness. Catch `InvalidProtocolBufferException` and translate
its message into `ValidationError`s. Because protobuf's parser reports one problem at a time rather than
accumulating, a single error is acceptable; document the difference from Avro's error-accumulating behaviour.

**Encoding.**

```java
DynamicMessage.Builder builder = DynamicMessage.newBuilder(descriptor);
JsonFormat.parser().merge(payloadJson, builder);
return builder.build().toByteArray();
```

Plain protobuf wire bytes, no framing prefix — consistent with the Avro codec's no-magic-byte decision.

**Fake data.** Walk the `Descriptor`'s fields, reusing the same name-based heuristics from §6.9. Map
protobuf types onto the generators: `STRING`→string heuristics, `INT32`/`INT64`/`UINT*`/`SINT*`→integer
heuristics, `FLOAT`/`DOUBLE`→float heuristics, `BOOL`→boolean, `BYTES`→random bytes, `ENUM`→random value,
`MESSAGE`→recurse, `repeated`→1–4 elements, `map`→1–4 entries. Protobuf 3 has no "absent" scalar, so the
90%-populate rule applies only to `optional` fields and message fields.

**Semantic note for the spec's consumers.** Protobuf's default-value semantics differ fundamentally from
Avro's: an unset `int32` is `0`, not absent. This means the §7.4 default-value precedence has **no protobuf
analogue** — steps 2–4 collapse. Document this rather than trying to emulate Avro semantics.

### 7.6 Extracting the format seam without regressing

The extraction touches the most heavily tested code in the service. Sequence it so the tests stay green:

1. Introduce `SchemaFormat`, `SchemaDescriptor`, `MessageCodec`, `MessageCodecRegistry`.
2. Move the existing Avro validation and conversion code into `AvroMessageCodec` **verbatim** — no logic
   changes. `ValidationService` becomes a thin delegate. All 47 `ValidationServiceTest` cases must pass
   unchanged; keep them pointed at `ValidationService` so they prove the delegation.
3. Introduce `SchemaSource` and the four implementations; `SchemaService` delegates to the composite. The 25
   `SchemaServiceTest` cases must pass unchanged.
4. Add the `format` column migration and the `SchemaResponse` alias fields.
5. Only then add `ProtobufMessageCodec`, with its own test class.

---

## 8. Configuration reference

### 8.1 Properties that go away

Delete these entirely — they existed only to configure the internal libraries:

```yaml
db-core:            # whole tree: use-iam, flyway.*, entities, reader.*, writer.*, repository.groups[]
kafka:              # root-level tree: bootstrap-servers, use-iam, group-id, producer.*, consumer.*
security.protocol:  # root-level
sasl:               # root-level tree: mechanism, jaas.config, client.callback.handler.class
aws.rds:            # replaced by spring.datasource.*
spring.main.allow-bean-definition-overriding:   # only needed because db-core registered duplicate beans
spring.autoconfigure.exclude:                   # the JpaRepositoriesAutoConfiguration exclusion
spring.data.jdbc.repositories.enabled:          # vestigial
```

Also drop from `app.*`, or implement them:

| Property | Status |
|---|---|
| `app.schema-registry.enabled` / `.url` | **Never read by any code.** Vestigial from an abandoned Confluent integration. Delete. |
| `app.audit.encryption-key` | Bound but **never used** — payload encryption is not implemented. Delete, or implement it. Leaving a named-but-inert encryption key in configuration is worse than having none. |
| `aws.glue.schema-registry.*` | Only relevant to the removed Glue serde. Delete. |
| `switches.secret.manager.enabled` | `false` in every profile and read by nothing in this service. Verify and delete. |

> **Latent bug being removed.** `application-local.yml` and `application-docker.yml` point
> `db-core.entities` and `db-core.*.repositories` at packages that **do not exist** in this codebase
> (`za.co.nova.outbound.database.entity`, `…database.repository.read`, `…database.repository.write`).
> Only `application-dev.yml` names the real ones. This works by accident because the writer group also
> scans the real `za.co.nova.outbound.repository`. Moving to a single datasource removes the whole
> failure mode.

### 8.2 Datasource, JPA and Flyway

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST}:${DB_PORT:5432}/${DB_NAME}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 2
      idle-timeout: 600000        # 10 min — matches db-core's default
      max-lifetime: 840000        # 14 min — matches db-core's default
      connection-timeout: 30000
  jpa:
    open-in-view: false           # set explicitly; Boot's default of true is a known trap
    show-sql: false
    database-platform: org.hibernate.dialect.PostgreSQLDialect
    hibernate:
      ddl-auto: validate          # never create/update; Flyway owns the schema
  flyway:
    enabled: true
    baseline-on-migrate: true
    locations: classpath:db/migration
    out-of-order: false
    validate-on-migrate: true
```

`maximum-pool-size: 10` replaces db-core's split of `reader: 2` / `writer: 5`. `ddl-auto: validate` is a
deliberate tightening — the dev profile currently leaves it unset while `application-test.yml` uses
`create-drop`.

### 8.3 Kafka

```yaml
spring:
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS}
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.ByteArraySerializer
      acks: all
      properties:
        enable.idempotence: true
        delivery.timeout.ms: 30000
        max.block.ms: 10000
```

### 8.4 MSK IAM (dev / qa / prod only)

```yaml
spring:
  kafka:
    bootstrap-servers: b-1.mskclusternpr.vxqkkx.c2.kafka.af-south-1.amazonaws.com:9098
    properties:
      security.protocol: SASL_SSL
      sasl.mechanism: AWS_MSK_IAM
      sasl.jaas.config: software.amazon.msk.auth.iam.IAMLoginModule required;
      sasl.client.callback.handler.class: software.amazon.msk.auth.iam.IAMClientCallbackHandler
```

Local and docker profiles simply omit the `properties` block, which defaults to `PLAINTEXT`. No
`kafka.use-iam` boolean and no code branch — the absence of the properties *is* the switch.

Note the current `application-dev.yml` sets
`kafka.bootstrap-servers: SASL_SSL://b-1...:9098` — the `SASL_SSL://` scheme prefix is **not valid** in
`bootstrap.servers`, which expects bare `host:port`. Drop the prefix; the protocol belongs in
`security.protocol`.

### 8.5 Application properties (`app.*`)

Bound by `@ConfigurationProperties(prefix = "app")`. **These defaults are pinned by
`ApplicationPropertiesTest` and must not drift.**

| Property | Type | Default | Meaning |
|---|---|---|---|
| `app.audit.store-payload` | `boolean` | `false` | Persist `payload_json` on audit rows. **Replay requires this.** |
| `app.kafka.topic-existence-check` | `boolean` | `false` | Verify the topic exists when creating an event type |
| `app.kafka.producer-timeout` | `int` | `30000` | Blocking-send timeout, ms |
| `app.kafka.auto-create-topics.enabled` | `boolean` | `false` | Create missing topics on publish. **Local only.** |
| `app.kafka.auto-create-topics.partitions` | `int` | `1` | |
| `app.kafka.auto-create-topics.replication-factor` | `short` | `1` | |
| `app.idempotency.ttl-minutes` | `long` | `60` | Caffeine `expireAfterWrite` |
| `app.idempotency.max-size` | `long` | `10000` | Caffeine `maximumSize` |
| `app.security.enabled` | `boolean` | `true` | Selects the JWT chain or the permit-all chain |

Read via `@Value` rather than the properties class — **fold these into `ApplicationProperties` in the
rebuild** so they appear in `spring-configuration-metadata.json` and get IDE completion:

| Property | Default |
|---|---|
| `app.schema.extracted-path` | `target/extracted-schemas/schemas` |
| `app.schema.classpath-pattern` | `classpath*:schemas/**/*.avsc` |
| `app.schema.protobuf-classpath-pattern` *(new)* | `classpath*:schemas/**/*.desc` |
| `app.schema.default-format` *(new)* | `AVRO` |
| `app.cors.allowed-origins` | `http://localhost:3000,http://localhost:5173,http://localhost:4200` |
| `app.cors.allowed-methods` | `GET,POST,PUT,DELETE,OPTIONS` |
| `app.cors.allowed-headers` | `*` |
| `app.cors.allow-credentials` | `true` |
| `app.cors.max-age` | `3600` |

### 8.6 Profiles

| Profile | Purpose | Key settings |
|---|---|---|
| *(none)* | Base `application.yml` | `spring.application.name=@project.artifactId@`; config-server + Vault import (`configserver:http://config-server:8888,optional:configtree:/vault/`) activated on `!docker && !local && !test && !integration`, with `fail-fast: true`; actuator probes enabled |
| `local` | Laptop, local Postgres + Kafka | `spring.cloud.config.enabled=false`; `bootstrap-servers=${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}`; PLAINTEXT; `auto-create-topics.enabled=true`; `store-payload=true`; `security.enabled=false`; DEBUG for `za.co.nova` |
| `docker` | docker-compose | As `local` but `bootstrap-servers=localhost:29092` |
| `dev` | Deployed non-prod | MSK IAM; Aurora Postgres; `producer-timeout=15000`; `security.enabled=false`; CORS allows the dev frontend origin plus `http://localhost:4200`, methods include `PATCH`, `allow-credentials=false`; `server.port=8080` |
| `test` | Automated tests | See §10.2 |

The base `application.yml` has an unused `log.level.org.springframework.cloud.config: DEBUG` — the correct
key is `logging.level.*`. Fix or delete it.

---

## 9. Cross-cutting concerns

### 9.1 Correlation ID propagation

```java
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class CorrelationIdFilter extends OncePerRequestFilter {
    public static final String CORRELATION_ID_HEADER = "X-Correlation-Id";
    public static final String CORRELATION_ID_MDC_KEY = "correlationId";
    // ...
}
```

Behaviour:

1. Read `X-Correlation-Id` from the request.
2. If absent, empty or whitespace-only (`!StringUtils.hasText`), generate `UUID.randomUUID().toString()` —
   a **lowercase** hyphenated UUID.
3. `MDC.put("correlationId", value)`.
4. `response.setHeader("X-Correlation-Id", value)` — always echoed, generated or not.
5. Call the chain inside `try`, and `MDC.remove(...)` in `finally` — **the MDC must be cleared even when
   the chain throws**, or the value leaks to the next request on that thread.

`CorrelationIdHolder` is a thin `@Component` facade over MDC (`get`/`set`/`clear`) so services do not import
SLF4J's MDC directly and can be unit-tested with a mock.

The value reaches log output because `structuredconsole.xml` sets `includeMdc` on the `LogstashEncoder`, and
reaches Kafka as the `X-Correlation-Id` record header (§6.5).

### 9.2 Exception hierarchy

All extend `RuntimeException`, in `za.co.nova.domain.exception`:

| Exception | Constructors |
|---|---|
| `ResourceNotFoundException` | `(String message)`; `(String type, Object id)` → `"%s not found with id: %s"`; `(String type, String field, String value)` → `"%s not found with %s: %s"` |
| `DuplicateResourceException` | `(String message)`; `(String type, String field, Object value)` → `"%s with %s '%s' already exists"` |
| `SchemaValidationException` | `(String message, List<ValidationError> errors)`; `(String message)` → **`errors = List.of()`, never null**. Field is `private final transient List<ValidationError> errors` with `@Getter`. |
| `SchemaRegistryException` | `(msg)`; `(msg, cause)` — **handled but never thrown**, see §12.6 |
| `KafkaTopicException` | `(msg)`; `(msg, cause)` |
| `PublishException` | `(msg)`; `(msg, cause)` |

The `transient` on `SchemaValidationException.errors` exists because `RuntimeException` is `Serializable` and
`ValidationError` is not — a Sonar rule. Keep it.

### 9.3 Global exception handling

`@RestControllerAdvice`. Every handler builds an `ErrorResponse` with `timestamp = Instant.now()`, the
numeric `status`, `error = HttpStatus.getReasonPhrase()`, a `message`, `path =
request.getRequestURI()`, and `correlationId = MDC.get("correlationId")` (null when absent).

| Exception | Status | Message | Log |
|---|---|---|---|
| `ResourceNotFoundException` | **404** | `ex.getMessage()` | warn |
| `DuplicateResourceException` | **409** | `ex.getMessage()` | warn |
| `SchemaValidationException` | **400** | `ex.getMessage()`, plus `fieldErrors` mapped `path→field`, `message→message`, `actualValue→rejectedValue`. **`fieldErrors` is set to `null`, not an empty list, when there are no errors.** | warn |
| `SchemaRegistryException` | **502** | `"Schema Registry communication error: " + msg` | error |
| `KafkaTopicException` | **500** | `"Kafka topic operation failed: " + msg` | error |
| `PublishException` | **500** | cause-aware, see below | error |
| `MethodArgumentNotValidException` | **400** | exactly `"Validation failed"`, plus `fieldErrors` from `BindingResult.getFieldErrors()` (`field`, `defaultMessage`, `rejectedValue`) | warn |
| `IllegalArgumentException` | **400** | `ex.getMessage()` | warn |
| `Exception` (catch-all) | **500** | exactly `"An unexpected error occurred"` — **the original message is never leaked** | error |

`PublishException` message ladder, in order:

```java
String errorMessage = "Failed to publish event: " + ex.getMessage();
Throwable cause = ex.getCause();
if (cause != null) {
    if (cause instanceof java.util.concurrent.TimeoutException) {
        errorMessage = "Failed to publish event: Kafka connection timeout. Please verify that Kafka brokers "
                     + "are reachable and authentication is configured correctly.";
    } else if (cause instanceof org.apache.kafka.common.errors.TimeoutException) {
        errorMessage = "Failed to publish event: Kafka operation timed out. The broker may be unavailable "
                     + "or experiencing high load.";
    } else if (cause instanceof org.apache.kafka.common.errors.AuthenticationException) {
        errorMessage = "Failed to publish event: Kafka authentication failed. Please verify IAM credentials "
                     + "and permissions.";
    } else if (cause instanceof java.net.ConnectException || cause instanceof java.net.UnknownHostException) {
        errorMessage = "Failed to publish event: Cannot connect to Kafka broker. Please verify the broker "
                     + "address and network connectivity.";
    } else if (cause.getMessage() != null) {
        errorMessage = "Failed to publish event: " + cause.getMessage();
    }
}
```

The ordering matters: `java.util.concurrent.TimeoutException` is checked before Kafka's own
`TimeoutException` because the former is what the blocking `Future.get(timeout)` throws.

### 9.4 Idempotency cache

```java
@Bean
public Cache<String, PublishResponse> idempotencyCache(ApplicationProperties properties) {
    return Caffeine.newBuilder()
            .expireAfterWrite(properties.getIdempotency().getTtlMinutes(), TimeUnit.MINUTES)
            .maximumSize(properties.getIdempotency().getMaxSize())
            .build();
}
```

Caffeine is used **directly**, not through Spring's `Cache` abstraction, and there is no `@EnableCaching`.
Consequence: idempotency is per-JVM. With more than one replica, the same `Idempotency-Key` can publish
once per replica. See §12.4.

### 9.5 Security

`@Configuration @EnableWebSecurity @EnableMethodSecurity(prePostEnabled = true)`, with two mutually
exclusive filter chains.

**Enabled** (`app.security.enabled=true`, or absent — `matchIfMissing = true`): CSRF disabled, stateless
sessions, CORS from the shared source, OAuth2 resource server with JWT.

| Matcher | Requirement |
|---|---|
| `/actuator/health`, `/actuator/info`, `/actuator/prometheus`, `/swagger-ui/**`, `/v3/api-docs/**`, `/swagger-resources/**` | `permitAll()` |
| `/api/v1/schemas/**` | `hasAnyRole("ADMIN")` |
| `/api/v1/event-types/**` | `hasAnyRole("ADMIN")` |
| `/api/v1/events/validate`, `/api/v1/events/publish` | `hasAnyRole("ADMIN","PUBLISHER")` |
| `/api/v1/published-messages/**` | `hasAnyRole("ADMIN","PUBLISHER","VIEWER")` |
| `/api/v1/events/bulk-publish` | `hasAnyRole("ADMIN","PUBLISHER")` |
| `/api/v1/topics/**` | `GET` → `hasAnyRole("ADMIN","PUBLISHER","VIEWER")`; write methods → `hasAnyRole("ADMIN")` |
| anything else | `authenticated()` |

> **Three corrections against the current implementation**, all included above:
> 1. The rule is written against **`/api/v1/audit/**`**, a path that no longer exists — the controller moved
>    to `/api/v1/published-messages`. As written, audit search falls through to `anyRequest().authenticated()`
>    and any authenticated user can read the full publish history regardless of role.
> 2. **`/api/v1/events/bulk-publish` has no rule** — the most expensive endpoint in the service (10 000
>    messages) is merely `authenticated()`.
> 3. **`/api/v1/topics/**` has no rule** — catalogue writes are merely `authenticated()`.
>
> These are latent rather than live, because `app.security.enabled=false` in every shipped profile means the
> permit-all chain is what actually runs. That makes them easy to miss and important to fix before security
> is ever switched on.

**Disabled** (`app.security.enabled=false`): CORS, CSRF disabled, stateless, `anyRequest().permitAll()`.

`SecurityConfig` currently `@Autowired`s `ApplicationProperties` and never uses it — remove the field.

### 9.6 CORS

One `CorsConfigurationSource` registered for `/**`, shared by both chains. Comma-separated
`app.cors.allowed-origins` and `allowed-methods` are split into lists; `allowed-headers` is `List.of("*")`
when the value is `*`, else a single-element list of the raw value (**note: a comma-separated
`allowed-headers` value is *not* split** — preserve or fix deliberately). `setExposedHeaders(List.of
("X-Correlation-Id"))` so browsers can read the correlation ID back.

### 9.7 Observability

**Metrics** — Micrometer with the Prometheus registry. Three custom meters, registered in a
`@PostConstruct`:

| Meter | Type | Description |
|---|---|---|
| `publish_success_total` | Counter | Total successful publishes |
| `publish_failure_total` | Counter | Total failed publishes |
| `publish_latency_ms` | Timer | Publish latency, recorded in a `finally` so it covers failures too |

> These names are snake_case with a `_total` suffix, which is Prometheus exposition style rather than
> Micrometer's dotted convention. Micrometer's Prometheus registry would render `publish.success` as
> `publish_success_total` on its own. Renaming to `publish.success` / `publish.failure` / `publish.latency`
> would be more idiomatic, but **it changes the exported metric names** and would break dashboards and
> alerts. Keep the current names unless dashboards are migrated in the same change.

Prefer constructor-time registration over `@PostConstruct` in the rebuild — `MeterRegistry` is available as
a constructor argument, so the meters can be `final`.

**Actuator** — `management.endpoint.health.probes.enabled=true` with liveness and readiness state
indicators. Exposed and permitted: `/actuator/health`, `/actuator/info`, `/actuator/prometheus`. No custom
`HealthIndicator` exists; consider adding Kafka and database indicators.

**Logging** — `logback-spring.xml` with three profiles:

| Profile | Appender |
|---|---|
| `structuredconsole` | `jsonConsoleAppender` from `structuredconsole.xml` — `LogstashEncoder` with `includeContext` and **`includeMdc`** |
| `fluentbit` | Console + `FLUENCY` from `fluency.xml` |
| `!(structuredconsole\|fluentbit)` | Spring Boot's default console appender |

Root level `INFO`.

> **The `fluentbit` profile is broken.** It includes `fluency.xml`, which does not exist in this repository
> and is not provided by any dependency. Activating the profile fails logging initialisation. Either add the
> file or delete the profile.

---

## 10. Test specification

### 10.1 Starting position

The existing suite is **392 `@Test` methods across 29 classes**, of which roughly **70 are `@Disabled`** —
commit `5ed38be "Temporarily disable test"` disabled every controller slice, every repository slice and the
sole integration test. Two classes are empty stubs.

Two gaps are worth stating plainly:

1. **`spring-kafka-test` is already a declared dependency and is used nowhere.** There is no `@EmbeddedKafka`
   anywhere in the suite.
2. **No test has ever asserted that a record reaches a broker.** The one Testcontainers integration test
   starts a Kafka container and never publishes to it. Every Kafka assertion in the suite runs against a
   mocked `KafkaTemplate`. The serialized Avro bytes have never been verified end to end.

| Currently disabled | Tests |
|---|---|
| `controller/EventControllerTest` | 11 |
| `controller/AuditControllerTest` | 12 |
| `controller/EventTypeControllerTest` | 7 |
| `controller/SchemaControllerTest` | 9 |
| `repository/EventTypeRepositoryTest` | 11 |
| `repository/PublishRequestAuditRepositoryTest` | 13 |
| `repository/SchemaArtifactRepositoryTest` | 14 |
| `integration/EventPublisherIntegrationTest` | 11 |

**All of these must be re-enabled.** A disabled test is a requirement nobody is checking.

Delete the two empty stubs (`controller/ServiceControllerTest`, `domain/service/AuditServiceTest`) — the
latter is also a confusing duplicate of the real `service/AuditServiceTest`.

### 10.2 Test configuration

Replace the current H2-based `src/test/resources/application-test.yml` with:

```yaml
spring:
  cloud:
    config:
      enabled: false
  config:
    import: "optional:configserver:"
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
  flyway:
    enabled: true                 # was false — migrations are now exercised
  # datasource.* is supplied by @DynamicPropertySource from the Postgres container

app:
  schema:
    extracted-path: target/extracted-schemas/schemas
    classpath-pattern: classpath*:schemas/**/*.avsc
    default-format: AVRO
  audit:
    store-payload: true
  kafka:
    topic-existence-check: false
    producer-timeout: 5000        # keep short; see 10.6
  idempotency:
    ttl-minutes: 60
    max-size: 1000
  security:
    enabled: false

springdoc:
  api-docs:
    enabled: false

logging:
  level:
    root: WARN
    za.co.nova: DEBUG
```

Also delete `src/main/resources/application-test.yml`. Having a `test` profile in **both**
`src/main/resources` and `src/test/resources` is a trap — the test-classpath copy wins at test runtime, so
the main one is dead weight that looks authoritative. It even disagrees with its twin (`create-drop` versus
`none` + `schema-h2.sql`).

### 10.3 Database tests — Testcontainers PostgreSQL

Retire `src/test/resources/schema-h2.sql` and the `h2` dependency. The hand-maintained H2 schema has already
drifted: **it has no `topics` table**, so `Topic` persistence and every `TopicRepository` query method are
currently untestable, and it declares `fingerprint VARCHAR(255) NOT NULL UNIQUE` where the real migration has
no unique constraint.

A shared base class, so one container is reused across all persistence tests:

```java
@Testcontainers
@SpringBootTest
@ActiveProfiles("test")
public abstract class AbstractPostgresTest {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>("postgres:15-alpine")
                    .withDatabaseName("mockafka")
                    .withUsername("test")
                    .withPassword("test");
}
```

`@ServiceConnection` (Spring Boot 3.1+) wires `spring.datasource.*` automatically — no
`@DynamicPropertySource` boilerplate. The static field means Testcontainers reuses one container for the
whole run.

With Flyway enabled against real Postgres, these become genuinely tested for the first time:

- All four migrations actually run, including `gen_random_uuid()` and the `role` CHECK constraint.
- `JSONB` columns via `@JdbcTypeCode(SqlTypes.JSON)` — H2 mapped these to `CLOB`.
- `TIMESTAMPTZ` round-tripping of `Instant`.
- The `UNIQUE(subject, version)` and `UNIQUE(name)` constraints.
- The `topics` table and its seeded 87 rows.

Repository tests move from `@DataJpaTest` to `extends AbstractPostgresTest` with `@Transactional` for
rollback isolation. Keep every existing assertion, including:

- `findBySubjectOrderByVersionDesc` on inserts of 1, 3, 2 returns `[3, 2, 1]`.
- `findAllSubjects` is distinct **and** ordered.
- `findVersionsBySubject` is ascending.
- `existsByNameAndIdNot` is true for a *different* row with that name and false for the row's own id.
- `updatedAt` advances on update while `createdAt` does not.
- Full-field persistence round-trips, which is what catches the `key`→`message_key`,
  `partition`→`partition_number` and `offset`→`offset_value` mappings.

Add the missing coverage: `Topic` persistence, `findAllCategories`, `findAllEnvironments`, the `role` CHECK
constraint rejecting an invalid value, and the seeded row count after migration.

### 10.4 Kafka tests — `@EmbeddedKafka`

The gap that matters most. Add a real end-to-end publish test:

```java
@SpringBootTest
@ActiveProfiles("test")
@EmbeddedKafka(partitions = 1, topics = "test-publish-topic",
               bootstrapServersProperty = "spring.kafka.bootstrap-servers")
class PublishEndToEndIntegrationTest extends AbstractPostgresTest {
    // publish via MockMvc, then consume with KafkaTestUtils and assert the record
}
```

It must assert, on the record actually read back off the broker:

1. **Key** — equals `PublishRequest.key`.
2. **Value** — the exact bytes produced by `GenericDatumWriter` + a binary encoder for the same
   `GenericRecord`. Assert **byte equality**, and separately assert that the value does **not** begin with
   `0x00` — that is the guard against a Confluent wire-format prefix creeping in.
3. **Headers** — all four: `X-Correlation-Id`, `Schema-Name`, `Event-Type`, and a caller-supplied custom
   header, each decoded as UTF-8.
4. **Round-trip** — deserialize the value with `GenericDatumReader` against the same schema and assert every
   field, proving the payload survives encoding.
5. **Audit row** — a `SUCCESS` row exists in Postgres with the real `partition` and `offset` from the broker.

Add a second embedded-Kafka test for the `Event-Type` derivation contract (§6.5), asserting on the wire that
a derived header is present when the caller omitted it and that a caller-supplied one is passed through
unchanged with **no duplicate header**.

### 10.5 Required new coverage

Ordered by risk.

**a. The MOCKAFKA-16 "unmapped values" fix — currently completely untested.**

Commit `61378aa` changed default-value handling and union resolution in `convertJsonToAvro` (§7.4) and added
**no tests**. `TEST_PAYLOAD.json` at the repository root is a manual curl fixture, not a test resource. The
required cases:

| Case | Expectation |
|---|---|
| Field absent, schema has a non-null default | Default is applied and converted |
| Field explicitly `null`, schema has a non-null default | Default is applied — **not** null |
| Field absent, default is the `JsonProperties.Null` sentinel | `null` |
| Field absent, no default, union contains `null` | `null` |
| Field absent, no default, no null in union | Field unset → validation error |
| `["null","string"]` receiving `"value"` | `"value"`, the `NULL` branch skipped |
| `["null","long"]` receiving `"567"` (numeric string) | Coerced per the union branch order |
| `["int","boolean"]` receiving `{"a":1}` | `RuntimeException("Cannot convert value to any union type")` |
| The full `TEST_PAYLOAD.json` against its real schema | Converts and encodes cleanly |

Move `TEST_PAYLOAD.json` into `src/test/resources/fixtures/` and make it an actual test input.

**b. `deriveSchemaName` / `deriveEventType` direct unit tests.** Currently only exercised indirectly through
two publish tests. Cover the whole table in §6.5 including `null`, `""`, `-key` suffix and the
no-underscore case.

**c. `BulkPublishService` and `POST /api/v1/events/bulk-publish` — zero coverage today.** The
`@Min(1)`/`@Max(10000)`/`@NotBlank` rules have never been exercised. Cover: success counting, the 100-error
cap, `InterruptedException` breaking the loop and restoring the interrupt flag, `sampleKeys` capped at 10,
`randomKeys` versus `fixedKey`, `errors` being `null` rather than empty, and 400 on `numberOfMessages` of
`0` and `10001`.

**d. `FakeDataGeneratorService` — zero coverage today.** Generated payloads must validate against the
schema that produced them (a strong property test); the non-record schema rejection; both event-type
presets; dot-notation field overrides including the missing-intermediate-segment skip; logical-type
generation.

**e. `PublishRequestAuditSpecification` predicate semantics.** Fourteen existing tests assert only
`assertThat(spec).isNotNull()` — pure coverage theatre that would pass against a specification returning no
predicates at all. With real Postgres available, replace them with tests that assert *which rows come back*,
including that blank and whitespace filters are ignored and that the date bounds are inclusive.

**f. `IdempotencyCacheConfig` TTL eviction.** `PublishServiceTest` builds its own Caffeine cache, so the
configured TTL and max-size are never verified. Use a Caffeine `Ticker` to test expiry without sleeping.

**g. Kafka producer and `AdminClient` wiring.** An `@SpringBootTest` asserting the `KafkaTemplate` bean
exists with the expected serializers and that `enable.idempotence` and `acks` are set as specified.

**h. `ProtobufMessageCodec`** — a new class needs a new test class mirroring the Avro codec's coverage.

**i. `ServiceController`** — trivial, but the stub should become a real one-line test.

**j. Security.** No test covers `app.security.enabled=true`. Add a `@WebMvcTest` with
`spring-security-test`'s `jwt()` post-processor asserting the role matrix in §9.5, including the three
corrected rules.

### 10.6 Behaviour the current tests pin down

These are requirements, discovered from the test suite, that are not obvious from reading the production
code. The rebuild must preserve every one.

**Publish**

- The idempotency cache key is literally `<idempotencyKey>:<schemaSubject>`.
- A cached `SUCCESS` short-circuits completely — `kafkaTemplate.send` is **never called**.
- A failure is **not** cached, so `getIfPresent(key)` returns null after one.
- `ExecutionException` is unwrapped: `PublishException.getCause()` is the original Kafka error.
- A timeout produces `PublishException` whose message contains `"Kafka connection timeout"` and whose cause
  is `java.util.concurrent.TimeoutException`.
- With `app.audit.store-payload=false`, the saved audit's `payloadJson` is null.
- A null payload produces `IllegalArgumentException("Payload cannot be null")` even though the DTO also has
  `@NotNull`.
- A `String` payload is forwarded verbatim, not re-serialized.

**Schema**

- `resolveSchemaId` **always returns `null`** — asserted directly, not incidentally.
- `getPreloadedSchemas()` returns an immutable map; `put` throws `UnsupportedOperationException`.
- `getSubjects()` is sorted and distinct.
- Startup against a non-existent schema path must **not throw** — it logs and yields an empty map.
- An invalid schema produces `SchemaValidationException` containing `"Invalid Avro schema"`.

**Topics**

- All `AdminClient` calls use a 30-second timeout.
- `topicExists` returns `false` on interrupt, execution failure or timeout, and restores the interrupt flag.
- `ensureTopicExists` never propagates, even when `listTopics()` itself throws.
- The same topic name is checked against the broker **once** — the second call hits `verifiedTopics`.
- `listAvailableTopics` sorts by name; `categories` excludes `"other"`.
- `TopicManagementService.update` is partial on a `PUT`, and skips the duplicate check when the name is
  unchanged.
- `create` defaults `isActive` to `true` at the service layer, not only via `@Builder.Default`.
- `delete` uses `repository.delete(entity)`, not `deleteById`.

**Event types**

- `keyStrategy = FIELD` with a null **or blank** `keyField` → `IllegalArgumentException("Key field is
  required when key strategy is FIELD")`.
- `deserializeHeaders`: null or blank → empty map; invalid JSON → `RuntimeException("Failed to deserialize
  headers")`.
- `update` is a **full** replacement of every field.

**Audit and replay**

- Search sorts `createdAt DESC`; defaults are `page=0`, `size=20`.
- Replay always passes a `null` idempotency key.
- A missing or blank stored payload → `IllegalArgumentException("Cannot replay published message without
  stored payload…")` → 400.
- Read-path leniency exactly as in §6.13.

**HTTP**

- `POST /events/validate` returns **200** with `valid: false` on a validation failure.
- `POST /events/publish` returns **200**, and **400** with populated `fieldErrors` on
  `SchemaValidationException`.
- `POST /{id}/replay` with `Content-Type: application/json` and **no body** returns 200.
- `create` → 201; `delete` → 204.
- Subjects containing underscores and hyphens round-trip through path variables unchanged.
- `GET /published-messages` returns the standard Spring Data `Page` envelope.
- Exact 409 message: `"Topic with name 'existing-topic' already exists"`.
- Exact 404 messages: `"Topic not found with id: <uuid>"`, `"Topic not found with name: <name>"`.

**Errors**

- The full status table in §9.3, including 502 for `SchemaRegistryException`.
- `fieldErrors` is `null`, not `[]`, when a `SchemaValidationException` carries no errors.
- `MethodArgumentNotValidException` yields exactly `"Validation failed"`.
- The catch-all yields exactly `"An unexpected error occurred"`.
- `correlationId` is null in the body when MDC is empty.

**DTOs and entities**

- `AuditSearchRequest`: `page=0`, `size=20`. `ReplayRequest.useLatestSchema=false`.
  `EventType.keyStrategy=MANUAL`. `Topic.isActive=true`.
- `@AllArgsConstructor` parameter order is pinned: **11** for `EventType`
  (`id, name, description, topic, schemaSubject, schemaVersion, keyStrategy, keyField, defaultHeaders,
  createdAt, updatedAt`) and **17** for `PublishRequestAudit`
  (`id, eventTypeId, topic, key, headers, schemaSubject, schemaVersion, schemaId, payloadJson, status,
  errorMessage, partition, offset, correlationId, idempotencyKey, userId, createdAt`). Field **order** in
  these two classes is therefore part of the contract.

### 10.7 Test class inventory — port map

Every existing test class, what it locks in, and what to do with it. Counts are `@Test` methods.

| Test class | # | Status | What it locks in | Action |
|---|---|---|---|---|
| `service/ValidationServiceTest` | 47 | active | The entire Avro validation type-matrix and JSON→`GenericRecord` conversion (§7.4), with exact error-message substrings | **Port unchanged** against `ValidationService`, so it proves the delegation to `AvroMessageCodec`. Add the §10.5a default/union cases. |
| `service/SchemaServiceTest` | 25 | active | Subject/version resolution, `resolveSchemaId → null`, immutable preloaded map, sorted+distinct subjects, graceful missing-path startup | **Port unchanged.** Uses `ReflectionTestUtils` to point the schema paths at non-existent locations — replace that with constructor injection of a stub `SchemaSource`. |
| `service/TopicServiceTest` | 24 | active | `AdminClient` interaction: 30 s timeout, swallowed failures, interrupt-flag restoration, `verifiedTopics` caching, name parsing, `KafkaTopicException` messages | **Port unchanged.** Add a `docker-` prefix case (§12.20). |
| `service/TopicManagementServiceTest` | 22 | active | Catalogue CRUD, filter→repository routing precedence, partial-update semantics, `isActive` defaulting, duplicate-check skip on unchanged name | **Port**, adjusting for the collapsed single `TopicRepository` (§4.7). Good `@Nested` structure — keep it. |
| `service/EventTypeServiceTest` | 20 | active | CRUD, `FIELD`-without-`keyField` rejection (null **and** blank), headers JSON round-trip, full-replacement update | **Port**, replacing the `KafkaAdmin` mock with the shared `AdminClient` (§12.17). |
| `controller/TopicControllerTest` | 19 | active | All 7 topic endpoints, 201/204/404/409 codes, exact 404 and 409 message bodies, query-param→service routing | **Port unchanged.** The model for the other controller slices. |
| `exception/GlobalExceptionHandlerTest` | 18 | active | The authoritative status/message contract (§9.3) including the `PublishException` cause ladder and the non-leaking catch-all | **Port unchanged.** |
| `service/AuditServiceTest` | 18 | active | Search filters and paging, event-type enrichment with swallowed 404, replay version precedence, replay's null idempotency key, read-path leniency (§6.13) | **Port unchanged.** |
| `service/PublishServiceTest` | 16 | active | The whole publish pipeline: idempotency key format and semantics, `ExecutionException` unwrapping, timeout handling, `store-payload` behaviour, metric names, and the two MOCKAFKA-16 `Event-Type` header assertions | **Port unchanged**, but fix the 30 s runtime (§10.8). The most valuable class in the suite. |
| `repository/PublishRequestAuditSpecificationTest` | 14 | active | Nothing — all 14 assert only `isNotNull()` | **Rewrite** against real Postgres to assert which rows return (§10.5e). |
| `repository/SchemaArtifactRepositoryTest` | 14 | **disabled** | Version ordering, distinct+ordered subjects, fingerprint lookup, full-field round-trip | **Re-enable** on `AbstractPostgresTest`. |
| `repository/PublishRequestAuditRepositoryTest` | 13 | **disabled** | Derived queries, `Specification` filtering incl. inclusive date bounds, `@PrePersist`, full-field round-trip proving the three column-name mismatches | **Re-enable** on `AbstractPostgresTest`. |
| `controller/AuditControllerTest` | 12 | **disabled** | All 3 endpoints, ISO-8601 `Instant` binding, `Page` envelope, 400 on unreplayable, **200 on an absent request body** | **Re-enable.** |
| `dto/RequestDtoTest` | 12 | active | Request DTO defaults: `page=0`, `size=20`, `useLatestSchema=false` | **Port.** |
| `controller/EventControllerTest` | 11 | **disabled** | `/validate` returning **200 with `valid:false`**, `/publish` returning 200, `Idempotency-Key` forwarding, 400 on missing payload | **Re-enable.** Add the missing `/bulk-publish` cases (§10.5c). |
| `repository/EventTypeRepositoryTest` | 11 | **disabled** | `existsByNameAndIdNot` semantics, timestamp callbacks, full-field round-trip | **Re-enable** on `AbstractPostgresTest`. |
| `integration/EventPublisherIntegrationTest` | 11 | **disabled** | Event-type CRUD through real Postgres, duplicate → 409, `FIELD`-without-`keyField` → 400 | **Re-enable and repair.** Its `endpoints_shouldReturn401_whenUnauthenticated` test contradicts its own `app.security.enabled=false` property — that contradiction is likely why the class was disabled. Split it: keep the CRUD flows here, move the 401 assertions to the new security test (§10.5j). Replace its Kafka container with `@EmbeddedKafka` and **actually publish** (§10.4). |
| `exception/ExceptionClassesTest` | 11 | active | Exception message formats, and `SchemaValidationException.getErrors()` being empty rather than null | **Port.** |
| `config/ApplicationPropertiesTest` | 10 | active | Every production default in §8.5 | **Port**, extending it to the `app.schema.*` and `app.cors.*` properties once they are folded into the class. |
| `dto/ResponseDtoTest` | 10 | active | Response DTO field completeness | **Port**, extending `SchemaResponse` for the new `format`/`schemaDefinition` fields and the deprecated aliases (§5.10). |
| `controller/SchemaControllerTest` | 9 | **disabled** | All 4 schema endpoints, the `latest` vs `{version}` route case, subjects with underscores and hyphens | **Re-enable.** Add a subject literally named `latest` (§12.7). |
| `filter/CorrelationIdFilterTest` | 8 | active | Header constants, UUID generation on absent/empty/blank, response echo, MDC cleared **even when the chain throws** | **Port.** Invokes `doFilterInternal` by reflection — acceptable, or make the method package-private. |
| `filter/CorrelationIdHolderTest` | 8 | active | MDC facade behaviour | **Port.** |
| `model/EnumsTest` | 8 | active | Enum values **and ordinals** (§4.2) | **Port.** |
| `entity/EventTypeEntityTest` | 7 | active | `keyStrategy` defaulting to `MANUAL`; the 11-arg constructor order | **Port.** |
| `entity/PublishRequestAuditEntityTest` | 7 | active | The 17-arg constructor order | **Port.** |
| `controller/EventTypeControllerTest` | 7 | **disabled** | All 5 endpoints, 201/204, 400 on missing name | **Re-enable.** |
| `controller/ServiceControllerTest` | 0 | **empty stub** | Nothing | **Replace** with a real one-line test (§10.5i). |
| `domain/service/AuditServiceTest` | 0 | **empty stub** | Nothing — a confusing duplicate name | **Delete.** |
| **Total** | **392** | ~257 running, ~70 skipped | | |

### 10.8 Test hygiene

- **`PublishServiceTest` takes about 30 seconds** because one test waits out the real 30 000 ms
  `producerTimeout` on a never-completing future. Inject a short timeout (the test profile already uses
  5000 ms) or a controllable clock. A slow suite gets skipped.
- Prefer `@Nested` grouping — `TopicManagementServiceTest` and `TopicControllerTest` already do this well.
- Keep AssertJ (`assertThat`, `assertThatThrownBy`) and `@ExtendWith(MockitoExtension.class)` with
  `@Mock`/`@InjectMocks`/`ArgumentCaptor`. Use `@MockitoBean` (Boot 3.4+) in Spring slices, not the
  deprecated `@MockBean`.
- Controller slices stay `@WebMvcTest(X.class)` + `@Import({GlobalExceptionHandler.class,
  SecurityConfig.class, ApplicationProperties.class})` + `@ActiveProfiles("test")`.
- Naming: `**/*IntegrationTest` runs under failsafe, everything else under surefire. `AbstractPostgresTest`
  subclasses that are not integration tests still run under surefire — keep the container lightweight.

---

## 11. Build, container and CI/CD

### 11.1 Container

```dockerfile
FROM artifacts.nova.co.za/odin-docker-shared-local/novacorretto:25-alpine-jdk

ARG JAR_FILE=events-management-service-1.0.0-SNAPSHOT.jar
ENV JAR_FILE=$JAR_FILE

COPY target/$JAR_FILE /

USER 1000
EXPOSE 8080
ENV TZ="Africa/Johannesburg"

ENTRYPOINT exec java $JAVA_OPTS -jar /$JAR_FILE
```

Non-root (`USER 1000`), `$JAVA_OPTS` respected for heap and GC tuning, `exec` so the JVM is PID 1 and
receives `SIGTERM` for graceful shutdown.

### 11.2 CI — `.github/workflows/build-deploy.yaml`

Triggers: `workflow_dispatch`, and pull requests to `develop` / `release` / `main` (opened, synchronize,
closed) touching `src/**`, `aql/**`, `certs/**`, `Dockerfile`, `pom.xml` or `.github/workflows/*.yaml`.
Concurrency is grouped by target branch without cancel-in-progress.

| Job | Runner | Does |
|---|---|---|
| `build` | self-hosted, in `maven:3.9.11-amazoncorretto-25-al2023` | JFrog CLI setup and ping; `jf mvn-config` pointing resolve and deploy at `$JF_REPO`; Maven dependency cache keyed on a SHA-256 of the POM with the project version line stripped; `jf mvn clean install --threads 8 --build-name … --build-number $RUN`; uploads `target/site/jacoco` and `target/{classes,generated-sources}` |
| `sonarqube` | self-hosted | Downloads the coverage and binary artifacts, installs nova certs, runs `sonarsource/sonarqube-scan-action` with inline `-Dsonar.projectKey`, `-Dsonar.java.binaries=target/classes`, `-Dsonar.exclusions=src/test/java/**`, `-Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml`, then the **quality gate check** with a 600 s poll |
| `container` | self-hosted `m6i-xlarge ubuntu-22` | Downloads the JAR from Artifactory, `docker build --build-arg JAR_FILE=…`, tags `${BASE_URL}/${DOCKER_REPO}/${ARTIFACT}:${VERSION}-${SHA:0:8}`, `jf docker push`, `jf rt build-publish` |
| `deploy-dev` / `deploy-int` / `deploy-qa` / `deploy-prod` | `ubuntu-22.04`, GitHub Environments | `nova-odin/action-deploy@v7` against the external GitOps repo (Argo CD). `prod` requires `create-release` and `deploy-qa` to have succeeded. |
| `create-release` | `ubuntu-22.04` | On a merged PR on `release`, `gh release create` with generated notes plus the Docker image URI |

Note the JaCoCo report is produced by the `build` job but the quality gate runs in a **separate** job that
re-downloads it — hence the coverage-artifact upload and download. There is no `sonar-project.properties`;
all Sonar configuration is inline in the workflow. No Kubernetes or Helm manifests live in this repository —
deployment state is entirely in the GitOps repo.

### 11.3 Keeping the build decoupled from JFrog

§2.3 states the goal: JFrog is required to release, not to build. CI is where that either holds or quietly
rots, so it needs a job that proves it.

**Add a `portable-build` job** that runs on a plain GitHub-hosted runner, in a public container, with no
JFrog CLI, no `jf mvn-config` and no nova credentials:

```yaml
  portable-build:
    name: Portable Build (no Artifactory)
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '25'
          distribution: 'corretto'
          cache: maven
      - name: Assert no internal Maven dependencies
        run: |
          # The project's own groupId is the only permitted za.co.nova coordinate.
          # Deliberately avoids `grep -v -q`: that combination is NOT portable — GNU grep and
          # ugrep (common on developer macOS) return opposite exit codes for it, so the check
          # would silently invert depending on who runs it. Test string emptiness instead.
          OFFENDERS=$(grep -n 'za\.co\.nova' pom.xml \
                      | grep -v '<groupId>za.co.nova</groupId>' || true)
          if [ -n "$OFFENDERS" ]; then
            echo "::error::Internal Maven dependency reintroduced — see SPECIFICATION.md section 2.3"
            echo "$OFFENDERS"
            exit 1
          fi
      - name: Assert no repository block
        run: |
          if grep -qE '<(pluginR|r)epositories>' pom.xml; then
            echo "::error::POM must not declare repositories — see SPECIFICATION.md section 2.3.1"
            exit 1
          fi
      - name: Build and test from Maven Central only
        run: mvn -s /dev/null --batch-mode clean verify
```

Both assertions were verified against the current POM (assertion 1 correctly fails on the three
`za.co.nova.domain` coordinates) and against a POM with those dependencies stripped
(correctly passes). The `|| true` is required so the step does not abort when `grep` legitimately finds
nothing.

`-s /dev/null` is the crux: it forces Maven to ignore any `settings.xml` and fall back to its built-in
`central`. If this job passes, the decoupling is real; if it fails, something reintroduced an internal
coordinate or a repository override.

This job is **cheap and fast** (no self-hosted runner, no container credentials, warm Maven cache) and can run
on every PR. It does not replace the `build` job — that one still runs under the JFrog CLI to produce
build-info and publish the artifact. The two exist for different reasons: `build` produces the releasable
artifact, `portable-build` protects contributor experience and supply-chain optionality.

**What deliberately stays JFrog-coupled**, and the reasoning, so nobody "cleans it up" without a platform
decision:

| Item | Why it stays |
|---|---|
| `build` job's `jf mvn-config` + `jf mvn clean install` | Produces JFrog **build-info**: the dependency graph, checksums and provenance record that Xray scans and that `jf rt build-promote` acts on. Losing it loses supply-chain traceability for the released artifact. |
| `jf rt download` in the `container` job | The image is built from the *published* artifact, not a locally rebuilt one, so what ships is provably what was scanned. |
| `jf docker push` + `jf rt build-publish` | Argo CD pulls the image from this registry. The registry is the deployment interface. |
| Base image `novacorretto:25-alpine-jdk` | Almost certainly carries the corporate CA bundle, a hardening baseline and a patch cadence. Docker Hub `amazoncorretto:25-alpine` would build and run, but swapping it forfeits those and is a platform-governance call. Note the `sonarqube` job already needs a separate `nova-certs` action for exactly this reason. |
| CI build container `universal/maven:3.9.11-amazoncorretto-25-al2023` | Same reasoning. The new `portable-build` job proves a public image also works, which is the useful evidence to have *before* proposing a change here. |

**Also delete** the `aql/` directory (`spec-build.json`, `get-all-docker.json`) if it is genuinely unused —
these are JFrog AQL query specs referenced by no workflow step in the current pipeline, though `aql/**` is
still listed as a path trigger on the `pull_request` event. Either wire them up or remove both the directory
and the trigger.

### 11.4 Release — `.github/workflows/release.yaml`

`workflow_dispatch` on `develop` only. Strips `-SNAPSHOT` via
`mvn build-helper:parse-version versions:set`, creates `release-<version>`, opens a PR into `release`,
then bumps to `<major>.<nextMinor>.0-SNAPSHOT` on a `develop-<version>` branch and opens a second PR into
`develop`. It fails fast if the current version has no `-SNAPSHOT` suffix, or if the `release` branch does
not exist on the remote.

---

## 12. Known defects and migration decisions

Each item is a deliberate decision point. The rebuild must resolve each one rather than inherit it silently.

| # | Defect | Decision |
|---|---|---|
| **12.1** | `SchemaService.resolveSchemaId` always returns `null`, so `schemaId` is null in every response and audit row. The `schema_id` column is dead. | **Keep returning null, but make it honest.** Rename to `resolveExternalSchemaId` and document that local schemas have no registry ID. Do not remove the field — the frontend reads it. |
| **12.2** | `PublishRequestAudit.eventTypeId` is never populated by the publish path, so `AuditResponse.eventTypeName` is always null and the `idx_audits_event_type_id` index is unused. | **Fix or drop.** Either accept an optional `eventTypeId` on `PublishRequest` and populate it, or remove the column, the index and the enrichment lookup. Do not ship a field the UI renders as permanently blank. |
| **12.3** | Failure audits are saved inside `@Transactional` and then rolled back by the rethrow. | **Must fix.** See §6.10; removing `@Transactional` from `publish` is recommended. |
| **12.4** | Idempotency is node-local Caffeine, while the `idempotency_cache` table exists and is unused. Behind a load balancer the same key publishes once per replica. | **Decide explicitly.** Either implement database-backed idempotency using the existing table, or delete the table and document idempotency as best-effort and single-instance. Recommended: delete the table for now and document the limitation — the service is a test tool, and a distributed lock is real complexity. |
| **12.5** | `EventType.keyStrategy` and `keyField` are stored and validated but **never used at publish time**. The key always comes from `PublishRequest.key`. `KeyStrategy.FIELD` does nothing. | **Implement or remove.** `FIELD` should extract the key from the payload at the configured JSON path. If that is not wanted, delete both columns and the enum — validation that guards an unimplemented feature is worse than no feature. |
| **12.6** | `ValidateRequest` and `ValidationService.validate(ValidateRequest)` are unreachable — no controller calls them. `SchemaRegistryException` is handled but never thrown. | Delete both, or expose the event-type-driven validate path as an endpoint. Note that deleting `SchemaRegistryException` removes the only source of 502s. |
| **12.7** | `GET /{subject}/versions/latest` collides with `GET /{subject}/versions/{version}`. Resolution depends on `latest` failing to bind to `Integer`. | **Fix.** Constrain the numeric route to `/{version:\\d+}` and declare `latest` first. Add a test for a subject literally named `latest`. |
| **12.8** | `PublishAuditWriteRepository` is dead code — no `@Repository`, never injected, and its native insert references a non-existent `stack_trace` column. | Delete. |
| **12.9** | `TopicWriteRepository` is an empty interface identical in capability to `TopicReadRepository`; the read/write package split exists only for db-core. | Collapse into one `TopicRepository` (§4.7). |
| **12.10** | `BulkPublishService` runs up to 10 000 blocking sends plus optional sleeps on the HTTP request thread. A 10 000-message request with a 100 ms delay occupies a servlet thread for over 16 minutes and will hit any proxy timeout. | **Must fix.** Make it asynchronous: return **202 Accepted** with a job ID, run the batch on a bounded executor, and add `GET /api/v1/events/bulk-publish/{jobId}` for progress. If synchronous behaviour must be kept for compatibility, cap `numberOfMessages` far below 10 000 for the synchronous path. |
| **12.11** | `schema-h2.sql` has no `topics` table and adds a `UNIQUE` on `fingerprint` that the real schema lacks. | Resolved by moving to Testcontainers (§10.3). |
| **12.12** | Security rules reference `/api/v1/audit/**`, which no longer exists; `bulk-publish` and `topics/**` have no rules. | **Must fix.** See §9.5. Latent today only because security is disabled everywhere. |
| **12.13** | RDS IAM authentication disappears with db-core. The `dev` profile uses it (`db-core.use-iam: true`) with a username of `nova_iam_schema_management_dev`. | **Deployment prerequisite.** Before the rebuild reaches `dev`, either provision a password credential in Vault or add the AWS Advanced JDBC Wrapper. This is a blocking infrastructure task, not a code change — flag it early. |
| **12.14** | The `fluentbit` logback profile includes a non-existent `fluency.xml`. | Add the file or delete the profile. |
| **12.15** | `application-test.yml` exists in both `src/main/resources` and `src/test/resources`, with different contents. | Delete the `src/main` copy (§10.2). |
| **12.16** | `EventTypeController` is `@Hidden`, so a functional CRUD surface is absent from the API docs. | Remove `@Hidden` (§5.6). |
| **12.17** | `EventTypeService.validateTopicExists` creates a new `AdminClient` per call. | Inject the shared `AdminClient` bean (§3.4). |
| **12.18** | `POST /events/publish` declares `@RequestHeader("X-Correlation-Id")` and never uses it — the value comes from MDC. | Keep for documentation only, with a comment, or remove it. Do not resolve the correlation ID from two places. |
| **12.19** | The two `eventType` presets in `FakeDataGeneratorService` are repayments-specific business rules hardcoded in a generic tool. | Move to configuration (§6.9). |
| **12.20** | `TopicService.parseTopicInfo` does not recognise the `docker-` prefix that `V1.0.3` seeds. | Add `docker-` to the prefix table (§6.7). |
| **12.21** | `SecurityConfig` autowires `ApplicationProperties` and never uses it. | Remove the field. |
| **12.22** | `PublishService.parsePayload` is unused private code. | Delete. |
| **12.23** | `app.audit.encryption-key` is bound but no encryption exists. | Delete the property, or implement payload encryption. A named encryption key that encrypts nothing is a false assurance in a security review. |
| **12.24** | `aql/spec-build.json` and `aql/get-all-docker.json` are JFrog AQL query specs referenced by **no step** in either workflow, yet `aql/**` is a `pull_request` path trigger — so editing a dead file triggers a full build-and-deploy pipeline. | Delete the directory and the trigger, or wire the specs into the pipeline. |
| **12.25** | Three JFrog couplings cannot be resolved inside this repository: the `settings.xml` Maven Central proxy, the hardened base images, and the publish/deploy chain that Argo CD reads from. | **Not defects — constraints.** Recorded in §2.3.2 so they are visibly deliberate. The actionable part is §11.3's `portable-build` job, which proves the *project* does not depend on them even while the *pipeline* does. Raise the base-image question with platform engineering only once that job is green — it is the evidence the conversation needs. |
| **12.26** | Dropping `event-schema-registry` means a default local run discovers **zero** schemas, so `GET /api/v1/schemas/subjects` returns an empty list and publishing is impossible until schemas are supplied. | **Expected, but needs a usable default.** Ship the §2.3.3 fixture schemas on the `local` and `docker` profiles' classpath (or document a one-line `mvn dependency:unpack` into `app.schema.extracted-path`) so a fresh clone is immediately usable. An empty schema list on first run reads as a broken service. |

---

## Appendix A — package layout

Base package `za.co.nova`. The existing inbound/domain/outbound split is sound; keep it.

```
za.co.nova
├── Application.java                      @SpringBootApplication (no excludes)
├── controller
│   └── ServiceController                  GET /api/v1/hello
├── inbound                                everything driven from outside
│   ├── controller
│   │   ├── EventController                + EventControllerDoc (OpenAPI-only interface)
│   │   ├── AuditController
│   │   ├── EventTypeController
│   │   ├── SchemaController
│   │   ├── TopicController
│   │   └── request/                       9 request DTOs
│   └── response/                          10 response DTOs
├── domain                                 business logic, no framework leakage outward
│   ├── config
│   │   ├── ApplicationProperties          @ConfigurationProperties("app")
│   │   ├── IdempotencyCacheConfig
│   │   ├── OpenApiConfig
│   │   └── SecurityConfig
│   ├── exception                           6 exceptions + GlobalExceptionHandler
│   ├── filter                              CorrelationIdFilter, CorrelationIdHolder
│   ├── model/enums                         KeyStrategy, PublishStatus
│   ├── schema                              NEW — the format seam (§7)
│   │   ├── SchemaFormat, SchemaDescriptor
│   │   ├── SchemaSource + 4 implementations
│   │   └── codec/  MessageCodec, MessageCodecRegistry,
│   │                AvroMessageCodec, ProtobufMessageCodec
│   └── service
│       ├── PublishService                  the core pipeline
│       ├── ValidationService               thin delegate over MessageCodec
│       ├── SchemaService                   thin delegate over SchemaSource
│       ├── EventTypeService
│       ├── AuditService
│       ├── TopicService                    live Kafka via AdminClient
│       ├── TopicManagementService          database catalogue
│       ├── BulkPublishService
│       └── FakeDataGeneratorService
└── outbound                                everything driven outward
    ├── entity                              4 JPA entities
    ├── kafka/config
    │   └── KafkaProducerConfiguration      REPLACES the kafka-core ProducerConfig
    └── repository                           4 repositories + PublishRequestAuditSpecification
                                             (read/ and write/ subpackages collapsed)
```

`Application` becomes plain:

```java
@SpringBootApplication
@ConfigurationPropertiesScan
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

No `exclude = JpaRepositoriesAutoConfiguration.class`, and `@ConfigurationPropertiesScan` in place of the
bare `@EnableConfigurationProperties`. Removing the internal libraries also means the component-scan root no
longer picks up third-party `za.co.nova.domain.**` beans — the current arrangement, where two
external libraries wire themselves purely because their package prefix happens to fall under the scan root,
is fragile and worth being rid of.

---

## Appendix B — what the internal libraries did

Recorded so that no behaviour is lost by accident, and so anyone auditing the migration can check the mapping.

### B.1 `kafka-core:4.0.2`

Properties it read, all at root level with no `spring.` prefix:

| Property | Default |
|---|---|
| `kafka.bootstrap-servers` | *(required)* |
| `aws.region` | *(required)* |
| `security.protocol` | *(required)* |
| `sasl.mechanism` | *(required)* |
| `sasl.jaas.config` | *(required)* |
| `sasl.client.callback.handler.class` | *(required)* |
| `kafka.consumer.enable-auto-commit` | `true` |
| `kafka.consumer.isolation-level` | `read_uncommitted` |
| `kafka.producer.transaction-id` | `""` |
| `kafka.producer.enable-idempotence` | `true` |
| `kafka.use-iam` | `true` |
| `kafka.group-id` | `""` |
| `kafka.topic-create.topics[]` | `{name, partitions, replicas, retentionInMilliseconds}` |

`KafkaBaseProducerConfig.producerFactoryBase()` — `@ConditionalOnProperty("kafka.producer.enabled" =
"true")` — set exactly: `bootstrap.servers`; `key.serializer` = `StringSerializer`; `value.serializer` =
`ByteArraySerializer`; `transactional.id` only when non-empty; `enable.idempotence`; and, **only when
`kafka.use-iam=true`**, the four SASL properties. Nothing else — no `acks`, `retries`, `linger.ms`,
`batch.size`, `compression.type`, `max.in.flight` or `delivery.timeout.ms`. Effective behaviour was Kafka
client defaults plus `enable.idempotence=true`.

Envelope header names used by its abstract `KafkaProducer<T>` (which this service never extended):
`Correlation-Id`, `Causation-Id`, `Event-Type`, `Schema-Name`. Note the difference from this service's
`X-Correlation-Id`.

Unused by this service and requiring no replacement: `KafkaConsumer`, `KafkaConsumerWithAck`,
`KafkaSendReplyClient`, `KafkaTopicCreation`, `RecordType{AVRO,JSON,PROTOBUF,CUSTOM}`, `SerializerUtil`,
`DeserializerUtil` (including `deserializeAvroTolerant`), `ProtobufSerializerUtil`,
`ProtobufDeserializerUtil`, `KafkaInterceptor` (a `RecordInterceptor` that put `Correlation-Id`,
`Causation-Id`, `Record-Key` and `Event-Type` into MDC), `LoggingUtil`, and the resilience4j-based
`ConsumerManager` circuit breaker.

> Worth noting for §7: kafka-core already contained `ProtobufSerializerUtil` and a `RecordType.PROTOBUF`,
> so protobuf support is consistent with the platform's direction rather than a novel departure.

### B.2 `db-core:0.0.10`

Registered exactly one autoconfiguration —
`za.co.nova.domain.config.RepositoryAutoConfiguration` — and relied on component scan for the
rest.

| Property | Default | Purpose |
|---|---|---|
| `db-core.use-iam` | `true` | RDS IAM token auth versus static password |
| `db-core.entities` | — | Packages passed to `EntityManagerFactoryBuilder.packages(...)` |
| `db-core.repository.groups[].name` | — | Group label |
| `db-core.repository.groups[].repositories` | — | Packages scanned for repository interfaces |
| `db-core.repository.groups[].entityManager` | — | Bean name to inject |
| `db-core.repository.groups[].transactionManager` | — | Bean name to inject |
| `db-core.idle-timeout-minutes` | `10` | Hikari `idleTimeout` |
| `db-core.max-lifetime-minutes` | `14` | Hikari `maxLifetime` |
| `db-core.reader.maximum-pool-size` | `1` | |
| `db-core.writer.maximum-pool-size` | `1` | |
| `db-core.flyway-delay` | `2000` | Sleep for IAM token propagation before migrating |
| `aws.rds.reader.hostname` | `PLACEHOLDER` | |
| `aws.rds.writer.hostname` | `PLACEHOLDER` | |
| `aws.rds.port` | — | |
| `aws.rds.dbname` | — | |
| `aws.rds.username` | — | |
| `aws.rds.password` | `password` | |
| `aws.rds.driver-class-name` | — | |

Beans it contributed: `readerDataSource`, `readerEntityManagerFactory` (persistence unit `"read"`),
`readerTransactionManager`, `readerEntityManager`; and the writer equivalents, with `writerDataSource`
marked `@Primary`.

`RepositoryRegistrar` scanned each group's packages with a
`ClassPathScanningCandidateComponentProvider`, and for every discovered interface registered a
`RootBeanDefinition(JpaRepositoryFactoryBean.class)` with the interface as its constructor argument and
`entityManager` / `transactionManager` property values pointing at the group's named beans. This is precisely
what `@EnableJpaRepositories` does declaratively, which is why the replacement is simply to stop excluding
Boot's autoconfiguration.

`FlywayConfig` produced a `@Bean(initMethod = "migrate") Flyway` configured with
`locations("classpath:db/migration", "classpath:sql")`, `schemas("public")`, and `outOfOrder(...)`.

> Note the **second location, `classpath:sql`**, which Boot's `spring.flyway.locations` in
> `application-dev.yml` does not include. Confirm no migrations live under `classpath:sql` before switching
> to Boot's Flyway autoconfiguration — nothing in this repository uses it, but a dependency could.

### B.3 `event-schema-registry:286.0.0`

Not code. A resource-only JAR of roughly 506 KB containing **80 `.avsc` files** under
`schemas/<domain>/*.avsc`, across the domains `arrears`, `cam`, `common`, `communication`, `contracting`,
`customer`, `decisioning`, `digitaldropoff`, `drafting`, `fulfilment`, `granting`, `invoice`, `matter`,
`offers`, `payments`, `paymentproxy`, `product`, `ptp`, `repayments`, `signing`, `test`, `transaction` and
`treatments`.

Because it contains only resources, it plugs into the `ClasspathSchemaSource` (§7.2) with no code at all.
That is what makes it genuinely optional: adding or removing the dependency changes the available subjects
and nothing else.

---

*End of specification.*
