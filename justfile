# Dotfiles Management System
# Cross-platform dotfiles orchestrator using dotter and just

# Platform detection
os_type := os()

# Cross-platform dotter command
_dotter := if os_type == "windows" { "dotter.exe" } else { "./bin/dotter" }

# Default recipe - show available commands
default:
    @just --list

# Install packages via platform-specific package managers
install:
    @echo "==> Installing packages for {{ os_type }}..."
    @{{ if os_type == "windows" { "pwsh script/install.ps1" } else { "bash script/install-unix.sh" } }}
    @echo "==> Package installation complete"

# Dry run - preview dotfile deployment without making changes
[unix]
dry:
    @echo "==> Running dotter dry-run (preview mode)..."
    @./bin/dotter deploy --dry-run || echo "==> Some files would be skipped. Use 'just stow-force' to overwrite."
    @echo "==> Dry-run complete."

[windows]
dry:
    @echo "==> Running dotter dry-run (preview mode)..."
    @pwsh -NoProfile -Command "dotter.exe deploy --dry-run; if ($LASTEXITCODE -ne 0) { Write-Host '==> Some files would be skipped. Use just stow-force to overwrite.' }"
    @echo "==> Dry-run complete."

# Stow - deploy dotfiles via dotter (create symbolic links)
[unix]
stow:
    @echo "==> Deploying dotfiles via dotter..."
    @./bin/dotter deploy --verbose || echo "==> Some files were skipped (already exist). Use 'just stow-force' to overwrite."
    @echo "==> Dotfiles deployed"

[windows]
stow:
    @echo "==> Deploying dotfiles via dotter..."
    @pwsh -NoProfile -Command "dotter.exe deploy --verbose; if ($LASTEXITCODE -ne 0) { Write-Host '==> Some files were skipped (already exist). Use just stow-force to overwrite.' }"
    @echo "==> Dotfiles deployed"

# Force stow - deploy dotfiles, overwriting conflicts
stow-force:
    @echo "==> Force deploying dotfiles (overwriting conflicts)..."
    @{{ _dotter }} deploy --force --verbose
    @echo "==> Dotfiles force-deployed successfully"

# Post-installation - run post-deployment scripts
post:
    @echo "==> Running post-installation scripts for {{ os_type }}..."
    @{{ if os_type == "windows" { "pwsh script/post.ps1" } else { "bash script/post.sh" } }}
    @echo "==> Post-installation complete"

# Up - complete setup workflow (install -> stow -> post)
up: install stow post
    @echo ""
    @echo "=========================================="
    @echo "  Setup Complete!"
    @echo "=========================================="

# Up force - complete setup workflow, overwriting conflicts
up-force: install stow-force post
    @echo ""
    @echo "=========================================="
    @echo "  Setup Complete!"
    @echo "=========================================="

# Uninstall - remove deployed dotfiles
uninstall:
    @echo "==> Undeploying dotfiles..."
    @{{ _dotter }} undeploy --verbose
    @echo "==> Dotfiles removed successfully"
