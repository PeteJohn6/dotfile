# Ghostty Package

This guide explains the Ghostty config files under `packages/ghostty/` and how they participate in the repository workflow.

Ghostty is a Dotter-managed Unix config package. The host install list installs the Ghostty application only on macOS through Homebrew cask; Linux may deploy the config when the package is selected, but this repo does not install a Linux Ghostty package.

## Design Intent

- Generate a plain Ghostty config from a Dotter template because Ghostty's native config is simple `key = value` syntax, not a programmable config language.
- Mirror the repo-managed terminal visual baseline where Ghostty has direct equivalents: custom palette, fallback font stack, zero padding, hidden scrollbar, blinking block cursor, right-click paste, no copy-on-select, and a static backdrop.
- Preserve the shared terminal interaction bindings where Ghostty supports them: `F11` fullscreen, `Ctrl+N` new window, and clipboard shortcuts using Command on macOS or Alt on Linux.
- Select terminal-tab shortcuts, font size, and platform CJK fallback automatically for macOS and Linux, following the shared model in [terminal.md](../terminal.md).
- Use one static background image instead of porting the WezTerm Lua backdrop selector.

## Structure

| Path | Role |
| --- | --- |
| `packages/ghostty/config.ghostty.tmpl` | Dotter-rendered Ghostty entrypoint deployed as `~/.config/ghostty/config.ghostty` |
| `packages/ghostty/themes/custom` | WezTerm-derived theme translated to Ghostty color and palette syntax |
| `packages/ghostty/backdrops/pastel-samurai.acrylic.png` | Static background image reused from the WezTerm package |

## Platform Defaults

Dotter renders `packages/ghostty/config.ghostty.tmpl` before Ghostty reads it. The template uses Dotter's `dotter.macos` and `dotter.linux` booleans, available in Dotter 0.13.4 or newer, to select defaults for the platform running Dotter. The generated file contains ordinary Ghostty syntax without template expressions.

| Setting | macOS | Linux |
| --- | --- | --- |
| Terminal-tab modifier, combined with Shift | `super` (Command) | `alt` |
| Font size | `18` | `13` |
| Platform CJK fallback | `PingFang SC` | `Noto Sans CJK SC` |

Platform selection does not require local variables. The four tab shortcuts are defined directly by platform in the template; `ghostty_terminal_modifier` is no longer read. In Ghostty, `super` is the canonical name for macOS Command; `cmd` and `command` are aliases.

Font size and platform CJK fallback are defined directly in the template's platform branches. The shared fallback stack starts with `SauceCodePro Nerd Font` and `LXGW WenKai Mono Lite`.

## Configuration Model

Ghostty loads `config.ghostty` from `$XDG_CONFIG_HOME/ghostty/`, or from `~/.config/ghostty/` when `XDG_CONFIG_HOME` is unset. Dotter deploys the package so the final layout is:

```text
~/.config/ghostty/config.ghostty
~/.config/ghostty/themes/custom
~/.config/ghostty/backdrops/pastel-samurai.acrylic.png
```

The `theme = custom` setting relies on Ghostty's theme lookup under `~/.config/ghostty/themes/`. The `background-image = backdrops/pastel-samurai.acrylic.png` setting uses a relative path, so `backdrops/` must remain beside `config.ghostty`.

On macOS, Ghostty loads XDG config first and then loads config under `~/Library/Application Support/com.mitchellh.ghostty/`. If a file exists in that macOS-specific directory, later conflicting values there can override this Dotter-managed XDG config.

## Background Boundaries

Ghostty background images require Ghostty 1.2.0 or newer and currently support PNG or JPEG files. This package uses `backdrops/pastel-samurai.acrylic.png` with `background-image-fit = cover`, centered positioning, no repeat, and `background-image-opacity = 0.3`.

Because Ghostty applies the background image per terminal surface, split-heavy layouts may repeat the image across splits. Large images can also increase VRAM use. This package does not include WezTerm's dynamic background selector, acrylic mode, or Lua backdrop controller.

Ghostty documents `window-show-tab-bar = never`, but currently marks that value as Linux GTK-only. Do not rely on this package to hide Ghostty's tab bar on macOS; the keybinding contract is independent of tab bar visibility.

## Key Bindings

Ghostty uses `keybind = trigger=action` entries in the rendered config for explicit bindings. It also supports `keybind = trigger=unbind` to remove a previously bound Ghostty or user keybind.

Shared interaction bindings:

| Key | Action |
| --- | --- |
| `F11` | `toggle_fullscreen` |
| `Command+C` (macOS) / `Alt+C` (Linux) | `copy_to_clipboard` |
| `Command+V` (macOS) / `Alt+V` (Linux) | `paste_from_clipboard` |
| `Ctrl+N` | `new_window` |

Dotter selects Shift+Command (`super`) on macOS or Shift+Alt on Linux for terminal-tab actions: t opens a tab, w closes it, comma selects the previous tab, and period selects the next tab. Clipboard shortcuts use Command+C/V on macOS or Alt+C/V on Linux.

On macOS, Command navigation explicitly sends CSI-u Meta keys to tmux, matching `packages/tmux/conf.d/10-keybindings.conf`. Linux output omits these Command bindings and their unbinds. There is no global Command-to-Alt remap. Physical Alt navigation continues through Ghostty's normal input encoding.

| Command key | Ghostty action | tmux key |
| --- | --- | --- |
| h | `csi:104;3u` | `M-h` |
| j | `csi:106;3u` | `M-j` |
| k | `csi:107;3u` | `M-k` |
| l | `csi:108;3u` | `M-l` |
| comma | `csi:44;3u` | `M-,` |
| period | `csi:46;3u` | `M-.` |
| left bracket | `csi:91;3u` | `M-[` |
| right bracket | `csi:93;3u` | `M-]` |
| t | `csi:116;3u` | `M-t` |
| w | `csi:119;3u` | `M-w` |

The `csi` action supplies the ESC [ header. The character number and modifier 3 encode an Alt/Meta key, followed by `u`. See the [Ghostty action reference](https://ghostty.org/docs/config/keybind/reference#csi).

Punctuation triggers use literal characters (`super+,`, `super+.`, `super+[`, and `super+]`) to replace the Unicode bindings used by native menus. Names such as `comma` identify physical keys and do not replace the default Unicode `super+,=open_config` or `shift+super+,=reload_config` entries.

Each tmux shortcut has its unbind directly before the CSI binding. Command+h uses a consuming CSI binding that replaces native Hide. Unrelated defaults remain available.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `ghostty @macos | brew:cask:ghostty`. It is not in `packages/container.list`. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | Unix renders `packages/ghostty/config.ghostty.tmpl` to `~/.config/ghostty/config.ghostty` and deploys `themes/` and `backdrops/` beside it when the selected Dotter profile includes `ghostty`. The default Unix profile includes it; the container profile does not. |
| Post hook | No post hook. |

The `@macos` selector keeps Ghostty out of Linux and Windows package-manager installs. The `brew:cask:ghostty` alias tells `script/install.sh` to call Homebrew with `--cask` and to treat an already installed cask as satisfied even when no `ghostty` command is on `PATH`.

## Configuration Boundaries

- No Linux package-manager or PPA automation is included for Ghostty.
- No Windows Ghostty install or deployment path is included.
- No WezTerm Lua modules are ported.
- No dynamic background selector or acrylic backdrop mode is included.
- No Ghostty runtime platform detection is expected from the generated file; Dotter resolves platform conditions before Ghostty starts.

## Validation Notes

When validating this package, use Dotter dry-runs to confirm the rendered config target and asset directory targets. Render a fresh profile on macOS and Linux: macOS should produce size `18`, `PingFang SC`, and `shift+super` tab shortcuts; Linux should produce size `13`, `Noto Sans CJK SC`, and `shift+alt` tab shortcuts without macOS Command bindings or unbinds. Render on each platform to check its branch.

On a machine with Ghostty installed, inspect the final effective keybinding map with `ghostty +list-keybinds` using the isolated config, as well as the generated lines. The macOS render must contain all ten Super CSI actions above, all four Shift+Super tab actions, and Super clipboard actions. The Linux render must contain all four Shift+Alt tab actions and Alt clipboard actions, with no custom Super CSI bindings. The ten reserved bare Alt navigation keys must reach tmux. `ghostty +list-keybinds --default` shows native defaults rather than proving the generated bindings are effective. Starting Ghostty can additionally check the custom theme, fallback fonts, keybinds, hidden scrollbar, zero padding, right-click paste, and static background image.

## Common Failure Modes

- Ghostty is older than 1.2.0, so background image options are unsupported.
- `themes/custom` is not beside the config directory, so `theme = custom` cannot resolve.
- `backdrops/pastel-samurai.acrylic.png` is not beside `config.ghostty`, so the background image path fails.
- One or more configured fonts are not installed, causing Ghostty to fall back to another family.
- A macOS-specific Ghostty config exists under `~/Library/Application Support/com.mitchellh.ghostty/` and overrides the Dotter-managed XDG config.
- Dotter is older than 0.13.4 and does not provide the platform booleans used by the template.
