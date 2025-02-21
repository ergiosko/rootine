#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [restart-xrdp]="Restart XRDP service after installation:0:${1:-true}:^(true|false)$"
)

declare -ga DEFAULT_ROOTINE_APT_PACKAGES=(
  "apt-transport-https"
  "coreutils"
  "curl"
  "dbus-x11"
  "gdebi"
  "gnupg"
  "usb-creator-gtk"
)

install_packages() {
  local -a packages=("${@}")

  if ! apt_get_do update; then
    log_error "Failed to update package lists"
    return 1
  fi

  if ! apt_get_do install "${packages[@]}"; then
    log_error "Failed to install packages: ${packages[*]}"
    return 1
  fi

  return 0
}

handle_xrdp_restart() {
  if ! systemctl is-active --quiet xrdp; then
    log_debug "XRDP service is not active, skipping restart"
    return 0
  fi

  log_info "Restarting XRDP service..."
  if ! systemctl restart xrdp; then
    log_error "Failed to restart XRDP service"
    return 1
  fi

  log_debug "XRDP service restarted successfully"
  return 0
}

main() {
  handle_args "$@"

  local restart_xrdp="${SCRIPT_ARG_RESTART_XRDP}"
  local -a packages=("${DEFAULT_ROOTINE_APT_PACKAGES[@]}")

  log_info "Starting package installation..."
  log_debug "Packages to install: ${packages[*]}"

  if ! install_packages "${packages[@]}"; then
    return 1
  fi

  if [[ "${restart_xrdp}" == "true" ]]; then
    if ! handle_xrdp_restart; then
      return 1
    fi
  fi

  log_info "Verifying installation..."

  for pkg in "${packages[@]}"; do
    if dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -q "ok installed"; then
      log_debug "Package '${pkg}' installed successfully"
    else
      log_warning "Package '${pkg}' installation status uncertain"
    fi
  done

  log_success "Package installation completed successfully"
  return 0
}

main "$@"
