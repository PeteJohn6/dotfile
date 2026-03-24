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
gitcm() { git commit "$@"; }
gitp() { git push "$@"; }
gitpl() { git pull "$@"; }
gitwt() { git worktree "$@"; }

_git_require_fzf() {
  local caller="$1"
  if ! test_command fzf; then
    profile_warn "${caller}: fzf not found in PATH"
    return 1
  fi
  return 0
}

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

_git_branch_items() {
  git for-each-ref \
    --sort=-committerdate \
    --format='%(refname:short)'$'\t''%(HEAD)'$'\t''%(upstream:short)'$'\t''%(committerdate:relative)'$'\t''%(subject)' \
    refs/heads
}

gitco() {
  if (( $# > 0 )); then
    git checkout "$@"
    return $?
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    profile_warn "gitco: not inside a Git repository"
    return 0
  fi

  _git_require_fzf gitco || return 0

  local line selected selected_branch
  local -a items

  while IFS= read -r line; do
    [[ -n "$line" ]] && items+=("$line")
  done < <(_git_branch_items)

  if (( ${#items[@]} == 0 )); then
    profile_warn "gitco: no branches found"
    return 0
  fi

  selected="$(
    printf '%s\n' "${items[@]}" |
      fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt='branch> ' \
        --delimiter=$'\t' \
        --with-nth=2,1,3,4,5 \
        --header='CURRENT  |  BRANCH  |  UPSTREAM  |  AGE  |  SUBJECT' \
        --preview-window='right,60%,wrap' \
        --preview='git --no-pager branch -vv --list {1} 2>/dev/null; echo; git --no-pager log -n 30 --oneline --decorate --graph {1} 2>/dev/null'
  )"

  if [[ -z "$selected" ]]; then
    print -- "gitco: cancelled"
    return 0
  fi

  selected_branch="${selected%%$'\t'*}"
  if [[ -z "$selected_branch" ]]; then
    profile_warn "gitco: invalid branch selection"
    return 0
  fi

  git checkout "$selected_branch"
}

_git_worktree_items() {
  local current_root common_dir main_root
  local line current_worktree branch rel_path exists is_main is_current

  current_root="$(git rev-parse --path-format=absolute --show-toplevel 2>/dev/null)" || return 1
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  main_root="${common_dir:h}"

  while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
      current_worktree="${line#worktree }"
      continue
    fi

    if [[ "$line" == branch\ * && -n "$current_worktree" ]]; then
      branch="${line#branch refs/heads/}"
      rel_path="$(_git_relative_path "$PWD" "$current_worktree")"
      exists=0
      [[ -d "$current_worktree" ]] && exists=1
      is_main=0
      [[ "$current_worktree" == "$main_root" ]] && is_main=1
      is_current=0
      [[ "$current_worktree" == "$current_root" ]] && is_current=1
      print -- "${branch}"$'\t'"${rel_path}"$'\t'"${current_worktree}"$'\t'"${exists}"$'\t'"${is_main}"$'\t'"${is_current}"
      current_worktree=""
      continue
    fi

    if [[ "$line" == detached && -n "$current_worktree" ]]; then
      rel_path="$(_git_relative_path "$PWD" "$current_worktree")"
      exists=0
      [[ -d "$current_worktree" ]] && exists=1
      is_main=0
      [[ "$current_worktree" == "$main_root" ]] && is_main=1
      is_current=0
      [[ "$current_worktree" == "$current_root" ]] && is_current=1
      print -- "(detached)"$'\t'"${rel_path}"$'\t'"${current_worktree}"$'\t'"${exists}"$'\t'"${is_main}"$'\t'"${is_current}"
      current_worktree=""
    fi
  done < <(git worktree list --porcelain)
}

# Git worktree interactive selector
gitwts() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    profile_warn "gitwts: not inside a Git repository"
    return 0
  fi

  _git_require_fzf gitwts || return 0

  local branch rel_path selected_path exists is_main is_current
  local -a items

  while IFS=$'\t' read -r branch rel_path selected_path exists is_main is_current; do
    [[ -z "$selected_path" ]] && continue
    items+=("${branch}"$'\t'"${rel_path}"$'\t'"${selected_path}")
  done < <(_git_worktree_items)

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
        --preview='if [ -d {3} ]; then git -C {3} --no-pager status -sb 2>/dev/null; echo; git -C {3} --no-pager log -n 30 --oneline --decorate --graph 2>/dev/null; else echo "worktree path missing: {3}"; fi'
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

# Git worktree interactive remover
gitwtr() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    profile_warn "gitwtr: not inside a Git repository"
    return 0
  fi

  _git_require_fzf gitwtr || return 0

  local branch rel_path worktree_path exists is_main is_current
  local -a items

  while IFS=$'\t' read -r branch rel_path worktree_path exists is_main is_current; do
    [[ -z "$worktree_path" ]] && continue
    [[ "$is_main" == "1" || "$is_current" == "1" ]] && continue
    items+=("${branch}"$'\t'"${rel_path}"$'\t'"${worktree_path}"$'\t'"${exists}")
  done < <(_git_worktree_items)

  if (( ${#items[@]} == 0 )); then
    profile_warn "gitwtr: no removable worktrees found"
    return 0
  fi

  local selected selected_branch selected_relpath selected_path selected_exists confirm
  selected="$(
    printf '%s\n' "${items[@]}" |
      fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt='remove-worktree> ' \
        --delimiter=$'\t' \
        --with-nth=1,2 \
        --header='BRANCH  |  PATH' \
        --preview-window='right,60%,wrap' \
        --preview='if [ -d {3} ]; then git -C {3} --no-pager status -sb 2>/dev/null; echo; git -C {3} --no-pager log -n 30 --oneline --decorate --graph 2>/dev/null; else echo "worktree path missing: {3}"; fi'
  )"

  if [[ -z "$selected" ]]; then
    print -- "gitwtr: cancelled"
    return 0
  fi

  IFS=$'\t' read -r selected_branch selected_relpath selected_path selected_exists <<< "$selected"
  if [[ -z "$selected_path" ]]; then
    profile_warn "gitwtr: invalid worktree selection"
    return 0
  fi

  read -r "confirm?Remove worktree ${selected_relpath}? [y/N] "
  case "${confirm:l}" in
    y|yes)
      ;;
    *)
      print -- "gitwtr: cancelled"
      return 0
      ;;
  esac

  git worktree remove -- "$selected_path" || return $?
  print -- "gitwtr: removed $selected_path"
}
