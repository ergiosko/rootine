#!/usr/bin/env bash

# ---
# @description      Command line interface for SSH key generation with secure defaults
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Common Commands
# @dependencies     - Bash 5.0.0 or higher
# @configuration    Arguments:
#                   - file:    Path to SSH key (default: $HOME/.ssh/id_rsa)
#                   - type:    Key type [dsa|ecdsa|ecdsa-sk|ed25519|ed25519-sk|rsa] (default: ed25519)
#                   - bits:    Number of bits for the key (default: 4096)
#                   - comment: Key comment (default: $USER@$HOSTNAME)
# @example          # Generate default ED25519 key
#                   generate-ssh-key.sh
#
#                   # Generate RSA key with custom settings
#                   generate-ssh-key.sh \
#                     --file="/path/to/key" \
#                     --type="rsa" \
#                     --bits=4096 \
#                     --comment="user@host"
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  ["file"]="Path to SSH key:1:${1:-${HOME}/.ssh/id_rsa}:^[a-zA-Z0-9/_.-]+$"
  ["type"]="Key type [dsa|ecdsa|ecdsa-sk|ed25519|ed25519-sk|rsa]:1:${2:-ed25519}:^(dsa|ecdsa|ecdsa-sk|ed25519|ed25519-sk|rsa)$"
  ["bits"]="Number of bits for the key:0:${3:-4096}:^[0-9]+$"
  ["comment"]="Key comment:1:${4:-${USER}@${HOSTNAME}}:^[a-zA-Z0-9@._-]+$"
)

main() {
  handle_args "$@"

  local -r file="${ROOTINE_SCRIPT_ARG_FILE}"
  local -r type="${ROOTINE_SCRIPT_ARG_TYPE}"
  local -r bits="${ROOTINE_SCRIPT_ARG_BITS}"
  local -r comment="${ROOTINE_SCRIPT_ARG_COMMENT}"

  log_info "Generating SSH key..."
  log_debug "Settings:"
  log_debug "- File: ${file}"
  log_debug "- Type: ${type}"
  log_debug "- Bits: ${bits}"
  log_debug "- Comment: ${comment}"

  if ! generate_ssh_key "${file}" "${type}" "${bits}" "${comment}"; then
    return 1
  fi

  log_success "You can now add public key to your GitHub account or other services"
  return 0
}

main "$@"
