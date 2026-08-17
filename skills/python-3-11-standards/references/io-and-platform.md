# I/O And Platform

Use when changing files, paths, subprocesses, environment variables, platform behavior, encodings, serialization, or standard-library integrations.

## MUST

- Use context managers for file and stream lifetime.
- Specify encodings for text file I/O when data crosses machine, locale, or process boundaries.
- Treat paths as platform-sensitive; do not concatenate filesystem paths with string operators.
- Validate and constrain subprocess arguments; avoid shell interpretation unless it is explicitly required and safe.
- Keep secrets out of logs, exceptions, command lines, and serialized debug output.
- Treat `pickle`, `marshal`, and similar object deserialization as unsafe for untrusted data.

## SHOULD

- Prefer `pathlib.Path` for new path manipulation.
- Accept `str`, `bytes`, or `os.PathLike` only when the API genuinely needs that flexibility.
- Use `tempfile` for temporary files and directories.
- Use `shutil` for high-level file operations such as copying, moving, archiving, and disk usage.
- Use `json` for JSON, `csv` for CSV, and `tomllib` for reading TOML in Python 3.11.
- Use `subprocess.run(..., check=True)` for simple subprocess calls that should fail on non-zero exit.
- Use `secrets` for security-sensitive randomness and `random` only for simulation, tests, or non-security use.
- Use `urllib.parse` for URL parsing and construction instead of ad hoc string splitting.
- Use `zoneinfo` for IANA time zones when standard-library timezone support is enough.

## CONSIDER

- Use `importlib.resources` for package data instead of assuming files exist on the filesystem.
- Use `hashlib.file_digest()` for hashing file-like objects in Python 3.11.
- Use `argparse` for command-line parsing in standard-library-only programs.
- Use `logging` rather than `print` for library or long-running application diagnostics.

## AVOID

- Relying on the process current working directory when explicit paths are available.
- Using locale-dependent default encodings for persisted data.
- Using `shell=True`; pass argument lists when possible.
- Putting user-writable directories or untrusted paths ahead of trusted imports.
- Using deprecated or superseded standard-library modules in new code, such as `imp`, `optparse`, `asyncore`, `asynchat`, or `cgi`.

## NEVER

- Deserialize untrusted bytes with `pickle` or `marshal`.
- Build shell commands through string interpolation with untrusted input.
- Store credentials in source code.

## Agent Guardrails

- Do not add third-party packages for behavior the Python 3.11 standard library handles well.
- Do not choose deployment, packaging, CLI framework, or configuration-management conventions from this language skill alone.
- Preserve platform assumptions already documented by the repository.
