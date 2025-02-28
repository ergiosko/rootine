#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [url]="Viber download URL:0:${1:-https://download.cdn.viber.com/cdn/desktop/Linux/viber.deb}:^https?://[a-zA-Z0-9.-]+/.*\.deb$"
)

declare -gr VIBER_DEB_FILE="${ROOTINE_TMP_DIR:-/tmp}/viber.deb"

ensure_dependencies() {
  if ! command -v wget >/dev/null 2>&1; then
    log_info "Installing wget..."

    if ! apt_get_do install wget; then
      log_error "Failed to install wget"
      return 1
    fi
  fi

  return 0
}

download_viber() {
  local url="${1}"

  if [[ -f "${VIBER_DEB_FILE}" ]]; then
    log_debug "Removing existing Viber package file"
    rm -f "${VIBER_DEB_FILE}"
  fi

  log_info "Downloading Viber package..."

  if ! wget -q -O "${VIBER_DEB_FILE}" "${url}"; then
    log_error "Failed to download Viber package"
    return 1
  fi

  if [[ ! -f "${VIBER_DEB_FILE}" ]]; then
    log_error "Viber package file not found after download"
    return 1
  fi

  return 0
}

install_viber() {
  log_info "Installing Viber..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install "${VIBER_DEB_FILE}"; then
    log_error "Failed to install Viber package"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Viber installation..."

  if ! command -v viber >/dev/null 2>&1; then
    log_error "Viber is not available in PATH"
    return 1
  fi

  if ! dpkg -l | grep -q "^ii.*viber"; then
    log_error "Viber package is not properly installed"
    return 1
  fi

  local desktop_file="/usr/share/applications/viber.desktop"

  if [[ ! -f "${desktop_file}" ]]; then
    log_warning "Viber desktop entry not found"
  else
    log_debug "Desktop entry exists: ${desktop_file}"
  fi

  return 0
}

main() {
  handle_args "$@"

  local url="${ROOTINE_SCRIPT_ARG_URL}"

  log_info "Starting Viber installation..."
  log_debug "Download URL: ${url}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! download_viber "${url}"; then
    return 1
  fi

  if ! install_viber; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Viber installation completed successfully"
  return 0
}

main "$@"
