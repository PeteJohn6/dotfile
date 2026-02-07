# Scripts

This directory contains the install and post-installation scripts, invoked by `just`.

## Install Scripts

Install scripts read the unified package list and install software using platform-specific package managers.

**Invocation**: Called by `just install`

### Available Scripts

- `install-unix.sh` - Linux/macOS installation script (apt/dnf/pacman/brew)
- `install.ps1` - Windows installation script (winget/scoop/chocolatey)

### How It Works

1. Detect environment: container vs desktop Unix via `is_container()` which checks:
   - `/.dockerenv` file existence
   - `$container` environment variable (set by systemd-nspawn, podman, etc.)
   - `/proc/1/cgroup` containing `docker`, `lxc`, `podman`, or `containerd`
2. Select package list: `packages/container.list` for containers, `packages/packages.list` otherwise
3. Parse the list file (skip comments, handle whitespace, filter by `@platform` tag)
4. Install packages using the platform's package manager
5. Log progress and handle errors gracefully

### Invocation

```bash
# Linux/macOS
bash script/install-unix.sh

# Windows (PowerShell)
pwsh script/install.ps1
```

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
