#!/usr/bin/env bash

# ---
# @description      Script for cloning Git repositories with advanced options
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @dependencies     - Bash 4.4.0 or higher
#                   - Git 2.0 or higher
# @configuration    None required
# @arguments        repository              Repository URL to clone (required)
#                   [destination]           Target directory (optional)
#                   [--bare]                Create a bare repository
#                   [--depth N]             Create a shallow clone
#                   [--branch NAME]         Clone specific branch
#                   [--single-branch]       Clone only one branch
#                   [--recurse-submodules]  Clone submodules
# @stdout           Clone operation progress
# @stderr           Error messages for invalid URLs or failed operations
# @exitstatus       0  Success
#                   1  General error
#                   64 Usage error (invalid arguments)
# @sideeffects      - Creates new directory structure
#                   - Downloads repository content
#                   - May download submodules
# @security         - Validates repository URL format
#                   - Checks destination directory permissions
#                   - Validates numeric depth value
# @todo             - Add support for SSH key configuration
#                   - Add mirror clone option
#                   - Add progress reporting options
# @note             Destination defaults to repository name if not specified
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [repository]="Repository URL to clone:1:${1:?Repository URL is required}:^(https?|git|ssh)://.+$"
  [destination]="Destination directory:1:${2:-}:"
  [bare]="Create a bare repository:0:${3:-false}:^(true|false)$"
  [depth]="Create a shallow clone with specified depth:1:${4:-}:^[1-9][0-9]*$"
  [branch]="Clone specific branch:1:${5:-}:[[:alnum:]_.-]+$"
  [single-branch]="Clone only one branch:0:${6:-false}:^(true|false)$"
  [recurse-submodules]="Clone submodules:0:${7:-true}:^(true|false)$"
)

# --
# @description      Main function that processes arguments and executes git clone
# @param            Command line arguments
# @exitstatus       0  Success
#                   1  General error
#                   64 Usage error
# @sideeffects      Creates new repository in filesystem
# @security         Validates all input parameters before cloning
# @internal
# --
main() {
  handle_args "$@"

  local repository="${ROOTINE_SCRIPT_ARG_REPOSITORY}"
  local destination="${ROOTINE_SCRIPT_ARG_DESTINATION}"
  local -a clone_args=()

  # Build clone arguments based on configuration
  [[ "${ROOTINE_SCRIPT_ARG_BARE}" == "true" ]] && clone_args+=(--bare)
  if [[ -n "${ROOTINE_SCRIPT_ARG_DEPTH}" ]]; then
    clone_args+=(--depth "${ROOTINE_SCRIPT_ARG_DEPTH}")
  fi
  if [[ -n "${ROOTINE_SCRIPT_ARG_BRANCH}" ]]; then
    clone_args+=(--branch "${ROOTINE_SCRIPT_ARG_BRANCH}")
  fi
  [[ "${ROOTINE_SCRIPT_ARG_SINGLE_BRANCH}" == "true" ]] && clone_args+=(--single-branch)
  [[ "${ROOTINE_SCRIPT_ARG_RECURSE_SUBMODULES}" == "true" ]] && clone_args+=(--recurse-submodules)

  # Execute git clone operation
  if ! git_clone "${repository}" "${destination}" "${clone_args[@]}"; then
    log_error "Failed to clone repository: ${repository}"
    return 1
  fi

  return 0
}

main "$@"
