# =============================================================================
# Zsh Profile - Starship Module
# =============================================================================
# Initialize the Starship prompt when the binary is available.

if ! typeset -f test_command >/dev/null 2>&1; then
  test_command() { command -v "$1" >/dev/null 2>&1; }
fi

if ! test_command starship; then
  return 0
fi

eval "$(starship init zsh)"
