# =============================================================================
# Zsh Profile - Git Module
# =============================================================================
# Git shortcuts and utilities

if ! typeset -f test_command >/dev/null 2>&1; then
  test_command() { command -v "$1" >/dev/null 2>&1; }
fi

if ! typeset -f profile_warn >/dev/null 2>&1; then
  profile_warn() { print -u2 -- "$1"; }
fi

# Guard: Return if git is not available
if ! test_command git; then
  profile_warn "[conf.d/10-git.zsh] Skipping: 'git' command not found in PATH"
  return 0
fi

# Lightweight git-prefixed helpers
gits() { git status "$@"; }
gitl() { git log --oneline --decorate --graph "$@"; }
gitco() { git checkout "$@"; }
gitcm() { git commit "$@"; }
gitp() { git push "$@"; }
gitpl() { git pull "$@"; }
gitwt() { git worktree "$@"; }

_git_relative_path() {
  local base="$1"
  local target="$2"

  if [[ "$target" == "$base" ]]; then
    print -- "."
    return 0
  fi

  case "$target" in
    "$base"/*)
      print -- "${target#"$base"/}"
      ;;
    *)
      print -- "$target"
      ;;
  esac
}

# Git worktree interactive selector
gitwts() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    profile_warn "gitwts: not inside a Git repository"
    return 0
  fi

  if ! test_command fzf; then
    profile_warn "gitwts: fzf not found in PATH"
    return 0
  fi

  local line current_worktree branch rel_path
  local -a items

  while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
      current_worktree="${line#worktree }"
      continue
    fi

    if [[ "$line" == branch\ * && -n "$current_worktree" ]]; then
      branch="${line#branch refs/heads/}"
      rel_path="$(_git_relative_path "$PWD" "$current_worktree")"
      items+=("${branch}"$'\t'"${rel_path}"$'\t'"${current_worktree}")
      current_worktree=""
      continue
    fi

    if [[ "$line" == detached && -n "$current_worktree" ]]; then
      rel_path="$(_git_relative_path "$PWD" "$current_worktree")"
      items+=("(detached)"$'\t'"${rel_path}"$'\t'"${current_worktree}")
      current_worktree=""
    fi
  done < <(git worktree list --porcelain)

  if (( ${#items[@]} == 0 )); then
    profile_warn "gitwts: no worktrees found"
    return 0
  fi

  local selected selected_path selected_branch selected_relpath
  selected="$(
    printf '%s\n' "${items[@]}" |
      fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt='worktree> ' \
        --delimiter=$'\t' \
        --with-nth=1,2 \
        --header='BRANCH  |  PATH' \
        --preview-window='right,60%,wrap' \
        --preview='git -C {3} --no-pager status -sb 2>/dev/null; echo; git -C {3} --no-pager log -n 30 --oneline --decorate --graph 2>/dev/null'
  )"

  if [[ -z "$selected" ]]; then
    print -- "gitwts: cancelled"
    return 0
  fi

  IFS=$'\t' read -r selected_branch selected_relpath selected_path <<< "$selected"
  if [[ -z "$selected_path" || ! -d "$selected_path" ]]; then
    profile_warn "gitwts: path does not exist: $selected_path"
    return 0
  fi

  builtin cd -- "$selected_path" || return 0
  print -- "gitwts -> $PWD"
}
