#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [php-version]="PHP version to install:1:${1:-8.4}:^[0-9]+\.[0-9]+$"
  [use-libbrotli]="Use system libbrotli:0:${2:-false}:^(true|false)$"
  [extension-dir]="Directory for PHP Brotli extension:0:${3:-/opt/php-ext-brotli}:^/[a-zA-Z0-9/_-]+$"
)

install_dependencies() {
  local php_version="${1}"
  local packages=(
    "git"
    "brotli"
    "php${php_version}-dev"
  )

  if ! apt_get_do update; then
    log_error "Failed to update package lists"
    return 1
  fi

  if ! apt_get_do install "${packages[@]}"; then
    log_error "Failed to install required packages"
    return 1
  fi

  return 0
}

clone_extension() {
  local extension_dir="${1}"

  if [[ -d "${extension_dir}" ]]; then
    log_debug "Extension directory already exists: ${extension_dir}"
    return 0
  fi

  if ! git clone --depth=1 --recurse-submodules \
    "https://github.com/kjdev/php-ext-brotli.git" "${extension_dir}"; then
    log_error "Failed to clone PHP Brotli extension"
    return 1
  fi

  return 0
}

build_extension() {
  local extension_dir="${1}"
  local use_libbrotli="${2}"
  local configure_options=()

  if [[ "${use_libbrotli}" == "true" ]]; then
    configure_options+=("--with-libbrotli")
  fi

  if ! cd "${extension_dir}"; then
    log_error "Failed to change directory to ${extension_dir}"
    return 1
  fi

  if ! phpize; then
    log_error "Failed to run phpize"
    return 1
  fi

  if ! ./configure "${configure_options[@]}"; then
    log_error "Failed to configure extension"
    return 1
  fi

  if ! make; then
    log_error "Failed to build extension"
    return 1
  fi

  if ! make install; then
    log_error "Failed to install extension"
    return 1
  fi

  return 0
}

verify_installation() {
  local extension_dir="${1}"

  if ! php -m | grep -q "brotli"; then
    log_warning "Brotli extension not loaded in PHP"
    return 1
  fi

  log_debug "Extension build directory: ${extension_dir}"
  log_debug "PHP modules:"
  php -m | grep -i "brotli" || true

  return 0
}

main() {
  handle_args "$@"

  local php_version="${SCRIPT_ARG_PHP_VERSION}"
  local use_libbrotli="${SCRIPT_ARG_USE_LIBBROTLI}"
  local extension_dir="${SCRIPT_ARG_EXTENSION_DIR}"

  log_info "Starting Brotli installation..."
  log_debug "PHP version: ${php_version}"
  log_debug "Use libbrotli: ${use_libbrotli}"
  log_debug "Extension directory: ${extension_dir}"

  if ! install_dependencies "${php_version}"; then
    return 1
  fi

  if ! clone_extension "${extension_dir}"; then
    return 1
  fi

  if ! build_extension "${extension_dir}" "${use_libbrotli}"; then
    return 1
  fi

  if ! verify_installation "${extension_dir}"; then
    return 1
  fi

  log_success "Brotli installation completed successfully"
  return 0
}

main "$@"
