#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [install-dir]="Installation directory:0:${1:-/usr/local/bin}:^/[a-zA-Z0-9/_-]+$"
  [create-symlink]="Create Python symlink if needed:0:${2:-true}:^(true|false)$"
)

declare -gr PS_MEM_URL="https://raw.githubusercontent.com/pixelb/ps_mem/refs/heads/master/ps_mem.py"

ensure_dependencies() {
  local -a packages=()

  if ! command -v wget >/dev/null 2>&1; then
    packages+=("wget")
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    packages+=("python3")
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

setup_python_symlink() {
  local create_symlink="${1}"

  if [[ "${create_symlink}" != "true" ]]; then
    log_debug "Skipping Python symlink creation"
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    log_debug "Python symlink already exists"
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    log_error "Python3 not found, cannot create symlink"
    return 1
  fi

  log_info "Creating Python symlink..."

  if ! ln -sf "$(command -v python3)" /usr/bin/python; then
    log_error "Failed to create Python symlink"
    return 1
  fi

  return 0
}

install_ps_mem() {
  local install_dir="${1}"

  if [[ ! -d "${install_dir}" ]]; then
    if ! mkdir -p "${install_dir}"; then
      log_error "Failed to create installation directory: ${install_dir}"
      return 1
    fi
  fi

  log_info "Downloading ps_mem..."

  if ! wget -q -O "${install_dir}/ps_mem" "${PS_MEM_URL}"; then
    log_error "Failed to download ps_mem"
    return 1
  fi

  if ! chmod 0700 "${install_dir}/ps_mem"; then
    log_error "Failed to make ps_mem executable"
    return 1
  fi

  return 0
}

verify_installation() {
  local install_dir="${1}"

  log_info "Verifying ps_mem installation..."

  if [[ ! -x "${install_dir}/ps_mem" ]]; then
    log_error "ps_mem is not executable"
    return 1
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    log_error "Python3 is not available"
    return 1
  fi

  local version
  version=$("${install_dir}/ps_mem" --version 2>&1) || version="${ROOTINE_UNKNOWN}"

  log_debug "ps_mem version: ${version}"
  log_debug "Installation directory: ${install_dir}"
  log_debug "Python version: $(python3 --version 2>&1)"

  return 0
}

main() {
  handle_args "$@"

  local install_dir="${SCRIPT_ARG_INSTALL_DIR}"
  local create_symlink="${SCRIPT_ARG_CREATE_SYMLINK}"

  log_info "Starting ps_mem installation..."
  log_debug "Installation directory: ${install_dir}"
  log_debug "Create Python symlink: ${create_symlink}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! setup_python_symlink "${create_symlink}"; then
    return 1
  fi

  if ! install_ps_mem "${install_dir}"; then
    return 1
  fi

  if ! verify_installation "${install_dir}"; then
    return 1
  fi

  log_success "ps_mem installation completed successfully"
  return 0
}

main "$@"
