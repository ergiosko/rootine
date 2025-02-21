#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [create-local-config]="Create local jail configuration:0:${1:-true}:^(true|false)$"
  [enable-service]="Enable fail2ban service:0:${2:-true}:^(true|false)$"
)

declare -gr FAIL2BAN_JAIL_CONF="/etc/fail2ban/jail.conf"
declare -gr FAIL2BAN_JAIL_LOCAL="/etc/fail2ban/jail.local"

install_fail2ban() {
  log_info "Installing Fail2Ban..."

  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install fail2ban; then
    log_error "Failed to install Fail2Ban"
    return 1
  fi

  return 0
}

configure_fail2ban() {
  local create_local_config="${1}"

  if [[ "${create_local_config}" != "true" ]]; then
    log_debug "Skipping local configuration creation"
    return 0
  fi

  if [[ -f "${FAIL2BAN_JAIL_LOCAL}" ]]; then
    log_debug "Local configuration already exists"
    return 0
  fi

  log_info "Creating local jail configuration..."

  if ! cp "${FAIL2BAN_JAIL_CONF}" "${FAIL2BAN_JAIL_LOCAL}"; then
    log_error "Failed to create local jail configuration"
    return 1
  fi

  return 0
}

manage_service() {
  local enable_service="${1}"

  if [[ "${enable_service}" == "true" ]]; then
    if ! systemctl is-enabled fail2ban &>/dev/null; then
      log_info "Enabling Fail2Ban service..."

      if ! systemctl enable fail2ban; then
        log_error "Failed to enable Fail2Ban service"
        return 1
      fi
    fi
  fi

  log_info "Restarting Fail2Ban service..."

  if ! systemctl restart fail2ban; then
    log_error "Failed to restart Fail2Ban service"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Fail2Ban installation..."

  if ! command -v fail2ban-client >/dev/null 2>&1; then
    log_error "fail2ban-client not found"
    return 1
  fi

  log_debug "Service status:"
  systemctl --no-pager status fail2ban || true

  log_debug "Fail2Ban client status:"
  fail2ban-client status || true

  if [[ -f "${FAIL2BAN_JAIL_LOCAL}" ]]; then
    log_debug "Local configuration exists at: ${FAIL2BAN_JAIL_LOCAL}"
  fi

  return 0
}

main() {
  handle_args "$@"

  local create_local_config="${SCRIPT_ARG_CREATE_LOCAL_CONFIG}"
  local enable_service="${SCRIPT_ARG_ENABLE_SERVICE}"

  log_info "Starting Fail2Ban installation..."
  log_debug "Create local config: ${create_local_config}"
  log_debug "Enable service: ${enable_service}"

  if ! install_fail2ban; then
    return 1
  fi

  if ! configure_fail2ban "${create_local_config}"; then
    return 1
  fi

  if ! manage_service "${enable_service}"; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Fail2Ban installation completed successfully"
  return 0
}

main "$@"
