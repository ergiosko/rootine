#!/usr/bin/env bash

# ---
# @description      Manages Git configuration with scope control and display options
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Common Commands
# @dependencies     - Bash 5.0.0 or higher
#                   - git (git-core package)
# @configuration    Arguments:
#                     - scope:      Configuration scope [global|system|local|worktree]
#                     - show-only:  Display settings without modifications [true|false]
# @envvar           GIT_CONFIG  Path to git config file (optional)
# @stdout           Git configuration settings when show-only is true
# @stderr           Status and error messages
# @exitstatus       0 Success
#                   1 General error
#                   2 Invalid arguments or missing dependencies
# @example          # Configure git for local repository
#                   rootine git-config --scope=local
#
#                   # Show global git configuration
#                   rootine git-config --scope=global --show-only=true
#
#                   # Configure system-wide git settings (requires sudo)
#                   rootine git-config --scope=system
# @security         - Validates scope parameter
#                   - Requires appropriate permissions for system scope
#                   - Safe handling of configuration values
# @note             The show-only option allows viewing without modifying settings
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [scope]="Configuration scope (global, system, local, worktree):1:${1:-local}:^(global|system|local|worktree)$"
  [show-only]="Show configuration without making changes:0:false:^(true|false)$"
)

main() {
  handle_args "$@"

  local scope="${ROOTINE_SCRIPT_ARG_SCOPE}"
  local show_only="${ROOTINE_SCRIPT_ARG_SHOW_ONLY:-false}"

  git_config "${scope}" ${show_only:+--show-only}
  return 0
}

main "$@"
