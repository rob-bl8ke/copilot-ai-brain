## 18. Streams

### MUST

* Avoid interfering with a stream's data source during processing unless explicitly supported.
* Do not reuse an already-consumed stream.

### SHOULD

* Use streams for clear transformations, filtering and aggregation.
* Keep stream functions stateless/non-interfering where possible.
* Extract complicated pipeline operations into meaningfully named methods.

### CONSIDER

* A traditional loop whenever it is clearer.
* Primitive streams for numeric operations.

### AVOID

* Side effects inside `map`, `filter`, etc.
* Streams for deeply imperative workflows.
* Giant pipelines.
* Nested stream constructs that are difficult to reason about.
* Collecting intermediate lists unnecessarily.

### NEVER

* Treat "stream" as automatically superior to a loop.

