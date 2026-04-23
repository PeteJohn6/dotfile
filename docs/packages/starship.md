# Starship Package

This guide explains the repo-managed Starship package under `packages/starship/`. The package only maintains Nerd Font symbol overrides for Starship modules.

## Design Intent

- Keep Starship prompt layout on Starship defaults.
- Override symbols so prompts render consistently in Nerd Font-capable terminals.
- Avoid duplicating shell-specific prompt setup; shell profiles initialize Starship when the binary is present.

## Structure

| Path | Role |
| --- | --- |
| `packages/starship/nerd-font-symbols.toml` | Starship TOML deployed as `~/.config/starship.toml` |

## Configuration Model

`nerd-font-symbols.toml` defines module symbols for languages, package ecosystems, cloud providers, operating systems, and repository state. It does not define `format`, `right_format`, module enablement, prompt timing, or command-duration behavior.

The file assumes the active terminal font can render Nerd Font glyphs. Terminal packages in this repository configure Nerd Font-capable font stacks, but Starship itself does not enforce font installation.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `starship`. `packages/container.list` also includes `starship`. |
| Pre-install | `packages/pre-install-unix.sh` maps `starship` to `preinstall_starship`. |
| Dotter deployment | Global Dotter config deploys `packages/starship/nerd-font-symbols.toml` to `~/.config/starship.toml`. Default Unix, Windows, and container profiles include `starship`. |
| Post hook | No post hook. |

`preinstall_starship` runs only on Linux. It skips when `starship` is already on `PATH`, requires `curl` and `sh`, creates `INSTALL_BIN_DIR`, downloads the official installer from `https://starship.rs/install.sh`, and installs the binary into `INSTALL_BIN_DIR`.

PowerShell and zsh profiles initialize Starship independently when `starship` is available.

## Configuration Boundaries

- Prompt shape and module ordering remain Starship defaults.
- Shell integration belongs to the shell profile packages.
- Font installation and terminal font selection belong to the terminal and package-manager layers.

## Validation Notes

Use Dotter dry-runs to confirm `~/.config/starship.toml` is deployed. For runtime checks, run `starship explain` in a Nerd Font-capable terminal and confirm symbols render as expected.

## Common Failure Modes

- The terminal font lacks Nerd Font glyphs, so symbols render as boxes or fallback characters.
- A shell profile does not initialize Starship because `starship` is not on `PATH`.
- Local Starship config outside Dotter overrides the deployed file.
