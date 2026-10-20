# Terminal Emulator Packages

This guide is the entry point for repo-managed terminal emulator docs and adjacent shell multiplexer docs. It defines the shared terminal key model, then points to package-specific guides for lifecycle, deployment, and implementation details.

## Guide Map

| Guide | Role in this map | Boundary |
| --- | --- | --- |
| [alacritty.md](terminal/alacritty.md) | Terminal emulator package | Dotter-rendered config and themes; no native terminal tabs |
| [wezterm.md](terminal/wezterm.md) | Terminal emulator package | Dotter-managed config with terminal tabs and WezTerm-specific background controls |
| [ghostty.md](terminal/ghostty.md) | Terminal emulator package | Dotter-rendered Unix config with automatic platform defaults and macOS Command-to-Meta navigation |
| [tmux.md](terminal/tmux.md) | Shell multiplexer/keybinding owner | Owns bare `Alt` pane, tmux-window, and tmux-session navigation inside the shell |
| [zellij.md](terminal/zellij.md) | Adjacent multiplexer config | Repo-maintained but not installed, deployed, or wired into post hooks |

This page does not cover zsh, Starship, or Neovim's built-in terminal. Those guides may mention terminal behavior where it affects their own package, but they are outside this terminal emulator and multiplexer navigation map.

## Font Model

Terminal emulator packages should use `SauceCodePro Nerd Font` as the primary Latin font. The Chinese fallback stack starts with `LXGW WenKai Mono`, then appends a platform CJK font where the terminal supports fallback stacks.

The maintained terminal font-size target is:

| Platform | Font size |
| --- | --- |
| macOS | `18` |
| Windows | current package default, currently `13` |
| Linux | current package default, currently `13` |

Package-specific config files may express this model differently depending on terminal support. WezTerm owns the explicit platform fallback stack in `packages/wezterm/config/fonts.lua`; Alacritty and Ghostty keep their font settings in their native config files.

## Key Binding Model

Terminal emulator bindings and tmux bindings are separate layers.

The terminal emulator layer owns application-level terminal actions such as terminal tabs, terminal windows, fullscreen, copy, paste, and background controls. These bindings must avoid bare `Alt` for navigation-style actions because bare `Alt` is reserved for tmux.

Terminal-level bindings use a platform terminal modifier for shortcuts that would commonly be described as `Alt` on Windows: macOS uses `Command`, while Windows and Linux use `Alt`. This mapping keeps terminal-level actions on the outer terminal layer without taking over tmux's literal bare `Alt` navigation layer.

The tmux layer owns pane, tmux-window, and tmux-session navigation inside the shell. `packages/tmux/conf.d/10-keybindings.conf` is the source of truth for these bindings.

### tmux Navigation Layer

tmux uses bare `Alt` for high-frequency navigation:

| Key | Meaning |
| --- | --- |
| `Alt+h` | Move to the pane on the left |
| `Alt+j` | Move to the pane below |
| `Alt+k` | Move to the pane above |
| `Alt+l` | Move to the pane on the right |
| `Alt+,` | Previous tmux window |
| `Alt+.` | Next tmux window |
| `Alt+[` | Previous tmux client/session |
| `Alt+]` | Next tmux client/session |
| `Alt+t` | New tmux window in the current pane path |
| `Alt+w` | Kill the current tmux window |

Terminal emulator packages must not bind these same bare `Alt` navigation keys for terminal-level actions.

### Terminal Emulator Tab Layer

Terminal emulators use `Shift` plus the platform terminal modifier for terminal-tab actions:

| Action | macOS | Windows/Linux |
| --- | --- | --- |
| New terminal tab | `Shift+Command+t` | `Shift+Alt+t` |
| Close terminal tab | `Shift+Command+w` | `Shift+Alt+w` |
| Previous terminal tab | `Shift+Command+,` | `Shift+Alt+,` |
| Next terminal tab | `Shift+Command+.` | `Shift+Alt+.` |

Terminal tabs may stay visually hidden when the emulator supports hidden tab bars. The binding contract is still valid: tabs are available as an outer terminal layer, while tmux remains the primary pane/window manager inside the shell.

### Terminal Interaction Bindings

These terminal interaction bindings stay shared where the emulator supports them:

| Key | Meaning |
| --- | --- |
| `F11` | Toggle fullscreen |
| `Alt+C` | Copy to clipboard |
| `Alt+V` | Paste from clipboard |
| `Ctrl+N` | New terminal window |
| Right click | Paste from clipboard |

These bindings are not tmux navigation bindings, so they may remain outside the terminal-tab modifier policy.

### Package Notes

[alacritty.md](terminal/alacritty.md) covers the Alacritty terminal emulator package. Alacritty does not provide native terminal tabs, so it implements the shared interaction bindings but not the terminal-tab bindings.

[wezterm.md](terminal/wezterm.md) covers the WezTerm terminal emulator package. WezTerm must implement terminal-tab bindings with the platform terminal modifier: `Shift+Command+t`, `Shift+Command+w`, `Shift+Command+,`, and `Shift+Command+.` on macOS, with `Command` replaced by `Alt` on Windows and Linux. WezTerm-specific background controls should also avoid bare `Alt` so they do not compete with tmux.

[ghostty.md](terminal/ghostty.md) covers the Ghostty terminal emulator package. Dotter selects macOS Command or Linux Alt automatically for clipboard shortcuts and, combined with Shift, terminal-tab bindings. On macOS, Command+h/j/k/l, comma, period, brackets, t, and w explicitly send CSI-u Meta sequences to tmux, with each binding preceded by its matching unbind. Linux output omits these Command bindings and unbinds. Ghostty does not globally remap Command to Alt. Unrelated defaults remain available. Ghostty supports `keybind = trigger=action`, `unbind`, and tab actions such as `new_tab`, `previous_tab`, and `next_tab`.

[tmux.md](terminal/tmux.md) covers the maintained shell multiplexer package. tmux is not a terminal emulator package, but it owns the bare `Alt` navigation layer that terminal emulator packages must preserve.

[zellij.md](terminal/zellij.md) covers the adjacent Zellij multiplexer config. Zellij is not a terminal emulator package, and its config is repo-maintained but not wired into install, Dotter deployment, or post hooks.
