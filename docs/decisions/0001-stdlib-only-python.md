---
number: 0001
title: Generated CLIs use stdlib-only Python 3.8+ in a single file
status: accepted
date: 2026-05-11
---

# 0001 — Generated CLIs use stdlib-only Python 3.8+ in a single file

## Context

A `<vendor>-api-skill` CLI holds a real API credential and can spend money, delete production data, and issue new credentials. The reader of the source needs to be able to audit the *entire* tool quickly, and the install path needs to be trivial enough that operators won't disable safety steps to "just get it working."

Third-party Python packages introduce supply-chain risk (a compromised dependency runs with the same privileges as the CLI), version-skew bugs (e.g. `requests`/`urllib3` certificate-verification flips), and install friction (virtualenvs, lock files, pip cache invalidation). For a tool whose value proposition is "you can trust this with your credentials," dependencies are a liability.

## Decision

The CLI in every project this skill builds is one Python 3.8+ file using only the standard library. No `requests`, no `httpx`, no `click`/`typer`, no `pydantic`, no `keyring`, no `dotenv`.

## Consequences

- **Positive.** End-to-end audit is reading one ~1.5k LOC file. No transitive dependencies to worry about. Install is "copy one file" or a symlink. Works on any system with Python 3.8+ already installed.
- **Negative / risks.** Some patterns are more verbose (`urllib.request` vs `requests`, hand-rolled argparse vs click, manual JSON shape checks vs pydantic). Storage backends are re-implemented against the OS-native CLIs (`security` on macOS, `secret-tool` on Linux, file fallback on Windows). The author writes more code; the reader reads less *new* code.
- **Neutral / open.** Python 3.8 was the version dial chosen to maximize OS coverage (still on default macOS / older Debian). When `3.8` EOL friction outweighs the coverage benefit, this can be raised — ADR-document the change.

## Alternatives considered

- **Use `requests` for HTTP.** Saves 30 lines but adds a dependency the auditor must also trust. Rejected: `urllib.request` is enough for JSON REST.
- **Use `click` for CLI.** Nicer help output, less code. Rejected: argparse is in stdlib and the boilerplate is one-time.
- **Use `keyring` for cross-platform storage.** Convenient API but adds a non-trivial dependency tree. Rejected: re-implementing against the three OS-native CLIs is ~150 LOC and lets us refuse to read the file fallback if its mode is broader than `0600`, which `keyring` doesn't do.
- **Multi-file Python package with `setup.py`.** Standard Python idiom. Rejected for v0.1 — see [[0006-monolithic-cli-file]] for the single-file rationale.

## Related

- [[0006-monolithic-cli-file]] — why one file rather than a package.
- [[0003-cross-platform-token-storage]] — the OS-native storage layer this enables.
