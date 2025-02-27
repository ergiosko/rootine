#!/usr/bin/env bash

# ---
# @description      Removes Rootine configuration from system-wide bashrc and
#                   cleans up related settings
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Installation
# @dependencies     bash (v4+), grep, sed
# @configuration    No configuration needed. Script detects system bashrc
#                   location automatically.
# @arguments        None
# @param            None
# @envvar           EUID - Used to check if script is running with root privileges
# @stdin            None
# @stdout           None
# @stderr           Progress messages, error messages
# @file             /etc/bash.bashrc or /etc/bashrc - System-wide bashrc file
#                   to be modified
#                   /etc/bash.bashrc.rootine.bak or /etc/bashrc.rootine.bak -
#                   Backup of bashrc before modification
#                   /etc/bash.bashrc.tmp or /etc/bashrc.tmp - Temporary file
#                   created by sed (automatically removed)
# @exitstatus       0: Success - Uninstallation completed successfully
#                   1: Error conditions:
#                     - Script not run as root
#                     - System bashrc file not found
#                     - No write permissions for bashrc
#                     - Failed to create backup
#                     - Failed to remove configuration
# @return           None
# @global           ROOTINE_ETC_BASHRC_FILE - Path to system bashrc file
#                   ROOTINE_CODE_MARKER_START - Marker indicating start of
#                   rootine configuration
#                   ROOTINE_CODE_MARKER_END - Marker indicating end of
#                   rootine configuration
# @sideeffects      - Removes required utility directories
#                   - Creates backup of system bashrc file (.rootine.bak)
#                   - Modifies system bashrc by removing rootine configuration block
#                   - Removes global 'rootine' alias
#                   - Removes global IS_ROOTINE_INSTALLED variable
#                   - Creates and removes temporary sed file (.tmp)
# @example          sudo ./uninstall.sh
# @see              https://github.com/ergiosko/rootine/blob/main/install.sh
# @functions        None
# @security         - Requires root privileges to modify system files
#                   - Creates backup before modifying system files
#                   - Uses strict error handling (set -euf -o pipefail)
#                   - Verifies write permissions before modifications
#                   - Safely removes temporary files
# @todo             - Add option to restore from backup
# @note             This script is the counterpart to install.sh and removes all
#                   Rootine-related configurations from the system
# @internal         Uses marker-based block removal to ensure clean uninstallation
# ---

# Verify script is running with root privileges
if [[ ${EUID} -ne 0 ]]; then
  echo "[ ERROR ] This script must be run as root" >&2
  exit 1
fi

# Enable strict error handling
set -euf -o pipefail

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

# Remove required utility directories
ROOTINE_UTILITY_DIRECTORIES=(
  "/srv/backups/rootine"
  "/var/cache/rootine"
  "/var/log/rootine"
  "/var/run/rootine"
  "/tmp/rootine"
)

for dir in "${ROOTINE_UTILITY_DIRECTORIES[@]}"; do
  [[ ! -d "${dir}" ]] && continue

  if ! rm -rf "${dir}"; then
    printf "%s[ ERROR ]%s Failed to remove utility directory\n" \
      $'\e[0;31m' $'\e[0m' >&2
    printf "  Directory: %s\n" "${dir}" >&2
    printf "  Please check:\n" >&2
    printf "  - You have delete permissions\n" >&2
    printf "  - Parent directory exists\n" >&2
    return 1
  fi

  echo "[SUCCESS] ${dir} utility directory removed successfully" >&2
done

# Define markers for rootine configuration block
ROOTINE_CODE_MARKER_START="# -- Start Rootine Code --"
ROOTINE_CODE_MARKER_END="# -- End Rootine Code --"

# Remove rootine configuration if present
if grep -xsq "${ROOTINE_CODE_MARKER_START}" "${ROOTINE_ETC_BASHRC_FILE}" &>/dev/null; then
  # Create backup of original bashrc
  if ! cp "${ROOTINE_ETC_BASHRC_FILE}" "${ROOTINE_ETC_BASHRC_FILE}.rootine.bak"; then
    echo "[ ERROR ] Unable to create ${ROOTINE_ETC_BASHRC_FILE} backup file" >&2
    exit 1
  fi

  # Remove configuration block using sed
  if ! sed -i.tmp "/${ROOTINE_CODE_MARKER_START}/,/${ROOTINE_CODE_MARKER_END}/d" \
    "${ROOTINE_ETC_BASHRC_FILE}" &>/dev/null; then
    echo "[ ERROR ] Failed to remove Rootine configuration from ${ROOTINE_ETC_BASHRC_FILE}" >&2
    exit 1
  fi

  rm -f "${ROOTINE_ETC_BASHRC_FILE}.tmp"
  echo "[SUCCESS] Rootine uninstallation completed successfully" >&2
  echo "  Please reload your terminal window" >&2
else
  echo "[NOTICE ] No Rootine configuration found in ${ROOTINE_ETC_BASHRC_FILE}" >&2
fi
