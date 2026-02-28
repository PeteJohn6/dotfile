#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
STRICT=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT=1
            shift
            ;;
        *)
            echo "[install] ERROR: Unknown argument: $1"
            echo "[install] Usage: bash script/install.sh [--strict]"
            exit 2
            ;;
    esac
done

# shellcheck source=script/misc.sh
source "$SCRIPT_DIR/misc.sh"

if ! detect_platform; then
    echo "[install] ERROR: Failed to detect platform"
    exit 1
fi

echo "[install] Platform: $PLATFORM"

# Select package list based on environment
if [ "$IS_CONTAINER" -eq 1 ]; then
    LIST_FILE="$REPO_ROOT/packages/container.list"
    echo "[install] Environment: container"
else
    LIST_FILE="$REPO_ROOT/packages/packages.list"
    echo "[install] Environment: host"
fi

if [[ -z "${INSTALL_BIN_DIR:-}" ]]; then
    if [ "$IS_CONTAINER" -eq 1 ]; then
        INSTALL_BIN_DIR="/usr/local/bin"
    else
        INSTALL_BIN_DIR="$HOME/.local/bin"
    fi
fi

case ":$PATH:" in
    *":$INSTALL_BIN_DIR:"*) ;;
    *) export PATH="$INSTALL_BIN_DIR:$PATH" ;;
esac

if [[ "$PKG_MANAGER" == "brew" ]] && ! command -v brew >/dev/null 2>&1; then
    echo "[install] ERROR: Homebrew not found. Run bootstrap first."
    exit 1
fi

echo "[install] Package manager: $PKG_MANAGER"
echo "[install] Binary link dir: $INSTALL_BIN_DIR"

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

PARSED_PKG=""
PARSED_CLI=""
PARSED_TAG=""

parse_main_entry() {
    local main="$1"

    main="$(trim "$main")"
    PARSED_PKG=""
    PARSED_CLI=""
    PARSED_TAG=""

    [[ -z "$main" ]] && return 0

    if [[ "$main" =~ @([A-Za-z0-9_-]+)$ ]]; then
        PARSED_TAG="${BASH_REMATCH[1]}"
        main="$(trim "${main%@"$PARSED_TAG"}")"
    fi

    if [[ "$main" =~ ^([^()[:space:]]+)\(([^()[:space:]]+)\)$ ]]; then
        PARSED_PKG="${BASH_REMATCH[1]}"
        PARSED_CLI="${BASH_REMATCH[2]}"
    else
        PARSED_PKG="$main"
        PARSED_CLI="$main"
    fi
}

parse_packages() {
    while IFS= read -r line; do
        line="${line%%$'\r'}"
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        local main alias_part install_name manager alias_name mapping
        main="${line%%|*}"
        parse_main_entry "$main"
        [[ -z "$PARSED_PKG" ]] && continue
        [[ -z "$PARSED_TAG" || "$PARSED_TAG" == "unix" || "$PARSED_TAG" == "$PLATFORM" ]] || continue

        install_name="$PARSED_PKG"
        if [[ "$line" == *"|"* ]]; then
            alias_part="${line#*|}"
            alias_part="${alias_part%%#*}"
            alias_part="$(trim "$alias_part")"
            for mapping in $alias_part; do
                [[ "$mapping" != *:* ]] && continue
                manager="${mapping%%:*}"
                alias_name="${mapping#*:}"
                if [[ "$manager" == "$PKG_MANAGER" ]]; then
                    install_name="$alias_name"
                    break
                fi
            done
        fi

        echo "$PARSED_PKG:$PARSED_CLI:$install_name"
    done < "$LIST_FILE"
}

preinstall_log() {
    echo "[pre-install:$PKG_MANAGER] $1"
}

preinstall_handle_failure() {
    local msg="$1"
    if [[ "$STRICT" == "1" ]]; then
        echo "[pre-install:$PKG_MANAGER] ERROR: $msg"
        exit 1
    fi
    echo "[pre-install:$PKG_MANAGER] WARN: $msg"
}

refresh_package_index() {
    preinstall_log "Updating package index..."
    case "$PKG_MANAGER" in
        apt)
            if ! maybe_sudo env DEBIAN_FRONTEND=noninteractive apt-get update -qq; then
                preinstall_handle_failure "Failed to update apt index"
            fi
            ;;
        dnf)
            if ! maybe_sudo env DNF_YUM_AUTO_YES=1 dnf makecache -q; then
                preinstall_handle_failure "Failed to refresh dnf cache"
            fi
            ;;
        pacman)
            if ! maybe_sudo pacman -Sy --noconfirm; then
                preinstall_handle_failure "Failed to refresh pacman index"
            fi
            ;;
        brew)
            if ! env NONINTERACTIVE=1 CI=1 brew update; then
                preinstall_handle_failure "Failed to update Homebrew index"
            fi
            ;;
    esac
}

install_package() {
    local install_name="$1"

    case "$PKG_MANAGER" in
        apt)
            maybe_sudo env DEBIAN_FRONTEND=noninteractive \
                apt-get install -y -qq \
                -o Dpkg::Options::=--force-confdef \
                -o Dpkg::Options::=--force-confold \
                "$install_name"
            ;;
        dnf)
            maybe_sudo env DNF_YUM_AUTO_YES=1 dnf install -y -q "$install_name"
            ;;
        pacman) maybe_sudo pacman -S --noconfirm --needed "$install_name" ;;
        brew)   env NONINTERACTIVE=1 CI=1 brew install "$install_name" ;;
    esac
}

is_package_satisfied() {
    local cli_name="$1"
    command -v "$cli_name" >/dev/null 2>&1
}

# Collect packages into array (bash 3.2 compatible)
packages=()
cli_names=()
install_names=()
while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    pkg="${item%%:*}"
    rest="${item#*:}"
    cli="${rest%%:*}"
    install_name="${rest#*:}"
    packages+=("$pkg")
    cli_names+=("$cli")
    install_names+=("$install_name")
done < <(parse_packages)

source "$REPO_ROOT/packages/pre-install-unix.sh"

echo "[install] Running pre-install rules..."
for pkg in "${packages[@]}"; do
    run_pre_install_for_package "$pkg"
done
refresh_package_index
preinstall_log "Pre-install complete"

echo "[install] Installing ${#packages[@]} package(s)..."
echo ""

succeeded=0
skipped=0
failed=0
skipped_packages=()
failed_packages=()

for i in "${!packages[@]}"; do
    pkg="${packages[$i]}"
    cli_name="${cli_names[$i]}"
    install_name="${install_names[$i]}"

    if is_package_satisfied "$cli_name"; then
        echo "[install] Skipping: $pkg (already satisfied: $cli_name)"
        skipped=$((skipped + 1))
        skipped_packages+=("$pkg")
        continue
    fi

    echo "[install] Installing: $pkg"
    if install_package "$install_name"; then
        succeeded=$((succeeded + 1))
    else
        echo "[install] WARN: Failed to install: $pkg"
        failed=$((failed + 1))
        failed_packages+=("$pkg")
    fi
done

echo ""
echo "[install] =========================================="
echo "[install] Install complete: $succeeded succeeded, $skipped skipped, $failed failed"
if [[ "$skipped" -gt 0 ]]; then
    echo "[install] Skipped packages: ${skipped_packages[*]}"
fi
if [[ "$failed" -gt 0 ]]; then
    echo "[install] Failed packages: ${failed_packages[*]}"
fi
echo "[install] =========================================="

if [[ "$STRICT" == "1" && "$failed" -gt 0 ]]; then
    exit 1
fi
