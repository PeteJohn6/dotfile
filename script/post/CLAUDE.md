# Post-Installation Scripts

This directory contains scripts that run **after** dotfiles are deployed via dotter.

**Architecture**:
1. **Orchestrator Script** (`script/post/post.{sh,ps1}`):
   - Discovers all executable scripts in `script/post/`
   - Executes them in order
   - Handles errors and logging

2. **Implementation Scripts** (e.g., `script/post/nvim-setup.sh`):
   - Perform specific post-installation tasks
   - Should be idempotent
   - Should check prerequisites (e.g., is neovim installed?)

**Example Use Cases**:
- Installing Neovim plugins after config is linked
- Compiling native extensions
- Running health checks
- Setting up shell completions

**Implementation Notes**:
- Keep scripts focused - one responsibility per script
- Name scripts descriptively (e.g., `nvim-plugins.sh`, `shell-completions.sh`)
- Log progress clearly
- Exit with non-zero code on critical failures

## Purpose

Post-installation scripts handle tasks that must run after symlinks are created:
- Installing plugin managers (e.g., vim-plug, zinit for zsh)
- Installing plugins (e.g., Neovim plugins, tmux plugins)
- Compiling native extensions
- Running health checks
- Setting up application-specific configurations

## Workflow

1. `just stow` deploys dotfiles via dotter (creates symlinks)
2. `just post` runs all post-installation scripts in this directory
3. Scripts should be **idempotent** (safe to run multiple times)

## File Organization

### Unix (Linux/macOS)
- `post.sh` - Main orchestrator that runs all `*.sh` scripts
- Individual `*.sh` scripts for specific tasks (e.g., `nvim-plugins.sh`, `tmux-plugins.sh`)

### Windows
- `post.ps1` - Main orchestrator that runs all `*.ps1` scripts
- Individual `*.ps1` scripts for specific tasks (e.g., `nvim-plugins.ps1`)

## Example Scripts

Create scripts like:
- `nvim-plugins.sh` / `nvim-plugins.ps1` - Install Neovim plugins
- `zsh-setup.sh` - Install zsh plugins (oh-my-zsh, zinit, etc.)
- `tmux-plugins.sh` - Install tmux plugin manager and plugins
- `health-check.sh` / `health-check.ps1` - Verify installations

## Guidelines

1. **Idempotency**: Scripts must be safe to run multiple times
2. **Error Handling**: Use `set -euo pipefail` (bash) or `Set-StrictMode` (PowerShell)
3. **Logging**: Use consistent logging functions (say, ok, err)
4. **Platform-Specific**: Keep Unix and Windows scripts separate
5. **Dependencies**: Check for required tools before running

## Example

```bash
#!/usr/bin/env bash
# nvim-plugins.sh - Install Neovim plugins

set -euo pipefail

say() { echo "[nvim] $*"; }
ok() { echo "✔ $*"; }

if ! command -v nvim >/dev/null 2>&1; then
    say "Neovim not installed, skipping plugin installation"
    exit 0
fi

say "Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa
ok "Neovim plugins installed"
```
