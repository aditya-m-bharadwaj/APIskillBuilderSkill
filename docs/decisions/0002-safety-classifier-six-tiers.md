---
number: 0002
title: Every generated CLI uses a six-tier safety classifier with a required-flag matrix
status: accepted
date: 2026-05-11
---

# 0002 — Six-tier safety classifier with required-flag matrix

## Context

A REST-API CLI that lets a human (or worse, an AI agent) drive a real account needs gates against the highest-impact operations. A single `--yes` flag doesn't distinguish "I'm rebooting a Linode" from "I'm wiping the production database" — both go through the same gate. Operators have repeatedly asked for a way to make different *kinds* of mutations require *different* acknowledgments, so the gravity of an operation is visible in the command itself.

`linode-api-skill` settled on six tiers as the right granularity after iterating during the alpha. Fewer tiers conflate risks (billable vs. mutating); more tiers add friction without adding signal.

## Decision

Every project this skill builds implements the same six-tier classifier:

| Tier | When | Required flags |
| --- | --- | --- |
| `read` | Any GET | (none) |
| `mutating` | In-place change (reversible) | `--yes` |
| `destructive` | Any DELETE or non-reversible erasure | `--yes --confirm-id <last-path-segment>` |
| `billable` | Creates/clones/migrates a paid resource | `--yes --i-understand-billing` |
| `financial` | Touches payments, payment methods, invoices, promo codes, service transfers | `--yes --allow-financial` |
| `privilege` | Issues credentials or modifies users/OAuth/tokens | `--yes --allow-privilege` |

Unrecognized endpoints fall through to the strictest applicable default: GET → read, DELETE → destructive, anything else → mutating. Unknown endpoints are never auto-classified as `read`.

The CLI itself enforces the matrix at the entry to every mutating code path. The skill text in the runtime SKILL.md is for the AI's *planning* — knowing which flag corresponds to which risk so it can explain to the user what's about to happen.

## Consequences

- **Positive.** A reader of `<bin> --help <subcommand>` sees the exact gate. A reader of the runtime SKILL.md sees the matrix and can plan calls without trial-and-error. Most importantly, an AI agent that mis-guesses a tier still hits a hard refusal, not silent execution.
- **Negative / risks.** The classifier table is hand-curated. A new vendor endpoint not in the table falls through to a default, which is safe but possibly stricter than necessary. Mitigation: the skill prescribes per-vendor live smoke testing to surface mis-classifications (this is exactly what surfaced the `/firewalls` vs. `/networking/firewalls` bug in `linode-api-skill`).
- **Neutral / open.** Some endpoints are borderline (e.g. `POST /object-storage/keys` — the key itself is free but it issues a credential, so privilege might be a better tier than billable). Per-vendor ADRs document any non-obvious tier choices.

## Alternatives considered

- **Single `--yes` flag for all mutations.** Rejected: doesn't distinguish "reboot" from "drop the account." Operators asked for granularity.
- **Three tiers (read / mutating / destructive).** Rejected: collapses billing and privilege concerns into one bucket, hiding gravity.
- **YAML-defined classifier loaded at runtime.** Rejected: introduces a config-file dependency that an attacker could tamper with. The classifier lives in code, audited together with the rest of the CLI.

## Related

- [[0006-monolithic-cli-file]] — keeping the classifier in the same file the operator reads.
- Reference implementation: `linode-api-skill/bin/linode-api-skill` lines ~620–740.
