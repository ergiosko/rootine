#!/usr/bin/env bash

# ---
# @description      Bootstrap component of the Rootine framework - initializes
#                   core functionality and handles command routing
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Core
# @dependencies     - Bash 4.4.0 or higher
#                   - date
#                   - dirname
#                   - lsb_release
#                   - mkdir
#                   - realpath
#                   - uname
#                   - rm
#                   - find
#                   - chmod
# @configuration    Requires various ROOTINE_* environment variables to be set:
#                   - ROOTINE_PATH: Base path of the framework
#                   - ROOTINE_LIBRARY_DIR: Path to library directory
#                   - ROOTINE_COMMANDS_DIR: Path to commands directory
#                   - And others defined in constants.sh
# @stdin            None
# @stdout           None
# @stderr           Status and error messages
# @exitstatus       0 Success
#                   1 Various error conditions (see individual functions)
# @functions        is_sourced                Checks if script is being sourced
#                   is_root                   Checks if running as root
#                   _safe_remove              Safely removes files and directories
#                   _cleanup_handler          Handles cleanup on exit
#                   _error_handler            Handles error conditions
#                   is_command_available      Checks for required system commands
#                   _populate_ubuntu_info     Gathers system information
#                   _get_user_level           Determines user execution level
#                   _source_user_level_files  Loads appropriate library files
#                   _validate_constants       Verifies required constants
#                   _create_utility_dirs      Creates required directories
#                   _find_library_function    Locates library functions
#                   _route_command            Routes and executes commands
#                   _init_environment         Initializes the environment
# @security         - Validates all paths before use
#                   - Enforces user level access controls
#                   - Uses full paths for commands
#                   - Implements safe file cleanup
# @todo             - Implement library function caching
# ---

# Global arrays for tracking temporary resources
declare -gar ROOTINE_USER_LEVELS=("common" "root" "user")
declare -ga ROOTINE_TEMPORARY_FILES=()
declare -ga ROOTINE_CLEANUP_DIRS=()

# --
# @description      Determines if the current script is being sourced or executed directly
# @stdout           None
# @return           0 if script is being sourced, 1 if executed directly
# @example          if ! is_sourced; then
#                     echo "This script must be sourced"
#                     exit 1
#                   fi
# --
is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# --
# @description      Checks if the current user has root privileges
# @stdout           None
# @return           0 if user is root, 1 otherwise
# @example          if ! is_root; then
#                     echo "This command requires root privileges"
#                     exit 1
#                   fi
# --
is_root() {
  [[ "${EUID}" -eq 0 ]]
}

# --
# @description      Safely removes files or directories
# @param {string}   item    Path to file or directory to remove
# @param {boolean}  is_dir  'true' if item is directory, 'false' if file
# @stdout           None
# @stderr           None (errors suppressed)
# @return           0 on success or if item doesn't exist
#                   1 on removal failure
# @example          _safe_remove "/tmp/tempfile" "false"
# @internal
# --
_safe_remove() {
  local -r item="${1}"
  local -r is_dir="${2}"

  [[ ! -e "${item}" ]] && return 0

  if [[ "${is_dir}" == "true" ]]; then
    rm -rf -- "${item}" &>/dev/null || return 1
  else
    rm -f -- "${item}" &>/dev/null || return 1
  fi

  return 0
}

# --
# @description      Handles cleanup of temporary files and directories on script exit
# @param {integer}  exit_code Exit code from the terminated script (optional)
# @stdout           None
# @stderr           Status messages about cleanup operations
# @exitstatus       0 All cleanups successful
#                   1 One or more cleanup operations failed
# @global           ROOTINE_TEMPORARY_FILES Array of temporary files to remove
# @global           ROOTINE_CLEANUP_DIRS    Array of temporary directories to remove
# @sideeffects      - Removes temporary files and directories
#                   - Disables error exit flag during cleanup
# @example          trap '_cleanup_handler' EXIT
# @internal
# --
_cleanup_handler() {
  local -r exit_code="${1:-$?}"
  local -a failed_cleanups=()
  local -i cleanup_status=0

  set +e

  if [[ -n "${ROOTINE_TEMPORARY_FILES[*]:-}" ]]; then
    printf "%s[ DEBUG ]%s Cleaning up temporary files...\n" \
      "${RCLR_WHITE}" "${RCLR_RESET}" >&2
    printf "  Total files: %d\n" "${#ROOTINE_TEMPORARY_FILES[@]}" >&2

    for file in "${ROOTINE_TEMPORARY_FILES[@]}"; do
      if ! _safe_remove "${file}" "false"; then
        failed_cleanups+=("${file}")
        cleanup_status=1
      fi
    done
  fi

  if [[ -n "${ROOTINE_CLEANUP_DIRS[*]:-}" ]]; then
    printf "%s[ DEBUG ]%s Cleaning up temporary directories...\n" \
      "${RCLR_WHITE}" "${RCLR_RESET}" >&2
    printf "  Total directories: %d\n" "${#ROOTINE_CLEANUP_DIRS[@]}" >&2

    for dir in "${ROOTINE_CLEANUP_DIRS[@]}"; do
      if ! _safe_remove "${dir}" "true"; then
        failed_cleanups+=("${dir}")
        cleanup_status=1
      fi
    done
  fi

  if ((cleanup_status != 0)); then
    printf "%s[ ERROR ]%s Failed to clean up the following items:\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    printf "  %s\n" "${failed_cleanups[@]}" >&2
  fi

  printf "%s[ DEBUG ]%s Cleanup handler completed\n" \
    "${RCLR_WHITE}" "${RCLR_RESET}" >&2
  printf "  Exit code: %d\n" "${exit_code}" >&2

  set -e

  exit $((exit_code != 0 ? exit_code : cleanup_status))
}

# --
# @description      Handles error conditions and provides detailed stack traces
# @param {string}   source      Source file where error occurred
# @param {integer}  lineno      Line number where error occurred
# @param {integer}  error_code  Error code (defaults to 1)
# @stdout           None
# @stderr           Detailed error information and stack trace
# @exitstatus       Value of error_code parameter
# @global           FUNCNAME    Array of function names in call stack
# @global           BASH_LINENO Array of line numbers in call stack
# @global           BASH_SOURCE Array of source files in call stack
# @example          trap 'status=$?; _error_handler "${BASH_SOURCE[0]}" "${LINENO}" "${status}"' ERR
# @internal
# @note             This handler provides detailed debugging information for development
# --
_error_handler() {
  local -r source="${1:?}"
  local -r lineno="${2:?}"
  local -r error_code="${3:-1}"
  local -i stack_size
  local -i i

  stack_size=$((${#FUNCNAME[@]} - 1))

  printf "%s[ ERROR ]%s Script execution failed\n" \
    "${RCLR_RED}" "${RCLR_RESET}" >&2
  printf "  Location: %s\n" "${source}" >&2
  printf "  Line: %d\n" "${lineno}" >&2
  printf "  Exit code: %d\n" "${error_code}" >&2

  if ((stack_size > 0)); then
    printf "\n%s[ DEBUG ]%s Call stack (most recent call first):\n" \
      "${RCLR_WHITE}" "${RCLR_RESET}" >&2

    for ((i = 1; i <= stack_size; i += 1)); do
      local -r func="${FUNCNAME[i]}"
      local -r line="${BASH_LINENO[i - 1]}"
      local -r src="${BASH_SOURCE[i]:-unknown}"
      local -r display_func="${func/#main/<main>}"

      printf "  %2d: %s()\n" "${i}" "${display_func}" >&2
      printf "    File: %s\n" "${src}" >&2
      printf "    Line: %s\n" "${line}" >&2
    done
  fi

  printf "\n%s[ DEBUG ]%s Error handler triggered with exit code: %s\n" \
    "${RCLR_WHITE}" "${RCLR_RESET}" "${error_code}" >&2

  exit "${error_code}"
}

# --
# @description      Checks if required system commands are available
# @param            Command names as separate arguments or space-separated string
# @stdout           None
# @stderr           Error message if commands are missing
# @exitstatus       0 All commands are available
#                   1 One or more commands are missing
# @example          is_command_available "date" "dirname" "realpath"
#                   is_command_available "date dirname realpath"
# --
is_command_available() {
  local -a commands=()
  local -a missing_cmds=()
  local cmd

  if [[ $# -eq 1 ]] && [[ "${1}" == *" "* ]]; then
    IFS=' ' read -r -a commands <<<"${1}"
  else
    commands=("$@")
  fi

  for cmd in "${commands[@]}"; do
    [[ -z "${cmd}" ]] && continue
    command -v "${cmd}" &>/dev/null || missing_cmds+=("${cmd}")
  done

  if [[ ${#missing_cmds[@]} -gt 0 ]]; then
    printf "%s[ ERROR ]%s Missing required system commands\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    printf "  Commands: %s\n" "$(printf "'%s' " "${missing_cmds[@]}")" >&2
    printf "  Please install the required packages for these commands\n" >&2
    return 1
  fi

  return 0
}

# --
# @description      Gathers Ubuntu system information and sets global variables
# @stdout           None
# @stderr           None
# @exitstatus       0 Always succeeds, using ROOTINE_UNKNOWN for unavailable info
# @global           ROOTINE_UBUNTU_DESCRIPTION  Ubuntu system description
# @global           ROOTINE_UBUNTU_RELEASE      Ubuntu release version
# @global           ROOTINE_UBUNTU_CODENAME     Ubuntu release codename
# @global           ROOTINE_KERNEL_RELEASE      Kernel version
# @dependencies     lsb_release, uname
# @example          _populate_ubuntu_info
#                   echo "Ubuntu version: ${ROOTINE_UBUNTU_RELEASE}"
# @internal
# @note             Uses ROOTINE_UNKNOWN if system information is unavailable
# --
_populate_ubuntu_info() {
  local desc release codename kernel

  if is_command_available "lsb_release"; then
    desc="$(lsb_release -ds &>/dev/null || echo "${ROOTINE_UNKNOWN}")"
    release="$(lsb_release -rs &>/dev/null || echo "${ROOTINE_UNKNOWN}")"
    codename="$(lsb_release -cs &>/dev/null || echo "${ROOTINE_UNKNOWN}")"
  else
    desc="${ROOTINE_UNKNOWN}"
    release="${ROOTINE_UNKNOWN}"
    codename="${ROOTINE_UNKNOWN}"
  fi

  kernel="$(is_command_available "uname" && uname -r &>/dev/null ||
    echo "${ROOTINE_UNKNOWN}")"

  declare -gr ROOTINE_UBUNTU_DESCRIPTION="${desc}"
  declare -gr ROOTINE_UBUNTU_RELEASE="${release}"
  declare -gr ROOTINE_UBUNTU_CODENAME="${codename}"
  declare -gr ROOTINE_KERNEL_RELEASE="${kernel}"

  return 0
}

# --
# @description      Determines the current user's execution level (root or user)
# @stdout           "root" if running as root, "user" otherwise
# @return           0 Always succeeds
# @example          user_level="$(_get_user_level)"
# @internal
# --
_get_user_level() {
  is_root && echo "root" || echo "user"
}

# --
# @description      Sources appropriate library files based on user level
# @param {string}   level User level ("root" or "user")
# @stdout           None
# @stderr           Error messages if files cannot be accessed
# @exitstatus       0 All required files sourced successfully
#                   1 Failed to source one or more files
# @global           ROOTINE_LIBRARY_DIR  Base directory for library files
# @sideeffects      Sources multiple shell script files into current environment
# @example          _source_user_level_files "root"
# @internal
# --
_source_user_level_files() {
  local -r level="${1}"
  local -a level_files=()
  local -r lib_path="${ROOTINE_LIBRARY_DIR}"

  local -ar common_files=(
    "${lib_path}/common/constants.sh"
    "${lib_path}/common/log_messages.sh"
    "${lib_path}/common/functions.sh"
    "${lib_path}/common/arg_parser.sh"
  )

  local -ar root_files=(
    "${lib_path}/root/constants.sh"
    "${lib_path}/root/sys_info.sh"
    "${lib_path}/root/snap.sh"
    "${lib_path}/root/apt_get.sh"
  )

  local -ar user_files=(
    "${lib_path}/user/constants.sh"
    "${lib_path}/user/git.sh"
  )

  for file in "${common_files[@]}"; do
    if [[ ! -f "${file}" ]] || [[ ! -r "${file}" ]]; then
      printf "%s[ ERROR ]%s Common library file not accessible\n" \
        "${RCLR_RED}" "${RCLR_RESET}" >&2
      printf "  File: %s\n" "${file}" >&2
      printf "  Please check:\n" >&2
      printf "  - File exists\n" >&2
      printf "  - File permissions are correct\n" >&2
      printf "  - Path is valid\n" >&2
      return 1
    fi
    source "${file}"
  done

  case "${level}" in
    "root") level_files=("${root_files[@]}") ;;
    "user") level_files=("${user_files[@]}") ;;
    *)
      printf "%s[ ERROR ]%s Invalid user level specified\n" \
        "${RCLR_RED}" "${RCLR_RESET}" >&2
      printf "  Level: %s\n" "${level}" >&2
      printf "  Valid levels: root, user\n" >&2
      return 1
      ;;
  esac

  for file in "${level_files[@]}"; do
    if [[ ! -f "${file}" ]] || [[ ! -r "${file}" ]]; then
      printf "%s[ ERROR ]%s %s-level library file not accessible\n" \
        "${RCLR_RED}" "${RCLR_RESET}" "${level^}" >&2
      printf "  File: %s\n" "${file}" >&2
      printf "  Please check:\n" >&2
      printf "  - File exists\n" >&2
      printf "  - File permissions are correct\n" >&2
      printf "  - Path is valid\n" >&2
      return 1
    fi
    source "${file}"
  done

  return 0
}

# --
# @description      Validates that all required environment constants are set
# @stdout           None
# @stderr           Error message listing missing constants
# @exitstatus       0 All required constants are set
#                   1 One or more constants are missing
# @example          _validate_constants || echo "Missing required constants"
# @internal
# --
_validate_constants() {
  local -ar required_constants=(
    "ROOTINE_COMMANDS_DIR"
    "ROOTINE_LIBRARY_DIR"
    "ROOTINE_LOG_LEVEL_DEFAULT"
    "ROOTINE_MIN_BASH_VERSION"
    "ROOTINE_PATH"
    "ROOTINE_TMP_DIR"
    "ROOTINE_VALID_FILE_PERMISSIONS"
    "ROOTINE_VERSION"
  )
  local missing_constants=()

  for const in "${required_constants[@]}"; do
    [[ -z "${!const+@}" ]] && missing_constants+=("${const}")
  done

  if ((${#missing_constants[@]} > 0)); then
    printf "%s[ ERROR ]%s Required environment constants not set\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    printf "  Missing constants:\n" >&2
    printf "  - %s\n" "${missing_constants[@]}" >&2
    printf "  Please ensure all required constants are properly defined\n" >&2
    return 1
  fi

  return 0
}

# --
# @description      Searches for and loads a function from library files
# @param {string}   func_name     Name of function to find
# @param {string}   search_level  User level to search in (root/user)
# @stdout           None
# @stderr           None
# @exitstatus       0 Function found and loaded
#                   1 Function not found
# @sideeffects      Sources library files when searching for functions
# @example          _find_library_function "my_function" "user"
# @internal
# @security         Only searches in authorized library directories
# --
_find_library_function() {
  local -r func_name="${1}"
  local -r search_level="${2}"
  local found=0

  # First look in common library
  if [[ -d "${ROOTINE_LIBRARY_DIR}/common" ]]; then
    while IFS= read -r -d '' file; do
      if [[ -r "${file}" ]]; then
        if source "${file}" 2>/dev/null; then
          if declare -F "${func_name}" >/dev/null; then
            found=1
            break
          fi
        fi
      fi
    done < <(find "${ROOTINE_LIBRARY_DIR}/common" \
      -maxdepth 1 -type f -name "*.sh" -print0)
  fi

  # Then look in level-specific library
  if ((found == 0)) && [[ -n "${search_level}" ]] &&
    [[ "${search_level}" != "common" ]]; then
    if [[ -d "${ROOTINE_LIBRARY_DIR}/${search_level}" ]]; then
      while IFS= read -r -d '' file; do
        if [[ -r "${file}" ]]; then
          if source "${file}" 2>/dev/null; then
            if declare -F "${func_name}" >/dev/null; then
              found=1
              break
            fi
          fi
        fi
      done < <(find "${ROOTINE_LIBRARY_DIR}/${search_level}" \
        -maxdepth 1 -type f -name "*.sh" -print0)
    fi
  fi

  return $((1 - found))
}

# --
# @description      Routes and executes commands or functions based on call format
# @param {string}   call Command or function to execute
# @param            Additional arguments passed to the command/function
# @stdout           Command/function output
# @stderr           Status and error messages
# @exitstatus       0 Command/function executed successfully
#                   1 Various error conditions
# @global           ROOTINE_COMMAND_PATH  Set to path of executed command script
# @example          _route_command "lib::common::function" "arg1" "arg2"
#                   _route_command "command_name" "arg1" "arg2"
# @internal
# @security         Validates user level access before execution
# --
_route_command() {
  local -r call="${1:?Command call parameter is required}"
  shift || {
    printf "%s[ ERROR ]%s No command arguments provided\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    printf "  Usage: <command> [arguments...]\n" >&2
    return 1
  }

  # Get user level and validate early
  local -r level="$(_get_user_level)"
  if [[ -z "${level}" ]]; then
    printf "%s[ ERROR ]%s Failed to determine user execution level\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    printf "  Please check effective user ID (EUID)\n" >&2
    return 1
  fi

  local -r request_id="$(date -u +%Y%m%d_%H%M%S_%N)"
  printf "%s[ DEBUG ]%s Processing function call\n" \
    "${RCLR_WHITE}" "${RCLR_RESET}" >&2
  printf "  Request ID: %s\n" "${request_id}" >&2
  printf "  Call: %s\n" "${call}" >&2

  # Case 1: Handle explicit library function calls (lib::library::function)
  if [[ "${call}" =~ ^lib::([^:]+)::([^:]+)$ ]]; then
    local -r lib_name="${BASH_REMATCH[1]}"
    local -r func_name="${BASH_REMATCH[2]}"

    # Validate library name
    case "${lib_name}" in
      common)
        local -r lib_dir="${ROOTINE_LIBRARY_DIR}/common"
        ;;
      root | user)
        if [[ "${lib_name}" != "${level}" ]]; then
          printf "%s[ ERROR ]%s Access denied to library\n" \
            "${RCLR_RED}" "${RCLR_RESET}" >&2
          printf "  Library: %s\n" "${lib_name}" >&2
          printf "  Current user level: %s\n" "${level}" >&2
          printf "  Required user level: %s\n" "${lib_name}" >&2
          return 1
        fi
        local -r lib_dir="${ROOTINE_LIBRARY_DIR}/${lib_name}"
        ;;
      *)
        printf "%s[ ERROR ]%s Invalid library specified\n" \
          "${RCLR_RED}" "${RCLR_RESET}" >&2
        printf "  Library: %s\n" "${lib_name}" >&2
        printf "  Valid libraries: common, root, user\n" >&2
        return 1
        ;;
    esac

    # Execute library function if found
    if [[ -d "${lib_dir}" ]]; then
      while IFS= read -r -d '' lib_file; do
        if [[ -r "${lib_file}" ]] && source "${lib_file}" 2>/dev/null; then
          if declare -F "${func_name}" >/dev/null; then
            printf "%s[ DEBUG ]%s Executing library function\n" \
              "${RCLR_WHITE}" "${RCLR_RESET}" >&2
            printf "  Library: %s\n" "${lib_name}" >&2
            printf "  Function: %s\n" "${func_name}" >&2
            "${func_name}" "$@"
            return $?
          fi
        fi
      done < <(find "${lib_dir}" -maxdepth 1 -type f -name "*.sh" -print0)
    fi

    printf "%s[ ERROR ]%s Function not found in library\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    printf "  Library: %s\n" "${lib_name}" >&2
    printf "  Function: %s\n" "${func_name}" >&2
    printf "  Please check:\n" >&2
    printf "  - Function name is correct\n" >&2
    printf "  - Function is defined in the library\n" >&2
    printf "  - Library files are properly sourced\n" >&2
    return 1
  fi

  # Case 2: Check for commands in user level directory
  local -r cmd_path="${ROOTINE_COMMANDS_DIR}/${level}/${call}.sh"
  if [[ -f "${cmd_path}" ]] && [[ -r "${cmd_path}" ]]; then
    printf "%s[ DEBUG ]%s Executing command script\n" \
      "${RCLR_WHITE}" "${RCLR_RESET}" >&2
    printf "  Command: %s\n" "${call}" >&2
    printf "  Path: %s\n" "${cmd_path}" >&2
    declare -g ROOTINE_COMMAND_PATH="${cmd_path}"
    source "${cmd_path}" "$@"
    return $?
  fi

  # Case 3: Try direct library function call
  if _find_library_function "${call}" "${level}"; then
    printf "%s[ DEBUG ]%s Executing direct function call\n" \
      "${RCLR_WHITE}" "${RCLR_RESET}" >&2
    printf "  Function: %s\n" "${call}" >&2
    "${call}" "$@"
    return $?
  fi

  printf "%s[ ERROR ]%s Command or function not found\n" \
    "${RCLR_RED}" "${RCLR_RESET}" >&2
  printf "  Name: %s\n" "${call}" >&2
  printf "  User level: %s\n" "${level}" >&2
  printf "  Please check:\n" >&2
  printf "  - Command/function name is correct\n" >&2
  printf "  - You have the required permissions\n" >&2
  printf "  - Command exists in %s/%s/\n" "${ROOTINE_COMMANDS_DIR}" "${level}" >&2
  return 1
}

# --
# @description      Initializes the Rootine framework environment
# @param            Command line arguments passed to script
# @stdout           None
# @stderr           Status and error messages
# @exitstatus       0 Environment initialized successfully
#                   1 Initialization failed
# @global           Multiple framework-wide variables
# @sideeffects      - Sets up error and signal handlers
#                   - Sources library files
#                   - Creates utility directories
#                   - Validates environment
# @example          _init_environment "$@"
# @internal
# @security         - Validates command availability
#                   - Enforces sourcing requirement
#                   - Sets up proper error handling
# --
_init_environment() {
  local -i status

  trap 'status=$?; _error_handler "${BASH_SOURCE[0]}" "${LINENO}" "${status}"' ERR
  trap 'status=$?; _cleanup_handler; exit "${status}";' SIGHUP SIGINT SIGQUIT SIGTERM
  trap '_cleanup_handler' EXIT

  if ! is_sourced; then
    printf "%s[ ERROR ]%s Bootstrap must be sourced, not executed directly\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    return 1
  fi

  if ! is_command_available "date" "dirname" "lsb_release" "mkdir" "realpath" "uname"; then
    printf "%s[ ERROR ]%s Missing required system commands\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    return 1
  fi

  printf "%s[ DEBUG ]%s Initializing environment\n" \
    "${RCLR_WHITE}" "${RCLR_RESET}" >&2

  _populate_ubuntu_info

  local -r user_level="$(_get_user_level)"
  if ! _source_user_level_files "${user_level}"; then
    printf "%s[ ERROR ]%s Failed to source user level files\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    return 1
  fi

  if ! _validate_constants; then
    printf "%s[ ERROR ]%s Constants validation failed\n" \
      "${RCLR_RED}" "${RCLR_RESET}" >&2
    return 1
  fi

  ROOTINE_CLEANUP_DIRS+=("${ROOTINE_TMP_DIR}")

  printf "%s[ DEBUG ]%s Environment initialized successfully\n" \
    "${RCLR_WHITE}" "${RCLR_RESET}" >&2
  return 0
}

# --
# @description      Main initialization sequence
# @stdout           None
# @stderr           Error message if initialization fails
# @exitstatus       0 Initialization successful
#                   1 Initialization failed
# @note             This is the main entry point for the bootstrap process
# @security         Ensures clean exit on initialization failure
# --
if ! _init_environment "$@"; then
  printf "%s[ ERROR ]%s Environment initialization failed\n" \
    "${RCLR_RED}" "${RCLR_RESET}" >&2
  printf "  Please check previous error messages for details\n" >&2
  exit 1
fi
