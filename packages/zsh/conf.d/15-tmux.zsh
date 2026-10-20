# =============================================================================
# Zsh Profile - Tmux Module
# =============================================================================
# Wrap tmux to always request UTF-8 output mode.

if ! command -v tmux >/dev/null 2>&1; then
  return 0
fi

tmux() {
  command tmux -u "$@"
}
