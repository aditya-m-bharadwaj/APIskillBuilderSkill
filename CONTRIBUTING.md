# Contributing

Thanks for considering a contribution. This repo is a **Claude skill** (markdown) plus the standard project scaffolding around it. The deliverable is the text at [`.claude/skills/api-skill-builder/SKILL.md`](.claude/skills/api-skill-builder/SKILL.md). Most contributions will be either:

- a clarification / correction to the skill text, or
- a new ADR in `docs/decisions/` documenting a change to the build process the skill prescribes.

## Hard rules

1. **The skill must not weaken the safety contract.** The ten "Hard rules (non-negotiable for every generated skill)" section in `SKILL.md` is the safety floor. A change that allows a generated project to slip below any of those rules must come with an ADR explaining why and a security review from someone other than the author.
2. **No third-party Python dependencies in the prescribed CLI.** The skill mandates stdlib-only Python for generated projects. Don't suggest patterns that quietly require `requests`, `httpx`, `pydantic`, `keyring`, `click`, etc.
3. **Reference implementation stays the source of truth.** When the skill says "mirror `linode-api-skill`", changes to the pattern should land in `linode-api-skill` first, then propagate to the skill text here. ADR-document significant divergences.
4. **One logical change per commit.** Don't bundle a SKILL.md cleanup with a CI change.

## How to extend the skill safely

If the build process needs a new step (e.g. handling a vendor with OAuth refresh tokens), the workflow is:

1. **Open a discussion** at <https://github.com/aditya-m-bharadwaj/APIskillBuilderSkill/discussions> describing the gap.
2. **Write an ADR** at `docs/decisions/<NNNN>-<slug>.md` (copy `docs/decisions/TEMPLATE.md`) describing the decision: what's the new design, why is it safe, what alternatives were rejected.
3. **Update `SKILL.md`** to add the new step or refactor an existing one. Link the ADR with `[[NNNN-slug]]`.
4. **Update `CHANGELOG.md`** under `[Unreleased]`.

If you have not been explicitly invited to land a commit, draft the change and open a PR rather than push to `main`.

## Commit message format

Every commit must follow this format exactly:

```
type(scope): short subject

Brief description (1–2 sentences).

- Bullet per logical change.

Prompted-By: <operator name> <operator email>
Co-Authored-By: <model name and version> <noreply address>
```

- **`type`** ∈ `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `ci`, `build`.
- **`scope`** is the area of the change: `skill`, `docs`, `ci`, `install`, `memory`, etc.
- **`Prompted-By:`** identifies the human who directed the commit. Read it from `git config user.name` / `git config user.email`. This project is open source; any contributor may run an AI agent against it.
- **`Co-Authored-By:`** identifies the model that wrote the change. Use your actual model identifier — `Claude Opus 4.7 (1M context) <noreply@anthropic.com>`, `Claude Sonnet 4.6 <noreply@anthropic.com>`, etc. Don't fabricate versions.
- **Omit the trailers** on hand-typed changes where the AI did not materially shape the commit.
- **Never bypass commit hooks** (`--no-verify`, `--no-gpg-sign`) without an explicit per-commit instruction from the operator.

Example:

```
docs(skill): clarify token-rotation reminder in step 4

Step 4 told the AI to rotate the token via gui-setup but didn't say
the local replacement does not invalidate the old token on the
vendor's side. Add an explicit reminder.

- SKILL.md §"Step 4 — Implement gui-setup and setup": new
  reminder that the user must revoke the old token at the vendor's
  dashboard after rotation.

Prompted-By: Aditya Bharadwaj <aditya.m.bharadwaj@gmail.com>
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

## How to extend the skill's "Things you should NOT do" list

This list is anti-pattern enforcement. If you've seen an AI agent make a specific mistake while following this skill, add it to the list with a one-line explanation of why. Don't add anti-patterns that are merely stylistic — only safety- or correctness-relevant ones.

## Project memory protocol

This repo uses the same `docs/` memory layer as `linode-api-skill`. See `docs/README.md`. Briefly:

- Sessions write progress notes to `docs/progress/YYYY-MM-DD-<slug>.md`.
- Material design decisions get an ADR at `docs/decisions/<NNNN>-<slug>.md`.
- Documentation lands in the **same commit** as the code/skill change it documents, never as a trailing follow-up.

## Code of conduct

Be kind. Disagree on the merits. The threat model is real and the safety contract is the reason this skill exists — keep that front of mind.
