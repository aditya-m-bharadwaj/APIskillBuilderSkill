#!/usr/bin/env sh
# APIskillBuilderSkill installer for macOS and Linux.
#
# Installs the api-skill-builder Claude skill into ~/.claude/skills/ so any
# Claude Code session can find and follow it.
#
# Two ways to run:
#
#   1. Inside a cloned checkout:
#        ./install.sh
#
#   2. One-liner (replace REPO_URL with the published repo before publishing):
#        curl -fsSL https://raw.githubusercontent.com/aditya-m-bharadwaj/APIskillBuilderSkill/main/install.sh | sh
#
# Flags (env vars):
#   ASB_HOME    where to clone the repo                  (default: ~/.local/share/APIskillBuilderSkill)
#   ASB_REPO    git URL to clone                         (default: REPO_URL placeholder)
#   ASB_REF     branch/tag/SHA to check out              (default: main)
#   SKILLS_DIR  where to symlink the skill               (default: ~/.claude/skills)
#
# This script:
#   * verifies the .claude/skills/api-skill-builder/SKILL.md is in place,
#   * clones the repo (or uses the current checkout),
#   * symlinks .claude/skills/api-skill-builder -> $SKILLS_DIR/api-skill-builder
#
# No credentials are read or written. The skill is markdown.

set -eu

REPO_URL="${ASB_REPO:-https://github.com/aditya-m-bharadwaj/APIskillBuilderSkill.git}"
REF="${ASB_REF:-main}"
HOME_DIR="${ASB_HOME:-$HOME/.local/share/APIskillBuilderSkill}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.claude/skills}"

# Pretty output
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    BLUE=$(printf '\033[1;34m')
    YELLOW=$(printf '\033[1;33m')
    RESET=$(printf '\033[0m')
else
    BLUE=""
    YELLOW=""
    RESET=""
fi
log()  { printf '%s[install]%s %s\n' "$BLUE" "$RESET" "$*"; }
warn() { printf '%s[warn]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# Decide source dir: existing checkout (script invoked from one) or clone.
SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/.claude/skills/api-skill-builder/SKILL.md" ]; then
    SRC_DIR="$SCRIPT_DIR"
    log "Using current checkout: $SRC_DIR"
else
    log "Cloning $REPO_URL -> $HOME_DIR (ref=$REF)"
    if [ -d "$HOME_DIR/.git" ]; then
        git -C "$HOME_DIR" fetch --quiet origin "$REF" \
            && git -C "$HOME_DIR" checkout --quiet "$REF" \
            && git -C "$HOME_DIR" pull --quiet --ff-only origin "$REF" 2>/dev/null || true
    else
        git clone --quiet --branch "$REF" "$REPO_URL" "$HOME_DIR" \
            || die "git clone failed"
    fi
    SRC_DIR="$HOME_DIR"
fi

SKILL_SRC="$SRC_DIR/.claude/skills/api-skill-builder"
[ -d "$SKILL_SRC" ] || die "skill dir missing at $SKILL_SRC"
[ -f "$SKILL_SRC/SKILL.md" ] || die "SKILL.md missing at $SKILL_SRC/SKILL.md"

mkdir -p "$SKILLS_DIR"
SKILL_DST="$SKILLS_DIR/api-skill-builder"

if [ -L "$SKILL_DST" ]; then
    EXISTING=$(readlink "$SKILL_DST" || true)
    if [ "$EXISTING" = "$SKILL_SRC" ]; then
        log "Symlink already up-to-date: $SKILL_DST -> $SKILL_SRC"
    else
        warn "Replacing existing symlink at $SKILL_DST (was -> $EXISTING)"
        rm "$SKILL_DST"
        ln -s "$SKILL_SRC" "$SKILL_DST"
        log "Symlinked: $SKILL_DST -> $SKILL_SRC"
    fi
elif [ -e "$SKILL_DST" ]; then
    die "$SKILL_DST exists and is not a symlink. Move or remove it, then re-run."
else
    ln -s "$SKILL_SRC" "$SKILL_DST"
    log "Symlinked: $SKILL_DST -> $SKILL_SRC"
fi

cat <<EOF

${BLUE}[install]${RESET} Installed. The skill is now available to any Claude Code session.
${BLUE}[install]${RESET}   Skill path: $SKILL_DST
${BLUE}[install]${RESET}   In a session, ask Claude to "build a CLI and Claude skill for the <X> API".
${BLUE}[install]${RESET}   The skill text: $SKILL_SRC/SKILL.md
${BLUE}[install]${RESET}
${BLUE}[install]${RESET} To uninstall:  rm "$SKILL_DST"
EOF
