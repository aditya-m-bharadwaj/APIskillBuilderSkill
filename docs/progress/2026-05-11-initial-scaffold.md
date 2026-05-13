---
date: 2026-05-11
session: initial-scaffold
operator: Aditya Bharadwaj <aditya.m.bharadwaj@gmail.com>
ai-assist: Claude Opus 4.7 (1M context)
---

# Initial public alpha — meta-skill that bootstraps `<vendor>-api-skill` projects

Authored the first version of `APIskillBuilderSkill`: a Claude skill that codifies the build process and safety contract that emerged from `linode-api-skill`, so any future "wrap the X API safely" request can be delivered with the same shape and the same guarantees.

## What was done

- **`.claude/skills/api-skill-builder/SKILL.md`** — the deliverable. Frontmatter + ten "Hard rules (non-negotiable for every generated skill)" + 14-step build process + "Safety guarantees the generated skill MUST provide" `grep`-verifiable checklist + "Things you should NOT do" anti-pattern list + reference-implementation file pointers.
- **Supporting docs** mirroring `linode-api-skill`'s shape: `README.md`, `AUTHORS.md`, `SECURITY.md` (split threat model: skill text vs. generated-project safety), `CONTRIBUTING.md` (hard rules + ADR-driven extension + commit-message format), `CHANGELOG.md` (`[0.1.0-alpha.1]` entry), `CLAUDE.md` (project-level rules + memory protocol + commit-message rules), `LICENSE` (MIT).
- **`.github/` metadata**: `workflows/ci.yml` (shellcheck on `install.sh`; skill-markdown sanity job checks frontmatter + six classifier tiers + reference to `linode-api-skill`; relative-link existence check). `ISSUE_TEMPLATE/{bug_report,feature_request,config.yml}` with private security advisory contact link. `DISCUSSION_TEMPLATE/{q-and-a,ideas,show-and-tell}.yml`. `FUNDING.yml`.
- **`.claude/` infrastructure**: project-level `commands/{resume,save}.md`; `settings.json` with the graphify PreToolUse hook nudging the AI toward `graphify-out/GRAPH_REPORT.md` before grep/find.
- **`docs/` memory layer**: `README.md` documenting the `docs/` ↔ `graphify-out/` ↔ `~/.claude/vault/` split; `progress/TEMPLATE.md`; `decisions/TEMPLATE.md`; ADRs `0001`–`0006` covering stdlib-only Python, the six-tier classifier, cross-platform token storage, AI-safe GUI token entry, the Prompted-By trailer convention, and the monolithic CLI file rationale.
- **`install.sh` / `install.ps1`** — symlink `.claude/skills/api-skill-builder/` into `~/.claude/skills/api-skill-builder/` so the skill is available globally to any Claude Code session.

## What's in-flight (not finished)

- Not yet committed — these are first-pass files staged in the working tree. Initial commit pending operator's go-ahead.
- `graphify update .` not yet run. Will populate `graphify-out/GRAPH_REPORT.md` after the initial commit lands.
- `~/.claude/skills/api-skill-builder/` symlink not yet created. The operator can run `./install.sh` after the commit lands (or now, before, since it doesn't depend on git state).

## What's next (recommended pickup)

1. Land the initial commit (one `feat: initial public alpha (v0.1.0-alpha.1)` covering everything in this scaffold, with `Prompted-By:` + `Co-Authored-By:` trailers).
2. Run `graphify update .` once and verify `graphify-out/GRAPH_REPORT.md` reflects the structure (mostly markdown, no Python code yet — graph will be small).
3. Install the post-commit graphify hook (`graphify hook install`) so future commits regenerate the graph.
4. Optionally: create the GitHub repo at <https://github.com/aditya-m-bharadwaj/APIskillBuilderSkill> and push. Tag `v0.1.0-alpha.1` and cut a pre-release.
5. Use the skill once against a real target API (the operator mentioned Porkbun) to validate the build process end-to-end. Surface any gaps as follow-up ADRs.

## Open questions

- Should the skill add a "generator tool" — a Python script that takes an OpenAPI spec and emits a starter CLI? Discussed in `SKILL.md` §"Open issues / things the build process does not yet automate". For v0.1 the answer is no; the skill is markdown that guides an AI to do the work, with `linode-api-skill` as the working reference. Generator tooling is reasonable future work.
- How should the skill handle APIs with OAuth refresh tokens (e.g. Google APIs)? Current text mentions this is a gap. May warrant ADR `0007` if/when we tackle a vendor that needs it.
- Should generated projects be encouraged to ALSO depend on this skill (i.e. cite it in their `AUTHORS.md`)? Currently the skill cites `linode-api-skill` as the reference; whether generated projects should cite `APIskillBuilderSkill` as their meta-source is unspecified.

## Related files / links

- ADRs created this session:
  - [[0001-stdlib-only-python]]
  - [[0002-safety-classifier-six-tiers]]
  - [[0003-cross-platform-token-storage]]
  - [[0004-ai-safe-token-entry-gui-dialog]]
  - [[0005-prompted-by-trailer-convention]]
  - [[0006-monolithic-cli-file]]
- Reference implementation: <https://github.com/aditya-m-bharadwaj/linode-api-skill>
- This repo: `~/Code/APIskillBuilderSkill` (not yet pushed).
