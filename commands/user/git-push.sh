#!/usr/bin/env bash

# ---
# @description      Script for committing and pushing Git changes with customizable options
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
# @sideeffects      - Commits staged changes
#                   - Pushes commits to remote repository
#                   - May create upstream tracking references
# @security         - Validates all input parameters
#                   - Uses safe git operations
#                   - Prevents unsafe force pushes by default
# @todo             - Add support for GPG signed commits
#                   - Add dry-run option
#                   - Add support for specific file pushes
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [message]="Commit message:1:${1:-Update}:"
  [branches]="Push all branches:0:${2:-true}:^(true|false)$"
  [branch]="Target branch:1:${3:-ROOTINE_GIT_DEFAULT_BRANCH}:"
  [remote]="Remote repository:1:${4:-ROOTINE_GIT_DEFAULT_REMOTE}:"
  [force]="Force push:0:${5:-false}:^(true|false)$"
  [verbose]="Show verbose output:0:${6:-false}:^(true|false)$"
  [upstream]="Upstream (tracking) reference:0:${7:-true}:^(true|false)$"
)

# --
# @description      Main function that processes arguments and executes git push
# @param            Command line arguments
# @exitstatus       0  Success
#                   1  General error
#                   64 Usage error
# @sideeffects      - Commits and pushes changes to remote
#                   - May create upstream tracking references
# @security         Validates all input parameters before git operations
# @internal
# --
main() {
  handle_args "$@"

  local message="${ROOTINE_SCRIPT_ARG_MESSAGE}"
  local branches="${ROOTINE_SCRIPT_ARG_BRANCHES}"
  local branch="${ROOTINE_SCRIPT_ARG_BRANCH}"
  local remote="${ROOTINE_SCRIPT_ARG_REMOTE}"
  local force="${ROOTINE_SCRIPT_ARG_FORCE}"
  local verbose="${ROOTINE_SCRIPT_ARG_VERBOSE}"
  local upstream="${ROOTINE_SCRIPT_ARG_UPSTREAM}"
  local -a push_args=()

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
  if ! git_push "${message}" "${push_args[@]}"; then
    log_error "Failed to push changes"
    return 1
  fi

  log_success "Changes pushed successfully"
  return 0
}

main "$@"
