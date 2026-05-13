# Project: APIskillBuilderSkill

A Claude skill that bootstraps a new `<vendor>-api-skill` project — a safe single-file Python CLI wrapping a third-party REST API, plus a matching Claude runtime skill. The deliverable is the markdown at [`.claude/skills/api-skill-builder/SKILL.md`](.claude/skills/api-skill-builder/SKILL.md), which is authoritative for the build process and the safety contract.

## Hard rules (override anything else)

1. **The skill text must not weaken the safety contract.** The "Hard rules (non-negotiable for every generated skill)" section enumerates the ten invariants every project this skill builds must satisfy. Changes to that section require an ADR and a security review.
2. **`linode-api-skill` is the reference implementation.** When the skill points to a pattern, it should match the corresponding file in `linode-api-skill`. If the two drift, update both deliberately and ADR-document the divergence.
3. **One logical change per commit.** Don't bundle SKILL.md edits with CI changes or refactors.
4. **Documentation lands in the same commit as the code/skill change it documents.** Don't land code now and the progress note / ADR / CHANGELOG entry as a trailing commit — at the latest, fold them into the final commit of a sequence before pushing.

## Commit-message rules

When you produce a commit on behalf of the operator, follow [CONTRIBUTING.md](CONTRIBUTING.md) §"Commit message format" exactly. Format:

```
type(scope): short subject

Brief description.

- Bullet per logical change.

Prompted-By: <operator name> <operator email>
Co-Authored-By: <model name and version> <noreply address>
```

- **`type`** ∈ `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `ci`, `build`.
- **`Prompted-By:`** identifies the human who directed the commit. Use the *current operator's* name and email — read it from `git config user.name` / `git config user.email` if not told otherwise. This project is open source and any contributor may run an AI agent against it.
- **`Co-Authored-By:`** identifies the model that wrote the change. Use your actual model identifier — `Claude Opus 4.7 (1M context) <noreply@anthropic.com>` and so on. Don't fabricate versions.
- Add trailers only when the AI materially shaped the commit; omit on hand-typed changes.
- Never bypass commit hooks (`--no-verify`, `--no-gpg-sign`) without an explicit per-commit instruction from the operator.

If the operator has not given explicit go-ahead to commit, draft the message and stop — do not run `git commit`.

## Memory protocol (binding for /resume, /save, and any agent in this repo)

This repo uses the same `docs/` ↔ `graphify-out/` ↔ `~/.claude/vault/` split as [`linode-api-skill`](https://github.com/aditya-m-bharadwaj/linode-api-skill).

| Layer | Location | Tracked by git? | What lives there |
| --- | --- | --- | --- |
| **In-repo canonical** | `docs/` | yes | ADRs and session-by-session progress notes |
| **Live structure graph** | `graphify-out/` | no (auto-regenerated) | `GRAPH_REPORT.md`, `graph.json`. Rebuilt by graphify post-commit hook |
| **Operator's centralized vault** | `~/.claude/vault/` | no (lives outside the repo) | Cross-project graphify snapshots and reusable concept notes |

### `/resume` reads, in order:

1. The most recent file in `docs/progress/` (sorted by filename = sorted by date).
2. `graphify-out/GRAPH_REPORT.md` for current repo structure (run `graphify update .` first if absent on a fresh clone).
3. The 3 most recent files in `docs/decisions/`.

Then summarizes: where we left off, what's in-flight, what's next, open questions.

### `/save` writes:

- A new progress note at `docs/progress/YYYY-MM-DD-<slug>.md` summarizing the just-finished session.
- If a material design decision was made in the session, also a new ADR at `docs/decisions/NNNN-<slug>.md` (use the next available number).
- Reusable cross-project concepts go to `~/.claude/vault/zettel/concepts/<concept-slug>.md`, NOT into this repo's `docs/`.

## graphify

This project has a graphify knowledge graph at `graphify-out/` (populated by `graphify update .` after the first commit lands). Rules:

- Before answering architecture or skill-process questions, read `graphify-out/GRAPH_REPORT.md` for the structure overview.
- For cross-file "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's extracted + inferred edges.
- After modifying skill text or other files in this session, run `graphify update .` to keep the graph current (AST + markdown extraction, no API cost).
