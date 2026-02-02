#!/usr/bin/env bash
# post.sh - Run all post-installation scripts

set -euo pipefail

say() { echo "[post] $*"; }
ok() { echo "✔ $*"; }
err() { echo "✘ $*" >&2; }

POST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say "Running post-installation scripts from $POST_DIR"

# Find all .sh scripts except post.sh itself
shopt -s nullglob
SCRIPTS=("$POST_DIR"/*.sh)
shopt -u nullglob

# Filter out post.sh itself
FILTERED=()
for script in "${SCRIPTS[@]}"; do
    if [[ "$(basename "$script")" != "post.sh" ]]; then
        FILTERED+=("$script")
    fi
done

if [[ ${#FILTERED[@]} -eq 0 ]]; then
    say "No post-installation scripts found"
    exit 0
fi

say "Found ${#FILTERED[@]} script(s) to run"

# Run each script
for script in "${FILTERED[@]}"; do
    say "Running: $(basename "$script")"
    if bash "$script"; then
        ok "Completed: $(basename "$script")"
    else
        err "Failed: $(basename "$script")"
    fi
done

ok "All post-installation scripts completed"
