---
number: 0007
title: GitHub Wiki adopted as a human-readable documentation surface alongside docs/
status: accepted
date: 2026-05-14
---

# 0007 — GitHub Wiki adopted as a human-readable documentation surface alongside `docs/`

## Context

The project's canonical memory layer is `docs/` — in-repo, code-adjacent, reviewed in PRs, indexed by graphify. ADRs and progress notes live there and are the authoritative record of design decisions.

But `docs/` is not what an external contributor sees when they land on github.com. They open the README, scan a few headings, and bounce. The pages that *would* hold a casual reader — "what is this", "why use it", "how does it work at a glance", "FAQ" — are not naturally `docs/` content. ADRs and progress notes are dense reference for code authors and AI agents loading the repo. Mixing landing-page framing into `docs/` dilutes that audience.

GitHub Wikis are enabled by default in Step 14 of this skill's prescribed repo configuration. But default-enabled is not the same as actually-used. A wiki containing only GitHub's *"Welcome to the wiki!"* placeholder is worse than no wiki — it advertises a documentation surface that does not exist.

## Decision

Adopt the GitHub Wiki as a human-readable documentation surface for this repo, alongside `docs/`. The wiki is **not** canonical; `docs/` remains the tie-breaker when the two disagree. Wiki pages **summarize and link to** canonical content — they do not duplicate it.

Propagate the same pattern to every project this skill builds via SKILL.md Step 14, in a "Bootstrap the wiki" subsection. Every generated project ships with a 12-page wiki seed set (`Home`, `_Sidebar`, `_Footer`, `Getting-Started`, `How-It-Works`, `Hard-Rules`, `Six-Tier-Safety-Classifier`, `Build-Process`, `ADR-Index`, `FAQ`, `Roadmap`, `Contributing-to-the-Wiki`) and a `CONTRIBUTING.md` section explaining the workflow.

Operational shape:

- The wiki lives at `<repo>.wiki.git` — a separate git repository GitHub auto-provisions only after the operator manually clicks "Create the first page" in the Wiki tab. There is no `gh`-based path to provision it (GitHub reserves the `.wiki` suffix; `gh repo create <slug>.wiki` fails).
- The local working clone sits at `wiki/` inside the project root, gitignored from main so the nested `.git/` does not poison the parent's `git status`.
- GitHub-provisioned wiki repos default to the `master` branch (not `main`); commits and pushes use `master`.

## Consequences

- **Positive.** Lower-friction surface for drive-by contributors landing on github.com — they get tutorials, conceptual overviews, FAQ rendered in the GitHub UI without cloning. Day-one human-readable framing in every project this skill builds, not just the ones where someone happens to remember. `docs/` stays dense and code-adjacent; the wiki carries the framing audience.
- **Negative / risks.** Two surfaces to update when canonical content drifts — the wiki can go stale silently because there's no automated drift check. Wikis cannot natively take PRs, so external corrections must come as issues filed against the main repo. Wiki commits don't appear in the main repo's `git log`, making "what changed about this project recently" harder to reconstruct from one place.
- **Neutral / open.** Wiki staleness has no automated detection in v0.1; future ADR may prescribe a CI check or a one-way `wiki/`-in-main → `<repo>.wiki.git` sync action. The per-vendor wiki content remains AI-authored rather than templated — generated projects use the same 12-page filenames + structure but rewrite prose for the target API.

## Alternatives considered

- **`docs/` only (status quo before this session).** Rejected: drive-by contributors don't dig past the README. The Step-14 default-on-Wikis setting was already paying lip service to this audience but delivering nothing.
- **One-way sync from a `wiki/` subdir in the main repo to `<repo>.wiki.git` via a GitHub Action.** Would let wiki content be PR-able and reviewed alongside code. Rejected for v0.1: complexity, low ROI when most edits will come from the operator directly via a local clone. Deferred to v0.2+ if external contributors actually want this.
- **Only this repo gets a wiki; generated projects don't.** Rejected: inconsistency across projects defeats the "every project this skill builds has the same shape" pitch that the safety contract depends on. If wiki is good for this repo, it's good for every generated project.
- **Wiki as canonical, `docs/` deprecated.** Rejected: wiki history is not in the main repo's `git log` and is not indexed by graphify. ADRs and progress notes belong in the same git history as the code they describe — that's the entire premise of `docs/`.

## Related

- [[0006-monolithic-cli-file]] — same "auditable surface" thinking from the CLI side: one file per concern, easy to read end-to-end. The wiki is the parallel for human framing: one URL per concept, readable on github.com without cloning.
- Cross-project concept note: `~/.claude/vault/zettel/concepts/github-wiki-bootstrap-gotchas.md` — the three GitHub-wiki bootstrap gotchas surfaced while implementing this decision.
- Wiki page: [Contributing to the Wiki](https://github.com/aditya-m-bharadwaj/APIskillBuilderSkill/wiki/Contributing-to-the-Wiki) — operator-facing version of the contribution workflow.
- Session log: [[2026-05-14-github-wiki-adoption]].
