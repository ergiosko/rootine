#!/usr/bin/env bash

# ---
# @description      Defines user-level constants for non-privileged operations.
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         User Operations
# @dependencies     Bash 5.0.0 or higher
# @configuration    No special configuration required.
# @security         - Constants are designed for non-privileged user operations.
#                   - All constants are read-only.
#                   - Paths use user-specific locations.
# @note             This file must be sourced, not executed directly.
# @todo             - Add user-specific path constants.
#                   - Add configuration for user-level services.
#                   - Add constants for common user applications.
# ---

is_sourced || exit 1
