#!/usr/bin/env bash

# ---
# @description      Argument parsing system for the Rootine framework
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Core
# @dependencies     Bash 4.4.0 or higher
# @configuration    Requires ROOTINE_COMMON_ARGS to be defined with valid argument definitions
# @envvar           ROOTINE_COMMON_ARGS Associative array of common argument definitions
# @envvar           ROOTINE_SCRIPT_ARGS Associative array of script-specific argument definitions
# @stderr           Error messages for invalid arguments
# @exitstatus       0   Success
#                   64  Usage error (invalid arguments)
#                   1   Other errors
# @functions        _create_reverse_mapping Creates mapping from long to short options
#                   _get_arg_description    Gets description for an argument
#                   _arg_requires_value     Checks if argument requires a value
#                   _show_common_args_help  Displays help for common arguments
#                   _handle_common_args     Processes common arguments
#                   _validate_argument      Validates argument values against patterns
#                   _parse_arg_components   Parses argument definition components
#                   _process_long_arg       Processes long-format arguments
#                   _validate_required_args Validates required arguments are present
#                   _show_script_args_help  Displays help for script-specific arguments
#                   _handle_script_args     Processes script-specific arguments
#                   _handle_positional_args Processes positional arguments
#                   handle_args             Main argument handling function
# @security         - Validates all argument values
#                   - Prevents argument injection
#                   - Sanitizes variable names
# @todo             - Add support for grouped short options
#                   - Add validation for argument names
#                   - Add support for environment variable overrides
# ---

is_sourced || exit 1

# --
# @description      Creates a reverse mapping from long to short option names
# @global           ROOTINE_COMMON_ARGS_LONG_TO_SHORT Associative array storing long to short mappings
# @global           ROOTINE_COMMON_ARGS               Source array of argument definitions
# @exitstatus       0 Always succeeds
# @example          _create_reverse_mapping
#                   echo "${ROOTINE_COMMON_ARGS_LONG_TO_SHORT[help]}" # prints "h"
# @internal
# --
_create_reverse_mapping() {
  ROOTINE_COMMON_ARGS_LONG_TO_SHORT=()
  local short long

  for short in "${!ROOTINE_COMMON_ARGS[@]}"; do
    long="${ROOTINE_COMMON_ARGS[${short}]%%:*}"
    ROOTINE_COMMON_ARGS_LONG_TO_SHORT["${long}"]="${short}"
  done

  return 0
}

# --
# @description      Gets the description for a given argument
# @param {string}   arg The argument to get description for (can be short or long form)
# @stdout           The argument description or empty string if not found
# @exitstatus       0  Always succeeds
# @example          desc="$(_get_arg_description "h")"
#                   desc="$(_get_arg_description "--help")"
# @internal
# --
_get_arg_description() {
  local arg="${1:?Argument required}"
  local entry short

  if [[ ${#arg} -eq 1 ]]; then
    entry="${ROOTINE_COMMON_ARGS[$arg]:-}"
  else
    short="${ROOTINE_COMMON_ARGS_LONG_TO_SHORT[${arg#--}]:-}"
    entry="${ROOTINE_COMMON_ARGS[$short]:-}"
  fi

  if [[ -z "${entry}" ]]; then
    echo ""
    return 0
  fi

  local description
  description="${entry#*:}"
  description="${description%%:*}"

  echo "${description}"
  return 0
}

# --
# @description      Checks if an argument requires a value
# @param {string}   arg  The argument to check (can be short or long form)
# @exitstatus       0 Argument requires a value
#                   1 Argument does not require a value or not found
# @example          if _arg_requires_value "i"; then
#                     echo "Input file is required"
#                   fi
# @internal
# --
_arg_requires_value() {
  local arg="${1:?Argument required}"
  local entry short

  if [[ ${#arg} -eq 1 ]]; then
    entry="${ROOTINE_COMMON_ARGS[$arg]:-}"
  else
    short="${ROOTINE_COMMON_ARGS_LONG_TO_SHORT[${arg#--}]:-}"
    entry="${ROOTINE_COMMON_ARGS[$short]:-}"
  fi

  [[ -z "${entry}" ]] && return 1

  local requires_value="${entry##*:}"
  requires_value="${requires_value%%:*}"
  [[ "${requires_value}" -eq 1 ]] && return 0

  return 1
}

# --
# @description      Displays help information for common arguments
# @stdout           Formatted help text for all common arguments
# @exitstatus       0 Always succeeds
# @global           ROOTINE_COMMON_ARGS  Array of common argument definitions
# @example          _show_common_args_help
#                   # Output:
#                   # Common arguments:
#                   #   -h, --help          Show help information
#                   #   -v, --version       Show version information
# @internal
# --
_show_common_args_help() {
  printf "Common arguments:\n"
  local short long desc requires_value sorted_shorts
  sorted_shorts=$(printf "%s\n" "${!ROOTINE_COMMON_ARGS[@]}" | sort)

  while IFS= read -r short; do
    IFS=':' read -r long desc requires_value <<<"${ROOTINE_COMMON_ARGS[${short}]}"

    if [[ "${requires_value}" -eq 1 ]]; then
      printf "  -%s, --%-20s %s\n" "${short}" "${long} <value>" "${desc}"
    else
      printf "  -%s, --%-20s %s\n" "${short}" "${long}" "${desc}"
    fi
  done <<<"${sorted_shorts}"

  return 0
}

# --
# @description      Processes common command-line arguments
# @param            Command-line arguments to process
# @stdout           Version information if -v/--version specified
# @stderr           Error messages for invalid arguments
# @exitstatus       0   Success or help/version requested
#                   64  Usage error
# @global           ROOTINE_LOG_LEVEL_DEFAULT May be modified for debug mode
# @global           ROOTINE_COMMON_ARG_*      Set based on provided arguments
# @global           ROOTINE_REMAINING_ARGS    Set to unprocessed arguments
# @sideeffects      - May exit program (help/version)
#                   - Sets various ROOTINE_COMMON_ARG_* variables
# @example          _handle_common_args "-d" "--input" "file.txt"
# @internal
# --
_handle_common_args() {
  [[ $# -eq 0 ]] && return 0

  local arg_key arg_val short_name long_name entry

  while [[ $# -gt 0 ]]; do
    arg_key="$1"
    arg_val=""

    case "${arg_key}" in
      --*)
        long_name="${arg_key#--}"
        short_name="${ROOTINE_COMMON_ARGS_LONG_TO_SHORT[$long_name]:-}"
        [[ -z "${short_name}" ]] && break
        ;;
      -*)
        short_name="${arg_key#-}"
        entry="${ROOTINE_COMMON_ARGS[$short_name]:-}"
        [[ -z "${entry}" ]] && break
        ;;
      *)
        break
        ;;
    esac

    if _arg_requires_value "${short_name}"; then
      if [[ $# -lt 2 ]]; then
        log_error "Missing value for ${arg_key}"
        show_help_info
        return "${ROOTINE_STATUS_USAGE}"
      fi

      arg_val="$2"
      shift
    fi

    case "${short_name}" in
      d) ROOTINE_LOG_LEVEL_DEFAULT="${ROOTINE_LOG_LEVEL_DEBUG}" ;;
      h)
        show_help_info
        return 0
        ;;
      i) ROOTINE_COMMON_ARG_INPUT_FILE="${arg_val}" ;;
      l) ROOTINE_COMMON_ARG_LOG_FILE="${arg_val}" ;;
      o) ROOTINE_COMMON_ARG_OUTPUT_FILE="${arg_val}" ;;
      q) ROOTINE_COMMON_ARG_QUIET=1 ;;
      v)
        printf "Script version: %s\n" "${ROOTINE_VERSION:-ROOTINE_UNKNOWN}"
        exit 0
        ;;
    esac
    shift
  done

  ROOTINE_REMAINING_ARGS=("$@")
  return 0
}

# --
# @description      Validates an argument value against a pattern
# @param {string}   value   The value to validate
# @param {string}   pattern Regular expression pattern (optional)
# @exitstatus       0 Value matches pattern or no pattern provided
#                   1 Value does not match pattern
# @example          _validate_argument "123" "^[0-9]+$"
# @internal
# @security         Ensures argument values match expected formats
# --
_validate_argument() {
  local value="${1:?Value required}"
  local pattern="${2:-}"

  [[ -z "${pattern}" ]] && return 0
  [[ "${value}" =~ ^${pattern}$ ]] && return 0

  return 1
}

# --
# @description      Parses components of an argument definition
# @param {string}   arg Name of the argument to parse
# @stdout           Semicolon-separated string of components:
#                   description;requires_value;default_value;pattern
# @exitstatus       0 Success
#                   1 Argument not found in ROOTINE_SCRIPT_ARGS
# @global           ROOTINE_SCRIPT_ARGS Array of script argument definitions
# @example          components="$(_parse_arg_components "input-file")"
# @internal
# --
_parse_arg_components() {
  local arg="${1:?Argument name required}"
  local entry="${ROOTINE_SCRIPT_ARGS[$arg]:-}"

  if [[ -z "${entry}" ]]; then
    log_error "Argument '${arg}' not found in ROOTINE_SCRIPT_ARGS"
    return 1
  fi

  local description requires_value default_value pattern
  description=$(echo "${entry}" | cut -d':' -f1)
  requires_value=$(echo "${entry}" | cut -d':' -f2)
  default_value=$(echo "${entry}" | cut -d':' -f3)
  pattern=$(echo "${entry}" | cut -d':' -f4)

  printf "%s;%s;%s;%s" \
    "${description}" "${requires_value}" "${default_value}" "${pattern}"
  return 0
}

# --
# @description      Processes a long-format command line argument
# @param {string}   arg_key   The argument key (including --)
# @param {array}    args_ref  Reference to array of remaining arguments
# @stderr           Error messages for invalid arguments
# @exitstatus       0   Success
#                   64  Usage error
#                   1   Unknown option
# @global           Sets SCRIPT_ARG_* variables based on arguments
# @sideeffects      - Modifies the referenced args array
#                   - Creates global variables
# @security         - Sanitizes variable names
#                   - Validates argument values
# @internal
# --
_process_long_arg() {
  local arg_key="${1:?Argument key required}"
  local -n args_ref="${2:?Args reference required}"
  local long_name="${arg_key#--}"

  if [[ -n "${ROOTINE_SCRIPT_ARGS[$long_name]:-}" ]]; then
    local components requires_value pattern
    components=$(_parse_arg_components "${long_name}") || return "${ROOTINE_STATUS_USAGE}"
    requires_value=$(cut -d';' -f2 <<<"${components}")
    pattern=$(cut -d';' -f4 <<<"${components}")
    local safe_name="${long_name//[^a-zA-Z0-9_]/_}"

    if [[ "${requires_value}" -eq 1 ]]; then
      if [[ ${#args_ref[@]} -lt 2 ]]; then
        log_error "Missing value for ${arg_key}"
        _show_script_args_help
        return "${ROOTINE_STATUS_USAGE}"
      fi

      local arg_val="${args_ref[1]}"

      if ! _validate_argument "${arg_val}" "${pattern}"; then
        log_error "Invalid value for ${arg_key}: ${arg_val}"
        _show_script_args_help
        return "${ROOTINE_STATUS_USAGE}"
      fi

      declare -g "SCRIPT_ARG_${safe_name^^}"="${arg_val}"
    else
      declare -g "SCRIPT_ARG_${safe_name^^}"="true"
    fi

    args_ref=("${args_ref[@]:1}")
  elif [[ -n "${ROOTINE_COMMON_ARGS_LONG_TO_SHORT[$long_name]:-}" ]]; then
    log_error "Common argument ${long_name} used in script-specific section. Use short option."
    _show_script_args_help
    return "${ROOTINE_STATUS_USAGE}"
  else
    log_error "Unknown option: ${arg_key}"
    _show_script_args_help
    return 1
  fi

  return 0
}

# --
# @description      Validates that all required arguments are provided
# @stderr           Error messages for missing required arguments
# @exitstatus       0   All required arguments present
#                   64  Missing required arguments
# @global           Reads SCRIPT_ARG_* variables
# @example          _validate_required_args || exit $?
# @internal
# --
_validate_required_args() {
  local arg components description requires_value var_name

  for arg in "${!ROOTINE_SCRIPT_ARGS[@]}"; do
    components=$(_parse_arg_components "${arg}") || continue
    description=$(cut -d';' -f1 <<<"${components}")
    requires_value=$(cut -d';' -f2 <<<"${components}")
    arg="$(alnum_str "${arg}")"
    var_name="SCRIPT_ARG_${arg^^}"

    if [[ "${requires_value}" == "1" && -z "${!var_name:-}" ]]; then
      log_error "Required argument missing: --${arg} (${description})"
      return "${ROOTINE_STATUS_USAGE}"
    fi
  done

  return 0
}

# --
# @description      Displays help information for script-specific arguments
# @stdout           Formatted help text for all script arguments
# @global           ROOTINE_SCRIPT_ARGS Array of script argument definitions
# @example          _show_script_args_help
# @internal
# --
_show_script_args_help() {
  printf "Script-specific arguments:\n"
  local arg components description requires_value default_value

  for arg in "${!ROOTINE_SCRIPT_ARGS[@]}"; do
    components=$(_parse_arg_components "${arg}") || continue
    description=$(cut -d';' -f1 <<<"${components}")
    requires_value=$(cut -d';' -f2 <<<"${components}")
    default_value=$(cut -d';' -f3 <<<"${components}")

    local arg_string="--${arg}"
    [[ "${requires_value}" == "1" ]] && arg_string+=" <value>"

    local default_string=""
    [[ -n "${default_value}" ]] && default_string=" (default: ${default_value})"

    printf "  %-26s %s%s\n" "${arg_string}" "${description}" "${default_string}"
  done

  return 0
}

# --
# @description      Processes script-specific arguments
# @stdout           None
# @stderr           Error messages for invalid arguments
# @exitstatus       0   Success
#                   64  Usage error
# @global           ROOTINE_REMAINING_ARGS  Array of remaining arguments to process
# @sideeffects      - Sets default values for arguments
#                   - Creates SCRIPT_ARG_* variables
# @security         Validates all argument values against patterns
# @internal
# --
_handle_script_args() {
  local -a args=("${ROOTINE_REMAINING_ARGS[@]}")
  local arg components default_value

  for arg in "${!ROOTINE_SCRIPT_ARGS[@]}"; do
    components=$(_parse_arg_components "${arg}") || continue
    default_value=$(cut -d';' -f3 <<<"${components}")

    if [[ -n "${default_value}" ]]; then
      arg="$(alnum_str "${arg}")"
      declare -g SCRIPT_ARG_"${arg^^}"="${default_value}"
    fi
  done

  local arg_key
  while [[ ${#args[@]} -gt 0 ]]; do
    arg_key="${args[0]}"

    case "${arg_key}" in
      --*)
        _process_long_arg "${arg_key}" args || return $?
        ;;
      -*)
        log_error "Short options not supported for script args: ${arg_key}"
        _show_script_args_help
        return "${ROOTINE_STATUS_USAGE}"
        ;;
      *)
        args=("${args[@]:1}")
        ;;
    esac
  done

  _validate_required_args || return $?

  return 0
}

# --
# @description      Handles positional arguments
# @param            List of positional arguments
# @exitstatus       0 Always succeeds
# @global           Creates SCRIPT_POS_ARG_* variables
# @example          _handle_positional_args "file1" "file2"
#                   echo "${SCRIPT_POS_ARG_1}"  # prints "file1"
# @internal
# --
_handle_positional_args() {
  local -a positional_args=("$@")
  local i=1

  for arg in "${positional_args[@]}"; do
    declare -g "SCRIPT_POS_ARG_${i}=${arg}"
    ((i += 1))
  done

  return 0
}

# --
# @description      Main argument handling function
# @param            Command line arguments to process
# @stderr           Error messages for invalid arguments
# @exitstatus       0   Success
#                   64  Usage error
# @global           Multiple ROOTINE_* and SCRIPT_* variables
# @example          handle_args "$@"
# @public
# --
handle_args() {
  _handle_common_args "$@" || return $?
  _handle_script_args || return $?

  if [[ ${#ROOTINE_REMAINING_ARGS[@]} -gt 0 ]]; then
    _handle_positional_args "${ROOTINE_REMAINING_ARGS[@]}"
    return $?
  fi

  return 0
}

# Initialize argument handling
_create_reverse_mapping

if [[ ${#ROOTINE_COMMON_ARGS[@]} -eq 0 ]]; then
  log_error "ROOTINE_COMMON_ARGS not initialized."
  exit "${ROOTINE_STATUS_USAGE}"
fi
