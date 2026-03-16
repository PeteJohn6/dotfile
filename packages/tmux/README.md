# Tmux - Modular Configuration

Lightweight tmux configuration for Unix-like environments, with a minimal direct-navigation layer on top of tmux defaults.

## Prerequisites
- tmux
- git (required for TPM bootstrap in `just post`)

## Load Behavior
- Main entrypoint: `~/.tmux.conf`
- Modules are sourced in this order: `00-options.conf`, `90-plugins.conf`, `10-keybindings.conf`, `20-status.conf`
- Plugin manager: TPM (`~/.tmux/plugins/tpm`)

## Module Layout
- `00-options.conf`: terminal, history, mouse, indexing, clipboard, activity monitoring
- `10-keybindings.conf`: tmux-default prefix plus direct pane/window/session bindings
- `20-status.conf`: WezTerm-inspired status line with key table, session, and window-state blocks
- `90-plugins.conf`: TPM and plugin declarations

## Navigation Model
- Tmux prefix remains the default `C-b`
- `prefix + r`: reload `~/.tmux.conf`
- `prefix + w`: view windows/tree
- `prefix + s`: view sessions

## Direct Keys
- `Alt+h/j/k/l`: move between panes
- `Alt+,` / `Alt+.`: previous / next window
- `Alt+{` / `Alt+}`: previous / next session
- `Alt+t`: create a new window in the current pane path
- `Alt+w`: kill the current window

## Status Line
- Left status uses orange icon blocks for `LEADER` and any active non-root key table
- Window blocks are left-justified so they grow from left to right like a tab strip
- Active windows use a green block; inactive windows use a dark gray block
- Right status uses a compact orange session block only
- Inactive windows with unseen activity or bell state get `!` / `*` markers inside the window block
- This layout expects a Nerd Font-capable terminal for the icons to render cleanly

## Plugins
- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
