---
date: 2026-05-11
session: shellcheck-fix-and-github-config-step
operator: Aditya Bharadwaj <aditya.m.bharadwaj@gmail.com>
ai-assist: Claude Opus 4.7 (1M context)
---

# Drafted GitHub repo settings, fixed CI shellcheck failure, codified "configure the GitHub repo" as a build-process step

Follow-up to [[2026-05-11-initial-scaffold]]. The operator pushed the initial alpha to `origin/main` and the first CI run surfaced two `shellcheck` SC2015 warnings in `install.sh`. The operator also asked for a draft of the GitHub About-panel / topics / repo-feature settings, and asked that the same configuration be encoded in the skill so it becomes the default for every project the skill builds.

## What was done

- **Drafted the GitHub About-panel content** for `APIskillBuilderSkill`: description (one sentence covering what the skill does + the safety pitch), website (point to `linode-api-skill` as the canonical reference, or leave blank), and a ~12-topic list for discovery (`claude-code`, `claude-skill`, `claude-agent-sdk`, `ai-safety`, `ai-agents`, `api-wrapper`, `cli-generator`, `scaffold`, `python`, `credential-management`, `audit-log`, `safety-classifier`). Delivered as a chat draft; operator applies in the GitHub UI.
- **Drafted the repo Settings**: Features (Issues + Discussions + **Wikis + Projects** + Sponsorships all on, per operator preference — Wikis/Projects on even though `docs/` is canonical, because no cost and lowers external-contributor friction), Pull Requests (squash-merge only, auto-merge, auto-delete head branches), Code security (private vulnerability reporting, Dependabot alerts + security updates, secret scanning, push protection — all enable). Branch protection deferred for v0.x alpha.
- **`fix(install): satisfy shellcheck SC2015 in install.sh`** (commit `509dfc7`). Two `A && B || C` chains flagged on lines 50 and 59. Replaced with explicit `if`/`else` forms that encode the same control flow:
  - `SCRIPT_DIR` assignment: `if SCRIPT_DIR=$(cd … && pwd); then : else SCRIPT_DIR=""; fi`.
  - fetch/checkout/pull chain: `if fetch && checkout; then pull || true; fi` — `|| true` now only covers `pull`, which is what we actually wanted to tolerate. Original behaviour was "silently no-op on any failure"; new behaviour fails loud on fetch/checkout failure (correct) and tolerates pull failure (also correct).
  - Locally verified: `shellcheck install.sh` exits 0; sandbox install (`SKILLS_DIR=/tmp/...` `ASB_HOME=/tmp/...`) still produces a working symlink to `SKILL.md`.
- **`docs(skill): add "configure the GitHub repo" as Step 14 of the build process`** (commit `a30acb5`). Inserted between the initial commit (Step 13) and the live smoke test (renumbered to Step 15). Captures the same About-panel + Features + Code-security defaults drafted above, plus rationale on why each setting matters. Key choice: Wikis and Projects are *on* by default in the skill's prescribed config — they cost nothing and add an optional surface for external contributors. The step instructs the AI to run it immediately after the first push lands, because otherwise `SECURITY.md`'s "file a private security advisory" link is a dead end.
- Both commits pushed to `origin/main`.

## What's in-flight (not finished)

- Nothing partially completed. The first CI run on `509dfc7` should pass the shellcheck job (verified locally). The operator may need to manually re-apply the About-panel description + topics in the GitHub UI from the chat draft.

## What's next (recommended pickup)

1. Verify CI on the published `a30acb5` is green — the shellcheck job should now exit 0 and the `skill-lint` job should still pass (the new Step 14 section doesn't change the sanity checks).
2. Apply the About-panel description + topics + Settings to the GitHub repo from the drafted text. The skill's new Step 14 is the authoritative reference for what to set.
3. Install the skill globally on the operator's machine: `cd ~/Code/APIskillBuilderSkill && ./install.sh`. After this, any Claude Code session can find and follow `api-skill-builder`.
4. Validate the skill end-to-end by using it once against a real target API (the operator mentioned Porkbun earlier). The `~/Code/porkbun-api-skill/` directory already exists; in a fresh session, ask Claude to "build a CLI and Claude skill for the Porkbun API using the api-skill-builder skill" and see whether the result matches the contract end-to-end. Surface any gaps as ADRs.

## Open questions

- Should the skill's Step 14 also include `gh api`-based commands the AI could run to set the description / topics / features programmatically? Currently the step describes what to set; the operator applies it in the UI. Adding `gh` commands would let the AI configure the repo end-to-end after the push lands. Trade-off: the AI needs `repo`-scope on its `gh` auth (which it has from the linode-api-skill workflow-scope grant earlier), and any future operator must also have `gh` installed. Punted.
- Should Step 14 prescribe specific topic counts / words for every vendor, or leave them as "pick ~12 from this list + add `<vendor>`"? Current text leaves it open; tighter prescriptions would reduce thinking-time but also lock in choices that may not fit every API. Operator preference TBD.
- The operator's CI broke on the initial commit — minor, but it means the very first published build was red. For polish, a future ADR could prescribe that `install.sh` is `shellcheck`-validated locally as a pre-commit hook (or as part of `graphify hook install` augmentation) so future scaffolds don't ship with red CI on commit 0.

## Related files / links

- Commits this session (in order, both on `origin/main`):
  - `509dfc7` — `fix(install): satisfy shellcheck SC2015 in install.sh`
  - `a30acb5` — `docs(skill): add "configure the GitHub repo" as Step 14 of the build process`
- Updated section: `.claude/skills/api-skill-builder/SKILL.md` §"Step 14 — Push and configure the GitHub repo".
- Initial scaffold note: [[2026-05-11-initial-scaffold]].
- ADRs touched: none (no material design decision worth its own ADR — settings policy is documented inline in SKILL.md).
- No new concept notes created in the centralized vault — the GitHub-settings policy is specific to `claude-code-skill` projects, not a cross-project pattern that would outlive this skill.

## Note to self (process)

The two follow-up commits this session each carried their own `CHANGELOG.md` entry (per the [[feedback_commit_docs_with_code]] memory rule). The session-level progress note (this file) is written at session boundary, which is the intent of the rule. If the session had produced a third commit, that commit's docs would have been folded into it inline, not deferred here.
