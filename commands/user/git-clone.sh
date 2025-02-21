#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [repository]="Repository URL to clone:1:${1:?Repository URL is required}:^.+$"
  [destination]="Destination directory:1:${2:-}:"
  [bare]="Create a bare repository:0:false:"
  [depth]="Create a shallow clone with specified depth:1::"
  [branch]="Clone specific branch:1::"
  [single-branch]="Clone only one branch:0:false:"
  [recurse-submodules]="Clone submodules:0:true:"
)

main() {
  handle_args "$@"

  local repository="${SCRIPT_ARG_REPOSITORY}"
  local destination="${SCRIPT_ARG_DESTINATION}"
  local -a clone_args=()

  [[ "${SCRIPT_ARG_BARE}" == "true" ]] && clone_args+=(--bare)
  [[ -n "${SCRIPT_ARG_DEPTH}" ]] && clone_args+=(--depth "${SCRIPT_ARG_DEPTH}")
  [[ -n "${SCRIPT_ARG_BRANCH}" ]] && clone_args+=(--branch "${SCRIPT_ARG_BRANCH}")
  [[ "${SCRIPT_ARG_SINGLE_BRANCH}" == "true" ]] && clone_args+=(--single-branch)
  [[ "${SCRIPT_ARG_RECURSE_SUBMODULES}" == "true" ]] && clone_args+=(--recurse-submodules)

  git_clone "${repository}" "${destination}" "${clone_args[@]}"
  return 0
}

main "$@"
