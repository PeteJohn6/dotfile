# =============================================================================
# Zsh Profile - Utilities Module
# =============================================================================
# Provides common helper functions for all profile modules

# test_command: Check if a command exists in PATH
test_command() {
  [[ $# -eq 1 ]] || return 1
  (( $+commands[$1] ))
}

# profile_warn: Consistent warning output helper
profile_warn() {
  print -u2 -- "$1"
}

# Cache directory for storing completions and other generated files
typeset -g PROFILE_CACHE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/cache"
mkdir -p -- "$PROFILE_CACHE_DIR" 2>/dev/null || :
