## What should deliberately **not** live in this skill

This boundary is as important as the standards included in this skill.

| Concern                            | Better home                           |
| ---------------------------------- | ------------------------------------- |
| Core Java                          | `java-21-standards`                      |
| JUnit/Mockito detailed conventions | `java-testing-standards`              |
| JPA/Hibernate                      | `java-spring-data-jpa-standards`      |
| JDBC                               | `java-spring-jdbc-standards`          |
| Kafka                              | `java-spring-kafka-standards`         |
| REST API design                    | Possibly `java-spring-rest-standards` |
| Spring Security                    | `java-spring-security-standards`      |
| Resilience4j                       | `java-resilience-standards`           |
| OpenAPI                            | separate API skill                    |
| AWS                                | infrastructure-specific skill         |
| Kubernetes                         | deployment skill                      |
| Maven                              | `java-maven-standards`                |
| architectural style                | architecture skill                    |
| DDD                                | domain-design skill                   |

This prevents us eventually ending up with a 2,000-line "Spring skill that knows everything."
