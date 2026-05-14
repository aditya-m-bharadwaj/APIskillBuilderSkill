---
date: 2026-05-14
session: github-wiki-adoption
operator: Aditya Bharadwaj <aditya.m.bharadwaj@gmail.com>
ai-assist: Claude Opus 4.7 (1M context)
---

# Adopted GitHub Wiki as a human-readable documentation surface and propagated the pattern to the skill contract

Follow-up to [[2026-05-11-shellcheck-fix-and-github-config-step]]. SKILL.md Step 14 already prescribed "Wikis: on by default" but the repo's wiki was empty placeholder. The operator asked whether the project should adopt the wiki as a real documentation surface and, if so, how the workflow should look. The session worked through the conceptual model (wiki as a sibling `<repo>.wiki.git` repo, gitignored from main, `docs/` remains canonical), authored a 12-page seed set, bootstrapped the wiki repo via the web UI, pushed, and then propagated the same pattern into SKILL.md so every project this skill builds gets the same starter wiki.

## What was done

- **Discussed the conceptual model in chat** — confirmed `<repo>.wiki.git` is a separate git repo sharing only a URL prefix with the main repo, sketched the `wiki/`-inside-main-repo-but-gitignored pattern, and made the call that `docs/` stays canonical while the wiki is human-readable framing.
- **Authored 12 wiki pages** in `wiki/`: `Home.md`, `_Sidebar.md`, `_Footer.md`, `Getting-Started.md`, `How-It-Works.md`, `Hard-Rules.md`, `Six-Tier-Safety-Classifier.md`, `Build-Process.md`, `ADR-Index.md`, `FAQ.md`, `Roadmap.md`, `Contributing-to-the-Wiki.md`. All pages link to canonical sources in the main repo (SKILL.md, ADRs, SECURITY.md) via absolute github.com URLs. The wiki is a human-readable companion, not a replacement; `docs/` wins on conflicts.
- **First attempt failed:** ran `git init -b main` locally inside `wiki/`, added the remote, committed, and tried `git push -u origin main` → `Repository not found.` because `<slug>.wiki.git` doesn't exist server-side until a page is saved via the web UI.
- **Discovered `gh repo create <slug>.wiki` is also rejected** with `The repository <slug>.wiki cannot end in .wiki` — GitHub reserves the `.wiki` suffix for auto-provisioned wiki repos.
- **Working path:** operator manually clicked "Create the first page" in the GitHub Wiki tab → GitHub auto-provisioned `<slug>.wiki.git`. We then removed the local `git init` (`mv wiki wiki-old`), cloned the GitHub-provisioned repo fresh, copied the 12 pages over the GitHub-auto-`Home.md`, removed the `temp.md` placeholder the operator had created during bootstrap, and pushed to `master` (GitHub's wiki default branch, not `main`).
- **Wiki commit `59e3dd8`** (`wiki: initial seed (v0.1.0-alpha.1 surface)`) pushed to `origin/master` of `APIskillBuilderSkill.wiki.git`. Live at <https://github.com/aditya-m-bharadwaj/APIskillBuilderSkill/wiki>.
- **`docs: adopt GitHub wiki as a human-readable documentation surface`** (commit `5ae43b6` on `origin/main`):
  - `.gitignore` — added `wiki/` with an inline comment explaining the nested-repo pattern.
  - `CONTRIBUTING.md` — new "Contributing to the wiki" section documenting the clone-edit-push workflow, `[[Page Name]]` / absolute-link conventions, and the `docs/` (canonical) vs. wiki (human-readable framing) split.
  - `.claude/skills/api-skill-builder/SKILL.md` — Step 14 gains a "Bootstrap the wiki" subsection: 12-page starter set, gitignore pattern, `CONTRIBUTING.md` addition requirement, plus three gotchas as a hard operator-action callout (`.wiki` reserved suffix, web-UI-bootstrap required, master not main).
  - `CHANGELOG.md` `[Unreleased]` — new Docs subsection (this-repo adoption) + expanded Skill bullet (SKILL.md Step 14 expansion with lessons learned).

## What's in-flight (not finished)

- Nothing partially completed. Both repos clean and pushed.

## What's next (recommended pickup)

1. **Apply the GitHub Settings drafted in [[2026-05-11-shellcheck-fix-and-github-config-step]]** — About-panel description, topics, code-security toggles. Still pending per the prior progress note's Step 2.
2. **End-to-end validate the skill against Porkbun.** The skill now mandates a wiki bootstrap as part of Step 14; the first real cross-vendor exercise will confirm the new "Bootstrap the wiki" subsection reads correctly under execution and that the `.wiki` / web-UI / `master` gotchas are surfaced clearly enough that the next AI doesn't have to discover them.
3. **Decide on a one-way `wiki/`-in-main-repo → `<slug>.wiki.git` sync action.** Out of scope for v0.1 per the wiki's Roadmap page, but if external contributors want PR-able wiki content, a GitHub Action would deliver that without breaking the "`docs/` canonical" rule.

## Open questions

- **Wiki content drift.** The wiki summarizes content that's authoritative in `docs/` and `SKILL.md`. When canonical content changes, the wiki page must be updated by hand in the wiki repo. There's no automated drift detection. For v0.1 we accept the drift risk as the cost of two-surface clarity; a future ADR could prescribe a wiki-staleness CI check (or the one-way sync from main, which sidesteps the question).
- **Per-vendor wiki page templates.** Every generated project will now ship with a 12-page wiki seed, but the prose on each page is currently generic — the AI is expected to rewrite each page from scratch using the seed structure as scaffolding. Should there be a `wiki/templates/` set in the skill repo that the AI mechanically copies and substitutes the vendor name into? Current SKILL.md leaves this open.
- **OAuth refresh-token APIs.** Carried over from prior progress notes; still unresolved.

## Related files / links

- This session's commits:
  - Main repo: `5ae43b6 docs: adopt GitHub wiki as a human-readable documentation surface` on `origin/main`.
  - Wiki repo: `59e3dd8 wiki: initial seed (v0.1.0-alpha.1 surface)` on `origin/master` of `APIskillBuilderSkill.wiki.git`.
- New ADR: [[0007-github-wiki-as-documentation-surface]] (created this session).
- New vault concept note: `~/.claude/vault/zettel/concepts/github-wiki-bootstrap-gotchas.md` (cross-project — three GitHub-wiki gotchas surfaced this session).
- Vault mirror of this progress note: `~/.claude/vault/zettel/progress/2026-05-14-apiskillbuilderskill-github-wiki-adoption.md`.
- Prior progress notes: [[2026-05-11-initial-scaffold]], [[2026-05-11-shellcheck-fix-and-github-config-step]].
- Live wiki: <https://github.com/aditya-m-bharadwaj/APIskillBuilderSkill/wiki>.
