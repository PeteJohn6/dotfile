#!/usr/bin/env bash
# install-linux.sh - Install packages from lists/linux.list
# Supports apt (Debian/Ubuntu), dnf (Fedora), pacman (Arch)

set -euo pipefail

say() { echo "[install] $*"; }
ok() { echo "✔ $*"; }
err() { echo "✘ $*" >&2; exit 1; }

# Detect package manager
if command -v apt >/dev/null 2>&1; then
    PKG_MGR="apt"
    INSTALL_CMD="sudo apt install -y"
    UPDATE_CMD="sudo apt update"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
    INSTALL_CMD="sudo dnf install -y"
    UPDATE_CMD="sudo dnf check-update || true"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MGR="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    UPDATE_CMD="sudo pacman -Sy"
else
    err "No supported package manager found (apt/dnf/pacman)"
fi

say "Using package manager: $PKG_MGR"

# Update package database
say "Updating package database..."
$UPDATE_CMD

# Read and install packages
LIST_FILE="lists/linux.list"
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

# Install packages (idempotent - package manager handles already-installed)
for pkg in "${PACKAGES[@]}"; do
    if $INSTALL_CMD "$pkg"; then
        ok "Installed/verified: $pkg"
    else
        err "Failed to install: $pkg"
    fi
done

ok "All packages installed successfully"
