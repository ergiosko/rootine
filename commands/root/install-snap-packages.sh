#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [packages]="Comma-separated list of packages to install:0:${1:-}:^[a-zA-Z0-9,._-]+$"
  [retries]="Number of installation retries:0:${2:-ROOTINE_SNAP_REFRESH_RETRIES}:^[1-9][0-9]*$"
  [delay]="Delay between retries in seconds:0:${3:-ROOTINE_SNAP_REFRESH_DELAY}:^[1-9][0-9]*$"
)

declare -ga DEFAULT_ROOTINE_SNAP_PACKAGES=(
  "certbot"
  "firefox"
  "htop"
  "skype"
  "telegram-desktop"
  "tmpwatcher"
  "vlc"
)

ensure_dependencies() {
  if ! command -v snap >/dev/null 2>&1; then
    log_info "Installing snapd..."

    if ! apt_get_do update || ! apt_get_do install snapd; then
      log_error "Failed to install snapd"
      return 1
    fi
  fi

  return 0
}

parse_packages() {
  local packages_arg="${1}"
  local -a package_list=()

  if [[ -n "${packages_arg}" ]]; then
    IFS=',' read -ra package_list <<< "${packages_arg}"
    log_debug "Using user-specified packages: ${package_list[*]}"
  else
    package_list=("${DEFAULT_ROOTINE_SNAP_PACKAGES[@]}")
    log_debug "Using default package list: ${package_list[*]}"
  fi

  printf '%s\n' "${package_list[@]}"
}

install_packages() {
  local -a packages=("$@")
  local -i retries="${ROOTINE_SCRIPT_ARG_RETRIES}"
  local -i delay="${ROOTINE_SCRIPT_ARG_DELAY}"
  local -i attempt=1
  local package

  for package in "${packages[@]}"; do
    attempt=1

    while ((attempt <= retries)); do
      log_info "Installing ${package} (attempt ${attempt}/${retries})..."

      if snap install "${package}"; then
        log_success "${package} installed successfully"
        break
      fi

      if ((attempt == retries)); then
        log_error "Failed to install ${package} after ${retries} attempts"
        return 1
      fi

      log_info "Waiting ${delay} seconds before retry..."
      sleep "${delay}"

      ((attempt+=1))
    done
  done

  return 0
}

verify_installation() {
  local -a packages=("$@")
  local -i status=0
  local package

  log_info "Verifying snap package installations..."

  for package in "${packages[@]}"; do
    if ! snap list | grep -q "^${package}"; then
      log_error "Package ${package} is not properly installed"
      ((status+=1))
    else
      local version
      version=$(snap list "${package}" | awk 'NR==2{print $2}')
      log_debug "${package} version: ${version}"
    fi
  done

  return "${status}"
}

main() {
  handle_args "$@"

  local packages_arg="${ROOTINE_SCRIPT_ARG_PACKAGES}"
  local -a packages

  log_info "Starting snap packages installation..."

  if ! ensure_dependencies; then
    return 1
  fi

  if ! snap_stop; then
    log_warning "Failed to stop snap store, continuing anyway..."
  fi

  if ! snap_refresh; then
    log_error "Failed to refresh snap packages"
    return 1
  fi

  mapfile -t packages < <(parse_packages "${packages_arg}")

  if ! install_packages "${packages[@]}"; then
    return 1
  fi

  if ! verify_installation "${packages[@]}"; then
    return 1
  fi

  log_success "Snap packages installation completed successfully"
  return 0
}

main "$@"
