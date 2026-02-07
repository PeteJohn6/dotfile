# Dotfiles Management System
# Cross-platform dotfiles orchestrator using dotter and just

# Platform detection
os_type := os()

# Default recipe - show available commands
default:
    @just --list

# Install packages via platform-specific package managers
install:
    @echo "==> Installing packages for {{ os_type }}..."
    @{{ if os_type == "windows" { "pwsh script/install.ps1" } else { "bash script/install-unix.sh" } }}
    @echo "==> Package installation complete"

# Dry run - preview dotfile deployment without making changes
dry:
    @echo "==> Running dotter dry-run (preview mode)..."
    @{{ if os_type == "windows" { "dotter deploy --dry-run" } else { "./bin/dotter deploy --dry-run" } }}
    @echo "==> Dry-run complete. Run 'just stow' to apply changes."

# Stow - deploy dotfiles via dotter (create symbolic links)
stow:
    @echo "==> Deploying dotfiles via dotter..."
    @{{ if os_type == "windows" { "dotter.exe deploy" } else { "./bin/dotter deploy" } }}
    @echo "==> Dotfiles deployed successfully"

# Post-installation - run post-deployment scripts
post:
    @echo "==> Running post-installation scripts for {{ os_type }}..."
    @{{ if os_type == "windows" { "pwsh script/post.ps1" } else { "bash script/post.sh" } }}
    @echo "==> Post-installation complete"

# Up - complete setup workflow (install -> stow -> post)
up: install stow post
    @echo ""
    @echo "=========================================="
    @echo "  Setup Complete! 🎉"
    @echo "=========================================="
    @echo "Your dotfiles have been installed and deployed."
    @echo ""

# Uninstall - remove deployed dotfiles
uninstall:
    @echo "==> Undeploying dotfiles..."
    @{{ if os_type == "windows" { ".\\bin\\dotter.exe undeploy --verbose" } else { "./bin/dotter undeploy --verbose" } }}
    @echo "==> Dotfiles removed successfully"
