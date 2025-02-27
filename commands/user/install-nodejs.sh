#!/usr/bin/env bash

# ---
# @description      Installs nvm (Node Version Manager), Node.js and npm
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @param            $1 nvm_version  Version of nvm to install (default: v0.40.1)
# @param            $2 node_version Version of Node.js to install (default: 22)
# @stdout           Version information for installed components
# @stderr           Status and error messages
# @exitstatus       0 Success
#                   1 Installation or dependency error
#                   2 Invalid parameters
# @dependencies     curl, bash
# @example          # Install with default versions
#                   rootine install-nodejs
#
#                   # Install specific versions
#                   rootine install-nodejs v0.39.3 18
# @public
# ---

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [nvm-version]="nvm version to install:1:${1:-v0.40.1}:^v[0-9]+\.[0-9]+\.[0-9]+$"
  [node-version]="Node.js version to install:1:${2:-22}:^([0-9]+|lts\/[a-zA-Z]+|latest)$"
)

main() {
  handle_args "$@"

  local -r nvm_version="${SCRIPT_ARG_NVM_VERSION}"
  local -r node_version="${SCRIPT_ARG_NODE_VERSION}"

  if ! command -v curl >/dev/null; then
    log_error "Required command 'curl' not found"
    log_info "Install using: sudo apt-get install curl"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  log_info "Installing nvm ${nvm_version}..."
  if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash; then
    log_error "Failed to install nvm"
    return "${ROOTINE_STATUS_CANTCREAT}"
  fi

  declare -gx NVM_DIR="${HOME}/.nvm"
  if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    log_error "nvm installation files not found"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi

  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"
  # shellcheck source=/dev/null
  [[ -s "${NVM_DIR}/bash_completion" ]] && source "${NVM_DIR}/bash_completion"

  if ! command -v nvm >/dev/null; then
    log_error "nvm command not found after installation"
    return "${ROOTINE_STATUS_CANTCREAT}"
  fi

  log_info "Installing Node.js ${node_version}..."
  if ! nvm install "${node_version}"; then
    log_error "Failed to install Node.js ${node_version}"
    return "${ROOTINE_STATUS_CANTCREAT}"
  fi

  log_info "Verifying installation..."
  local nvm_installed_version
  if ! nvm_installed_version=$(nvm --version); then
    log_error "Failed to get nvm version"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi
  log_debug "nvm version: ${nvm_installed_version}"

  local node_installed_version
  if ! node_installed_version=$(node -v); then
    log_error "Failed to get Node.js version"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi
  log_debug "Node.js version: ${node_installed_version}"

  local npm_version
  if ! npm_version=$(npm -v); then
    log_error "Failed to get npm version"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi
  log_debug "npm version: ${npm_version}"

  local current_node
  if ! current_node=$(nvm current); then
    log_error "Failed to get current Node.js version"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi
  log_debug "Current Node.js version: ${current_node}"

  log_success "Installation completed successfully"
  return 0
}

main "$@"
