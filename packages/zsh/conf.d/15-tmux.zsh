# =============================================================================
# Zsh Profile - Tmux Module
# =============================================================================
# Wrap tmux to always request UTF-8 output mode.

if ! typeset -f test_command >/dev/null 2>&1; then
  test_command() { command -v "$1" >/dev/null 2>&1; }
fi

if ! test_command tmux; then
  return 0
fi

tmux() {
  command tmux -u "$@"
}
