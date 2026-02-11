# Scripts

This directory contains the install and post-installation scripts, invoked by `just`.

## Install Scripts

Install scripts read the unified package list and install software using platform-specific package managers.

**Invocation**: Called by `just install` and `just install-force`

### Available Scripts

- `install-unix.sh` - Linux/macOS installation script (apt/dnf/pacman/brew)
- `install.ps1` - Windows installation script (winget/scoop/chocolatey)

### How It Works

1. Detect runtime via `script/detect_platform.sh`, which outputs:
   - `PLATFORM` (`linux` or `macos`)
   - `IS_CONTAINER` (`0` or `1`)
   - `PKG_MANAGER` (`apt`, `dnf`, `pacman`, or `brew`)
2. Select package list:
   - `IS_CONTAINER=1` -> `packages/container.list`
   - `IS_CONTAINER=0` -> `packages/packages.list`
3. Parse the list file (skip comments, handle whitespace, filter by `@platform` tag)
   - Supports `package[(cli_name)]`
   - `cli_name` defaults to package name when omitted
4. Source `packages/pre-install-unix.sh` as a rule library
5. Run package-driven pre-install rules using the rule-map selector
6. Refresh package indexes after pre-install rules
7. For each package, check if CLI is already available; if yes, skip package-manager install
8. Install only unresolved packages via the platform's package manager
9. Log progress with `succeeded/skipped/failed` summary

### Invocation

```bash
# Linux/macOS
bash script/install-unix.sh
bash script/install-unix.sh --strict

# Windows (PowerShell)
pwsh script/install.ps1
```

### Pre-Install Behavior

`packages/pre-install-unix.sh` uses a package rule dispatcher:
- `install-unix.sh` iterates parsed packages and calls `run_pre_install_for_package`
- `run_pre_install_for_package` resolves handlers via `PREINSTALL_RULE_MAP` (`pkg:handler`)
- Current built-in rule: `neovim` -> rule function triggers when `PKG_MANAGER` is `apt`; installs Neovim tarball into `~/.local/opt/neovim` and links `INSTALL_BIN_DIR/nvim` (defaults: host `~/.local/bin/nvim`, container `/usr/local/bin/nvim`) (idempotent)
- If rule conditions are not met, pre-install returns without installing and `install-unix.sh` falls back to package-manager install
- After rules run, package indexes are refreshed
- Consistent log prefix format: `[pre-install:<manager>]`

`packages/pre-install-unix.sh` should not call `detect_platform.sh`; it relies on context provided by `install-unix.sh`.
`install-unix.sh` provides `INSTALL_BIN_DIR` for binary link targets (default: host `~/.local/bin`, container `/usr/local/bin`) and prepends it to `PATH` for the current install process.

### Strict vs Non-Strict

- `install-unix.sh` default mode is non-strict (`--strict` omitted)
  - Failed package installs are recorded, but script exits `0`
  - Supports "manual fix then rerun install" workflow
- `install-unix.sh --strict`
  - Any failed package install causes final non-zero exit
- `packages/pre-install-unix.sh` follows the same strict flag through `preinstall_handle_failure`

## Post Scripts

Post orchestrators discover and execute per-tool scripts from `packages/post/`.

**Invocation**: Called by `just post`

### Available Scripts

- `post.sh` - Unix orchestrator: runs all `packages/post/*.sh`
- `post.ps1` - Windows orchestrator: runs all `packages/post/*.ps1`

### How It Works

1. `just stow` deploys dotfiles via dotter (creates symlinks)
2. `just post` runs the orchestrator (`post.sh` or `post.ps1`)
3. The orchestrator discovers all scripts in `packages/post/` and executes them

Per-tool post-install scripts live in `packages/post/` (see `packages/CLAUDE.md`).

### Invocation

```bash
# Linux/macOS
bash script/post.sh

# Windows (PowerShell)
pwsh script/post.ps1
```

## Implementation Requirements

All scripts must:
- Be idempotent (safe to run multiple times)
- Provide clear progress output
- Exit with appropriate status codes
- Use `set -euo pipefail` (bash) or `#Requires -Version 7` (PowerShell)
