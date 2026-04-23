# Alacritty Package

This guide explains the repo-managed Alacritty package under `packages/alacritty/`. The package provides a shared terminal config, shared theme assets, and a Windows WSL profile.

## Design Intent

- Keep the base Alacritty config shared across platforms through one Dotter template.
- Deploy shared theme files beside the rendered config so imported theme paths stay relative and portable.
- Provide a Windows WSL profile that follows the current user's default WSL distribution.
- Keep platform-specific behavior in Dotter mappings and the small Windows profile file instead of branching the main config.

## Structure

| Path | Role |
| --- | --- |
| `packages/alacritty/alacritty.toml.tmpl` | Dotter-rendered base Alacritty config |
| `packages/alacritty/themes/` | Shared Alacritty theme files |
| `packages/alacritty/wsl.toml` | Windows WSL profile that imports the base config |

## Configuration Model

`alacritty.toml.tmpl` is rendered by Dotter so host-specific variables can be substituted without duplicating the config. The `themes/` directory is deployed as a symbolic directory beside the rendered config.

On Windows, `wsl.toml` starts `wsl.exe` without a `-d` distribution argument:

```toml
args = ["-u", "root", "--cd", "/home", "zsh"]
```

The selected distribution is the current user's WSL default. Change it outside this repository with:

```powershell
wsl --set-default <DistroName>
```

The profile enters WSL as `root`, starts in `/home`, and runs `zsh`.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `alacritty @macos,windows`. It is not in `packages/container.list`. |
| Pre-install | No package-specific pre-install rule. |
| Dotter deployment | Unix deploys the rendered config and themes to `~/.config/alacritty/`. Windows deploys the rendered config, `wsl.toml`, and themes to `~/AppData/Roaming/Alacritty/`. |
| Post hook | No post hook. |

## Validation Notes

Use Dotter dry-runs to confirm the rendered config, theme directory, and Windows `wsl.toml` target paths. On Windows, also confirm the user's default WSL distribution because this package intentionally does not pin a distro name.

## Common Failure Modes

- The default WSL distribution points at a different distro than expected.
- `zsh` is missing in the selected default WSL distribution.
- The `root` user is unavailable in an unusual WSL distribution.
- Dotter mappings drift from the files shipped under `packages/alacritty/`.
