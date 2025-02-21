#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [domain]="Domain for SSL certificate:1:${1:-noskov.org}:^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"
)

main() {
  handle_args "$@"

  local domain="${SCRIPT_ARG_DOMAIN}"
  local -a snap_commands=(
    "install core"
    "refresh core"
    "install --classic certbot"
    "set certbot trust-plugin-with-root=ok"
    "install certbot-dns-cloudflare"
  )

  log_info "Starting Certbot installation..."

  for cmd in "${snap_commands[@]}"; do
    if ! snap "${cmd}"; then
      log_error "Failed to execute: snap ${cmd}"
      return 1
    fi
  done

  ln -sf "/snap/bin/certbot" "/usr/bin/certbot"

  if ! certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials "${ROOTINE_APACHE2_CLOUDFLARE_DIR}/${domain}.ini" \
    --dns-cloudflare-propagation-seconds 60 \
    -d "${domain}" \
    -d "*.${domain}" \
    -i apache; then
    log_error "Failed to obtain SSL certificates"
    return 1
  fi

  if ! certbot renew --dry-run; then
    log_error "Certbot renewal test failed"
    return 1
  fi

  if ! systemctl restart apache2; then
    log_error "Failed to restart Apache"
    return 1
  fi

  log_success "Certbot installation completed successfully"
  return 0
}

main "$@"
