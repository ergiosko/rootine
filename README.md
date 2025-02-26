# Rootine — Bash Library for Lazy Ubuntoids

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/ergiosko/rootine?style=flat-square)](https://github.com/ergiosko/rootine/releases)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/ergiosko/rootine/shellcheck.yml?branch=main&style=flat-square)](https://github.com/ergiosko/rootine/actions)
[![Bash Version](https://img.shields.io/badge/bash-%3E%3D4.4.0-brightgreen?style=flat-square)](https://www.gnu.org/software/bash/)
[![Ubuntu Version](https://img.shields.io/badge/ubuntu-%3E%3D20.04-orange?style=flat-square)](https://ubuntu.com/)
[![Code Style](https://img.shields.io/badge/code%20style-shellcheck-blue?style=flat-square)](https://www.shellcheck.net/)
[![GitHub issues](https://img.shields.io/github/issues/ergiosko/rootine?style=flat-square)](https://github.com/ergiosko/rootine/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/ergiosko/rootine?style=flat-square)](https://github.com/ergiosko/rootine/pulls)
[![GitHub Discussions](https://img.shields.io/github/discussions/ergiosko/rootine?style=flat-square)](https://github.com/ergiosko/rootine/discussions)
[![Security Policy](https://img.shields.io/badge/security-policy-red?style=flat-square)](https://github.com/ergiosko/rootine/security/policy)
[![GitHub](https://img.shields.io/github/license/ergiosko/rootine?style=flat-square)](https://github.com/ergiosko/rootine/blob/main/LICENSE)
[![GitHub Sponsor](https://img.shields.io/github/sponsors/ergiosko?style=flat-square&logo=github&label=Sponsor)](https://github.com/sponsors/ergiosko)


## Description

> [!CAUTION]
> This library is currently under active development and is NOT ready for production use. Production readiness will be achieved with the first public release (v1.0.0). See [Project Status](#project-status).


## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [Tests](#tests)
- [Security](#security)
- [Project Status](#project-status)
- [Maintainers](#maintainers)
- [Contact](#contact)
- [License](#license)


## Features




## Installation

### Prerequisites

- Bash version 4.4.0 or higher
- Root/sudo privileges
- Required utilities: `grep`, `realpath`, `sed`

### Automatic Installation

1. Clone the repository:

```bash
git clone https://github.com/ergiosko/rootine.git
cd rootine
```

2. Run the installation script with root privileges:

```bash
sudo ./install.sh
```

The installer will:
- Create Rootine-related utility directories
- Detect the appropriate system-wide bashrc location (`/etc/bash.bashrc` or `/etc/bashrc`)
- Create a backup of your current bashrc as `*.rootine.bak`
- Add Rootine configuration to your system-wide bashrc
- Set up the global `rootine` alias
- Create the global `IS_ROOTINE_INSTALLED` variable

3. Reload your terminal session to apply changes:

```bash
source /etc/bash.bashrc  # or /etc/bashrc depending on your system
```

### Verification

To verify the installation:

```bash
# Check if Rootine is installed
echo $IS_ROOTINE_INSTALLED  # Should output 1

# Test the rootine alias
rootine --version
```

### Uninstallation

To remove Rootine from your system:

```bash
sudo ./uninstall.sh
```

The uninstaller will:
- Remove Rootine-related utility directories
- Remove all Rootine-related configurations from your system-wide bashrc
- Keep a backup of the original configuration as `*.rootine.bak`
- Remove the global `rootine` alias and `IS_ROOTINE_INSTALLED` variable

### Manual Installation

If you prefer to install manually, add the following to your system-wide bashrc:

```bash
# -- Start Rootine Code --
if [[ -f "/path/to/rootine/rootine" ]]; then
  alias rootine="/path/to/rootine/rootine"
  declare -gix IS_ROOTINE_INSTALLED=1
fi
# -- End Rootine Code --
```

Replace `/path/to/rootine` with the actual path to your Rootine installation.

### Troubleshooting

Common installation issues and solutions:

1. **Permission Denied**
  ```
  [ ERROR ] This script must be run as root
  ```
  Solution: Run the installation script with `sudo`.

2. **Bashrc Not Found**
  ```
  [ ERROR ] No global bashrc file found
  ```
  Solution: Ensure either `/etc/bash.bashrc` or `/etc/bashrc` exists.

3. **Write Permission Error**
  ```
  [ ERROR ] No write permission for /etc/bash.bashrc
  ```
  Solution: Check file permissions and ensure you're running with sudo.

4. **Backup Creation Failed**
  ```
  [ ERROR ] Unable to create /etc/bash.bashrc backup file
  ```
  Solution: Ensure sufficient disk space and proper permissions in /etc.

### Security Considerations

- Installation scripts create backups before making any modifications
- Strict permissions are enforced for configuration files
- All scripts use strict error handling (`set -euf -o pipefail`)
- Configuration blocks are clearly marked for easy identification
- Temporary files are securely handled and removed

### File Locations

- **Installation Script**: `./install.sh`
- **Uninstallation Script**: `./uninstall.sh`
- **System Configuration**: `/etc/bash.bashrc` or `/etc/bashrc`
- **Backup Files**: `*.rootine.bak`

### Notes

- Always review scripts before running them with root privileges
- Keep the backup files (`*.rootine.bak`) in case you need to restore the original configuration
- The installation adds minimal overhead to your shell initialization
- Both installation and uninstallation are idempotent operations


## Usage

### File Structure Overview

```
rootine/
├── commands/           - Command scripts
│   ├── root/           - Commands requiring root privileges
│   └── user/           - Commands for regular users
├── library/            - Core library functions
│   ├── bootstrap.sh    - Initialization script
│   ├── common/         - Shared utility functions
│   ├── root/           - Root-level functions
│   └── user/           - User-level functions
├── .github/            - GitHub-specific configurations
├── .editorconfig       - Editor configuration
├── .shellcheckrc       - ShellCheck configuration
├── LICENSE             - MIT License
├── README.md           - Documentation
├── rootine             - Main executable
├── install.sh          - Installation script
└── uninstall.sh        - Deinstallation script
```

### Naming Conventions

We follow these naming conventions for consistency and clarity:

| Item        | Case Style  | Delimiter       | Extension  | Example            |
|-------------|-------------|-----------------|------------|--------------------|
| Commands    | kebab-case  | Hyphen (-)      | .sh        | `install-git.sh`   |
| Library     | snake_case  | Underscore (_)  | .sh        | `log_messages.sh`  |
| Functions   | snake_case  | Underscore (_)  | (none)     | `is_sourced()`     |

### How It Works

1. `commands/`: Contains scripts that perform specific tasks. These scripts might use functions from the library directory.
The separation into `root/` and `user/` subdirectories ensures that root actions are kept separate and protected.

2. `library/`: Contains reusable functions and helper scripts. The `common/` directory holds functions that are used by both root and user scripts. The `root/` and `user/` subdirectories contain functions specific to each privilege level.

3. `library/bootstrap.sh`: The core initialization component that:
  - Sets up error handling and cleanup procedures
  - Validates the environment and required dependencies
  - Initializes system-wide constants and configurations
  - Manages user privilege levels (root/user)
  - Provides dynamic function loading and command routing
  - Handles library file sourcing based on user level
  - Implements secure temporary file management
  - Establishes logging and debugging infrastructure

The bootstrap process ensures:
  - Proper initialization of the framework
  - Secure execution environment
  - Clean error handling and resource cleanup
  - Appropriate privilege separation
  - Dynamic command and function resolution

4. `rootine` (Main Script): The framework's entry point that, in a nutshell, initializes core components, and routes commands to their appropriate handlers. It acts as a secure gateway between user input and the framework's functionality.

### Basic Usage

Rootine's command-line interface follows a simple pattern:

```bash
rootine [command] [options]
```

Commands are organized by privilege level in corresponding subdirectories:

- Root-level commands: `commands/root/*.sh`
- User-level commands: `commands/user/*.sh`

For example, to install Git:

```bash
# This will execute commands/root/install-git.sh
rootine install-git
```

Each command is a standalone Bash script that:

1. Lives in the appropriate privilege directory
2. Has a `.sh` extension (omitted when calling)
3. Contains a `main()` function that performs the actual work

More examples:

```bash
# Root-level commands (require sudo)
rootine install-apache2-server  # Install Apache2 web server
rootine remove-docker           # Remove Docker and its dependencies
rootine configure-firewall      # Configure system firewall

# User-level commands
rootine install-nodejs          # Install Node.js runtime environment
rootine check-updates           # Check for system updates
rootine get-system-info         # Display system information
```

Available commands can be found by exploring the `commands/` directory structure or by running:

```bash
rootine --help
```


## Contributing

### Community Code of Conduct

All communication channels follow our [Code of Conduct](.github/CODE_OF_CONDUCT.md). We expect all community members to:

- Be respectful and inclusive
- Follow the guidelines
- Help maintain a positive environment

Guidelines for contributing to the project, including how to submit bug reports, feature requests, and pull requests. Link to a [CONTRIBUTING.md](.github/CONTRIBUTING.md) file for more detailed information.


## Tests

### Static Analysis

We use [ShellCheck](https://www.shellcheck.net/) for static analysis of our Bash scripts to ensure code quality and catch common errors.

### Running Tests Locally

1. **Install ShellCheck**:

```bash
# Ubuntu/Debian
sudo apt install shellcheck
```

2. **Run Tests**:

```bash
# Test all shell scripts
shellcheck rootine library/**/*.sh commands/**/*.sh

# Test specific file
shellcheck path/to/script.sh
```

### Continuous Integration

ShellCheck runs automatically on all pull requests through our GitHub Actions workflow. PRs must pass ShellCheck validation before merging.

### ShellCheck Configuration

Project-specific ShellCheck settings are defined in [.shellcheckrc](.shellcheckrc) file.

For detailed error explanations, visit [shellcheck.net/wiki](https://shellcheck.net/wiki).


## Security

We take security seriously. Please review our comprehensive [Security Policy](.github/SECURITY.md) for:

- Vulnerability reporting procedures
- Supported versions
- Security best practices
- Contact information
- Security features and limitations

For security concerns, please email sergiy@noskov.org or contact@ergiosko.com starting with \[SECURITY\] in the subject line.

**Do not report security vulnerabilities through public GitHub issues.**


## Project Status

### Current Status

- **Phase**: Active Development
- **Version**: 0.9.0
- **Stability**: NOT PRODUCTION READY

### Focus Areas
- Security hardening
- Documentation improvements
- Performance optimization
- Test coverage expansion

> [!IMPORTANT]
> This library is currently under active development and is NOT ready for production use. Production readiness will be achieved with the first public release (v1.0.0).


## Maintainers

### Core Team

**Sergiy Noskov** (Lead Maintainer)
- GitHub: [@noskov](https://github.com/noskov)
- Email: sergiy@noskov.org
- Web: [noskov.org](https://noskov.org/)
- Focus: Architecture, Security, Releases

**Ergiosko** (Organization)
- GitHub: [@ergiosko](https://github.com/ergiosko)
- Email: contact@ergiosko.com
- Web: [ergiosko.com](https://ergiosko.com/)
- Focus: Governance, Community, Strategy

### Becoming a Maintainer

Prerequisites:
- History of quality contributions
- Strong Bash scripting knowledge
- Ubuntu systems expertise
- Good communication skills


## Contact

For all support inquiries, community discussions, and contact information, please refer to our detailed [Support Guide](.github/SUPPORT.md).

### Quick Links

- [Github Discussions](https://github.com/ergiosko/rootine/discussions)
- [Issue Tracker](https://github.com/ergiosko/rootine/issues)
- [Pull Requests](https://github.com/ergiosko/rootine/pulls)
- [Security Policy](https://github.com/ergiosko/rootine/security)

> [!NOTE]
> For security vulnerabilities, please DO NOT use public channels. Follow the security reporting guidelines in our [Security Policy](.github/SECURITY.md).


## License

### MIT License

```text
Copyright (c) 2024-2025 Sergiy Noskov <sergiy@noskov.org>
Copyright (c) 2024-2025 Ergiosko <contact@ergiosko.com>
```

Rootine is open-source software licensed under the [MIT License](LICENSE). This means you can:

- ✓ Use it commercially
- ✓ Modify the source code
- ✓ Distribute it freely
- ✓ Use it privately
- ✓ Sublicense it

**Requirements:**

- Keep the copyright and license notices
- Include the full license text

**Usage in Your Projects:**

```text
This software includes Rootine (https://github.com/ergiosko/rootine)
Copyright (c) 2024-2025 Sergiy Noskov <sergiy@noskov.org>
Copyright (c) 2024-2025 Ergiosko <contact@ergiosko.com>
Licensed under the MIT License
```

For questions about licensing, contact:
- Sergiy Noskov <sergiy@noskov.org>
- Ergiosko <contact@ergiosko.com>
