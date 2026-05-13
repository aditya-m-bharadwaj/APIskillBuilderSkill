# APIskillBuilderSkill

> Status: v0.1.0-alpha.1 — Claude skill (markdown), not a runnable binary

A Claude skill that bootstraps a new `<vendor>-api-skill` project — a safe, cross-platform single-file Python CLI that mediates a third-party REST API, plus a matching Claude skill that drives it under explicit AI-safety constraints.

The skill at [`.claude/skills/api-skill-builder/SKILL.md`](.claude/skills/api-skill-builder/SKILL.md) is the deliverable. The rest of this repo is the home of the skill source plus the standard project scaffolding (license, docs, CI, memory layer) that every project this skill builds will also produce.

## What the generated projects look like

Every project this skill bootstraps inherits the same opinionated shape, modeled after [`linode-api-skill`](https://github.com/aditya-m-bharadwaj/linode-api-skill):

- **Single-file Python CLI**, stdlib only, Python 3.8+.
- **Six-tier safety classifier** (`read` / `mutating` / `destructive` / `billable` / `financial` / `privilege`) with a required-flag matrix the CLI itself enforces. Unrecognized endpoints fall back to the strictest applicable default.
- **The API credential never enters Claude's context.** Entry is either `<bin> setup` (TTY-only hidden prompt) or `<bin> gui-setup` (native OS password dialog rendered by the desktop, out-of-band of any pipe).
- **OS-native secret storage** — macOS Keychain → Linux Secret Service (libsecret) → file fallback at mode `0600` (refuses to read if broader).
- **Append-only audit log** of every mutation at `~/.<vendor>-api-skill/audit.log`, mode `0600`. Records timestamp / user / action / target / parameter *metadata* — never the token, never body values, never generated secrets.
- **MIT license + Prompted-By / Co-Authored-By commit trailers** so the AI's contribution is disclosed in `AUTHORS.md` and git history.
- **Threat model documented** in `SECURITY.md`; vulnerability reporting via GitHub private security advisories.
- **CI matrix** (3 OS × Python 3.8–3.12), issue + discussion templates, FUNDING.yml.
- **Tracked memory layer** under `docs/` (progress notes + ADRs), plus graphify integration and project-level `/resume` and `/save` slash commands.

## How to use

1. **Install the skill** (drops it into `~/.claude/skills/api-skill-builder/`):

   ```sh
   curl -fsSL https://raw.githubusercontent.com/aditya-m-bharadwaj/APIskillBuilderSkill/main/install.sh | sh
   ```

   Or from a checkout:

   ```sh
   ./install.sh
   ```

2. **In a Claude Code session**, ask Claude to build a CLI + skill for an API you want to wrap:

   > "Build a CLI and Claude skill for the Porkbun API. Reference: `/path/to/api-spec.json`. Follow the api-skill-builder skill."

3. Claude reads [`.claude/skills/api-skill-builder/SKILL.md`](.claude/skills/api-skill-builder/SKILL.md), follows the 14-step build process, and produces a complete `<vendor>-api-skill` project at `~/Code/<slug>` with every safety guarantee baked in.

## Repository layout

```
APIskillBuilderSkill/
├── .claude/
│   ├── skills/api-skill-builder/SKILL.md   ← THE deliverable
│   ├── commands/{resume,save}.md           ← project-level slash commands
│   └── settings.json                       ← graphify PreToolUse hook
├── .github/
│   ├── workflows/ci.yml                    ← lints + checks skill markdown
│   ├── ISSUE_TEMPLATE/{bug,feature,config}
│   ├── DISCUSSION_TEMPLATE/{q-and-a,ideas,show-and-tell}
│   └── FUNDING.yml
├── docs/
│   ├── README.md                           ← memory-layer index
│   ├── progress/                           ← session-by-session notes
│   └── decisions/                          ← ADRs
├── install.sh / install.ps1                ← symlink the skill into ~/.claude/skills/
├── AUTHORS.md
├── CHANGELOG.md
├── CLAUDE.md
├── CONTRIBUTING.md
├── LICENSE                                 ← MIT
├── README.md (this file)
└── SECURITY.md
```

## Project memory

Sessions on this repo write progress notes to [`docs/progress/`](docs/progress/) and ADRs to [`docs/decisions/`](docs/decisions/). The `/resume` slash command (provided at [`.claude/commands/resume.md`](.claude/commands/resume.md)) reads the most recent progress note and the three most recent ADRs to bootstrap a new session.

For details see [`docs/README.md`](docs/README.md).

## Reference implementation

The reference implementation that this skill mirrors is **`linode-api-skill`** at <https://github.com/aditya-m-bharadwaj/linode-api-skill>. When in doubt, read the corresponding file there.

## Uninstall

```sh
rm -f ~/.claude/skills/api-skill-builder      # symlink, not a directory
```

## License

MIT — see [LICENSE](LICENSE). AI-authored — see [AUTHORS.md](AUTHORS.md).
