#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [repository]="Repository URL to clone:1:${1:?Repository URL is required}:^.+$"
  [destination]="Destination directory:1:${2:-}:"
  [bare]="Create a bare repository:0:false:^(true|false)$"
  [depth]="Create a shallow clone with specified depth:1::"
  [branch]="Clone specific branch:1::"
  [single-branch]="Clone only one branch:0:false:^(true|false)$"
  [recurse-submodules]="Clone submodules:0:true:^(true|false)$"
)

main() {
  handle_args "$@"

  local repository="${ROOTINE_SCRIPT_ARG_REPOSITORY}"
  local destination="${ROOTINE_SCRIPT_ARG_DESTINATION}"
  local -a clone_args=()

  [[ "${ROOTINE_SCRIPT_ARG_BARE}" == "true" ]] && clone_args+=(--bare)
  [[ -n "${ROOTINE_SCRIPT_ARG_DEPTH}" ]] && clone_args+=(--depth "${ROOTINE_SCRIPT_ARG_DEPTH}")
  [[ -n "${ROOTINE_SCRIPT_ARG_BRANCH}" ]] && clone_args+=(--branch "${ROOTINE_SCRIPT_ARG_BRANCH}")
  [[ "${ROOTINE_SCRIPT_ARG_SINGLE_BRANCH}" == "true" ]] && clone_args+=(--single-branch)
  [[ "${ROOTINE_SCRIPT_ARG_RECURSE_SUBMODULES}" == "true" ]] && clone_args+=(--recurse-submodules)

  git_clone "${repository}" "${destination}" "${clone_args[@]}"
  return 0
}

main "$@"
