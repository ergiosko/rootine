#!/usr/bin/env bash

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
