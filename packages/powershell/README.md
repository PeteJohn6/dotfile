# PowerShell Profile - Modular Configuration

Modular PowerShell profile with Starship, Git, and Docker utilities.

## Prerequisites
- PowerShell 7+
- Starship (optional - loaded only in rich terminal sessions)
- Git, fzf, Docker (optional - modules auto-disable if missing)

## Load Behavior
- Main entrypoint: `Microsoft.PowerShell_profile.ps1`
- Modules: `profile.d/*.ps1` loaded in alphabetical order (numeric prefix controls sequence)
- `07-starship.ps1` owns prompt initialization when `starship` is available
- Minimal terminal mode skips all repo-managed profile modules when any of these are true:
  - `TERM=dumb`
  - PowerShell started with `-NonInteractive`
  - stdin is not a TTY
  - stdout is not a TTY
- Debug: set `PROFILE_DEBUG=1` before loading the profile to print either loaded modules or the minimal-mode skip reason

## Commands

### Git Module (requires: git, fzf for gitco, gitwts and gitwtr)
| Command | Description |
|---------|-------------|
| gits | git status |
| gitl | git log --oneline --graph |
| gitco | git checkout; interactive branch selector when called without args (fzf) |
| gitcm | git commit |
| gitp | git push |
| gitpl | git pull |
| gitwt | git worktree |
| gitwts | Interactive worktree selector (fzf) |
| gitwtr | Interactive worktree remover (fzf, confirmation required) |

### Docker Module (requires: docker, fzf for interactive)
Naming: `dockerf*` means an interactive fzf-powered command.

| Command | Description |
|---------|-------------|
| dockerfshell | Interactive shell in container (fzf) |
| dockerflogs | View container logs (fzf, multi-select) |
| dockerfrmi | Remove images (fzf, multi-select) |
| dockerfrm | Remove containers (fzf, multi-select, forced) |
| dockerfrun | Run container from image (fzf) |
| dockerfexec | Execute command in container (fzf) |

## Testing

```powershell
# Rich-terminal debug session
$env:PROFILE_DEBUG=1; pwsh -NoProfile -NoExit -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'"

# Session-aware diagnostics (rich sessions expect commands; minimal sessions expect a skip)
pwsh -NoProfile -Command "& '$PWD\test\test-profile-commands.ps1'"
```
