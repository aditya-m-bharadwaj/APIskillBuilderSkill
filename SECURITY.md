# Security policy

`APIskillBuilderSkill` is a meta-skill: its output is *another* privileged tool that will hold a real API credential and call a vendor's API. The threat model here is therefore split:

- **The skill itself** (this repo) is markdown that an AI agent reads. It cannot exfiltrate anything on its own.
- **The skill's output** — projects scaffolded by following [`.claude/skills/api-skill-builder/SKILL.md`](.claude/skills/api-skill-builder/SKILL.md) — IS privileged. The safety contract that makes those projects safe lives in the skill text. Drift in the skill text is the primary risk.

## Reporting a vulnerability

If you find a defect in the skill that would cause a *generated* project to violate the safety contract — e.g. instructions that would route the token through a pipe an AI can read, classifier guidance that mis-tiers a destructive endpoint, a recipe that runs `setup` with the token in argv, etc. — please open a private security advisory on the project's GitHub repository rather than a public issue. Include:

- the specific section of the skill text at fault,
- why following the instruction violates the safety contract,
- and a proposed correction if you have one.

We aim to acknowledge within 5 business days.

## Threat model

### Defended

- **The safety contract is documented in one place.** [`.claude/skills/api-skill-builder/SKILL.md`](.claude/skills/api-skill-builder/SKILL.md) §"Hard rules" enumerates the ten invariants every generated project must satisfy. Any AI agent following the skill is told these are non-negotiable.
- **The reference implementation is named.** The skill names `linode-api-skill` as the canonical reference and explicitly says "do not invent variations of the safety contract — copy it." This minimizes the surface area for subtle drift.
- **Things-you-should-NOT-do is enumerated.** The skill carries an explicit anti-pattern list (no third-party packages, no env-var-as-primary credential, no `expect` scripts, no OAuth fanciness, no auto-classify-unknown-as-read).
- **Verifiability checklist.** The skill includes a "Safety guarantees the generated skill MUST provide" section listing exactly which `grep`s a reader can run against a generated `bin/<slug>` to verify the token doesn't leak through argv / stdout / logs / audit.

### Not defended

- **Drift between the skill and the reference implementation.** If `linode-api-skill`'s safety patterns change (e.g. new classifier tier added) and the skill text isn't updated, generated projects will follow the older pattern. Mitigation: this repo's `/save` workflow encourages explicit ADRs when contract changes are made.
- **AI agents that override the skill.** A sufficiently coerced AI agent can simply not follow the skill. Mitigation: the generated project's own `CLAUDE.md` and `SKILL.md` re-state the hard rules at runtime; a generated project is its own enforcement boundary.
- **Vendor-specific footguns the skill doesn't anticipate.** APIs with mandatory query-string auth, HMAC-signed requests with non-replayable nonces, OAuth with refresh tokens, etc. require additional design beyond what the skill specifies. The skill instructs the AI to surface conflicts rather than silently weaken the contract; correctness here depends on the operator catching it.
- **Code review of generated projects.** The skill says generated projects should be human-reviewed before being entrusted with credentials. This is operator discipline; the skill cannot enforce it.

## Hardening recommendations

If you are using this skill to bootstrap a project that will hold real credentials:

- **Read the generated `bin/<slug>` end-to-end** before running `<slug> setup`. The safety guarantees are claims the code must back up — read the code to verify.
- **Run the smoke-test recipe from Step 14** of the skill before tagging. Don't skip it.
- **Audit the generated `_BILLABLE_EXACT` / `_FINANCIAL_PREFIXES` / `_PRIVILEGE_PREFIXES`** against the vendor's pricing page. Over-cautious is safe; under-cautious is dangerous. If the AI guessed any entries, double-check them.
- **Use a minimum-scope token** for the generated project's first runs. Most vendors support per-resource scopes.
- **Enable the harness deny-rules** from `docs/settings.local.json.template` (in the generated project, not this repo) when driving the generated project from a Claude session. They mechanically block the AI from reading the keystore / config dir / calling the vendor's API with `curl` directly.

## Cryptographic notes

The skill itself performs no cryptography. Generated projects inherit `linode-api-skill`'s patterns:

- Random secrets (e.g. test-instance root passwords) use Python's `secrets.choice()` over a 70-character alphabet.
- TLS to the vendor's API is provided by the OS / Python stdlib trust store. No certificate pinning.
- No secrets are written to stdout, stderr, or the audit log.
