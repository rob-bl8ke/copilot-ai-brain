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

### Examples

**A loop is clearer when iteration is index-dependent**

```java
// HARDER TO READ — stream requires IntStream gymnastics for the index
var result = IntStream.range(0, items.size())
    .filter(i -> items.get(i).isValid())
    .mapToObj(i -> i + ": " + items.get(i).name())
    .toList();

// CLEARER — plain loop
var result = new ArrayList<String>();
for (int i = 0; i < items.size(); i++)
    if (items.get(i).isValid()) result.add(i + ": " + items.get(i).name());
```

**Side effects inside `map` break with parallel streams**

```java
// WRONG — mutation inside map; order undefined, broken when parallel
List<String> recorded = new ArrayList<>();
list.stream()
    .map(item -> { recorded.add(item.id()); return item.process(); })
    .toList();

// CORRECT — separate transformation from side effect
var results = list.stream().map(Item::process).toList();
list.forEach(item -> recorded.add(item.id()));
```

