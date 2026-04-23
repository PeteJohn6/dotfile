# WezTerm Package

This guide explains the repo-managed WezTerm package under `packages/wezterm/`. It covers the package layout, the imported background system, lifecycle integration, and validation notes.

## Design Intent

- Keep the deployed WezTerm config minimal while reusing upstream theme, font, and backdrop modules.
- Preserve the repository's existing Alacritty-style copy, paste, fullscreen, and new-window bindings.
- Ship a usable background-image system that works out of the box with a small sample image set and pre-rendered acrylic variants.
- Keep the deployment contract simple by stowing the whole package directory to `~/.config/wezterm` on every supported platform profile.

## Structure

| Path | Role |
| --- | --- |
| `packages/wezterm/wezterm.lua` | Package entrypoint and config assembly |
| `packages/wezterm/config/` | Appearance, bindings, fonts, and general behavior modules |
| `packages/wezterm/colors/custom.lua` | Imported theme definition |
| `packages/wezterm/utils/backdrops.lua` | Background image controller |
| `packages/wezterm/utils/platform.lua` | Lightweight platform detection |
| `packages/wezterm/backdrops/` | Sample images and user-added background assets |

## Configuration Model

`wezterm.lua` calls `backdrops:set_images()` during initial config load because the image scan uses `wezterm.glob(...)`, which WezTerm expects to run from the top-level config evaluation path.

The package keeps the upstream theme and background logic, but it does not import statusline, tab-title, launcher, workspace, or multiplexer modules.

The background controller exposes four user modes as `(background, blur_backdrop)` mappings: original image with blur backdrop disabled, pre-rendered acrylic image with blur backdrop disabled, focus color with blur backdrop disabled, and platform blur backdrop with no custom background. The package starts in original-image mode. Acrylic mode uses pre-rendered `.acrylic.*` images when they exist, then falls back to the original image list or the focus-color mode.

The default launched shell is platform-specific: Windows starts the WSL default distribution as `root` in `/home` and runs `tmux`, while macOS and Linux use `zsh -l`.

The primary Latin font is `SauceCodePro Nerd Font`; the Chinese fallback stack starts with `LXGW WenKai Mono` and appends a platform CJK font where configured. `cell_width` is pinned to `1.0` to avoid further widening the terminal grid.

## Key Bindings

- `F11` toggles fullscreen.
- `Alt+C` copies to the clipboard.
- `Alt+V` pastes from the clipboard.
- `Ctrl+N` opens a new WezTerm window.
- On Windows, `Shift+Alt+\` activates the WezTerm leader key for 3 seconds.
- On Windows, leader then `p` opens a visible domain group selector for WSL, SSH, and SSHMUX domains.
- Background controls use the upstream modifier policy:
  - macOS: `SUPER+/` next backdrop, `SUPER|CTRL+/` selector, `SUPER+B` mode toggle
  - Windows and Unix: `ALT+/` next backdrop, `ALT|CTRL+/` selector, `ALT+B` mode toggle

The mode toggle order is original image, pre-rendered acrylic image, focus, platform blur backdrop, then back to original image.

## Background Assets

The package ships a small sample backdrop set so the background system is immediately testable after deployment. Each shipped backdrop has an original image and a pre-rendered acrylic PNG variant:

- `final-showdown.jpg` and `final-showdown.acrylic.png`
- `garden-pavilion.jpg` and `garden-pavilion.acrylic.png`
- `miku-kimono.jpg` and `miku-kimono.acrylic.png`
- `pastel-samurai.jpg` and `pastel-samurai.acrylic.png`
- `studentClassroom.jpg` and `studentClassroom.acrylic.png`

Additional image pairs can be dropped into `packages/wezterm/backdrops/`. Files whose names contain `.acrylic.`, `.acrylic-`, or `.acrylic_` are treated as acrylic variants by the background controller.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `wezterm @macos,windows`. It is not in `packages/container.list`. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | Unix and Windows Dotter profiles deploy `packages/wezterm` to `~/.config/wezterm` when the selected profile includes `wezterm`. |
| Post hook | No post hook. |

## Validation Notes

Use Dotter dry-runs to confirm the package directory target. After Lua or asset changes, start WezTerm on a machine with the terminal installed and exercise the background shortcuts, platform shell launch, and common keybindings.

## Common Failure Modes

- Missing sample images causing the background system to fall back to focus mode.
- Invalid Lua syntax in one of the imported modules.
- A missing font resulting in WezTerm falling back to a different family than intended.
- Linux platform blur backdrop requires a WezTerm build that supports `kde_window_background_blur`.
- Drift between Dotter defaults, package-list entries, and the actual maintained package directory.
- Upstream backdrop asset shape changing if the package is refreshed from the original source repository.
