#!/usr/bin/env bash

is_sourced || exit 1

declare -gA ROOTINE_SCRIPT_ARGS=(
  [user-email]="Git global user email:1:${1:-ROOTINE_GIT_USER_EMAIL}:^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
  [user-name]="Git global user name:1:${2:-ROOTINE_GIT_USER_NAME}:^[a-zA-Z0-9\s.-]+$"
  [core-filemode]="Git core filemode:0:${3:-ROOTINE_GIT_CORE_FILEMODE}:^(true|false)$"
)

install_git() {
  log_info "Adding Git PPA and installing Git..."

  if ! add_apt_repository "ppa:git-core/ppa"; then
    log_error "Failed to add Git PPA"
    return 1
  fi

  if ! apt_get_do install git; then
    log_error "Failed to install Git"
    return 1
  fi

  return 0
}

configure_git() {
  local email="${1}"
  local name="${2}"
  local core_filemode="${3}"
  local -i config_errors=0
  local -A git_config=(
    ["user.email"]="${email}"
    ["user.name"]="${name}"
    ["core.filemode"]="$([[ "${core_filemode}" == "true" ]] && echo "true" || echo "false")"
  )

  log_info "Configuring Git global settings..."

  for key in "${!git_config[@]}"; do
    if ! git config --global "${key}" "${git_config[${key}]}"; then
      log_error "Failed to set ${key}=${git_config[${key}]}"
      ((config_errors+=1))
    else
      log_debug "Set ${key}=${git_config[${key}]}"
    fi
  done

  if ((config_errors > 0)); then
    log_error "Git configuration failed with ${config_errors} errors"
    return 1
  fi

  return 0
}

verify_installation() {
  log_info "Verifying Git installation..."

  if ! command -v git &>/dev/null; then
    log_error "Git is not available in PATH"
    return 1
  fi

  log_debug "Git version: $(git --version)"
  log_debug "Git configuration:"
  git config --list --show-origin || true

  return 0
}

main() {
  handle_args "$@"

  local user_email="${ROOTINE_SCRIPT_ARG_USER_EMAIL}"
  local user_name="${ROOTINE_SCRIPT_ARG_USER_NAME}"
  local core_filemode="${ROOTINE_SCRIPT_ARG_CORE_FILEMODE}"

  log_info "Starting Git installation and configuration..."
  log_debug "User email: ${user_email}"
  log_debug "User name: ${user_name}"
  log_debug "Core filemode: ${core_filemode}"

  if ! install_git; then
    return 1
  fi

  if ! configure_git "${user_email}" "${user_name}" "${core_filemode}"; then
    return 1
  fi

  if ! verify_installation; then
    return 1
  fi

  log_success "Git installation and configuration completed successfully"
  return 0
}

main "$@"
