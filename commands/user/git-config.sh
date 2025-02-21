#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [config-scope]="Configuration scope (local, global, or system):1:${1:-global}:^(local|global|system)$"
  [show-only]="Show configuration without making changes:0:false:"
)

main() {
  handle_args "$@"

  local config_scope="${SCRIPT_ARG_CONFIG_SCOPE}"
  local show_only="${SCRIPT_ARG_SHOW_ONLY:-false}"

  git_config "${config_scope}" ${show_only:+--show-only}
  return 0
}

main "$@"
