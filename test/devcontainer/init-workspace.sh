#!/usr/bin/env bash
set -euo pipefail

src="/repo-ro"
dst="/workspace"

if [[ ! -d "$src" ]]; then
    echo "[init-workspace] ERROR: Missing read-only source mount: $src" >&2
    exit 1
fi

mkdir -p "$dst"

# Reset the container-local workspace to a fresh copy of the host repo
# without Git metadata or host-local ignored state.
rsync_filters=(
    "--exclude=.git"
    "--exclude=.tree"
    "--filter=+ /.agents/"
    "--filter=+ /.agents/skills/"
    "--filter=+ /.agents/skills/***"
    "--filter=- /.agents/***"
    "--filter=+ /.claude/"
    "--filter=+ /.claude/skills/"
    "--filter=+ /.claude/skills/***"
    "--filter=- /.claude/***"
    "--exclude=.dotter/local.toml"
    "--exclude=.dotter/cache.toml"
    "--exclude=bin/"
    "--exclude=.DS_Store"
    "--exclude=Thumbs.db"
    "--exclude=desktop.ini"
    "--exclude=.vscode/"
    "--exclude=.idea/"
    "--exclude=*.swp"
    "--exclude=*.swo"
    "--exclude=*~"
    "--exclude=packages/nvim/lazy-lock.json"
)

rsync -a --delete --delete-excluded "${rsync_filters[@]}" "$src"/ "$dst"/

workspace_packages="$dst/packages/packages.list"
workspace_container="$dst/packages/container.list"

if [[ ! -f "$workspace_packages" ]]; then
    echo "[init-workspace] ERROR: Missing package list in workspace: $workspace_packages" >&2
    exit 1
fi

# In the disposable test workspace, treat the full desktop package list as the
# container install list so `just install` exercises the broader toolchain.
rm -f "$workspace_container"
cp "$workspace_packages" "$workspace_container"

echo "[init-workspace] Copied repository from $src to $dst"
echo "[init-workspace] Replaced /workspace/packages/container.list with packages.list for testing"
