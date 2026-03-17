# Zsh Profile - Modular Configuration

Modular zsh profile with Git, Docker, and tmux helpers.

## Prerequisites
- zsh, Starship (optional, auto-enabled when available)
- Git, Docker, tmux (optional - related module auto-disables if missing)
- fzf (optional - only required for `gitco`, `gitwts`, `gitwtr`, and `dockerf*` interactive commands)

## Load Behavior
- Main entrypoint: `.zshrc`
- Modules: `conf.d/*.zsh` loaded in alphabetical order (numeric prefix controls sequence)
- Debug: set `PROFILE_DEBUG=1` before sourcing `.zshrc` to print module load summary

## Commands

### Git Module (requires: `git`; `fzf` only for `gitco`, `gitwts`, and `gitwtr`)
| Command | Description |
|---------|-------------|
| `gits` | `git status` |
| `gitl` | `git log --oneline --decorate --graph` |
| `gitco` | `git checkout`; interactive branch selector when called without args (`fzf`) |
| `gitcm` | `git commit` |
| `gitp` | `git push` |
| `gitpl` | `git pull` |
| `gitwt` | `git worktree` |
| `gitwts` | Interactive worktree selector (`fzf`) |
| `gitwtr` | Interactive worktree remover (`fzf`, confirmation required) |

### Docker Module (requires: `docker`; `fzf` for all `dockerf*`)
| Command | Description |
|---------|-------------|
| `dockerfshell` | Interactive shell in container (`fzf`) |
| `dockerflogs` | View container logs (`fzf`, multi-select) |
| `dockerfrmi` | Remove images (`fzf`, multi-select) |
| `dockerfrm` | Remove containers (`fzf`, multi-select, forced) |
| `dockerfrun` | Run container from image (`fzf`) |
| `dockerfexec` | Execute command in container (`fzf`) |

### Tmux Module (requires: `tmux`)
| Command | Description |
|---------|-------------|
| `tmux` | Wrapped as `tmux -u` to force UTF-8 output mode for tmux servers started from zsh |

## fzf Missing Behavior
- Matches PowerShell profile behavior.
- If `fzf` is not available, interactive commands are skipped with a clear message.
- Non-`fzf` parts of the profile continue to work.

## Docker Completion Caching
- Cache file: `${XDG_CONFIG_HOME:-$HOME/.config}/zsh/cache/docker_completion.zsh`
- Regeneration policy: regenerate when missing or older than 30 days
- Failure behavior: silently skip completion generation (profile load continues)

## Tmux UTF-8 Behavior
- The tmux module wraps `tmux` as `tmux -u` from zsh.
- This prevents tmux from starting in non-UTF-8 output mode, which would otherwise replace Nerd Font and prompt icons with `_`.
- Existing tmux servers keep their original mode; after enabling this module, restart tmux with `tmux kill-server`.

## Testing

```zsh
# Syntax checks
zsh -n packages/zsh/.zshrc
zsh -n packages/zsh/conf.d/05-utils.zsh
zsh -n packages/zsh/conf.d/10-git.zsh
zsh -n packages/zsh/conf.d/15-tmux.zsh
zsh -n packages/zsh/conf.d/20-docker.zsh

# Diagnostics
zsh packages/zsh/test/test-profile-commands.zsh
```
