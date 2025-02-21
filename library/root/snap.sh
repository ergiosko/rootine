#!/usr/bin/env bash

# ---
# @description      Manages Snap Store operations including stopping and refreshing snap packages.
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Rootine
# @dependencies     Bash 4.0+, pgrep, killall, snap, sleep
# @configuration    Requires initialization of the following environment variables:
#                   - ROOTINE_SNAP_STORE: Name of the snap store process.
#                   - ROOTINE_SNAP_REFRESH_RETRIES: Number of retries for snap refresh (default: 3).
#                   - ROOTINE_SNAP_REFRESH_DELAY: Delay between retries in seconds (default: 5).
#                   - ROOTINE_STATUS_NETWORK_UNREACHABLE: Status code for network unreachability.
# @envvar           ROOTINE_SNAP_STORE                  Name of the snap store process.
# @envvar           ROOTINE_SNAP_REFRESH_RETRIES        Number of retries for snap refresh (default: 3).
# @envvar           ROOTINE_SNAP_REFRESH_DELAY          Delay between retries in seconds (default: 5).
# @envvar           ROOTINE_STATUS_NETWORK_UNREACHABLE  Status code for network unreachability.
# @stdout           Logs information and success messages.
# @stderr           Logs error messages.
# @exitstatus       0 Success
#                   1 General error
#                   2 Usage error (invalid arguments)
#                   3 Network unreachability
# @functions        snap_stop     Stops the Snap Store service if running.
#                   snap_refresh  Refreshes snap packages with retry logic.
# @security         Ensures that required commands are available before proceeding.
#                   Checks internet connectivity before attempting to refresh
#                   snap packages. Handles errors and logs appropriate messages.
# @note             This script is designed to be sourced, not executed directly.
#                   Provides detailed logging for each step of the operations.
# ---

is_sourced || exit 1

# --
# @description      Stops the Snap Store service if it is running.
# @dependencies     pgrep, killall
# @envvar           ROOTINE_SNAP_STORE  Name of the snap store process.
# @stdout           Logs information and success messages.
# @stderr           Logs error messages.
# @exitstatus       0 if the Snap Store service is stopped successfully or not running.
#                   1 if an error occurs.
# --
snap_stop() {
  local -ar required_cmds=("pgrep" "killall")

  if ! is_command_available "${required_cmds[@]}"; then
    log_error "Missing required commands: ${required_cmds[*]}"
    return 1
  fi

  if ! pgrep "${ROOTINE_SNAP_STORE}" &>/dev/null; then
    log_info "Snap Store is not running"
    return 0
  fi

  log_info "Stopping ${ROOTINE_SNAP_STORE}..."

  if ! killall -q -w "${ROOTINE_SNAP_STORE}"; then
    log_error "Failed to stop ${ROOTINE_SNAP_STORE} using killall"
    return 1
  fi

  log_success "Snap Store stopped successfully"
  return 0
}

# --
# @description      Refreshes snap packages with retry logic.
# @dependencies     snap, sleep
# @envvar           ROOTINE_SNAP_REFRESH_RETRIES        Number of retries for snap refresh (default: 3).
# @envvar           ROOTINE_SNAP_REFRESH_DELAY          Delay between retries in seconds (default: 5).
# @envvar           ROOTINE_STATUS_NETWORK_UNREACHABLE  Status code for network unreachability.
# @stdout           Logs information and success messages.
# @stderr           Logs error messages.
# @exitstatus       0 if snap packages are refreshed successfully.
#                   1 if an error occurs.
#                   ROOTINE_STATUS_NETWORK_UNREACHABLE if network is not reachable.
# --
snap_refresh() {
  local -ir retries="${ROOTINE_SNAP_REFRESH_RETRIES:-3}"
  local -ir delay="${ROOTINE_SNAP_REFRESH_DELAY:-5}"
  local -ar required_cmds=("snap" "sleep")
  local -i attempt=1

  if ! is_command_available "${required_cmds[@]}"; then
    log_error "Missing required commands: ${required_cmds[*]}"
    return 1
  fi

  if ! check_internet_connection; then
    return "${ROOTINE_STATUS_NETWORK_UNREACHABLE}"
  fi

  while ((attempt <= retries)); do
    log_info "Refreshing snap packages (attempt ${attempt}/${retries})..."

    if snap refresh; then
      log_success "Snap packages refreshed successfully"
      return 0
    fi

    if ((attempt < retries)); then
      log_info "Waiting ${delay} seconds before retry..."
      sleep "${delay}"
    fi

    ((attempt+=1))
  done

  log_error "Failed to refresh snap packages after ${retries} attempts"
  return 1
}
