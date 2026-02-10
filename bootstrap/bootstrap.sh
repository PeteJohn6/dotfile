#!/usr/bin/env bash
# Unified Bootstrap Script for Linux/macOS
# Installs just via package managers and downloads dotter to local bin/

set -euo pipefail

# ============================================================================
# Shared Functions (Platform-Independent)
# ============================================================================

# Environment detection functions
is_container() {
    # Check for Docker
    [ -f /.dockerenv ] && return 0

    # Check for container environment variable
    [ -n "${container:-}" ] && return 0

    # Check cgroup for docker/lxc/podman/containerd
    if [ -f /proc/1/cgroup ]; then
        grep -qE 'docker|lxc|podman|containerd' /proc/1/cgroup 2>/dev/null && return 0
    fi

    return 1
}

needs_sudo() {
    # If running as root, don't need sudo
    [ "$(id -u)" -eq 0 ] && return 1

    # If in container, check if we can write to target directory
    if is_container; then
        # Test write permission to /usr/local/bin
        [ -w /usr/local/bin ] && return 1
    fi

    # Standard environment needs sudo
    return 0
}

# Wrapper function for conditional sudo
maybe_sudo() {
    if needs_sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

# Binary directory setup
setup_bin_directory() {
    echo "[bootstrap] Setting up bin/ directory..."
    mkdir -p bin

    # Add to .gitignore if not already present
    if ! grep -q "^bin/$" .gitignore 2>/dev/null; then
        echo "bin/" >> .gitignore
        echo "[bootstrap] Added bin/ to .gitignore"
    fi
}

# Download dotter binary
download_dotter() {
    local platform=$1
    local arch=$2

    echo "[bootstrap] Downloading dotter for ${platform}-${arch}..."

    # Define download function based on available tool
    if command -v curl &> /dev/null; then
        download_file() {
            curl -L -o "$1" "$2"
        }
        download_string() {
            curl -s "$1"
        }
    elif command -v wget &> /dev/null; then
        download_file() {
            wget -O "$1" "$2"
        }
        download_string() {
            wget -q -O - "$1"
        }
    else
        echo "[bootstrap] ERROR: No download tool available (curl/wget)"
        exit 1
    fi

    # Fetch latest version from GitHub
    DOTTER_VERSION=$(download_string https://api.github.com/repos/SuperCuber/dotter/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

    if [ -z "$DOTTER_VERSION" ]; then
        echo "[bootstrap] ERROR: Failed to fetch dotter version"
        exit 1
    fi

    echo "[bootstrap] Latest dotter version: v${DOTTER_VERSION}"

    # Download to bin/
    case "$platform" in
        linux)
            DOTTER_URL="https://github.com/SuperCuber/dotter/releases/download/v${DOTTER_VERSION}/dotter-linux-${arch}-musl"
            ;;
        macos)
            DOTTER_URL="https://github.com/SuperCuber/dotter/releases/download/v${DOTTER_VERSION}/dotter-macos-${arch}"
            ;;
        *)
            echo "[bootstrap] ERROR: Unsupported platform: $platform"
            exit 1
            ;;
    esac

    if ! download_file "bin/dotter" "$DOTTER_URL"; then
        echo "[bootstrap] ERROR: Failed to download dotter"
        exit 1
    fi

    chmod +x bin/dotter
    echo "[bootstrap] dotter downloaded successfully: $(bin/dotter --version)"
}

# ============================================================================
# Linux Bootstrap
# ============================================================================

bootstrap_linux() {
    echo "[bootstrap] Detected: Linux"

    # Detect and report environment
    if [ "$(id -u)" -eq 0 ]; then
        echo "[bootstrap] Environment: Running as root"
        echo "[bootstrap] Sudo not required"
    elif is_container; then
        if [ -w /usr/local/bin ]; then
            echo "[bootstrap] Environment: Container (writable system paths)"
            echo "[bootstrap] Sudo not required"
        else
            echo "[bootstrap] Environment: Container (restricted permissions)"
            echo "[bootstrap] Sudo will be used for system installations"
        fi
    else
        echo "[bootstrap] Environment: Standard Linux"
        echo "[bootstrap] Sudo will be used for system installations"
    fi

    # Detect package manager
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
    else
        echo "[bootstrap] ERROR: No supported package manager found (apt/dnf/pacman)"
        exit 1
    fi

    echo "[bootstrap] Package manager: $PKG_MANAGER"

    # Check and install required dependencies (curl/wget for dotter download)
    echo "[bootstrap] Checking required dependencies..."

    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        echo "[bootstrap] Neither curl nor wget found. Installing curl..."
        case "$PKG_MANAGER" in
            apt)
                maybe_sudo apt-get update -qq >/dev/null 2>&1
                DEBIAN_FRONTEND=noninteractive maybe_sudo apt-get install -y -qq curl
                ;;
            dnf)
                maybe_sudo dnf install -y -q curl
                ;;
            pacman)
                maybe_sudo pacman -Sy --noconfirm curl
                ;;
        esac
        echo "[bootstrap] curl installed successfully"
    fi

    # Install just via package manager
    if command -v just &> /dev/null; then
        echo "[bootstrap] just already installed: $(just --version)"
    else
        echo "[bootstrap] Installing just via $PKG_MANAGER..."
        case "$PKG_MANAGER" in
            apt)
                maybe_sudo apt-get update -qq
                DEBIAN_FRONTEND=noninteractive maybe_sudo apt-get install -y -qq just
                ;;
            dnf)
                maybe_sudo dnf install -y -q just
                ;;
            pacman)
                maybe_sudo pacman -Sy --noconfirm just
                ;;
        esac
        echo "[bootstrap] just installed: $(just --version)"
    fi

    # Download dotter to bin/
    if [ -f bin/dotter ]; then
        echo "[bootstrap] dotter already exists: $(bin/dotter --version)"
    else
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) DOTTER_ARCH="x64" ;;
            aarch64|arm64) DOTTER_ARCH="arm64" ;;
            *) echo "[bootstrap] ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        download_dotter "linux" "$DOTTER_ARCH"
    fi
}

# ============================================================================
# macOS Bootstrap
# ============================================================================

bootstrap_macos() {
    echo "[bootstrap] Detected: macOS"

    # Detect and report environment
    if [ "$(id -u)" -eq 0 ]; then
        echo "[bootstrap] Environment: Running as root"
        echo "[bootstrap] Note: Homebrew should not be run as root"
    else
        echo "[bootstrap] Environment: Standard macOS"
    fi

    # Check for curl (should always be present on macOS)
    if ! command -v curl &> /dev/null; then
        echo "[bootstrap] ERROR: curl not found. This is unexpected on macOS."
        echo "[bootstrap] Please install curl manually and try again."
        exit 1
    fi

    # Detect architecture for Homebrew path
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        BREW_PREFIX="/opt/homebrew"
    else
        BREW_PREFIX="/usr/local"
    fi

    echo "[bootstrap] Architecture: $ARCH"

    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        if [ -f "$BREW_PREFIX/bin/brew" ]; then
            echo "[bootstrap] Homebrew found at $BREW_PREFIX, adding to PATH..."
            eval "$($BREW_PREFIX/bin/brew shellenv)"
        else
            echo "[bootstrap] Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$($BREW_PREFIX/bin/brew shellenv)"
            echo "[bootstrap] Homebrew installed successfully"
            echo "[bootstrap] NOTE: Add Homebrew to your shell profile to persist:"
            echo "  echo 'eval \"\$($BREW_PREFIX/bin/brew shellenv)\"' >> ~/.zprofile"
        fi
    else
        echo "[bootstrap] Homebrew already installed: $(brew --version | head -n1)"
    fi

    # Install just via Homebrew
    if command -v just &> /dev/null; then
        echo "[bootstrap] just already installed: $(just --version)"
    else
        echo "[bootstrap] Installing just via Homebrew..."
        brew install just
        echo "[bootstrap] just installed: $(just --version)"
    fi

    # Download dotter to bin/
    if [ -f bin/dotter ]; then
        echo "[bootstrap] dotter already exists: $(bin/dotter --version)"
    else
        case "$ARCH" in
            x86_64) DOTTER_ARCH="x64" ;;
            arm64) DOTTER_ARCH="arm64" ;;
            *) echo "[bootstrap] ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        download_dotter "macos" "$DOTTER_ARCH"
    fi
}

# ============================================================================
# Local Configuration Setup
# ============================================================================

# Setup local.toml from default template
setup_local_toml() {
    local default_file

    if is_container; then
        default_file=".dotter/default/container.toml"
        echo "[bootstrap] Environment: Container detected"
    else
        default_file=".dotter/default/unix.toml"
    fi

    if [ -f ".dotter/local.toml" ]; then
        echo "[bootstrap] local.toml already exists, showing diff:"
        if command -v diff &> /dev/null; then
            diff -u "$default_file" ".dotter/local.toml" || true
        else
            echo "[bootstrap] (diff not available, skipping comparison)"
        fi
    else
        cp "$default_file" ".dotter/local.toml"
        echo "[bootstrap] Copied $default_file -> .dotter/local.toml"
    fi
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    echo "[bootstrap] Starting bootstrap process..."

    # Navigate to repository root (parent of script directory)
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    REPO_ROOT="$(dirname "$SCRIPT_DIR")"
    cd "$REPO_ROOT"
    echo "[bootstrap] Working directory: $REPO_ROOT"
    echo ""

    # Setup bin directory
    setup_bin_directory

    # Platform dispatch
    case "$(uname -s)" in
        Linux)
            bootstrap_linux
            ;;
        Darwin)
            bootstrap_macos
            ;;
        *)
            echo "[bootstrap] ERROR: Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac

    # Setup local.toml from default template
    echo ""
    setup_local_toml

    echo ""
    echo "[bootstrap] =========================================="
    echo "[bootstrap] Bootstrap complete!"
    echo "[bootstrap] =========================================="
    echo "[bootstrap] Installed tools:"
    echo "  - just: $(just --version)"
    echo "  - dotter: $(bin/dotter --version)"
    echo ""
    echo "Next steps:"
    echo "  1. Run 'just install' to install packages"
    echo "  2. Run 'just stow' to deploy dotfiles"
    echo "  3. Or run 'just up' to do everything at once"
}

main
