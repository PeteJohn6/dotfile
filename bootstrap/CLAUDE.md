# Bootstrap Documentation

## Overview

**GOAL**: Do not assume any dependencies are available before execution. Except:
1. There are already package managers like apt, dnf, and pacman on Linux.

Bootstrap scripts prepare the system with minimal dependencies required to run the dotfiles management system. The bootstrap phase installs:
1. **Package manager** (if needed) - Homebrew (macOS), Scoop (Windows)
2. **`just`** - Task runner installed via package manager (system-wide)
3. **`dotter`** - Dotfiles manager downloaded as local binary to `bin/` (project-local)

## Design Philosophy

### Unified Approach
- **Single `bootstrap.sh`** for Linux/macOS (platform detection at runtime)
- **`bootstrap.ps1`** for Windows
- **Consistent strategy**: Package manager for `just`, local binary for `dotter`

### Installation Strategy

| Tool | Linux | macOS | Windows | Location |
|------|-------|-------|---------|----------|
| `just` | apt/dnf/pacman | Homebrew | Scoop | System-wide (/usr/local/bin, etc.) |
| `dotter` | Download to bin/ | Download to bin/ | Download to bin/ | Project-local (./bin/) |

### Why This Approach?

1. **`just` via package managers**:
   - Available in all major package managers (apt, dnf, pacman, brew, scoop)
   - System-wide installation is standard practice for task runners
   - Easier updates via package manager

2. **`dotter` as local binary**:
   - Not available in all package managers (e.g., apt doesn't have it)
   - Keeps project self-contained
   - No global pollution
   - Consistent across all platforms

## Bootstrap Workflow

### Linux/macOS (`bootstrap.sh`)

1. **Unified Detection**: Uses `script/detect_platform.sh` to set:
   - `PLATFORM` (`linux`/`macos`)
   - `IS_CONTAINER` (`0`/`1`)
   - `PKG_MANAGER` (`apt`/`dnf`/`pacman`/`brew`)
2. **Environment Handling**: Uses root/container state to decide sudo usage
3. **Bin Directory Setup**: Creates `bin/` and adds to `.gitignore`
4. **Self-Sufficiency Check**: Installs curl/wget if needed (for dotter download)
5. **Package Manager Setup**:
   - Linux: Uses detected package manager (`PKG_MANAGER`)
   - macOS: Installs Homebrew if not present
6. **Install `just`**: Via package manager (system-wide)
7. **Download `dotter`**: Latest release from GitHub to `bin/` (project-local)

### Windows (`bootstrap.ps1`)

1. **Bin Directory Setup**: Creates `bin\` and adds to `.gitignore`
2. **Install Scoop**: User-mode package manager (no admin required)
3. **Install `just`**: Via Scoop (system-wide)
4. **Download `dotter`**: Latest release from GitHub to `bin\` (project-local)

## Environment Detection (Linux/macOS only)

Bootstrap automatically detects the execution environment and conditionally uses `sudo`:

### Container Environments
- Detected via unified `detect_platform.sh` (`IS_CONTAINER=1`)
- No `sudo` used

### Standard Linux/macOS
- Uses `sudo` for system installations unless running as root

### Root User
- Never uses `sudo` (not needed)

This allows bootstrap to work seamlessly in:
- Docker/Podman containers running as root
- Docker/Podman containers running as non-root
- Standard Linux systems requiring privilege elevation
- macOS systems (Homebrew typically doesn't need sudo)

## Files

### Bootstrap Scripts
- `bootstrap/bootstrap.sh` - Unified bootstrap for Linux/macOS
- `bootstrap/bootstrap.ps1` - Windows bootstrap

### Helper Functions (`bootstrap.sh`)
- `needs_sudo()` - Determines if sudo is required
- `maybe_sudo()` - Conditionally wraps commands with sudo
- `setup_bin_directory()` - Creates bin/ and updates .gitignore
- `download_dotter()` - Downloads dotter binary from GitHub
- `bootstrap_linux()` - Linux-specific bootstrap logic
- `bootstrap_macos()` - macOS-specific bootstrap logic

## Usage

```bash
# Linux/macOS (auto-detects platform)
bash bootstrap/bootstrap.sh

# Windows (PowerShell)
.\bootstrap\bootstrap.ps1
```

## Key Principles

1. **Idempotent**: Can be run multiple times safely
2. **Platform-Aware**: Auto-detects platform and environment
3. **Clean**: Local binaries in `bin/`, not polluting global paths
4. **Consistent**: Same approach across all platforms

## After Bootstrap

Once bootstrap completes:
- `just` is available system-wide
- `dotter` is available at `./bin/dotter` (or `.\bin\dotter.exe` on Windows)
- The `justfile` will use the local dotter binary for all operations

Next steps:
```bash
just install  # Install packages via package managers
just stow     # Deploy dotfiles via dotter
just post     # Run post-installation scripts
# Or all at once:
just up       # install -> stow -> post
```
