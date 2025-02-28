#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [htpasswd]="Password for Apache2 user:1:${2:-}:^.{12,}$"
)

declare -ga APACHE_MODULES_ENABLE=(
  "core" "so" "watchdog" "http" "log_config" "logio" "version" "unixd"
  "alias" "auth_basic" "authn_core" "authn_file" "authz_core" "authz_host"
  "authz_user" "autoindex" "brotli" "deflate" "dir" "env" "expires"
  "ext_filter" "fcgid" "filter" "headers" "http2" "mime" "mpm_event"
  "negotiation" "proxy" "proxy_balancer" "proxy_http" "proxy_fcgi"
  "reqtimeout" "rewrite" "setenvif" "socache_shmcb" "ssl"
)

declare -ga APACHE_MODULES_DISABLE=(
  "access_compat"
  "status"
)

install_apache() {
  if ! add_apt_repository "ppa:ondrej/apache2"; then
    log_error "Failed to add Apache PPA"
    return 1
  fi

  if ! apt_get_do install apache2; then
    log_error "Failed to install Apache2"
    return 1
  fi

  return 0
}

configure_htpasswd() {
  local password="${1}"
  local htpasswd_file="/etc/apache2/htpasswds"

  if ! htpasswd -cbB "${htpasswd_file}" "${ROOTINE_APACHE2_USER_NAME}" "${password}"; then
    log_error "Failed to create htpasswd file"
    return 1
  fi

  return 0
}

install_additional_packages() {
  if ! apt_get_do update; then
    return 1
  fi

  if ! apt_get_do install "libapache2-mod-fcgid" "brotli"; then
    log_error "Failed to install additional packages"
    return 1
  fi

  return 0
}

manage_apache_modules() {
  local operation="${1}"
  shift
  local -a modules=("${@}")

  for module in "${modules[@]}"; do
    if ! "a2${operation}mod" "${module}"; then
      log_error "Failed to ${operation} Apache module: ${module}"
      return 1
    fi
  done

  return 0
}

verify_apache_config() {
  if ! apachectl -t; then
    log_error "Apache configuration is invalid"
    return 1
  fi

  log_debug "Apache version info:"
  apachectl -V

  log_debug "Loaded modules:"
  apachectl -M

  return 0
}

main() {
  handle_args "$@"

  local htpasswd="${ROOTINE_SCRIPT_ARG_HTPASSWD}"

  log_info "Starting Apache server installation..."

  if ! install_apache; then
    return 1
  fi

  if ! configure_htpasswd "${htpasswd}"; then
    return 1
  fi

  if ! manage_apache_modules "dis" "${APACHE_MODULES_DISABLE[@]}"; then
    return 1
  fi

  if ! install_additional_packages; then
    return 1
  fi

  if ! manage_apache_modules "en" "${APACHE_MODULES_ENABLE[@]}"; then
    return 1
  fi

  if ! systemctl restart apache2; then
    log_error "Failed to restart Apache"
    return 1
  fi

  if ! verify_apache_config; then
    return 1
  fi

  log_success "Apache server installation completed successfully"
  return 0
}

main "$@"
