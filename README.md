# Ralph Wiggum Plugin - Windows Platform Fixes

[中文文档](README_CN.md) | English

## 🎯 About This Repository

This repository contains **Windows platform fixes** for the Ralph Wiggum plugin, which is part of [Claude Code](https://github.com/anthropics/claude-code).

### Original Source

- **Original Plugin**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- **Author**: Daisy Hollman (Anthropic)
- **Technique Creator**: [Geoffrey Huntley](https://ghuntley.com/ralph/)

### Why Not Forked?

The Ralph Wiggum plugin is part of the main Claude Code repository, not a standalone repository. Since it's a subdirectory within a larger monorepo, it cannot be forked independently. This repository was created to:

1. **Provide immediate Windows fixes** for users experiencing issues
2. **Document the fixes comprehensively** with detailed testing reports
3. **Serve as a reference** for potential contribution back to the official repository
4. **Enable easy installation** for Windows users without waiting for official updates

### Purpose of This Repository

This repository specifically addresses **two critical Windows platform issues**:

1. **Stop Hook Window Popup** - Fixed the issue where Windows would open `stop-hook.sh` in a text editor instead of executing it
2. **Argument Parsing Failure** - Fixed "command not found" errors when using command-line flags on Windows

**Status**: ✅ Fully tested and verified through 5 complete iterations with 100% success rate.

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

---

## 🔧 What's Fixed

### Issue 1: Stop Hook Window Popup ✅

**Problem**: On Windows, the original plugin would cause a `stop-hook.sh` file window to pop up repeatedly because Windows cannot natively execute `.sh` files.

**Solution**:
- Created PowerShell version: `hooks/stop-hook.ps1`
- Updated `hooks/hooks.json` for platform-specific hooks
- Windows now uses PowerShell, macOS/Linux use Bash

**Verification**: 5 iterations, 0 popup windows

### Issue 2: Argument Parsing Failure ✅

**Problem**: Git Bash on Windows would split multi-line arguments, causing errors like:
```
/usr/bin/bash: line 3: --completion-promise: command not found
```

**Solution**:
- Created PowerShell version: `scripts/setup-ralph-loop.ps1`
- Implemented native PowerShell parameter parsing
- Added support for Chinese characters and special characters

**Verification**: 5 iterations, 0 parsing errors

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

- **[WINDOWS-FIXES.md](WINDOWS-FIXES.md)** - Detailed fix documentation and troubleshooting
- **[VERIFICATION-REPORT.md](VERIFICATION-REPORT.md)** - Test verification report
- **[FINAL-REPORT.md](FINAL-REPORT.md)** - Comprehensive testing report
- **[EXECUTIVE-SUMMARY.md](EXECUTIVE-SUMMARY.md)** - Executive summary
- **[COMPLETION-REPORT.md](COMPLETION-REPORT.md)** - Final completion report

---

## 🧪 Testing

This fix has been thoroughly tested:

- **5 complete iterations** of the Ralph loop
- **100% success rate** across all tests
- **0 errors**, 0 popup windows
- **Edge cases tested**: Long Chinese text, special characters, concurrent operations
- **Stress tested**: Multiple iterations, file operations, state management

Test scripts included:
- `verify-fix.ps1` - Basic verification
- `edge-case-test.ps1` - Edge case testing
- `concurrent-test.ps1` - Concurrent operations
- `final-validation.ps1` - Final validation

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
- **Windows Fixes**: Created 2026-01-22 using Claude Code
- **Testing & Verification**: Automated through Ralph loop (5 iterations)

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
