# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html). Pre-1.0 releases may include breaking changes to the skill's prescribed build steps between iterations; the skill's safety contract (the ten "Hard rules") is stable starting at `1.0.0`.

## [Unreleased]

### Skill

- **`SKILL.md` — new Step 14: "Push and configure the GitHub repo".** Inserted between the initial commit (Step 13) and the live smoke test (renumbered to Step 15). Covers the About-panel description / website / topics, Features (Issues + Discussions + Wikis + Projects + Sponsorships all on), Pull-Request settings (squash-merge + auto-delete head branches), Code-security settings (private vulnerability reporting, Dependabot alerts/security updates, secret scanning, push protection), and a deferred-branch-protection note for solo alpha. The default is intentionally permissive: Wikis and Projects are *on* even though `docs/` is the canonical memory layer, because leaving them on costs nothing and lowers friction for external contributors. The step instructs the AI to run this immediately after the first push lands — without it, `SECURITY.md`'s "file a private security advisory" instruction is a dead link.

### Fixed

- **`install.sh`** — replaced two `A && B || C` chains flagged by `shellcheck` SC2015 with explicit `if`/`else` forms. The original logic was correct (we wanted to swallow non-fatal failures), but shellcheck can't tell the two patterns apart. CI now passes the `shellcheck install.sh` step.

## [0.1.0-alpha.1] — 2026-05-11 — initial public alpha

First public alpha. A Claude skill that bootstraps a new `<vendor>-api-skill` project (single-file stdlib Python CLI + matching Claude runtime skill) with AI-safety baked in, mirroring the patterns of [`linode-api-skill`](https://github.com/aditya-m-bharadwaj/linode-api-skill).

### Skill

- **`.claude/skills/api-skill-builder/SKILL.md`** — the deliverable. ~14 build steps from "I want to wrap API X" to "v0.1 alpha published". Sections:
  - **Hard rules (non-negotiable for every generated skill)** — ten invariants: credential never enters AI context, OS-native storage, verify-before-store, six-tier classifier, audit log, path/argument hardening, stdlib-only Python, in-chat + machine confirmation, MIT + trailer convention, threat model documented.
  - **The build process** — 14 ordered steps (init repo → classifier → token storage → `gui-setup` → named commands + `api` gateway → tests → runtime SKILL.md → supporting docs → `.github/` metadata → memory layer → graphify → install scripts → initial commit → live smoke test).
  - **Safety guarantees the generated skill MUST provide** — a checklist of `grep`-verifiable invariants in the generated `bin/<slug>`.
  - **Things you should NOT do** — anti-pattern list.
  - **Reference implementation table** — file-by-file pointers into `linode-api-skill` for each concern.

### Supporting docs

- `README.md` — usage, generated-project shape, repository layout, install one-liner.
- `AUTHORS.md` — AI-authorship attribution + disclaimer specific to single-session AI-generated skills.
- `SECURITY.md` — threat model (skill drift vs. generated-project safety), private-advisory reporting, hardening recommendations.
- `CONTRIBUTING.md` — hard rules, ADR-driven skill extension, commit-message format with `Prompted-By` + `Co-Authored-By` trailers.
- `CLAUDE.md` — project-level hard rules for any AI agent working in this repo, plus the memory protocol.
- `LICENSE` — MIT.

### Project memory layer (mirrored from `linode-api-skill`)

- `docs/README.md`, `docs/progress/TEMPLATE.md`, `docs/decisions/TEMPLATE.md`.
- ADRs `0001`–`0006` covering the design choices that this skill prescribes: stdlib-only Python, six-tier classifier, cross-platform token storage, AI-safe GUI token entry, the `Prompted-By` trailer convention, the monolithic CLI file.
- Seed progress note `docs/progress/2026-05-11-initial-scaffold.md`.

### `.github/` metadata

- `workflows/ci.yml` — lints the skill markdown and runs `shellcheck` on `install.sh`.
- `ISSUE_TEMPLATE/{bug_report,feature_request,config}.{md,yml}` — bug + feature templates; `config.yml` disables blank issues and points contact links at the private security advisory, `SECURITY.md`, and Discussions.
- `DISCUSSION_TEMPLATE/{q-and-a,ideas,show-and-tell}.yml`.
- `FUNDING.yml` — GitHub Sponsors entry; other platform keys commented out.

### Install scripts

- `install.sh` (POSIX) and `install.ps1` (Windows) — symlink `.claude/skills/api-skill-builder/` into `~/.claude/skills/api-skill-builder/` so the skill is available globally to any Claude Code session.
- One-liner bootstrap documented in `README.md`.
