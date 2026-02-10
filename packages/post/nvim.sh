#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvim >/dev/null 2>&1; then
    echo "[post:nvim] Neovim not installed, skipping"
    exit 0
fi

echo "[post:nvim] Bootstrapping lazy.nvim..."
nvim --headless +qa

echo "[post:nvim] Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa
echo "[post:nvim] Neovim plugins installed"
