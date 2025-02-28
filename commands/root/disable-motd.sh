#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [create-hushlogin]="Create .hushlogin file:0:${1:-true}:^(true|false)$"
  [disable-news]="Disable MOTD news:0:${2:-true}:^(true|false)$"
)

main() {
  handle_args "$@"

  local create_hushlogin="${ROOTINE_SCRIPT_ARG_CREATE_HUSHLOGIN}"
  local disable_news="${ROOTINE_SCRIPT_ARG_DISABLE_NEWS}"
  local motd_news_file="/etc/default/motd-news"
  local hushlogin_file="/root/.hushlogin"
  local update_motd_dir="/etc/update-motd.d"

  log_info "Starting MOTD configuration..."

  if [[ "${create_hushlogin}" == "true" ]]; then
    if ! touch "${hushlogin_file}"; then
      log_error "Failed to create ${hushlogin_file}"
      return 1
    fi
    log_debug "Created ${hushlogin_file}"
  fi

  if [[ "${disable_news}" == "true" ]]; then
    if ! touch "${motd_news_file}" || ! echo "ENABLED=0" > "${motd_news_file}"; then
      log_error "Failed to configure ${motd_news_file}"
      return 1
    fi
    log_debug "Disabled MOTD news in ${motd_news_file}"
  fi

  if [[ -d "${update_motd_dir}" ]]; then
    set +f
    if ! chmod 0644 "${update_motd_dir}"/*; then
      log_error "Failed to set permissions in ${update_motd_dir}"
      return 1
    fi
    set -f
    log_debug "Updated permissions in ${update_motd_dir}"
  fi

  log_info "Verifying MOTD configuration..."
  log_debug "Hushlogin enabled: ${create_hushlogin}"
  log_debug "MOTD news disabled: ${disable_news}"
  log_debug "MOTD scripts permissions updated: $(test -d "${update_motd_dir}" && echo true || echo false)"

  log_success "MOTD configuration completed successfully"
  return 0
}

main "$@"
