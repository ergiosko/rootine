#!/usr/bin/env bash

# ---
# @description      Installs Git hooks for repository automation and validation
# @version          1.0.0
# @since            1.0.0
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @category         User Commands
# @public           Intended for use by repository contributors
# @dependencies     Bash 5.0.0 or higher
#                   Git 2.0 or higher
#                   library/user/conventional-commits.sh
#                   library/user/git.sh
# @arguments        [--force] - Pass 'true' to overwrite existing hooks
# @stdin            None
# @stdout           None
# @stderr           Progress messages, error messages
# @return           0 on success, 1 on failure
# @exitstatus       0: Success - Hooks installed successfully
#                   1: Error conditions:
#                     - Script is not sourced
#                     - Invalid arguments
#                     - Failed to install commit-msg hook
# @global           ROOTINE_SCRIPT_ARGS - Associative array of script arguments
# @sideeffects      - Creates/overwrites .git/hooks/commit-msg
#                   - Modifies Git repository configuration
# @usage            rootine git-install-hooks [--force true|false]
# @example          rootine git-install-hooks
#                   rootine git-install-hooks --force true
# @see              library/user/conventional-commits.sh
#                   library/user/git.sh
#                   https://www.conventionalcommits.org/
# @functions        main - Main script execution function
#                   git_install_commit_msg_hook - Installs commit-msg hook
# @security         - Modifies local Git repository configuration only
#                   - No system-wide changes
#                   - Validates input arguments
# @note             Currently only installs the commit-msg hook for
#                   Conventional Commits validation
# @todo             - Add pre-commit hook support
# ---

is_sourced || exit 1

# --
# @description      Defines script-specific argument format and validation rules
# @format           <description>:<requires_value>:<default_value>:<validation_pattern>
#                   Fields:
#                   description         Required  Argument's purpose and usage
#                   requires_value      Required  1 (needs value) or 0 (flag)
#                   default_value       Optional  Default when not provided
#                   validation_pattern  Optional  Regex for value validation
# @validation       Field requirements:
#                   description:
#                     - Must be non-empty
#                     - Must be descriptive
#                     - Should explain purpose clearly
#                   requires_value:
#                     - Must be exactly 0 or 1
#                     - 1: Argument requires value
#                     - 0: Boolean flag
#                   default_value:
#                     - Must match validation_pattern
#                     - Must be valid for argument type
#                   validation_pattern:
#                     - Must be valid regex
#                     - Must enforce value constraints
# @example          # Input file requiring .txt extension
#                   [input]="Input file path:1:input.txt:^[a-zA-Z0-9/_-]+\.txt$"
#
#                   # Boolean flag with true/false validation
#                   [debug]="Enable debug mode:1:false:^(true|false)$"
#
#                   # Simple flag without value
#                   [quiet]="Suppress output:0:false"
# @global           ROOTINE_SCRIPT_ARGS Associative array for argument definitions
# @security         - Values validated against patterns
#                   - Boolean flags strictly enforced
#                   - No shell expansion in validation
#                   - Pattern matching prevents injection
# @see              library/common/arg_parser.sh  Argument parsing functionality
# @internal         Not intended for direct external use
# --
declare -gA ROOTINE_SCRIPT_ARGS=(
  [force]="Force installation (overwrite existing):1:${1:-false}:^(true|false)$"
)

main() {
  handle_args "$@"

  if ! git_install_commit_msg_hook "${ROOTINE_SCRIPT_ARG_FORCE}"; then
    return 1
  fi

  return 0
}

main "$@"
