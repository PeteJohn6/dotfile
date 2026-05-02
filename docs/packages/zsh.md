# Zsh Package

This guide explains the repo-managed zsh package under `packages/zsh/`. The package provides a modular interactive shell profile with Git, Docker, tmux, and Starship integration.

## Design Intent

- Keep `.zshrc` as a small loader and put behavior in ordered `conf.d/` modules.
- Skip rich profile behavior in sessions that cannot support interactive shell UX.
- Guard optional tool integrations so missing tools degrade locally rather than breaking profile startup.
- Keep zsh helper behavior close to the PowerShell profile where both shells expose the same workflows.

## Structure

| Path | Role |
| --- | --- |
| `packages/zsh/.zshrc` | Main zsh entrypoint |
| `packages/zsh/conf.d/05-utils.zsh` | Shared command checks, warning helper, and cache directory |
| `packages/zsh/conf.d/06-tty-guard.zsh` | Deleted-PTY guard for orphaned interactive shells |
| `packages/zsh/conf.d/07-starship.zsh` | Starship prompt initialization when `starship` is available |
| `packages/zsh/conf.d/08-misc.zsh` | Terminal declaration plus Linux user-level `uv` and `nvm` setup |
| `packages/zsh/conf.d/10-git.zsh` | Git shortcuts and worktree helpers |
| `packages/zsh/conf.d/15-tmux.zsh` | `tmux -u` wrapper |
| `packages/zsh/conf.d/20-docker.zsh` | Docker and `fzf` helpers plus completion cache |
| `packages/zsh/test/` | Package diagnostics |

## Configuration Model

`.zshrc` resolves `PROFILE_ROOT`, checks for minimal-session conditions, and loads `conf.d/*.zsh` in lexical order. Minimal mode skips repo-managed modules when any of these are true:

- `TERM=dumb`
- the shell is non-interactive
- stdin is not a TTY
- stdout is not a TTY

Set `PROFILE_DEBUG=1` before sourcing `.zshrc` to print either the minimal-mode reason or the loaded module list.

Module ordering is dependency-oriented:

- `05-utils.zsh` defines `test_command`, `profile_warn`, and `PROFILE_CACHE_DIR`.
- `06-tty-guard.zsh` exits orphaned interactive shells whose file descriptors point at deleted PTYs.
- `07-starship.zsh` initializes Starship only when the binary is available.
- `08-misc.zsh` declares `TERM=xterm-256color` and, on Linux, prepares `$HOME/.local/bin` plus `nvm`.
- `10-git.zsh` exports Git helpers only when `git` is available.
- `15-tmux.zsh` wraps `tmux` as `tmux -u` only when tmux is available.
- `20-docker.zsh` exports Docker helpers only when `docker` is available.

## Exported Helpers

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
| `tmux` | Wrapper that runs `command tmux -u "$@"` |

Docker helpers use the `dockerf*` naming convention for `fzf`-powered commands.

| Command | Description |
| --- | --- |
| `dockerfshell` | Select a running container and open `pwsh` or `bash` |
| `dockerflogs` | Select one or more containers and show logs |
| `dockerfrmi` | Select one or more images and remove them |
| `dockerfrm` | Select one or more containers and remove them forcibly |
| `dockerfrun` | Select a local image and run an interactive container |
| `dockerfexec` | Select a running container and execute an entered command |

When `fzf` is missing, interactive helpers print a clear message and return without failing profile startup.

## Completion Cache

Docker completion is cached at `${XDG_CONFIG_HOME:-$HOME/.config}/zsh/cache/docker_completion.zsh`. The Docker module regenerates the cache when it is missing or older than 30 days. Completion generation failures are ignored so profile startup can continue.

## Tmux UTF-8 Behavior

The tmux module wraps `tmux` as `tmux -u` from zsh. This prevents new tmux servers started from zsh from using a non-UTF-8 output mode that can replace Nerd Font and prompt icons with fallback characters.

Existing tmux servers keep their original mode; after enabling this module, restart tmux with `tmux kill-server` when UTF-8 rendering is wrong.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `zsh`. `packages/container.list` also includes `zsh`. |
| Pre-install | No package-specific pre-install rule. The package depends on the install stage making `zsh` available. |
| Dotter deployment | Unix deploys `.zshrc` to `~/.zshrc` and `conf.d/` to `~/.config/zsh/conf.d`. The default Unix and container Dotter profiles include `zsh`. |
| Post hook | No post hook. |

## Validation Notes

Use `zsh -n` on `.zshrc` and edited modules for syntax checks. Use `packages/zsh/test/test-profile-commands.zsh` for package diagnostics; it accounts for either rich-mode command availability or minimal-mode skips.

## Common Failure Modes

- Minimal-session checks skip modules in automation or redirected shells.
- Missing optional tools cause guarded modules or interactive helpers to return early.
- `fzf` is missing, so interactive Git and Docker helpers are unavailable.
- Docker completion cache generation fails because Docker is not running or the command is unavailable.
- Existing tmux servers need restart before the `tmux -u` wrapper affects server output mode.
