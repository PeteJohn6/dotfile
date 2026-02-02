# Dotfiles management orchestration
# Cross-platform task runner for bootstrap → install → stow → post workflow

# Default: show available recipes
default:
    @just --list

# Install all packages from platform-specific lists
install:
    @echo "==> Installing packages..."
    {{if os() == "windows" { "pwsh -NoProfile -File install/install.ps1" } else if os() == "macos" { "bash install/install-macos.sh" } else { "bash install/install-linux.sh" } }}
    @echo "✔ Package installation complete"

# Dry-run dotter deployment (preview what will be linked)
dry:
    @echo "==> Running dotter dry-run..."
    dotter deploy --dry-run
    @echo "✔ Dry-run complete"

# Deploy dotfiles via dotter (create symbolic links)
stow:
    @echo "==> Deploying dotfiles..."
    dotter deploy
    @echo "✔ Dotfiles deployed"

# Run post-installation scripts
post:
    @echo "==> Running post-installation scripts..."
    {{if os() == "windows" { "pwsh -NoProfile -File post/post.ps1" } else { "bash post/post.sh" } }}
    @echo "✔ Post-installation complete"

# Full workflow: install → stow → post (idempotent)
up: install stow post
    @echo "==> ✔ All done! Dotfiles are ready."

# Remove all deployed dotfiles
uninstall:
    @echo "==> Uninstalling dotfiles..."
    dotter undeploy --verbose
    @echo "✔ Dotfiles removed"

# Update dotter cache
cache:
    @echo "==> Updating dotter cache..."
    dotter cache
    @echo "✔ Cache updated"
