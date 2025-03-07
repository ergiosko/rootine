#!/usr/bin/env bash

# ---
# @description      Defines global constants for the Rootine framework
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Configuration
# @dependencies     Bash 5.0.0 or higher
# @configuration    Constants can be overridden by setting them before sourcing this file
# @global           Defines numerous global constants used throughout the framework
# @security         - All constants are read-only (readonly or integer readonly)
#                   - File permissions are strictly defined
#                   - System paths follow security best practices
# @note             This file must be sourced, not executed directly
# ---

is_sourced || exit 1

# System Requirements
declare -gir ROOTINE_MIN_MEMORY_MB=2048                   # Minimum required memory in MB
declare -gir ROOTINE_MIN_DISK_SPACE_MB=10240              # Minimum required disk space in MB
declare -gar ROOTINE_DISK_SPACE_PATHS=("/usr" "/var")     # Paths to check for disk space
declare -gar ROOTINE_VALID_FILE_PERMISSIONS=("700" "755") # Valid file permission modes

# System Paths
declare -gr ROOTINE_BACKUPS_DIR="/srv/backups/rootine"  # Directory for backups
declare -gr ROOTINE_CACHE_DIR="/var/cache/rootine"      # Directory for cache data
declare -gr ROOTINE_LOGS_DIR="/var/log/rootine"         # Directory for logs
declare -gr ROOTINE_RUNTIME_DIR="/var/run/rootine"      # Directory runtime files and locks
declare -gr ROOTINE_TMP_DIR="/tmp/rootine"              # Directory for temporary files

# Internet Connectivity Check Settings
declare -gr ROOTINE_IC_PING_HOST="8.8.8.8"  # Host to ping for connectivity check
declare -gir ROOTINE_IC_PING_RETRIES=3      # Number of ping retry attempts
declare -gir ROOTINE_IC_PING_TIMEOUT=5      # Ping timeout in seconds

# --
# @description      Exit status codes following sysexits.h conventions
# @see              https://man.openbsd.org/sysexits.3
# --
declare -gir ROOTINE_STATUS_SUCCESS=0               # Successful completion
declare -gir ROOTINE_STATUS_FAILURE=1               # General failure
declare -gir ROOTINE_STATUS_BUILTIN_ERROR=2         # Built-in command error

# Command Line Interface Status Codes
declare -gir ROOTINE_STATUS_USAGE=64                # Command line usage error
declare -gir ROOTINE_STATUS_DATAERR=65              # Data format error
declare -gir ROOTINE_STATUS_NOINPUT=66              # Cannot open input
declare -gir ROOTINE_STATUS_NOUSER=67               # Addressee unknown
declare -gir ROOTINE_STATUS_NOHOST=68               # Host name unknown
declare -gir ROOTINE_STATUS_UNAVAILABLE=69          # Service unavailable

# System Status Codes
declare -gir ROOTINE_STATUS_SOFTWARE=70             # Internal software error
declare -gir ROOTINE_STATUS_OSERR=71                # System error
declare -gir ROOTINE_STATUS_OSFILE=72               # Critical OS file missing
declare -gir ROOTINE_STATUS_CANTCREAT=73            # Can't create output file
declare -gir ROOTINE_STATUS_IOERR=74                # Input/output error
declare -gir ROOTINE_STATUS_TEMPFAIL=75             # Temporary failure
declare -gir ROOTINE_STATUS_PROTOCOL=76             # Remote error in protocol
declare -gir ROOTINE_STATUS_NOPERM=77               # Permission denied
declare -gir ROOTINE_STATUS_CONFIG=78               # Configuration error

# Package Management Status Codes
declare -gir ROOTINE_STATUS_PACKAGE_ERROR=80        # General package error
declare -gir ROOTINE_STATUS_DEPENDENCY_ERROR=81     # Package dependency error
declare -gir ROOTINE_STATUS_DISK_SPACE=82           # Insufficient disk space
declare -gir ROOTINE_STATUS_PACKAGE_CONFLICT=83     # Package conflict
declare -gir ROOTINE_STATUS_PACKAGE_CORRUPT=84      # Package corrupt

# Network Status Codes
declare -gir ROOTINE_STATUS_NETWORK_ERROR=90        # General network error
declare -gir ROOTINE_STATUS_NETWORK_TIMEOUT=91      # Network timeout
declare -gir ROOTINE_STATUS_NETWORK_UNREACHABLE=92  # Network unreachable
declare -gir ROOTINE_STATUS_SSL_ERROR=93            # SSL/TLS error
declare -gir ROOTINE_STATUS_DNS_ERROR=94            # DNS resolution error

# Runtime Status Codes
declare -gir ROOTINE_STATUS_RUNTIME_ERROR=100       # Runtime error
declare -gir ROOTINE_STATUS_TIMEOUT=124             # Command timed out
declare -gir ROOTINE_STATUS_NOT_EXECUTABLE=126      # Command not executable
declare -gir ROOTINE_STATUS_COMMAND_NOT_FOUND=127   # Command not found
declare -gir ROOTINE_STATUS_INVALID_EXIT=128        # Invalid exit code
declare -gir ROOTINE_STATUS_TERMINATED=130          # Script terminated

# --
# @description      Log levels following syslog conventions
# @see              https://en.wikipedia.org/wiki/Syslog#Severity_level
# --
declare -gir ROOTINE_LOG_LEVEL_EMERG=0    # System is unusable
declare -gir ROOTINE_LOG_LEVEL_PANIC=0    # Alias for EMERG
declare -gir ROOTINE_LOG_LEVEL_ALERT=1    # Action must be taken immediately
declare -gir ROOTINE_LOG_LEVEL_CRIT=2     # Critical conditions
declare -gir ROOTINE_LOG_LEVEL_ERR=3      # Error conditions
declare -gir ROOTINE_LOG_LEVEL_ERROR=3    # Alias for ERR
declare -gir ROOTINE_LOG_LEVEL_WARNING=4  # Warning conditions
declare -gir ROOTINE_LOG_LEVEL_WARN=4     # Alias for WARNING
declare -gir ROOTINE_LOG_LEVEL_NOTICE=5   # Normal but significant condition
declare -gir ROOTINE_LOG_LEVEL_INFO=6     # Informational messages
declare -gir ROOTINE_LOG_LEVEL_DEBUG=7    # Debug-level messages

# Log Level Configuration
declare -gi ROOTINE_LOG_LEVEL_DEFAULT="${ROOTINE_LOG_LEVEL_DEFAULT:-${ROOTINE_LOG_LEVEL_DEBUG}}"
declare -gir ROOTINE_LOG_LEVEL_MAX="${ROOTINE_LOG_LEVEL_DEBUG}"
declare -gir ROOTINE_LOG_LEVEL_APPEND="${ROOTINE_LOG_LEVEL_DEFAULT:-${ROOTINE_LOG_LEVEL_DEBUG}}" # Append log level

# --
# @description      ANSI color and style definitions for terminal output
# @see              https://en.wikipedia.org/wiki/ANSI_escape_code
# --
# Regular Colors
declare -gr ROOTINE_COLOR_BLACK=$'\e[0;30m'
declare -gr ROOTINE_COLOR_RED=$'\e[0;31m'
declare -gr ROOTINE_COLOR_GREEN=$'\e[0;32m'
declare -gr ROOTINE_COLOR_YELLOW=$'\e[0;33m'
declare -gr ROOTINE_COLOR_BLUE=$'\e[0;34m'
declare -gr ROOTINE_COLOR_MAGENTA=$'\e[0;35m'
declare -gr ROOTINE_COLOR_CYAN=$'\e[0;36m'
declare -gr ROOTINE_COLOR_WHITE=$'\e[0;37m'
declare -gr ROOTINE_COLOR_DEFAULT=$'\e[0;39m'

# Bold Colors
declare -gr ROOTINE_BOLD_BLACK=$'\e[1;30m'
declare -gr ROOTINE_BOLD_RED=$'\e[1;31m'
declare -gr ROOTINE_BOLD_GREEN=$'\e[1;32m'
declare -gr ROOTINE_BOLD_YELLOW=$'\e[1;33m'
declare -gr ROOTINE_BOLD_BLUE=$'\e[1;34m'
declare -gr ROOTINE_BOLD_MAGENTA=$'\e[1;35m'
declare -gr ROOTINE_BOLD_CYAN=$'\e[1;36m'
declare -gr ROOTINE_BOLD_WHITE=$'\e[1;37m'
declare -gr ROOTINE_BOLD_DEFAULT=$'\e[1;39m'

# Italic Colors
declare -gr ROOTINE_ITALIC_BLACK=$'\e[3;30m'
declare -gr ROOTINE_ITALIC_RED=$'\e[3;31m'
declare -gr ROOTINE_ITALIC_GREEN=$'\e[3;32m'
declare -gr ROOTINE_ITALIC_YELLOW=$'\e[3;33m'
declare -gr ROOTINE_ITALIC_BLUE=$'\e[3;34m'
declare -gr ROOTINE_ITALIC_MAGENTA=$'\e[3;35m'
declare -gr ROOTINE_ITALIC_CYAN=$'\e[3;36m'
declare -gr ROOTINE_ITALIC_WHITE=$'\e[3;37m'
declare -gr ROOTINE_ITALIC_DEFAULT=$'\e[3;39m'

# Background Colors
declare -gr ROOTINE_BG_BLACK=$'\e[40m'
declare -gr ROOTINE_BG_RED=$'\e[41m'
declare -gr ROOTINE_BG_GREEN=$'\e[42m'
declare -gr ROOTINE_BG_YELLOW=$'\e[43m'
declare -gr ROOTINE_BG_BLUE=$'\e[44m'
declare -gr ROOTINE_BG_MAGENTA=$'\e[45m'
declare -gr ROOTINE_BG_CYAN=$'\e[46m'
declare -gr ROOTINE_BG_WHITE=$'\e[47m'
declare -gr ROOTINE_BG_DEFAULT=$'\e[49m'

# Style Reset Codes
declare -gr ROOTINE_STYLE_RESET=$'\e[0m'
declare -gr ROOTINE_COLOR_RESET="${ROOTINE_STYLE_RESET}"
declare -gr ROOTINE_BOLD_RESET=$'\e[22m'
declare -gr ROOTINE_ITALIC_RESET=$'\e[23m'
declare -gr ROOTINE_BG_RESET=$'\e[49m'

# Message Style Definitions
declare -gr ROOTINE_ERROR_STYLE="${ROOTINE_BOLD_RED}"
declare -gr ROOTINE_WARNING_STYLE="${ROOTINE_BOLD_YELLOW}"
declare -gr ROOTINE_SUCCESS_STYLE="${ROOTINE_BOLD_GREEN}"
declare -gr ROOTINE_INFO_STYLE="${ROOTINE_BOLD_CYAN}"

# Array and Formatting Settings
declare -gir ROOTINE_MAX_ARRAY_DEPTH_DEFAULT=3
declare -gir ROOTINE_INDENT_WIDTH_DEFAULT=2

# --
# @description      Common command line argument definitions
# @note             Format: [short_opt]="long_opt:description:requires_value"
# --
declare -gAr ROOTINE_COMMON_ARGS=(
  [d]="debug:Enable debug mode:0"
  [h]="help:Show help information:0"
  [i]="input:Specify input file:1"
  [l]="log:Specify log file:1"
  [o]="output:Specify output file:1"
  [q]="quiet:Enable quiet mode:0"
  [v]="version:Show version information:0"
)

# Common Argument Variables
declare -g ROOTINE_COMMON_ARG_INPUT_FILE=""
declare -g ROOTINE_COMMON_ARG_LOG_FILE=""
declare -g ROOTINE_COMMON_ARG_OUTPUT_FILE=""
declare -g ROOTINE_COMMON_ARG_QUIET=""

# Argument Processing Arrays
declare -gA ROOTINE_COMMON_ARGS_LONG_TO_SHORT=()
declare -ga ROOTINE_REMAINING_ARGS=()
declare -gA ROOTINE_SCRIPT_ARGS=()

# Git Configuration Defaults
declare -gr ROOTINE_GIT_USER_EMAIL=""
declare -gr ROOTINE_GIT_USER_NAME=""
declare -gr ROOTINE_GIT_CORE_FILEMODE="false"
declare -gr ROOTINE_GIT_DEFAULT_REMOTE="origin"
declare -gr ROOTINE_GIT_DEFAULT_BRANCH="main"     # Default branch name [develop|main]
declare -gr ROOTINE_GIT_WORKING_BRANCH="develop"  # Working branch name [develop|main]

# --
# @description      Documentation style definitions and comment styles
# --
declare -gar ROOTINE_COMMENT_STYLES=("//" "#" ";" "--" "!" "%")

# --
# @description      Documentation style definitions and tags
# @format           ["@tag"]="Display Name" # Description and usage guidelines
# --
declare -gAr ROOTINE_COMMENT_TAGS=(
  # Essential Documentation (Required)
  ["@description"]="Description"        # Brief, one-line summary of the component (required)
  ["@version"]="Version"                # Current version using semantic versioning (required)
  ["@since"]="Since"                    # Version when component was first introduced (required)

  # Authorship and License (Required)
  ["@author"]="Author"                  # Primary author/maintainer with contact (required)
  ["@copyright"]="Copyright"            # Copyright holder information (required)
  ["@license"]="License"                # License type (e.g., MIT, GPL) (required)

  # Classification and Status
  ["@category"]="Category"              # Component category (Core|User|System|Network)
  ["@public"]="Public"                  # Marks as intended for external use
  ["@internal"]="Internal"              # Marks as internal implementation detail
  ["@deprecated"]="Deprecated"          # Marks as deprecated with reason and alternative

  # Input/Output Specification
  ["@param"]="Parameter"                # Describes positional parameter: {type} name description
  ["@arguments"]="Arguments"            # Lists expected command-line arguments
  ["@stdin"]="Standard Input"           # Describes expected standard input format
  ["@stdout"]="Standard Output"         # Describes standard output format
  ["@stderr"]="Standard Error"          # Describes error output format
  ["@return"]="Return"                  # Describes return value or output format
  ["@exitstatus"]="Exit Status"         # Lists possible exit status codes and meanings

  # Data Format and Validation
  ["@format"]="Format"                  # Defines data structure or format specification
  ["@validation"]="Validation"          # Lists validation rules and constraints

  # Dependencies and Environment
  ["@dependencies"]="Dependencies"      # Lists required dependencies and versions
  ["@envvar"]="Environment"             # Documents environment variables used
  ["@global"]="Global"                  # Documents global variables used/modified
  ["@configuration"]="Configuration"    # Describes configuration requirements

  # File Operations and Side Effects
  ["@file"]="File"                      # Documents file operations and permissions
  ["@sideeffects"]="Side Effects"       # Lists side effects beyond return values

  # References and Examples
  ["@usage"]="Usage"                    # Command syntax and invocation patterns
  ["@example"]="Example"                # Provides usage examples with code
  ["@see"]="See Also"                   # References related components or docs
  ["@functions"]="Functions"            # Lists available functions in script

  # Security and Implementation Notes
  ["@security"]="Security"              # Documents security considerations
  ["@note"]="Note"                      # Additional implementation notes
  ["@todo"]="Todo"                      # Planned improvements or changes

  # Documentation Control
  ["@ignore"]="Ignore"                  # Excludes section from documentation
)
