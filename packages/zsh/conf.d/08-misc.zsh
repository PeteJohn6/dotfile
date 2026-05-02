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

  export NVM_DIR="$HOME/.nvm"

  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi
