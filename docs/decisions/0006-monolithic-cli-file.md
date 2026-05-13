---
number: 0006
title: Generated CLIs ship as one monolithic Python file
status: accepted
date: 2026-05-11
---

# 0006 — Generated CLIs ship as one monolithic Python file

## Context

Python's idiomatic project shape is a package: `setup.py` / `pyproject.toml`, a `src/<pkg>/` directory, sub-modules per concern, an entry point declared in metadata. That's correct for libraries that will be imported by other code and for projects with many active developers.

For a privileged CLI that an operator (or auditor) needs to read end-to-end before trusting with credentials, a package adds friction: which sub-module is the storage layer in? Where does the classifier live? Where's the audit log? The answer is "look at the imports" — and the auditor has to click around.

## Decision

The CLI in every project this skill builds is **one Python file** at `bin/<slug>`. ~1k–2k LOC, all sections (constants, errors, token store, HTTP, path validation, classifier, helpers, command implementations, argparse, entry point) in one place, separated by `# ---------- <section> ----------` banners.

## Consequences

- **Positive.** End-to-end audit is one file. Grep across the entire tool is one file. No `sys.path` games when running tests via `importlib.machinery.SourceFileLoader`. No package metadata to keep in sync.
- **Negative / risks.** The file grows. At ~2k LOC it's still readable; past ~3k the section banners may not be enough and a split becomes appealing. ADR-document the split when it happens — explain *which* concerns are coming out and why.
- **Neutral / open.** This decision implicitly forbids `setup.py` / `pyproject.toml` / `entry_points`. Distribution is "symlink one file." When PyPI publishing becomes worthwhile, this ADR will be revisited together with the version-string format (PEP 440 vs. SemVer with `-alpha.N`).

## Alternatives considered

- **Package with `pip install`-able distribution.** Standard idiom. Rejected for v0.1: install path becomes `pip install … --user` with the associated PATH / virtualenv questions, when the goal was "one-liner curl-pipe-sh installs a symlink."
- **Two files: `cli.py` + `core.py`.** Half-measure. Doesn't gain the audit clarity of one file or the modularity of a package.
- **Zipapp (`.pyz`) build.** Distributes as one file but the *source* is multi-file. Same audit complexity, plus a build step.

## Related

- [[0001-stdlib-only-python]] — single-file is easier when there are no dependencies to declare.
- Reference implementation: `linode-api-skill/bin/linode-api-skill` (one ~1.5k LOC file).
