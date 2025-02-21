#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [arch]="Architecture to install:0:${1:-amd64}:^(amd64|arm64)$"
  [codename]="Repository codename:0:${2:-xenial}:^[a-zA-Z0-9]+$"
)

declare -gr SIGNAL_KEYRING="/usr/share/keyrings/signal-desktop-keyring.gpg"
declare -gr SIGNAL_LIST="/etc/apt/sources.list.d/signal-xenial.list"
declare -gr SIGNAL_KEY_URL="https://updates.signal.org/desktop/apt/keys.asc"

ensure_dependencies() {
  local -a packages=()

  if ! command -v wget >/dev/null 2>&1; then
    packages+=("wget")
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
  local arch="${1}"
  local codename="${2}"

  log_info "Setting up Signal repository..."

  if ! wget -q -O- "${SIGNAL_KEY_URL}" | gpg --dearmor | tee "${SIGNAL_KEYRING}" >/dev/null; then
    log_error "Failed to import Signal GPG key"
    return 1
  fi

  if [[ ! -f "${SIGNAL_KEYRING}" ]]; then
    log_error "Signal keyring file not created"
    return 1
  fi

  local repo_line="deb [arch=${arch} signed-by=${SIGNAL_KEYRING}] https://updates.signal.org/desktop/apt ${codename} main"
  echo "${repo_line}" | tee "${SIGNAL_LIST}" >/dev/null

  if [[ ! -f "${SIGNAL_LIST}" ]]; then
    log_error "Signal repository list file not created"
    return 1
  fi

  return 0
}

install_signal() {
  log_info "Installing Signal..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install "signal-desktop"; then
    log_error "Failed to install Signal"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Signal installation..."

  if ! command -v signal-desktop >/dev/null 2>&1; then
    log_error "Signal is not available in PATH"
    return 1
  fi

  if ! dpkg -l | grep -q "^ii.*signal-desktop"; then
    log_error "Signal package is not properly installed"
    return 1
  fi

  local desktop_file="/usr/share/applications/signal-desktop.desktop"

  if [[ ! -f "${desktop_file}" ]]; then
    log_warning "Signal desktop entry not found"
  else
    log_debug "Desktop entry exists: ${desktop_file}"
  fi

  log_debug "Signal version: $(signal-desktop --version 2>/dev/null || echo "${ROOTINE_UNKNOWN}")"
  return 0
}

main() {
  handle_args "$@"

  local arch="${SCRIPT_ARG_ARCH}"
  local codename="${SCRIPT_ARG_CODENAME}"

  log_info "Starting Signal installation..."
  log_debug "Architecture: ${arch}"
  log_debug "Repository codename: ${codename}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! setup_repository "${arch}" "${codename}"; then
    return 1
  fi

  if ! install_signal; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Signal installation completed successfully"
  return 0
}

main "$@"
