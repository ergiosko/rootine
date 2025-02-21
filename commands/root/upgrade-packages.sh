#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [upgrade-type]="Type of upgrade to perform:0:${1:-safe}:^(full|safe)$"
  [autoremove]="Remove unused packages:0:${2:-true}:^(true|false)$"
  [clean]="Clean package cache after upgrade:0:${3:-true}:^(true|false)$"
)

check_system_state() {
  log_info "Checking system state..."

  if ! check_internet_connection; then
    log_error "No internet connection available"
    return "${ROOTINE_STATUS_NETWORK_UNREACHABLE}"
  fi

  local space
  space=$(df -h / | awk 'NR==2 {print $4}')
  log_debug "Available disk space: ${space}"

  if [[ $(df / | awk 'NR==2 {print $4}') -lt 1048576 ]]; then
    log_error "Insufficient disk space (less than 1GB available)"
    return 1
  fi

  return 0
}

upgrade_snap_packages() {
  log_info "Starting snap package updates..."

  if ! command -v snap >/dev/null 2>&1; then
    log_debug "Snap is not installed, skipping snap updates"
    return 0
  fi

  if ! snap_stop; then
    log_warning "Failed to stop snap store, continuing anyway..."
  fi

  if ! snap_refresh; then
    log_error "Failed to refresh snap packages"
    return 1
  fi

  return 0
}

upgrade_apt_packages() {
  local upgrade_type="${1}"
  local -i status=0

  log_info "Starting APT package updates..."

  if ! apt_get_do update; then
    return 1
  fi

  case "${upgrade_type}" in
    full)
      if ! apt_get_do "dist-upgrade"; then
        log_error "Full system upgrade failed"
        ((status+=1))
      fi
      ;;
    safe)
      if ! apt_get_do "upgrade"; then
        log_error "Safe system upgrade failed"
        ((status+=1))
      fi
      ;;
  esac

  return "${status}"
}

cleanup_packages() {
  local autoremove="${1}"
  local clean="${2}"
  local -i status=0

  if [[ "${autoremove}" == "true" ]]; then
    log_info "Removing unused packages..."

    if ! apt_get_do autoremove; then
      log_error "Failed to remove unused packages"
      ((status+=1))
    fi
  fi

  if [[ "${clean}" == "true" ]]; then
    log_info "Cleaning package cache..."

    if ! apt_get_do clean; then
      log_error "Failed to clean package cache"
      ((status+=1))
    fi
  fi

  return "${status}"
}

verify_system_state() {
  log_info "Verifying system state..."

  if dpkg --audit 2>/dev/null | grep -q .; then
    log_error "Found package inconsistencies"
    return 1
  fi

  if dpkg --configure -a 2>/dev/null | grep -q .; then
    log_error "Found unconfigured packages"
    return 1
  fi

  log_debug "Package system is consistent"
  return 0
}

main() {
  handle_args "$@"

  local upgrade_type="${SCRIPT_ARG_UPGRADE_TYPE}"
  local autoremove="${SCRIPT_ARG_AUTOREMOVE}"
  local clean="${SCRIPT_ARG_CLEAN}"

  log_info "Starting system package updates..."
  log_debug "Upgrade type: ${upgrade_type}"
  log_debug "Clean cache: ${clean}"
  log_debug "Autoremove: ${autoremove}"

  if ! check_system_state; then
    return 1
  fi

  if ! upgrade_snap_packages; then
    log_warning "Snap package updates failed, continuing with APT updates"
  fi

  if ! upgrade_apt_packages "${upgrade_type}"; then
    return 1
  fi

  if ! cleanup_packages "${autoremove}" "${clean}"; then
    return 1
  fi

  if ! verify_system_state; then
    return 1
  fi

  log_success "System package updates completed successfully"
  return 0
}

main "$@"
