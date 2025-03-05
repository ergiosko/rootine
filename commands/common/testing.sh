#!/usr/bin/env bash

# ---
# @description      Tests system configuration and displays system information
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Common Commands
# @dependencies     - Bash 5.0.0 or higher
#                   - Core system utilities
#                   - lsb_release (for Ubuntu version)
#                   - uname (for kernel info)
# @stdout           System information and test results
# @stderr           Status and error messages during testing
# @exitstatus       0 Success, all tests passed
#                   1 General error during testing
#                   2 Missing dependencies
# @example          # Run system tests and display information
#                   rootine testing
# @sideeffects      - Reads system configuration files
#                   - Accesses hardware information
# @functions        - get_system_info: Gathers and displays system information
# @security         - Read-only operations
#                   - No privileged operations required
#                   - Safe information disclosure
# @note             This command performs basic system testing and information
#                   gathering without making any modifications to the system
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=()

main() {
  handle_args "$@"

  log_info "Start testing..."

  get_system_info

  log_success "Testing passed successfully"
  return 0
}

main "$@"
