#!/usr/bin/env bash

# ---
# @description      Command line interface for SSH key generation with secure defaults
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Common Commands
# @dependencies     - Bash 4.4.0 or higher
#                   - ssh-keygen (openssh-client)
#                   - chmod
#                   - mkdir
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

  local -r file="${SCRIPT_ARG_FILE}"
  local -r type="${SCRIPT_ARG_TYPE}"
  local -r bits="${SCRIPT_ARG_BITS}"
  local -r comment="${SCRIPT_ARG_COMMENT}"

  # Verify openssh-client is installed
  if ! is_package_installed "openssh-client"; then
    log_error "Required package 'openssh-client' is not installed"
    log_info "Install using: sudo apt-get install openssh-client"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  # Check if key file already exists
  if [[ -f "${file}" ]]; then
    log_error "SSH key already exists: ${file}"
    log_info "Please choose a different path or remove the existing key"
    return "${ROOTINE_STATUS_DATAERR}"
  fi

  # Generate the SSH key
  log_info "Generating SSH key..."
  log_debug "Settings:"
  log_debug "- File: ${file}"
  log_debug "- Type: ${type}"
  log_debug "- Bits: ${bits}"
  log_debug "- Comment: ${comment}"

  if ! generate_ssh_key "${file}" "${type}" "${bits}" "${comment}"; then
    log_error "Failed to generate SSH key"
    return "${ROOTINE_STATUS_CANTCREAT}"
  fi

  # Display public key location
  log_info "Your public key is available at: ${file}.pub"
  log_info "You can now add it to your GitHub account or other services"
  return 0
}

main "$@"
