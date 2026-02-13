# =============================================================================
# Zsh Profile - Main Entry Point
# =============================================================================

typeset -g PROFILE_ROOT="${${(%):-%N}:A:h}"

# Initialize Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# === Auto-load conf.d modules ===
typeset -ga _profile_loaded_modules=()
typeset -ga _profile_failed_modules=()

typeset -g profile_dir="${PROFILE_ROOT}/conf.d"
if [[ -d "$profile_dir" ]]; then
  typeset module
  for module in "$profile_dir"/*.zsh(N); do
    if source "$module"; then
      _profile_loaded_modules+=("${module:t}")
    else
      _profile_failed_modules+=("${module:t}")
      print -u2 -- "[zsh profile] Failed to load module: ${module:t}"
    fi
  done
fi

# Display profile load summary (only in debug mode)
if [[ -n "${PROFILE_DEBUG:-}" ]]; then
  print
  print "[Zsh Profile]"
  print "  Location: ${PROFILE_ROOT}"

  if (( ${#_profile_loaded_modules[@]} > 0 )); then
    print "  Loaded modules: ${(j:, :)_profile_loaded_modules}"
  fi

  if (( ${#_profile_failed_modules[@]} > 0 )); then
    print "  Failed modules: ${(j:, :)_profile_failed_modules}"
  fi

  print
fi
