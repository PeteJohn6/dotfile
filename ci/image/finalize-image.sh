#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
HOME_DIR="${HOME:-/root}"

if [[ ! -d "$WORKSPACE_ROOT" ]]; then
    echo "[image-finalize] ERROR: Missing workspace root: $WORKSPACE_ROOT" >&2
    exit 1
fi

if [[ ! -d "$HOME_DIR" ]]; then
    echo "[image-finalize] ERROR: Missing home directory: $HOME_DIR" >&2
    exit 1
fi

materialize_link() {
    local link_path="$1"
    local resolved tmp_path

    resolved="$(readlink -f "$link_path")"
    if [[ "$resolved" != "$WORKSPACE_ROOT"* ]]; then
        return 0
    fi

    tmp_path="${link_path}.image-finalize.$$"
    rm -rf "$tmp_path"

    cp -aL "$link_path" "$tmp_path"
    rm -rf "$link_path"
    mv "$tmp_path" "$link_path"

    echo "[image-finalize] Materialized: ${link_path#$HOME_DIR/}"
}

collect_repo_links() {
    local path resolved

    while IFS= read -r -d '' path; do
        resolved="$(readlink -f "$path")" || continue
        if [[ "$resolved" == "$WORKSPACE_ROOT"* ]]; then
            printf '%s\0' "$path"
        fi
    done < <(find "$HOME_DIR" -type l -print0)
}

echo "[image-finalize] Materializing repository-backed symlinks under $HOME_DIR..."

while true; do
    mapfile -d '' repo_links < <(collect_repo_links)
    if [[ "${#repo_links[@]}" -eq 0 ]]; then
        break
    fi

    for link_path in "${repo_links[@]}"; do
        [[ -n "$link_path" ]] || continue
        materialize_link "$link_path"
    done
done

mapfile -d '' remaining_links < <(collect_repo_links)
if [[ "${#remaining_links[@]}" -gt 0 ]]; then
    echo "[image-finalize] ERROR: Repository-backed symlinks remain under $HOME_DIR" >&2
    for link_path in "${remaining_links[@]}"; do
        [[ -n "$link_path" ]] || continue
        echo "[image-finalize] Remaining: $link_path -> $(readlink -f "$link_path")" >&2
    done
    exit 1
fi

cp -aL "$HOME_DIR/.config/zsh/conf.d" "$HOME_DIR/conf.d"
echo "[image-finalize] Materialized zsh runtime modules: conf.d"

case "$WORKSPACE_ROOT" in
    ""|"/")
        echo "[image-finalize] ERROR: Refusing to delete unsafe workspace root: '$WORKSPACE_ROOT'" >&2
        exit 1
        ;;
esac

rm -rf "$WORKSPACE_ROOT"
echo "[image-finalize] Removed build workspace: $WORKSPACE_ROOT"
