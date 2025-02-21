#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [channel]="Repository channel to use:0:${1:-stable}:^(stable|dev)$"
)

declare -gr SUBLIME_KEYRING="/etc/apt/trusted.gpg.d/sublimehq-archive.gpg"
declare -gr SUBLIME_LIST="/etc/apt/sources.list.d/sublime-text.list"
declare -gr SUBLIME_KEY_URL="https://download.sublimetext.com/sublimehq-pub.gpg"

ensure_dependencies() {
  local -a packages=()

  if ! command -v wget >/dev/null 2>&1; then
    packages+=("wget")
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

setup_repository() {
  local channel="${1}"

  log_info "Setting up Sublime HQ repository..."

  if [[ -f "${SUBLIME_KEYRING}" ]]; then
    log_debug "Repository keyring already exists"
    return 0
  fi

  if ! wget -q -O- "${SUBLIME_KEY_URL}" | gpg --dearmor | tee "${SUBLIME_KEYRING}" >/dev/null; then
    log_error "Failed to import Sublime HQ GPG key"
    return 1
  fi

  if [[ ! -f "${SUBLIME_KEYRING}" ]]; then
    log_error "Sublime HQ keyring file not created"
    return 1
  fi

  local repo_line="deb https://download.sublimetext.com/ apt/${channel}/"
  echo "${repo_line}" | tee "${SUBLIME_LIST}" >/dev/null

  if [[ ! -f "${SUBLIME_LIST}" ]]; then
    log_error "Sublime HQ repository list file not created"
    return 1
  fi

  return 0
}

install_sublime_merge() {
  log_info "Installing Sublime Merge..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install sublime-merge; then
    log_error "Failed to install Sublime Merge"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Sublime Merge installation..."

  if ! command -v smerge >/dev/null 2>&1; then
    log_error "Sublime Merge is not available in PATH"
    return 1
  fi

  if ! dpkg -l | grep -q "^ii.*sublime-merge"; then
    log_error "Sublime Merge package is not properly installed"
    return 1
  fi

  local desktop_file="/usr/share/applications/sublime_merge.desktop"

  if [[ ! -f "${desktop_file}" ]]; then
    log_warning "Sublime Merge desktop entry not found"
  else
    log_debug "Desktop entry exists: ${desktop_file}"
  fi

  log_debug "Sublime Merge version: $(smerge --version 2>/dev/null || echo "unknown")"
  return 0
}

main() {
  handle_args "$@"

  local channel="${SCRIPT_ARG_CHANNEL}"

  log_info "Starting Sublime Merge installation..."
  log_debug "Repository channel: ${channel}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! setup_repository "${channel}"; then
    return 1
  fi

  if ! install_sublime_merge; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Sublime Merge installation completed successfully"
  return 0
}

main "$@"
