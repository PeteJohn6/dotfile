# =============================================================================
# Zsh Profile - Dev Container Module
# =============================================================================

# Guard: Return if devcontainer is not available.
if ! command -v devcontainer >/dev/null 2>&1; then
  profile_warn "[conf.d/25-devcontainer.zsh] Skipping: 'devcontainer' command not found in PATH"
  return 0
fi

alias devc='devcontainer'

# devcx is an interactive input prefix: the entire remaining buffer belongs
# to the container's Bash, including pipelines, redirects, and substitutions.
[[ -o interactive ]] || return 0
zmodload zsh/zle || return 0

_devcx_add_history() {
  emulate -L zsh
  local original="${_devcx_history_input-}"
  local expanded="${_devcx_history_expanded-}"
  unset _devcx_history_input _devcx_history_expanded

  # Only replace the submission prepared by our widget, never ordinary input.
  if [[ -n "$expanded" && "${1%$'\n'}" == "$expanded" ]]; then
    print -sr -- "$original"
    # A nonzero return alone leaves the expanded line available to Up until
    # the next command. Isolate it in a temporary history context instead;
    # zsh restores the original context after processing this history line.
    fc -p
  fi
  return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook zshaddhistory _devcx_add_history

_devcx_accept_line() {
  emulate -L zsh
  setopt extendedglob
  local input="$BUFFER" command_text diagnostics suffix
  local -i trailing_slashes=0

  # Do not reinterpret a line already being parsed by the host shell.
  if [[ -n "$PREBUFFER" ]]; then
    zle _devcx_original_accept_line
    return
  fi

  # Allow indentation, but only recognize a literal first command word.
  input="${input##[[:blank:]]#}"
  if [[ "$input" != devcx && "$input" != devcx[[:space:]]* ]]; then
    zle _devcx_original_accept_line
    return
  fi

  command_text="${input#devcx}"
  command_text="${command_text##[[:blank:]]#}"
  if [[ -z "${command_text//[[:space:]]/}" ]]; then
    zle -M 'Usage: devcx <shell command>'
    return
  fi

  # Parse without executing. Keep incomplete shell constructs in the editor,
  # rather than submitting their remaining lines to the host shell.
  diagnostics="$(LC_ALL=C command bash -n <<< "$command_text" 2>&1)"
  local -i parse_result=$?
  suffix="$command_text"
  while [[ "$suffix" == *\\ ]]; do
    (( trailing_slashes += 1 ))
    suffix="${suffix%?}"
  done

  if [[ "$diagnostics" == *'unexpected end of file'* ||
        "$diagnostics" == *'unexpected EOF'* ||
        "$diagnostics" == *'here-document'*'delimited by end-of-file'* ]] ||
      (( trailing_slashes % 2 )); then
    BUFFER+=$'\n'
    CURSOR=${#BUFFER}
    zle -M 'devcx: continue the container command; Ctrl-C cancels'
    return
  fi

  if (( parse_result != 0 )); then
    zle -M "devcx: ${diagnostics}"
    return
  fi

  # Quote once for the host zsh; Bash inside the container interprets the text.
  typeset -g _devcx_history_input="$BUFFER"
  BUFFER="devcontainer exec --workspace-folder . bash -c ${(qq)command_text}"
  typeset -g _devcx_history_expanded="$BUFFER"
  CURSOR=${#BUFFER}
  zle _devcx_original_accept_line
}

# Preserve existing accept-line behavior and avoid wrapping ourselves on reload.
if [[ "${widgets[accept-line]}" != user:_devcx_accept_line ]]; then
  zle -A accept-line _devcx_original_accept_line
  zle -N accept-line _devcx_accept_line
fi
