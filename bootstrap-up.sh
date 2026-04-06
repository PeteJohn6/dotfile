#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_just_bin() {
    local candidate
    local -a candidates=()

    if [[ -n "${JUST_BIN:-}" ]]; then
        candidates+=("$JUST_BIN")
    fi

    if command -v just >/dev/null 2>&1; then
        command -v just
        return 0
    fi

    if [[ -n "${INSTALL_BIN_DIR:-}" ]]; then
        candidates+=("${INSTALL_BIN_DIR%/}/just")
    fi

    case "$(uname -s)" in
        Darwin)
            candidates+=("/opt/homebrew/bin/just" "/usr/local/bin/just")
            ;;
        Linux)
            candidates+=("/usr/local/bin/just")
            ;;
    esac

    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

main() {
    cd "$REPO_ROOT"

    echo "[bootstrap-up] Running bootstrap..."
    bash "$REPO_ROOT/bootstrap/bootstrap.sh"

    local just_bin
    if ! just_bin="$(resolve_just_bin)"; then
        echo "[bootstrap-up] ERROR: Failed to locate 'just' after bootstrap" >&2
        echo "[bootstrap-up] Set JUST_BIN or INSTALL_BIN_DIR if just is installed outside the default PATH." >&2
        exit 1
    fi

    echo "[bootstrap-up] Using just binary: $just_bin"
    echo "[bootstrap-up] Running: just up"
    "$just_bin" up
}

main "$@"
