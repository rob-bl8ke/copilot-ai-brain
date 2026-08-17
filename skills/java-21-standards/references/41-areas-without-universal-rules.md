## Areas where I would deliberately not declare a universal rule

These are places where Java developers frequently turn preferences into "standards."

| Topic | Why we shouldn't dictate it |
|---|---|
| Tabs vs spaces | Formatter/project concern |
| Exact line length | Repository concern |
| Exact method length | Context dependent |
| Exact class length | Context dependent |
| Checked vs unchecked exceptions | Depends on API semantics |
| Interface for every service | Not good vanilla-Java practice |
| Every class `final` | Too absolute |
| Always use `var` | Style preference |
| Never use `var` | Equally arbitrary |
| Always use streams | Wrong |
| Never use streams | Also wrong |
| Functional vs OO | Problem dependent |
| Static factory vs constructor | Context dependent |
| Builder threshold | No universal number |
| Package-by-feature vs package-by-layer | Architectural decision |
| JPMS | Deployment/architecture decision |
| Dependency injection | Framework/application architecture |
| Specific logging library | Not vanilla Java |
| Specific testing library | Separate concern |
| Maven vs Gradle | Build concern |
| Formatting tool | Repository concern |
