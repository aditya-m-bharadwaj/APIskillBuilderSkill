---
number: 0004
title: AI-safe token entry via native OS password dialog (gui-setup)
status: accepted
date: 2026-05-11
---

# 0004 — AI-safe token entry via native OS password dialog (gui-setup)

## Context

The whole point of this family of skills is that the AI agent driving a vendor's API never gets to see the API credential. That means the AI can't `cat` it from a file, can't `printenv` it, can't read it from the keystore.

But operators legitimately need to add, rotate, or change tokens *during* an AI-driven session. If the only entry path is a TTY prompt (`<bin> setup`), the AI can't help with the workflow — it has to tell the user "go to a terminal yourself." For not-very-techie operators driving the CLI by chatting with Claude, that's a wall.

We need a path where:

1. The AI can initiate the entry flow (run a command).
2. The credential bytes never reach any pipe / stdout / file the AI can read.
3. The AI gets back only "success: authenticated as X" — no secret material.

## Decision

Implement `<bin> gui-setup`, which pops a **native OS password dialog rendered by the desktop's WindowServer / compositor**, completely out-of-band of any pipe the AI process is attached to. The user types into the dialog process; that process returns the token via its own stdout, which the CLI captures into Python memory via `subprocess.run(..., capture_output=True)`. The CLI validates the token against a `whoami`-equivalent endpoint, writes it to the keystore, and prints only metadata.

Per-platform dialogs:

- **macOS:** `osascript -e 'display dialog "..." with hidden answer default answer ""'`. The dialog is a real native macOS modal rendered by WindowServer.
- **Linux:** try `zenity --password`; fall back to `kdialog --password`. Both are GTK / Qt dialogs rendered by the compositor.
- **Windows:** PowerShell `Get-Credential` returns a `SecureString`; the one-liner immediately converts to plain text inside the PowerShell process and emits to stdout. Same out-of-band guarantee.

If the CLI detects no display server (SSH session via `SSH_CONNECTION` / `SSH_TTY`, missing `DISPLAY` / `WAYLAND_DISPLAY` on Linux, etc.), `gui-setup` returns a clean error directing the user to use `<bin> setup` in a terminal. **AI agents cannot work around this** — they have no DISPLAY either.

This is the same pattern `gh auth login` and `aws sso login` use: the secret is entered out-of-band; the agent only sees the verification result.

## Consequences

- **Positive.** AI-runnable add/rotate flows without the AI seeing the token. The CLI also validates the token before storage (verify-before-store), so a bad paste doesn't overwrite a working credential.
- **Negative / risks.** Requires a desktop session. SSH-only environments fall back to `setup` (TTY, hidden prompt) — which is fine for humans but blocks AI agents on those hosts.
- **Neutral / open.** The dialog text is constructed via string interpolation; on macOS, AppleScript injection in the prompt string is a real concern (the prompt is a string literal but if it ever takes user-controlled input, escaping backslash + double-quote + control characters is mandatory). `linode-api-skill`'s `_confirm_gui` handles this — copy the escaping logic, do not reinvent it.

## Alternatives considered

- **Read the token from a file the user pre-creates.** Defeats the contract — the file is readable by any process the user runs, including the AI.
- **Browser-based OAuth flow with a local callback server.** Adds complexity (HTTP server in the CLI, port collisions) and many APIs don't offer OAuth. Rejected for v0.1.
- **`expect` script to feed `setup`'s prompt automatically from the AI.** Defeats the point — the token ends up in argv or a fed-stdin pipe the AI controls.

## Related

- [[0003-cross-platform-token-storage]] — where the validated token ends up.
- Reference implementation: `linode-api-skill/bin/linode-api-skill` `_has_display`, `_prompt_token_gui`, `_confirm_gui`, `cmd_gui_setup`.
