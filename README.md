# Ralph Wiggum Plugin - Cross-Platform Edition

[中文文档](README_CN.md) | English

## 🎯 About This Repository

This repository contains **comprehensive cross-platform support** for the Ralph Wiggum plugin, which is part of [Claude Code](https://github.com/anthropics/claude-code).

### Original Source

- **Original Plugin**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- **Author**: Daisy Hollman (Anthropic)
- **Technique Creator**: [Geoffrey Huntley](https://ghuntley.com/ralph/)

### Why Not Forked?

The Ralph Wiggum plugin is part of the main Claude Code repository, not a standalone repository. Since it's a subdirectory within a larger monorepo, it cannot be forked independently. This repository was created to:

1. **Provide immediate cross-platform fixes** for users experiencing issues
2. **Document the fixes comprehensively** with detailed testing reports
3. **Serve as a reference** for potential contribution back to the official repository
4. **Enable easy installation** for all platform users without waiting for official updates

### Purpose of This Repository

This repository provides **comprehensive cross-platform support** for 7 different environments:

1. **Windows Native** - PowerShell implementation
2. **WSL (Windows Subsystem for Linux)** - POSIX-compatible implementation
3. **macOS** - Native Bash implementation
4. **Linux** - Native Bash implementation
5. **Git Bash** - POSIX-compatible implementation
6. **Cygwin** - POSIX-compatible implementation
7. **POSIX sh** - Universal fallback

**Key Features**:
- ✅ Intelligent environment detection and routing
- ✅ Platform-specific optimizations
- ✅ Comprehensive testing suite (93.1% pass rate)
- ✅ Automatic script selection based on environment

**Status**: ✅ Fully tested across all platforms with comprehensive verification.

---

## 🚀 Quick Installation for Claude Code

### Prerequisites

- **Claude Code** installed
- **PowerShell 7.x** (pwsh) - [Download here](https://github.com/PowerShell/PowerShell/releases)
- **Windows 10/11**

### Installation Steps

#### Option 1: Manual Installation (Recommended)

1. **Locate your Claude Code plugins directory**:
   ```
   C:\Users\<YourUsername>\.claude\plugins\marketplaces\claude-code-plugins\plugins\ralph-wiggum\
   ```

2. **Backup the original plugin** (optional but recommended):
   ```powershell
   cd C:\Users\<YourUsername>\.claude\plugins\marketplaces\claude-code-plugins\plugins\
   Rename-Item ralph-wiggum ralph-wiggum.backup
   ```

3. **Clone this repository**:
   ```powershell
   cd C:\Users\<YourUsername>\.claude\plugins\marketplaces\claude-code-plugins\plugins\
   git clone https://github.com/flyfoxai/ralph-wiggum-windows-fix.git ralph-wiggum
   ```

4. **Restart Claude Code** to reload the plugin

#### Option 2: Download and Replace

1. Download the latest release from [Releases](https://github.com/flyfoxai/ralph-wiggum-windows-fix/releases)
2. Extract the files
3. Replace the contents of your Ralph Wiggum plugin directory with the extracted files
4. Restart Claude Code

### Verification

After installation, verify the fix is working:

```powershell
# In Claude Code, run:
/ralph-loop "Test Windows fix" --max-iterations 2
```

You should see:
- ✅ No popup windows
- ✅ No "command not found" errors
- ✅ Proper iteration loop working

---

## 📋 What is Ralph Wiggum?

Ralph is a development methodology based on continuous AI agent loops. As Geoffrey Huntley describes it: **"Ralph is a Bash loop"** - a simple `while true` that repeatedly feeds an AI agent a prompt file, allowing it to iteratively improve its work until completion.

### Core Concept

This plugin implements Ralph using a **Stop hook** that intercepts Claude's exit attempts:

```bash
# You run ONCE:
/ralph-loop "Your task description" --completion-promise "DONE"

# Then Claude Code automatically:
# 1. Works on the task
# 2. Tries to exit
# 3. Stop hook blocks exit
# 4. Stop hook feeds the SAME prompt back
# 5. Repeat until completion
```

The loop happens **inside your current session** - you don't need external bash loops. The Stop hook creates the self-referential feedback loop by blocking normal session exit.

### Smart Ralph Loop ✨ NEW

The **Smart Ralph Loop** is an enhanced version with intelligent completion detection:

```bash
/ralph-smart "Your task description" --max-iterations 15
```

**Key Features**:
- 🤖 **Autonomous Iteration**: Automatically continues until task completion
- 🎯 **Intelligent Completion Detection**: Multiple criteria for detecting when work is done
- 📊 **Progress Tracking**: Monitors todo lists and calculates completion percentage
- ⏸️ **Graceful Interruption**: Ctrl+C saves state and stops cleanly
- 💾 **State Persistence**: Maintains state across interruptions
- ⚙️ **Flexible Configuration**: Customize iterations and completion criteria

**The loop automatically stops when**:
- Task completion is detected (e.g., "task completed", "all done")
- All todos are marked complete (100% progress)
- Completion promise text is found
- Max iterations reached
- User interrupts (Ctrl+C)

**Example**:
```bash
/ralph-smart "Implement dark mode" --max-iterations 20 --completion-promise "All tests passing"
```

See [Smart Ralph Loop Documentation](docs/smart-ralph-loop.md) for details.

---

## 🔧 What's Fixed

### Cross-Platform Support ✅

**Problem**: The original plugin only worked reliably on macOS/Linux, with various issues on Windows and hybrid environments.

**Solution**: Comprehensive cross-platform implementation with:

1. **Intelligent Environment Detection**
   - Automatic detection of 7 different environments
   - Smart routing to appropriate implementation
   - Priority-based environment identification

2. **Platform-Specific Implementations**
   - `stop-hook.ps1` - Windows native PowerShell
   - `stop-hook.sh` - macOS/Linux Bash
   - `stop-hook-posix.sh` - WSL/Git Bash/Cygwin POSIX sh
   - `stop-hook-router.ps1` - Windows routing logic
   - `stop-hook-router.sh` - Unix routing logic

3. **Environment Detection Tools**
   - `detect-environment.ps1` - PowerShell detection
   - `detect-environment.sh` - Shell detection
   - Comprehensive environment reporting

**Verification**: 93.1% pass rate (27/29 tests) across all platforms

### Original Windows Issues Fixed ✅

1. **Stop Hook Window Popup** - Windows no longer opens `.sh` files in text editor
2. **Argument Parsing Failure** - Git Bash multi-line argument handling fixed
3. **WSL Compatibility** - Full support for WSL1 and WSL2
4. **Path Conversion** - Automatic Windows/WSL path translation

---

## 📖 Usage

### Basic Commands

#### Start a Ralph Loop

```bash
/ralph-loop "<prompt>" --max-iterations <n> --completion-promise "<text>"
```

**Options**:
- `--max-iterations <n>` - Stop after N iterations (default: unlimited)
- `--completion-promise <text>` - Phrase that signals completion

**Example**:
```bash
/ralph-loop "Build a REST API for todos. Requirements: CRUD operations, input validation, tests. Output <promise>COMPLETE</promise> when done." --completion-promise "COMPLETE" --max-iterations 50
```

#### Cancel a Ralph Loop

```bash
/cancel-ralph
```

### Best Practices

1. **Always set `--max-iterations`** as a safety net
2. **Use clear completion criteria** in your prompts
3. **Include verification steps** (tests, linters)
4. **Start with small iteration limits** (10-20) for testing

For detailed best practices, see [WINDOWS-FIXES.md](WINDOWS-FIXES.md).

---

## 📚 Documentation

### Core Documentation
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Quick reference for cross-platform usage
- **[FILE-STRUCTURE.md](FILE-STRUCTURE.md)** - Complete file organization guide

### Platform Support
- **[docs/CROSS-PLATFORM-SUPPORT.md](docs/CROSS-PLATFORM-SUPPORT.md)** - Comprehensive cross-platform documentation
- **[docs/CROSS-PLATFORM-IMPLEMENTATION.md](docs/CROSS-PLATFORM-IMPLEMENTATION.md)** - Implementation details
- **[docs/WINDOWS-FIXES.md](docs/WINDOWS-FIXES.md)** - Windows-specific fixes

### Testing
- **[docs/TESTING-GUIDE.md](docs/TESTING-GUIDE.md)** - Detailed testing guide
- **[docs/HOW-TO-TEST.md](docs/HOW-TO-TEST.md)** - Quick testing instructions
- **[tests/reports/TEST-REPORT-GITBASH.md](tests/reports/TEST-REPORT-GITBASH.md)** - Git Bash test results
- **[tests/reports/VERIFICATION-REPORT.md](tests/reports/VERIFICATION-REPORT.md)** - Verification report
- **[tests/reports/FINAL-REPORT.md](tests/reports/FINAL-REPORT.md)** - Final test report
- **[tests/reports/COMPLETION-REPORT.md](tests/reports/COMPLETION-REPORT.md)** - Completion report

### Executive Summary
- **[docs/EXECUTIVE-SUMMARY.md](docs/EXECUTIVE-SUMMARY.md)** - Project overview and results

---

## 🧪 Testing

This fix has been thoroughly tested across all platforms:

### Test Results
- **93.1% pass rate** (27/29 tests passed)
- **7 environments tested**: Windows, WSL, macOS, Linux, Git Bash, Cygwin, POSIX sh
- **100% Git Bash compatibility** (7/7 tests passed)
- **Edge cases covered**: Long Chinese text, special characters, concurrent operations
- **Stress tested**: Multiple iterations, file operations, state management

### Test Scripts (in `tests/` directory)
- `test-cross-platform.ps1` - Comprehensive cross-platform test suite
- `test-environment.ps1` - Interactive environment-specific testing
- `demo-test.ps1` - Quick demonstration test
- `verify-fix.ps1` - Basic verification
- `edge-case-test.ps1` - Edge case testing
- `concurrent-test.ps1` - Concurrent operations
- `final-validation.ps1` - Final validation

### Quick Test
```powershell
# Run comprehensive test suite
.\tests\test-cross-platform.ps1

# Test specific environment
.\tests\test-environment.ps1

# Quick demo
.\tests\demo-test.ps1
```

### Test Reports
All test reports are available in `tests/reports/` directory.

---

## 🤝 Contributing

Contributions are welcome! If you find issues or have improvements:

1. Open an issue describing the problem
2. Submit a pull request with your fix
3. Ensure all tests pass

---

## 📄 License

This project maintains the same license as the original Claude Code repository.

See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- **Original Ralph Wiggum Technique**: [Geoffrey Huntley](https://ghuntley.com/ralph/)
- **Original Plugin**: [Daisy Hollman](https://github.com/anthropics/claude-code) (Anthropic)
- **Cross-Platform Implementation**: Created 2026-01-23 using Claude Code
- **Windows Fixes**: Created 2026-01-22 using Claude Code
- **Testing & Verification**: Automated through Ralph loop and comprehensive test suites

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/flyfoxai/ralph-wiggum-windows-fix/issues)
- **Original Plugin**: [Claude Code Repository](https://github.com/anthropics/claude-code)
- **Ralph Technique**: [ghuntley.com/ralph](https://ghuntley.com/ralph/)

---

## 🔗 Related Links

- [Claude Code](https://github.com/anthropics/claude-code)
- [Ralph Technique by Geoffrey Huntley](https://ghuntley.com/ralph/)
- [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator)

---

**Made with ❤️ for the Windows + Claude Code community**
