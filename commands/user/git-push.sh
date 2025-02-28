#!/usr/bin/env bash

# ---
# @description      Script for committing and pushing Git changes using Conventional Commits
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @dependencies     - Bash 4.4.0 or higher
#                   - Git 2.0 or higher
# @configuration    ROOTINE_GIT_DEFAULT_BRANCH  Default git branch name
#                   ROOTINE_GIT_DEFAULT_REMOTE  Default git remote name
# @envvar           ROOTINE_GIT_DEFAULT_BRANCH  Default branch for pushing
#                   ROOTINE_GIT_DEFAULT_REMOTE  Default remote repository
# @stderr           Error messages for invalid arguments and git operations
# @exitstatus       0  Success
#                   1  General error
#                   64 Usage error (invalid arguments)
# @sideeffects      - Creates conventional commit
#                   - Pushes commits to remote repository
#                   - May create upstream tracking references
# @security         - Validates all input parameters
#                   - Validates commit message format
#                   - Uses safe git operations
#                   - Prevents unsafe force pushes by default
# @todo             - Add support for GPG signed commits
#                   - Add dry-run option
#                   - Add support for specific file pushes
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [type]="Commit type (feat, fix, etc.):1:${1:-}:^($(IFS=\|; echo "${ROOTINE_COMMIT_TYPES[*]}"))"
  [scope]="Commit scope:0:${2:-}:^($(IFS=\|; echo "${ROOTINE_COMMIT_SCOPES[*]}"))?$"
  [description]="Commit description:1:${3:-}:^[a-z].*$"
  [body]="Commit body (optional):0:${4:-}:"
  [footer]="Commit footer (optional):0:${5:-}:"
  [breaking]="Mark as breaking change:0:${6:-false}:^(true|false)$"
  [branches]="Push all branches:0:${7:-true}:^(true|false)$"
  [branch]="Target branch:0:${8:-${ROOTINE_GIT_DEFAULT_BRANCH}}:"
  [remote]="Remote repository:0:${9:-${ROOTINE_GIT_DEFAULT_REMOTE}}:"
  [force]="Force push:0:${10:-false}:^(true|false)$"
  [verbose]="Show verbose output:0:${11:-false}:^(true|false)$"
  [upstream]="Upstream (tracking) reference:0:${12:-true}:^(true|false)$"
)

# --
# @description      Main function that processes arguments and executes
#                   conventional commit and push
# @param            Command line arguments
# @exitstatus       0  Success
#                   1  General error
#                   64 Usage error
# @sideeffects      - Creates conventional commit
#                   - Pushes changes to remote
# @security         Validates all input parameters before operations
# @internal
# --
main() {
  handle_args "$@"

  # Use parameter expansion to provide default empty values for optional arguments
  local type="${ROOTINE_SCRIPT_ARG_TYPE}"
  local scope="${ROOTINE_SCRIPT_ARG_SCOPE:-}"
  local description="${ROOTINE_SCRIPT_ARG_DESCRIPTION}"
  local body="${ROOTINE_SCRIPT_ARG_BODY:-}"
  local footer="${ROOTINE_SCRIPT_ARG_FOOTER:-}"
  local breaking="${ROOTINE_SCRIPT_ARG_BREAKING:-false}"
  local branches="${ROOTINE_SCRIPT_ARG_BRANCHES:-true}"
  local branch="${ROOTINE_SCRIPT_ARG_BRANCH:-${ROOTINE_GIT_DEFAULT_BRANCH}}"
  local remote="${ROOTINE_SCRIPT_ARG_REMOTE:-${ROOTINE_GIT_DEFAULT_REMOTE}}"
  local force="${ROOTINE_SCRIPT_ARG_FORCE:-false}"
  local verbose="${ROOTINE_SCRIPT_ARG_VERBOSE:-false}"
  local upstream="${ROOTINE_SCRIPT_ARG_UPSTREAM:-true}"
  local -a push_args=()

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

main "$@"
