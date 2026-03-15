#!/usr/bin/env bash
set -euo pipefail

dir="${1:-$PWD}"

if [[ ! -d "$dir" ]]; then
    dir="$HOME"
fi

name="$(basename "$dir")"
name="$(printf '%s' "$name" | tr -cs '[:alnum:]_.-' '-')"
name="${name#-}"
name="${name%-}"

if [[ -z "$name" ]]; then
    name="main"
fi

if tmux has-session -t "$name" 2>/dev/null; then
    tmux switch-client -t "$name"
    exit 0
fi

tmux new-session -d -s "$name" -c "$dir"
tmux switch-client -t "$name"
