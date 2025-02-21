#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=()

declare -gr CHROME_DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
declare -gr CHROME_DEB_FILE="${ROOTINE_TMP_DIR:-/tmp}/google-chrome-stable_current_amd64.deb"

download_chrome() {
  if [[ -f "${CHROME_DEB_FILE}" ]]; then
    log_debug "Removing existing Chrome package file"
    rm -f "${CHROME_DEB_FILE}"
  fi

  log_info "Downloading Google Chrome package..."

  if ! wget -q -O "${CHROME_DEB_FILE}" "${CHROME_DEB_URL}"; then
    log_error "Failed to download Chrome package"
    return 1
  fi

  if [[ ! -f "${CHROME_DEB_FILE}" ]]; then
    log_error "Chrome package file not found after download"
    return 1
  fi

  return 0
}

install_chrome() {
  log_info "Installing Google Chrome..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install "${CHROME_DEB_FILE}"; then
    log_error "Failed to install Chrome package"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Chrome installation..."

  if ! command -v google-chrome-stable &>/dev/null; then
    log_error "Google Chrome is not available in PATH"
    return 1
  fi

  local chrome_version
  chrome_version=$(google-chrome-stable --version 2>/dev/null)
  log_debug "Chrome version: ${chrome_version}"

  return 0
}

main() {
  handle_args "$@"

  log_info "Starting Google Chrome installation..."

  if ! command -v wget &>/dev/null; then
    log_info "Installing wget..."

    if ! apt_get_do install wget; then
      log_error "Failed to install wget"
      return 1
    fi
  fi

  if ! download_chrome; then
    return 1
  fi

  if ! install_chrome; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Google Chrome installation completed successfully"
  return 0
}

main "$@"
