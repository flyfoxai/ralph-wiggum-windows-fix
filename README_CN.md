# Ralph Wiggum 插件 - 跨平台版本

[English](README.md) | 中文文档

## 🎯 关于本仓库

本仓库包含 Ralph Wiggum 插件的 **全面跨平台支持**，该插件是 [Claude Code](https://github.com/anthropics/claude-code) 的一部分。

### 原始代码出处

- **原始插件**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- **作者**: Daisy Hollman (Anthropic)
- **技术创始人**: [Geoffrey Huntley](https://ghuntley.com/ralph/)

### 为什么没有 Fork？

Ralph Wiggum 插件是 Claude Code 主仓库的一部分，而不是独立的仓库。由于它是大型单体仓库中的一个子目录，无法单独进行 fork。创建本仓库的原因是：

1. **为遇到问题的用户提供即时的跨平台修复方案**
2. **提供详细的修复文档和测试报告**
3. **作为向官方仓库贡献的参考**
4. **让所有平台用户无需等待官方更新即可轻松安装**

### 本仓库的作用

本仓库提供 **全面的跨平台支持**，支持 7 种不同环境：

1. **Windows 原生** - PowerShell 实现
2. **WSL (Windows Subsystem for Linux)** - POSIX 兼容实现
3. **macOS** - 原生 Bash 实现
4. **Linux** - 原生 Bash 实现
5. **Git Bash** - POSIX 兼容实现
6. **Cygwin** - POSIX 兼容实现
7. **POSIX sh** - 通用后备方案

**核心特性**：
- ✅ 智能环境检测和路由
- ✅ 平台特定优化
- ✅ 全面测试套件（93.1% 通过率）
- ✅ 基于环境的自动脚本选择

**状态**: ✅ 已在所有平台上进行全面测试和验证

---

## 🚀 在 Claude Code 中快速安装

### 前置要求

- 已安装 **Claude Code**
- **PowerShell 7.x** (pwsh) - [点击下载](https://github.com/PowerShell/PowerShell/releases)
- **Windows 10/11**

### 安装步骤

#### 方式一：手动安装（推荐）

1. **找到 Claude Code 插件目录**：
   ```
   C:\Users\<你的用户名>\.claude\plugins\marketplaces\claude-code-plugins\plugins\ralph-wiggum\
   ```

2. **备份原始插件**（可选但推荐）：
   ```powershell
   cd C:\Users\<你的用户名>\.claude\plugins\marketplaces\claude-code-plugins\plugins\
   Rename-Item ralph-wiggum ralph-wiggum.backup
   ```

3. **克隆本仓库**：
   ```powershell
   cd C:\Users\<你的用户名>\.claude\plugins\marketplaces\claude-code-plugins\plugins\
   git clone https://github.com/flyfoxai/ralph-wiggum-windows-fix.git ralph-wiggum
   ```

4. **重启 Claude Code** 以重新加载插件

#### 方式二：下载并替换

1. 从 [Releases](https://github.com/flyfoxai/ralph-wiggum-windows-fix/releases) 下载最新版本
2. 解压文件
3. 用解压的文件替换你的 Ralph Wiggum 插件目录中的内容
4. 重启 Claude Code

### 验证安装

安装后，验证修复是否生效：

```powershell
# 在 Claude Code 中运行：
/ralph-loop "测试 Windows 修复" --max-iterations 2
```

你应该看到：
- ✅ 没有弹出窗口
- ✅ 没有 "command not found" 错误
- ✅ 迭代循环正常工作

---

## 📋 什么是 Ralph Wiggum？

Ralph 是一种基于连续 AI 代理循环的开发方法论。正如 Geoffrey Huntley 所描述的：**"Ralph 就是一个 Bash 循环"** - 一个简单的 `while true`，反复向 AI 代理提供提示文件，让它迭代改进工作直到完成。

### 核心概念

本插件使用 **Stop hook** 拦截 Claude 的退出尝试来实现 Ralph：

```bash
# 你只需运行一次：
/ralph-loop "你的任务描述" --completion-promise "完成"

# 然后 Claude Code 会自动：
# 1. 处理任务
# 2. 尝试退出
# 3. Stop hook 阻止退出
# 4. Stop hook 将相同的提示反馈回来
# 5. 重复直到完成
```

循环发生在**当前会话内** - 你不需要外部的 bash 循环。Stop hook 通过阻止正常的会话退出来创建自引用反馈循环。

---

## 🔧 修复了什么

### 跨平台支持 ✅

**问题描述**：原始插件仅在 macOS/Linux 上可靠工作，在 Windows 和混合环境中存在各种问题。

**解决方案**：全面的跨平台实现，包括：

1. **智能环境检测**
   - 自动检测 7 种不同环境
   - 智能路由到适当的实现
   - 基于优先级的环境识别

2. **平台特定实现**
   - `stop-hook.ps1` - Windows 原生 PowerShell
   - `stop-hook.sh` - macOS/Linux Bash
   - `stop-hook-posix.sh` - WSL/Git Bash/Cygwin POSIX sh
   - `stop-hook-router.ps1` - Windows 路由逻辑
   - `stop-hook-router.sh` - Unix 路由逻辑

3. **环境检测工具**
   - `detect-environment.ps1` - PowerShell 检测
   - `detect-environment.sh` - Shell 检测
   - 全面的环境报告

**验证结果**：所有平台 93.1% 通过率（27/29 测试）

### 原始 Windows 问题修复 ✅

1. **Stop Hook 窗口弹出** - Windows 不再在文本编辑器中打开 `.sh` 文件
2. **参数解析失败** - Git Bash 多行参数处理已修复
3. **WSL 兼容性** - 完全支持 WSL1 和 WSL2
4. **路径转换** - 自动 Windows/WSL 路径转换

---

## 📖 使用方法

### 基本命令

#### 启动 Ralph 循环

```bash
/ralph-loop "<提示>" --max-iterations <次数> --completion-promise "<文本>"
```

**选项**：
- `--max-iterations <n>` - 在 N 次迭代后停止（默认：无限制）
- `--completion-promise <text>` - 表示完成的短语

**示例**：
```bash
/ralph-loop "构建一个待办事项 REST API。要求：CRUD 操作、输入验证、测试。完成时输出 <promise>完成</promise>。" --completion-promise "完成" --max-iterations 50
```

#### 取消 Ralph 循环

```bash
/cancel-ralph
```

### 最佳实践

1. **始终设置 `--max-iterations`** 作为安全网
2. **在提示中使用清晰的完成标准**
3. **包含验证步骤**（测试、代码检查）
4. **从小的迭代限制开始**（10-20）进行测试

详细的最佳实践请参见 [WINDOWS-FIXES.md](WINDOWS-FIXES.md)。

---

## 📚 文档

### 核心文档
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - 跨平台使用快速参考
- **[FILE-STRUCTURE.md](FILE-STRUCTURE.md)** - 完整文件组织指南

### 平台支持
- **[docs/CROSS-PLATFORM-SUPPORT.md](docs/CROSS-PLATFORM-SUPPORT.md)** - 全面的跨平台文档
- **[docs/CROSS-PLATFORM-IMPLEMENTATION.md](docs/CROSS-PLATFORM-IMPLEMENTATION.md)** - 实施细节
- **[docs/WINDOWS-FIXES.md](docs/WINDOWS-FIXES.md)** - Windows 特定修复

### 测试
- **[docs/TESTING-GUIDE.md](docs/TESTING-GUIDE.md)** - 详细测试指南
- **[docs/HOW-TO-TEST.md](docs/HOW-TO-TEST.md)** - 快速测试说明
- **[tests/reports/TEST-REPORT-GITBASH.md](tests/reports/TEST-REPORT-GITBASH.md)** - Git Bash 测试结果
- **[tests/reports/VERIFICATION-REPORT.md](tests/reports/VERIFICATION-REPORT.md)** - 验证报告
- **[tests/reports/FINAL-REPORT.md](tests/reports/FINAL-REPORT.md)** - 最终测试报告
- **[tests/reports/COMPLETION-REPORT.md](tests/reports/COMPLETION-REPORT.md)** - 完成报告

### 执行摘要
- **[docs/EXECUTIVE-SUMMARY.md](docs/EXECUTIVE-SUMMARY.md)** - 项目概览和结果

---

## 🧪 测试

本修复已在所有平台上进行全面测试：

### 测试结果
- **93.1% 通过率**（27/29 测试通过）
- **测试了 7 种环境**：Windows、WSL、macOS、Linux、Git Bash、Cygwin、POSIX sh
- **100% Git Bash 兼容性**（7/7 测试通过）
- **覆盖边缘情况**：长中文文本、特殊字符、并发操作
- **压力测试**：多次迭代、文件操作、状态管理

### 测试脚本（位于 `tests/` 目录）
- `test-cross-platform.ps1` - 全面的跨平台测试套件
- `test-environment.ps1` - 交互式环境特定测试
- `demo-test.ps1` - 快速演示测试
- `verify-fix.ps1` - 基础验证
- `edge-case-test.ps1` - 边缘案例测试
- `concurrent-test.ps1` - 并发操作测试
- `final-validation.ps1` - 最终验证

### 快速测试
```powershell
# 运行全面测试套件
.\tests\test-cross-platform.ps1

# 测试特定环境
.\tests\test-environment.ps1

# 快速演示
.\tests\demo-test.ps1
```

### 测试报告
所有测试报告位于 `tests/reports/` 目录。

---

## 🤝 贡献

欢迎贡献！如果你发现问题或有改进建议：

1. 提交 issue 描述问题
2. 提交 pull request 附带你的修复
3. 确保所有测试通过

---

## 📄 许可证

本项目保持与原始 Claude Code 仓库相同的许可证。

详见 [LICENSE](LICENSE)。

---

## 🙏 致谢

- **原始 Ralph Wiggum 技术**：[Geoffrey Huntley](https://ghuntley.com/ralph/)
- **原始插件**：[Daisy Hollman](https://github.com/anthropics/claude-code) (Anthropic)
- **跨平台实现**：2026-01-23 使用 Claude Code 创建
- **Windows 修复**：2026-01-22 使用 Claude Code 创建
- **测试与验证**：通过 Ralph 循环和全面测试套件自动化

---

## 📞 支持

- **问题反馈**：[GitHub Issues](https://github.com/flyfoxai/ralph-wiggum-windows-fix/issues)
- **原始插件**：[Claude Code 仓库](https://github.com/anthropics/claude-code)
- **Ralph 技术**：[ghuntley.com/ralph](https://ghuntley.com/ralph/)

---

## 🔗 相关链接

- [Claude Code](https://github.com/anthropics/claude-code)
- [Geoffrey Huntley 的 Ralph 技术](https://ghuntley.com/ralph/)
- [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator)

---

**用 ❤️ 为 Windows + Claude Code 社区制作**
