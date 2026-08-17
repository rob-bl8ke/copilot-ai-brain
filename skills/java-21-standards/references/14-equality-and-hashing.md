## 14. Equality and hashing

### MUST

* Override `hashCode()` whenever `equals()` is overridden.
* Preserve the `equals()` contract.
* Avoid mutating fields involved in hashing while the object is being used as a key/set member.

### SHOULD

* Model equality according to domain semantics.
* Prefer records where their generated structural equality exactly matches the required semantics.

### AVOID

* Identity equality for value objects.
* Including volatile/mutable operational state in value equality.

### NEVER

* Override `equals()` without a compatible `hashCode()` implementation.

### Examples

**Missing `hashCode` silently breaks `HashSet` lookup**

```java
// WRONG — equals overridden without hashCode
class Point {
    int x, y;
    @Override public boolean equals(Object o) {
        if (!(o instanceof Point p)) return false;
        return x == p.x && y == p.y;
    }
    // hashCode not overridden — inherits identity hash
}
Set<Point> set = new HashSet<>();
set.add(new Point(1, 2));
set.contains(new Point(1, 2)); // false — different bucket

// CORRECT — use a record, or override both
record Point(int x, int y) {} // generates equals + hashCode
```

**Mutating a key after insertion makes the entry unreachable**

```java
// WRONG — entry becomes unreachable after key mutation
List<String> tags = new ArrayList<>(List.of("a"));
Map<List<String>, String> map = new HashMap<>();
map.put(tags, "value");
tags.add("b");   // changes tags.hashCode()
map.get(tags);   // null — entry is in the old bucket

// CORRECT — use an immutable key
map.put(List.copyOf(tags), "value");
```

