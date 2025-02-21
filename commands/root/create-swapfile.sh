#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [swap-size]="Swap size in GB:1:${1:-4}:^[0-9]+$"
  [swappiness]="VM swappiness value:0:${2:-10}:^[0-9]+$"
  [cache-pressure]="VFS cache pressure:0:${3:-50}:^[0-9]+$"
)

main() {
  handle_args "$@"

  local swap_size="${SCRIPT_ARG_SWAP_SIZE}"
  local swappiness="${SCRIPT_ARG_SWAPPINESS}"
  local cache_pressure="${SCRIPT_ARG_CACHE_PRESSURE}"
  local swapfile="/mnt/swapfile"

  if [[ -f "${swapfile}" ]]; then
    log_info "Swap file already exists at ${swapfile}"
    return 0
  fi

  log_info "Creating ${swap_size}GB swap file..."

  if ! fallocate -l "${swap_size}G" "${swapfile}"; then
    log_error "Failed to create swap file"
    return 1
  fi

  chmod 0600 "${swapfile}"

  if ! mkswap "${swapfile}"; then
    log_error "Failed to format swap file"
    return 1
  fi

  if ! swapon "${swapfile}"; then
    log_error "Failed to activate swap file"
    return 1
  fi

  if ! grep -q "${swapfile} none swap sw 0 0" /etc/fstab; then
    echo "${swapfile} none swap sw 0 0" >> /etc/fstab
  fi

  sysctl "vm.swappiness=${swappiness}"
  sysctl "vm.vfs_cache_pressure=${cache_pressure}"

  sed -i '/vm.swappiness=/d' /etc/sysctl.conf
  sed -i '/vm.vfs_cache_pressure=/d' /etc/sysctl.conf
  {
    echo "vm.swappiness=${swappiness}"
    echo "vm.vfs_cache_pressure=${cache_pressure}"
  } >> /etc/sysctl.conf

  if ! sysctl -p; then
    log_error "Failed to apply kernel parameters"
    return 1
  fi

  log_info "Verifying swap setup..."
  log_debug "Swap file: ${swapfile}"
  log_debug "Swap size: ${swap_size}GB"
  log_debug "VM swappiness: ${swappiness}"
  log_debug "VFS cache pressure: ${cache_pressure}"

  log_success "Swap setup completed successfully"
  return 0
}

main "$@"
