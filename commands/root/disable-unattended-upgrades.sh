#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [verify]="Verify configuration after changes:0:${1:-true}:^(true|false)$"
  [stop-service]="Stop unattended-upgrades service:0:${2:-true}:^(true|false)$"
)

main() {
  handle_args "$@"

  local verify="${ROOTINE_SCRIPT_ARG_VERIFY}"
  local stop_service="${ROOTINE_SCRIPT_ARG_STOP_SERVICE}"
  local apt_config="/etc/apt/apt.conf.d/20auto-upgrades"
  local service_name="unattended-upgrades"

  log_info "Starting unattended upgrades configuration..."

  if [[ -f "${apt_config}" ]]; then
    log_info "Configuring APT periodic settings..."

    local settings=(
      "Update-Package-Lists"
      "Download-Upgradeable-Packages"
      "AutocleanInterval"
      "Unattended-Upgrade"
    )

    for setting in "${settings[@]}"; do
      if ! sed -i "s/APT::Periodic::${setting} \"1\"/APT::Periodic::${setting} \"0\"/g" "${apt_config}"; then
        log_error "Failed to disable ${setting}"
        return 1
      fi
      log_debug "Disabled APT::Periodic::${setting}"
    done
  else
    log_warning "${apt_config} not found"
  fi

  if [[ "${stop_service}" == "true" ]]; then
    log_info "Managing ${service_name} service..."

    if systemctl is-active --quiet "${service_name}"; then
      if ! systemctl stop "${service_name}"; then
        log_error "Failed to stop ${service_name} service"
        return 1
      fi
      log_debug "Stopped ${service_name} service"
    fi

    if systemctl is-enabled --quiet "${service_name}"; then
      if ! systemctl disable "${service_name}"; then
        log_error "Failed to disable ${service_name} service"
        return 1
      fi
      log_debug "Disabled ${service_name} service"
    fi
  fi

  if [[ "${verify}" == "true" ]]; then
    log_info "Verifying configuration..."
    log_debug "APT Periodic settings:"
    apt-config dump | grep -E "APT::Periodic::(Update-Package-Lists|Download-Upgradeable-Packages|AutocleanInterval|Unattended-Upgrade)" || true
    log_debug "Service status:"
    systemctl is-enabled "${service_name}" || true
    systemctl is-active "${service_name}" || true
  fi

  log_success "Unattended upgrades configuration completed successfully"
  return 0
}

main "$@"
