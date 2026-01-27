# Ralph Wiggum Plugin - Cross-Platform Edition

**Version 1.35** | [中文文档](README_CN.md) | English

> Cross-platform Ralph Wiggum plugin for Windows, WSL, macOS, and Linux.

---

## Introduction

A. Fix: Stop hook path translation for WSL/Git Bash to avoid bash path errors.
B. Feature: `/ralph-smart` multi-task mode for sequential tasks with automatic completion detection (v1.30+).

---

## Quick Start

1) Install
```bash
/plugin install https://github.com/flyfoxai/ralph-wiggum-windows-fix.git
# or: /plugin install ralph-wiggum-cross-platform
```

2) Run a task
```bash
/ralph-smart "Implement user authentication"
```

3) Optional: multi-task or default iterations
```bash
/ralph-smart tasks.md
/ralph-smart-setmaxiterations 15
```

Note: For the original plugin, use `/plugin install ralph-wiggum`.

---

## Ralph Project Overview

Ralph is a development method based on continuous AI agent loops. The plugin uses a Stop hook to intercept exit attempts and feed the prompt back to Claude until completion or max iterations.

```bash
/ralph-smart "Implement user authentication"
# Claude Code works, attempts to exit, gets stopped, and continues until done.
```

---

## Commands (Brief)

- `/ralph-smart` - Smart loop with automatic completion detection.
- `/ralph-smart-setmaxiterations` - Set default max iterations for `/ralph-smart`.
- `/ralph-loop` - Basic loop with manual completion.
- `/cancel-ralph` - Cancel the current loop.
- `/help` - Show help.

---

## Documentation

- Quick reference: `docs/QUICK-REFERENCE.md`
- Multi-task guide: `docs/MULTI-TASK-GUIDE.md`
- Changelog: `CHANGELOG.md`

---

## License

See `LICENSE`.
