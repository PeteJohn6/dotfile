#!/usr/bin/env bash
set -euo pipefail

TPM_DIR="${HOME}/.tmux/plugins/tpm"
TPM_REPO="https://github.com/tmux-plugins/tpm"

if ! command -v tmux >/dev/null 2>&1; then
    echo "[post:tmux] tmux not installed, skipping"
    exit 0
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[post:tmux] git not installed, skipping"
    exit 0
fi

mkdir -p "$(dirname "$TPM_DIR")"

if [[ ! -d "$TPM_DIR/.git" ]]; then
    echo "[post:tmux] Installing TPM..."
    git clone --depth 1 "$TPM_REPO" "$TPM_DIR"
else
    echo "[post:tmux] Updating TPM..."
    git -C "$TPM_DIR" pull --ff-only --quiet || echo "[post:tmux] WARN: Failed to update TPM"
fi

if [[ ! -x "$TPM_DIR/bin/install_plugins" ]]; then
    echo "[post:tmux] TPM install script missing, skipping plugin sync"
    exit 0
fi

echo "[post:tmux] Installing tmux plugins..."
TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins/" "$TPM_DIR/bin/install_plugins"
echo "[post:tmux] Tmux plugins ready"
