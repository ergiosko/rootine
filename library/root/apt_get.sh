#!/usr/bin/env bash

# ---
# @description      Provides a robust wrapper around apt-get commands with locking
#                   mechanisms and error handling.
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         System Administration
# @dependencies     bash (>= 4.0), coreutils, apt-get, flock, timeout
# @configuration    Requires several environment variables to be set:
#                   - ROOTINE_APT_KEYRINGS_DIR
#                   - ROOTINE_APT_SOURCES_LIST_DIR
#                   - ROOTINE_APT_LOCK_FILE
#                   - ROOTINE_APT_DPKG_LOCK_TIMEOUT
#                   - ROOTINE_APT_COMMAND_OPTIONS (associative array)
#                   - ROOTINE_APT_QUIET_MODE (optional)
# @exitstatus       0 Success
#                   1 General error
#                   ROOTINE_STATUS_NETWORK_UNREACHABLE Network connectivity issues
# @functions        _create_apt_directories, _validate_lock_file, _acquire_apt_lock,
#                   _release_apt_lock, _filter_apt_options, apt_get_do,
#                   add_apt_repository
# @security         - Uses secure file permissions (0755) for directories
#                   - Implements proper locking mechanisms to prevent concurrent
#                   apt operations
# ---

is_sourced || exit 1

# --
# @description      Creates required directories for APT operations
# @envvar           ROOTINE_APT_KEYRINGS_DIR      Directory for storing APT keyrings
# @envvar           ROOTINE_APT_SOURCES_LIST_DIR  Directory for APT sources lists
# @return           0 on success, non-zero on failure
# @internal
# --
_create_apt_directories() {
  local -ar required_dirs=(
    "${ROOTINE_APT_KEYRINGS_DIR:?Error: ROOTINE_APT_KEYRINGS_DIR not set}"
    "${ROOTINE_APT_SOURCES_LIST_DIR:?Error: ROOTINE_APT_SOURCES_LIST_DIR not set}"
    "${ROOTINE_RUNTIME_DIR:?Error: ROOTINE_RUNTIME_DIR not set}"
  )
  local -i status=0

  for dir in "${required_dirs[@]}"; do
    if [[ -d "${dir}" ]]; then
      if [[ ! -w "${dir}" ]]; then
        log_error "Directory exists but is not writable: ${dir}"
        ((status+=1))
        continue
      fi
    else
      if ! install -d -m 0755 -- "${dir}"; then
        log_error "Failed to create required directory: ${dir}"
        ((status+=1))
      fi
    fi
  done

  return "${status}"
}

# --
# @description      Checks if package management processes are running
#                   and their lock files are held. Specifically checks
#                   dpkg, apt-get, apt processes and their lock files.
# @stdout           None
# @stderr           Log messages about process and lock file status
# @exitstatus       0 No processes running and no locks held
#                   1 Process running or lock file held
# @dependencies     - is_process_running()
#                   - is_lock_file_held()
#                   - log_messages.sh
# @example          # Check if package manager is available
#                   if check_package_manager_status; then
#                     log_info "Package manager is available for use"
#                     # Proceed with package operations
#                   else
#                     log_error "Package manager is busy, try again later"
#                     exit 1
#                   fi
# @security         - Root permissions may be needed for some lock files
#                   - Safe handling of file paths and process names
# @note             Some lock files may only be accessible by root
# @public
# --
check_package_manager_status() {
  local -ar processes=(
    "dpkg"
    "apt-get"
    "apt"
  )
  local -ar lock_files=(
    "/var/lib/dpkg/lock"
    "/var/lib/dpkg/lock-frontend"
    "/var/lib/apt/lists/lock"
    "/var/cache/apt/archives/lock"
  )
  local running=false
  local held=false
  local process
  local lock_file

  log_debug "Checking package manager processes and lock files..."

  # Check processes
  for process in "${processes[@]}"; do
    if is_process_running "${process}"; then
      log_warning "Package manager process '${process}' is running"
      running=true
      break
    fi
  done

  # Check lock files
  if ! "${running}"; then
    for lock_file in "${lock_files[@]}"; do
      if is_lock_file_held "${lock_file}"; then
        log_warning "Package manager lock file '${lock_file}' is held"
        held=true
        break
      fi
    done
  fi

  # Return status based on checks
  if "${running}"; then
    log_error "Package manager process is currently running"
    return 1
  elif "${held}"; then
    log_error "Package manager lock file is currently held"
    return 1
  else
    log_debug "Package manager is not running and no lock files are held"
    return 0
  fi
}

# --
# @description      Validates the APT lock file and its directory
# @param            lock_file Path to the APT lock file (optional,
#                   defaults to ROOTINE_APT_LOCK_FILE)
# @return           0 on success, 1 on failure
# @internal
# --
_validate_lock_file() {
  local -r lock_file="${1:-${ROOTINE_APT_LOCK_FILE}}"
  local lock_dir

  if [[ -z "${lock_file}" ]]; then
    log_error "No APT lock file provided"
    return 1
  fi

  lock_dir="$(dirname -- "${lock_file}")"

  if [[ ! -d "${lock_dir}" ]]; then
    log_error "APT lock directory does not exist: ${lock_dir}"
    return 1
  fi

  if [[ ! -w "${lock_dir}" ]]; then
    log_error "APT lock directory is not writable: ${lock_dir}"
    return 1
  fi

  if ! (umask 077 && touch "${lock_file}.$$" \
    && ln "${lock_file}.$$" "${lock_file}" 2>/dev/null); then
    rm -f "${lock_file}.$$"

    if [[ ! -f "${lock_file}" ]]; then
      log_error "Failed to create APT lock file: ${lock_file}"
      return 1
    fi
  fi

  rm -f "${lock_file}.$$"

  log_debug "APT lock file has been validated successfully"
  return 0
}

# --
# @description      Acquires an exclusive lock for APT operations
# @envvar           ROOTINE_APT_LOCK_FILE Path to the APT lock file
# @envvar           ROOTINE_APT_DPKG_LOCK_TIMEOUT Timeout in seconds
#                   for lock acquisition
# @return           0 on success, 1 on failure
# @internal
# --
_acquire_apt_lock() {
  local -i err=0

  if ! _validate_lock_file "${ROOTINE_APT_LOCK_FILE}"; then
    log_error "Failed to validate APT lock file: ${ROOTINE_APT_LOCK_FILE}"
    return 1
  fi

  if ! exec 357>"${ROOTINE_APT_LOCK_FILE}"; then
    err=$?
    log_error "Failed to open APT lock file: ${ROOTINE_APT_LOCK_FILE} (errno: ${err})"
    return 1
  fi

  if ! flock -x -w "${ROOTINE_APT_DPKG_LOCK_TIMEOUT}" 357; then
    err=$?
    log_error "Failed to acquire lock after ${ROOTINE_APT_DPKG_LOCK_TIMEOUT}s (errno: ${err})"
    exec 357>&-
    return 1
  fi

  log_debug "APT lock file has been acquired successfully"
  return 0
}

# --
# @description      Releases the APT lock and closes the file descriptor
# @return           0 on success, 1 on failure
# @internal
# --
_release_apt_lock() {
  local -i err=0

  if ! flock -x -u 357; then
    err=$?
    log_error "Failed to explicitly unlock FD 357 (errno: ${err})"
    return 1
  fi

  if ! { true >&357; } &>/dev/null; then
    err=$?
    log_error "Failed to close FD 357 (errno: ${err})"
    return 1
  fi

  log_debug "APT lock file has been released and FD closed successfully"
  return 0
}

# --
# @description      Filters and processes APT command options
# @param            command The APT command to get options for
# @envvar           ROOTINE_APT_COMMAND_OPTIONS Associative array of command options
# @envvar           ROOTINE_APT_QUIET_MODE Enable quiet mode if set to 1/true/TRUE/True
# @stdout           Filtered and processed command options
# @return           0 on success, 1 on failure
# @internal
# --
_filter_apt_options() {
  local -r command="${1:?Error: Missing APT command argument}"
  local command_options="${ROOTINE_APT_COMMAND_OPTIONS[${command}]}"

  if [[ -z "${command_options+x}" ]]; then
    log_error "Invalid APT command: ${command}"
    return 1
  fi

  if [[ -v ROOTINE_APT_QUIET_MODE ]]; then
    if [[ "${ROOTINE_APT_QUIET_MODE}" =~ ^(1|true|TRUE|True)$ ]]; then
      command_options="-qq ${command_options}"
    fi
  fi

  local -a filtered_options
  readarray -t filtered_options < <(printf "%s\n" "${command_options}" | xargs -n1)

  printf "%q\n" "${filtered_options[@]+"${filtered_options[@]}"}"
  return 0
}

# --
# @description      Sets environment variables required for non-interactive apt-get operations
# @global           LC_ALL Sets locale to C.UTF-8 for consistent output formatting
# @global           LANG Sets language locale to C.UTF-8
# @global           LANGUAGE Sets language preference to C.UTF-8
# @global           DEBIAN_FRONTEND Sets to noninteractive to prevent prompts
# @global           DEBIAN_PRIORITY Sets to critical to minimize user interaction
# @global           APT_LISTCHANGES_FRONTEND Disables listchanges frontend
# @return           Always returns 0 (success)
# @example          _set_apt_get_env_vars
# --
_set_apt_get_env_vars() {
  declare -gx LC_ALL="C.UTF-8"
  declare -gx LANG="C.UTF-8"
  declare -gx LANGUAGE="C.UTF-8"
  declare -gx DEBIAN_FRONTEND="noninteractive"
  declare -gx DEBIAN_PRIORITY="critical"
  declare -gx APT_LISTCHANGES_FRONTEND="none"
  return 0
}

# --
# @description      Executes apt-get commands with proper locking and error handling
# @param            command The apt-get command to execute (default: update)
# @param            [args...] Additional arguments to pass to apt-get
# @return           0 on success, non-zero on failure
# @public
# --
apt_get_do() {
  local -r command="${1:-update}"
  shift
  local -a apt_options cmd
  local -i status=0

  trap 'status=$?; _release_apt_lock; return "${status}"' ERR SIGHUP SIGINT SIGQUIT SIGTERM
  trap '_release_apt_lock' EXIT

  if ! check_package_manager_status; then
    log_error "Package manager is busy, try again later"
    return 1
  fi

  if ! check_internet_connection; then
    return "${ROOTINE_STATUS_NETWORK_UNREACHABLE}"
  fi

  if ! mapfile -t apt_options < <(_filter_apt_options "${command}"); then
    log_error "Failed to process APT options from '${command}' command"
    return 1
  fi

  cmd=(
    "apt-get"
    "${apt_options[@]:-}"
    "${command}"
    "${@}"
  )

  if ! _acquire_apt_lock; then
    log_error "Failed to acquire APT lock"
    return 1
  fi

  _set_apt_get_env_vars

  log_debug "Running '${cmd[*]}'"

  if ! "${cmd[@]}"; then
    status=$?
    log_error "Command failed with ${status} error code"
    return "${status}"
  fi

  log_debug "Command '${cmd[*]}' has been executed successfully"
  return 0
}

# --
# @description      Adds a new APT repository with proper error handling
# @param            repo_spec Repository specification to add
# @return           0 on success, non-zero on failure
# @public
# @example          add_apt_repository "ppa:user/repo-name"
# --
add_apt_repository() {
  local -r repo_spec="${1:?Error: Missing repository specification}"
  local -a cmd
  local -i status=0

  trap 'status=$?; _release_apt_lock; return "${status}"' ERR SIGHUP SIGINT SIGQUIT SIGTERM
  trap '_release_apt_lock' EXIT

  if ! check_package_manager_status; then
    log_error "Package manager is busy, try again later"
    return 1
  fi

  if ! command -v add-apt-repository &>/dev/null; then
    log_error "add-apt-repository command not found. Installing software-properties-common..."

    if ! apt_get_do install software-properties-common; then
      log_error "Failed to install software-properties-common"
      return 1
    fi
  fi

  if ! check_internet_connection; then
    return "${ROOTINE_STATUS_NETWORK_UNREACHABLE}"
  fi

  cmd=(
    "add-apt-repository"
    "-y"
    "${repo_spec}"
  )

  if ! _acquire_apt_lock; then
    log_error "Failed to acquire APT lock"
    return 1
  fi

  _set_apt_get_env_vars

  log_debug "Running '${cmd[*]}'"

  if ! "${cmd[@]}"; then
    status=$?
    log_error "Failed to add repository: ${repo_spec}"
    return "${status}"
  fi

  log_success "Successfully added repository: ${repo_spec}"
  return 0
}

# Initialize required directories
_create_apt_directories || exit 1
