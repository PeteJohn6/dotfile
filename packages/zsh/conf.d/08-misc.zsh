# =============================================================================
# Zsh Profile - Misc Module
# =============================================================================
# Small interactive defaults and user-level Linux path setup.

export TERM="xterm-256color"

if [[ "$OSTYPE" == linux* ]]; then
  typeset -g _profile_local_bin="$HOME/.local/bin"

  if [[ ":$PATH:" != *":$_profile_local_bin:"* ]]; then
    export PATH="$_profile_local_bin:$PATH"
  fi

fi

# nvm is a sourced shell function, so check its script before initializing it.
if [[ "$OSTYPE" == linux* || "$OSTYPE" == darwin* ]]; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [[ -s "$NVM_DIR/nvm.sh" && -r "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
    if [[ -s "$NVM_DIR/bash_completion" && -r "$NVM_DIR/bash_completion" ]]; then
      source "$NVM_DIR/bash_completion"
    fi
  fi
fi

return 0
