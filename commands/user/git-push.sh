#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [message]="Commit message:1:${1:-Update}:"
  [force]="Force push:0:${2:-false}:"
  [verbose]="Show verbose output:0:false:"
  [branch]="Target branch:1:${ROOTINE_GIT_DEFAULT_BRANCH}:"
  [remote]="Remote repository:1:${ROOTINE_GIT_DEFAULT_REMOTE}:"
)

main() {
  handle_args "$@"

  local message="${SCRIPT_ARG_MESSAGE}"
  local force="${SCRIPT_ARG_FORCE}"
  local verbose="${SCRIPT_ARG_VERBOSE}"
  local branch="${SCRIPT_ARG_BRANCH}"
  local remote="${SCRIPT_ARG_REMOTE}"

  local -a push_args=()
  [[ "${force}" == "true" ]] && push_args+=(--force)
  [[ "${verbose}" == "true" ]] && push_args+=(--verbose)
  [[ -n "${branch}" ]] && push_args+=(--branch "${branch}")
  [[ -n "${remote}" ]] && push_args+=(--remote "${remote}")

  git_push "${message}" "${push_args[@]}"
  return 0
}

main "$@"
