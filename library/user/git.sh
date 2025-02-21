#!/usr/bin/env bash

# ---
# @description      Git operations wrapper providing safe and convenient git commands
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.1.0
# @since            1.0.0
# @category         Version Control
# @dependencies     bash (>= 4.0), git (>= 2.0)
# @envvar           ROOTINE_GIT_USER_EMAIL      User's email for git config
# @envvar           ROOTINE_GIT_USER_NAME       User's name for git config
# @envvar           ROOTINE_GIT_CORE_FILEMODE   Git filemode setting
# @envvar           ROOTINE_GIT_DEFAULT_BRANCH  Default git branch (default: main)
# @envvar           ROOTINE_GIT_DEFAULT_REMOTE  Default git remote (default: origin)
# @security         Implements safe git operations with proper validation
# @todo             Add support for signed commits
# @todo             Add support for GitHub/GitLab specific features
# ---

is_sourced || exit 1

# --
# @description      Validates if current directory is a git repository
# @return           0 if in git repo, 1 otherwise
# @internal
# --
_is_git_repo() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    log_error "Not in a Git repository"
    return 1
  fi
  return 0
}

# --
# @description      Clones a git repository with various options
# @param            repository_url URL of the repository to clone
# @param            [destination_directory] Optional target directory
# @arguments        [--bare] [--depth N] [--branch NAME] [--single-branch]
#                   [--recurse-submodules[=BOOL]]
# @return           0 on success, 1 on failure
# @example          git_clone "https://github.com/user/repo" "target-dir" --depth 1
# @public
# --
git_clone() {
  local repository_url="${1:?Repository URL required}"
  local destination_directory="${2:-}"
  local -A options=(
    [bare]=false
    [depth]=""
    [branch]=""
    [single_branch]=false
    [recurse_submodules]=true
  )
  shift "$(( ${#} >= 2 ? 2 : 1 ))"

  # Input validation
  if [[ ! "${repository_url}" =~ ^(https?|git|ssh):// ]]; then
    log_error "Invalid repository URL format: ${repository_url}"
    return 1
  fi

  while (( ${#} )); do
    case "${1}" in
      --bare)
        options[bare]=true
        ;;
      --depth)
        if [[ ! "${2}" =~ ^[1-9][0-9]*$ ]]; then
          log_error "Depth must be a positive integer"
          return 1
        fi
        options[depth]="${2}"
        shift
        ;;
      --branch)
        options[branch]="${2:?--branch requires a value}"
        shift
        ;;
      --single-branch)
        options[single_branch]=true
        ;;
      --recurse-submodules)
        if [[ "${2:-}" =~ ^(true|false)$ ]]; then
          options[recurse_submodules]="${2}"
          shift
        fi
        ;;
      *)
        log_error "Invalid argument '${1}'"
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "${destination_directory}" ]]; then
    destination_directory="$(basename "${repository_url%.git}")"
    destination_directory="${destination_directory%.*}"

    if [[ -z "${destination_directory}" ]]; then
      log_error "Cannot determine destination directory"
      return 1
    fi
  fi

  # Check if destination exists and is not empty
  if [[ -d "${destination_directory}" ]] && [[ -n "$(ls -A "${destination_directory}")" ]]; then
    log_error "Destination directory exists and is not empty: ${destination_directory}"
    return 1
  fi

  local -a cmd=(git clone)

  "${options[bare]}" && cmd+=(--bare)
  [[ -n "${options[depth]}" ]] && cmd+=(--depth "${options[depth]}")
  [[ -n "${options[branch]}" ]] && cmd+=(--branch "${options[branch]}")
  "${options[single_branch]}" && cmd+=(--single-branch)
  "${options[recurse_submodules]}" && cmd+=(--recurse-submodules)

  if ! "${cmd[@]}" "${repository_url}" "${destination_directory}"; then
    log_error "Clone failed for repository: ${repository_url}"
    return 1
  fi

  log_success "Successfully cloned ${repository_url} to ${destination_directory}"
  return 0
}

# --
# @description      Manages git configuration at different scopes
# @param            [scope] Configuration scope (local|global|system)
# @arguments        [--show-only] Only show current configuration
# @return           0 on success, non-zero on failure
# @example          git_config global --show-only
# @public
# --
git_config() {
  local config_file="--${1:-global}"
  local show_only=false
  shift || true

  # Validate scope
  if [[ ! "${config_file#--}" =~ ^(local|global|system)$ ]]; then
    log_error "Invalid configuration scope: ${config_file#--}"
    return 1
  fi

  while (( ${#} )); do
    case "${1}" in
      --show-only)
        show_only=true
        ;;
      *)
        log_error "Invalid argument '${1}'"
        return 1
        ;;
    esac
    shift
  done

  local -i status=0

  if ! "${show_only}"; then
    local -A configs=(
      ["user.email"]="${ROOTINE_GIT_USER_EMAIL:-}"
      ["user.name"]="${ROOTINE_GIT_USER_NAME:-}"
      ["core.filemode"]="${ROOTINE_GIT_CORE_FILEMODE:-}"
    )

    for key in "${!configs[@]}"; do
      local value="${configs[$key]}"
      if [[ -n "${value}" ]]; then
        if ! git config "${config_file}" "${key}" "${value}"; then
          log_error "Failed to set ${key}=${value}"
          ((status++))
        fi
      fi
    done
  fi

  log_info "${config_file#--} Git configuration:"

  if ! git config "${config_file}" --list; then
    log_error "Failed to list ${config_file#--} configuration"
    ((status++))
  fi

  return "${status}"
}

# --
# @description      Resets git repository to specified commit
# @param            [commit] Commit to reset to (default: HEAD)
# @arguments        [--force] Skip confirmation prompt
# @return           0 on success, 1 on failure
# @example          git_reset HEAD~1 --force
# @public
# --
git_reset() {
  local commit="${1:-HEAD}"
  local force=false
  shift || true

  _is_git_repo || return 1

  while (( ${#} )); do
    case "${1}" in
      --force)
        force=true
        ;;
      *)
        log_error "Invalid argument '${1}'"
        return 1
        ;;
    esac
    shift
  done

  if ! git rev-parse --verify "${commit}" &>/dev/null; then
    log_error "Invalid commit reference: ${commit}"
    return 1
  fi

  if ! "${force}"; then
    log_warning "This will reset to '${commit}'. All uncommitted changes will be lost."
    read -r -p "Continue? [y/N] " response

    if [[ ! "${response}" =~ ^[Yy]$ ]]; then
      log_info "Operation cancelled"
      return 0
    fi
  fi

  local -a cmd=(
    "git rm -r --cached ."
    "git reset --hard ${commit}"
    "git clean -fd"
  )

  for c in "${cmd[@]}"; do
    if ! eval "${c}"; then
      log_error "Command failed: ${c}"
      return 1
    fi
  done

  log_success "Successfully reset to ${commit}"
  return 0
}

# --
# @description      Commits and pushes changes to remote repository
# @param            [commit_msg] Commit message (default: "Update")
# @arguments        [-f|--force] Force push
#                   [-v|--verbose] Verbose output
#                   [-b|--branch BRANCH] Target branch
#                   [-r|--remote REMOTE] Target remote
# @return           0 on success, 1 on failure
# @example          git_push "Fix bug" -b develop -v
# @public
# --
git_push() {
  local commit_msg="${1:-Update}"
  shift || true

  local force_push=false
  local verbose=false
  local branch="${ROOTINE_GIT_DEFAULT_BRANCH:-main}"
  local remote="${ROOTINE_GIT_DEFAULT_REMOTE:-origin}"

  _is_git_repo || return 1

  while (( ${#} )); do
    case "${1}" in
      -f|--force)
        force_push=true
        ;;
      -v|--verbose)
        verbose=true
        ;;
      -b|--branch)
        branch="${2:?Branch name required for -b/--branch}"
        shift
        ;;
      -r|--remote)
        remote="${2:?Remote name required for -r/--remote}"
        shift
        ;;
      *)
        log_error "Invalid argument '${1}'"
        return 1
        ;;
    esac
    shift
  done

  # Validate remote exists
  if ! git remote get-url "${remote}" &>/dev/null; then
    log_error "Remote '${remote}' does not exist"
    return 1
  fi

  if ! git add .; then
    log_error "Failed to stage changes"
    return 1
  fi

  if ! git status --porcelain | grep -q .; then
    log_info "No changes to commit"
    return 0
  fi

  if ! git commit -m "${commit_msg}"; then
    log_error "Commit failed"
    return 1
  fi

  local -a push_args=("${remote}" "${branch}")
  "${force_push}" && push_args+=(--force)
  "${verbose}" && push_args+=(--verbose)

  if ! git push "${push_args[@]}"; then
    log_error "Failed to push to ${remote}:${branch}"
    return 1
  fi

  log_success "Successfully pushed to ${remote}:${branch}"
  return 0
}
