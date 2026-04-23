# Ghostty Package

This guide explains the Ghostty config files under `packages/ghostty/` and how they participate in the repository workflow.

Ghostty is a Dotter-managed Unix config package. The host install list installs the Ghostty application only on macOS through Homebrew cask; Linux may deploy the config when the package is selected, but this repo does not install a Linux Ghostty package.

## Design Intent

- Mirror the repo-managed WezTerm visual baseline where Ghostty has direct equivalents: custom palette, fallback font stack, zero padding, hidden scrollbar, blinking block cursor, right-click paste, no copy-on-select, and a static backdrop.
- Keep the config plain Ghostty syntax so Dotter can symlink the package without template rendering.
- Preserve the current terminal interaction bindings where Ghostty supports them: `F11` fullscreen, `Alt+C` copy, `Alt+V` paste, and `Ctrl+N` new window.
- Use one static background image instead of porting the WezTerm Lua backdrop selector.

## Structure

| Path | Role |
| --- | --- |
| `packages/ghostty/config.ghostty` | Ghostty entrypoint loaded as `~/.config/ghostty/config.ghostty` |
| `packages/ghostty/themes/custom` | WezTerm-derived theme translated to Ghostty color and palette syntax |
| `packages/ghostty/backdrops/pastel-samurai.acrylic.png` | Static background image reused from the WezTerm package |

## Configuration Model

Ghostty loads `config.ghostty` from `$XDG_CONFIG_HOME/ghostty/`, or from `~/.config/ghostty/` when `XDG_CONFIG_HOME` is unset. Dotter deploys the package so the final layout is:

```text
~/.config/ghostty/config.ghostty
~/.config/ghostty/themes/custom
~/.config/ghostty/backdrops/pastel-samurai.acrylic.png
```

The `theme = custom` setting relies on Ghostty's theme lookup under `~/.config/ghostty/themes/`. The `background-image = backdrops/pastel-samurai.acrylic.png` setting uses a relative path, so `backdrops/` must remain beside `config.ghostty`.

Ghostty background images require Ghostty 1.2.0 or newer and currently support PNG or JPEG files. This package uses `backdrops/pastel-samurai.acrylic.png` with `background-image-fit = cover`, centered positioning, no repeat, and `background-image-opacity = 0.3`.

Because Ghostty applies the background image per terminal surface, split-heavy layouts may repeat the image across splits. Large images can also increase VRAM use.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `ghostty @macos | brew:cask:ghostty`. It is not in `packages/container.list`. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | Unix deploys `packages/ghostty` to `~/.config/ghostty` when the selected Dotter profile includes `ghostty`. The default Unix profile includes it; the container profile does not. |
| Post hook | No post hook. |

The `@macos` selector keeps Ghostty out of Linux and Windows package-manager installs. The `brew:cask:ghostty` alias tells `script/install.sh` to call Homebrew with `--cask` and to treat an already installed cask as satisfied even when no `ghostty` command is on `PATH`.

## Configuration Boundaries

- No Linux package-manager or PPA automation is included for Ghostty.
- No Windows Ghostty install or deployment path is included.
- No WezTerm Lua modules are ported.
- No dynamic background selector or acrylic backdrop mode is included.

## Validation Notes

Use static checks to confirm the guide, install-list entry, Dotter mappings, and shell syntax stay aligned. On a machine with Ghostty installed, run Dotter deployment, start Ghostty, and verify the custom theme, fallback fonts, keybinds, hidden scrollbar, zero padding, right-click paste, and static background image.

## Common Failure Modes

- Ghostty is older than 1.2.0, so background image options are unsupported.
- `themes/custom` is not beside the config directory, so `theme = custom` cannot resolve.
- `backdrops/pastel-samurai.acrylic.png` is not beside `config.ghostty`, so the background image path fails.
- One or more configured fonts are not installed, causing Ghostty to fall back to another family.
- Both `config.ghostty` and `config` exist in the target directory, and another file overrides the values from this package later in Ghostty's load order.
