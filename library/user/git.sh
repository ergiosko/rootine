#!/usr/bin/env bash

# ---
# @description      Git operations wrapper providing safe and convenient git commands
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Version Control
# @dependencies     bash (>= 5.0.0), git (>= 2.0)
# @envvar           ROOTINE_GIT_USER_EMAIL      User's email for git config
# @envvar           ROOTINE_GIT_USER_NAME       User's name for git config
# @envvar           ROOTINE_GIT_CORE_FILEMODE   Git filemode setting
# @envvar           ROOTINE_GIT_WORKING_BRANCH  Default git branch (default: main)
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
    log_error "Current directory is not a Git repository"
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
    "git rm -rf --cached ."
    "git reset --hard ${commit}"
    "git clean -df"
  )
  for c in "${cmd[@]}"; do
    if ! eval "${c}"; then
      log_error "Command failed: ${c}"
      return 1
    fi
  done

  log_success "Repository reset to commit: ${commit}"
  return 0
}

# --
# @description      Creates a conventional commit and pushes changes to remote repository
# @param {string}   type        Commit type (default: "chore")
# @param {string}   scope       Optional commit scope
# @param {string}   description Commit description (default: "update")
# @param {string}   body        Optional commit body
# @param {string}   footer      Optional commit footer
# @param {boolean}  breaking    Whether this is a breaking change (default: false)
# @param {boolean}  branches    Push all branches flag (default: true)
# @param {string}   branch      Target branch (default: $ROOTINE_GIT_WORKING_BRANCH)
# @param {string}   remote      Target remote (default: $ROOTINE_GIT_DEFAULT_REMOTE)
# @param {boolean}  force       Force push flag (default: false)
# @param {boolean}  verbose     Verbose output flag (default: false)
# @param {boolean}  upstream    Set upstream tracking (default: true)
# @dependencies     - Git 2.0 or higher
# @envvar           ROOTINE_GIT_WORKING_BRANCH Default git branch
# @envvar           ROOTINE_GIT_DEFAULT_REMOTE Default git remote
# @exitstatus       0 Success
#                   1 Various error conditions:
#                     - Not a git repository
#                     - Remote does not exist
#                     - Failed to stage changes
#                     - Failed to create commit
#                     - Failed to push changes
# @stdout           Status messages
# @stderr           Error messages
# @example          # Basic usage with defaults
#                   git_push
#
#                   # Full example with all parameters
#                   git_push "feat" "auth" "add login page" \
#                     "Implements user authentication" \
#                     "Closes #123" \
#                     false true "develop" "origin" \
#                     false true true
#
#                   # Create feature with breaking change
#                   git_push "feat" "api" "new endpoint" "" "" true
# @see              git_conventional_commit()
# @security         - Validates git repository
#                   - Checks remote existence
#                   - Safe parameter handling
# @public
# --
git_push() {
  local -r type="${1:-chore}"
  local -r scope="${2:-}"
  local -r description="${3:-update}"
  local -r body="${4:-}"
  local -r footer="${5:-}"
  local -r breaking="${6:-false}"
  local -r branches="${7:-true}"
  local -r branch="${8:-${ROOTINE_GIT_WORKING_BRANCH}}"
  local -r remote="${9:-${ROOTINE_GIT_DEFAULT_REMOTE}}"
  local -r force="${10:-false}"
  local -r verbose="${11:-false}"
  local -r upstream="${12:-true}"
  local -a push_args=()

  _is_git_repo || return 1

  # Check if remote exists
  if ! git remote get-url "${remote}" &>/dev/null; then
    log_error "Remote '${remote}' does not exist"
    return 1
  fi

  # Stage all changes
  if ! git add -A; then
    log_error "Failed to stage changes"
    return 1
  fi

  # Check if there are changes to commit
  if ! git status --porcelain | grep -q .; then
    log_info "No changes to commit"
    return 0
  fi

  # Create conventional commit
  if ! git_conventional_commit \
    "${type}" \
    "${scope}" \
    "${description}" \
    "${body}" \
    "${footer}" \
    "${breaking}"; then
    log_error "Failed to create commit"
    return 1
  fi

  # Build push arguments based on configuration
  if [[ "${branches}" == "true" ]]; then
    push_args+=("--all")
  else
    [[ -n "${branch}" ]] && push_args+=("--branch" "${branch}")
    [[ -n "${remote}" ]] && push_args+=("--remote" "${remote}")
  fi
  [[ "${force}" == "true" ]] && push_args+=("--force")
  [[ "${verbose}" == "true" ]] && push_args+=("--verbose")
  [[ "${upstream}" == "true" ]] && push_args+=("-u")

  # Execute git push operation
  if ! git push "${push_args[@]}"; then
    log_error "Failed to push to ${remote}:${branch} running 'git push ${push_args[*]}'"
    return 1
  fi

  log_success "Changes pushed successfully to '${remote}:${branch}' running 'git push ${push_args[*]}'"
  return 0
}
