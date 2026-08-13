# State Diagram Reference

## When to Use

- Lifecycles, state machines, or status progressions for a service, entity, or process
- Workflows where states, guards, transitions, retries, degradation, and recovery matter
- Models with composite states or nested substates that improve clarity
- Sunny-day, rainy-day, or combined lifecycle views

---

## Inlined Reference Example

```plantuml
@startuml "Service Runtime Lifecycle"

skinparam shadowing false
skinparam state {
  BackgroundColor White
  BorderColor #36536B
  FontColor #1F2D3A
  StartColor #36536B
  EndColor #36536B
}

[*] --> Stopped

state Stopped
Stopped : entry / clearRuntimeContext()
Stopped --> Starting : startRequested

state Starting {
  [*] --> DependencyChecks

  state DependencyChecks
  state ConfigurationLoad
  state Warmup
  state StartupReady
  state StartupFailed #LightPink

  DependencyChecks --> ConfigurationLoad : dependenciesAvailable
  ConfigurationLoad --> Warmup : configurationValid
  ConfigurationLoad --> StartupFailed : configurationInvalid
  Warmup --> StartupReady : warmupComplete
  StartupReady --> [*]
  StartupFailed --> [*]
}

Starting : entry / allocateResources()
Starting : do / bootstrapDependencies()
Starting : exit / publishStartupMetric()
StartupFailed : entry / recordStartupFailure()

Starting --> HealthGate : startupCompleted
Starting --> Failed : startupTimeout / openIncident()

state HealthGate <<choice>>
HealthGate --> Running : healthCheckPassed
HealthGate --> Degraded : healthCheckWarning
HealthGate --> Failed : healthCheckFailed

state Running {
  [*] --> AcceptingTraffic

  state AcceptingTraffic
  state Draining

  AcceptingTraffic --> Draining : drainRequested
  Draining --> AcceptingTraffic : drainCleared
}

Running : entry / markServiceAvailable()
Running : do / processRequests()
Running : exit / flushInFlightMetrics()

note right of Running
  Composite runtime state.
  Service can accept traffic or temporarily drain it.
end note

Running --> Degraded : dependencyLatencyHigh
Running --> Stopped : stopRequested / closeIngress()

state Degraded #LightPink
Degraded : entry / raiseWarningAlert()
Degraded : do / monitorRecoveryWindow()
Degraded : exit / resolveWarningAlert()

note right of Degraded
  Service remains available,
  but it is outside normal thresholds.
end note

Degraded --> Running : metricsRecovered [errorBudgetAvailable]
Degraded --> Retrying : dependencyUnavailable [retryBudgetAvailable]
Degraded --> Failed : dependencyUnavailable [retryBudgetExhausted]

state Retrying #LightPink
Retrying : entry / scheduleBackoff()
Retrying : do / retryDependencyCall()
Retrying : exit / cancelBackoffTimer()

Retrying --> Running : retrySucceeded
Retrying --> Failed : retryLimitReached
Retrying --> Recovering : operatorInterventionRequested

state Failed #LightPink
Failed : entry / pageOnCall()
Failed : do / awaitRecoveryDecision()

note right of Failed
  Failed is terminal for the active runtime session
  until recovery is requested.
end note

Failed --> Recovering : recoveryRequested
Failed --> Stopped : shutdownConfirmed

state Recovering #LightPink {
  [*] --> RestoringDependencies

  state RestoringDependencies
  state ValidatingState
  state RecoveryComplete
  state RecoveryRejected #LightPink
  state RecoveryDecision <<choice>>

  RestoringDependencies --> ValidatingState : dependenciesRestored
  ValidatingState --> RecoveryDecision : validationComplete
  RecoveryDecision --> RecoveryComplete : stateConsistent
  RecoveryDecision --> RecoveryRejected : stateCorrupt
  RecoveryComplete --> [*]
  RecoveryRejected --> [*]
}

Recovering : entry / restoreCriticalConnections()
Recovering : do / replayBufferedWork()
Recovering : exit / clearRecoveryFlag()
RecoveryRejected : entry / requestManualRepair()

Recovering --> Running : recoverySucceeded
Recovering --> Failed : recoveryFailed

Stopped --> [*] : serviceRetired

@enduml
```

---

## Required Modeling Rules

- Start with `@startuml "<title>"`.
- Use `[*]` for initial and final states where lifecycle entry or exit is meaningful.
- Use clear transition labels with events, triggers, outcomes, and guards when supported.
- Use `<<choice>>` only when a real decision point improves clarity.
- Use composite states only when nested substates materially improve readability.
- Attach `entry`, `do`, and `exit` actions to state names (not inside composite state blocks).
- Add concise `note right of`, `note left of`, or `note over` blocks where clarification materially helps.
- Highlight rainy-day states with `#LightPink` for failure, degradation, retry exhaustion, or recovery-required paths.
- Keep nesting shallow; avoid deep or decorative hierarchy.
- Keep state names and transition labels concrete and business-readable.

---

## Scenario Handling

| Requested | Show |
|-----------|------|
| `sunny` | Happy-path or nominal lifecycle only |
| `rainy` | Key failure, degradation, retry, timeout, compensation, or recovery paths only |
| `both` | Both nominal and exception paths |
| Not specified | Context-driven: include both if source describes important failure or recovery behavior; otherwise default to sunny |

---

## Diagram Construction Process

1. Extract the lifecycle title or synthesize a short title from the source.
2. Identify the main states, lifecycle start, and lifecycle end conditions.
3. Map the primary transitions in business order.
4. Add guards, choices, retries, degraded states, or recovery states only where supported or strongly implied.
5. Add composite states only when internal substates materially improve clarity.
6. Add notes only where they clarify state meaning, transition intent, or lifecycle constraints.
7. Keep the diagram focused on one lifecycle or one coherent state machine.

---

## Output Format Note

Output sections in this order:

```
# Diagram Script
# Steps          ← manually numbered list describing the meaningful lifecycle progression
# Short Assumptions
```

State diagrams do not support `autonumber`; number the `# Steps` list manually.
