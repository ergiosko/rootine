#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [url]="Zoom download URL:0:${1:-https://www.zoom.us/client/latest/zoom_amd64.deb}:^https?://[a-zA-Z0-9.-]+/.*\.deb$"
)

declare -gr ZOOM_DEB_FILE="${ROOTINE_TMP_DIR:-/tmp}/zoom_amd64.deb"

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

download_zoom() {
  local url="${1}"

  if [[ -f "${ZOOM_DEB_FILE}" ]]; then
    log_debug "Removing existing Zoom package file"
    rm -f "${ZOOM_DEB_FILE}"
  fi

  log_info "Downloading Zoom package..."

  if ! wget -q -O "${ZOOM_DEB_FILE}" "${url}"; then
    log_error "Failed to download Zoom package"
    return 1
  fi

  if [[ ! -f "${ZOOM_DEB_FILE}" ]]; then
    log_error "Zoom package file not found after download"
    return 1
  fi

  return 0
}

install_zoom() {
  log_info "Installing Zoom..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install "${ZOOM_DEB_FILE}"; then
    log_error "Failed to install Zoom package"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Zoom installation..."

  if ! command -v zoom >/dev/null 2>&1; then
    log_error "Zoom is not available in PATH"
    return 1
  fi

  local zoom_version
  zoom_version=$(zoom --version 2>/dev/null || echo "unknown")
  log_debug "Zoom version: ${zoom_version}"

  if ! dpkg -l | grep -q "^ii.*zoom"; then
    log_error "Zoom package is not properly installed"
    return 1
  fi

  return 0
}

main() {
  handle_args "$@"

  local url="${SCRIPT_ARG_URL}"

  log_info "Starting Zoom installation..."
  log_debug "Download URL: ${url}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! download_zoom "${url}"; then
    return 1
  fi

  if ! install_zoom; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Zoom installation completed successfully"
  return 0
}

main "$@"
