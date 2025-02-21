#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [version]="MariaDB version to install:1:${1:-11.4.4}:^[0-9]+\.[0-9]+\.[0-9]+$"
)

declare -gr MARIADB_BASE_URL="https://dlm.mariadb.com"
declare -gr EXTRACT_DIR="/opt"

download_package() {
  local version="${1}"
  local package_url
  local tar_file

  package_url="${MARIADB_BASE_URL}/3959235/MariaDB/mariadb-${version}/repo/ubuntu/mariadb-${version}-ubuntu-${ROOTINE_UBUNTU_CODENAME}-amd64-debs.tar"
  tar_file="${ROOTINE_TMP_DIR}/mariadb-${version}.tar"

  log_info "Downloading MariaDB ${version} package..."

  if ! wget -q -nc -O "${tar_file}" "${package_url}"; then
    log_error "Failed to download MariaDB package"
    return 1
  fi

  echo "${tar_file}"
  return 0
}

extract_package() {
  local tar_file="${1}"

  if ! cd "${EXTRACT_DIR}"; then
    log_error "Failed to change directory to ${EXTRACT_DIR}"
    return 1
  fi

  if ! tar -xf "${tar_file}"; then
    log_error "Failed to extract MariaDB package"
    return 1
  fi

  return 0
}

setup_repository() {
  local version="${1}"
  local setup_script

  setup_script="${EXTRACT_DIR}/mariadb-${version}-ubuntu-${ROOTINE_UBUNTU_CODENAME}-amd64-debs/setup_repository"

  if [[ ! -f "${setup_script}" ]]; then
    log_error "Repository setup script not found"
    return 1
  fi

  if ! "${setup_script}"; then
    log_error "Failed to setup MariaDB repository"
    return 1
  fi

  return 0
}

install_server() {
  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install "mariadb-server"; then
    log_error "Failed to install MariaDB server"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying MariaDB installation..."

  if ! command -v mariadb >/dev/null 2>&1; then
    log_error "MariaDB client not found"
    return 1
  fi

  if ! systemctl is-active --quiet mariadb; then
    log_error "MariaDB service is not running"
    return 1
  fi

  local version_info
  version_info=$(mariadb --version 2>/dev/null)
  log_debug "MariaDB version: ${version_info}"

  return 0
}

main() {
  handle_args "$@"

  local version="${SCRIPT_ARG_VERSION}"

  log_info "Starting MariaDB installation..."
  log_debug "Version: ${version}"

  local tar_file
  tar_file=$(download_package "${version}") || return 1

  if ! extract_package "${tar_file}"; then
    return 1
  fi

  if ! setup_repository "${version}"; then
    return 1
  fi

  if ! install_server; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "MariaDB installation completed successfully"
  return 0
}

main "$@"
