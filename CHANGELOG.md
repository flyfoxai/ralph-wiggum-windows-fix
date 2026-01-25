# Changelog

All notable changes to the Ralph Wiggum plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-01-25

### Fixed
- **Critical**: Fixed hooks.json nested structure that caused stop hooks to execute twice
  - Removed extra nested "hooks" layer in Stop hook configuration
  - Eliminates `/usr/bin/sh: cannot execute binary file` error
  - Prevents resource competition between duplicate hook executions
  - Improves hook execution performance

### Added
- Comprehensive diagnostic script (`tests/diagnose-hook-error.ps1`)
- Hooks validation script (`tests/validate-hooks-fix.ps1`)
- Detailed fix documentation (`docs/STOP-HOOK-ERROR-FIX.md`)

### Changed
- Hooks configuration structure now uses correct flat array format
- Each platform now executes exactly one stop hook (instead of two)

## [1.0.1] - 2026-01-24

### Added
- Marketplace configuration for official plugin installation
- Cross-platform hook support with intelligent routing
- Enhanced hooks.json with comprehensive environment support documentation

### Fixed
- Correct hooks directory path in test-cross-platform.ps1
- Remove Export-ModuleMember to enable function availability
- Use intelligent router for cross-platform hook support

## [1.0.0] - 2026-01-23

### Added
- Initial release with full cross-platform support
- Smart Ralph Loop with intelligent completion detection
- Support for Windows, WSL, macOS, Linux, Git Bash, and Cygwin
- Comprehensive test suite
- State management and persistence
- Task progress monitoring
- Graceful interruption handling
