#!/usr/bin/env bash
# Unified Bootstrap Script for Linux/macOS
# Installs just via package managers and downloads dotter to local bin/

set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_REPO_ROOT="$(dirname "$BOOTSTRAP_DIR")"
# shellcheck source=script/misc.sh
source "$BOOTSTRAP_REPO_ROOT/script/misc.sh"

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

# Parse browser_download_url entries from GitHub release JSON.
extract_release_asset_urls() {
    local release_json=$1
    printf '%s\n' "$release_json" | sed -nE 's/.*"browser_download_url":[[:space:]]*"([^"]+)".*/\1/p'
}

# Verify dotter binary can execute and report version.
is_valid_dotter_binary() {
    local dotter_path=$1
    [ -x "$dotter_path" ] || return 1
    "$dotter_path" --version >/dev/null 2>&1
}

# Resolve the best release asset URL for the requested platform + architecture.
resolve_dotter_asset_url() {
    local target_platform=$1
    local arch=$2
    local release_json=$3
    local asset_urls asset_url asset_name lower_name score best_score best_url

    asset_urls=$(extract_release_asset_urls "$release_json")
    if [ -z "$asset_urls" ]; then
        echo "[bootstrap] ERROR: No release assets found in GitHub response" >&2
        return 1
    fi

    best_score=-1
    best_url=""

    while IFS= read -r asset_url; do
        [ -n "$asset_url" ] || continue
        asset_name="${asset_url##*/}"
        lower_name=$(printf '%s' "$asset_name" | tr '[:upper:]' '[:lower:]')

        # Ignore checksum/signature artifacts.
        case "$lower_name" in
            *.sha256*|*.sha512*|*.sig|*.asc|*.txt)
                continue
                ;;
        esac

        score=0
        case "$target_platform" in
            macos)
                case "$lower_name" in
                    *macos*|*apple-darwin*)
                        ;;
                    *)
                        continue
                        ;;
                esac
                case "$arch" in
                    arm64)
                        case "$lower_name" in
                            *arm64*|*aarch64*) score=100 ;;
                            *universal*) score=80 ;;
                            *) continue ;;
                        esac
                        ;;
                    x64)
                        case "$lower_name" in
                            *x64*|*x86_64*|*amd64*) score=100 ;;
                            *universal*) score=80 ;;
                            *) continue ;;
                        esac
                        ;;
                    *)
                        continue
                        ;;
                esac
                ;;
            linux)
                case "$lower_name" in
                    *linux*)
                        ;;
                    *)
                        continue
                        ;;
                esac
                case "$arch" in
                    arm64)
                        case "$lower_name" in
                            *arm64*|*aarch64*) score=90 ;;
                            *) continue ;;
                        esac
                        ;;
                    x64)
                        case "$lower_name" in
                            *x64*|*x86_64*|*amd64*) score=90 ;;
                            *) continue ;;
                        esac
                        ;;
                    *)
                        continue
                        ;;
                esac
                case "$lower_name" in
                    *musl*) score=$((score + 10)) ;;
                esac
                ;;
            *)
                echo "[bootstrap] ERROR: Unsupported platform: $target_platform" >&2
                return 1
                ;;
        esac

        case "$lower_name" in
            *.tar.gz|*.tgz|*.zip)
                score=$((score - 20))
                ;;
        esac

        if [ "$score" -gt "$best_score" ]; then
            best_score=$score
            best_url=$asset_url
        fi
    done <<< "$asset_urls"

    if [ -z "$best_url" ]; then
        echo "[bootstrap] ERROR: Failed to match dotter asset for ${target_platform}-${arch}" >&2
        echo "[bootstrap] Available assets:" >&2
        printf '%s\n' "$asset_urls" | sed 's/^/[bootstrap]   - /' >&2
        return 1
    fi

    printf '%s\n' "$best_url"
}

# Download dotter binary
download_dotter() {
    local target_platform=$1
    local arch=$2
    local release_json dotter_version dotter_url tmp_path

    echo "[bootstrap] Downloading dotter for ${target_platform}-${arch}..."

    # Define download function based on available tool
    if command -v curl &> /dev/null; then
        download_file() {
            curl -fL --retry 3 --connect-timeout 10 -o "$1" "$2"
        }
        download_string() {
            curl -fsSL "$1"
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
    if ! release_json=$(download_string https://api.github.com/repos/SuperCuber/dotter/releases/latest); then
        echo "[bootstrap] ERROR: Failed to fetch dotter release metadata"
        exit 1
    fi
    dotter_version=$(printf '%s\n' "$release_json" | sed -nE 's/.*"tag_name":[[:space:]]*"v([^"]+)".*/\1/p' | head -n1)

    if [ -z "$dotter_version" ]; then
        echo "[bootstrap] ERROR: Failed to fetch dotter version"
        exit 1
    fi

    echo "[bootstrap] Latest dotter version: v${dotter_version}"
    if ! dotter_url=$(resolve_dotter_asset_url "$target_platform" "$arch" "$release_json"); then
        exit 1
    fi
    echo "[bootstrap] Selected dotter asset: ${dotter_url##*/}"

    tmp_path="bin/.dotter.tmp.$$"
    rm -f "$tmp_path"
    if ! download_file "$tmp_path" "$dotter_url"; then
        echo "[bootstrap] ERROR: Failed to download dotter"
        rm -f "$tmp_path"
        exit 1
    fi

    chmod +x "$tmp_path"
    if ! is_valid_dotter_binary "$tmp_path"; then
        echo "[bootstrap] ERROR: Downloaded file is not a valid dotter binary"
        rm -f "$tmp_path"
        exit 1
    fi
    mv "$tmp_path" bin/dotter

    echo "[bootstrap] dotter downloaded successfully: $(bin/dotter --version 2>/dev/null)"
}

ensure_dotter() {
    local target_platform=$1
    local arch=$2

    if [ -f bin/dotter ]; then
        if is_valid_dotter_binary "bin/dotter"; then
            echo "[bootstrap] dotter already exists: $(bin/dotter --version 2>/dev/null)"
            return 0
        fi
        echo "[bootstrap] Existing bin/dotter is invalid, re-downloading..."
        rm -f bin/dotter
    fi

    download_dotter "$target_platform" "$arch"
}

# ============================================================================
# Linux Bootstrap
# ============================================================================

bootstrap_linux() {
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

    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) DOTTER_ARCH="x64" ;;
        aarch64|arm64) DOTTER_ARCH="arm64" ;;
        *) echo "[bootstrap] ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ensure_dotter "linux" "$DOTTER_ARCH"
}

# ============================================================================
# macOS Bootstrap
# ============================================================================

bootstrap_macos() {
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

    case "$ARCH" in
        x86_64) DOTTER_ARCH="x64" ;;
        arm64) DOTTER_ARCH="arm64" ;;
        *) echo "[bootstrap] ERROR: Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    ensure_dotter "macos" "$DOTTER_ARCH"
}

# ============================================================================
# Local Configuration Setup
# ============================================================================

# Setup local.toml from default template
setup_local_toml() {
    local default_file

    if [ "$IS_CONTAINER" -eq 1 ]; then
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

    if ! detect_platform; then
        echo "[bootstrap] ERROR: Failed to detect platform"
        exit 1
    fi
    echo "[bootstrap] Platform: $PLATFORM"
    if [ "$IS_CONTAINER" -eq 1 ]; then
        echo "[bootstrap] Environment: container"
    else
        echo "[bootstrap] Environment: host"
    fi
    echo "[bootstrap] Package manager: $PKG_MANAGER"

    # Platform dispatch
    case "$PLATFORM" in
        linux)
            bootstrap_linux
            ;;
        macos)
            bootstrap_macos
            ;;
        *)
            echo "[bootstrap] ERROR: Unsupported platform: $PLATFORM"
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
