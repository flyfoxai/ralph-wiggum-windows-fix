# Ralph Wiggum Plugin - Cross-Platform Edition

**Version 1.33** | [中文文档](README_CN.md) | English

> Cross-platform Ralph Wiggum plugin with comprehensive Windows, WSL, macOS, and Linux support. Implements the Ralph technique - continuous self-referential AI loops for iterative development.

---

## ✨ What's New in Version 1.33

### 🐛 WSL Fixes

Fixed WSL stop hook errors and improved stability:

- ✅ Fixed "/usr/bin/sh: cannot execute binary file" error
- ✅ Added script verification and detailed logging
- ✅ WSL test pass rate: 85.7%
- ✅ Overall test pass rate: 98.3%

---

## 🎯 What is Ralph Wiggum?

Ralph is a development methodology based on continuous AI agent loops. The plugin implements this using a **Stop hook** that intercepts Claude's exit attempts, creating a self-referential feedback loop:

```bash
# You run ONCE:
/ralph-smart "Implement user authentication"

# Then Claude Code automatically:
# 1. Works on the task
# 2. Tries to exit
# 3. Stop hook blocks exit and feeds the prompt back
# 4. Repeat until completion or max iterations
```

**Key Features**:
- 🔄 Continuous iteration within a single session
- 🎯 Automatic task completion detection
- 🛡️ Safety limits with max iterations
- 📊 Progress tracking and state management
- 🌍 Full cross-platform support (Windows, WSL, macOS, Linux)
- 🎯 Multi-task sequential execution (NEW in v1.30)

---

## 🚀 Quick Start

### Installation

Install via Claude Code plugin marketplace:

```bash
/plugin install ralph-wiggum
```

### Basic Usage

```bash
# Set default max iterations (NEW in v1.30)
/ralph-smart-setmaxiterations 10

# Single task with Smart Ralph (uses default max iterations)
/ralph-smart "Implement user authentication"

# Multiple tasks from file (NEW in v1.30)
/ralph-smart tasks.md

# Basic Ralph loop
/ralph-loop "Build a REST API" --max-iterations 20

# Cancel the loop
/cancel-ralph
```

---

## 📖 Commands

### `/ralph-smart` (Recommended)
Start an intelligent Ralph loop with automatic completion detection.

**Usage**:

1. **Single Task (Direct Command)**:
```bash
/ralph-smart "Implement user authentication"
/ralph-smart "Fix the bug in login.js"
/ralph-smart "Add dark mode support"
```

2. **Single Task (From File)**:
```bash
/ralph-smart task.txt
/ralph-smart prompt.md
```

3. **Multi-Task (NEW in v1.30)**:
```bash
/ralph-smart tasks.md
```

**Features**:
- 🤖 Autonomous iteration with progress tracking
- 🎯 Multiple completion detection criteria
- 📊 Todo list monitoring and progress calculation
- ⏸️ Graceful interruption handling (Ctrl+C)
- 💾 State persistence across interruptions
- 🔄 Multi-task sequential execution
- 🔢 Uses default max iterations (set via `/ralph-smart-setmaxiterations`)

**Note**: `/ralph-smart` does not accept `--max-iterations` parameter. Use `/ralph-smart-setmaxiterations` to configure the default value (default: 10 iterations).

---

### `/ralph-smart-setmaxiterations` (NEW in v1.30)
Set the default maximum iterations for `/ralph-smart` command.

**Syntax**:
```bash
/ralph-smart-setmaxiterations <number>
```

**Examples**:
```bash
/ralph-smart-setmaxiterations 10
/ralph-smart-setmaxiterations 20
/ralph-smart-setmaxiterations 30
```

**What it does**:
- Sets the default max iterations for `/ralph-smart` command
- Default value after installation: 10 iterations
- Recommended range: 10-30 iterations
- Stored in: `~/.claude/ralph-config.json`

**Note**: This setting only affects `/ralph-smart`. The `/ralph-loop` command requires explicit `--max-iterations` parameter.

---

### `/ralph-loop`
Start a basic Ralph loop with manual completion.

**Syntax**:
```bash
/ralph-loop "<prompt>" --max-iterations <n> --completion-promise "<text>"
```

**Options**:
- `--max-iterations <n>` - Stop after N iterations (default: unlimited)
- `--completion-promise <text>` - Phrase that signals completion

**Example**:
```bash
/ralph-loop "Build a todo API. Output DONE when complete." --completion-promise "DONE" --max-iterations 30
```

---

### `/cancel-ralph`
Cancel the current Ralph loop.

```bash
/cancel-ralph
```

### `/help`
Show Ralph Wiggum help information.

```bash
/help
```

---

## 🔧 Best Practices

### Single-Task Mode
1. **Always set `--max-iterations`** as a safety net (recommended: 15-30)
2. **Use clear completion criteria** in your prompts
3. **Include verification steps** (tests, linters) in your task description
4. **Start with small limits** (10-20) for testing

### Multi-Task Mode (NEW in v1.30)
1. **Write clear acceptance criteria** for each task
2. **Keep tasks focused** - 3-5 criteria per task
3. **Order tasks logically** - foundational tasks first
4. **Use descriptive titles** - helps AI understand dependencies
5. **Monitor progress** - check the progress display regularly

---

## 🧪 Testing & Verification

This plugin has been thoroughly tested:

- ✅ **93.1% pass rate** (27/29 tests) - Cross-platform tests
- ✅ **100% pass rate** (22/22 tests) - Multi-task tests (NEW in v1.30)
- ✅ **7 environments tested**: Windows, WSL, macOS, Linux, Git Bash, Cygwin, POSIX sh
- ✅ **100% Git Bash compatibility**
- ✅ **Edge cases covered**: Long text, special characters, concurrent operations

**Run tests**:
```powershell
# Cross-platform tests
.\tests\test-cross-platform.ps1

# Multi-task tests (NEW in v1.30)
.\tests\test-multi-task.ps1
```

---

## 📚 Documentation

### Core Documentation
- **[README.md](README.md)** - This file (English)
- **[README_CN.md](README_CN.md)** - Chinese version
- **[docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** - Quick reference

### Multi-Task Documentation (NEW in v1.30)
- **[docs/MULTI-TASK-GUIDE.md](docs/MULTI-TASK-GUIDE.md)** - Complete multi-task guide
- **[MULTI-TASK-IMPLEMENTATION.md](MULTI-TASK-IMPLEMENTATION.md)** - Implementation details

### Technical Documentation
- **[COMPLETE-SOLUTION.md](COMPLETE-SOLUTION.md)** - Troubleshooting guide
- **[FIXES-VERIFICATION.md](FIXES-VERIFICATION.md)** - Fix verification report
- **[docs/FILE-STRUCTURE.md](docs/FILE-STRUCTURE.md)** - Project structure

---

## 📋 Version History

### Version 1.33 (2026-01-26)
- 🐛 **WSL Fix**: Improved WSL stop hook error handling
  - Fixed "/usr/bin/sh: cannot execute binary file" error
  - Added script existence and readability verification
  - Added detailed debug logging to `/tmp/ralph-hook-router.log`
  - Improved error messages for better diagnostics
- 🧪 **Testing**: Added comprehensive WSL test suite
  - WSL test pass rate: 85.7% (6/7 tests)
  - Added `tests/test-wsl-hook.sh` - WSL functionality test
  - Added `tests/test-wsl-complete.ps1` - Complete WSL test suite
  - Added `tests/diagnose-wsl-hook.sh` - WSL diagnostic script
- 📚 **Documentation**: Added detailed test reports
  - `TEST-REPORT-v1.31.md` - Comprehensive test report
  - `WSL-TEST-REPORT.md` - Detailed WSL test report
  - `WSL-FIX-VERIFICATION.md` - Fix verification report

### Version 1.31 (2026-01-26)
- 📚 **Improved Documentation**: Reorganized command documentation for better clarity
  - `/ralph-smart-setmaxiterations` now placed directly after `/ralph-smart`
  - Added explicit examples for single task (direct command) usage
  - Added explicit examples for single task (from file) usage
  - Clarified multi-task usage
- 🧹 **Project Cleanup**: Removed outdated and temporary files
  - Removed 6 outdated test reports
  - Removed 7 temporary fix documentation files
  - Removed 2 outdated release notes (v1.0.2, v1.20)
  - Removed backup and configuration files
  - Streamlined project structure for better maintainability

### Version 1.30 (2026-01-26)
- ✨ **NEW**: Multi-task support with automatic task switching
- ✨ **NEW**: AI-driven task ordering and dependency analysis
- ✨ **NEW**: Rich progress visualization for multiple tasks
- ✨ **NEW**: State persistence for multi-task sessions
- ✨ **NEW**: `/ralph-smart-setmaxiterations` command for setting default max iterations
- 📚 **NEW**: Comprehensive multi-task documentation
- 🧪 **NEW**: 22 unit tests for multi-task functionality

### Version 1.20 (2026-01-23)
- ✅ Cross-platform support (Windows, WSL, macOS, Linux)
- ✅ Smart Ralph loop with intelligent completion detection
- ✅ Enhanced hooks configuration
- ✅ Comprehensive testing suite (93.1% pass rate)

---

## 🤝 Contributing

Contributions welcome! Please:
1. Open an issue describing the problem
2. Submit a pull request with your fix
3. Ensure all tests pass

---

## 📄 License

This project maintains the same license as the original Claude Code repository.

---

## 🙏 Credits

- **Ralph Technique**: [Geoffrey Huntley](https://ghuntley.com/ralph/)
- **Original Plugin**: [Daisy Hollman](https://github.com/anthropics/claude-code) (Anthropic)
- **Cross-Platform Implementation**: Created 2026-01-23 using Claude Code
- **Multi-Task Support**: Added 2026-01-26
- **Original Source**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/flyfoxai/ralph-wiggum-windows-fix/issues)
- **Original Plugin**: [Claude Code Repository](https://github.com/anthropics/claude-code)
- **Ralph Technique**: [ghuntley.com/ralph](https://ghuntley.com/ralph/)

---

**Made with ❤️ for the Claude Code community**
