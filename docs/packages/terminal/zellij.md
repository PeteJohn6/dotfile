# Zellij Package

This guide explains the repo-maintained Zellij config under `packages/zellij/`. The package currently stores an inert config file: it is not installed, deployed by Dotter, or used by post hooks.

## Design Intent

- Keep a Zellij config available for users who want a multiplexer option beside tmux.
- Mirror the tmux package's high-frequency direct navigation keys where Zellij has close equivalents.
- Keep Zellij's default keybindings intact and add only a small normal-mode direct-key layer.
- Avoid claiming support in the maintained workflow until the config is wired into install and deployment paths.

## Structure

| Path | Role |
| --- | --- |
| `packages/zellij/config.kdl` | Zellij config file maintained in the repo but not deployed by Dotter |

## Configuration Model

The config sets `/bin/zsh` as the default shell, detaches on force close, enables pane frames and mouse mode, increases scrollback to 100000 lines, uses system clipboard copy, enables copy-on-select, selects `catppuccin-macchiato`, and hides startup tips and release notes.

Normal-mode direct keys mirror the tmux package's frequent navigation layer:

- `Alt h` moves focus left or to the previous tab.
- `Alt j` moves focus down.
- `Alt k` moves focus up.
- `Alt l` moves focus right or to the next tab.
- `Alt ,` and `Alt .` move to previous and next tabs.
- `Alt t` creates a new tab.
- `Alt w` closes the current tab.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | No entry in `packages/packages.list` or `packages/container.list`. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | No Dotter mapping. The config is not selected by default Unix, Windows, or container profiles. |
| Post hook | No post hook. |

## Configuration Boundaries

- Zellij default keybindings remain enabled.
- This repository does not install Zellij.
- This repository does not deploy `packages/zellij/config.kdl` to `~/.config/zellij/config.kdl`.
- This repository does not manage Zellij plugins or layouts.

## Validation Notes

On a machine with Zellij installed, load the config explicitly with Zellij's config option and verify the direct keys. Repo static validation should confirm the file remains outside current install lists and Dotter mappings unless lifecycle behavior is intentionally changed.

## Common Failure Modes

- Users expect the config to be deployed even though it has no Dotter mapping.
- `/bin/zsh` is unavailable on a host where the config is loaded manually.
- The active terminal does not send the expected `Alt` key sequences.
