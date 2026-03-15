# Tmux - Modular Configuration

Lightweight tmux configuration for Unix-like environments, with a WezTerm-inspired key layout.

## Prerequisites
- tmux
- git (required for TPM bootstrap in `just post`)

## Load Behavior
- Main entrypoint: `~/.tmux.conf`
- Modules: `~/.tmux.d/*.conf` loaded in numeric order
- Helper scripts: `~/.tmux.d/bin/*`
- Plugin manager: TPM (`~/.tmux/plugins/tpm`)

## Module Layout
- `00-options.conf`: terminal, history, mouse, indexing, clipboard, activity monitoring
- `10-keybindings.conf`: root bindings, leader, direct navigation, copy/scroll helpers
- `11-keytables.conf`: WezTerm-style `window`, `pane`, `session` groups
- `20-status.conf`: WezTerm-inspired status line with key table, session, and window-state blocks
- `90-plugins.conf`: TPM and plugin declarations

## Navigation Model
- WezTerm `tab` maps to tmux `window`
- WezTerm `pane` maps to tmux `pane`
- WezTerm `domain/workspace` maps to tmux `session`
- Tmux prefix is `Alt+\`

## Key Groups
- `prefix + t`: window group
- `prefix + p`: pane group
- `prefix + s`: session group

## Direct Keys
- `Alt+h/j/k/l`: move between panes
- `Alt+,` / `Alt+.`: previous / next window
- `Alt+Enter`: zoom pane
- `Alt+w`: kill pane
- `Alt+u` / `Alt+d`: scroll tmux history
- `Alt+f`: search tmux scrollback
- `F2`: enter copy-mode
- `F3`: open tree chooser
- `F4`: open window chooser
- `F5` / `F6`: open session chooser

## Session Workflow
- `prefix + s n`: create or reuse a session based on the current pane directory
- Session names are derived from the current directory basename and sanitized for tmux
- The helper script lives at `~/.tmux.d/bin/session-from-path.sh`

## Status Line
- Left status uses orange icon blocks for `LEADER` and active key tables
- Window blocks are left-justified so they grow from left to right like a tab strip
- Active windows use a green block; inactive windows use a dark gray block
- Right status uses a compact orange session block only
- Inactive windows with unseen activity or bell state get `!` / `*` markers inside the window block
- This layout expects a Nerd Font-capable terminal for the icons to render cleanly

## Plugins
- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
