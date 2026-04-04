# Dotfiles

Cross-platform dotfiles repository built around `bootstrap`, `just`, and `dotter`.

## Overview

This repository separates two concerns:

- Software installation is driven by `packages/packages.list` for host machines and `packages/container.list` for container environments.
- Dotfile deployment is driven by `.dotter/global.toml`, `.dotter/unix.toml`, `.dotter/windows.toml`, and your local `.dotter/local.toml`.

The default workflow is still `bootstrap -> install -> stow -> post`, with `just` orchestrating the install and deploy steps.

## Quick Start

### 1. Bootstrap

Bootstrap prepares the repo for your platform, installs `just`, fetches `dotter`, and copies a platform-appropriate `.dotter/local.toml` template if one does not already exist.

**Linux/macOS:**
```bash
./bootstrap/bootstrap.sh
```

**Windows (PowerShell):**
```powershell
.\bootstrap\bootstrap.ps1
```

### 2. Configure

Bootstrap creates `.dotter/local.toml` from `.dotter/default/unix.toml`, `.dotter/default/windows.toml`, or `.dotter/default/container.toml`.

Edit `.dotter/local.toml` to choose which maintained config packages are deployed:

```toml
includes = [".dotter/unix.toml"]
packages = ["git", "nvim", "zsh", "starship", "tmux", "alacritty"]
[variables]
alacritty_working_directory = "/home/your-user"  # or C:/Users/your-user
```

Windows defaults to:

```toml
includes = [".dotter/windows.toml"]
packages = ["git", "nvim", "starship", "powershell"]
```

When the `alacritty` package is enabled on Windows, the repo also deploys an explicit WSL entrypoint profile at `%APPDATA%\Alacritty\ubuntu-20_04.toml`. Launch it with:

```powershell
alacritty --config-file "$env:APPDATA\Alacritty\ubuntu-20_04.toml"
```

That profile imports the shared `alacritty.toml`, opens `Ubuntu-20.04`, and starts in `/home`.

### 3. Install and Deploy

**All-in-one setup:**
```bash
just up
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

### 4. Remove Deployed Dotfiles

```bash
just uninstall
```

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
| `alacritty` | Templated Alacritty config plus shared themes deployed to the platform config directory | Linux, macOS, Windows |

## Software Install Lists

The package lists under `packages/` are broader than the maintained config packages above:

- `packages/packages.list` is the host-machine install list. It currently includes CLI tools, terminals, shells, editors, and language tooling such as `git`, `neovim`, `ripgrep`, `fd`, `fzf`, `jq`, `yq`, `wezterm`, `starship`, `nushell`, `zed`, `nvm`, and `uv`.
- `packages/container.list` is the smaller container-oriented install list used when `install.sh` detects a container runtime.

In other words: `packages/*.list` decides what software gets installed, while `.dotter/local.toml` decides which repo-managed configs get deployed.

## Architecture

### Tools

- **`just`**: task runner for `install`, `stow`, `post`, and combined workflows
- **`dotter`**: dotfile manager used for deployment and undeployment
- **Platform package managers**:
  - Windows: Scoop is the package-manager path implemented by `script/install.ps1`
  - macOS: Homebrew
  - Linux: `apt`, `dnf`, or `pacman`
- **Bootstrap `just` fallback**: Linux bootstrap installs `just` via the package manager first, and falls back to the official installer into `INSTALL_BIN_DIR` (default: `/usr/local/bin`) only when the package manager does not provide a `just` package
- **Unix pre-install hooks**: `packages/pre-install-unix.sh` can install newer binaries before package-manager fallback when needed. `script/install.sh` provides `INSTALL_BIN_DIR` (default: `/usr/local/bin`) for command entrypoints and `INSTALL_OPT_DIR` (default: `/usr/local/opt`) for directory-based manual installs such as the Neovim tarball.

### Workflow

```text
1. Bootstrap -> install just, fetch dotter, seed .dotter/local.toml
2. Install   -> parse packages/packages.list or packages/container.list
3. Stow      -> deploy selected config packages via dotter
4. Post      -> run scripts from packages/post/ after links are in place
```

### Directory Structure

```text
├── justfile
├── .dotter/
│   ├── global.toml
│   ├── unix.toml
│   ├── windows.toml
│   ├── default/
│   │   ├── unix.toml
│   │   ├── windows.toml
│   │   └── container.toml
│   └── CLAUDE.md
├── bootstrap/
│   ├── bootstrap.sh
│   ├── bootstrap.ps1
│   └── CLAUDE.md
├── script/
│   ├── install.sh
│   ├── install.ps1
│   ├── misc.sh
│   ├── post.sh
│   ├── post.ps1
│   └── CLAUDE.md
├── packages/
│   ├── packages.list
│   ├── container.list
│   ├── pre-install-unix.sh
│   ├── post/
│   ├── git/
│   ├── nvim/
│   ├── powershell/
│   ├── starship/
│   ├── tmux/
│   └── zsh/
├── test/
│   └── devcontainer/
└── README.md
```

## Design Principles

1. **Idempotency**: bootstrap, install, deploy, and post steps should be safe to rerun.
2. **Platform awareness**: scripts detect platform and container context before acting.
3. **Separation of concerns**: install lists decide software; dotter profiles decide deployed config.

## Force Mode

- `just install-force`: strict install mode on Unix
- `just stow-force`: deploy while overwriting conflicts
- `just up-force`: run `install-force -> stow-force -> post`

## Documentation

- `.dotter/CLAUDE.md` - dotter configuration guide
- `bootstrap/CLAUDE.md` - bootstrap implementation notes
- `script/CLAUDE.md` - install and post orchestration notes
- `packages/zsh/README.md` - zsh profile details
- `packages/powershell/README.md` - PowerShell profile details
- `packages/tmux/README.md` - tmux configuration details

## License

MIT
