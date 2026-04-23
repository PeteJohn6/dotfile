# Tmux Package

This guide explains the repo-managed tmux package under `packages/tmux/`. The package provides a modular tmux config for Unix-like environments with a small direct-navigation layer on top of tmux defaults.

## Design Intent

- Keep tmux defaults recognizable, including the default `C-b` prefix.
- Add direct keys only for frequent pane, window, and session navigation.
- Keep options, keybindings, status styling, and plugins in separate modules.
- Use TPM for plugin management while keeping the post hook idempotent.

## Structure

| Path | Role |
| --- | --- |
| `packages/tmux/.tmux.conf` | Main tmux entrypoint deployed to `~/.tmux.conf` |
| `packages/tmux/conf.d/00-options.conf` | Terminal, history, mouse, indexing, clipboard, and activity options |
| `packages/tmux/conf.d/10-keybindings.conf` | Prefix behavior, restored defaults, direct navigation keys |
| `packages/tmux/conf.d/20-status.conf` | WezTerm-inspired status line |
| `packages/tmux/conf.d/90-plugins.conf` | TPM and plugin declarations |
| `packages/post/tmux.sh` | Unix post hook for TPM bootstrap and plugin sync |

## Configuration Model

`.tmux.conf` sources modules in this order:

1. `00-options.conf`
2. `90-plugins.conf`
3. `10-keybindings.conf`
4. `20-status.conf`

Plugins load before user keybindings so local keybinding choices can override plugin defaults. The current plugin set is:

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`

Core options set `/bin/zsh` as the default shell, `tmux-256color` as the default terminal, RGB terminal overrides, a 100000-line history, mouse support, one-based indexes, automatic window renumbering, activity monitoring, and clipboard integration.

## Navigation Model

- Prefix remains `C-b`.
- `prefix + r` reloads `~/.tmux.conf`.
- `prefix + w` opens the windows/tree view.
- `prefix + s` opens the session tree.
- `Alt+h/j/k/l` moves between panes.
- `Alt+,` and `Alt+.` move to the previous and next window.
- `Alt+[` and `Alt+]` switch to the previous and next tmux client/session.
- `Alt+t` creates a new window in the current pane path.
- `Alt+w` kills the current window.

The keybinding module also removes bindings from the older layout during reload so stale root bindings do not linger in a running tmux server.

## Status Line

The status line is bottom-positioned, left-justified, and inspired by the repo-managed WezTerm styling:

- left status shows orange blocks for active prefix and non-root key table state
- window blocks grow left to right like a tab strip
- active windows use a green block
- inactive windows use dark gray blocks
- unseen activity and bell states show `!` and `*` markers inside the window block
- right status shows the current session name in a compact orange block

This layout assumes a Nerd Font-capable terminal for icons.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `tmux @macos,linux`. `packages/container.list` also includes `tmux`. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | Unix deploys `.tmux.conf` to `~/.tmux.conf` and `conf.d/` to `~/.tmux.d`. The default Unix and container Dotter profiles include `tmux`. |
| Post hook | `packages/post/tmux.sh` installs or updates TPM and runs TPM plugin installation. |

The post hook skips when `tmux` or `git` is missing. Otherwise it installs or updates `~/.tmux/plugins/tpm`, checks for `bin/install_plugins`, and runs it with `TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins/"`.

## Validation Notes

Use `tmux source-file packages/tmux/.tmux.conf` in an isolated tmux session to catch syntax and reload issues. After plugin changes, run `packages/post/tmux.sh` on a machine with `tmux` and `git` and confirm TPM plugin installation completes.

## Common Failure Modes

- TPM is absent because the post hook has not run.
- `git` is missing, so the post hook skips TPM bootstrap.
- A terminal does not send the expected `Alt` key sequences.
- Nerd Font symbols in the status line render with fallback glyphs.
- Existing tmux servers keep older option state until the config is reloaded or the server is restarted.
