# Tmux - Modular Configuration

Lightweight tmux configuration for Unix-like environments.

## Prerequisites
- tmux
- git (required for TPM bootstrap in `just post`)

## Load Behavior
- Main entrypoint: `~/.tmux.conf`
- Modules: `~/.tmux.d/*.conf` loaded in numeric order
- Plugin manager: TPM (`~/.tmux/plugins/tpm`)

## Module Layout
- `00-options.conf`: terminal, history, mouse, indexing, clipboard
- `10-keybindings.conf`: reload, split panes, navigation, copy-mode
- `20-status.conf`: minimal status bar
- `90-plugins.conf`: TPM and plugin declarations

## Plugins
- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`

## Usage
Add `tmux` to `.dotter/local.toml`, then run:

```bash
just install
just stow
just post
```

Reload an active tmux session with `prefix + r`.
