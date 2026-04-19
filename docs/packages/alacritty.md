# Alacritty Package

This document explains the repo-managed Alacritty package under `packages/alacritty/`. It covers the deployed base config, shared theme assets, and the Windows WSL profile.

## Design Intent

- Keep the base Alacritty config shared across platforms through one Dotter template.
- Deploy shared theme files beside the rendered config so imported theme paths stay relative and portable.
- Provide a Windows WSL profile that follows the current user's default WSL distribution.

## Structure

| Path | Role |
| --- | --- |
| `packages/alacritty/alacritty.toml.tmpl` | Dotter-rendered base Alacritty config |
| `packages/alacritty/themes/` | Shared Alacritty theme files |
| `packages/alacritty/wsl.toml` | Windows WSL profile that imports the base config |

## Windows WSL Profile

`wsl.toml` starts `wsl.exe` without a `-d` distribution argument:

```toml
args = ["-u", "root", "--cd", "/home", "zsh"]
```

The selected distribution is the current user's WSL default. Change it outside this repository with:

```powershell
wsl --set-default <DistroName>
```

The profile enters WSL as `root`, starts in `/home`, and runs `zsh`.

## Validation Design

- Validate Dotter deployment first so path and package-name regressions surface before runtime debugging.
- On Windows, use `dotter.exe deploy --dry-run` to verify `wsl.toml` is deployed.
- When Unix Alacritty mappings change, validate the Unix Dotter preview in the repository devcontainer.

## Fast Checks

| Task | Command |
| --- | --- |
| Windows dry-run | `dotter.exe deploy --dry-run` |
| Unix dry-run in devcontainer | `./bin/dotter deploy --dry-run` |
| Full workflow in devcontainer | `just install && just stow && just post` |

## Common Failure Modes

- The default WSL distribution points at an older distro than expected.
- `zsh` is missing in the selected default WSL distribution.
- The `root` user is unavailable in an unusual WSL distribution.
- Drift between README examples, Dotter mappings, and the files shipped under `packages/alacritty/`.
