#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [commit]="Commit to reset to:1:${1:-HEAD}:"
  [force]="Force reset without confirmation:0:false:^(true|false)$"
)

main() {
  handle_args "$@"

  local commit="${SCRIPT_ARG_COMMIT}"
  local force="${SCRIPT_ARG_FORCE}"

  git_reset "${commit}" ${force:+--force}
  return 0
}

main "$@"
