# Ralph Wiggum Plugin - Cross-Platform Edition

**Version 1.30** | [中文文档](README_CN.md) | English

> Cross-platform Ralph Wiggum plugin with comprehensive Windows, WSL, macOS, and Linux support. Implements the Ralph technique - continuous self-referential AI loops for iterative development.

---

## ✨ What's New in Version 1.30

### 🎯 Multi-Task Support (NEW!)

Execute multiple related tasks sequentially with automatic task switching:

```bash
# Create a task file with multiple tasks
/ralph-smart tasks.md
```

**Key Features**:
- 🔄 **Sequential Execution** - Tasks run one after another automatically
- 🤖 **AI Task Ordering** - Analyzes dependencies and determines optimal order
- 📊 **Progress Tracking** - Real-time progress across all tasks
- ✅ **Auto-Switching** - Moves to next task when current completes (≥90%)
- 💾 **State Persistence** - Resume after interruptions
- 📈 **Rich Visualization** - Beautiful progress display with status indicators

**Example Task File**:
```markdown
## Task 1: Create Database Schema
**Description**: Set up database structure
**Acceptance Criteria**:
- [ ] Create User table
- [ ] Create Posts table
- [ ] Add indexes

## Task 2: Implement API
**Description**: Build REST endpoints
**Acceptance Criteria**:
- [ ] GET /users endpoint
- [ ] POST /users endpoint
- [ ] Add validation

## Task 3: Write Tests
**Description**: Comprehensive test coverage
**Acceptance Criteria**:
- [ ] API tests
- [ ] Database tests
- [ ] 80%+ coverage
```

**Progress Display**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Smart Ralph - Multi-Task Progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Total Progress: 1/3 tasks complete (33%)
🔁 Total Iterations: 15

✅ Task 1: Create Database Schema (100% - 8 iterations)
● Task 2: Implement API (60% - 7 iterations) ← Current
☐ Task 3: Write Tests (0%)

🤖 AI Recommended Order: 1 → 2 → 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Implementation Details**:
- 1,188 lines of new code
- 22 unit tests (100% pass rate)
- Full documentation included
- See [MULTI-TASK-GUIDE.md](docs/MULTI-TASK-GUIDE.md) for complete guide

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
# Single task with Smart Ralph
/ralph-smart "Implement user authentication" --max-iterations 15

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

**Single Task**:
```bash
/ralph-smart "<prompt>" --max-iterations <n>
```

**Multi-Task** (NEW in v1.30):
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

### Version 1.30 (2026-01-26)
- ✨ **NEW**: Multi-task support with automatic task switching
- ✨ **NEW**: AI-driven task ordering and dependency analysis
- ✨ **NEW**: Rich progress visualization for multiple tasks
- ✨ **NEW**: State persistence for multi-task sessions
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
