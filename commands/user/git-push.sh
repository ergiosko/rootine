#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [message]="Commit message:1:${1:-Update}:"
  [branches]="Push all branches:0:${2:-true}:"
  [branch]="Target branch:1:${3:-ROOTINE_GIT_DEFAULT_BRANCH}:"
  [remote]="Remote repository:1:${4:-ROOTINE_GIT_DEFAULT_REMOTE}:"
  [force]="Force push:0:${5:-false}:"
  [verbose]="Show verbose output:0:${6:-false}:"
  [upstream]="Upstream (tracking) reference:0:${7:-true}:"
)

main() {
  handle_args "$@"

  local message="${SCRIPT_ARG_MESSAGE}"
  local branches="${SCRIPT_ARG_BRANCHES}"
  local branch="${SCRIPT_ARG_BRANCH}"
  local remote="${SCRIPT_ARG_REMOTE}"
  local force="${SCRIPT_ARG_FORCE}"
  local verbose="${SCRIPT_ARG_VERBOSE}"
  local upstream="${SCRIPT_ARG_UPSTREAM}"
  local -a push_args=()

  if [[ "${branches}" == "true" ]]; then
    push_args+=("--all")
  else
    [[ -n "${branch}" ]] && push_args+=("--branch" "${branch}")
    [[ -n "${remote}" ]] && push_args+=("--remote" "${remote}")
  fi

  [[ "${force}" == "true" ]] && push_args+=("--force")
  [[ "${verbose}" == "true" ]] && push_args+=("--verbose")
  [[ "${upstream}" == "true" ]] && push_args+=("-u")

  git_push "${message}" "${push_args[@]}"
  return 0
}

main "$@"



