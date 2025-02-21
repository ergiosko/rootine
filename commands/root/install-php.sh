#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [version]="PHP version to install:0:${1:-8.4}:^[0-9]+\.[0-9]+$"
  [dev]="Install development packages:0:${2:-false}:^(true|false)$"
  [disable-others]="Disable other PHP versions:0:${3:-true}:^(true|false)$"
)

declare -gr PHP_MODULES=(
  "fpm" "apcu" "bcmath" "bz2" "cli" "common" "curl" "gd" "imagick"
  "imap" "intl" "mbstring" "mysql" "opcache" "readline" "soap"
  "sqlite3" "ssh2" "tidy" "xml" "yaml" "zip"
)

ensure_dependencies() {
  if ! command -v apache2 >/dev/null 2>&1; then
    log_info "Installing Apache2..."

    if ! apt_get_do install apache2; then
      log_error "Failed to install Apache2"
      return 1
    fi
  fi

  return 0
}

setup_repository() {
  log_info "Setting up PHP repository..."

  if ! add_apt_repository "ppa:ondrej/php"; then
    log_error "Failed to add PHP repository"
    return 1
  fi

  return 0
}

get_available_versions() {
  log_info "Getting available PHP versions..."
  local -a versions

  mapfile -t versions < <(apt-cache search php | grep -oP '^php\d\.\d(?=-)' | sort -u)
  printf '%s\n' "${versions[@]}"
}

install_php_modules() {
  local version="${1}"
  local dev="${2}"
  local -a packages=()

  log_info "Installing PHP ${version} and modules..."

  for module in "${PHP_MODULES[@]}"; do
    packages+=("php${version}-${module}")
  done

  if [[ "${dev}" == "true" ]]; then
    packages+=("php${version}-dev")
  fi

  if ! apt_get_do install "${packages[@]}"; then
    log_error "Failed to install PHP packages"
    return 1
  fi

  return 0
}

disable_php_versions() {
  local current_version="${1}"
  local disable_others="${2}"
  local -i status=0

  if [[ "${disable_others}" != "true" ]]; then
    return 0
  fi

  log_info "Disabling other PHP versions..."

  local -a installed_versions
  mapfile -t installed_versions < <(find /etc/php/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

  for version in "${installed_versions[@]}"; do
    if [[ "${version}" == "${current_version}" ]]; then
      continue
    fi

    local fpm_service="php${version}-fpm"

    if systemctl is-enabled "${fpm_service}" &>/dev/null; then
      log_info "Disabling ${fpm_service}..."

      a2disconf "${fpm_service}" || ((status+=1))

      systemctl stop "${fpm_service}" || ((status+=1))
      systemctl disable "${fpm_service}" || ((status+=1))
      systemctl mask "${fpm_service}" || ((status+=1))
    fi
  done

  return "${status}"
}

configure_php() {
  local version="${1}"
  local -i status=0

  log_info "Configuring PHP ${version}..."

  if ! a2enconf "php${version}-fpm"; then
    log_error "Failed to enable PHP-FPM configuration"
    ((status+=1))
  fi

  if ! systemctl restart "apache2" "php${version}-fpm"; then
    log_error "Failed to restart services"
    ((status+=1))
  fi

  return "${status}"
}

verify_installation() {
  local version="${1}"
  local -i status=0

  log_info "Verifying PHP installation..."

  if ! command -v "php${version}" >/dev/null 2>&1; then
    log_error "PHP ${version} binary not found"
    ((status+=1))
  fi

  if ! systemctl is-active "php${version}-fpm" >/dev/null 2>&1; then
    log_error "PHP-FPM service not running"
    ((status+=1))
  fi

  local php_version
  php_version=$("php${version}" -v 2>/dev/null | head -n1)
  log_debug "Installed PHP version: ${php_version}"

  return "${status}"
}

main() {
  handle_args "$@"

  local version="${SCRIPT_ARG_VERSION}"
  local dev="${SCRIPT_ARG_DEV}"
  local disable_others="${SCRIPT_ARG_DISABLE_OTHERS}"

  log_info "Starting PHP ${version} installation..."
  log_debug "Development packages: ${dev}"
  log_debug "Disable other versions: ${disable_others}"

  if ! ensure_dependencies; then
    return 1
  fi

  if ! setup_repository; then
    return 1
  fi

  if ! install_php_modules "${version}" "${dev}"; then
    return 1
  fi

  if ! disable_php_versions "${version}" "${disable_others}"; then
    log_warning "Some PHP versions could not be disabled"
  fi

  if ! configure_php "${version}"; then
    return 1
  fi

  if ! verify_installation "${version}"; then
    return 1
  fi

  log_success "PHP ${version} installation completed successfully"
  return 0
}

main "$@"
