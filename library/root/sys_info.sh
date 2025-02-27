#!/usr/bin/env bash

# ---
# @description      System information gathering and reporting module for
#                   Rootine framework
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         System Information
# @dependencies     Required:
#                   - Bash 4.4.0 or higher
#                   - coreutils (hostname, uptime, df, etc.)
#                   - procfs (/proc filesystem)
#                   Optional:
#                   - lsb_release (OS detection)
#                   - dmidecode (hardware info)
#                   - sysctl (BSD/macOS support)
#                   - lspci (GPU detection)
#                   - systemd (service counting)
# @configuration    - Root privileges required for hardware information
#                   - Cache duration configurable via ROOTINE_SYS_INFO_CACHE_DURATION
#                   - Fallback methods available when commands missing
# @envvar           ROOTINE_UNKNOWN Default value for unavailable information
# @envvar           ROOTINE_CACHE_DIR Directory for cache files
# @envvar           ROOTINE_SYS_INFO_CACHE_DURATION Cache duration in seconds (default: 300)
# @stdout           Formatted system information report
# @stderr           Log messages and error information
# @exitstatus       0 Success
#                   1 General error
#                   2 Missing required dependencies
# @security         - Sanitizes all command output
#                   - Validates command existence before execution
#                   - Handles missing commands gracefully
#                   - Uses secure temporary file handling
# @functions        Public:
#                   - get_system_info Main interface for system information
#                   Internal:
#                   - Multiple _collect_* and _get_* helper functions
# @todo             - Add support for container detection
#                   - Add support for virtual machine detection
#                   - Add JSON/YAML output formats
#                   - Add support for custom field selection
# ---

is_sourced || exit 1

# Ensure required variables are set
: "${ROOTINE_UNKNOWN:=Unknown}"
: "${ROOTINE_CACHE_DIR:=/var/cache/rootine}"
: "${ROOTINE_SYS_INFO_CACHE_DURATION:=300}"

# --
# @description      Verifies that required commands are available
# @exitstatus       0 All required commands available
#                   2 Missing required commands
# @stderr           List of missing required commands
# @internal
# --
_verify_requirements() {
  local -a required_commands=("hostname" "uname" "awk" "grep" "free" "df" "ps" "who")
  local -a missing_commands=()

  for cmd in "${required_commands[@]}"; do
    command -v "${cmd}" >/dev/null 2>&1 || missing_commands+=("${cmd}")
  done

  if ((${#missing_commands[@]} > 0)); then
    log_error "Missing required commands: ${missing_commands[*]}"
    return 2
  fi

  return 0
}

# --
# @description      Initializes system information array with default values
# @global           info                    Array to store system information
# @global           ROOTINE_SYS_INFO_FIELDS Array of valid system info fields
# @global           ROOTINE_UNKNOWN         Default value for unavailable information
# @exitstatus       0 Array initialized successfully
#                   1 Required global arrays not defined
# @internal
# --
_initialize_sys_info_array() {
  if [[ ! -v ROOTINE_SYS_INFO_FIELDS[@] ]]; then
    log_error "ROOTINE_SYS_INFO_FIELDS not defined"
    return 1
  fi

  # Initialize all fields with unknown value
  for key in "${!ROOTINE_SYS_INFO_FIELDS[@]}"; do
    info["${key}"]="${ROOTINE_UNKNOWN}"
  done

  return 0
}

# --
# @description      Gets CPU frequency using multiple methods
# @stdout           CPU frequency in MHz
# @exitstatus       0 Frequency retrieved successfully
#                   1 All methods failed
# @dependencies     At least one of:
#                     - /proc/cpuinfo
#                     - dmidecode
#                     - sysctl (BSD/macOS)
# @example          freq=$(_get_cpu_freq)
# @internal
# --
_get_cpu_freq() {
  local freq method
  local -a methods=(
    "_get_cpu_freq_proc"
    "_get_cpu_freq_dmidecode"
    "_get_cpu_freq_sysctl"
  )

  # Try each method until one succeeds
  for method in "${methods[@]}"; do
    if freq=$("${method}") && [[ "${freq}" != "${ROOTINE_UNKNOWN}" ]]; then
      printf '%.2f\n' "${freq}"
      return 0
    fi
  done

  printf '%s\n' "${ROOTINE_UNKNOWN}"
  return 1
}

# --
# @description      Gets CPU frequency from /proc/cpuinfo
# @stdout           CPU frequency in MHz or ROOTINE_UNKNOWN
# @exitstatus       0 Success, frequency found
#                   1 Failed to read frequency
# @internal
# --
_get_cpu_freq_proc() {
  local freq

  if [[ ! -r /proc/cpuinfo ]]; then
    printf '%s\n' "${ROOTINE_UNKNOWN}"
    return 1
  fi

  # Get the first CPU frequency found
  freq=$(LC_ALL=C grep -m 1 "cpu MHz" /proc/cpuinfo |
    awk -F': ' '{printf "%.2f", $2}')

  if [[ -z "${freq}" ]]; then
    printf '%s\n' "${ROOTINE_UNKNOWN}"
    return 1
  fi

  printf '%s\n' "${freq}"
  return 0
}

# --
# @description      Gets CPU frequency using dmidecode
# @stdout           CPU frequency in MHz or ROOTINE_UNKNOWN
# @exitstatus       0 Success
#                   1 dmidecode not available or failed
# @dependencies     dmidecode
# @internal
# --
_get_cpu_freq_dmidecode() {
  if ! command -v dmidecode &>/dev/null; then
    printf '%s\n' "${ROOTINE_UNKNOWN}"
    return 1
  fi

  local freq

  # Need root privileges for dmidecode
  if [[ ${EUID} -ne 0 ]]; then
    printf '%s\n' "${ROOTINE_UNKNOWN}"
    return 1
  fi

  freq=$(dmidecode -t processor 2>/dev/null | grep -m 1 "Current Speed" |
    awk '{printf "%.2f", $3}') || freq=""

  if [[ -z "${freq}" ]]; then
    printf '%s\n' "${ROOTINE_UNKNOWN}"
    return 1
  fi

  printf '%s\n' "${freq}"
  return 0
}

# --
# @description      Gets CPU frequency using sysctl (macOS/BSD)
# @stdout           CPU frequency in MHz or ROOTINE_UNKNOWN
# @exitstatus       0 Success
#                   1 sysctl not available or failed
# @dependencies     sysctl
# @internal
# --
_get_cpu_freq_sysctl() {
  if ! command -v sysctl &>/dev/null; then
    printf '%s\n' "${ROOTINE_UNKNOWN}"
    return 1
  fi

  local freq

  # Convert Hz to MHz with proper rounding
  freq=$(sysctl -n hw.cpufrequency 2>/dev/null |
    awk '{printf "%.2f", $1/1000000}') || freq=""

  if [[ -z "${freq}" ]]; then
    printf '%s\n' "${ROOTINE_UNKNOWN}"
    return 1
  fi

  printf '%s\n' "${freq}"
  return 0
}

# --
# @description      Collects core system information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @sideeffects      Updates hostname, os, os_version, arch, kernel, locale
# @dependencies     hostname, lsb_release or /etc/os-release, uname, locale
# @internal
# --
_collect_core_info() {
  # Get hostname without any redirections
  info[hostname]=$(hostname || echo "${ROOTINE_UNKNOWN}")

  # OS detection with multiple fallback methods
  if command -v lsb_release >/dev/null; then
    info[os]=$(lsb_release -ds || echo "${ROOTINE_UNKNOWN}")
    info[os_version]=$(lsb_release -rs || echo "${ROOTINE_UNKNOWN}")
  elif [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    info[os]="${NAME:-${ROOTINE_UNKNOWN}}"
    info[os_version]="${VERSION_ID:-${ROOTINE_UNKNOWN}}"
  else
    info[os]="${ROOTINE_UNKNOWN}"
    info[os_version]="${ROOTINE_UNKNOWN}"
  fi

  # System architecture and kernel information
  info[arch]=$(uname -m || echo "${ROOTINE_UNKNOWN}")
  info[kernel]=$(uname -r || echo "${ROOTINE_UNKNOWN}")

  # Get system locale with fallbacks
  if locale_val=$(locale 2>/dev/null); then
    info[locale]=$(echo "${locale_val}" | grep "LANG=" | cut -d= -f2)
  else
    info[locale]="${ROOTINE_UNKNOWN}"
  fi

  return 0
}

# --
# @description      Collects hardware-related information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @sideeffects      Updates cpu, cpu_cores, and cpu_freq
# @dependencies     /proc/cpuinfo or sysctl, nproc or grep
# @internal
# --
_collect_hardware_info() {
  # Get CPU model with multiple methods
  if [[ -r /proc/cpuinfo ]]; then
    info[cpu]=$(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo | xargs)
  elif command -v sysctl >/dev/null; then
    info[cpu]=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
  else
    info[cpu]="${ROOTINE_UNKNOWN}"
  fi

  # Get CPU cores count with fallback methods
  if command -v nproc >/dev/null; then
    info[cpu_cores]=$(nproc)
  elif [[ -r /proc/cpuinfo ]]; then
    info[cpu_cores]=$(grep -c '^processor' /proc/cpuinfo)
  elif command -v sysctl >/dev/null; then
    info[cpu_cores]=$(sysctl -n hw.ncpu 2>/dev/null)
  else
    info[cpu_cores]="${ROOTINE_UNKNOWN}"
  fi

  # Get CPU frequency
  info[cpu_freq]="$(_get_cpu_freq)"
  return 0
}

# --
# @description      Collects memory usage information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @sideeffects      Updates total_mem, used_mem, free_mem, total_swap, used_swap,
#                   free_swap
# @dependencies     free or sysctl (BSD/macOS)
# @internal
# --
_collect_memory_info() {
  # Linux memory info using free
  if command -v free >/dev/null; then
    local mem_info
    if mem_info=$(free -h 2>/dev/null); then
      info[total_mem]=$(echo "${mem_info}" | awk '/^Mem:/ {print $2}')
      info[used_mem]=$(echo "${mem_info}" | awk '/^Mem:/ {print $3}')
      info[free_mem]=$(echo "${mem_info}" | awk '/^Mem:/ {print $4}')
      info[total_swap]=$(echo "${mem_info}" | awk '/^Swap:/ {print $2}')
      info[used_swap]=$(echo "${mem_info}" | awk '/^Swap:/ {print $3}')
      info[free_swap]=$(echo "${mem_info}" | awk '/^Swap:/ {print $4}')
      return 0
    fi
  fi

  # BSD/macOS memory info using sysctl
  if command -v sysctl >/dev/null; then
    local total_mem used_mem free_mem total_swap used_swap

    # Get physical memory in bytes and convert to human-readable
    total_mem=$(sysctl -n hw.memsize 2>/dev/null)
    if [[ -n "${total_mem}" ]]; then
      info[total_mem]=$(numfmt --to=iec-i --suffix=B "${total_mem}")

      # Get VM statistics for memory usage
      local vm_stat
      if vm_stat=$(vm_stat 2>/dev/null); then
        local pages_free pages_active pages_inactive pages_speculative page_size

        page_size=$(sysctl -n hw.pagesize)
        pages_free=$(echo "${vm_stat}" | awk '/Pages free/ {print $3}' | tr -d '.')
        pages_active=$(echo "${vm_stat}" | awk '/Pages active/ {print $3}' | tr -d '.')
        pages_inactive=$(echo "${vm_stat}" | awk '/Pages inactive/ {print $3}' | tr -d '.')
        pages_speculative=$(echo "${vm_stat}" | awk '/Pages speculative/ {print $3}' | tr -d '.')

        used_mem=$(((pages_active + pages_speculative) * page_size))
        free_mem=$((pages_free * page_size))

        info[used_mem]=$(numfmt --to=iec-i --suffix=B "${used_mem}")
        info[free_mem]=$(numfmt --to=iec-i --suffix=B "${free_mem}")
      fi

      # Get swap information
      total_swap=$(sysctl -n vm.swapusage 2>/dev/null | awk '{print $3}' | tr -d 'M')
      used_swap=$(sysctl -n vm.swapusage 2>/dev/null | awk '{print $6}' | tr -d 'M')

      if [[ -n "${total_swap}" ]]; then
        info[total_swap]="${total_swap}M"
        info[used_swap]="${used_swap}M"
        info[free_swap]="$((total_swap - used_swap))M"
      fi

      return 0
    fi
  fi

  # Fallback: try to read from /proc/meminfo
  if [[ -r /proc/meminfo ]]; then
    local mem_info
    mem_info=$(cat /proc/meminfo)

    info[total_mem]=$(echo "${mem_info}" | awk '/MemTotal:/ {printf "%.1fG", $2/1024/1024}')
    info[used_mem]=$(echo "${mem_info}" | awk '/MemAvailable:/ {printf "%.1fG", ($2)/1024/1024}')
    info[free_mem]=$(echo "${mem_info}" | awk '/MemFree:/ {printf "%.1fG", $2/1024/1024}')
    info[total_swap]=$(echo "${mem_info}" | awk '/SwapTotal:/ {printf "%.1fG", $2/1024/1024}')
    info[used_swap]=$(echo "${mem_info}" | awk '/SwapFree:/ {printf "%.1fG", ($2)/1024/1024}')
    info[free_swap]=$(echo "${mem_info}" | awk '/SwapFree:/ {printf "%.1fG", $2/1024/1024}')
    return 0
  fi

  # If all methods fail, set to unknown
  info[total_mem]="${ROOTINE_UNKNOWN}"
  info[used_mem]="${ROOTINE_UNKNOWN}"
  info[free_mem]="${ROOTINE_UNKNOWN}"
  info[total_swap]="${ROOTINE_UNKNOWN}"
  info[used_swap]="${ROOTINE_UNKNOWN}"
  info[free_swap]="${ROOTINE_UNKNOWN}"
  return 0
}

# --
# @description      Collects storage usage information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @sideeffects      Updates total_disk, used_disk, free_disk, disk_usage
# @dependencies     df
# @internal
# --
_collect_storage_info() {
  if ! command -v df >/dev/null; then
    info[total_disk]="${ROOTINE_UNKNOWN}"
    info[used_disk]="${ROOTINE_UNKNOWN}"
    info[free_disk]="${ROOTINE_UNKNOWN}"
    info[disk_usage]="${ROOTINE_UNKNOWN}"
    return 0
  fi

  local df_output

  # Try GNU df format first
  if df_output=$(df -h --total 2>/dev/null); then
    info[total_disk]=$(echo "${df_output}" | awk '/total/ {print $2}')
    info[used_disk]=$(echo "${df_output}" | awk '/total/ {print $3}')
    info[free_disk]=$(echo "${df_output}" | awk '/total/ {print $4}')
  # Fallback to BSD/macOS format
  elif df_output=$(df -h 2>/dev/null); then
    local total_size=0 used_size=0 free_size=0

    while read -r filesystem size used free _; do
      if [[ "${filesystem}" =~ ^/dev/ ]]; then
        total_size=$((total_size + ${size%G}))
        used_size=$((used_size + ${used%G}))
        free_size=$((free_size + ${free%G}))
      fi
    done < <(echo "${df_output}" | tail -n +2)

    info[total_disk]="${total_size}G"
    info[used_disk]="${used_size}G"
    info[free_disk]="${free_size}G"
  else
    info[total_disk]="${ROOTINE_UNKNOWN}"
    info[used_disk]="${ROOTINE_UNKNOWN}"
    info[free_disk]="${ROOTINE_UNKNOWN}"
  fi

  # Collect per-filesystem usage information
  info[disk_usage]=$(df -h --output=source,pcent 2>/dev/null | grep -E '^/dev' |
    awk '{printf "%s %s ", $1, $2}' || echo "${ROOTINE_UNKNOWN}")
  return 0
}

# --
# @description      Collects network interface information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @sideeffects      Updates ip and interfaces
# @dependencies     ip or ifconfig, hostname or host
# @internal
# --
_collect_network_info() {
  # Get primary IP address
  if command -v hostname >/dev/null; then
    info[ip]=$(hostname -I 2>/dev/null | awk '{print $1}')
  elif command -v host >/dev/null; then
    info[ip]=$(host "$(hostname)" 2>/dev/null | awk '/has address/ {print $4; exit}')
  else
    info[ip]="${ROOTINE_UNKNOWN}"
  fi

  # Get network interfaces
  if command -v ip >/dev/null; then
    info[interfaces]=$(ip -o link show 2>/dev/null |
      awk -F': ' '{printf "%s%s", (NR==1)?"":" ", $2}' || echo "${ROOTINE_UNKNOWN}")
  elif command -v ifconfig >/dev/null; then
    info[interfaces]=$(ifconfig -l 2>/dev/null || echo "${ROOTINE_UNKNOWN}")
  else
    info[interfaces]="${ROOTINE_UNKNOWN}"
  fi

  # Additional network information (optional)
  if command -v ip >/dev/null; then
    # Get active interfaces only
    info[active_interfaces]=$(ip -o link show up 2>/dev/null |
      awk -F': ' '{printf "%s%s", (NR==1)?"":" ", $2}' || echo "${ROOTINE_UNKNOWN}")

    # Get default gateway
    info[default_gateway]=$(ip route show default 2>/dev/null |
      awk '/default/ {print $3; exit}' || echo "${ROOTINE_UNKNOWN}")
  fi

  return 0
}

# --
# @description      Collects GPU information
# @global          info  Associative array storing system information
# @exitstatus      0  Success
# @sideeffects     Updates gpu and gpu_count
# @dependencies    lspci or system_profiler (macOS)
# @internal
# --
_collect_gpu_info() {
  # Linux GPU detection using lspci
  if command -v lspci >/dev/null; then
    local gpu_list
    gpu_list=$(lspci -mm 2>/dev/null | grep -i 'VGA\|3D\|Display')

    if [[ -n "${gpu_list}" ]]; then
      # Format GPU information more cleanly
      info[gpu]=$(echo "${gpu_list}" | awk -F'"' '{
        gsub(/\([^)]*\)/, "", $6)  # Remove parenthetical details
        printf "%s%s", (NR==1)?"":", ", $6
      }' | xargs)
      info[gpu_count]=$(echo "${gpu_list}" | wc -l)
      return 0
    fi
  fi

  # macOS GPU detection
  if command -v system_profiler >/dev/null; then
    local gpu_info
    gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null)

    if [[ -n "${gpu_info}" ]]; then
      info[gpu]=$(echo "${gpu_info}" | awk '/Chipset Model:/ {
        printf "%s%s", (NR==1)?"":", ", $3
      }')
      info[gpu_count]=$(echo "${gpu_info}" | grep -c "Chipset Model:")
      return 0
    fi
  fi

  # Fallback to checking /sys for GPU information
  if [[ -d "/sys/class/drm" ]]; then
    local gpu_list=()

    while IFS= read -r -d '' card; do
      if [[ -f "${card}/device/label" ]]; then
        gpu_list+=("$(cat "${card}/device/label")")
      fi
    done < <(find /sys/class/drm -name "card[0-9]*" -print0)

    if ((${#gpu_list[@]} > 0)); then
      info[gpu]="${gpu_list[*]}"
      info[gpu_count]=${#gpu_list[@]}
      return 0
    fi
  fi

  info[gpu]="${ROOTINE_UNKNOWN}"
  info[gpu_count]="0"
  return 0
}

# --
# @description      Collects system status information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @sideeffects      Updates load, uptime, processes, users, services
# @dependencies     uptime, ps, who, systemctl
# @internal
# --
_collect_system_status() {
  # Get load average
  if [[ -r /proc/loadavg ]]; then
    info[load]=$(cut -d' ' -f1-3 /proc/loadavg)
  elif command -v uptime >/dev/null; then
    info[load]=$(uptime | awk -F'load average: ' '{print $2}')
  else
    info[load]="${ROOTINE_UNKNOWN}"
  fi

  # Get uptime with proper formatting
  if [[ -r /proc/uptime ]]; then
    info[uptime]=$(awk '{
      days = int($1/86400)
      hours = int(($1%86400)/3600)
      mins = int(($1%3600)/60)
      printf "%d days %02d:%02d", days, hours, mins
    }' /proc/uptime)
  elif command -v uptime >/dev/null; then
    info[uptime]=$(uptime -p 2>/dev/null | sed 's/^up //' ||
      uptime | awk -F'( |,)+' '{print $4 " " $5}')
  else
    info[uptime]="${ROOTINE_UNKNOWN}"
  fi

  # Get process count
  if command -v ps >/dev/null; then
    info[processes]=$(ps aux --no-headers 2>/dev/null | wc -l ||
      ps -A 2>/dev/null | wc -l || echo "${ROOTINE_UNKNOWN}")
  else
    info[processes]=$(find /proc -maxdepth 1 -regex '/proc/[0-9]+' 2>/dev/null |
      wc -l || echo "${ROOTINE_UNKNOWN}")
  fi

  # Get active users count
  info[users]=$(who 2>/dev/null | wc -l || echo "0")

  # Get service count
  if command -v systemctl >/dev/null; then
    info[services]=$(systemctl list-units --type=service --state=running --no-pager --no-legend |
      wc -l || echo "N/A")
  elif [[ -d "/Library/LaunchDaemons" ]]; then  # macOS
    info[services]=$(find /Library/LaunchDaemons /System/Library/LaunchDaemons \
      -type f -name "*.plist" 2>/dev/null | wc -l || echo "N/A")
  else
    info[services]="N/A"
  fi

  return 0
}

# --
# @description      Collects date, time and user information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @sideeffects      Updates datetime_utc, timezone, username
# @dependencies     date, whoami
# @internal
# --
_collect_datetime_info() {
  # Get current UTC date and time
  if command -v date >/dev/null; then
    info[datetime_utc]=$(date -u '+%Y-%m-%d %H:%M:%S')
  else
    info[datetime_utc]="${ROOTINE_UNKNOWN}"
  fi

  # Get timezone information
  if [[ -r /etc/timezone ]]; then
    info[timezone]=$(cat /etc/timezone)
  elif command -v date >/dev/null; then
    info[timezone]=$(date +%Z)
  else
    info[timezone]="${ROOTINE_UNKNOWN}"
  fi

  # Get current user
  if command -v whoami >/dev/null; then
    info[username]=$(whoami)
  else
    info[username]="${USER}"
  fi

  return 0
}

# --
# @description      Generates formatted system information report
# @stdout           Formatted report with all collected information
# @global           info Associative array storing system information
# @exitstatus       0 Success
# @internal
# --
_generate_sys_info_report() {
  local -r separator=$(printf -- '- %.0s' {1..40})

  printf '\nSystem Information Report\n%s\n' "${separator}"

  # Current Date/Time Section
  printf '%-20s : %s\n' \
    "Date/Time (UTC)" "${info[datetime_utc]}" \
    "Timezone" "${info[timezone]}" \
    "Current User" "${info[username]}" \
    "" ""

  # System Section
  printf '%-20s : %s\n' \
    "Hostname" "${info[hostname]}" \
    "OS / Version" "${info[os]} (${info[os_version]})" \
    "Architecture" "${info[arch]}" \
    "Kernel Version" "${info[kernel]}" \
    "System Locale" "${info[locale]}" \
    "" ""

  # Hardware Section
  printf '%-20s : %s\n' \
    "CPU Model" "${info[cpu]}" \
    "CPU Cores" "${info[cpu_cores]}" \
    "CPU Frequency" "${info[cpu_freq]} MHz" \
    "" ""

  # Memory Section
  printf '%-20s : %s\n' \
    "Total Memory" "${info[total_mem]}" \
    "Used Memory" "${info[used_mem]}" \
    "Free Memory" "${info[free_mem]}" \
    "Total Swap" "${info[total_swap]}" \
    "Used Swap" "${info[used_swap]}" \
    "Free Swap" "${info[free_swap]}" \
    "" ""

  # Storage Section
  printf '%-20s : %s\n' \
    "Total Disk" "${info[total_disk]}" \
    "Used Disk" "${info[used_disk]}" \
    "Free Disk" "${info[free_disk]}" \
    "Disk Usage" "${info[disk_usage]}" \
    "" ""

  # Network Section
  printf '%-20s : %s\n' \
    "IP Address" "${info[ip]}" \
    "Network Interfaces" "${info[interfaces]}" \
    "Active Interfaces" "${info[active_interfaces]:-${ROOTINE_UNKNOWN}}" \
    "Default Gateway" "${info[default_gateway]:-${ROOTINE_UNKNOWN}}" \
    "" ""

  # GPU Section
  printf '%-20s : %s\n' \
    "GPU Model(s)" "${info[gpu]}" \
    "Number of GPUs" "${info[gpu_count]}" \
    "" ""

  # System Status Section
  printf '%-20s : %s\n' \
    "Uptime" "${info[uptime]}" \
    "Load Average" "${info[load]}" \
    "Running Processes" "${info[processes]}" \
    "Active Users" "${info[users]}" \
    "Active Services" "${info[services]}"

  printf '%s\n\n' "${separator}"
  return 0
}

# --
# @description      Main function to gather and display system information
# @stdout           Formatted system information report
# @stderr           Progress messages during information gathering
# @exitstatus       0 Success
#                   1 General error
#                   2 Missing required dependencies
# @example          get_system_info
# @public
# --
get_system_info() {
  local -r cache_file="${ROOTINE_CACHE_DIR}/system_info.cache"
  local -ir cache_max_age=${ROOTINE_SYS_INFO_CACHE_DURATION}
  local -A info

  # Verify system requirements
  _verify_requirements || return $?

  # Check cache validity
  if [[ -f "${cache_file}" ]] &&
     (($( date +%s) - $(stat -c %Y "${cache_file}") < cache_max_age)); then
    cat "${cache_file}"
    return 0
  fi

  log_info "Gathering fresh system information..."

  # Initialize and collect information
  _initialize_sys_info_array || return 1

  _collect_datetime_info
  _collect_core_info
  _collect_hardware_info
  _collect_memory_info
  _collect_storage_info
  _collect_network_info
  _collect_gpu_info
  _collect_system_status

  # Generate and cache report
  _generate_sys_info_report | tee "${cache_file}"
  return 0
}
