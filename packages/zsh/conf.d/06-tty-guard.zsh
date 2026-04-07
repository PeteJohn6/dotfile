# =============================================================================
# Zsh Profile - TTY Guard Module
# =============================================================================
# Exit interactive shells that have lost their backing PTY. This avoids
# orphaned tmux shells spinning on a deleted /dev/pts entry.

if ! typeset -f test_command >/dev/null 2>&1; then
  test_command() { command -v "$1" >/dev/null 2>&1; }
fi

if ! typeset -f profile_warn >/dev/null 2>&1; then
  profile_warn() { print -u2 -- "$1"; }
fi

if ! test_command readlink; then
  return 0
fi

_profile_fd_points_to_deleted_tty() {
  local fd_path="$1"
  local target

  target="$(readlink "$fd_path" 2>/dev/null)" || return 1
  [[ "$target" == *" (deleted)"* ]]
}

profile_guard_deleted_tty() {
  emulate -L zsh

  [[ -o interactive ]] || return 0

  if _profile_fd_points_to_deleted_tty "/proc/$$/fd/0" ||
     _profile_fd_points_to_deleted_tty "/proc/$$/fd/1" ||
     _profile_fd_points_to_deleted_tty "/proc/$$/fd/2"; then
    profile_warn "[zsh profile] Exiting orphaned shell with deleted TTY"
    builtin exit 0
  fi
}

if [[ -z "${precmd_functions[(r)profile_guard_deleted_tty]}" ]]; then
  precmd_functions+=(profile_guard_deleted_tty)
fi
