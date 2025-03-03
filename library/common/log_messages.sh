#!/usr/bin/env bash

# ---
# @description      Provides standardized logging functionality with colored output
#                   and syslog integration
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Logging
# @dependencies     - Bash 5.0.0 or higher
#                   - date command
#                   - logger command (optional, for syslog integration)
# @configuration    Requires ROOTINE_LOG_LEVEL_* and ROOTINE_COLOR_* variables to be set
# @envvar           ROOTINE_LOG_LEVEL_DEFAULT Maximum log level to display
# @envvar           ROOTINE_COLOR_*           ANSI color codes for different log levels
# @stderr           All log messages are written to standard error
# @exitstatus       0 Success
#                   1 Invalid log level provided
# @functions        _get_syslog_priority  Maps log levels to syslog priorities
#                   _get_centered_label   Formats log level labels with consistent width
#                   _log_message          Core logging function
#                   log_debug             Wrapper for DEBUG level messages
#                   log_info              Wrapper for INFO level messages
#                   log_notice            Wrapper for NOTICE level messages
#                   log_success           Wrapper for SUCCESS level messages
#                   log_warning           Wrapper for WARNING level messages
#                   log_error             Wrapper for ERROR level messages
#                   log_crit              Wrapper for CRIT level messages
#                   log_alert             Wrapper for ALERT level messages
#                   log_emerg             Wrapper for EMERG level messages
# @security         No security considerations as this is an internal logging utility
# ---

is_sourced || exit 1

# --
# @description      Maps internal log levels to syslog priority levels
# @param {string}   level The log level to map (required)
# @return           Corresponding syslog priority as a string
# @exitstatus       0 Success (always)
# @example          _get_syslog_priority "ERROR"
#                   err
# @internal
# --
_get_syslog_priority() {
  local -r level="${1:?Log level parameter is required}"

  case "${level^^}" in
    DEBUG)          echo "debug" ;;
    INFO)           echo "info" ;;
    NOTICE)         echo "notice" ;;
    WARN | WARNING) echo "warning" ;;
    ERR | ERROR)    echo "err" ;;
    CRIT)           echo "crit" ;;
    ALERT)          echo "alert" ;;
    EMERG | PANIC)  echo "emerg" ;;
    *)              echo "debug" ;;
  esac

  return 0
}

# --
# @description      Creates a consistently formatted, centered log level label
# @param {string}   level The log level text to center (required)
# @return           9-character wide string with centered text in brackets
# @example          _get_centered_label "INFO"
#                   [ INFO  ]
# @internal
# --
_get_centered_label() {
  local -r level="${1:?Level parameter is required}"
  local -ir width=7 # 9 total width minus 2 brackets
  local -r level_text="${level^^}"
  local -ir text_length="${#level_text}"
  local -ir pad_total=$((width - text_length))
  local -ir pad_left=$((pad_total / 2))
  local -ir pad_right=$((pad_total - pad_left))

  printf "[%*s%s%*s]" "${pad_left}" "" "${level_text}" "${pad_right}" ""
  return 0
}

# --
# @description      Core logging function that formats and outputs log messages
# @param {string}   level   Log level (DEBUG|INFO|NOTICE|WARNING|ERROR|CRIT|ALERT|EMERG)
# @param {string}   message The message to log
# @stdout           None
# @stderr           Formatted log message if level <= ROOTINE_LOG_LEVEL_DEFAULT
# @sideeffects      May write to syslog if logger command is available
# @exitstatus       0 Success
#                   1 Invalid log level provided
# @example          _log_message "INFO" "System initialized"
#                   [ INFO  ] System initialized
# @internal
# --
_log_message() {
  local -r level="${1:?Log level parameter is required}"
  local -r message="${2:?Message parameter is required}"
  local log_level_num color syslog_priority timestamp syslog_message styled_message label

  case "${level^^}" in
    DEBUG)
      log_level_num="${ROOTINE_LOG_LEVEL_DEBUG}"
      color="${ROOTINE_COLOR_WHITE}"
      ;;
    INFO)
      log_level_num="${ROOTINE_LOG_LEVEL_INFO}"
      color="${ROOTINE_COLOR_CYAN}"
      ;;
    NOTICE | SUCCESS)
      log_level_num="${ROOTINE_LOG_LEVEL_NOTICE}"
      color="${ROOTINE_COLOR_GREEN}"
      ;;
    WARN | WARNING)
      log_level_num="${ROOTINE_LOG_LEVEL_WARNING}"
      color="${ROOTINE_COLOR_YELLOW}"
      ;;
    ERR | ERROR)
      log_level_num="${ROOTINE_LOG_LEVEL_ERROR}"
      color="${ROOTINE_COLOR_RED}"
      ;;
    CRIT)
      log_level_num="${ROOTINE_LOG_LEVEL_CRIT}"
      color="${ROOTINE_ITALIC_RED}"
      ;;
    ALERT)
      log_level_num="${ROOTINE_LOG_LEVEL_ALERT}"
      color="${ROOTINE_BOLD_RED}"
      ;;
    EMERG | PANIC)
      log_level_num="${ROOTINE_LOG_LEVEL_EMERG}"
      color="${ROOTINE_BG_RED}"
      ;;
    *)
      printf "[ ERROR ] Invalid log level: %s\n" "${level}" >&2
      return 1
      ;;
  esac

  if ((log_level_num <= ROOTINE_LOG_LEVEL_DEFAULT)); then
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    syslog_priority="$(_get_syslog_priority "${level}")"
    label="$(_get_centered_label "${level}")"
    syslog_message="${label} ${message}"
    styled_message="${color}${label}${ROOTINE_COLOR_RESET} ${message}"

    if command -v logger &>/dev/null; then
      logger -t "${0##*/}" -p "${syslog_priority}" "${syslog_message}" || return 0
    fi

    printf '%s\n' "${styled_message}" >&2
  fi

  return 0
}

# --
# @description      Public logging functions for different severity levels
# @param {string}   message The message to log (required)
# @stderr           Formatted log message
# @example          log_info "Starting initialization..."
# --
log_debug()   { _log_message "DEBUG"    "${1:?Message parameter is required}"; }
log_info()    { _log_message "INFO"     "${1:?Message parameter is required}"; }
log_notice()  { _log_message "NOTICE"   "${1:?Message parameter is required}"; }
log_success() { _log_message "SUCCESS"  "${1:?Message parameter is required}"; }
log_warning() { _log_message "WARNING"  "${1:?Message parameter is required}"; }
log_error()   { _log_message "ERROR"    "${1:?Message parameter is required}"; }
log_crit()    { _log_message "CRIT"     "${1:?Message parameter is required}"; }
log_alert()   { _log_message "ALERT"    "${1:?Message parameter is required}"; }
log_emerg()   { _log_message "EMERG"    "${1:?Message parameter is required}"; }
