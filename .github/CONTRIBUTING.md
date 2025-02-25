# Contributing to Rootine

Thank you for your interest in contributing to Rootine! This document provides guidelines and instructions for contributing to the project.


## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Documentation](#documentation)
- [Security](#security)
- [Community](#community)


## Code of Conduct

This project follows our [Code of Conduct](.github/CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to contact@ergiosko.com.


## Getting Started

### Prerequisites

- Bash 4.4.0 or higher
- Git
- ShellCheck
- Ubuntu 20.04 or higher

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

2. Make your changes following our [coding standards](#coding-standards)

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

Each function must be documented using our standardized comment schema. The full list of available tags can be found in `ROOTINE_COMMENT_TAGS` variable array in `library/common/constants.sh`.

File header comments follow the same pattern, except for the comment start and end marker. Comments to functions use `# --` (2 hyphens), and comments to file headers use `# ---` (3 hyphens).

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

All functions must be documented consistently using this schema. Comments should be clear, concise, and provide enough information for both users and contributors to understand the function's purpose and usage.


## Commit Guidelines

### Commit Message Format

```
type(scope): subject

body

footer
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

### Example

```
feat(commands): add nginx installation command

Add new command to install and configure Nginx server
with default security settings.

Closes #123
```

## Pull Request Process

1. Update documentation for any new or modified functionality
2. Add or update tests as needed
3. Ensure all tests pass and ShellCheck reports no issues
4. Update the CHANGELOG.md file if applicable
5. Submit PR with clear description and reference to related issues

### PR Title Format

```
type(scope): description
```

Example: `feat(commands): add nginx installation command`


## Documentation

- Update README.md for user-facing changes
- Add inline documentation for new functions
- Include usage examples for new commands
- Update man pages if applicable

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
  - Sergiy Noskov sergiy@noskov.org
  - Ergiosko contact@ergiosko.com


---

## Thank You!

Your contributions make Rootine better! We deeply appreciate every form of contribution, whether it's:

- Writing code
- Improving documentation
- Reporting issues
- Suggesting features
- Helping other users
- Sharing feedback

Even the smallest contributions help make Rootine a better tool for every lazy ubuntoid.

*With gratitude,
Sergiy Noskov, The Rootine Team*
