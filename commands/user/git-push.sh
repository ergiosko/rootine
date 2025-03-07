#!/usr/bin/env bash

# ---
# @description      Script for committing and pushing Git changes using
#                   Conventional Commits standard
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @dependencies     - Bash 5.0.0 or higher
#                   - Git 2.0 or higher
# @configuration    ROOTINE_GIT_WORKING_BRANCH  Working git branch name
#                   ROOTINE_GIT_DEFAULT_REMOTE  Default git remote name
# @envvar           ROOTINE_GIT_WORKING_BRANCH  Working branch for pushing
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
  [remote]="Remote repository:0:${8:-${ROOTINE_GIT_DEFAULT_REMOTE}}:"
  [branch]="Target branch:0:${9:-${ROOTINE_GIT_WORKING_BRANCH}}:"
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

  local type="${ROOTINE_SCRIPT_ARG_TYPE}"
  local scope="${ROOTINE_SCRIPT_ARG_SCOPE:-}"
  local description="${ROOTINE_SCRIPT_ARG_DESCRIPTION}"
  local body="${ROOTINE_SCRIPT_ARG_BODY:-}"
  local footer="${ROOTINE_SCRIPT_ARG_FOOTER:-}"
  local breaking="${ROOTINE_SCRIPT_ARG_BREAKING:-false}"
  local branches="${ROOTINE_SCRIPT_ARG_BRANCHES:-true}"
  local remote="${ROOTINE_SCRIPT_ARG_REMOTE:-${ROOTINE_GIT_DEFAULT_REMOTE}}"
  local branch="${ROOTINE_SCRIPT_ARG_BRANCH:-${ROOTINE_GIT_WORKING_BRANCH}}"
  local force="${ROOTINE_SCRIPT_ARG_FORCE:-false}"
  local verbose="${ROOTINE_SCRIPT_ARG_VERBOSE:-false}"
  local upstream="${ROOTINE_SCRIPT_ARG_UPSTREAM:-true}"
  local -a push_args=()

  push_args+=("${type}" "${scope}" "${description}" "${body}"
    "${footer}" "${breaking}" "${branches}" "${remote}"
    "${branch}" "${force}" "${verbose}" "${upstream}"
  )

  if ! git_push "${push_args[@]}"; then
    return 1
  fi

  return 0
}

main "$@"
