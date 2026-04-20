# WezTerm Package

This document explains the repo-managed WezTerm package under `packages/wezterm/`. It covers the package layout, the imported background system, and the validation path for package changes.

## Design Intent

- Keep the deployed WezTerm config minimal even while reusing upstream theme, font, and backdrop modules.
- Preserve the repository's existing Alacritty-style copy, paste, fullscreen, and new-window bindings.
- Ship a usable background-image system that works out of the box with a small sample image set and pre-rendered acrylic variants.
- Keep the deployment contract simple by stowing the whole package directory to `~/.config/wezterm` on every supported platform.

## Structure

| Path | Role |
| --- | --- |
| `packages/wezterm/wezterm.lua` | Package entrypoint and config assembly |
| `packages/wezterm/config/` | Appearance, bindings, fonts, and general behavior modules |
| `packages/wezterm/colors/custom.lua` | Imported theme definition |
| `packages/wezterm/utils/backdrops.lua` | Background image controller |
| `packages/wezterm/utils/platform.lua` | Lightweight platform detection |
| `packages/wezterm/backdrops/` | Sample images and user-added background assets |

## Core Patterns

- `wezterm.lua` must call `backdrops:set_images()` during initial config load because the image scan uses `wezterm.glob(...)`, which WezTerm expects to run from the top-level config evaluation path.
- The package keeps the upstream theme and background logic, but it intentionally does not import statusline, tab-title, launcher, workspace, or multiplexer modules.
- The background controller exposes four user modes as `(background, blur_backdrop)` mappings: original image with blur backdrop disabled, pre-rendered acrylic image with blur backdrop disabled, focus color with blur backdrop disabled, and platform blur backdrop with no custom background.
- The package starts in original-image mode. Acrylic mode uses pre-rendered `.acrylic.*` images when they exist, then falls back to the original image list or the focus-color mode.
- The default launched shell is platform-specific: Windows starts the WSL default distribution as `root` in `/home` and runs `tmux`, while macOS and Linux use `zsh -l`.
- The primary Latin font remains `SauceCodePro Nerd Font`; the Chinese fallback stack starts with `LXGW WenKai Mono` and appends a platform CJK font where configured. `cell_width` is pinned to `1.0` to avoid further widening the terminal grid.

## Key Bindings

- `F11` toggles fullscreen.
- `Alt+C` copies to the clipboard.
- `Alt+V` pastes from the clipboard.
- `Ctrl+N` opens a new WezTerm window.
- On Windows, `Shift+Alt+\` activates the WezTerm leader key for 3 seconds; the config binds this as mapped `|` with `ALT|SHIFT`.
- On Windows, leader then `p` opens a visible domain group selector:
  - `w` opens a fuzzy WSL domain selector and spawns the selected domain in a new tab.
  - `s` opens a fuzzy SSH domain selector and spawns the selected domain in a new tab.
  - `m` opens a fuzzy SSHMUX domain selector and attaches the selected mux domain.
- The default Windows startup command is `wsl.exe --cd /home --user root --exec tmux`, so new windows use the WSL default distribution without naming a distribution in the config.
- Background controls use the upstream modifier policy:
  - macOS: `SUPER+/` next backdrop, `SUPER|CTRL+/` selector, `SUPER+B` mode toggle
  - Windows and Unix: `ALT+/` next backdrop, `ALT|CTRL+/` selector, `ALT+B` mode toggle
- The mode toggle order is original image, pre-rendered acrylic image, focus, platform blur backdrop, then back to original image.
- Platform blur backdrop uses `win32_system_backdrop = "Acrylic"` with `window_background_opacity = 0.8` and `win32_acrylic_accent_color` on Windows, `macos_window_background_blur = 20` with `window_background_opacity = 0.3` on macOS, and `kde_window_background_blur = true` with `window_background_opacity = 0.4` on Linux.

## Background Assets

The package ships a small sample backdrop set so the background system is immediately testable after deployment. Each shipped backdrop has an original image and a pre-rendered acrylic PNG variant:

- `final-showdown.jpg` and `final-showdown.acrylic.png`
- `garden-pavilion.jpg` and `garden-pavilion.acrylic.png`
- `miku-kimono.jpg` and `miku-kimono.acrylic.png`
- `pastel-samurai.jpg` and `pastel-samurai.acrylic.png`
- `studentClassroom.jpg` and `studentClassroom.acrylic.png`

Additional image pairs can be dropped into `packages/wezterm/backdrops/`. Files whose names contain `.acrylic.`, `.acrylic-`, or `.acrylic_` are treated as acrylic variants by the background controller.

## Validation Design

- Validate Dotter deployment first so path and package-name regressions surface before runtime debugging.
- When package configuration changes, use the repository devcontainer workflow to prove that the Unix `bootstrap -> install -> stow -> post` contract still holds.
- After static checks, run WezTerm on a machine with the terminal installed and exercise the background shortcuts to confirm the runtime behavior.

## Fast Checks

| Task | Command |
| --- | --- |
| Windows dry-run | `dotter.exe deploy --dry-run` |
| Unix dry-run in devcontainer | `./bin/dotter deploy --dry-run` |
| Full workflow in devcontainer | `just install && just stow && just post` |

## Common Failure Modes

- missing sample images causing the background system to fall back to focus mode
- invalid Lua syntax in one of the imported modules
- a missing font resulting in WezTerm falling back to a different family than intended
- Linux platform blur backdrop requires a WezTerm build that supports `kde_window_background_blur`
- drift between README examples, Dotter defaults, and the actual maintained package list
- upstream backdrop asset shape changing if the package is refreshed from the original source repository
