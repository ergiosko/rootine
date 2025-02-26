#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [nvm-version]="nvm version to install:1:${1:-v0.40.1}:^v[0-9]+\.[0-9]+\.[0-9]+$"
  [node-version]="Node.js version to install:1:${2:-22}:^([0-9]+|lts\/[a-zA-Z]+|latest)$"
)

main() {
  handle_args "$@"

  local nvm_version="${SCRIPT_ARG_NVM_VERSION}"
  local node_version="${SCRIPT_ARG_NODE_VERSION}"

  if ! is_command "curl"; then
    return 1
  fi

  log_info "Installing nvm ${nvm_version}..."

  if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash; then
    log_error "Failed to install nvm"
    return 1
  fi

  export NVM_DIR="${HOME}/.nvm"
  [[ -s "${NVM_DIR}/nvm.sh" ]] && \. "${NVM_DIR}/nvm.sh"
  [[ -s "${NVM_DIR}/bash_completion" ]] && \. "${NVM_DIR}/bash_completion"

  if ! is_command "nvm"; then
    log_error "nvm installation failed"
    return 1
  fi

  log_info "Installing Node.js ${node_version}..."

  if ! nvm install "${node_version}"; then
    log_error "Failed to install Node.js"
    return 1
  fi

  log_info "Verifying installation..."
  log_debug "nvm version: $(nvm --version)"
  log_debug "Node.js version: $(node -v)"
  log_debug "npm version: $(npm -v)"
  log_debug "Current Node.js version: $(nvm current)"

  log_success "Installation completed successfully"
  return 0
}

main "$@"
