# PowerShell Profile - Modular Configuration

Modular PowerShell profile with Git and Docker utilities.

## Prerequisites
- PowerShell 7+, Starship (required)
- Git, fzf, Docker (optional - modules auto-disable if missing)

## Commands

### Git Module (requires: git, fzf for gitwts)
| Command | Description |
|---------|-------------|
| gits | git status |
| gitl | git log --oneline --graph |
| gitco | git checkout |
| gitcm | git commit |
| gitp | git push |
| gitpl | git pull |
| gitwt | git worktree |
| gitwts | Interactive worktree selector (fzf) |

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
# Test with debug output
$env:PROFILE_DEBUG=1; pwsh -NoProfile -NoExit -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'"

# Verify all commands
pwsh -NoProfile -Command "& '$PWD\test\test-profile-commands.ps1'"
```
