# Dotfiles

Cross-platform dotfiles repository built around `bootstrap`, `just`, and `dotter`.

## Overview

This repository separates two concerns:

- Software installation is driven by `packages/packages.list` for host machines and `packages/container.list` for container environments.
- Dotfile deployment is driven by `.dotter/global.toml`, `.dotter/unix.toml`, `.dotter/windows.toml`, and your local `.dotter/local.toml`.

The default user workflow is `bootstrap -> install -> stow -> post`.

- `bootstrap` runs the platform-specific script under `bootstrap/` and prepares `just` and `dotter`.
- `install` runs the platform-specific script under `script/`.
- `stow` deploys config from `packages/` through Dotter.
- `post` runs post-deployment scripts from `packages/post/`.

The install stage is maintained as `pre-install -> install` across platforms. `pre-install` handles preparation, manual install paths, and exceptional cases where the package manager is not sufficient, while the package-manager install phase skips tools that are already satisfied and stays focused on normal package installs.

## Guide

### 1. Bootstrap

Bootstrap prepares the repo for your platform, installs `just`, fetches `dotter`, and copies a platform-appropriate `.dotter/local.toml` template if one does not already exist.

**Linux/macOS:**
```bash
./bootstrap/bootstrap.sh
```

**Linux/macOS CI / Docker one-shot setup:**
```bash
bash bootstrap-up.sh
```

**Windows (PowerShell):**
```powershell
.\bootstrap\bootstrap.ps1
```

`bootstrap-up.sh` is a root-level convenience entrypoint for ephemeral Unix environments. It runs `bootstrap/bootstrap.sh` and then `just up` in the same process so CI jobs and Docker builds can provision the repo with a single command.

### 2. Configure

Bootstrap creates `.dotter/local.toml` from `.dotter/default/unix.toml`, `.dotter/default/windows.toml`, or `.dotter/default/container.toml`.
Fresh container environments use `.dotter/default/container.toml` as the forward template for container-local package selection.

Edit `.dotter/local.toml` to choose which maintained config packages are deployed:

```toml
includes = [".dotter/unix.toml"]
packages = ["git", "nvim", "zsh", "starship", "tmux", "alacritty", "wezterm", "ghostty"]
[variables]
alacritty_working_directory = "/home/your-user"  # or C:/Users/your-user
```

Windows defaults to:

```toml
includes = [".dotter/windows.toml"]
packages = ["git", "nvim", "starship", "powershell", "alacritty", "wezterm"]
```

On Windows, Alacritty also deploys `wsl.toml`, a WSL profile that follows the current user's default distribution.

### 3. Install and Deploy

**All-in-one setup:**
```bash
just up
```

**One command for CI / Docker:**
```bash
bash bootstrap-up.sh
```

**Step-by-step:**
```bash
just install        # Install software from packages/*.list
just install-force  # Strict install mode on Unix; same as install on Windows
just dry            # Preview dotter deployment
just stow           # Deploy dotfiles
just stow-force     # Deploy dotfiles and overwrite conflicts
just post           # Run post-install scripts from packages/post/
```

`just stow` is safe to re-run. Dotter reconciles deployed targets using `.dotter/cache.toml`, so normal redeploys should not require `just uninstall` first.
On Unix machines, including normal containerized workspaces, the default deployment type remains symbolic links. The published Ubuntu release image is a separate runtime artifact: its Docker build runs a finalization step after `bootstrap-up.sh` that materializes repo-backed Dotter symlinks into ordinary files before the image is published. See `docs/release-image.md` for that image-specific contract.

### 4. Remove Deployed Dotfiles

```bash
just uninstall
```

## Shell shortcut


## Maintained Config Packages

These are the config packages currently maintained in this repository and referenced by `.dotter/*.toml`:

| Package | Description | Platforms |
|---------|-------------|-----------|
| `git` | Git config, global ignore rules, and gitattributes | Linux, macOS, Windows |
| `nvim` | Neovim configuration | Linux, macOS, Windows |
| `zsh` | Modular zsh profile and helper modules | Linux, macOS |
| `starship` | Shared Starship prompt symbols/config | Linux, macOS, Windows |
| `tmux` | Modular tmux config with TPM bootstrap in post-install | Linux, macOS |
| `powershell` | Modular PowerShell profile and helper modules | Windows |
| `alacritty` | Templated Alacritty config, shared themes, and a Windows WSL profile that follows the user's default WSL distribution | Linux, macOS, Windows |
| `wezterm` | Modular WezTerm config with imported theme, fallback font stack, and backdrop image system | Linux, macOS, Windows |
| `ghostty` | Ghostty config with custom theme, fallback font stack, keybinds, and static backdrop; installed only on macOS through Homebrew cask | Linux, macOS |

## Software Install Lists

The package lists under `packages/` are broader than the maintained config packages above:

- `packages/packages.list` is the host-machine install list. It currently includes CLI tools, terminals, shells, editors, and language tooling such as `git`, `neovim`, `ripgrep`, `fd`, `fzf`, `jq`, `yq`, `wezterm`, `ghostty`, `starship`, `nushell`, `zed`, `nvm`, and `uv`. Ghostty is selected for macOS only and installs as a Homebrew cask.
- `packages/container.list` is the smaller container-oriented install list used when `install.sh` detects a container runtime.

In other words: `packages/*.list` decides what software gets installed, while `.dotter/local.toml` decides which repo-managed configs get deployed.

## License

MIT
