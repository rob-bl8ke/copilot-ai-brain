## 29. Validation and defensive programming

### MUST

* Reject invalid inputs where accepting them would violate a contract/invariant.

### SHOULD

* Validate at boundaries.
* Fail early when an invariant cannot be maintained.
* Keep error messages useful.
* Trust already-validated internal representations where appropriate.

### AVOID

* Re-validating every internal value repeatedly.
* Silently correcting invalid data without a domain requirement.
* Defensive code that masks programming defects.

