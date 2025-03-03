#!/usr/bin/env bash

# ---
# @description      Installs Git hooks for:
#                     - Conventional Commits validation
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @dependencies     - Bash 5.0.0 or higher
#                   - Git 2.0 or higher
#                   - library/user/conventional-commits.sh
#                   - library/user/git.sh
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [force]="Force installation (overwrite existing):0:${1:-false}:^(true|false)$"
)

main() {
  handle_args "$@"

  if ! git_install_commit_msg_hook "${ROOTINE_SCRIPT_ARG_FORCE}"; then
    return 1
  fi

  return 0
}

main "$@"
