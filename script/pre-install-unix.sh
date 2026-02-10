#!/usr/bin/env bash
set -euo pipefail

STRICT=""
PKG_MANAGER=""
PACKAGE_LIST=""

usage() {
    echo "[pre-install] Usage: bash script/pre-install-unix.sh --strict <0|1> --pkg-manager <apt|dnf|pacman|brew> --package-list <pkg1,pkg2,...>"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT="${2:-}"
            shift 2
            ;;
        --pkg-manager)
            PKG_MANAGER="${2:-}"
            shift 2
            ;;
        --package-list)
            PACKAGE_LIST="${2:-}"
            shift 2
            ;;
        *)
            echo "[pre-install] ERROR: Unknown argument: $1"
            usage
            exit 2
            ;;
    esac
done

if [[ "$STRICT" != "0" && "$STRICT" != "1" ]]; then
    echo "[pre-install] ERROR: --strict must be 0 or 1"
    usage
    exit 2
fi

case "$PKG_MANAGER" in
    apt|dnf|pacman|brew) ;;
    *)
        echo "[pre-install] ERROR: --pkg-manager must be one of: apt, dnf, pacman, brew"
        usage
        exit 2
        ;;
esac

log() {
    echo "[pre-install:$PKG_MANAGER] $1"
}

handle_failure() {
    local msg="$1"
    if [[ "$STRICT" == "1" ]]; then
        echo "[pre-install:$PKG_MANAGER] ERROR: $msg"
        exit 1
    fi
    echo "[pre-install:$PKG_MANAGER] WARN: $msg"
}

is_container() {
    [[ -f /.dockerenv ]] && return 0
    [[ -n "${container:-}" ]] && return 0
    if [[ -f /proc/1/cgroup ]]; then
        grep -qE 'docker|lxc|podman|containerd' /proc/1/cgroup 2>/dev/null && return 0
    fi
    return 1
}

is_ubuntu() {
    [[ -f /etc/os-release ]] || return 1
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == "ubuntu" ]] && return 0
    [[ "${ID_LIKE:-}" =~ ubuntu ]] && return 0
    return 1
}

needs_sudo() {
    [[ "$(id -u)" -eq 0 ]] && return 1
    if is_container; then
        [[ -w /usr/local/bin ]] && return 1
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

packages=()
if [[ -n "$PACKAGE_LIST" ]]; then
    IFS=',' read -r -a packages <<< "$PACKAGE_LIST"
fi

has_package() {
    local needle="$1"
    local pkg
    for pkg in "${packages[@]}"; do
        [[ "$pkg" == "$needle" ]] && return 0
    done
    return 1
}

configure_neovim_apt_repo() {
    has_package "neovim" || return 0

    if ! is_ubuntu; then
        log "Skipping neovim repo setup (not Ubuntu)"
        return 0
    fi

    if is_container; then
        log "Skipping neovim repo setup (container environment)"
        return 0
    fi

    if ! command -v add-apt-repository >/dev/null 2>&1; then
        log "Installing software-properties-common..."
        if ! maybe_sudo apt-get install -y -qq software-properties-common; then
            handle_failure "Failed to install software-properties-common"
            return 0
        fi
    fi

    if maybe_sudo grep -Rqs "neovim-ppa/stable" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
        log "Neovim PPA already configured"
        return 0
    fi

    log "Adding neovim stable PPA..."
    if ! maybe_sudo add-apt-repository -y ppa:neovim-ppa/stable; then
        handle_failure "Failed to add ppa:neovim-ppa/stable"
    fi
}

run_package_rules() {
    local pkg
    for pkg in "${packages[@]}"; do
        case "$PKG_MANAGER:$pkg" in
            apt:neovim)
                configure_neovim_apt_repo
                ;;
            *)
                ;;
        esac
    done
}

refresh_package_index() {
    log "Updating package index..."
    case "$PKG_MANAGER" in
        apt)
            export DEBIAN_FRONTEND=noninteractive
            if ! maybe_sudo apt-get update -qq; then
                handle_failure "Failed to update apt index"
            fi
            ;;
        dnf)
            if ! maybe_sudo dnf makecache -q; then
                handle_failure "Failed to refresh dnf cache"
            fi
            ;;
        pacman)
            if ! maybe_sudo pacman -Sy --noconfirm; then
                handle_failure "Failed to refresh pacman index"
            fi
            ;;
        brew)
            if ! brew update; then
                handle_failure "Failed to update Homebrew index"
            fi
            ;;
    esac
}

run_package_rules
refresh_package_index

log "Pre-install complete"
