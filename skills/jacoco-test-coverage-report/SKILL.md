---
name: jacoco-test-coverage-report
description: Summarizes JaCoCo coverage, highlights low-coverage and high-risk classes, and recommends risk-based test improvements without treating coverage targets as the primary definition of quality. Use after generating a JaCoCo report when prioritizing where to strengthen tests next.
---

## Purpose
Summarize JaCoCo coverage, identify where low coverage may indicate real testing risk, and recommend the next best testing improvements.

## When to use
- After running tests and generating a JaCoCo CSV report
- When reviewing coverage or planning test improvements
- To quickly estimate coverage and prioritize test additions

## Trigger terms
- JaCoCo coverage
- coverage report
- test coverage summary
- coverage improvement
- low coverage classes
- risk-based coverage review

## Workflow
1. Generate or locate the latest JaCoCo CSV report using the repository's configured JaCoCo phase
2. Aggregate missed and covered instructions per class
3. Calculate overall coverage percentage
4. Identify low-coverage classes and classes with high missed-instruction counts
5. Distinguish business-critical or high-risk classes from trivial low-value classes
6. Recommend risk-based follow-up work, not just target chasing
7. Use the coverage-summary-template.md for reporting

## Best practices
- Use the latest JaCoCo CSV report
- Focus first on classes with 0% coverage, high missed instructions, or critical business behavior
- Treat coverage percentage as a signal, not as proof of quality
- Prefer recommending better test layering or missing scenarios over recommending tests for trivial code
- Update the summary after major test changes

## Project Markdown Guide
Follow this template for the coverage summary report:

```markdown
## **Overall Coverage Estimate**

To estimate overall coverage, sum the total instructions covered and missed for all classes:

- **Total Instructions Missed:** [number]
- **Total Instructions Covered:** [number]

**Coverage Percentage:**  
$\text{Coverage} = \frac{[\text{Covered}]}{[\text{Covered}] + [\text{Missed}]} \times 100 \approx [percentage]\%$

*This is [above/below] the current target of [target]%, but the more important question is whether low coverage appears in high-risk or business-critical areas.*

---

## **Classes Requiring Most Attention**

| Class                        | Missed | Covered | Coverage (%) |
|------------------------------|--------|---------|--------------|
| [ClassName]                  | [n]    | [n]     | [n.n]        |
| ...                          | ...    | ...     | ...          |

Use this table to highlight classes that are both low in coverage and meaningful in risk, business importance, or missed-instruction count.

---

## **Priority List for Increasing Coverage**

1. **[ClassName]** ([coverage]%)
2. **[ClassName]** ([coverage]%)
...

---

## **Next Steps**

- Focus on writing or improving tests for the classes above, starting with those at 0% coverage, those with the most missed instructions, and those that represent important business behavior.
- Prefer improvements that strengthen missing scenarios, test layering, or integration confidence rather than simply increasing line coverage.
- If low coverage reflects a broader structural problem, apply the initial Spring Boot testing framework skill to improve the test design.

---

**Summary:**  
Your current coverage is about **[percentage]%**. Use this as a prioritization signal, not as a standalone quality verdict. Prioritize the classes listed above when they combine low coverage with real business or architectural risk.

```

## References
- [JaCoCo Documentation](https://www.jacoco.org/jacoco/trunk/doc/)

## Coverage Analysis Quality Checklist

- [ ] Used latest JaCoCo CSV report
- [ ] Calculated overall coverage percentage
- [ ] Listed low-coverage and high-risk classes worth reviewing
- [ ] Sorted attention areas by missed instructions and business importance
- [ ] Highlighted classes with 0% coverage
- [ ] Distinguished meaningful testing gaps from trivial uncovered code
- [ ] Recommended actionable next steps
- [ ] Avoided treating the coverage target as the primary definition of quality
- [ ] Pointed to broader testing-framework improvements where coverage reveals structural issues
- [ ] Linked to references for further guidance
