# Dotfiles

Cross-platform dotfiles management system using a "bootstrap + justfile + dotter" architecture.

## Overview

This repository manages configuration files across Linux, macOS, and Windows through a declarative, profile-based workflow.

## Quick Start

### 1. Bootstrap

Install dependencies (just, dotter, package managers):

**Linux/macOS:**
```bash
./bootstrap/bootstrap.sh
```

**Windows (PowerShell):**
```powershell
.\bootstrap\bootstrap.ps1
```

### 2. Configure (Automatic)

Bootstrap automatically creates `.dotter/local.toml` based on your platform.
To customize packages, edit `.dotter/local.toml`:
```toml
packages = ["git", "nvim"]  # Add or remove packages
```

### 3. Deploy

**All-in-one deployment:**
```bash
just up          # install -> stow -> post
```

**Step-by-step:**
```bash
just install     # Install packages from lists
just dry         # Preview dotfile deployment
just stow        # Deploy dotfiles (create symlinks)
just post        # Run post-installation scripts
```

### 4. Uninstall

Remove deployed dotfiles:
```bash
just uninstall
```

## Managed Packages

| Package | Description | Platforms |
|---------|-------------|-----------|
| git     | Git configuration, global gitignore, and gitattributes | Linux, macOS, Windows |
| nvim    | Neovim editor configuration | Linux, macOS, Windows |

## Architecture

### Tools

- **just**: Task orchestrator for install/stow/post workflow
- **dotter**: Dotfiles manager with symbolic links and templating
- **Platform package managers**:
  - Windows: scoop (user-mode), winget/chocolatey (system-level)
  - macOS: homebrew
  - Linux: apt/dnf/pacman

### Workflow

```
1. Bootstrap → Install just, dotter, package managers
2. Install   → Install packages from packages/packages.list (or container.list in containers)
3. Stow      → Deploy dotfiles via dotter (symbolic links)
4. Post      → Run post-installation scripts
```

### Directory Structure

```
├── justfile                 # Task orchestration
├── .dotter/
│   ├── global.toml          # Base package definitions
│   ├── windows.toml         # Windows-specific overrides
│   ├── unix.toml            # Unix-specific overrides
│   ├── default/             # Default local.toml templates
│   │   ├── windows.toml     # Windows template
│   │   ├── unix.toml        # Unix template
│   │   └── container.toml   # Container template
│   ├── local.toml           # User configuration (auto-created by bootstrap, gitignored)
│   └── CLAUDE.md            # Dotter implementation guide
├── bootstrap/
│   ├── bootstrap.sh         # Linux/macOS bootstrap
│   └── bootstrap.ps1        # Windows bootstrap
├── script/
│   ├── install-unix.sh      # Linux/macOS install script
│   ├── install.ps1          # Windows install script
│   ├── post.sh              # Unix post orchestrator
│   └── post.ps1             # Windows post orchestrator
└── packages/
    ├── packages.list        # Unified package list (with @platform tags)
    ├── container.list       # Minimal package list for containers
    ├── post/                # Per-tool post-install scripts
    ├── git/                 # Git configuration
    ├── nvim/                # Neovim configuration
    └── ...                  # Other packages
```

## Design Principles

1. **Idempotency**: All scripts can be run multiple times safely
2. **Platform Detection**: Scripts auto-detect the platform
3. **Error Handling**: Fail fast with clear error messages

## Documentation

- `.dotter/CLAUDE.md` - Dotter configuration guide
- `script/CLAUDE.md` - Install and post-installation guide
- `bootstrap/CLAUDE.md` - Bootstrap script guide

## License

MIT
