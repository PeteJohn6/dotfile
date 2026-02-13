# =============================================================================
# Zsh Profile - Docker Module
# =============================================================================
# Docker utilities and interactive container management with fzf

if ! typeset -f test_command >/dev/null 2>&1; then
  test_command() { command -v "$1" >/dev/null 2>&1; }
fi

if ! typeset -f profile_warn >/dev/null 2>&1; then
  profile_warn() { print -u2 -- "$1"; }
fi

# Guard: Return if docker is not available
if ! test_command docker; then
  profile_warn "[conf.d/20-docker.zsh] Skipping: 'docker' command not found in PATH"
  return 0
fi

_docker_require_fzf() {
  local caller="$1"
  if ! test_command fzf; then
    profile_warn "${caller}: fzf not found in PATH"
    return 1
  fi
  return 0
}

# 1. Enter an interactive shell in a running container
dockerfshell() {
  _docker_require_fzf dockerfshell || return 0

  local selected container_id
  selected="$(
    docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' |
      fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt='container> ' \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --header='Select a running container (ID | NAME | IMAGE)' \
        --preview-window='right,60%,wrap' \
        --preview='docker logs {1} --tail 50' \
        --ansi
  )"

  [[ -z "$selected" ]] && return 0
  container_id="${selected%%$'\t'*}"

  if docker exec "$container_id" pwsh -c 'exit' >/dev/null 2>&1; then
    docker exec -it "$container_id" pwsh
  else
    docker exec -it "$container_id" bash
  fi
}

# 2. View logs of one or more containers
dockerflogs() {
  _docker_require_fzf dockerflogs || return 0

  local selections line container_id
  selections="$(
    docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' |
      fzf --header='Select container(s) to show logs' --multi --bind 'enter:accept' --ansi
  )"

  [[ -z "$selections" ]] && return 0
  while IFS= read -r line; do
    container_id="${line%%$'\t'*}"
    [[ -z "$container_id" ]] && continue
    print
    print -- "=== Logs for $container_id ==="
    docker logs "$container_id" --tail 100
  done <<< "$selections"
}

# 3. Remove one or more images
dockerfrmi() {
  _docker_require_fzf dockerfrmi || return 0

  local selections line
  local -a image_ids
  selections="$(
    docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.ID}}' |
      fzf --header='Select image(s) to remove (docker image rm)' --multi --ansi
  )"

  [[ -z "$selections" ]] && return 0
  while IFS= read -r line; do
    image_ids+=("${line##*$'\t'}")
  done <<< "$selections"

  (( ${#image_ids[@]} == 0 )) && return 0
  docker image rm "${image_ids[@]}"
}

# 4. Remove one or more containers (forced)
dockerfrm() {
  _docker_require_fzf dockerfrm || return 0

  local selections line
  local -a container_ids
  selections="$(
    docker container ls -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' |
      fzf --header='Select container(s) to remove (forced)' --multi --ansi
  )"

  [[ -z "$selections" ]] && return 0
  while IFS= read -r line; do
    container_ids+=("${line%%$'\t'*}")
  done <<< "$selections"

  (( ${#container_ids[@]} == 0 )) && return 0
  docker container rm -f "${container_ids[@]}"
}

# 5. Run a new interactive container from a local image
dockerfrun() {
  _docker_require_fzf dockerfrun || return 0

  local selected image_ref
  selected="$(
    docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.ID}}' |
      fzf --header='Select image to run' --ansi
  )"

  [[ -z "$selected" ]] && return 0
  image_ref="${selected%%$'\t'*}"
  docker run -it --rm "$image_ref" bash
}

# 6. Execute an arbitrary command in a running container
dockerfexec() {
  _docker_require_fzf dockerfexec || return 0

  local selected container_id command_line
  selected="$(
    docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' |
      fzf --header='Select a container to exec into' --ansi
  )"

  [[ -z "$selected" ]] && return 0
  container_id="${selected%%$'\t'*}"

  read -r "command_line?Enter the command to run inside container $container_id: "
  [[ -z "$command_line" ]] && return 0
  docker exec -it "$container_id" ${=command_line}
}

_docker_completion_needs_regen() {
  local completion_file="$1"
  local now age_days
  local -A file_stat

  [[ -f "$completion_file" ]] || return 0

  zmodload -F zsh/stat b:zstat 2>/dev/null || return 0
  zstat -A file_stat +mtime -- "$completion_file" 2>/dev/null || return 0

  now="${EPOCHSECONDS:-}"
  if [[ -z "$now" ]] && test_command date; then
    now="$(date +%s 2>/dev/null || true)"
  fi
  [[ -z "$now" ]] && return 0

  age_days=$(( (now - file_stat[mtime]) / 86400 ))
  (( age_days > 30 ))
}

_docker_setup_completion_cache() {
  local completion_file

  typeset -g PROFILE_CACHE_DIR="${PROFILE_CACHE_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh/cache}"
  mkdir -p -- "$PROFILE_CACHE_DIR" 2>/dev/null || :

  completion_file="${PROFILE_CACHE_DIR}/docker_completion.zsh"
  if _docker_completion_needs_regen "$completion_file"; then
    docker completion zsh >| "$completion_file" 2>/dev/null || :
  fi

  [[ -f "$completion_file" ]] && source "$completion_file"
}

_docker_setup_completion_cache
