#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [version]="Python version to install:0:${1:-3.13}:^[0-9]+\.[0-9]+$"
  [interactive]="Configure alternatives interactively:0:${2:-true}:^(true|false)$"
  [set-default]="Set as default Python version:0:${3:-false}:^(true|false)$"
)

declare -gr PYTHON_PACKAGES=(
  "dev"
  "venv"
  "pip"
  "doc"
  "distutils"
)

ensure_dependencies() {
  if ! command -v software-properties-common >/dev/null 2>&1; then
    log_info "Installing required dependencies..."

    if ! apt_get_do install software-properties-common; then
      log_error "Failed to install dependencies"
      return 1
    fi
  fi

  return 0
}

setup_repository() {
  log_info "Setting up Python repository..."

  if ! add_apt_repository "ppa:deadsnakes/ppa"; then
    log_error "Failed to add Python repository"
    return 1
  fi

  return 0
}

get_python_version() {
  local cmd="${1}"
  local executable
  local version_output

  executable=$(command -v "${cmd}")

  if [[ -z "${executable}" ]]; then
    return 1
  fi

  version_output=$("${executable}" --version 2>&1)

  if [[ "${version_output}" =~ Python[[:space:]]([0-9]+\.[0-9]+) ]]; then
    printf "%s" "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

install_python() {
  local version="${1}"
  local -a packages=("python${version}")

  log_info "Installing Python ${version}..."

  for pkg in "${PYTHON_PACKAGES[@]}"; do
    packages+=("python${version}-${pkg}")
  done

  if ! apt_get_do install "${packages[@]}"; then
    log_error "Failed to install Python packages"
    return 1
  fi

  return 0
}

configure_alternatives() {
  local version="${1}"
  local interactive="${2}"
  local set_default="${3}"
  local -i priority=1

  log_info "Configuring Python alternatives..."

  local current_version
  current_version=$(get_python_version python3 || echo "3.8")

  local -a cmds=(
    "update-alternatives --install /usr/bin/python python /usr/bin/python${version} ${priority}"
    "update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${version} ${priority}"
    "update-alternatives --install /usr/bin/python${version%%.*} python${version%%.*} /usr/bin/python${version} ${priority}"
  )

  for cmd in "${cmds[@]}"; do
    if ! eval "${cmd}"; then
      log_error "Failed to configure alternative: ${cmd}"
      return 1
    fi
  done

  if [[ "${set_default}" == "true" ]]; then
    local -a set_cmds=(
      "update-alternatives --set python /usr/bin/python${version}"
      "update-alternatives --set python3 /usr/bin/python${version}"
    )

    for cmd in "${set_cmds[@]}"; do
      if ! eval "${cmd}"; then
        log_error "Failed to set default: ${cmd}"
        return 1
      fi
    done
  elif [[ "${interactive}" == "true" ]]; then
    update-alternatives --config python
    update-alternatives --config python3
  fi

  return 0
}

verify_installation() {
  local version="${1}"
  local -i status=0

  log_info "Verifying Python installation..."

  if ! command -v "python${version}" >/dev/null 2>&1; then
    log_error "Python ${version} binary not found"
    ((status+=1))
  fi

  local installed_version
  installed_version=$(get_python_version "python${version}")

  if [[ "${installed_version}" != "${version}" ]]; then
    log_error "Installed version (${installed_version}) does not match requested version (${version})"
    ((status+=1))
  fi

  log_debug "Python version: $(python"${version}" --version 2>&1)"
  log_debug "Python path: $(command -v python"${version}")"
  log_debug "Current alternatives:"
  update-alternatives --display python || true
  update-alternatives --display python3 || true

  return "${status}"
}

main() {
  handle_args "$@"

  local version="${ROOTINE_SCRIPT_ARG_VERSION}"
  local interactive="${ROOTINE_SCRIPT_ARG_INTERACTIVE}"
  local set_default="${ROOTINE_SCRIPT_ARG_SET_DEFAULT}"

  log_info "Starting Python ${version} installation..."
  log_debug "Interactive configuration: ${interactive}"
  log_debug "Set as default: ${set_default}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! setup_repository; then
    return 1
  fi

  if ! install_python "${version}"; then
    return 1
  fi

  if ! configure_alternatives "${version}" "${interactive}" "${set_default}"; then
    return 1
  fi

  if ! verify_installation "${version}"; then
    return 1
  fi

  log_success "Python ${version} installation completed successfully"
  return 0
}

main "$@"
