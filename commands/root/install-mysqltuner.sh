#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [install-dir]="Installation directory:0:${1:-/opt/mysqltuner}:^/[a-zA-Z0-9/_-]+$"
  [branch]="MySQLTuner branch to install:0:${2:-master}:^[a-zA-Z0-9_.-]+$"
)

declare -gr MYSQLTUNER_GITHUB_BASE_URL="https://raw.githubusercontent.com/major/MySQLTuner-perl/refs/heads"
declare -ga MYSQLTUNER_REQUIRED_FILES=(
  "mysqltuner.pl"
  "basic_passwords.txt"
  "vulnerabilities.csv"
)

ensure_dependencies() {
  if ! command -v wget >/dev/null 2>&1; then
    log_info "Installing wget..."

    if ! apt_get_do install wget; then
      log_error "Failed to install wget"
      return 1
    fi
  fi

  if ! command -v perl >/dev/null 2>&1; then
    log_info "Installing perl..."

    if ! apt_get_do install perl; then
      log_error "Failed to install perl"
      return 1
    fi
  fi

  return 0
}

create_install_dir() {
  local install_dir="${1}"

  if [[ -d "${install_dir}" ]]; then
    log_debug "Installation directory already exists"
    return 0
  fi

  log_info "Creating installation directory..."

  if ! mkdir -p "${install_dir}"; then
    log_error "Failed to create installation directory: ${install_dir}"
    return 1
  fi

  return 0
}

download_files() {
  local install_dir="${1}"
  local branch="${2}"
  local -i status=0

  if ! cd "${install_dir}"; then
    log_error "Failed to change directory to ${install_dir}"
    return 1
  fi

  for file in "${MYSQLTUNER_REQUIRED_FILES[@]}"; do
    log_debug "Downloading ${file}..."

    if ! wget -q "${MYSQLTUNER_GITHUB_BASE_URL}/${branch}/${file}" -O "${file}"; then
      log_error "Failed to download ${file}"
      ((status+=1))
      continue
    fi
  done

  if ((status > 0)); then
    return 1
  fi

  if ! chmod +x "${install_dir}/mysqltuner.pl"; then
    log_error "Failed to make mysqltuner.pl executable"
    return 1
  fi

  return 0
}

verify_installation() {
  local install_dir="${1}"
  local -i status=0

  log_info "Verifying installation..."

  for file in "${MYSQLTUNER_REQUIRED_FILES[@]}"; do
    if [[ ! -f "${install_dir}/${file}" ]]; then
      log_error "Required file missing: ${file}"
      ((status+=1))
      continue
    fi
    log_debug "Found required file: ${file}"
  done

  if ((status > 0)); then
    return 1
  fi

  if ! "${install_dir}/mysqltuner.pl" --help >/dev/null 2>&1; then
    log_error "MySQLTuner is not working properly"
    return 1
  fi

  log_debug "Installation directory: ${install_dir}"
  log_debug "MySQLTuner version: $(head -n1 "${install_dir}/mysqltuner.pl" | grep -o 'v[0-9.]*' || echo "${ROOTINE_UNKNOWN}")"

  return 0
}

main() {
  handle_args "$@"

  local install_dir="${SCRIPT_ARG_INSTALL_DIR}"
  local branch="${SCRIPT_ARG_BRANCH}"

  log_info "Starting MySQLTuner installation..."
  log_debug "Installation directory: ${install_dir}"
  log_debug "Branch: ${branch}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! create_install_dir "${install_dir}"; then
    return 1
  fi

  if ! download_files "${install_dir}" "${branch}"; then
    return 1
  fi

  if ! verify_installation "${install_dir}"; then
    return 1
  fi

  log_success "MySQLTuner installation completed successfully"
  return 0
}

main "$@"
