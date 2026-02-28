#!/usr/bin/env bash

detect_platform() {
    local uname_s
    uname_s="$(uname -s)"

    case "$uname_s" in
        Darwin)
            PLATFORM="macos"
            ;;
        Linux)
            PLATFORM="linux"
            ;;
        *)
            echo "[detect-platform] ERROR: Unsupported platform: $uname_s"
            return 1
            ;;
    esac

    IS_CONTAINER=0
    if [ -f /.dockerenv ]; then
        IS_CONTAINER=1
    elif [ -n "${container:-}" ]; then
        IS_CONTAINER=1
    elif [ -f /proc/1/cgroup ]; then
        if grep -qE 'docker|lxc|podman|containerd' /proc/1/cgroup 2>/dev/null; then
            IS_CONTAINER=1
        fi
    fi

    case "$PLATFORM" in
        macos)
            PKG_MANAGER="brew"
            ;;
        linux)
            if command -v apt-get >/dev/null 2>&1; then
                PKG_MANAGER="apt"
            elif command -v dnf >/dev/null 2>&1; then
                PKG_MANAGER="dnf"
            elif command -v pacman >/dev/null 2>&1; then
                PKG_MANAGER="pacman"
            else
                echo "[detect-platform] ERROR: No supported package manager found (apt/dnf/pacman)"
                return 1
            fi
            ;;
    esac

    return 0
}

needs_sudo() {
    # macOS installs are user-space driven in this repo and should not use sudo.
    [ "${PLATFORM:-}" = "macos" ] && return 1

    [ "$(id -u)" -eq 0 ] && return 1
    [ "${IS_CONTAINER:-0}" -eq 1 ] && return 1
    return 0
}

maybe_sudo() {
    if needs_sudo; then
        sudo "$@"
    else
        "$@"
    fi
}
