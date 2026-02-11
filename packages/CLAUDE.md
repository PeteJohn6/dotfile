# Packages

## Package Lists

- `packages.list` — Full package list for desktop Unix and Windows (supports `@platform` tags)
- `container.list` — Minimal package list for container environments (no platform tags)

### List Format

Both list files support:

- `package[(cli_name)] [@platform] [| manager:name ...]`
- `cli_name` is optional and defaults to package name
- `| manager:name ...` defines package-manager aliases (e.g. `fd | apt:fd-find dnf:fd-find`)

Examples:

- `neovim(nvim)`
- `ripgrep(rg)`
- `fd | apt:fd-find dnf:fd-find`

### Selection Logic

`install-unix.sh` uses `script/detect_platform.sh` and its unified variables:
- `PLATFORM` (`linux`/`macos`)
- `IS_CONTAINER` (`0`/`1`)
- `PKG_MANAGER` (`apt`/`dnf`/`pacman`/`brew`)

Then selects the package list:

- **Host (`IS_CONTAINER=0`)** → `packages/packages.list` (filtered by `@platform` tags)
- **Container (`IS_CONTAINER=1`)** → `packages/container.list` (plain list, no tags needed)

`container.list` pairs with `.dotter/container.toml` — the list controls which packages are installed, while the dotter profile controls which dotfiles are deployed.

### Pre-Install Rules

Some packages trigger pre-install setup in `packages/pre-install-unix.sh` before installation.
`install-unix.sh` selects and runs these rules through a package-to-handler map.
Current rule:
- `neovim` -> pre-install rule triggers when `PKG_MANAGER` is `apt`; installs Neovim tarball under `~/.local/opt/neovim` and links `INSTALL_BIN_DIR/nvim` (defaults: host `~/.local/bin/nvim`, container `/usr/local/bin/nvim`)

## Per-Tool Post-Install Scripts (`packages/post/`)

Per-tool post-install scripts are stored in `packages/post/`.

### Naming Convention

File name = **command name**, not the package manager name.

| Package list name | Post script    | CLI command |
|-------------------|----------------|-------------|
| `neovim`          | `nvim.sh`      | `nvim`      |

This keeps scripts decoupled from any specific package manager's naming.

### Self-Check Pattern

Every post script **must** guard itself with a command-existence check at the top.
If the tool is not installed, exit silently with code 0.

This is the sole filtering mechanism — the orchestrator (`post.sh` / `post.ps1`) runs
**all** discovered scripts, and each script decides for itself whether to proceed.
This approach is intentionally environment-agnostic: the same set of scripts works for
both desktop (`packages.list`) and container (`container.list`) installs without any
coupling to the package lists.

### Requirements

- **Self-check**: exit 0 early via `command -v` (bash) or `Get-Command` (PowerShell) if the tool is absent
- **Idempotent**: safe to run multiple times
- **Log format**: `[post:<tool>] message`

### Examples

**Bash** (`packages/post/nvim.sh`):
```bash
#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvim >/dev/null 2>&1; then
    echo "[post:nvim] Neovim not installed, skipping"
    exit 0
fi

echo "[post:nvim] Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa
echo "[post:nvim] Neovim plugins installed"
```

**PowerShell** (`packages/post/nvim.ps1`):
```powershell
#Requires -Version 7

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "[post:nvim] Neovim not installed, skipping"
    exit 0
}

Write-Host "[post:nvim] Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa
Write-Host "[post:nvim] Neovim plugins installed"
```

## Configuration Location Specification

### git

- `.gitconfig` in `~/.gitconfig` is the global configuration file for Git.

`.gitconfig` in `~/.gitconfig` is the global configuration file for Git.

- Implement custom paths instead of Git's default paths. These paths are specified in `.gitconfig` through `core.excludesfile` and `core.attributesfile`.
`.gitignore_global` in `~/.gitconfig/.gitignore_global` is the global gitignore file.
`.gitattributes` in `~/.gitconfig/.gitattributes` is the global gitattributes file.
