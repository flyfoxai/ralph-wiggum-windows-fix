# Ralph Wiggum 插件 - Windows 平台修复版

[English](README.md) | 中文文档

## 🎯 关于本仓库

本仓库包含 Ralph Wiggum 插件的 **Windows 平台修复版本**，该插件是 [Claude Code](https://github.com/anthropics/claude-code) 的一部分。

### 原始代码出处

- **原始插件**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- **作者**: Daisy Hollman (Anthropic)
- **技术创始人**: [Geoffrey Huntley](https://ghuntley.com/ralph/)

### 为什么没有 Fork？

Ralph Wiggum 插件是 Claude Code 主仓库的一部分，而不是独立的仓库。由于它是大型单体仓库中的一个子目录，无法单独进行 fork。创建本仓库的原因是：

1. **为遇到问题的用户提供即时的 Windows 修复方案**
2. **提供详细的修复文档和测试报告**
3. **作为向官方仓库贡献的参考**
4. **让 Windows 用户无需等待官方更新即可轻松安装**

### 本仓库的作用

本仓库专门解决 **两个关键的 Windows 平台问题**：

1. **Stop Hook 窗口弹出问题** - 修复了 Windows 会用文本编辑器打开 `stop-hook.sh` 而不是执行它的问题
2. **参数解析失败问题** - 修复了在 Windows 上使用命令行标志时出现 "command not found" 错误的问题

**状态**: ✅ 已通过 5 次完整迭代测试，成功率 100%

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

### 问题 1：Stop Hook 窗口弹出 ✅

**问题描述**：在 Windows 上，原始插件会导致 `stop-hook.sh` 文件窗口反复弹出，因为 Windows 无法原生执行 `.sh` 文件。

**解决方案**：
- 创建了 PowerShell 版本：`hooks/stop-hook.ps1`
- 更新了 `hooks/hooks.json` 以支持平台特定的钩子
- Windows 现在使用 PowerShell，macOS/Linux 使用 Bash

**验证结果**：5 次迭代，0 次弹窗

### 问题 2：参数解析失败 ✅

**问题描述**：Windows 上的 Git Bash 会拆分多行参数，导致如下错误：
```
/usr/bin/bash: line 3: --completion-promise: command not found
```

**解决方案**：
- 创建了 PowerShell 版本：`scripts/setup-ralph-loop.ps1`
- 实现了原生 PowerShell 参数解析
- 添加了对中文字符和特殊字符的支持

**验证结果**：5 次迭代，0 次解析错误

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

- **[WINDOWS-FIXES.md](WINDOWS-FIXES.md)** - 详细的修复文档和故障排除
- **[VERIFICATION-REPORT.md](VERIFICATION-REPORT.md)** - 测试验证报告
- **[FINAL-REPORT.md](FINAL-REPORT.md)** - 综合测试报告
- **[EXECUTIVE-SUMMARY.md](EXECUTIVE-SUMMARY.md)** - 执行摘要
- **[COMPLETION-REPORT.md](COMPLETION-REPORT.md)** - 最终完成报告

---

## 🧪 测试

本修复已经过全面测试：

- **5 次完整迭代** 的 Ralph 循环
- **100% 成功率** 跨所有测试
- **0 个错误**，0 次弹窗
- **边缘案例测试**：长中文文本、特殊字符、并发操作
- **压力测试**：多次迭代、文件操作、状态管理

包含的测试脚本：
- `verify-fix.ps1` - 基础验证
- `edge-case-test.ps1` - 边缘案例测试
- `concurrent-test.ps1` - 并发操作测试
- `final-validation.ps1` - 最终验证

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
- **Windows 修复**：2026-01-22 使用 Claude Code 创建
- **测试与验证**：通过 Ralph 循环自动化（5 次迭代）

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
