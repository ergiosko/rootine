#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [mail-name]="Mail server FQDN:0:${1:-$(hostname -f)}:^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
  [interactive]="Run in interactive mode:0:${2:-true}:^(true|false)$"
  [configure-firewall]="Configure firewall rules:0:${3:-true}:^(true|false)$"
)

declare -gr POSTFIX_CONFIG_DIR="/etc/postfix"
declare -gr POSTFIX_MAIN_CF="${POSTFIX_CONFIG_DIR}/main.cf"
declare -gr BACKUP_DIR="/var/backups/postfix"

declare -gr REQUIRED_PACKAGES=(
  "mailutils"
  "postfix"
  "ufw"
  "ssl-cert"
  "ca-certificates"
)

declare -gr SMTP_PORTS=(25 465 587)

check_system_requirements() {
  log_info "Checking system requirements..."
  local -i status=0

  if ! check_internet_connection; then
    log_error "No internet connection available"
    return "${ROOTINE_STATUS_NETWORK_UNREACHABLE}"
  fi

  local -a required_commands=("ufw" "hostname" "systemctl")

  if ! is_command_available "${required_commands[@]}"; then
    log_error "Missing required commands"
    ((status+=1))
  fi

  local free_space
  free_space=$(df -k / | awk 'NR==2 {print $4}')

  if ((free_space < 1048576)); then
    log_error "Insufficient disk space (less than 1GB available)"
    ((status+=1))
  fi

  return "${status}"
}

install_packages() {
  log_info "Installing required packages..."

  if ! apt_get_do update; then
    return 1
  fi

  local -a install_opts=(-o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold")

  if ! apt_get_do install "${install_opts[@]}" "${REQUIRED_PACKAGES[@]}"; then
    log_error "Failed to install required packages"
    return 1
  fi

  return 0
}

configure_postfix() {
  local mail_name="${1}"
  local interactive="${2}"
  local -i status=0

  log_info "Configuring Postfix..."

  mkdir -p "${BACKUP_DIR}"

  if [[ -f "${POSTFIX_MAIN_CF}" ]]; then
    cp "${POSTFIX_MAIN_CF}" "${BACKUP_DIR}/main.cf.$(date +%Y%m%d%H%M%S)"
  fi

  if [[ "${interactive}" == "true" ]]; then
    dpkg-reconfigure postfix
  else
    local -a settings=(
      "myhostname = ${mail_name}"
      "mydestination = ${mail_name}, localhost.localdomain, localhost"
      "smtpd_banner = \$myhostname ESMTP"
      "smtp_tls_security_level = may"
      "smtpd_tls_security_level = may"
      "smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination"
    )

    for setting in "${settings[@]}"; do
      if ! postconf -e "${setting}"; then
        log_error "Failed to set: ${setting}"
        ((status+=1))
      fi
    done
  fi

  return "${status}"
}

configure_firewall() {
  local configure_fw="${1}"
  local -i status=0

  if [[ "${configure_fw}" != "true" ]]; then
    return 0
  fi

  log_info "Configuring firewall rules..."

  for port in "${SMTP_PORTS[@]}"; do
    if ! ufw allow "${port}/tcp" comment "Postfix SMTP"; then
      log_error "Failed to add firewall rule for port ${port}"
      ((status+=1))
    fi
  done

  if ! ufw reload; then
    log_error "Failed to reload firewall rules"
    ((status+=1))
  fi

  return "${status}"
}

verify_installation() {
  log_info "Verifying Postfix installation..."
  local -i status=0

  if ! systemctl is-active --quiet postfix; then
    log_error "Postfix service is not running"
    ((status+=1))
  fi

  if ! postfix check; then
    log_error "Postfix configuration check failed"
    ((status+=1))
  fi

  for port in "${SMTP_PORTS[@]}"; do
    if ! netstat -tuln | grep -q ":${port}"; then
      log_warning "Port ${port} is not listening"
    fi
  done

  log_debug "Postfix version: $(postconf -d mail_version)"
  log_debug "Configuration: $(postconf -n)"
  log_debug "Service status: $(systemctl status postfix --no-pager)"

  return "${status}"
}

main() {
  handle_args "$@"

  local mail_name="${SCRIPT_ARG_MAIL_NAME}"
  local interactive="${SCRIPT_ARG_INTERACTIVE}"
  local configure_fw="${SCRIPT_ARG_CONFIGURE_FIREWALL}"

  log_info "Starting Postfix installation..."
  log_debug "Mail name: ${mail_name}"
  log_debug "Interactive mode: ${interactive}"
  log_debug "Configure firewall: ${configure_fw}"

  if ! check_system_requirements; then
    return 1
  fi

  if ! install_packages; then
    return 1
  fi

  if ! configure_postfix "${mail_name}" "${interactive}"; then
    return 1
  fi

  if ! configure_firewall "${configure_fw}"; then
    log_warning "Firewall configuration failed"
  fi

  if ! systemctl restart postfix; then
    log_error "Failed to restart Postfix"
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Postfix installation completed successfully"
  return 0
}

main "$@"
