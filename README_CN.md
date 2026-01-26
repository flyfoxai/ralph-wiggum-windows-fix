# Ralph Wiggum 插件 - 跨平台版本

**版本 1.33** | [English](README.md) | 中文文档

> 全面支持 Windows、WSL、macOS 和 Linux 的跨平台 Ralph Wiggum 插件。实现 Ralph 技术 - 用于迭代开发的连续自引用 AI 循环。

---

## ✨ 版本 1.30 更新内容

### 🎯 多任务支持（全新功能！）

自动顺序执行多个相关任务，支持自动任务切换：

```bash
# 创建包含多个任务的任务文件
/ralph-smart tasks.md
```

**核心特性**：
- 🔄 **顺序执行** - 任务自动依次执行
- 🤖 **AI 任务排序** - 分析依赖关系并确定最优顺序
- 📊 **进度跟踪** - 实时显示所有任务的进度
- ✅ **自动切换** - 当前任务完成（≥90%）时自动切换到下一个
- 💾 **状态持久化** - 支持中断后恢复
- 📈 **丰富可视化** - 精美的进度显示和状态指示器

**任务文件示例**：
```markdown
## 任务 1: 创建数据库架构
**描述**: 建立数据库结构
**验收标准**:
- [ ] 创建 User 表
- [ ] 创建 Posts 表
- [ ] 添加索引

## 任务 2: 实现 API
**描述**: 构建 REST 端点
**验收标准**:
- [ ] GET /users 端点
- [ ] POST /users 端点
- [ ] 添加验证

## 任务 3: 编写测试
**描述**: 全面的测试覆盖
**验收标准**:
- [ ] API 测试
- [ ] 数据库测试
- [ ] 80%+ 覆盖率
```

**进度显示**：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Smart Ralph - 多任务进度
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 总进度: 1/3 任务完成 (33%)
🔁 总迭代: 15 次

✅ 任务1: 创建数据库架构 (100% - 8次迭代)
● 任务2: 实现 API (60% - 7次迭代) ← 当前
☐ 任务3: 编写测试 (0%)

🤖 AI 建议顺序: 1 → 2 → 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**实现详情**：
- 新增 1,188 行代码
- 22 个单元测试（100% 通过率）
- 包含完整文档
- 详见 [MULTI-TASK-GUIDE.md](docs/MULTI-TASK-GUIDE.md) 完整指南

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
- 🎯 多任务顺序执行（v1.30 新增）

---

## 🚀 快速开始

### 安装

通过 Claude Code 插件市场安装：

```bash
/plugin install ralph-wiggum
```

### 基本使用

```bash
# 设置默认最大迭代次数（v1.30 新增）
/ralph-smart-setmaxiterations 10

# 单任务智能 Ralph（使用默认最大迭代次数）
/ralph-smart "实现用户认证"

# 从文件执行多任务（v1.30 新增）
/ralph-smart tasks.md

# 基本 Ralph 循环
/ralph-loop "构建 REST API" --max-iterations 20

# 取消循环
/cancel-ralph
```

---

## 📖 命令说明

### `/ralph-smart`（推荐）
启动智能 Ralph 循环，自动完成检测。

**使用方式**：

1. **单任务（直接命令）**：
```bash
/ralph-smart "实现用户认证"
/ralph-smart "修复 login.js 中的 bug"
/ralph-smart "添加暗黑模式支持"
```

2. **单任务（从文件）**：
```bash
/ralph-smart task.txt
/ralph-smart prompt.md
```

3. **多任务（v1.30 新增）**：
```bash
/ralph-smart tasks.md
```

**功能特性**：
- 🤖 自主迭代与进度跟踪
- 🎯 多重完成检测标准
- 📊 待办事项监控和进度计算
- ⏸️ 优雅的中断处理（Ctrl+C）
- 💾 跨中断的状态持久化
- 🔄 多任务顺序执行
- 🔢 使用默认最大迭代次数（通过 `/ralph-smart-setmaxiterations` 设置）

**注意**：`/ralph-smart` 不接受 `--max-iterations` 参数。使用 `/ralph-smart-setmaxiterations` 配置默认值（默认：10 次迭代）。

---

### `/ralph-smart-setmaxiterations`（v1.30 新增）
设置 `/ralph-smart` 命令的默认最大迭代次数。

**语法**：
```bash
/ralph-smart-setmaxiterations <数字>
```

**示例**：
```bash
/ralph-smart-setmaxiterations 10
/ralph-smart-setmaxiterations 20
/ralph-smart-setmaxiterations 30
```

**功能说明**：
- 为 `/ralph-smart` 命令设置默认最大迭代次数
- 安装后默认值：10 次迭代
- 推荐范围：10-30 次迭代
- 存储位置：`~/.claude/ralph-config.json`

**注意**：此设置仅影响 `/ralph-smart` 命令。`/ralph-loop` 命令需要显式指定 `--max-iterations` 参数。

---

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

---

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

### 单任务模式
1. **始终设置 `--max-iterations`** 作为安全网（推荐：15-30）
2. **在提示中使用清晰的完成标准**
3. **在任务描述中包含验证步骤**（测试、代码检查）
4. **从小的限制开始**（10-20）进行测试

### 多任务模式（v1.30 新增）
1. **为每个任务编写清晰的验收标准**
2. **保持任务聚焦** - 每个任务 3-5 个标准
3. **合理排序任务** - 基础任务优先
4. **使用描述性标题** - 帮助 AI 理解依赖关系
5. **监控进度** - 定期检查进度显示

---

## 🧪 测试与验证

本插件已经过全面测试：

- ✅ **93.1% 通过率**（27/29 测试）- 跨平台测试
- ✅ **100% 通过率**（22/22 测试）- 多任务测试（v1.30 新增）
- ✅ **测试了 7 种环境**：Windows、WSL、macOS、Linux、Git Bash、Cygwin、POSIX sh
- ✅ **100% Git Bash 兼容性**
- ✅ **覆盖边缘情况**：长文本、特殊字符、并发操作

**运行测试**：
```powershell
# 跨平台测试
.\tests\test-cross-platform.ps1

# 多任务测试（v1.30 新增）
.\tests\test-multi-task.ps1
```

---

## 📚 文档

### 核心文档
- **[README.md](README.md)** - 英文版
- **[README_CN.md](README_CN.md)** - 本文件（中文版）
- **[docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md)** - 快速参考

### 多任务文档（v1.30 新增）
- **[docs/MULTI-TASK-GUIDE.md](docs/MULTI-TASK-GUIDE.md)** - 完整多任务指南
- **[MULTI-TASK-IMPLEMENTATION.md](MULTI-TASK-IMPLEMENTATION.md)** - 实现细节

### 技术文档
- **[COMPLETE-SOLUTION.md](COMPLETE-SOLUTION.md)** - 故障排除指南
- **[FIXES-VERIFICATION.md](FIXES-VERIFICATION.md)** - 修复验证报告
- **[docs/FILE-STRUCTURE.md](docs/FILE-STRUCTURE.md)** - 项目结构

---

## 📋 版本历史

### 版本 1.33（2026-01-26）
- 🐛 **WSL 修复**：改进 WSL stop hook 错误处理
  - 修复 "/usr/bin/sh: cannot execute binary file" 错误
  - 添加脚本存在性和可读性验证
  - 添加详细的调试日志到 `/tmp/ralph-hook-router.log`
  - 改进错误消息，便于诊断
- 🧪 **测试**：添加完整的 WSL 测试套件
  - WSL 测试通过率：85.7%（6/7 测试）
  - 添加 `tests/test-wsl-hook.sh` - WSL 功能测试
  - 添加 `tests/test-wsl-complete.ps1` - 完整 WSL 测试套件
  - 添加 `tests/diagnose-wsl-hook.sh` - WSL 诊断脚本
- 📚 **文档**：添加详细的测试报告
  - `TEST-REPORT-v1.31.md` - 综合测试报告
  - `WSL-TEST-REPORT.md` - 详细 WSL 测试报告
  - `WSL-FIX-VERIFICATION.md` - 修复验证报告

### 版本 1.31（2026-01-26）
- 📚 **改进文档**：重新组织命令文档，提高清晰度
  - `/ralph-smart-setmaxiterations` 现在紧跟在 `/ralph-smart` 后面
  - 添加单任务（直接命令）的明确示例
  - 添加单任务（从文件）的明确示例
  - 明确多任务使用方式
- 🧹 **项目清理**：删除过期和临时文件
  - 删除 6 个过期测试报告
  - 删除 7 个临时修复文档
  - 删除 2 个过期版本说明（v1.0.2, v1.20）
  - 删除备份和配置文件
  - 精简项目结构，提高可维护性

### 版本 1.30（2026-01-26）
- ✨ **新增**：多任务支持，自动任务切换
- ✨ **新增**：AI 驱动的任务排序和依赖分析
- ✨ **新增**：多任务丰富进度可视化
- ✨ **新增**：多任务会话状态持久化
- ✨ **新增**：`/ralph-smart-setmaxiterations` 命令用于设置默认最大迭代次数
- 📚 **新增**：全面的多任务文档
- 🧪 **新增**：22 个多任务功能单元测试

### 版本 1.20（2026-01-23）
- ✅ 跨平台支持（Windows、WSL、macOS、Linux）
- ✅ 智能 Ralph 循环，智能完成检测
- ✅ 增强的 hooks 配置
- ✅ 全面的测试套件（93.1% 通过率）

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
- **多任务支持**：2026-01-26 添加
- **原始代码**：[anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)

---

## 📞 支持

- **问题反馈**：[GitHub Issues](https://github.com/flyfoxai/ralph-wiggum-windows-fix/issues)
- **原始插件**：[Claude Code 仓库](https://github.com/anthropics/claude-code)
- **Ralph 技术**：[ghuntley.com/ralph](https://ghuntley.com/ralph/)

---

**用 ❤️ 为 Claude Code 社区制作**
