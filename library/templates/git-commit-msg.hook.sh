#!/usr/bin/env bash

# ---
# @description      Git commit-msg hook for conventional commits validation
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Version Control
# @dependencies     - Bash 5.0.0 or higher
#                   - Git 2.0 or higher
# @param            commit_msg_file Path to temporary file containing commit message
# @exitstatus       0 Commit message is valid
#                   1 Commit message is invalid or error occurred
# @sideeffects      None
# @security         - Uses full paths
#                   - No shell expansions in commit message
#                   - Safe repository root detection
# ---

# Get commit message from temporary file
commit_msg_file="${1}"
commit_msg="$(cat "${commit_msg_file}")"

# Skip validation for merge commits
if [[ "${commit_msg}" =~ ^Merge\ branch ]]; then
  exit 0
fi

# Get repository root path for locating rootine executable
repo_root="$(git rev-parse --show-toplevel)"
if [[ ! -d "${repo_root}" ]]; then
  echo "ERROR: Failed to determine repository root" >&2
  exit 1
fi

# Validate commit message using rootine
if [[ -x "${repo_root}/rootine" ]]; then
  ROOTINE_COMMAND="${repo_root}/rootine"
  if ! "${ROOTINE_COMMAND}" lib::user::git_validate_commit_message "${commit_msg}"; then
    echo "ERROR: Invalid commit message format" >&2
    exit 1
  fi
else
  echo "ERROR: Rootine library not found in ${repo_root}/library" >&2
  exit 1
fi

exit 0
