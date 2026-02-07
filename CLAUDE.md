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

### Package Lists Format

Desktop environments use `packages/packages.list`, container environments use `packages/container.list`.

**`packages/packages.list`** — Format: `package [@platform] [| manager:name ...]`
- One package per line
- `@unix` = Linux + macOS only
- `@windows` = Windows only
- No tag = all platforms
- `| manager:name ...` = optional per-manager name overrides (e.g. `fd | apt:fd-find dnf:fd-find`)
- Comments start with `#`
- Empty lines are ignored
- Whitespace is trimmed

**`packages/container.list`** — Minimal package list for containers
- One package per line (no platform tags)
- `install-unix.sh` auto-selects this file when a container environment is detected

### Workflow

1. **Bootstrap**
    - Linux/macOS: `bootstrap/bootstrap.sh` (auto-detects platform at runtime)
    - Windows: `bootstrap/bootstrap.ps1`

    a. Sets up environment variables if needed
    b. Installs a package manager on macOS/Windows if needed
    c. Uses the package manager to install: `just` (task runner) and `dotter` (dotfiles manager)

2. `just` runs the following tasks in order:
    1. **Install** (`script/install-unix.sh` | `script/install.ps1`)
        a. Detects environment (container vs desktop)
        b. Parses `packages/packages.list` (desktop) or `packages/container.list` (container)
        c. Installs tools via package managers (apt/dnf/pacman/brew/winget/choco)

    2. **Stow** (via `dotter`)

    3. **Post** (`script/post.sh` | `script/post.ps1`)
        - Discovers and runs per-tool scripts from `packages/post/`
        - Executes after dotfiles are linked (e.g., installing Neovim plugins)

### Design Principles

1. **Idempotency**: All scripts can be run multiple times safely
2. **Platform Detection**: Scripts auto-detect the platform
3. **Error Handling**: Fail fast with clear error messages

### Folder Layout

```
|-- justfile                 # install/stow/post orchestration
|-- .dotter/                 # dotter profiles
|-- bootstrap/
|   |-- bootstrap.sh          # Linux/macOS dependency bootstrap
|   `-- bootstrap.ps1         # Windows dependency bootstrap
|-- script/
|   |-- install-unix.sh      # Linux/macOS install script
|   |-- install.ps1          # Windows install script
|   |-- post.sh              # Unix post orchestrator
|   `-- post.ps1             # Windows post orchestrator
|-- packages/
|   |-- packages.list         # desktop package list (supports @platform tags)
|   |-- container.list        # minimal container package list
|   |-- post/                 # per-tool post-install scripts
|   |-- git/                  # git configuration
|   `-- nvim/                 # neovim configuration
|-- README.md                # overview and usage for users
```

## Implementation Guidelines

### Bootstrap Scripts

Bootstrap scripts prepare the system with minimal dependencies (package manager, just, dotter).

see `bootstrap/CLAUDE.md` for detailed bootstrap notes.

### Install Scripts

Install scripts read package lists and install software using platform-specific package managers.

**Invocation**: Called by `just install`

### Post Scripts

Post orchestrators discover and run per-tool scripts from `packages/post/`.

**Invocation**: Called by `just post`

see `script/CLAUDE.md` for detailed install and post-installation notes.

### README

1. Installed programs are presented through a table


## Reference

### Justfile

- See `https://just.systems/man/en/` for the full `just` documentation

### Dotter

- See `.dotter/CLAUDE.md` for detailed `dotter` notes

## Final goal:

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

## Must care for:

1. Keep maintained packages and the README in sync
