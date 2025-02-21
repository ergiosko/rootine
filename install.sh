#!/usr/bin/env bash

# ---
# @description      Installs Rootine by configuring system-wide bashrc and
#                   setting up necessary aliases
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Installation
# @dependencies     bash (v4+), grep, realpath
# @configuration    No configuration needed. Script detects system bashrc
#                   location automatically.
# @arguments        None
# @param            None
# @envvar           EUID - Used to check if script is running with root privileges
# @stdin            None
# @stdout           None
# @stderr           Progress messages, error messages
# @file             /etc/bash.bashrc or /etc/bashrc - System-wide bashrc file
#                   that gets modified
#                   /etc/bash.bashrc.rootine.bak or /etc/bashrc.rootine.bak -
#                   Backup of original bashrc
# @exitstatus       0: Success - Installation completed successfully
#                   1: Error conditions:
#                     - Script not run as root
#                     - Rootine executable not found
#                     - System bashrc file not found
#                     - No write permissions for bashrc
#                     - Failed to create backup
#                     - Failed to update bashrc
# @return           None
# @global           ROOTINE_CURRENT_WORKING_DIR - Absolute path to rootine
#                   installation directory
#                   ROOTINE_ETC_BASHRC_FILE - Path to system bashrc file
#                   ROOTINE_CODE_MARKER_START - Marker indicating start of
#                   rootine configuration
#                   ROOTINE_CODE_MARKER_END - Marker indicating end of rootine
#                   configuration
# @sideeffects      - Creates backup of system bashrc file (.rootine.bak)
#                   - Modifies system bashrc to include rootine configuration
#                   - Sets up global 'rootine' alias
#                   - Creates global IS_ROOTINE_INSTALLED variable
# @example          sudo ./install.sh
# @see              https://github.com/ergiosko/rootine
# @functions        None
# @security         - Requires root privileges to modify system files
#                   - Creates backup before modifying system files
#                   - Uses strict error handling (set -euf -o pipefail)
#                   - Verifies write permissions before modifications
# @todo             - Add verification of rootine executable integrity
# @note             The script automatically detects the appropriate system-wide
#                   bashrc location between /etc/bash.bashrc and /etc/bashrc
# ---

# Verify script is running with root privileges
if [[ $EUID -ne 0 ]]; then
  echo "[ ERROR ] This script must be run as root" >&2
  exit 1
fi

# Enable strict error handling
set -euf -o pipefail

# Verify rootine executable exists in current directory
if [[ ! -f "rootine" ]]; then
  echo "[ ERROR ] 'rootine' file not found in current directory" >&2
  exit 1
fi

# Get absolute path of rootine directory
ROOTINE_CURRENT_WORKING_DIR="$(realpath -- "$(dirname -- rootine)")" &>/dev/null

# Determine system-wide bashrc location
ROOTINE_ETC_BASHRC_FILE="/etc/bash.bashrc"
[[ ! -f "${ROOTINE_ETC_BASHRC_FILE}" ]] && ROOTINE_ETC_BASHRC_FILE="/etc/bashrc"
[[ ! -f "${ROOTINE_ETC_BASHRC_FILE}" ]] && {
  echo "[ ERROR ] No global bashrc file found" >&2
  exit 1
}

# Verify write permissions for bashrc file
if [[ ! -w "${ROOTINE_ETC_BASHRC_FILE}" ]]; then
  echo "[ ERROR ] No write permission for ${ROOTINE_ETC_BASHRC_FILE}" >&2
  exit 1
fi

# Define markers for rootine configuration block
ROOTINE_CODE_MARKER_START="# -- Start Rootine Code --"
ROOTINE_CODE_MARKER_END="# -- End Rootine Code --"

# Add rootine configuration if not already present
if ! grep -xsq "${ROOTINE_CODE_MARKER_START}" "${ROOTINE_ETC_BASHRC_FILE}" &>/dev/null; then
  # Create backup of original bashrc
  if ! cp "${ROOTINE_ETC_BASHRC_FILE}" "${ROOTINE_ETC_BASHRC_FILE}.rootine.bak"; then
    echo "[ ERROR ] Unable to create ${ROOTINE_ETC_BASHRC_FILE} backup file" >&2
    exit 1
  fi

  # Configuration content
  ROOTINE_CONFIG_BLOCK=$(
    cat <<EOF

${ROOTINE_CODE_MARKER_START}
if [[ -f "${ROOTINE_CURRENT_WORKING_DIR}/rootine" ]]; then
  alias rootine="${ROOTINE_CURRENT_WORKING_DIR}/rootine"
  declare -gix IS_ROOTINE_INSTALLED=1
fi
${ROOTINE_CODE_MARKER_END}
EOF
  )

  # Append the configuration to the file
  if ! echo "$ROOTINE_CONFIG_BLOCK" >>"${ROOTINE_ETC_BASHRC_FILE}"; then
    echo "[ ERROR ] Failed to update ${ROOTINE_ETC_BASHRC_FILE}" >&2
    exit 1
  fi

  echo "[SUCCESS] Rootine installation completed successfully" >&2
  echo "  Please reload your terminal window" >&2
else
  echo "[NOTICE ] Rootine configuration already exists in ${ROOTINE_ETC_BASHRC_FILE}" >&2
fi
