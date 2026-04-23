# PowerShell Package

This guide explains the repo-managed PowerShell package under `packages/powershell/`. It covers the profile layout, module conventions, lifecycle integration, and validation notes.

## Design Intent

- Keep the main profile as a thin coordinator rather than a long script full of inline logic.
- Use ordered modules in `profile.d/` so dependencies stay explicit and readable.
- Preserve a clean split between interactive UX helpers and minimal-session safety for automation.
- Prefer documented functions over aliases so exported behavior is discoverable and testable.

## Structure

| Path | Role |
| --- | --- |
| `packages/powershell/Microsoft.PowerShell_profile.ps1` | Main package entrypoint |
| `packages/powershell/profile.d/05-utils.ps1` | Shared command and cache helpers |
| `packages/powershell/profile.d/07-starship.ps1` | Starship prompt initialization when `starship` is available |
| `packages/powershell/profile.d/10-git.ps1` | Git shortcuts and worktree helpers |
| `packages/powershell/profile.d/20-docker.ps1` | Docker and `fzf` helpers plus completion cache |
| `packages/powershell/profile.d/90-local.ps1.example` | Example machine-local module |
| `packages/powershell/test/` | Package diagnostics |

## Configuration Model

The profile skips repo-managed modules when the session cannot support interactive profile UX. Minimal mode activates for `TERM=dumb`, `-NonInteractive`, redirected stdin, or redirected stdout. When `PROFILE_DEBUG=1` is set, the profile prints the skip reason or the loaded module list.

In rich sessions, `Microsoft.PowerShell_profile.ps1` imports Chocolatey tab completion when present, then loads `profile.d/*.ps1` in lexical order. Numeric prefixes define dependencies:

- `05-utils.ps1` defines `Test-Command` and the profile cache directory.
- `07-starship.ps1` initializes Starship only when the binary is available.
- `10-git.ps1` exports Git helpers only when `git` is available.
- `20-docker.ps1` exports Docker helpers only when `docker` is available.
- `90-local.ps1.example` documents the ignored machine-local extension point.

## Exported Helpers

Git helpers avoid short aliases that conflict with built-in PowerShell aliases.

| Command | Description |
| --- | --- |
| `gits` | `git status` |
| `gitl` | `git log --oneline --decorate --graph` |
| `gitco` | `git checkout`; interactive local branch selector when called without arguments and `fzf` is available |
| `gitcm` | `git commit` |
| `gitp` | `git push` |
| `gitpl` | `git pull` |
| `gitwt` | `git worktree` |
| `gitwtc` | Create a worktree under the main repository `.tree/<branch>` and switch to it |
| `gitwts` | Interactive worktree selector with `fzf` |
| `gitwtr` | Interactive worktree remover with `fzf` and confirmation |

Docker helpers use the `dockerf*` naming convention for `fzf`-powered commands.

| Command | Description |
| --- | --- |
| `dockerfshell` | Select a running container and open `pwsh` or `bash` |
| `dockerflogs` | Select one or more containers and show logs |
| `dockerfrmi` | Select one or more images and remove them |
| `dockerfrm` | Select one or more containers and remove them forcibly |
| `dockerfrun` | Select a local image and run an interactive container |
| `dockerfexec` | Select a running container and execute an entered command |

Docker completion is cached at `cache/docker_completion.ps1` beside the PowerShell profile root and regenerated when missing or older than 30 days. Completion generation failures are ignored so profile startup can continue.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | No package-specific entry in `packages/packages.list` or `packages/container.list`. The package assumes a PowerShell 7 profile host is already available. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | Windows deploys the main profile and `profile.d/` into `~/OneDrive/Documents/PowerShell/`. The default Windows Dotter profile selects `powershell`. |
| Post hook | No post hook. |

## Validation Notes

Use `packages/powershell/test/test-profile-commands.ps1` for package diagnostics. For targeted debugging, load the profile with `PROFILE_DEBUG=1`, then check exported functions with `Get-Command`.

## Common Failure Modes

- Missing exported commands because a module guard returned early.
- Syntax errors inside a profile module.
- Minimal-session gating preventing repo-managed modules from loading in automation.
- Documentation drift between exported commands and this guide.
