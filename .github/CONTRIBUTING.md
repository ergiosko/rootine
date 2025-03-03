# Contributing to Rootine

Thank you for your interest in contributing to Rootine! This document provides
guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Version Control and Release Process](#version-control-and-release-process)
  - [Semantic Versioning](#semantic-versioning)
  - [Conventional Commits](#conventional-commits)
  - [Changelog Management](#changelog-management)
  - [Release Please](#release-please)
- [Documentation](#documentation)
- [Security](#security)
- [Community](#community)

## Code of Conduct

This project follows our [Code of Conduct](.github/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to <contact@ergiosko.com>.

## Getting Started

### Prerequisites

- [Bash](https://www.gnu.org/software/bash/) v4.4.0 or higher
- [Git](https://git-scm.com/) v2 or higher
- [ShellCheck](https://www.shellcheck.net/) v0.8.0 or higher
- [Ubuntu](https://ubuntu.com/) 20.04 or higher

### Setting Up Development Environment

1. Fork the repository

2. Clone your fork:

    ```bash
    git clone https://github.com/YOUR-USERNAME/rootine.git
    cd rootine
    ```

3. Add upstream remote:

    ```bash
    git remote add upstream https://github.com/ergiosko/rootine.git
    ```

## Development Workflow

1. Create a new branch for your work:

    ```bash
    git checkout -b feature/your-feature-name
    ```

2. Make your changes following our [Coding Standards](#coding-standards)

3. Test your changes:

    ```bash
    # Run ShellCheck on all scripts
    shellcheck rootine library/**/*.sh commands/**/*.sh
    ```

4. Keep your branch updated:

    ```bash
    git fetch upstream
    git rebase upstream/main
    ```

## Coding Standards

### Shell Script Requirements

- Use Bash for all scripts
- Start each script with appropriate shebang: `#!/usr/bin/env bash`
- Include comprehensive file header documentation
- Set strict mode: `set -euf -o pipefail`
- Use `shellcheck` directives when necessary

### Naming Conventions

| Item        | Case Style  | Delimiter   | Extension  | Example          |
|-------------|-------------|-------------|------------|------------------|
| Commands    | kebab-case  | Hyphen      | .sh        | `install-git.sh` |
| Library     | snake_case  | Underscore  | .sh        | `log_utils.sh`   |
| Functions   | snake_case  | Underscore  | none       | `is_sourced()`   |

### Function and/or File Header Documentation

Each function must be documented using our standardized comment schema. The
full list of available tags can be found in `ROOTINE_COMMENT_TAGS` variable
array in `library/common/constants.sh`.

File header comments follow the same pattern, except for the comment start and
end marker. Comments to functions use `# --` (2 hyphens), and comments to file
headers use `# ---` (3 hyphens).

```bash
# --
# @description      Brief, one-line summary of the function's purpose (REQUIRED)
# @author           Author Name <email@example.com>
# @copyright        Copyright Holder <email@example.com>
# @license          MIT
# @version          1.3.7
# @since            1.1.5
# @deprecated       Marks a function/feature as deprecated, with optional reason
#                   and/or alternative.
# @category         Core|Common|Root|User
# @dependencies     - Bash 4.4.0 or higher
#                   - Required system commands
#                   - Other dependencies
# @configuration    Environment variables or configuration requirements
# @arguments        [arg1] [arg2...]  Description of positional parameters
# @param {string}   name  Parameter description
# @param {integer}  count Parameter description
# @param {boolean}  flag  Parameter description
# @envvar           USER  Current user's login name
# @stdin            Description of expected standard input, if any
# @stdout           Description of standard output format
# @stderr           Status and error messages format
# @file             /path/to/file Description of file usage
# @exitstatus       0 Success
#                   1 Various error conditions
# @return           Description of return value or output
# @global           VARIABLE_NAME Description of global variable usage
# @sideeffects      - Creates temporary files
#                   - Modifies system state
#                   - Other side effects
# @example          # Basic usage
#                   function_name arg1 arg2
#
#                   # With options
#                   function_name --option value
# @see              related_function()
#                   https://relevant-documentation-url
# @functions        - function1 Description
#                   - function2 Description
# @security         - Validates input
#                   - Handles permissions
#                   - Other security measures
# @todo             Future improvements or pending tasks:
#                     - Issue #37
#                     - etc.
# @note             Important implementation details
# @internal         Not intended for external use
# @public           Intended for external use
# @ignore           Documentation generation ignore marker
# --
function_name() {
  # Implementation
}
```

#### Required Tags

- `@description`: One-line summary
- `@author`: Original author
- `@copyright`: Copyright holder
- `@version`: Current version
- `@category`: Function category

#### Security-Related Tags

- `@security`: Security considerations
- `@dependencies`: Required system commands
- `@sideeffects`: System state changes
- `@exitstatus`: Possible exit codes

#### Documentation Tags

- `@example`: Usage examples
- `@param`: Parameter descriptions
- `@return`: Return value details
- `@see`: Related documentation

#### Internal Use Tags

- `@internal`: Private functions
- `@public`: Public API
- `@todo`: Future tasks
- `@note`: Implementation notes

All functions must be documented consistently using this schema. Comments
should be clear, concise, and provide enough information for both users and
contributors to understand the function's purpose and usage.

## Version Control and Release Process

This document outlines our version control and release process, including
[Semantic Versioning](https://semver.org/spec/v2.0.0.html),
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/),
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and [Release Please](https://github.com/googleapis/release-please) automation.

### Semantic Versioning

We follow [Semantic Versioning v2.0.0](https://semver.org/spec/v2.0.0.html)
for version numbering:

```text
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incompatible API changes
- **MINOR**: Backwards-compatible new functionality
- **PATCH**: Backwards-compatible bug fixes

Example: `1.2.3`

- Major version: 1
- Minor version: 2
- Patch version: 3

### Conventional Commits

We use [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
for commit messages:

```text
type(scope): description

[optional body]

[optional footer(s)]
```

#### Commit Types

- `feat!` or `fix!`: Breaking change (triggers MAJOR version)
- `build`: Changes that affect the build system or external dependencies
- `chore`: Other changes that don't modify src or test files
- `ci`: Changes to CI configuration files and scripts
- `docs`: Documentation only changes
- `feat`: A new feature
- `fix`: A bug fix
- `perf`: A code change that improves performance
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `revert`: Reverts a previous commit
- `style`: Changes that do not affect the meaning of the code
- `test`: Adding missing tests or correcting existing tests

#### Commit Scopes

- `commands`: Command scripts in commands/ directory
- `core`: Core functionality affecting entire system
- `docs`: Documentation files (.md, man pages)
- `git`: Git-related functionality
- `github`: GitHub-related functionality
- `library`: Library functions in library/
- `root`: Root-level functionality
- `security`: Security-related changes
- `user`: User-level functionality

#### Examples

```text
feat(commands): add nginx installation command

fix(library): correct path handling in file_exists function

docs: update installation instructions

feat!: change command-line interface
BREAKING CHANGE: new syntax for all commands
```

### Changelog Management

We follow [Keep a Changelog v1.1.0](https://keepachangelog.com/en/1.1.0/)
format in [CHANGELOG.md](CHANGELOG.md):

```markdown
# Changelog

## [Unreleased]

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Vulnerability fixes
```

The changelog is automatically updated by
[Release Please Action](https://github.com/marketplace/actions/release-please-action)
based on conventional commits.

### Release Please

We use [Release Please](https://github.com/googleapis/release-please)
and [Release Please Action](https://github.com/marketplace/actions/release-please-action)
to automate version management:

#### How it Works

1. Commit messages following conventional format
2. Release Please automatically:
    - Determines version bumps
    - Updates [CHANGELOG.md](CHANGELOG.md)
    - Creates release PR
    - Creates GitHub release

#### Configuration

Release Please is configured in our repository
in [release-please-config.json](.github/release-please-config.json) file.

#### Manual Release

To trigger a manual release or set a specific version:

1. Update `release-please-config.json`:

    ```json
    {
      "packages": {
        ".": {
          "release-type": "simple",
          "force-release-version": "x.x.x"
        }
      }
    }
    ```

2. Commit and push the changes

3. Release Please will create a release PR with the specified version

#### Release PR Review

1. Check the generated [CHANGELOG.md](CHANGELOG.md)
2. Verify version bump is correct
3. Review included commits
4. Merge when ready

## Documentation

- Update [README.md](README.md) for user-facing changes
- Add inline documentation for new functions
- Include usage examples for new commands

### Command Documentation Template

````markdown
# Command Name

## Description

Brief description of what the command does.

## Usage

```bash
rootine command-name [options]
```

## Options

- `-h, --help`: Show help message
- Other options...

## Examples

```bash
rootine command-name --option value
```
````

## Security

- Never commit sensitive information
- Follow security best practices
- Report security issues according to our [Security Policy](.github/SECURITY.md)
- Use proper permission handling in scripts

## Community

- [Github Discussions](https://github.com/ergiosko/rootine/discussions)
- [Issue Tracker](https://github.com/ergiosko/rootine/issues)
- [Pull Requests](https://github.com/ergiosko/rootine/pulls)

### Getting Help

1. Check existing documentation and source code's comments
2. Search [closed issues](https://github.com/ergiosko/rootine/issues?q=is%3Aissue%20state%3Aclosed)
3. Ask in [GitHub Discussions](https://github.com/ergiosko/rootine/discussions)
4. Contact maintainers:

- Sergiy Noskov <sergiy@noskov.org>
- Ergiosko <contact@ergiosko.com>

---

## Thank You

Your contributions make Rootine better! We deeply appreciate every form of contribution, whether it's:

- Writing code
- Improving documentation
- Reporting issues
- Suggesting features
- Helping other users
- Sharing feedback

Even the smallest contributions help make Rootine a better tool for every lazy ubuntoid.
