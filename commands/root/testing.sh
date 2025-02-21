#!/usr/bin/env bash

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
