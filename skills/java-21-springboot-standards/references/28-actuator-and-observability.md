## 28. Actuator and observability

### SHOULD

For production applications, consider Spring Boot Actuator for standardized health, metrics, diagnostics and operational integration.

### MUST

Treat exposed management endpoints as an operational/security surface.

### AVOID

* Exposing every actuator endpoint publicly.
* Writing custom health mechanisms where standard indicators already solve the need.
* Mixing operational health logic into controllers.

This is firmly Spring Boot-specific.
