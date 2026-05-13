---
number: 0003
title: Cross-platform token storage uses OS-native CLIs with a mode-0600 file fallback
status: accepted
date: 2026-05-11
---

# 0003 — Cross-platform token storage uses OS-native CLIs with a mode-0600 file fallback

## Context

Every project this skill builds holds an API credential at rest. Where to store it is a security-critical decision and a portability headache: each major OS has a different "the right place for secrets" answer (Keychain on macOS, Secret Service / libsecret on Linux, DPAPI / Credential Manager on Windows), and they're all accessed by different APIs.

The Python ecosystem solution is `keyring`, which abstracts these. But `keyring` is a non-trivial dependency tree (12+ transitive packages on a fresh install) and violates [[0001-stdlib-only-python]].

## Decision

The CLI's storage layer talks directly to the OS-native CLIs:

- **macOS:** `security add-generic-password -U -s <slug> -a <user> -w <token>` (read with `security find-generic-password -s <slug> -a <user> -w`). The `-U` flag updates in place rather than delete-then-add, avoiding a race where another process could read between operations.
- **Linux:** `secret-tool store --label '<slug>' service <slug>` and `secret-tool lookup`. Falls through to file fallback if `secret-tool` is not installed (informational message; user is told how to install `libsecret-tools`).
- **Windows / fallback:** file at `~/.<slug>/token`, mode `0600`. **The CLI refuses to read the file if its POSIX mode is broader than `0600`** (group or world read). On Windows, the install script applies an `icacls`-locked-down ACL.

For multi-part credentials (e.g. Porkbun's `apikey` + `secretapikey`), the pair is serialized as one JSON blob before storage. Each backend stays single-string. The CLI decodes inside the request layer; the rest of the code sees one opaque string.

A `--file` flag forces the file backend and evicts any pre-existing keystore entry to make the file the single source of truth.

## Consequences

- **Positive.** The strongest available secret store is used per OS. Re-implementing against the CLIs is ~150 LOC and lets us add safety beyond what `keyring` offers (the mode-0600 file-permission refusal). No supply-chain risk.
- **Negative / risks.** On macOS, `security` requires the token in argv during `add-generic-password`. Same-user `ps` can observe it for the lifetime of one subprocess call. Same-user attackers already have keychain access; this is documented as not-defended in `SECURITY.md`.
- **Neutral / open.** When new OS-native APIs emerge (e.g. macOS DataVault, Linux keyutils kernel keyring), this ADR can be revisited.

## Alternatives considered

- **`keyring` Python package.** Convenient but violates stdlib-only. Also doesn't enforce the mode-0600 file-permission check.
- **File-only storage.** Simpler but weaker — same-user file read is the only barrier. Rejected: when OS-native is available, use it.
- **Encrypted file with a password.** Adds a "remember a passphrase" UX layer. Rejected: punts the storage problem to user discipline.
- **Environment variable (`<VENDOR>_TOKEN`).** Trivial leak via `env` / `printenv` / process inspection. Rejected as *primary* path; supported only as a documented escape hatch for the operator who explicitly opts in.

## Related

- [[0001-stdlib-only-python]] — why we can't just use `keyring`.
- [[0004-ai-safe-token-entry-gui-dialog]] — the entry path that writes into these stores.
