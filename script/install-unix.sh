#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Container detection (mirrors bootstrap.sh)
is_container() {
    [ -f /.dockerenv ] && return 0
    [ -n "${container:-}" ] && return 0
    if [ -f /proc/1/cgroup ]; then
        grep -qE 'docker|lxc|podman|containerd' /proc/1/cgroup 2>/dev/null && return 0
    fi
    return 1
}

# Select package list based on environment
if is_container; then
    LIST_FILE="$REPO_ROOT/packages/container.list"
    echo "[install] Environment: container"
else
    LIST_FILE="$REPO_ROOT/packages/packages.list"
    echo "[install] Environment: unix"
fi

parse_packages() {
    while IFS= read -r line; do
        line="${line%%$'\r'}"
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        local main pkg tag
        main="${line%%|*}"
        pkg=$(echo "$main" | sed 's/@.*//' | xargs)
        tag=$(echo "$main" | grep -o '@[^ ]*' | tr -d '@' || true)
        [[ -z "$tag" || "$tag" == "unix" ]] && echo "$pkg"
    done < "$LIST_FILE"
}

needs_sudo() {
    [ "$(id -u)" -eq 0 ] && return 1
    if is_container; then
        [ -w /usr/local/bin ] && return 1
    fi
    return 0
}

maybe_sudo() {
    if needs_sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

detect_pkg_manager() {
    case "$(uname -s)" in
        Darwin)
            if ! command -v brew &> /dev/null; then
                echo "[install] ERROR: Homebrew not found. Run bootstrap first."
                exit 1
            fi
            PKG_MANAGER="brew"
            ;;
        Linux)
            if command -v apt-get &> /dev/null; then
                PKG_MANAGER="apt"
            elif command -v dnf &> /dev/null; then
                PKG_MANAGER="dnf"
            elif command -v pacman &> /dev/null; then
                PKG_MANAGER="pacman"
            else
                echo "[install] ERROR: No supported package manager found (apt/dnf/pacman)"
                exit 1
            fi
            ;;
        *)
            echo "[install] ERROR: Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac
    echo "[install] Package manager: $PKG_MANAGER"
}

load_aliases() {
    while IFS= read -r line; do
        line="${line%%$'\r'}"
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" != *"|"* ]] && continue
        local main alias_part pkg
        main="${line%%|*}"
        alias_part="${line#*|}"
        pkg=$(echo "$main" | sed 's/@.*//' | xargs)
        for mapping in $alias_part; do
            echo "${mapping%%:*}:${pkg}=${mapping#*:}"
        done
    done < "$LIST_FILE"
}

map_package_name() {
    local pkg="$1"
    local result
    result=$(echo "$PKG_ALIASES" | grep "^${PKG_MANAGER}:${pkg}=" | head -1 | cut -d= -f2)
    [ -n "$result" ] && echo "$result" || echo "$pkg"
}

install_package() {
    local pkg="$1"
    local mapped
    mapped=$(map_package_name "$pkg")

    case "$PKG_MANAGER" in
        apt)    maybe_sudo apt-get install -y -qq "$mapped" ;;
        dnf)    maybe_sudo dnf install -y -q "$mapped" ;;
        pacman) maybe_sudo pacman -S --noconfirm --needed "$mapped" ;;
        brew)   brew install "$mapped" ;;
    esac
}

# --- Main logic ---

detect_pkg_manager

PKG_ALIASES=$(load_aliases)

# Refresh package index
case "$PKG_MANAGER" in
    apt)    echo "[install] Updating package index..."
            maybe_sudo apt-get update -qq ;;
    dnf)    echo "[install] Updating package index..."
            maybe_sudo dnf makecache -q ;;
    pacman) echo "[install] Updating package index..."
            maybe_sudo pacman -Sy --noconfirm ;;
esac

# Collect packages into array (bash 3.2 compatible)
packages=()
while IFS= read -r pkg; do
    packages+=("$pkg")
done < <(parse_packages)

echo "[install] Installing ${#packages[@]} package(s)..."
echo ""

succeeded=0
failed=0

for pkg in "${packages[@]}"; do
    echo "[install] Installing: $pkg"
    if install_package "$pkg"; then
        succeeded=$((succeeded + 1))
    else
        echo "[install] WARN: Failed to install: $pkg"
        failed=$((failed + 1))
    fi
done

echo ""
echo "[install] =========================================="
echo "[install] Install complete: $succeeded succeeded, $failed failed"
echo "[install] =========================================="

if [ "$failed" -gt 0 ]; then
    exit 1
fi
