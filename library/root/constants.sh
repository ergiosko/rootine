#!/usr/bin/env bash

# ---
# @description      Defines root-level constants for system administration tasks
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         System Administration
# @dependencies     Bash 4.4.0 or higher
# @configuration    Requires root privileges
# @envvar           ROOTINE_APT_UPDATE_RETRIES  Number of retries for apt updates
# @envvar           ROOTINE_APT_DPKG_LOCK_TIMEOUT  Timeout for dpkg locks
# @security         - All constants are read-only
#                   - System paths follow security best practices
#                   - APT operations enforce secure defaults
# @note             This file must be sourced with root privileges
# ---

is_sourced || exit 1

# --
# @description      System information field definitions for system monitoring
# @note             Fields marked with 1 are enabled for collection
# --
declare -gAr ROOTINE_SYS_INFO_FIELDS=(
  [arch]=1          [cpu]=1           [cpu_cores]=1     [cpu_freq]=1
  [disk_usage]=1    [free_disk]=1     [free_mem]=1      [free_swap]=1
  [gpu]=1           [gpu_count]=1     [hostname]=1      [interfaces]=1
  [ip]=1            [kernel]=1        [load]=1          [locale]=1
  [os]=1            [os_version]=1    [processes]=1     [services]=1
  [total_disk]=1    [total_mem]=1     [total_swap]=1    [uptime]=1
  [used_disk]=1     [used_mem]=1      [used_swap]=1     [users]=1
)
declare -gir ROOTINE_SYS_INFO_CACHE_DURATION=300

# --
# @description      Snap package management configuration
# @dependencies     snapd
# --
declare -gr ROOTINE_SNAP_STORE="snap-store" # Snap store package name
declare -gir ROOTINE_SNAP_KILL_TIMEOUT=30   # Timeout for killing snap processes
declare -gir ROOTINE_SNAP_REFRESH_RETRIES=3 # Number of refresh retry attempts
declare -gir ROOTINE_SNAP_REFRESH_DELAY=5   # Delay between retries in seconds

# --
# @description      APT package management configuration
# @dependencies     apt, dpkg
# @security         - Enforces secure repository settings
#                   - Disables insecure repositories
#                   - Requires authentication
# --
declare -gr ROOTINE_APT_KEYRINGS_DIR="/etc/apt/keyrings"            # Repository keyrings directory
declare -gr ROOTINE_APT_SOURCES_LIST_DIR="/etc/apt/sources.list.d"  # Repository sources directory
declare -gr ROOTINE_APT_LOCK_FILE="/var/lib/dpkg/lock-frontend"     # APT lock file path
declare -gir ROOTINE_APT_DPKG_LOCK_TIMEOUT=60                       # Maximum wait time for dpkg lock
declare -gir ROOTINE_APT_UPDATE_RETRIES=3                           # Number of update retry attempts
declare -gir ROOTINE_APT_COMMAND_TIMEOUT=300                        # Command execution timeout
declare -gir ROOTINE_APT_QUIET_MODE=0                               # Quiet mode flag

# --
# @description      APT command options with secure defaults
# @note             Options enforce:
#                     - No insecure repositories
#                     - Required authentication
#                     - Automatic conflict resolution
#                     - Retry handling
#                     - Lock timeouts
# --
declare -gAr ROOTINE_APT_COMMAND_OPTIONS=(
  ["update"]="--no-allow-insecure-repositories -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["upgrade"]="-y --with-new-pkgs -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["dist-upgrade"]="-y -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["dselect-upgrade"]="-y -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["install"]="-y -f --auto-remove -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["reinstall"]="-y -f --auto-remove -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["remove"]="-y --auto-remove -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["purge"]="-y --auto-remove -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["source"]="-f -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["build-dep"]="-y -f -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["satisfy"]="-y -f -o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["check"]="-o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["download"]="-o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["clean"]="-o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["autoclean"]="-o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["auto-clean"]="-o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["autoremove"]="-y -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["auto-remove"]="-y -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["changelog"]="-o Acquire::Retries=${ROOTINE_APT_UPDATE_RETRIES} -o APT::Get::AllowUnauthenticated=false -o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
  ["indextargets"]="-o DPkg::Lock::Timeout=${ROOTINE_APT_DPKG_LOCK_TIMEOUT}"
)

# --
# @description      Apache2 server configuration paths
# @dependencies     apache2
# --
declare -gr ROOTINE_APACHE2_CLOUDFLARE_DIR="/etc/apache2/cloudflare"  # CloudFlare configuration directory
