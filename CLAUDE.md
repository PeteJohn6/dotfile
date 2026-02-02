# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## You must strictly comply every time you run.

CRITICAL: Always execute `pwd` first. File operations are RESTRICTED to the current directory only.  
CRITICAL: Do not modify any files under `$PWD/test` unless explicitly authorized.
CRITICAL: Never access the `$PWD/.tree/` folder.

## Repository Overview

This is a cross-platform dotfiles management system using a "bootstrap + justfile + dotter" architecture. The repository manages configuration files across Linux, macOS, and Windows through a declarative, profile-based workflow.

## Core Architecture

### Tooling Choices

1. Use `just` (Justfile) as the task orchestrator
2. Use `dotter` to deploy dotfiles via symbolic links
3. Support multiple platforms (Linux, macOS, Windows)
4. Use platform-specific package managers
    - Windows:
        - winget / chocolatey: system-level software; requires administrator privileges
        - scoop: user-mode portable packages; avoids tight coupling to system software (e.g., git, uv, neovim, etc.)
    - macOS:
        - homebrew

### Workflow

1. **Bootstrap** (`bootstrap/bootstrap.sh` | `bootstrap.ps1`)
    a. Sets up environment variables if needed
    b. Installs a package manager on macOS/Windows if needed
    c. Uses the package manager to install: `just` (task runner) and `dotter` (dotfiles manager)

2. `just` runs the following tasks in order:
    1. **Install** (`scripts/install/*.{sh,ps1}`)
        a. Parses platform-specific package lists from `lists/<platform>.list`
        b. Installs tools via package managers (apt/dnf/pacman/brew/winget/choco)

    2. **Stow** (via `dotter`)

    3. **Post** (`scripts/post/post.{sh,ps1}`)
        - Runs all `*.sh` (Unix) or `*.ps1` (Windows) scripts in `scripts/post/`
        - Executes after dotfiles are linked (e.g., installing Neovim plugins)

### Folder Layout

```
|-- justfile                 # install/stow/post orchestration
|-- .dotter/                 # dotter profiles
|-- bootstrap/
|   |-- bootstrap-macos.sh   # macOS dependency bootstrap
|   |-- bootstrap-linux.sh   # Linux dependency bootstrap
|   `-- bootstrap.ps1        # Windows dependency bootstrap
|-- lists                    # 
|-- scripts/
|   |-- install/             # platform-specific install scripts
|   `-- post/                # post scripts to run after stowing
|-- packages/                # package's configurations
|-- README.md                # overview and usage for users
```

## Detail

### Justfile

- See `https://just.systems/man/en/` for the full `just` documentation

### Dotter

- See `.dotter/CLAUDE.md` for detailed `dotter` notes

## post-installation

- See `scripts/post/CLAUDE.md` for detailed post-installation notes

## Goal:

1. `just` provides:

Step-by-step installation process
---
just install     # sanity checks (stage: install)
just dry         # dotter deploy --dry-run
just stow        # dotter deploy (links + templates)
just post        # run post scripts (nvim plugins, health checks)

all in one:
------
just up          # install -> stow -> post in one shot
just uninstall   # dotter uninstall --verbose

2. Each `just` step must be idempotent.

## Development Notes:

1. Keep maintained packages and the README in sync
