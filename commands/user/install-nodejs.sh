#!/usr/bin/env bash

# ---
# @description      Installs and configures Node.js development environment using nvm
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Commands
# @dependencies     - Bash 4.4.0 or higher
#                   - curl
#                   - Internet connectivity
#                   - Write access to $HOME/.nvm
# @configuration    NVM_DIR environment variable is set to $HOME/.nvm
# @arguments        [nvm-version]   Version of nvm to install (e.g., v0.40.1)
#                   [node-version]  Version of Node.js to install (e.g., 22, lts/*)
# @envvar           NVM_DIR Installation directory for nvm
# @stdin            None
# @stdout           Installation progress and version information
# @stderr           Error messages and installation failures
# @exitstatus       0  Success
#                   1  Installation or dependency error (ROOTINE_STATUS_CANTCREAT)
#                   64 Usage error (ROOTINE_STATUS_USAGE)
#                   66 Input error (ROOTINE_STATUS_NOINPUT)
# @sideeffects      - Creates $HOME/.nvm directory
#                   - Modifies shell initialization files
#                   - Downloads and installs nvm, Node.js, and npm
# @security         - Validates version numbers
#                   - Uses HTTPS for downloads
#                   - Verifies installations
# @example          # Install with default versions (nvm v0.40.1, Node.js 22)
#                   rootine install-nodejs
#
#                   # Install specific versions
#                   rootine install-nodejs v0.39.3 18
#
#                   # Install LTS version
#                   rootine install-nodejs v0.40.1 "lts/*"
# @todo             - Add checksum verification for downloads
#                   - Add offline installation support
#                   - Add system-wide installation option
#                   - Add support for custom npm global packages
# @note             nvm is installed per-user, not system-wide
# ---

is_sourced || exit 1

# Define script arguments with validation patterns
declare -gA ROOTINE_SCRIPT_ARGS=(
  [nvm-version]="nvm version to install:1:${1:-v0.40.1}:^v[0-9]+\.[0-9]+\.[0-9]+$"
  [node-version]="Node.js version to install:1:${2:-22}:^([0-9]+|lts\/[a-zA-Z]+|latest)$"
)

# --
# @description      Main function handling nvm and Node.js installation
# @param            Command line arguments processed by handle_args
# @exitstatus       0  Success
#                   1  Installation failure
#                   64 Usage error
#                   66 Input error
# @sideeffects      - Downloads and installs software
#                   - Creates directories and files
# @security         Validates dependencies and installation results
# @internal
# --
main() {
  handle_args "$@"

  local -r nvm_version="${ROOTINE_SCRIPT_ARG_NVM_VERSION}"
  local -r node_version="${ROOTINE_SCRIPT_ARG_NODE_VERSION}"

  # Verify curl availability
  if ! command -v curl >/dev/null; then
    log_error "Required command 'curl' not found"
    log_info "Install using: sudo apt-get install curl"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  # Install nvm
  log_info "Installing nvm ${nvm_version}..."
  if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash; then
    log_error "Failed to install nvm"
    return "${ROOTINE_STATUS_CANTCREAT}"
  fi

  # Configure nvm environment
  declare -gx NVM_DIR="${HOME}/.nvm"
  if [[ ! -s "${NVM_DIR}/nvm.sh" ]]; then
    log_error "nvm installation files not found"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi

  # Load nvm into current shell
  # shellcheck source=/dev/null
  source "${NVM_DIR}/nvm.sh"
  # shellcheck source=/dev/null
  [[ -s "${NVM_DIR}/bash_completion" ]] && source "${NVM_DIR}/bash_completion"

  # Verify nvm installation
  if ! command -v nvm >/dev/null; then
    log_error "nvm command not found after installation"
    return "${ROOTINE_STATUS_CANTCREAT}"
  fi

  # Install Node.js
  log_info "Installing Node.js ${node_version}..."
  if ! nvm install "${node_version}"; then
    log_error "Failed to install Node.js ${node_version}"
    return "${ROOTINE_STATUS_CANTCREAT}"
  fi

  # Verify all component versions
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
