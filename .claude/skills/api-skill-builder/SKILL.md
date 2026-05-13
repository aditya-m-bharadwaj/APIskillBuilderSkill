---
name: api-skill-builder
description: Bootstrap a new "<vendor>-api-skill" project — a safe, cross-platform single-file Python CLI that mediates a third-party REST API, plus a matching Claude skill that drives it under explicit AI-safety constraints (token never enters AI context; every mutation passes through a six-tier safety classifier; every mutation is recorded in a local audit log). Trigger when the user asks to "build a CLI / skill for <some API>", "wrap the <X> API safely", or to mirror the linode-api-skill pattern for a new vendor.
---

# API Skill Builder — bootstrap a vendor-API CLI + Claude skill with AI-safety baked in

This skill takes you from "I want to drive the &lt;X&gt; REST API safely from a Claude session" to a published alpha that:

- never lets the AI read the API credential,
- classifies every endpoint into a six-tier risk taxonomy and refuses to send a mutation without the matching operator-supplied flag,
- stores the credential in the strongest OS-native secret store available, with file fallback at mode `0600`,
- writes an append-only audit log of every mutation,
- ships with cross-platform installers, MIT license, full doc set, CI, issue/discussion templates, and a tracked project-memory layer.

The canonical reference implementation is **`linode-api-skill`** at <https://github.com/aditya-m-bharadwaj/linode-api-skill>. Whenever this skill says "mirror the pattern", read the corresponding file there and adapt it. Do not invent variations of the safety contract — copy it.

## Hard rules (non-negotiable for every generated skill)

When you generate a new `<vendor>-api-skill` repo, the resulting tool MUST satisfy all of these. If a target API makes one of them impossible (e.g. mandatory query-string auth), surface the conflict to the operator and stop — do not silently weaken the contract.

1. **The API credential never enters the AI's context.** Not via env, not via `cat`, not via argv, not via dialog stdout the AI can see. Entry path is `<bin> setup` (TTY-only, hidden prompt) or `<bin> gui-setup` (native OS password dialog, AI-runnable but renders out-of-band of any pipe the AI reads).
2. **Storage is OS-native first, file fallback at mode `0600` only.** macOS Keychain → Linux Secret Service (libsecret) → file at `~/.<vendor>-api-skill/token` (mode `0600`, refuses to read if broader). Single-string-secret backends only — if the vendor uses a key+secret pair, store the pair as one URL-encoded or JSON blob in one keystore entry.
3. **Verify before store.** A new credential is validated against a known-good read endpoint (`whoami`-equivalent for the API) BEFORE replacing whatever is already in the keystore. A bad credential never overwrites a working one.
4. **Six-tier safety classifier with required-flag matrix.** Every mutation passes through `classify(method, path)` which returns one of: `read`, `mutating`, `destructive`, `billable`, `financial`, `privilege`. The CLI itself enforces the required flags; the matrix is the same as `linode-api-skill`'s. Unrecognized endpoints fall through to the strictest applicable default (GET → read, DELETE → destructive, anything else → mutating).
5. **Append-only audit log of every mutation.** `~/.<vendor>-api-skill/audit.log`, mode `0600`, one JSON line per mutation, with timestamp / user / action / target / parameter metadata — **never** the token, never request body values, never generated secrets.
6. **Path / argument hardening.** Validate paths against a tight regex; reject `..`/`.` traversal segments and URL-encoded `%`-sequences pre-classification. Refuse `--body @file` paths that resolve inside the config dir. Strip a leading API-version prefix (e.g. `/v4`, `/v3`) at the boundary if the docs canonically include it.
7. **Stdlib-only Python, single file.** `bin/<vendor>-api-skill` is one Python 3.8+ file using only the stdlib. No `requests`, no `click`, no `pydantic`, no `keyring`. This eliminates supply-chain risk on a privileged tool.
8. **Every mutation needs human confirmation in chat AND the machine `--yes` flag.** `--yes` alone is never enough; the AI must obtain explicit human confirmation in chat before sending.
9. **MIT license, AI-authorship disclosure, commit-trailer convention.** `AUTHORS.md` discloses the model that wrote the code. Commits carry `Prompted-By: <operator>` + `Co-Authored-By: <model>` trailers. See `linode-api-skill/CONTRIBUTING.md` for the exact format.
10. **Threat model documented.** `SECURITY.md` lists what the tool defends and what it does NOT defend; reporting goes through GitHub private security advisories.

## The build process

Follow these steps in order. Do not skip "in-flight" steps to land a partial alpha — the safety contract is most useful when complete.

### Step 0 — Confirm scope with the operator

Before writing code, agree on:

- **API name and slug.** Slug is `<vendor>-api-skill` (kebab-case, no doubling). Used as the binary name, repo name, and Claude skill `name:` field.
- **Auth model.** Bearer token? `apikey` + `secret` pair? OAuth? HMAC-signed requests? This shapes the token storage and `gui-setup` flow.
- **API base URL and version.** e.g. `https://api.linode.com/v4`, `https://api.porkbun.com/api/json/v3`, etc. Note whether the canonical docs paths include the version segment (you'll want to strip it at the boundary if so — see `_strip_v4` in `linode-api-skill`).
- **The "billable" endpoints.** Which paths cost real money when called? Get a list from the operator or the vendor's pricing page. These are the ones that need `--i-understand-billing`.
- **The "financial" and "privilege" prefixes** (if any). Some APIs don't have these tiers — that's fine; leave the prefix lists empty.

### Step 1 — Init the repo

```
mkdir ~/Code/<slug>
cd ~/Code/<slug>
git init -b main
```

Drop in the LICENSE (MIT, copyright "<slug> contributors"), `.gitignore` (mirror `linode-api-skill`), and the dir skeleton:

```
.claude/
├── skills/<slug>/SKILL.md        ← the runtime skill (will be authored after the CLI exists)
├── commands/{resume,save}.md     ← project-level slash commands
└── settings.json                 ← graphify PreToolUse hook (installed by `graphify claude install`)

.github/
├── workflows/ci.yml
├── ISSUE_TEMPLATE/{bug_report,feature_request,config}.{md,yml}
├── DISCUSSION_TEMPLATE/{q-and-a,ideas,show-and-tell}.yml
└── FUNDING.yml

bin/<slug>                        ← the CLI (Python 3.8+, stdlib only)
tests/test_classify.py            ← offline classifier tests
docs/
├── README.md
├── progress/{TEMPLATE.md,YYYY-MM-DD-initial-alpha.md}
├── decisions/{TEMPLATE.md,NNNN-*.md}
└── settings.local.json.template  ← harness deny-rules template

install.sh
install.ps1

AUTHORS.md
CHANGELOG.md
CLAUDE.md
CONTRIBUTING.md
LICENSE
README.md
SECURITY.md
```

### Step 2 — Design the safety classifier

Author the classifier table in `bin/<slug>` with five collections (mirror `linode-api-skill` line ~620+):

- `_FINANCIAL_PREFIXES` — tuple of path prefixes under which any non-GET is `financial`. Leave empty `()` if the API has no money-movement endpoints.
- `_PRIVILEGE_PREFIXES` — tuple of path prefixes under which any non-GET is `privilege` (token/user/oauth management).
- `_BILLABLE_EXACT` — set of `(METHOD, normalized_path)` tuples that allocate a paid resource.
- `_MUTATING_EXACT` — set of `(METHOD, normalized_path)` for explicitly-mutating-but-free endpoints (clearer than relying on the default).
- `_DESTRUCTIVE_EXACT` — optional, for non-DELETE destructive endpoints (e.g. `POST /…/disable`).

Implement `_normalize_path(path)` — strips the API-version prefix if applicable, then maps numeric segments to `{id}` for table lookup. Implement `classify(method, path)` returning `(tier, [required_flags], explanation)`.

**Test the classifier offline** for every entry. Cross-check each `_BILLABLE_EXACT` entry against the vendor's pricing page — over-cautious is safe; under-cautious is dangerous.

### Step 3 — Implement token storage

Mirror the storage layer from `linode-api-skill` (look for `_kc_get_macos`, `_kc_set_macos`, `_kc_get_linux`, `_file_get`, `_file_set`):

- macOS: `security add-generic-password -U` (in-place update, no delete-then-add race).
- Linux: `secret-tool store` / `secret-tool lookup` (libsecret). Falls through to file if not present.
- Windows / fallback: file at `~/.<slug>/token`, mode `0600`. **Refuse to read** if POSIX mode is broader than `0600`.

For multi-part credentials (apikey + secret), serialize as one JSON blob before storage so each backend stays a single-string store. Encode/decode at the boundary; the rest of the CLI sees one opaque string and decodes inside `_request`.

### Step 4 — Implement `gui-setup` and `setup`

- `setup` reads via `getpass` (hidden prompt) from a TTY. AI agents cannot run this. The install script's `curl … | sh` invocation re-attaches stdin to `/dev/tty` so it still works when invoked through a pipe.
- `gui-setup` pops a native OS password dialog:
  - macOS: `osascript` with `display dialog "..." with hidden answer`.
  - Linux: try `zenity --password`, fall back to `kdialog --password`.
  - Windows: PowerShell `Get-Credential` (returns a `SecureString`; convert to plain inside the PS one-liner and emit to stdout).
- The dialog process's stdout is captured into Python memory via `subprocess.run(..., capture_output=True)`. The token bytes never re-enter stdout that any pipe / observer can see.
- Validate the captured token by calling the API's `whoami`-equivalent BEFORE writing it to the keystore (Step 3 contract).
- On rotation: tell the user to revoke the old token at the vendor's dashboard. **Local replacement does not invalidate the old token server-side.**

### Step 5 — Implement named commands + generic `api` gateway

- **Named commands** for the most common, highest-value workflows. For a domain registrar (Porkbun), this is `domains`, `dns-list <domain>`, `dns-create`, `dns-delete <id> --confirm-id`, `pricing`, etc. Each named command performs the classification check inline and audits on success.
- **Generic `api` command** for full API coverage: `<slug> api <METHOD> <path> [--data …] [--body @file] [--query k=v] [--paginate] [--dry-run] [--json] [--yes] [--confirm-id …] [--i-understand-billing] [--allow-financial] [--allow-privilege]`. Filter out `Authorization`-header overrides in `--header`-style flags. Refuse `--body @file` paths that resolve inside the config dir.
- Audit-log every non-read call after success (or after a 4xx that did mutation work).

### Step 6 — Write tests

`tests/test_classify.py` loads `bin/<slug>` via `importlib.machinery.SourceFileLoader` (no install needed) and exercises:

- One test per `_BILLABLE_EXACT` / `_FINANCIAL_PREFIXES` / `_PRIVILEGE_PREFIXES` entry — assert classification and flags.
- `_normalize_path`: numeric segments → `{id}`, string segments preserved, version-prefix stripping, edge cases (`/v40/foo` and `/foo/v4/bar` should NOT be stripped).
- `_validate_path`: traversal rejection, URL-encoded `%` rejection, ASCII path-char whitelist.
- Method case-insensitivity.
- Default fallback: unknown GET → read, unknown DELETE → destructive, anything else → mutating.
- Platform helpers (`_has_display`, `_platform`).

Aim for ≥25 tests; ≥30 once you've covered all classifier-table entries.

### Step 7 — Author the runtime SKILL.md

Author `.claude/skills/<slug>/SKILL.md`. Use `linode-api-skill/.claude/skills/linode-api-skill/SKILL.md` as the template. Sections to mirror:

- Frontmatter (`name`, `description`).
- Hard rules.
- How the safety classifier works (the same six-tier table).
- Named commands table.
- Generic `api` gateway examples for each tier.
- Resource-category checklist (one row per major API category — what to confirm with the user before calling).
- Token management workflows (add, rotate, remove, diagnose).
- Workflow recipes (the 4–8 most common multi-step operations for this vendor).
- Things you should NOT do.
- When something goes wrong (error → action table).

### Step 8 — Author the supporting docs

For each, copy the corresponding file from `linode-api-skill` and rewrite for the new vendor:

- `README.md` — install one-liners, token management, classifier reference, common workflows, file map, uninstall. Status banner at top: `Status: v0.1.0-alpha.1`.
- `AUTHORS.md` — AI-authorship attribution + AI-generated-code disclaimer.
- `SECURITY.md` — threat model: defended vs. not-defended, hardening recommendations, private-advisory reporting link.
- `CONTRIBUTING.md` — stdlib-only rule, classifier-extension procedure, test pattern, full commit-message format (Prompted-By + Co-Authored-By trailers).
- `CHANGELOG.md` — one `[0.1.0-alpha.1]` entry describing the alpha; future work goes under `[Unreleased]`.
- `CLAUDE.md` — project-level hard rules for any AI agent in the repo. Defers to `.claude/skills/<slug>/SKILL.md` as authoritative.

### Step 9 — `.github/` metadata

Copy from `linode-api-skill/.github/`:

- `workflows/ci.yml` — 3 OS × Python 3.8–3.12 matrix (exclude macOS 3.8/3.9 — runner images don't ship them). Steps: `py_compile`, `unittest discover tests`, smoke `<slug> classify` on a read and a destructive path. Separate `shellcheck install.sh` job on Ubuntu.
- `ISSUE_TEMPLATE/{bug_report,feature_request}.md` and `config.yml` — `config.yml` disables blank issues and points contact links at the private security advisory page, `SECURITY.md`, and Discussions.
- `DISCUSSION_TEMPLATE/{q-and-a,ideas,show-and-tell}.yml`.
- `FUNDING.yml` — fill in `github: [<operator-username>]`; comment out the rest.

### Step 10 — Memory layer

Set up the same `docs/` layer that `linode-api-skill` uses:

- `docs/README.md` — human-facing index of the memory layer.
- `docs/progress/TEMPLATE.md` and `docs/progress/YYYY-MM-DD-initial-alpha.md` — seed entry covering this scaffolding session.
- `docs/decisions/TEMPLATE.md` and ADRs `0001-N`. At minimum write:
  - `0001-stdlib-only-python.md` — why no requests/click/keyring.
  - `0002-safety-classifier-six-tiers.md` — the tier taxonomy.
  - `0003-cross-platform-token-storage.md` — backend selection.
  - `0004-ai-safe-token-entry-gui-dialog.md` — the out-of-band entry pattern.
  - `0005-prompted-by-trailer-convention.md` — commit-trailer rationale.
  - `0006-monolithic-cli-file.md` — single-file rationale.
  - `0007-versioning-semver.md` — SemVer with `-alpha.N`.
  - One ADR per vendor-specific decision (auth flow, version-prefix, billable-list source).
- `docs/settings.local.json.template` — harness deny-rules template using `~/` paths (NOT `/Users/<operator>`).

### Step 11 — Project-level slash commands + graphify

- `.claude/commands/resume.md` — reads `docs/progress/` (most recent), `graphify-out/GRAPH_REPORT.md`, three most recent `docs/decisions/`. Adapt from `linode-api-skill/.claude/commands/resume.md`.
- `.claude/commands/save.md` — writes a new `docs/progress/YYYY-MM-DD-<slug>.md`, optionally creates an ADR, routes reusable cross-project concepts to `~/.claude/vault/zettel/concepts/`. Adapt from `linode-api-skill/.claude/commands/save.md`.
- After at least one code file exists, run `graphify update .` once to populate `graphify-out/`. Install the post-commit hook: `graphify hook install`. Install the Claude PreToolUse hook: `graphify claude install` (writes `.claude/settings.json`).

### Step 12 — Install scripts

- `install.sh` (POSIX) — verify Python 3.8+, clone the repo (or use existing checkout), symlink `bin/<slug>` into `${LINODE_CTL_PREFIX:-~/.local/bin}` (rename the env var to match the vendor slug). Optionally install the Claude skill into `~/.claude/skills/<slug>/`. Re-attach stdin to `/dev/tty` for the optional immediate-setup prompt so `curl … | sh` still works.
- `install.ps1` (Windows) — Python check, `.cmd` shim on `PATH`, `icacls`-locked-down ACL for the file fallback if used.
- Verify with `shellcheck install.sh` before commit.

### Step 13 — Initial commit

One commit with the entire alpha. Subject form: `feat: initial public alpha (v0.1.0-alpha.1)`. Body: 1-sentence summary + bullet list of every major surface (CLI commands, classifier tiers, storage backends, install scripts, skill, docs). Trailers:

```
Prompted-By: <operator name> <operator email>      # from `git config user.name`/`user.email`
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>   # actual model id you are running as
```

**Do NOT** bypass hooks (`--no-verify`, `--no-gpg-sign`). **Do NOT** commit if the operator has not explicitly told you to — draft the message and stop.

### Step 14 — Live smoke test (if a token is available)

If the operator provides a scoped test credential, exercise the alpha end-to-end before declaring v0.1 done:

1. Install via the published `curl … | sh` one-liner against a *sandbox prefix* (`LINODE_CTL_PREFIX=/tmp/...`-style) so you don't pollute the operator's real install.
2. `<slug> gui-setup` via the OS dialog. Confirm `whoami` works.
3. Inventory all existing resources and **record them** so you can verify nothing got touched.
4. Exercise one workflow per tier:
   - `read` — list a resource type.
   - `mutating` — a reversible change (e.g. toggle a setting).
   - `destructive` — delete a test-tagged resource only.
   - `billable` — create the cheapest possible resource, tagged for cleanup.
   - `financial` / `privilege` — `--dry-run` only, do not actually call.
5. Verify the safety contract: try a billable call without `--i-understand-billing` (expect refusal); try a destructive call with mismatched `--confirm-id` (expect refusal).
6. Clean up all test-tagged resources via the named cleanup command.
7. Confirm pre-existing resources are untouched.
8. Review the audit log — every mutation should appear, no secrets should appear.

Any defects surfaced by the smoke test are blockers for v0.1, not follow-up issues. Land the fixes (with tests and the corresponding CHANGELOG / SKILL.md / docs updates **in the same commit**) before tagging.

## Safety guarantees the generated skill MUST provide

A reader looking at the generated repo for the first time should be able to verify the following by reading the code, with no external trust:

- The token is **never** in argv. Search `bin/<slug>` for the token variable name — it should only appear in: storage read/write helpers, the `Authorization` header construction, and the verify-before-store call.
- The token is **never** in stdout / stderr / log files / audit entries. Search for the token variable name in `print`, `_emit`, `_audit`, `logger`, etc. — should appear in none.
- The OS-dialog stdout is captured into Python memory by `subprocess.run(..., capture_output=True)` and never re-printed. The CLI prints success metadata (`Authenticated as: <username>`) and nothing else from that call.
- Every mutation is guarded by an `if not args.yes: raise CtlError(...)` check OR the generic `api` command's flag-check loop. There are no code paths that POST/PUT/PATCH/DELETE without classification + flag gating.
- The audit log only records body *keys* for generic `api` calls — not values. Grep `_audit(...)` calls; the only `body_keys=...` shape is keys-only.

## Things you should NOT do

- **Do not** import third-party Python packages. Stdlib only. Even `keyring` is out — the CLI's storage layer is intentionally re-implemented against the OS-native CLIs (`security`, `secret-tool`, `cmdkey`).
- **Do not** support an `LINODE_TOKEN`-style environment variable as the *primary* credential path. The operator can opt-in via documented escape hatches, but the default is keystore-only.
- **Do not** invent a "lighter" safety classifier with fewer tiers because the target API "seems mostly free". Even free APIs have privilege escalation (issuing scoped tokens), and the tier system is the operator's mental model — don't change it across vendors.
- **Do not** add a fancy interactive prompt for token entry beyond `setup` (TTY) and `gui-setup` (OS dialog). No browser-based OAuth flows, no QR codes, no `expect` scripts. The TTY/dialog out-of-band requirement is the contract.
- **Do not** auto-classify unrecognized endpoints as `read`. The default fallback for non-GET is `mutating`; for DELETE, `destructive`. Conservative is correct.
- **Do not** publish to PyPI yet. The default install path is the one-liner `curl … | sh` from raw.githubusercontent.com, which can't smuggle in a dependency. If PyPI publishing is added later, switch the version string to PEP 440 (`0.1.0a1` instead of `0.1.0-alpha.1`).
- **Do not** create the generated repo as a "monorepo" of multiple vendors. One vendor = one repo. The skill is independent per vendor; cross-vendor sharing happens at the doc level (this skill).

## Reference implementation

<https://github.com/aditya-m-bharadwaj/linode-api-skill> is the canonical implementation. When in doubt, read the corresponding file there. Specifically:

| Concern | File |
| --- | --- |
| Safety classifier | `bin/linode-api-skill` lines ~620–740 |
| Token storage | `bin/linode-api-skill` `_kc_*` and `_file_*` helpers |
| GUI dialog | `bin/linode-api-skill` `_has_display`, `_prompt_token_gui`, `_confirm_gui` |
| Audit log | `bin/linode-api-skill` `_audit` |
| Verify-before-store | `cmd_setup` and `cmd_gui_setup` (call `/profile` before persisting) |
| Path validation | `PATH_RE` and `_validate_path` |
| Header / body hardening | `_request` (filters `Authorization`); `_load_body` (refuses paths under `CONFIG_DIR`) |
| Skill template | `.claude/skills/linode-api-skill/SKILL.md` |
| Memory layer | `docs/` and `.claude/commands/{resume,save}.md` |
| CI | `.github/workflows/ci.yml` |
| Install scripts | `install.sh`, `install.ps1` |
| Commit-trailer convention | `CONTRIBUTING.md` §"Commit message format" |

## Open issues / things the build process does not yet automate

These are honest gaps you should surface to the operator rather than fake:

- **Pricing introspection.** This skill assumes you'll get the billable-endpoint list from a human or the vendor's pricing page. There's no automatic mapping from an OpenAPI spec to "this endpoint costs money".
- **OAuth-flow APIs.** The `setup` / `gui-setup` pattern assumes a paste-once-and-store credential. For APIs requiring OAuth dance + refresh tokens, you'll need additional design (similar in spirit to `gh auth login` but adapted).
- **Live smoke testing across all tiers.** Step 14 prescribes the methodology but the actual recipe is per-vendor — you need to know which resource is cheapest, which can be safely deleted, etc.
- **Generator tooling.** This skill is markdown that guides an AI to build. There is no `api-skill-builder scaffold <slug> <spec.json>` CLI. Building one is reasonable future work; for now, follow the steps by hand.
