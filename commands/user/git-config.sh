#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [config-scope]="Configuration scope (global, local, worktree):1:${1:-local}:^(global|local|worktree)$"
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
