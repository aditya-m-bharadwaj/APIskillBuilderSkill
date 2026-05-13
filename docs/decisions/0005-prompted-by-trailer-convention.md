---
number: 0005
title: Commits carry Prompted-By and Co-Authored-By trailers when AI materially shaped them
status: accepted
date: 2026-05-11
---

# 0005 — Prompted-By and Co-Authored-By commit trailer convention

## Context

These projects are heavily AI-authored. Future contributors, security reviewers, and the operators themselves need to be able to tell, by reading `git log`, which commits were directed by a human and written by an AI vs. hand-typed by the human. Burying this in `AUTHORS.md` is not enough — that file describes the project, not individual commits.

GitHub recognizes `Co-Authored-By:` as a real authorship signal (it shows the co-author in the PR/commit UI). There's no widely-recognized "Prompted-By" trailer, but the operator wants the *human* who directed the AI also disclosed.

## Decision

Every commit where the AI materially shaped the diff (which is most of them in these projects) carries two trailers at the end of the commit message:

```
Prompted-By: <human name> <human email>
Co-Authored-By: <model name and version> <noreply address>
```

Rules:

- `Prompted-By:` uses the *current operator's* name and email, read from `git config user.name` / `git config user.email` if not told otherwise. These projects are open source — any contributor may run an AI agent against them.
- `Co-Authored-By:` uses the *actual* model identifier the AI is running as. e.g. `Claude Opus 4.7 (1M context) <noreply@anthropic.com>`. Do not fabricate versions.
- Trailers are omitted on hand-typed changes where the AI did not materially shape the commit. Two-line typo fixes that the human wrote don't carry trailers; multi-file refactors the AI proposed do.
- Hooks (`--no-verify`, `--no-gpg-sign`) are never bypassed without an explicit per-commit instruction from the operator.

## Consequences

- **Positive.** `git log --format='%(trailers:only)' <range>` gives a clean attribution report. GitHub renders the `Co-Authored-By:` as a real co-author in the UI. Security reviewers can filter for AI-shaped commits and audit those specifically.
- **Negative / risks.** Adds two lines to every commit message. Operators who don't want this attribution must remove the trailers manually (or instruct the AI not to add them per-commit).
- **Neutral / open.** `Prompted-By:` is not a standard trailer; tooling that consumes git trailers won't recognize it specifically. It still parses as a Key-Value trailer.

## Alternatives considered

- **Only `Co-Authored-By:`.** Drops the human-prompter attribution. Rejected — the operator wants both halves disclosed.
- **AI authorship only in `AUTHORS.md`.** Insufficient at the commit level; doesn't disclose *which* commits were AI-shaped.
- **Hide AI authorship.** Rejected on principle; these are public projects and the AI's contribution is real.

## Related

- See `CONTRIBUTING.md` §"Commit message format" for the exact format and an example.
