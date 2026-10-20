# =============================================================================
# Zsh Profile - Utilities Module
# =============================================================================
# Provides common helper functions for all profile modules

# profile_warn: Consistent warning output helper
profile_warn() {
  print -u2 -- "$1"
}

# Cache directory for storing completions and other generated files
typeset -g PROFILE_CACHE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/cache"
mkdir -p -- "$PROFILE_CACHE_DIR" 2>/dev/null || :
