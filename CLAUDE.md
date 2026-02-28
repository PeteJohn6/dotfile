# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## You must strictly comply every time you run

CRITICAL: Always execute `pwd` first. File operations are RESTRICTED to the current directory only.  
CRITICAL: Do not modify files under any repository test directories (for example: `$PWD/packages/*/test`) unless explicitly authorized.
CRITICAL: NEVER access any content under `$PWD/.tree/` IF a `.tree/` directory exists under `$PWD`.

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

1. **Bootstrap**
    - Linux/macOS: `bootstrap/bootstrap.sh` (auto-detects platform at runtime)
    - Windows: `bootstrap/bootstrap.ps1`

    a. Sets up environment variables if needed
    b. Installs a package manager on macOS/Windows if needed
    c. Uses the package manager to install: `just` (task runner) and `dotter` (dotfiles manager)

2. `just` runs the following tasks in order:
    1. **Install** (`script/install.sh` | `script/install.ps1`)
        a. Detects runtime context (`PLATFORM` / `IS_CONTAINER` / `PKG_MANAGER`)
        b. Parses `packages/packages.list` (desktop) or `packages/container.list` (container)
        c. Runs package-driven pre-install rules (e.g. binary fallback installs using `INSTALL_BIN_DIR`: host default `~/.local/bin`, container default `/usr/local/bin`, and prepends it to `PATH` for current install run)
        d. Skips packages already satisfied by CLI availability
        e. Installs remaining tools via package managers (apt/dnf/pacman/brew/winget/choco)

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
|   |-- install.sh           # Linux/macOS install script
|   |-- misc.sh             # Unix shared runtime/privilege helpers
|   |-- install.ps1          # Windows install script
|   |-- post.sh              # Unix post orchestrator
|   `-- post.ps1             # Windows post orchestrator
|-- packages/
|   |-- packages.list         # desktop package list (supports @platform tags)
|   |-- container.list        # minimal container package list
|   |-- pre-install-unix.sh   # pre-install rules for Unix packages
|   |-- post/                # per-package post-install scripts (named by CLI command)
|   `-- [package_name]/       # per-package configuration
|-- README.md                # overview and usage for users
```

## Implementation Guidelines for Infrastructure

### Bootstrap Scripts

Bootstrap scripts prepare the system with minimal dependencies (package manager, just, dotter).

See `bootstrap/CLAUDE.md` for detailed bootstrap notes.

### Install Scripts

Install scripts read package lists and install software using platform-specific package managers.

**Invocation**: Called by `just install`

### Post Scripts

Post orchestrators discover and run per-tool scripts from `packages/post/`.

**Invocation**: Called by `just post`

See `script/CLAUDE.md` for detailed install and post-installation notes.

## Reference

### Justfile

- See `https://just.systems/man/en/` for the full `just` documentation

### Dotter

- See `.dotter/CLAUDE.md` for detailed `dotter` notes

## Final Goal

1. `just` provides:

Step-by-step installation process:

```
just install     # sanity checks (stage: install)
just dry         # dotter deploy --dry-run
just stow        # dotter deploy (links + templates)
just post        # run post scripts (nvim plugins, health checks)
```

All in one:

```
just up          # install -> stow -> post in one shot
just uninstall   # dotter undeploy --verbose
```

2. Each `just` step must be idempotent.

## Requirements for Package Configuration

1. Add the package to `packages/packages.list` (desktop) or `packages/container.list` (container). For the desktop list, you can use optional `@platform` tags.

2. If the package requires pre-install setup, add a rule to `packages/pre-install-unix.sh` (if applicable).

3. Package configuration:
    - Lives in `packages/[package_name]/`, you can see the guide in `packages/CLAUDE.md`.
    - Use dotter to configure the symlink/link paths for config files, you can see the guide in `.dotter/CLAUDE.md`.

4. If the package requires post-install configuration, add a script to `packages/post/` (named appropriately).

5. Keep maintained packages and the README in sync.
