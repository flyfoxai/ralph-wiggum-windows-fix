# Ralph Wiggum 插件 - 跨平台版本

**版本 1.20** | [English](README.md) | 中文文档

> 全面支持 Windows、WSL、macOS 和 Linux 的跨平台 Ralph Wiggum 插件。实现 Ralph 技术 - 用于迭代开发的连续自引用 AI 循环。

---

## 🎯 什么是 Ralph Wiggum？

Ralph 是一种基于连续 AI 代理循环的开发方法论。本插件使用 **Stop hook** 拦截 Claude 的退出尝试，创建自引用反馈循环：

```bash
# 你只需运行一次：
/ralph-loop "你的任务描述" --max-iterations 20

# 然后 Claude Code 会自动：
# 1. 处理任务
# 2. 尝试退出
# 3. Stop hook 阻止退出并反馈提示
# 4. 重复直到完成或达到最大迭代次数
```

**核心特性**：
- 🔄 在单个会话内持续迭代
- 🎯 自动任务完成检测
- 🛡️ 最大迭代次数安全限制
- 📊 进度跟踪和状态管理
- 🌍 完整跨平台支持

---

## 🚀 快速开始

### 安装

通过 Claude Code 插件市场安装：

```bash
/plugin install ralph-wiggum
```

### 基本使用

```bash
# 启动 Ralph 循环
/ralph-loop "构建一个带 CRUD 操作的 REST API" --max-iterations 20

# 使用智能 Ralph 循环（自动完成检测）
/ralph-smart "实现暗黑模式" --max-iterations 15

# 取消循环
/cancel-ralph
```

---

## ✨ 本版本更新内容

### A. 修复的问题

#### 1. **跨平台支持** ✅
- **问题**：原始插件仅在 macOS/Linux 上可靠工作
- **解决方案**：全面支持 7 种环境：
  - Windows 原生（PowerShell）
  - WSL（Windows Subsystem for Linux）
  - macOS（Bash）
  - Linux（Bash）
  - Git Bash（POSIX sh）
  - Cygwin（POSIX sh）
  - POSIX sh（通用后备方案）

#### 2. **Windows 特定问题** ✅
- **已修复**：Stop hook 在文本编辑器中打开 `.sh` 文件
- **已修复**：Git Bash 中的参数解析失败
- **已修复**：WSL 路径转换问题
- **已修复**：PowerShell 执行策略错误

#### 3. **智能环境检测** ✅
- 自动检测运行时环境
- 智能路由到适当的实现
- 平台特定优化

**测试结果**：所有平台 93.1% 通过率（27/29 测试）

### B. 新增功能

#### 1. **智能 Ralph 循环** 🆕
具有智能完成检测的增强循环：

```bash
/ralph-smart "你的任务" --max-iterations 15
```

**功能特性**：
- 🤖 自主迭代与进度跟踪
- 🎯 多重完成检测标准
- 📊 待办事项监控和进度计算
- ⏸️ 优雅的中断处理（Ctrl+C）
- 💾 跨中断的状态持久化

**自动停止条件**：
- 检测到任务完成（如 "任务完成"、"全部完成"）
- 所有待办事项标记为完成（100% 进度）
- 找到完成承诺文本
- 达到最大迭代次数
- 用户中断

#### 2. **增强的 Hooks 配置** 🆕
- 嵌套 hooks 结构，更好的组织
- 平台特定的路由逻辑
- 改进的错误处理和诊断

#### 3. **全面的测试套件** 🆕
- 跨平台测试脚本
- 环境特定验证
- 边缘情况覆盖
- 故障排除诊断工具

---

## 📖 命令说明

### `/ralph-loop`
启动基本的 Ralph 循环，手动完成。

**语法**：
```bash
/ralph-loop "<提示>" --max-iterations <次数> --completion-promise "<文本>"
```

**选项**：
- `--max-iterations <n>` - 在 N 次迭代后停止（默认：无限制）
- `--completion-promise <text>` - 表示完成的短语

**示例**：
```bash
/ralph-loop "构建待办事项 API。完成时输出 DONE。" --completion-promise "DONE" --max-iterations 30
```

### `/ralph-smart`
启动智能 Ralph 循环，自动完成检测。

**语法**：
```bash
/ralph-smart "<提示>" --max-iterations <次数>
```

**示例**：
```bash
/ralph-smart "实现用户认证" --max-iterations 20
```

### `/cancel-ralph`
取消当前的 Ralph 循环。

```bash
/cancel-ralph
```

### `/help`
显示 Ralph Wiggum 帮助信息。

```bash
/help
```

---

## 🔧 最佳实践

1. **始终设置 `--max-iterations`** 作为安全网（推荐：15-30）
2. **在提示中使用清晰的完成标准**
3. **在任务描述中包含验证步骤**（测试、代码检查）
4. **从小的限制开始**（10-20）进行测试
5. **对复杂任务使用 `/ralph-smart`** 以实现自动完成

---

## 🧪 测试与验证

本插件已经过全面测试：

- ✅ **93.1% 通过率**（27/29 测试）
- ✅ **测试了 7 种环境**：Windows、WSL、macOS、Linux、Git Bash、Cygwin、POSIX sh
- ✅ **100% Git Bash 兼容性**
- ✅ **覆盖边缘情况**：长文本、特殊字符、并发操作

**运行测试**：
```powershell
.\tests\test-cross-platform.ps1
```

---

## 📚 文档

- **[COMPLETE-SOLUTION.md](COMPLETE-SOLUTION.md)** - 故障排除指南
- **[FIXES-VERIFICATION.md](FIXES-VERIFICATION.md)** - 修复验证报告
- **[docs/FILE-STRUCTURE.md](docs/FILE-STRUCTURE.md)** - 项目结构
- **[docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** - 快速参考

---

## 🤝 贡献

欢迎贡献！请：
1. 提交 issue 描述问题
2. 提交 pull request 附带你的修复
3. 确保所有测试通过

---

## 📄 许可证

本项目保持与原始 Claude Code 仓库相同的许可证。

---

## 🙏 致谢

- **Ralph 技术**：[Geoffrey Huntley](https://ghuntley.com/ralph/)
- **原始插件**：[Daisy Hollman](https://github.com/anthropics/claude-code)（Anthropic）
- **跨平台实现**：2026-01-23 使用 Claude Code 创建
- **原始代码**：[anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)

---

## 📞 支持

- **问题反馈**：[GitHub Issues](https://github.com/flyfoxai/ralph-wiggum-windows-fix/issues)
- **原始插件**：[Claude Code 仓库](https://github.com/anthropics/claude-code)
- **Ralph 技术**：[ghuntley.com/ralph](https://ghuntley.com/ralph/)

---

**用 ❤️ 为 Claude Code 社区制作**
