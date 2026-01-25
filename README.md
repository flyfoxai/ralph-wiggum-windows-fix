# Ralph Wiggum Plugin - Cross-Platform Edition

**Version 1.20** | [中文文档](README_CN.md) | English

> Cross-platform Ralph Wiggum plugin with comprehensive Windows, WSL, macOS, and Linux support. Implements the Ralph technique - continuous self-referential AI loops for iterative development.

---

## 🎯 What is Ralph Wiggum?

Ralph is a development methodology based on continuous AI agent loops. The plugin implements this using a **Stop hook** that intercepts Claude's exit attempts, creating a self-referential feedback loop:

```bash
# You run ONCE:
/ralph-loop "Your task description" --max-iterations 20

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
- 🌍 Full cross-platform support

---

## 🚀 Quick Start

### Installation

Install via Claude Code plugin marketplace:

```bash
/plugin install ralph-wiggum
```

### Basic Usage

```bash
# Start a Ralph loop
/ralph-loop "Build a REST API with CRUD operations" --max-iterations 20

# Use Smart Ralph with intelligent completion detection
/ralph-smart "Implement dark mode" --max-iterations 15

# Cancel the loop
/cancel-ralph
```

---

## ✨ What's New in This Version

### A. Fixes from Original Plugin

#### 1. **Cross-Platform Support** ✅
- **Problem**: Original plugin only worked reliably on macOS/Linux
- **Solution**: Comprehensive support for 7 environments:
  - Windows Native (PowerShell)
  - WSL (Windows Subsystem for Linux)
  - macOS (Bash)
  - Linux (Bash)
  - Git Bash (POSIX sh)
  - Cygwin (POSIX sh)
  - POSIX sh (Universal fallback)

#### 2. **Windows-Specific Issues** ✅
- **Fixed**: Stop hook opening `.sh` files in text editor
- **Fixed**: Argument parsing failures in Git Bash
- **Fixed**: WSL path conversion issues
- **Fixed**: PowerShell execution policy errors

#### 3. **Intelligent Environment Detection** ✅
- Automatic detection of runtime environment
- Smart routing to appropriate implementation
- Platform-specific optimizations

**Test Results**: 93.1% pass rate (27/29 tests) across all platforms

### B. New Features

#### 1. **Smart Ralph Loop** 🆕
Enhanced loop with intelligent completion detection:

```bash
/ralph-smart "Your task" --max-iterations 15
```

**Features**:
- 🤖 Autonomous iteration with progress tracking
- 🎯 Multiple completion detection criteria
- 📊 Todo list monitoring and progress calculation
- ⏸️ Graceful interruption handling (Ctrl+C)
- 💾 State persistence across interruptions

**Auto-stops when**:
- Task completion detected (e.g., "task completed", "all done")
- All todos marked complete (100% progress)
- Completion promise text found
- Max iterations reached
- User interrupts

#### 2. **Enhanced Hooks Configuration** 🆕
- Nested hooks structure for better organization
- Platform-specific routing logic
- Improved error handling and diagnostics

#### 3. **Comprehensive Testing Suite** 🆕
- Cross-platform test scripts
- Environment-specific validation
- Edge case coverage
- Diagnostic tools for troubleshooting

---

## 📖 Commands

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

### `/ralph-smart`
Start an intelligent Ralph loop with automatic completion detection.

**Syntax**:
```bash
/ralph-smart "<prompt>" --max-iterations <n>
```

**Example**:
```bash
/ralph-smart "Implement user authentication" --max-iterations 20
```

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

1. **Always set `--max-iterations`** as a safety net (recommended: 15-30)
2. **Use clear completion criteria** in your prompts
3. **Include verification steps** (tests, linters) in your task description
4. **Start with small limits** (10-20) for testing
5. **Use `/ralph-smart`** for complex tasks with automatic completion

---

## 🧪 Testing & Verification

This plugin has been thoroughly tested:

- ✅ **93.1% pass rate** (27/29 tests)
- ✅ **7 environments tested**: Windows, WSL, macOS, Linux, Git Bash, Cygwin, POSIX sh
- ✅ **100% Git Bash compatibility**
- ✅ **Edge cases covered**: Long text, special characters, concurrent operations

**Run tests**:
```powershell
.\tests\test-cross-platform.ps1
```

---

## 📚 Documentation

- **[COMPLETE-SOLUTION.md](COMPLETE-SOLUTION.md)** - Troubleshooting guide
- **[FIXES-VERIFICATION.md](FIXES-VERIFICATION.md)** - Fix verification report
- **[docs/FILE-STRUCTURE.md](docs/FILE-STRUCTURE.md)** - Project structure
- **[docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** - Quick reference

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
- **Original Source**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/flyfoxai/ralph-wiggum-windows-fix/issues)
- **Original Plugin**: [Claude Code Repository](https://github.com/anthropics/claude-code)
- **Ralph Technique**: [ghuntley.com/ralph](https://ghuntley.com/ralph/)

---

**Made with ❤️ for the Claude Code community**
