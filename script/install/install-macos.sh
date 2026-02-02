#!/usr/bin/env bash
# install-macos.sh - Install packages from lists/macos.list via Homebrew

set -euo pipefail

say() { echo "[install] $*"; }
ok() { echo "✔ $*"; }
err() { echo "✘ $*" >&2; exit 1; }

# Ensure Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    err "Homebrew not found. Run bootstrap/bootstrap.sh first."
fi

say "Using Homebrew: $(brew --version | head -1)"

# Update Homebrew
say "Updating Homebrew..."
brew update

# Read and install packages
LIST_FILE="lists/macos.list"
if [[ ! -f "$LIST_FILE" ]]; then
    err "Package list not found: $LIST_FILE"
fi

say "Reading packages from $LIST_FILE"
PACKAGES=()
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Trim whitespace
    pkg="${line%%#*}"
    pkg="${pkg## }"
    pkg="${pkg%% }"
    [[ -n "$pkg" ]] && PACKAGES+=("$pkg")
done < "$LIST_FILE"

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    say "No packages to install"
    exit 0
fi

say "Installing ${#PACKAGES[@]} packages: ${PACKAGES[*]}"

# Install packages (idempotent - brew handles already-installed)
for pkg in "${PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        ok "Already installed: $pkg"
    else
        if brew install "$pkg"; then
            ok "Installed: $pkg"
        else
            err "Failed to install: $pkg"
        fi
    fi
done

ok "All packages installed successfully"
