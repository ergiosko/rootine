#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [enable-service]="Enable and start SSH service:0:${1:-true}:^(true|false)$"
  [verify-config]="Verify SSH configuration:0:${2:-true}:^(true|false)$"
)

install_openssh() {
  log_info "Installing OpenSSH server..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install "openssh-server"; then
    log_error "Failed to install OpenSSH server"
    return 1
  fi

  return 0
}

manage_service() {
  local enable_service="${1}"

  if [[ "${enable_service}" != "true" ]]; then
    log_debug "Skipping service management"
    return 0
  fi

  if ! systemctl is-enabled ssh &>/dev/null; then
    log_info "Enabling SSH service..."

    if ! systemctl enable ssh; then
      log_error "Failed to enable SSH service"
      return 1
    fi
  fi

  if ! systemctl is-active ssh &>/dev/null; then
    log_info "Starting SSH service..."

    if ! systemctl start ssh; then
      log_error "Failed to start SSH service"
      return 1
    fi
  fi

  return 0
}

verify_installation() {
  local verify_config="${1}"
  local -i status=0

  log_info "Verifying OpenSSH installation..."

  if ! command -v sshd >/dev/null 2>&1; then
    log_error "OpenSSH server not found"
    return 1
  fi

  log_debug "SSH version: $(sshd -V 2>&1)"
  log_debug "Service status: $(systemctl is-active ssh)"
  log_debug "Service enabled: $(systemctl is-enabled ssh)"

  if [[ "${verify_config}" == "true" ]]; then
    log_info "Verifying SSH configuration..."

    if ! sshd -t; then
      log_error "SSH configuration test failed"
      ((status+=1))
    fi
  fi

  if ((status > 0)); then
    return 1
  fi

  return 0
}

main() {
  handle_args "$@"

  local enable_service="${SCRIPT_ARG_ENABLE_SERVICE}"
  local verify_config="${SCRIPT_ARG_VERIFY_CONFIG}"

  log_info "Starting OpenSSH server installation..."
  log_debug "Enable service: ${enable_service}"
  log_debug "Verify config: ${verify_config}"

  if ! install_openssh; then
    return 1
  fi

  if ! manage_service "${enable_service}"; then
    return 1
  fi

  if ! verify_installation "${verify_config}"; then
    return 1
  fi

  log_success "OpenSSH server installation completed successfully"
  return 0
}

main "$@"
