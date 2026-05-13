# APIskillBuilderSkill installer for Windows.
#
# Installs the api-skill-builder Claude skill into ~/.claude/skills/ so any
# Claude Code session can find and follow it.
#
# Two ways to run:
#
#   1. Inside a cloned checkout:
#        ./install.ps1
#
#   2. One-liner (PowerShell 5+):
#        iwr -useb https://raw.githubusercontent.com/aditya-m-bharadwaj/APIskillBuilderSkill/main/install.ps1 | iex
#
# Env vars:
#   $env:ASB_HOME    where to clone the repo            (default: $HOME\.local\share\APIskillBuilderSkill)
#   $env:ASB_REPO    git URL to clone                   (default: REPO_URL placeholder)
#   $env:ASB_REF     branch/tag/SHA to check out        (default: main)
#   $env:SKILLS_DIR  where to install the skill         (default: $HOME\.claude\skills)
#
# No credentials are read or written. The skill is markdown.

$ErrorActionPreference = "Stop"

$RepoUrl   = if ($env:ASB_REPO)   { $env:ASB_REPO }   else { "https://github.com/aditya-m-bharadwaj/APIskillBuilderSkill.git" }
$Ref       = if ($env:ASB_REF)    { $env:ASB_REF }    else { "main" }
$HomeDir   = if ($env:ASB_HOME)   { $env:ASB_HOME }   else { Join-Path $HOME ".local\share\APIskillBuilderSkill" }
$SkillsDir = if ($env:SKILLS_DIR) { $env:SKILLS_DIR } else { Join-Path $HOME ".claude\skills" }

function Log($msg)  { Write-Host "[install] $msg" -ForegroundColor Blue }
function Warn($msg) { Write-Host "[warn]    $msg" -ForegroundColor Yellow }

# Decide source dir: existing checkout (script invoked from one) or clone.
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$LocalSkill = Join-Path $ScriptDir ".claude\skills\api-skill-builder\SKILL.md"

if (Test-Path $LocalSkill) {
    $SrcDir = $ScriptDir
    Log "Using current checkout: $SrcDir"
} else {
    Log "Cloning $RepoUrl -> $HomeDir (ref=$Ref)"
    if (Test-Path (Join-Path $HomeDir ".git")) {
        git -C $HomeDir fetch --quiet origin $Ref
        git -C $HomeDir checkout --quiet $Ref
        git -C $HomeDir pull --quiet --ff-only origin $Ref 2>$null
    } else {
        git clone --quiet --branch $Ref $RepoUrl $HomeDir
        if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
    }
    $SrcDir = $HomeDir
}

$SkillSrc = Join-Path $SrcDir ".claude\skills\api-skill-builder"
if (-not (Test-Path $SkillSrc)) { throw "skill dir missing at $SkillSrc" }
if (-not (Test-Path (Join-Path $SkillSrc "SKILL.md"))) { throw "SKILL.md missing at $SkillSrc\SKILL.md" }

if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

$SkillDst = Join-Path $SkillsDir "api-skill-builder"

# Try a symlink (requires Developer Mode or admin on older Windows).
# Fall back to copy if symlink isn't permitted.
$existing = Get-Item -LiteralPath $SkillDst -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.LinkType -eq "SymbolicLink") {
        $target = $existing.Target
        if ($target -is [array]) { $target = $target[0] }
        if ($target -eq $SkillSrc) {
            Log "Symlink already up-to-date: $SkillDst -> $SkillSrc"
            $skipInstall = $true
        } else {
            Warn "Replacing existing symlink at $SkillDst (was -> $target)"
            Remove-Item -LiteralPath $SkillDst -Force
        }
    } else {
        throw "$SkillDst exists and is not a symlink. Move or remove it, then re-run."
    }
}

if (-not $skipInstall) {
    try {
        New-Item -ItemType SymbolicLink -Path $SkillDst -Target $SkillSrc -Force | Out-Null
        Log "Symlinked: $SkillDst -> $SkillSrc"
    } catch {
        Warn "Symlink creation failed (Developer Mode off?). Falling back to copy."
        Copy-Item -Recurse -Force -Path $SkillSrc -Destination $SkillDst
        Log "Copied: $SkillSrc -> $SkillDst (manual re-copy needed when the skill updates)"
    }
}

Write-Host ""
Log "Installed. The skill is now available to any Claude Code session."
Log "  Skill path: $SkillDst"
Log "  In a session, ask Claude to 'build a CLI and Claude skill for the <X> API'."
Log "  The skill text: $SkillSrc\SKILL.md"
Write-Host ""
Log "To uninstall:  Remove-Item -LiteralPath '$SkillDst' -Recurse -Force"
