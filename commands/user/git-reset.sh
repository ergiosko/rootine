#!/usr/bin/env bash

# ---
# @description      Script for resetting Git repository to a specific commit
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @dependencies     - Bash 4.4.0 or higher
#                   - Git 2.0 or higher
# @configuration    None required
# @arguments        [commit] Reference to reset to (commit SHA, branch, or tag)
#                   [--force] Skip confirmation prompt
# @stdout           None
# @stderr           Error messages for invalid commits or failed operations
# @exitstatus       0  Success
#                   1  General error
#                   64 Usage error (invalid arguments)
# @sideeffects      - Resets working directory to specified commit
#                   - Removes all staged changes
#                   - Cleans untracked files
# @security         - Validates commit reference before reset
#                   - Requires confirmation unless --force is used
#                   - Prevents accidental data loss
# @todo             - Add support for soft/mixed reset modes
#                   - Add option to preserve untracked files
#                   - Add backup functionality before reset
# @note             This performs a hard reset which cannot be undone
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [commit]="Commit to reset to:1:${1:-HEAD}:"
  [force]="Force reset without confirmation:0:${2:-false}:^(true|false)$"
)

# --
# @description      Main function that processes arguments and executes git reset
# @param            Command line arguments
# @exitstatus       0  Success
#                   1  General error
#                   64 Usage error
# @sideeffects      Resets repository state to specified commit
# @security         - Validates commit reference
#                   - Requires confirmation for destructive operation
# @internal
# --
main() {
  handle_args "$@"

  local commit="${ROOTINE_SCRIPT_ARG_COMMIT}"
  local force="${ROOTINE_SCRIPT_ARG_FORCE}"

  # Execute git reset operation
  if ! git_reset "${commit}" ${force:+--force}; then
    log_error "Failed to reset to commit: ${commit}"
    return 1
  fi

  log_success "Repository reset to commit: ${commit}"
  return 0
}

main "$@"
