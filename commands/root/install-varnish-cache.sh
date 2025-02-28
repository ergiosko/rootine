#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [version]="Varnish version to install:0:${1:-76}:^[0-9]+$"
  [start-service]="Start Varnish service after installation:0:${2:-true}:^(true|false)$"
)

declare -gr VARNISH_KEYRING_NAME="varnishcache_varnish.gpg"
declare -gr VARNISH_LIST_NAME="varnishcache_varnish.list"
declare -gr VARNISH_GPG_URL="https://packagecloud.io/varnishcache/varnish"

ensure_dependencies() {
  local -a packages=()

  if ! command -v curl >/dev/null 2>&1; then
    packages+=("curl")
  fi

  if ! command -v gpg >/dev/null 2>&1; then
    packages+=("gnupg")
  fi

  if ((${#packages[@]} > 0)); then
    log_info "Installing required packages: ${packages[*]}"

    if ! apt_get_do update || ! apt_get_do install "${packages[@]}"; then
      log_error "Failed to install dependencies"
      return 1
    fi
  fi

  return 0
}

setup_repository() {
  local version="${1}"
  local keyring_path="${ROOTINE_APT_KEYRINGS_DIR}/${VARNISH_KEYRING_NAME}"
  local list_path="${ROOTINE_APT_SOURCES_LIST_DIR}/${VARNISH_LIST_NAME}"

  log_info "Setting up Varnish Cache repository..."

  if ! curl -fsSL "${VARNISH_GPG_URL}${version}/gpgkey" | gpg --dearmor > "${keyring_path}"; then
    log_error "Failed to import Varnish GPG key"
    return 1
  fi

  if [[ ! -f "${keyring_path}" ]]; then
    log_error "Varnish keyring file not created"
    return 1
  fi

  cat > "${list_path}" <<EOF
deb [signed-by=${keyring_path}] https://packagecloud.io/varnishcache/varnish${version}/ubuntu ${ROOTINE_UBUNTU_CODENAME} main
deb-src [signed-by=${keyring_path}] https://packagecloud.io/varnishcache/varnish${version}/ubuntu ${ROOTINE_UBUNTU_CODENAME} main
EOF

  if [[ ! -f "${list_path}" ]]; then
    log_error "Varnish repository list file not created"
    return 1
  fi

  return 0
}

install_varnish() {
  log_info "Installing Varnish Cache..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install varnish; then
    log_error "Failed to install Varnish"
    return 1
  fi

  return 0
}

configure_service() {
  local start_service="${1}"

  if [[ "${start_service}" != "true" ]]; then
    log_debug "Skipping service configuration"
    return 0
  fi

  if ! systemctl is-enabled varnish &>/dev/null; then
    log_info "Enabling Varnish service..."

    if ! systemctl enable varnish; then
      log_error "Failed to enable Varnish service"
      return 1
    fi
  fi

  if ! systemctl is-active varnish &>/dev/null; then
    log_info "Starting Varnish service..."

    if ! systemctl start varnish; then
      log_error "Failed to start Varnish service"
      return 1
    fi
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Varnish installation..."

  if ! command -v varnishd >/dev/null 2>&1; then
    log_error "Varnish daemon is not available in PATH"
    return 1
  fi

  if ! dpkg -l | grep -q "^ii.*varnish"; then
    log_error "Varnish package is not properly installed"
    return 1
  fi

  local version
  version=$(varnishd -V 2>&1 | head -n1)
  log_debug "Varnish version: ${version}"
  log_debug "Service status: $(systemctl is-active varnish)"
  log_debug "Service enabled: $(systemctl is-enabled varnish)"

  return 0
}

main() {
  handle_args "$@"

  local version="${ROOTINE_SCRIPT_ARG_VERSION}"
  local start_service="${ROOTINE_SCRIPT_ARG_START_SERVICE}"

  log_info "Starting Varnish Cache installation..."
  log_debug "Version: ${version}"
  log_debug "Start service: ${start_service}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! setup_repository "${version}"; then
    return 1
  fi

  if ! install_varnish; then
    return 1
  fi

  if ! configure_service "${start_service}"; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Varnish Cache installation completed successfully"
  return 0
}

main "$@"
