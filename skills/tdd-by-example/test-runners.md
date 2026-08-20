# Test runner reference by ecosystem

Detect which of these applies from existing project files before choosing one. If none exist yet and the project needs one, pick the ecosystem-standard default rather than a less common alternative, and say which one you picked.

## Python
- Detect: `pytest.ini`, `pyproject.toml` with `[tool.pytest...]`, `conftest.py`, or existing `test_*.py` files.
- Default framework: `pytest`.
- Run one test: `pytest -k <test_name_substring>` or `pytest path/to/test_file.py::test_name`.
- Run full suite: `pytest`.
- Convention: files named `test_*.py` or `*_test.py`; functions named `test_*`; `assert` statements (pytest rewrites them for good failure messages — no need for `self.assertEqual`).

## JavaScript / TypeScript
- Detect: `jest.config.*`, `vitest.config.*`, a `"test"` script in `package.json`, or existing `*.test.js`/`*.spec.ts` files.
- Default framework: whatever `package.json` already uses; if none, `vitest` for new projects (fast, ESM-native) or `jest` if the project looks CRA/older-style.
- Run one test: `npx vitest run -t "<test name>"` or `npx jest -t "<test name>"`.
- Run full suite: `npm test` or `npx vitest run` / `npx jest`.
- Convention: `describe`/`it` or `test` blocks; `expect(x).toBe(y)` style assertions.

## Java
- Detect: `pom.xml` (Maven) or `build.gradle` (Gradle); test files under `src/test/java`.
- Default framework: JUnit 5 (`org.junit.jupiter`).
- Run one test: `mvn test -Dtest=ClassName#methodName` or `gradle test --tests "ClassName.methodName"`.
- Run full suite: `mvn test` or `gradle test`.
- Convention: `@Test` annotated methods; `assertEquals(expected, actual)` (note argument order: expected first).

## Go
- Detect: `go.mod`; existing `*_test.go` files.
- Framework: built-in `testing` package (idiomatic Go avoids third-party test frameworks unless the project already uses one, e.g. `testify`).
- Run one test: `go test -run TestName ./...`.
- Run full suite: `go test ./...`.
- Convention: functions named `TestXxx(t *testing.T)`; `t.Errorf`/`t.Fatalf` for failures; table-driven tests are idiomatic once triangulating multiple cases.

## Rust
- Detect: `Cargo.toml`.
- Framework: built-in `#[test]` support via `cargo test`.
- Run one test: `cargo test test_name`.
- Run full suite: `cargo test`.
- Convention: `#[test]` attribute on functions inside a `#[cfg(test)] mod tests`; `assert_eq!(actual, expected)`.

## Ruby
- Detect: `Gemfile` with `rspec`, or `spec/` directory.
- Default framework: RSpec.
- Run one test: `bundle exec rspec spec/path_spec.rb -e "example description"`.
- Run full suite: `bundle exec rspec`.
- Convention: `describe`/`it` blocks; `expect(actual).to eq(expected)`.

## General fallback
If the language or framework isn't listed here, look for a `Makefile`, `justfile`, CI config (`.github/workflows/*.yml`), or README testing section — these usually reveal the intended command even when no test files exist yet.
