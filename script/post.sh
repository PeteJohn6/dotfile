#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
POST_DIR="$REPO_ROOT/packages/post"

if [[ ! -d "$POST_DIR" ]]; then
    echo "[post] No post directory found, skipping"
    exit 0
fi

errors=0
for script in "$POST_DIR"/*.sh; do
    [[ -f "$script" ]] || continue
    name="$(basename "$script")"
    echo "[post] Running $name..."
    if bash "$script"; then
        :
    else
        echo "[post] ERROR: $name failed (exit code $?)"
        errors=$((errors + 1))
    fi
done

if [[ $errors -gt 0 ]]; then
    echo "[post] WARNING: $errors script(s) had errors"
fi

echo "[post] All post-install scripts completed"
