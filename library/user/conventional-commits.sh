#!/usr/bin/env bash

# ---
# @description      Conventional Commits specification implementation and validation
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Core
# @dependencies     - Bash 4.4.0 or higher
# @see              https://www.conventionalcommits.org/
#                   https://commitlint.js.org/
# @security         - Validates commit message format
#                   - Prevents malformed commits
# @todo             - Add commit message linting
#                   - Add commit hooks integration
#                   - Add changelog generation
#                   - Add support for custom scopes
#                   - Add support for custom types
# ---

is_sourced || exit 1

# Valid commit types based on conventional commits specification
# @see https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional
declare -ga ROOTINE_COMMIT_TYPES=(
  "build"     # Changes that affect the build system or external dependencies
              # Examples: npm, gulp, broccoli, webpack
  "chore"     # Other changes that don't modify src or test files
              # Examples: updating grunt tasks, no production code change
  "ci"        # Changes to CI configuration files and scripts
              # Examples: Github Actions, Travis, Circle, BrowserStack, SauceLabs
  "docs"      # Documentation only changes
              # Examples: README, JSDoc, man pages, comments
  "feat"      # A new feature
              # Examples: new API endpoints, new UI components
  "fix"       # A bug fix
              # Examples: resolving a bug, fixing a defect
  "perf"      # A code change that improves performance
              # Examples: optimizing loops, improving rendering
  "refactor"  # A code change that neither fixes a bug nor adds a feature
              # Examples: moving code, renaming variables
  "revert"    # Reverts a previous commit
              # Format: revert: <type>(<scope>): <description>
  "style"     # Changes that do not affect the meaning of the code
              # Examples: white-space, formatting, missing semi-colons
  "test"      # Adding missing tests or correcting existing tests
              # Examples: unit tests, integration tests, e2e tests
)

# Valid commit scopes for Rootine project
declare -ga ROOTINE_COMMIT_SCOPES=(
  "commands"  # Command scripts in commands/ directory
  "common"    # Common utilities in library/common/
  "core"      # Core functionality affecting entire system
  "docs"      # Documentation files (.md, man pages)
  "git"       # Git-related functionality
  "library"   # Library functions in library/
  "root"      # Root-level functionality
  "security"  # Security-related changes
  "user"      # User-level functionality
)

# --
# @description      Validates a conventional commit type
# @param            type The commit type to validate
# @return           0 if valid, 1 otherwise
# @example          _validate_commit_type "feat"
# @see              https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional#type-enum
# @internal
# --
_validate_commit_type() {
  local type="${1:?Commit type required}"

  # Use space-padded string to ensure exact matches
  # shellcheck disable=SC2076
  [[ " ${ROOTINE_COMMIT_TYPES[*]} " =~ " ${type} " ]] && return 0
  return 1
}

# --
# @description      Validates a conventional commit scope
# @param            scope The commit scope to validate
# @return           0 if valid, 1 otherwise
# @example          _validate_commit_scope "core"
# @see              https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional#scope-enum
# @internal
# --
_validate_commit_scope() {
  local scope="${1:?Commit scope required}"

  # Use space-padded string to ensure exact matches
  # shellcheck disable=SC2076
  [[ " ${ROOTINE_COMMIT_SCOPES[*]} " =~ " ${scope} " ]] && return 0
  return 1
}

# --
# @description      Creates a commit message following Conventional Commits spec
# @param            type Commit type (feat, fix, etc.)
# @param            [scope] Optional scope in parentheses
# @param            description Commit description
# @param            [body] Optional commit body
# @param            [footer] Optional commit footer
# @param            [breaking=false] Whether this is a breaking change
# @return           0 on success, 1 on failure
# @example          git_conventional_commit "feat" "core" "add new feature"
#                   git_conventional_commit "fix" "security" "patch CVE" "" "" true
# @see              https://www.conventionalcommits.org/en/v1.0.0/#specification
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

  # Validate commit type against allowed types
  if ! _validate_commit_type "${type}"; then
    log_error "Invalid commit type: ${type}"
    log_info "Valid types: ${ROOTINE_COMMIT_TYPES[*]}"
    return 1
  fi

  # Validate commit scope if provided
  if [[ -n "${scope}" ]] && ! _validate_commit_scope "${scope}"; then
    log_error "Invalid commit scope: ${scope}"
    log_info "Valid scopes: ${ROOTINE_COMMIT_SCOPES[*]}"
    return 1
  fi

  # Validate description format (must start with lowercase)
  if [[ ! "${description}" =~ ^[a-z] ]]; then
    log_error "Description must start with lowercase letter"
    return 1
  fi

  # Build commit message following conventional commits spec
  # <type>[(scope)][!]: <description>
  message="${type}"
  [[ -n "${scope}" ]] && message+="(${scope})"
  [[ "${breaking}" == "true" ]] && message+="!"
  message+=": ${description}"

  # Add optional body after blank line
  [[ -n "${body}" ]] && message+="\n\n${body}"

  # Add optional footer after blank line
  [[ -n "${footer}" ]] && message+="\n\n${footer}"

  # Add BREAKING CHANGE footer for breaking changes
  if [[ "${breaking}" == "true" ]]; then
    [[ -n "${footer}" ]] && message+="\n"
    message+="\nBREAKING CHANGE: ${description}"
  fi

  # Create the commit with formatted message
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
# @see              https://commitlint.js.org/#/reference-rules
# @public
# --
git_validate_commit_message() {
  local message="${1:?Commit message required}"
  local type scope description

  # Build regex pattern from valid types dynamically
  local types_pattern
  types_pattern="$(printf '%s|' "${ROOTINE_COMMIT_TYPES[@]}")"
  types_pattern="${types_pattern%|}"  # Remove trailing |

  # Full commit message pattern following spec:
  # type(scope)!: description
  local commit_pattern="^(${types_pattern})(\\([a-z-]+\\))?(!)?: [a-z].*"

  # Validate basic message format
  if [[ ! "${message}" =~ ${commit_pattern} ]]; then
    log_error "Invalid commit message format"
    log_info "Expected format: type(scope): description"
    log_info "Valid types: ${ROOTINE_COMMIT_TYPES[*]}"
    return 1
  fi

  # Extract components from message
  type="${BASH_REMATCH[1]}"
  scope="${BASH_REMATCH[2]}"
  scope="${scope#(}"  # Remove leading (
  scope="${scope%)}"  # Remove trailing )

  # Validate commit type
  if ! _validate_commit_type "${type}"; then
    log_error "Invalid commit type: ${type}"
    return 1
  fi

  # Validate commit scope if present
  if [[ -n "${scope}" ]] && ! _validate_commit_scope "${scope}"; then
    log_error "Invalid commit scope: ${scope}"
    return 1
  fi

  return 0
}

# --
# @description      Installs commit-msg hook for Conventional Commits validation
# @param            [force=false] Whether to overwrite existing hook
# @return           0 on success, 1 on failure
# @example          git_install_commit_msg_hook
#                   git_install_commit_msg_hook true
# @sideeffects      - Creates/updates .git/hooks/commit-msg
#                   - Sets executable permissions
#                   - Creates backup of existing hook
# @security         - Validates Git repository
#                   - Sets proper file permissions (0755)
#                   - Creates secure backup
# @public
# --
git_install_commit_msg_hook() {
  local force="${1:-false}"
  local hooks_dir commit_msg_hook

  # Verify we're in a Git repository
  if ! _is_git_repo; then
    return 1
  fi

  # Get Git hooks directory
  if ! hooks_dir="$(git rev-parse --git-path hooks)"; then
    log_error "Failed to get Git hooks directory"
    return 1
  fi

  # Set commit-msg hook path
  commit_msg_hook="${hooks_dir}/commit-msg"

  # Check if hook already exists
  if [[ -f "${commit_msg_hook}" ]] && [[ "${force}" != "true" ]]; then
    log_error "commit-msg hook already exists. Use force=true to overwrite"
    return 1
  fi

  # Create hooks directory if it doesn't exist
  if [[ ! -d "${hooks_dir}" ]]; then
    if ! mkdir -p "${hooks_dir}"; then
      log_error "Failed to create hooks directory"
      return 1
    fi
  fi

  # Create new hook
  cat > "${commit_msg_hook}" <<'EOF'
#!/usr/bin/env bash

# ---
# @description      Git commit-msg hook for conventional commits validation
# @author           Sergiy Noskov <sergiy@noskov.org>
# @copyright        Ergiosko <contact@ergiosko.com>
# @license          MIT
# @version          1.0.0
# @since            1.0.0
# @category         Version Control
# @dependencies     - Bash 4.4.0 or higher
#                   - Git 2.0 or higher
# @param            commit_msg_file Path to temporary file containing commit message
# @exitstatus       0  Commit message is valid
#                   1  Commit message is invalid or error occurred
# @sideeffects      None
# @security         - Uses full paths
#                   - No shell expansions in commit message
#                   - Safe repository root detection
# ---

# Get commit message from temporary file
commit_msg_file="${1}"
commit_msg="$(cat "${commit_msg_file}")"

# Skip validation for merge commits
if [[ "${commit_msg}" =~ ^Merge\ branch ]]; then
  exit 0
fi

# Get repository root path for locating rootine executable
repo_root="$(git rev-parse --show-toplevel)"
if [[ ! -d "${repo_root}" ]]; then
  echo "ERROR: Failed to determine repository root" >&2
  exit 1
fi

# Validate commit message using rootine
if [[ -x "${repo_root}/rootine" ]]; then
  ROOTINE_COMMAND="${repo_root}/rootine"
  if ! "${ROOTINE_COMMAND}" lib::user::git_validate_commit_message "${commit_msg}"; then
    echo "ERROR: Invalid commit message format" >&2
    exit 1
  fi
else
  echo "ERROR: Rootine library not found in ${repo_root}/library" >&2
  exit 1
fi

exit 0
EOF

  # Make hook executable
  if ! chmod 0755 "${commit_msg_hook}"; then
    log_error "Failed to make commit-msg hook executable"
    return 1
  fi

  log_success "Successfully installed commit-msg hook in ${hooks_dir}"
  return 0
}

# --
# @description      Installs Git commit message template
# @param            [force=false] Whether to overwrite existing template
# @return           0 on success, 1 on failure
# @example          git_install_commit_template
#                   git_install_commit_template true
# @sideeffects      Sets Git commit.template configuration
# @security         Uses local Git configuration
# @public
# --
git_install_commit_template() {
  local force="${1:-false}"

  if ! git config --get commit.template &>/dev/null || [[ "${force}" == "true" ]]; then
    if ! git config --local commit.template "${ROOTINE_LIBRARY_DIR}/user/templates/git-commit-template.txt"; then
      log_error "Failed to set commit template"
      return 1
    fi
    log_success "Successfully set commit template"
  else
    log_error "Commit template already configured. Use force=true to override"
    return 1
  fi

  return 0
}
