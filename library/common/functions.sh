#!/usr/bin/env bash

# ---
# @description      Core utility functions library for the Rootine framework
#                   Provides essential functionality for variable inspection,
#                   string manipulation, system checks, and utility operations.
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Core Utilities
# @dependencies     - Bash 4.4.0 or higher
#                   - Core utilities: declare, printf, grep, awk, sed
#                   - Optional: mail (for email functionality)
#                   - Optional: dpkg-query (for package management)
#                   - Optional: ping, timeout (for network checks)
# @configuration    Environment variables:
#                   - ROOTINE_MAX_ARRAY_DEPTH_DEFAULT: Maximum recursion depth (default: 3)
#                   - ROOTINE_INDENT_WIDTH_DEFAULT: Default indentation width (default: 2)
#                   - ROOTINE_MIN_DISK_SPACE_MB: Minimum required disk space in MB (default: 10240)
#                   - ROOTINE_DISK_SPACE_PATHS: Array of paths to check for disk space
#                   - ROOTINE_IC_PING_HOST: Default host for connectivity check
#                   - ROOTINE_IC_PING_RETRIES: Number of connection retry attempts
#                   - ROOTINE_IC_PING_TIMEOUT: Connection timeout in seconds
# @functions        Public:
#                   - var_dump(): Debug variable inspection
#                   - trim_str(): String cleaning and escaping
#                   - alnum_str(): Alphanumeric string conversion
#                   - check_script_permissions(): File permission validation
#                   - is_package_installed(): Package installation verification
#                   - check_disk_space(): Disk space availability check
#                   - check_internet_connection(): Network connectivity test
#                   - send_email_message(): Email dispatch utility
#                   - show_help_info(): Help documentation display
# @security         - Input validation on all public functions
#                   - Secure handling of file operations
#                   - Email address validation
#                   - Protected against command injection
#                   - Safe handling of special characters
#                   - Controlled script permissions
# @example          # Source the library
#                   source "/path/to/functions.sh"
#
#                   # Variable inspection
#                   declare -A my_array=([key]="value")
#                   var_dump "my_array"
#
#                   # String manipulation
#                   cleaned_string=$(trim_str "  hello world  ")
#
#                   # System checks
#                   check_disk_space
#                   check_internet_connection
# ---

is_sourced || exit 1

# --
# @description      Prints variable attributes from declare output
# @param            $1 declare_output Output from declare -p command
# @param            $2 indent         Indentation string for formatting
# @stdout           Formatted list of variable attributes if any exist
# @exitstatus       0 Success
#                   2 Invalid number of parameters
# @internal
# --
_print_attributes() {
  if [[ $# -lt 2 ]]; then
    log_error "_print_attributes: requires 2 parameters, got $#"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  local -r declare_output="${1}"
  local -r indent="${2}"
  local -a attrs=()
  local -A attr_map=(
    ["declare -r"]="readonly"
    ["declare -x"]="export"
    ["declare -i"]="integer"
    ["declare -l"]="lowercase"
    ["declare -u"]="uppercase"
    ["declare -t"]="trace"
    ["declare -n"]="nameref"
    ["declare -a"]="array"
    ["declare -A"]="associative"
  )

  local attr
  for attr in "${!attr_map[@]}"; do
    [[ "${declare_output}" == *"${attr}"* ]] && attrs+=("${attr_map[${attr}]}")
  done

  [[ "${#attrs[@]}" -gt 0 ]] && printf "%sAttributes: %s\n" "${indent}" "${attrs[*]}"
  return 0
}

# --
# @description      Handles variable type detection and processing
# @param            $1 name       Variable name to process
# @param            $2 decl       Declaration string from declare -p
# @param            $3 max_depth  Maximum recursion depth
# @param            $4 depth      Current recursion depth
# @param            $5 indent     Indentation string
# @param            $6 width      Indentation width
# @exitstatus       0 Success
#                   2 Invalid number of parameters
#                   3 Invalid data
# @sideeffects      Calls appropriate dump function based on variable type
# @internal
# --
_handle_variable_type() {
  if [[ $# -lt 6 ]]; then
    log_error "_handle_variable_type: requires 6 parameters, got $#"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  local -r name="${1}"
  local -r decl="${2}"
  local -r max_depth="${3}"
  local -r depth="${4}"
  local -r indent="${5}"
  local -r width="${6}"

  if [[ -z "${name}" ]]; then
    log_error "_handle_variable_type: name parameter is empty"
    return "${ROOTINE_STATUS_DATAERR}"
  fi

  case "${decl}" in
    *"declare -a"*)
      _dump_indexed_array "${name}" "${max_depth}" "$((depth + 1))" "${indent}" "${width}"
      ;;
    *"declare -A"*)
      _dump_associative_array "${name}" "${max_depth}" "$((depth + 1))" "${indent}" "${width}"
      ;;
    *"declare -i"*)
      printf "%sinteger(%s) %s\n" "${indent}" "${name}" "${!name}"
      ;;
    *)
      _dump_scalar "${name}" "${indent}"
      ;;
  esac
  return 0
}

# --
# @description      Dumps contents of an indexed array with formatting
# @param            $1 name       Name of the array variable
# @param            $2 max_depth  Maximum recursion depth for nested arrays
# @param            $3 depth      Current recursion depth
# @param            $4 indent     Indentation string
# @param            $5 width      Indentation width for nested levels
# @stdout           Formatted array contents with type information
# @exitstatus       0 Success
#                   2 Invalid number of parameters
#                   4 Array not defined
# @dependencies     declare, printf
# @example          _dump_indexed_array "my_array" 3 0 "  " 2
# @internal
# --
_dump_indexed_array() {
  if [[ $# -lt 5 ]]; then
    log_error "_dump_indexed_array: requires 5 parameters, got $#"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  local -r name="${1}"
  local -r max_depth="${2}"
  local -r depth="${3}"
  local -r indent="${4}"
  local -r width="${5}"

  if ! declare -p "${name}" &>/dev/null; then
    log_error "_dump_indexed_array: array '${name}' is not defined"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi

  local -n ref="${name}"

  printf "%sarray(%d) {\n" "${indent}" "${#ref[@]}"
  local i
  for i in "${!ref[@]}"; do
    printf "%*s[%d] => " "$((depth * width))" "" "${i}"
    if _is_nested_var "ref[${i}]"; then
      var_dump "ref[${i}]" "${max_depth}" "${depth}" "${width}"
    else
      printf "string(%d) \"%s\"\n" "${#ref[$i]}" "${ref[$i]}"
    fi
  done
  printf "%s}\n" "${indent}"
  return 0
}

# --
# @description      Dumps contents of an associative array with formatting
# @param            $1 name       Name of the associative array variable
# @param            $2 max_depth  Maximum recursion depth for nested arrays
# @param            $3 depth      Current recursion depth
# @param            $4 indent     Indentation string
# @param            $5 width      Indentation width for nested levels
# @stdout           Formatted associative array contents with type information
# @exitstatus       0 Success
#                   2 Invalid number of parameters
#                   4 Array not defined
# @dependencies     declare, printf
# @example          _dump_associative_array "my_assoc" 3 0 "  " 2
# @internal
# --
_dump_associative_array() {
  if [[ $# -lt 5 ]]; then
    log_error "_dump_associative_array: requires 5 parameters, got $#"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  local -r name="${1}"
  local -r max_depth="${2}"
  local -r depth="${3}"
  local -r indent="${4}"
  local -r width="${5}"

  if ! declare -p "${name}" &>/dev/null; then
    log_error "_dump_associative_array: array '${name}' is not defined"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi

  local -n ref="${name}"

  printf "%sassoc(%d) {\n" "${indent}" "${#ref[@]}"
  local key
  for key in "${!ref[@]}"; do
    printf "%*s[\"%s\"] => " "$((depth * width))" "" "${key}"
    if _is_nested_var "ref[${key}]"; then
      var_dump "ref[${key}]" "${max_depth}" "${depth}" "${width}"
    else
      printf "string(%d) \"%s\"\n" "${#ref[$key]}" "${ref[$key]}"
    fi
  done
  printf "%s}\n" "${indent}"
  return 0
}

# --
# @description      Dumps a scalar variable with type information
# @param            $1 name   Name of the scalar variable
# @param            $2 indent Indentation string for formatting
# @stdout           Formatted scalar value with type information
# @exitstatus       0 Success
#                   2 Invalid number of parameters
#                   4 Variable not defined
# @dependencies     declare, printf
# @example          _dump_scalar "my_var" "  "
# @internal
# --
_dump_scalar() {
  if [[ $# -lt 2 ]]; then
    log_error "_dump_scalar: requires 2 parameters, got $#"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  local -r name="${1}"
  local -r indent="${2}"

  if ! declare -p "${name}" &>/dev/null; then
    log_error "_dump_scalar: variable '${name}' is not defined"
    return "${ROOTINE_STATUS_NOINPUT}"
  fi

  local -n ref="${name}"

  if [[ -z "${ref}" ]]; then
    printf "%sempty(0) \"\"\n" "${indent}"
  elif [[ "${ref}" =~ ^[[:digit:]]+$ ]]; then
    printf "%snumeric(%d) \"%s\"\n" "${indent}" "${#ref}" "${ref}"
  else
    printf "%sstring(%d) \"%s\"\n" "${indent}" "${#ref}" "${ref}"
  fi

  return 0
}

# --
# @description      Checks if a variable contains nested arrays
# @param            $1 var_name Name of the variable to check
# @stdout           None
# @exitstatus       0 Variable contains nested arrays
#                   1 Variable does not contain nested arrays
#                   2 Invalid number of parameters
#                   3 Invalid variable name
# @dependencies     declare, grep, command
# @example          _is_nested_var "my_array[0]"
# @internal
# --
_is_nested_var() {
  local var_name="${1}"
  local status=$?

  if [[ $# -ne 1 ]]; then
    log_error "_is_nested_var: requires 1 parameter, got $#"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  if [[ -z "${var_name}" ]]; then
    log_error "_is_nested_var: variable name is empty"
    return "${ROOTINE_STATUS_DATAERR}"
  fi

  if command -v "${var_name}" &>/dev/null; then
    if declare -p "${var_name}" 2>/dev/null | grep -q "declare -[aA]"; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

# --
# @description      Debug function to inspect variables and their contents
# @param            $1 var_name       Name of the variable to inspect
# @param            $2 max_depth      Maximum recursion depth (default: 3)
# @param            $3 current_depth  Current recursion depth (internal use)
# @param            $4 indent_width   Indentation width (default: 2)
# @param            $5 do_exit        Whether to exit after dump (default: 1)
# @stdout           Formatted variable content with type information
# @exitstatus       0 Success
#                   1 General error
#                   2 Invalid parameters
#                   4 Variable not accessible
# @envvar           ROOTINE_MAX_ARRAY_DEPTH_DEFAULT Maximum recursion depth
# @envvar           ROOTINE_INDENT_WIDTH_DEFAULT    Default indentation width
# @example          var_dump "my_variable" 2 0 4 0
# @sideeffects      May exit the script if do_exit is 1
# @public
# --
var_dump() {
  if [[ $# -lt 1 ]]; then
    log_error "Usage: var_dump VARIABLE [MAX_DEPTH] [INDENT_WIDTH]"
    return "${ROOTINE_STATUS_USAGE}"
  fi

  local -r var_name="${1}"
  local -ir max_depth="${2:-${ROOTINE_MAX_ARRAY_DEPTH_DEFAULT:-3}}"
  local -ir current_depth="${3:-0}"
  local -ir indent_width="${4:-${ROOTINE_INDENT_WIDTH_DEFAULT:-2}}"
  local -ir do_exit="${5:-1}"

  if ((max_depth < 0 || indent_width < 0)); then
    log_error "Invalid max_depth (${max_depth}) or indent_width (${indent_width})"
    return "${ROOTINE_STATUS_DATAERR}"
  fi

  if ((current_depth >= max_depth)); then
    printf "%*s*MAX DEPTH REACHED*\n" "$((current_depth * indent_width))" ""
    return 0
  fi

  if ! declare -p "${var_name}" &>/dev/null; then
    printf "%*sNULL\n" "$((current_depth * indent_width))" ""
    return 0
  fi

  local declare_output
  declare_output="$(declare -p "${var_name}")" || {
    log_error "Failed to get declaration for variable '${var_name}'"
    return "${ROOTINE_STATUS_NOINPUT}"
  }

  local indent_str
  indent_str="$(printf "%*s" "$((current_depth * indent_width))" "")"

  _print_attributes "${declare_output}" "${indent_str}"
  _handle_variable_type "${var_name}" "${declare_output}" "${max_depth}" \
    "${current_depth}" "${indent_str}" "${indent_width}"

  (( "${do_exit}" == 1 )) && exit 0

  return 0
}

# --
# @description      Trims and optionally escapes a string
# @param            $1 input_string String to process (required)
# @param            $2 escape_mode  Escaping mode [shell|string|none|raw] (default: shell)
# @param            $3 trim_spaces  Whether to trim spaces [true|false] (default: true)
# @stdout           Processed string
# @exitstatus       0 Success
#                   2 Missing required parameter or invalid escape mode
# @dependencies     sed, printf
# @example          trim_str "  hello world  " "string" "true"
# @security         Handles special characters safely
# @public
# --
trim_str() {
  local input_string="${1:?Error: Input string required}"
  local escape_mode="${2:-shell}"
  local trim_spaces="${3:-true}"
  local processed_string

  if [[ "${trim_spaces}" == "true" ]]; then
    processed_string="$(echo -e "${input_string}" | \
      sed -E 's/^[[:space:]]+|[[:space:]]+$//g; s/[[:space:]]+/ /g')"
  else
    processed_string="${input_string}"
  fi

  case "${escape_mode}" in
    shell)
      printf '%q' "${processed_string}"
      ;;
    string)
      printf '%s' "${processed_string}" | \
        sed 's/\\/\\\\/g; s/"/\\"/g; s/'\''/&\\&&/g; s/\$/\\\$/g'
      ;;
    none|raw)
      printf '%s' "${processed_string}"
      ;;
    *)
      log_error "Invalid escape mode: ${escape_mode}. Valid modes: [shell|string|none|raw]"
      return "${ROOTINE_STATUS_USAGE}"
      ;;
  esac
}

# --
# @description      Converts a string to alphanumeric format
# @param            $1 str Input string (optional)
# @stdout           Alphanumeric string with underscores replacing non-alphanumeric chars
# @exitstatus       0 Success
# @dependencies     tr
# @example          alnum_str "Hello, World! 123"
# @public
# --
alnum_str() {
  local str="${1:-}"

  str="$(printf "%s" "${str}" | tr -d '[:space:]' | tr -c '[:alnum:]' '_')"

  printf "%s" "${str}"
  return 0
}

# --
# @description      Validates script file permissions
# @param            $1 script_path Path to script (default: $0)
# @stdout           Success/error messages
# @stderr           Error details if validation fails
# @exitstatus       0 Valid permissions
#                   1 Invalid permissions or file not found
# @global           ROOTINE_VALID_FILE_PERMISSIONS Array of valid permission octals
# @dependencies     stat
# @example          check_script_permissions "/path/to/script.sh"
# @security         Ensures scripts have appropriate permissions
# @public
# --
check_script_permissions() {
  local -r script_path="${1:-$0}"

  [[ ! -f "${script_path}" ]] && {
    log_error "Script not found: ${script_path}"
    return 1
  }

  local file_perms_octal
  file_perms_octal=$(stat -c '%a' "${script_path}") || {
    log_error "Failed to get permissions for: ${script_path}"
    return 1
  }

  local valid_perm_found=false
  for perm in "${ROOTINE_VALID_FILE_PERMISSIONS[@]}"; do
    if (( file_perms_octal == perm )); then
      valid_perm_found=true
      break
    fi
  done

  if "$valid_perm_found"; then
    log_success "Script permissions valid for: ${script_path}"
    return 0
  else
    log_error "Invalid permissions ${file_perms_octal}. Must be one of: ${ROOTINE_VALID_FILE_PERMISSIONS[*]}"
    return 1
  fi
}

# --
# @description      Checks if a package is installed via dpkg
# @param            $1 package Package name to check (required)
# @stdout           None
# @stderr           Error message if package not installed
# @exitstatus       0 Package is installed
#                   1 Package is not installed
# @dependencies     dpkg-query
# @example          is_package_installed "nginx"
# @public
# --
is_package_installed() {
  local -r package="${1:?Package name is required}"

  if dpkg-query -W -f='${Status}' "${package}" &>/dev/null; then
    return 0
  else
    log_error "Package '${package}' is NOT installed"
    return 1
  fi
}

# --
# @description      Verifies available disk space in specified paths
# @stdout           None
# @stderr           Error messages if space requirements not met
# @exitstatus       0 Sufficient space available
#                   1 Insufficient space or error checking space
# @envvar           ROOTINE_MIN_DISK_SPACE_MB Minimum required space in MB (default: 10240)
# @envvar           ROOTINE_DISK_SPACE_PATHS  Array of paths to check (default: ["/usr" "/var"])
# @dependencies     df
# @example          check_disk_space
# @security         Validates paths before checking
# @public
# --
check_disk_space() {
  local -ir min_space_mb="${ROOTINE_MIN_DISK_SPACE_MB:-10240}"
  local -ir min_space_kb="$((min_space_mb * 1024))"
  local -a paths=("${ROOTINE_DISK_SPACE_PATHS[@]:-("/usr" "/var")}")
  local available_kb path

  for path in "${paths[@]}"; do
    if [[ ! -d "${path}" ]]; then
      log_error "Path not found: ${path}"
      return 1
    fi

    if ! available_kb=$(df -kP "${path}" 2>/dev/null | awk 'NR==2 {print $4}'); then
      log_error "Failed to determine available space for ${path}"
      return 1
    fi

    if [[ ! "${available_kb}" =~ ^[0-9]+$ ]]; then
      log_error "Invalid df output for ${path}: ${available_kb}"
      return 1
    fi

    if ((available_kb < min_space_kb)); then
      log_error "Insufficient space in ${path}. Need: ${min_space_mb}MB, Have: $((available_kb / 1024))MB"
      return 1
    fi
  done

  return 0
}

# --
# @description      Tests internet connectivity via ping
# @param            $1 host     Host to ping (default: 8.8.8.8)
# @param            $2 retries  Number of retry attempts (default: 3)
# @param            $3 timeout  Timeout in seconds per attempt (default: 5)
# @stdout           Status messages
# @stderr           Error messages if connection fails
# @exitstatus       0 Connection successful
#                   5 Connection failed or invalid parameters
# @envvar           ROOTINE_IC_PING_HOST    Default host to ping
# @envvar           ROOTINE_IC_PING_RETRIES Default number of retries
# @envvar           ROOTINE_IC_PING_TIMEOUT Default timeout in seconds
# @dependencies     ping, timeout
# @example          check_internet_connection "8.8.8.8" 3 5
# @security         Validates input parameters
# @public
# --
check_internet_connection() {
  local -r host="${1:-${ROOTINE_IC_PING_HOST:-8.8.8.8}}"
  local -r retries="${2:-${ROOTINE_IC_PING_RETRIES:-3}}"
  local -r timeout="${3:-${ROOTINE_IC_PING_TIMEOUT:-5}}"

  [[ ! "${retries}" =~ ^[1-9][0-9]*$ ]] && {
    log_error "Invalid retry count: ${retries} (must be a positive integer)"
    return "${ROOTINE_STATUS_NETWORK_ERROR}"
  }

  [[ ! "${timeout}" =~ ^[1-9][0-9]*$ ]] && {
    log_error "Invalid timeout value: ${timeout} (must be a positive integer)"
    return "${ROOTINE_STATUS_NETWORK_ERROR}"
  }

  log_info "Checking internet connection to ${host}..."
  local attempt
  for ((attempt = 1; attempt <= retries; attempt+=1)); do
    if timeout "${timeout}" ping -c 1 -W "${timeout}" "${host}" &>/dev/null; then
      log_success "Internet connection is active"
      return 0
    fi

    ((attempt < retries)) && {
      log_warning "Ping attempt ${attempt}/${retries} failed, retrying in 1s..."
      sleep 1
    }
  done

  log_error "No internet connection after ${retries} attempts"
  return "${ROOTINE_STATUS_NETWORK_ERROR}"
}

# --
# @description      Sends an email message using the mail command
# @param            $1 recipient  Email address of the recipient (required)
# @param            $2 subject    Subject of the email (required)
# @param            $3 message    Body of the email message (required)
# @stdout           Success message if email sent
# @stderr           Error messages if sending fails
# @exitstatus       0 Email sent successfully
#                   1 Failed to send email or invalid parameters
# @dependencies     mail (mailutils)
# @example          send_email_message "user@example.com" "Test Subject" "Test Message"
# @security         Validates email address format
# @public
# --
send_email_message() {
  local -r recipient="${1:?Recipient email address required}"
  local -r subject="${2:?Email subject required}"
  local -r message="${3:?Email message required}"

  is_command_available "mail" || {
    log_error "Required command 'mail' not found"
    log_info "Install using: sudo apt-get install mailutils"
    return 1
  }

  [[ ! "${recipient}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && {
    log_error "Invalid email address: ${recipient}"
    return 1
  }

  printf "%s" "${message}" | mail -s "${subject}" "${recipient}" || {
    log_error "Failed to send email to ${recipient}"
    return 1
  }

  log_success "Email sent to ${recipient}"
  return 0
}

# --
# @description      Displays script help information from header comments
# @param            $1 script_path Path to script file (default: $0)
# @stdout           Formatted help information
# @stderr           Error messages if help extraction fails
# @exitstatus       0 Help displayed successfully
#                   1 Failed to read script or extract help
# @envvar           ROOTINE_COMMAND_PATH  Default script path if not provided
# @dependencies     awk
# @example          show_help_info "./myscript.sh"
# @sideeffects      Exits the script after displaying help
# @public
# --
show_help_info() {
  local -r script_path="${1:-${ROOTINE_COMMAND_PATH:-$0}}"

  [[ ! -f "${script_path}" ]] && {
    log_error "Script not found: ${script_path}"
    exit 1
  }

  local header_comments
  header_comments=$(awk '
    /^$/ {
      empty_lines+=1
      if (empty_lines == 1) { next }
      else if (empty_lines == 2) { exit }
    }
    empty_lines == 1 && /^# ?/ {
      sub(/^# ?/, "")
      print
    }
  ' "${script_path}") || {
    log_error "Error extracting header comments from ${script_path}"
    exit 1
  }

  if [[ -n "${header_comments}" ]]; then
    printf "\n%s\n\n%s\n\n%s\n\n" \
      "${header_comments}" \
      "$(_show_common_args_help)" \
      "$(_show_script_args_help)"
  else
    log_warning "No help information found in ${script_path}"
  fi

  exit 0
}
