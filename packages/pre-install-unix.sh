#!/usr/bin/env bash
# This file is a rule library sourced by install.sh.
# Required caller context:
# - PLATFORM / IS_CONTAINER / PKG_MANAGER / STRICT / INSTALL_BIN_DIR
# - preinstall_log()
# - preinstall_handle_failure()

cleanup_tmp_dir() {
    local dir="$1"
    if [[ -n "$dir" && -d "$dir" ]]; then
        rm -rf "$dir" || true
    fi
}

preinstall_neovim() {
    if [[ "$PKG_MANAGER" != "apt" ]]; then
        preinstall_log "Skipping neovim manual install (pkg manager: $PKG_MANAGER)"
        return 0
    fi

    if command -v nvim >/dev/null 2>&1; then
        preinstall_log "Neovim already available in PATH"
        return 0
    fi

    local install_root="$HOME/.local/opt"
    local install_dir="$install_root/neovim"
    local link_dir="$INSTALL_BIN_DIR"
    local link_bin="$link_dir/nvim"
    local arch tarball_url tmp_dir archive_file extract_dir extracted_root

    if [[ -x "$install_dir/bin/nvim" ]]; then
        if ! mkdir -p "$link_dir"; then
            preinstall_handle_failure "Failed to create link directory: $link_dir"
            return 0
        fi
        if ! ln -sf "$install_dir/bin/nvim" "$link_bin"; then
            preinstall_handle_failure "Failed to link existing nvim binary at $link_bin"
            return 0
        fi
        preinstall_log "Neovim tarball install already present: $install_dir"
        return 0
    fi

    if ! command -v curl >/dev/null 2>&1; then
        preinstall_handle_failure "curl is required for neovim tarball install"
        return 0
    fi

    if ! command -v tar >/dev/null 2>&1; then
        preinstall_handle_failure "tar is required for neovim tarball install"
        return 0
    fi

    case "$(uname -m)" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="arm64" ;;
        *)
            preinstall_handle_failure "Unsupported architecture for neovim tarball: $(uname -m)"
            return 0
            ;;
    esac

    tarball_url="${NEOVIM_TARBALL_URL:-https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${arch}.tar.gz}"

    if ! tmp_dir="$(mktemp -d 2>/dev/null)"; then
        preinstall_handle_failure "Failed to create temporary directory for neovim install"
        return 0
    fi

    archive_file="$tmp_dir/nvim.tar.gz"
    extract_dir="$tmp_dir/extract"

    preinstall_log "Installing neovim tarball from: $tarball_url"

    if ! curl -fsSL "$tarball_url" -o "$archive_file"; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Failed to download neovim tarball"
        return 0
    fi

    if ! mkdir -p "$extract_dir"; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Failed to create extraction directory"
        return 0
    fi

    if ! tar -xzf "$archive_file" -C "$extract_dir"; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Failed to extract neovim tarball"
        return 0
    fi

    extracted_root="$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -1 || true)"
    if [[ -z "$extracted_root" || ! -x "$extracted_root/bin/nvim" ]]; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Extracted neovim tarball is missing bin/nvim"
        return 0
    fi

    if ! mkdir -p "$install_root" "$link_dir"; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Failed to create neovim install directories"
        return 0
    fi

    if ! rm -rf "$install_dir"; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Failed to clear existing neovim directory: $install_dir"
        return 0
    fi
    if ! mv "$extracted_root" "$install_dir"; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Failed to move neovim into $install_dir"
        return 0
    fi

    if ! ln -sf "$install_dir/bin/nvim" "$link_bin"; then
        cleanup_tmp_dir "$tmp_dir"
        preinstall_handle_failure "Failed to link nvim binary at $link_bin"
        return 0
    fi

    cleanup_tmp_dir "$tmp_dir"
    if ! "$link_bin" --version >/dev/null 2>&1; then
        preinstall_handle_failure "Installed nvim failed version check"
        return 0
    fi

    preinstall_log "Neovim tarball installed: $link_bin"
}

PREINSTALL_RULE_MAP=(
    "neovim:preinstall_neovim"
)

preinstall_resolve_handler() {
    local pkg="$1"
    local entry rule_pkg handler
    for entry in "${PREINSTALL_RULE_MAP[@]}"; do
        rule_pkg="${entry%%:*}"
        handler="${entry#*:}"
        if [[ "$rule_pkg" == "$pkg" ]]; then
            echo "$handler"
            return 0
        fi
    done
    return 1
}

run_pre_install_for_package() {
    local pkg="$1"
    local handler
    if handler="$(preinstall_resolve_handler "$pkg")"; then
        "$handler"
    fi
}
