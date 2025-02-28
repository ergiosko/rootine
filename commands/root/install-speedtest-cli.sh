#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [remove-old]="Remove old speedtest installations:0:${1:-true}:^(true|false)$"
)

declare -gr SPEEDTEST_KEYRING="/etc/apt/trusted.gpg.d/speedtest.gpg"
declare -gr SPEEDTEST_LIST="/etc/apt/sources.list.d/speedtest.list"
declare -gr SPEEDTEST_SCRIPT_URL="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"

ensure_dependencies() {
  local -a packages=()

  if ! command -v curl >/dev/null 2>&1; then
    packages+=("curl")
  fi

  if ! command -v gpg >/dev/null 2>&1; then
    packages+=("gnupg")
  fi

  packages+=("apt-transport-https")

  if ((${#packages[@]} > 0)); then
    log_info "Installing required packages: ${packages[*]}"

    if ! apt_get_do update || ! apt_get_do install "${packages[@]}"; then
      log_error "Failed to install dependencies"
      return 1
    fi
  fi

  return 0
}

remove_old_installations() {
  local remove_old="${1}"

  if [[ "${remove_old}" != "true" ]]; then
    return 0
  fi

  log_info "Checking for old speedtest installations..."

  if [[ -f "/etc/apt/sources.list.d/speedtest.list" ]]; then
    log_info "Removing old speedtest repository..."
    rm -f "/etc/apt/sources.list.d/speedtest.list"
  fi

  if dpkg -l | grep -q "speedtest-cli"; then
    log_info "Removing old speedtest-cli package..."

    if ! apt_get_do remove speedtest-cli; then
      log_error "Failed to remove old speedtest-cli package"
      return 1
    fi
  fi

  return 0
}

setup_repository() {
  log_info "Setting up Speedtest CLI repository..."

  if ! curl -s "${SPEEDTEST_SCRIPT_URL}" | bash; then
    log_error "Failed to setup Speedtest CLI repository"
    return 1
  fi

  if [[ ! -f "${SPEEDTEST_LIST}" ]]; then
    log_error "Speedtest repository list file not created"
    return 1
  fi

  return 0
}

install_speedtest() {
  log_info "Installing Speedtest CLI..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install speedtest; then
    log_error "Failed to install Speedtest CLI"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Speedtest CLI installation..."

  if ! command -v speedtest >/dev/null 2>&1; then
    log_error "Speedtest CLI is not available in PATH"
    return 1
  fi

  if ! dpkg -l | grep -q "^ii.*speedtest"; then
    log_error "Speedtest package is not properly installed"
    return 1
  fi

  local version
  version=$(speedtest --version 2>/dev/null || echo "unknown")
  log_debug "Speedtest CLI version: ${version}"

  return 0
}

main() {
  handle_args "$@"

  local remove_old="${ROOTINE_SCRIPT_ARG_REMOVE_OLD}"

  log_info "Starting Speedtest CLI installation..."
  log_debug "Remove old installations: ${remove_old}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! remove_old_installations "${remove_old}"; then
    return 1
  fi

  if ! setup_repository; then
    return 1
  fi

  if ! install_speedtest; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Speedtest CLI installation completed successfully"
  return 0
}

main "$@"
