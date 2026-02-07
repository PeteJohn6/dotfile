#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
POST_DIR="$REPO_ROOT/packages/post"

if [[ ! -d "$POST_DIR" ]]; then
    echo "[post] No post directory found, skipping"
    exit 0
fi

for script in "$POST_DIR"/*.sh; do
    [[ -f "$script" ]] || continue
    echo "[post] Running $(basename "$script")..."
    bash "$script"
done

echo "[post] All post-install scripts completed"
