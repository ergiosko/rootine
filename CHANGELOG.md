# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog v1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning v2.0.0](https://semver.org/spec/v2.0.0.html).

## [1.0.0]

### Added

- Conventional Commits support
  - Added `git-push` command for creating conventional commits
  - Added `git-install-hooks` command for setting up Git hooks
  - Added commit message validation following [Conventional Commits v1.0.0](https://www.conventionalcommits.org/)
  - Added Git commit message template
  - Added support for commit types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test
  - Added scopes: commands, common, core, docs, git, library, root, security, user

### Changed

- Git operations now enforce Conventional Commits format
- Git hooks are now managed through Rootine commands

### Security

- Safe Git hook installation with proper permissions
- Secure commit message validation
- Protected Git operations

[1.0.0]: https://github.com/ergiosko/rootine/compare/v0.9.0...v1.0.0
