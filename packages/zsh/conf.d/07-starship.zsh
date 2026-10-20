# =============================================================================
# Zsh Profile - Starship Module
# =============================================================================
# Initialize the Starship prompt when the binary is available.

if ! command -v starship >/dev/null 2>&1; then
  return 0
fi

eval "$(starship init zsh)"
