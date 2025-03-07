#!/usr/bin/env bash

# ---
# @description      Installs Git hooks for:
#                   - Conventional Commits validation
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @dependencies     - Bash 5.0.0 or higher
#                   - Git 2.0 or higher
#                   - library/user/conventional-commits.sh
#                   - library/user/git.sh
# @example          rootine git-install-hooks [--force true|false]
# ---

is_sourced || exit 1

# --
# Essential Documentation
# @description      Defines script-specific argument format and validation rules
#
# Data Format and Validation
# @format           <description>:<requires_value>:<default_value>:<validation_pattern>
#                   Fields:
#                   description         Required  Argument's purpose and usage
#                   requires_value      Required  1 (needs value) or 0 (flag)
#                   default_value       Optional  Default when not provided
#                   validation_pattern  Optional  Regex for value validation
#
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
#
# Input/Output Examples
# @example          # Input file requiring .txt extension
#                   [input]="Input file path:1:input.txt:^[a-zA-Z0-9/_-]+\.txt$"
#
#                   # Boolean flag with true/false validation
#                   [debug]="Enable debug mode:1:false:^(true|false)$"
#
#                   # Simple flag without value
#                   [quiet]="Suppress output:0:false"
#
# Dependencies and Environment
# @global           ROOTINE_SCRIPT_ARGS Associative array for argument definitions
#
# Security Considerations
# @security         - Values validated against patterns
#                   - Boolean flags strictly enforced
#                   - No shell expansion in validation
#                   - Pattern matching prevents injection
#
# References
# @see              library/common/arg_parser.sh  Argument parsing functionality
#
# Documentation Control
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
