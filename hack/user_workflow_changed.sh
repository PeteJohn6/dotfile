#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "usage: $0 <workspace|head>" >&2
    exit 1
}

matches_user_workflow_path() {
    local path=$1

    case "$path" in
        .dotter/*|bootstrap/*|packages/*|script/*|bootstrap-up.sh|justfile)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

collect_workspace_changes() {
    {
        git diff --name-only HEAD --
        git ls-files --others --exclude-standard
    } | awk 'NF' | sort -u
}

collect_head_changes() {
    if git rev-parse --verify HEAD^1 >/dev/null 2>&1; then
        git diff --name-only HEAD^1 HEAD --
        return 0
    fi

    git diff-tree --root --no-commit-id --name-only -r HEAD
}

main() {
    local source_mode=${1:-}
    local changed=false
    local path

    [[ -n "$source_mode" ]] || usage
    cd "$REPO_ROOT"

    case "$source_mode" in
        workspace)
            while IFS= read -r path; do
                [[ -n "$path" ]] || continue
                if matches_user_workflow_path "$path"; then
                    changed=true
                    break
                fi
            done < <(collect_workspace_changes)
            ;;
        head)
            while IFS= read -r path; do
                [[ -n "$path" ]] || continue
                if matches_user_workflow_path "$path"; then
                    changed=true
                    break
                fi
            done < <(collect_head_changes)
            ;;
        *)
            usage
            ;;
    esac

    printf '%s\n' "$changed"
}

main "$@"
