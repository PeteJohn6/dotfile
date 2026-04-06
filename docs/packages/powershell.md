# PowerShell Package

This document explains the repo-managed PowerShell package under `packages/powershell/`. It covers the package layout, module conventions, design intent behind the profile structure, and how to debug and validate changes.

## Design Intent

- Keep the main profile as a thin coordinator rather than a long script full of inline logic.
- Use ordered modules in `profile.d/` so dependencies stay explicit and readable.
- Preserve a clean split between interactive UX helpers and minimal-session safety for automation.
- Prefer documented functions over aliases so exported behavior is discoverable and testable.

## Structure

| Path | Role |
| --- | --- |
| `packages/powershell/Microsoft.PowerShell_profile.ps1` | Main package entrypoint |
| `packages/powershell/profile.d/` | Ordered domain modules |
| `packages/powershell/test/` | Validation and diagnostics |

## Core Patterns

- The main profile detects minimal sessions and skips rich UX modules when the environment is non-interactive.
- Modules in `profile.d/` load in lexical order, so numeric prefixes control dependencies.
- Domain modules should guard on required tools and return early when prerequisites are missing.
- User-facing shortcuts should be PowerShell functions with comment-based help, not aliases.

Those rules keep the package stable across interactive shells, CI-style sessions, and partially provisioned machines. A missing dependency should degrade behavior locally rather than breaking profile startup globally.

## Module Authoring Rules

When adding a module:

1. choose an ordering prefix that matches its dependencies
2. guard on required external tools
3. document user-facing functions with `.SYNOPSIS` and, for non-trivial commands, `.DESCRIPTION` and `.EXAMPLE`
4. keep `README.md` synchronized when exported commands or prerequisites change

## Diagnostics

Use the test harness in `packages/powershell/test/` after changes.

## Validation Design

- Exercise the full profile entrypoint first so regressions in module ordering or guards surface early.
- Keep a second layer of targeted commands for isolating failures to a specific module.
- Make verification cheap enough that package changes can be checked before they drift into user-visible breakage.

## Fast Checks

| Task | Command |
| --- | --- |
| Load the rich profile | `pwsh -NoProfile -NoExit -Command ". '$PWD\\Microsoft.PowerShell_profile.ps1'"` |
| Enable debug output | `$env:PROFILE_DEBUG=1; pwsh -NoProfile -NoExit -Command ". '$PWD\\Microsoft.PowerShell_profile.ps1'"` |
| Run the main diagnostic script | `pwsh -NoProfile -Command "& '$PWD\\test\\test-profile-commands.ps1'"` |
| Check specific exported commands | `Get-Command gitco,gitwt,gitwts,gitwtr,dockerfexec,dockerfshell,gits,dockerps,dockercompose -ErrorAction SilentlyContinue | Format-Table Name,CommandType` |

## Recommended Validation Flow

1. Run `test-profile-commands.ps1`.
2. Confirm prerequisites such as `git`, `docker`, `fzf`, and `starship`.
3. Reproduce the issue in a rich interactive terminal when the profile is expected to load repo-managed modules.
4. Test an individual module directly if the failure appears isolated.

## Common Failure Modes

- missing exported commands because a module guard returned early
- syntax errors inside a profile module
- minimal-session gating preventing repo-managed modules from loading in automation
- documentation drift between actual commands and `README.md`

## Useful Commands

```powershell
pwsh -NoProfile -Command "& '$PWD\test\test-profile-commands.ps1'"
pwsh -NoProfile -Command ". '$PWD\profile.d\10-git.ps1'; Get-Command gitco,gitwt,gitwtr,gits -ErrorAction SilentlyContinue"
$Error[0] | Format-List * -Force
```
