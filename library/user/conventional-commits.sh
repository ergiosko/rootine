#!/usr/bin/env bash

is_sourced || exit 1

# --
# @description      Validates a conventional commit type
# @param            type The commit type to validate
# @return           0 if valid, 1 otherwise
# @example          _validate_commit_type "feat"
# @internal
# --
_validate_commit_type() {
  local type="${1:?Commit type required}"
  local -a valid_types=(
    "build"     # Changes that affect the build system or external dependencies
    "chore"     # Other changes that don't modify src or test files
    "ci"        # Changes to CI configuration files and scripts
    "docs"      # Documentation only changes
    "feat"      # A new feature
    "fix"       # A bug fix
    "perf"      # A code change that improves performance
    "refactor"  # A code change that neither fixes a bug nor adds a feature
    "revert"    # Reverts a previous commit
    "style"     # Changes that do not affect the meaning of the code
    "test"      # Adding missing tests or correcting existing tests
  )

  # shellcheck disable=SC2076
  [[ " ${valid_types[*]} " =~ " ${type} " ]] && return 0
  return 1
}

# --
# @description      Validates a conventional commit scope
# @param            scope The commit scope to validate
# @return           0 if valid, 1 otherwise
# @example          _validate_commit_scope "core"
# @internal
# --
_validate_commit_scope() {
  local scope="${1:?Commit scope required}"
  local -a valid_scopes=(
    "commands"  # Command scripts
    "common"    # Common utilities
    "core"      # Core functionality
    "docs"      # Documentation
    "git"       # Git-related functionality
    "library"   # Library functions
    "root"      # Root-level functionality
    "security"  # Security-related changes
    "user"      # User-level functionality
  )

  # shellcheck disable=SC2076
  [[ " ${valid_scopes[*]} " =~ " ${scope} " ]] && return 0
  return 1
}

# --
# @description      Creates a commit message following Conventional Commits spec
# @param            type Commit type (feat, fix, etc.)
# @param            [scope] Optional scope
# @param            description Commit description
# @param            [body] Optional commit body
# @param            [footer] Optional commit footer
# @param            [breaking=false] Whether this is a breaking change
# @return           0 on success, 1 on failure
# @example          git_conventional_commit "feat" "core" "add new feature"
# @public
# --
git_conventional_commit() {
  local type="${1:?Commit type required}"
  local scope="${2:-}"
  local description="${3:?Commit description required}"
  local body="${4:-}"
  local footer="${5:-}"
  local breaking="${6:-false}"
  local message

  # Validate commit type
  if ! _validate_commit_type "${type}"; then
    log_error "Invalid commit type: ${type}"
    log_info "Valid types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test"
    return 1
  fi

  # Validate commit scope if provided
  if [[ -n "${scope}" ]] && ! _validate_commit_scope "${scope}"; then
    log_error "Invalid commit scope: ${scope}"
    log_info "Valid scopes: commands, common, core, docs, git, library, root, security, user"
    return 1
  fi

  # Validate description format
  if [[ ! "${description}" =~ ^[a-z] ]]; then
    log_error "Description must start with lowercase letter"
    return 1
  fi

  # Build commit message
  message="${type}"
  [[ -n "${scope}" ]] && message+="(${scope})"
  [[ "${breaking}" == "true" ]] && message+="!"
  message+=": ${description}"

  # Add body if provided
  [[ -n "${body}" ]] && message+="\n\n${body}"

  # Add footer if provided
  [[ -n "${footer}" ]] && message+="\n\n${footer}"

  # Add BREAKING CHANGE footer for breaking changes
  if [[ "${breaking}" == "true" ]]; then
    [[ -n "${footer}" ]] && message+="\n"
    message+="\nBREAKING CHANGE: ${description}"
  fi

  # Create the commit
  if ! git commit -m "${message}"; then
    log_error "Failed to create commit"
    return 1
  fi

  log_success "Created conventional commit: ${type}${scope:+"(${scope})"}${breaking:+"!"}: ${description}"
  return 0
}

# --
# @description      Validates if a commit message follows Conventional Commits spec
# @param            message The commit message to validate
# @return           0 if valid, 1 otherwise
# @example          git_validate_commit_message "feat(core): add new feature"
# @public
# --
git_validate_commit_message() {
  local message="${1:?Commit message required}"
  local type scope description

  # Build regex pattern from valid types
  local types_pattern
  types_pattern="$(printf '%s|' "${valid_types[@]}")"
  types_pattern="${types_pattern%|}"  # Remove trailing |

  # Build regex pattern for commit message
  local commit_pattern="^(${types_pattern})(\\([a-z-]+\\))?(!)?: [a-z].*"

  if [[ ! "${message}" =~ ${commit_pattern} ]]; then
    log_error "Invalid commit message format"
    log_info "Expected format: type(scope): description"
    log_info "Valid types: ${valid_types[*]}"
    return 1
  fi

  type="${BASH_REMATCH[1]}"
  scope="${BASH_REMATCH[2]}"
  scope="${scope#(}"  # Remove leading (
  scope="${scope%)}"  # Remove trailing )

  # Validate type
  if ! _validate_commit_type "${type}"; then
    log_error "Invalid commit type: ${type}"
    return 1
  fi

  # Validate scope if present
  if [[ -n "${scope}" ]] && ! _validate_commit_scope "${scope}"; then
    log_error "Invalid commit scope: ${scope}"
    return 1
  fi

  return 0
}
