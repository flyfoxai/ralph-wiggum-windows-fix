# Smart Ralph Loop - 设计文档

**版本**: 1.0
**日期**: 2026-01-23
**状态**: 设计完成,待实现

---

## 1. 概述

Smart Ralph 是对现有 Ralph Wiggum 插件的智能增强,核心目标是:

1. **AI 驱动的任务解析** - 支持任意格式的任务文件,无需严格格式要求
2. **智能完成判断** - 混合使用规则检查和 AI 自我评估
3. **多任务自动管理** - 自动切换任务,无需手动干预
4. **配置化设计** - 灵活的默认配置,支持命令行覆盖
5. **会话恢复** - 支持中断恢复,自动检测未完成会话

---

## 2. 核心设计决策

### 2.1 任务文件解析

**决策**: 完全抛弃格式限制,使用 AI 智能解析

**实现方式**:
- 用户可以用任意格式编写任务文件(Markdown、纯文本、列表等)
- setup 脚本注入解析提示,让 Claude 理解并提取任务
- Claude 输出标准化的 Markdown 格式到 `<task-analysis>` 标签
- 脚本提取并保存为状态文件

**优势**:
- 零学习成本,用户自然表达即可
- AI 自动理解任务意图和完成标准
- 输出统一格式,便于后续处理

### 2.2 完成度判断

**决策**: 混合方案 - 规则检查 + AI 评估

**阶段 1: 规则检查**
- 文件变化数量 (git status)
- 测试状态 (npm test / pytest / dotnet test)
- 检查清单进度 (Markdown checkbox)
- 错误数量 (从 transcript 检测)

**阶段 2: AI 自我评估**
- Stop hook 注入评估提示
- 提供规则检查结果作为参考
- AI 输出结构化评估到 `<completion-assessment>` 标签
- 包含: 完成状态、完成度、置信度、已完成项、未完成项、建议

**决策逻辑**:
```
IF AI 评估 = completed AND 置信度 >= 80% AND 完成度 >= 阈值:
    任务完成,切换下一个
ELSE IF 迭代次数 >= 最大值:
    停止并报告
ELSE IF 检测到停滞 (连续 N 次无进展):
    停止并询问用户
ELSE:
    继续当前任务
```

### 2.3 多任务管理

**任务状态机**:
```
pending → in_progress → completed
            ↓
          blocked → (用户干预) → in_progress
            ↓
          skipped
```

**任务切换**:
- 当前任务完成后自动切换到下一个
- 更新状态文件,标记任务状态
- 生成新任务提示,注入到下一次迭代
- 显示进度和统计信息

### 2.4 配置管理

**配置优先级**:
```
命令行参数 > 配置文件 > 内置默认值
```

**配置文件位置**: `.claude/ralph-smart/config.json`

**默认配置**:
```json
{
  "max_iterations": 50,
  "completion_threshold": 90,
  "auto_approve": false,
  "strict_mode": false,
  "stall_detection": 5,
  "verbose": false
}
```

**配置管理命令**: `/ralph-config`

### 2.5 会话恢复

**自动检测**:
- 启动新会话时自动检测未完成会话
- 显示上次会话信息和进度
- 提供选项: 继续/新建/取消

**历史管理**:
- 自动备份旧会话到 `.claude/ralph-smart/history/`
- 支持查看历史会话列表
- 支持恢复任意历史会话

**无上下文恢复**:
- 状态文件包含所有必要信息
- 恢复提示明确告知 AI 这是恢复的会话
- AI 可以从状态文件理解当前进度

---

## 3. 文件结构

```
ralph-wiggum/
├── commands/
│   ├── ralph-smart.md          # 主命令入口
│   ├── ralph-config.md         # 配置管理
│   ├── ralph-resume.md         # 会话恢复
│   ├── ralph-clean.md          # 数据清理
│   └── cancel-ralph.md         # 取消会话
├── scripts/
│   ├── setup-ralph-smart.ps1   # 初始化脚本
│   ├── manage-config.ps1       # 配置管理脚本
│   └── resume-ralph-smart.ps1  # 恢复脚本
├── hooks/
│   ├── smart-stop-hook.ps1     # Stop hook (Windows)
│   └── smart-stop-hook.sh      # Stop hook (Unix)
└── lib/
    ├── task-parser.ps1         # 任务解析函数
    ├── completion-checker.ps1  # 完成度检查函数
    ├── state-manager.ps1       # 状态管理函数
    └── assessment-builder.ps1  # 评估提示构建函数
```

---

## 4. 数据流

```
用户命令: /ralph-smart tasks.txt
    ↓
setup-ralph-smart.ps1
    ↓
检查未完成会话 → 提示用户选择
    ↓
读取任务文件
    ↓
注入 AI 解析提示
    ↓
Claude 输出 <task-analysis>
    ↓
提取并创建状态文件 (.claude/ralph-smart/state.md)
    ↓
注册 smart-stop-hook
    ↓
生成第一个任务提示
    ↓
═══════════════════════════════════════
    ↓
Claude 执行任务
    ↓
尝试退出 (Stop)
    ↓
smart-stop-hook.ps1 执行
    ↓
读取状态文件
    ↓
增加迭代计数
    ↓
执行规则检查
    ↓
注入 AI 评估提示
    ↓
阻止退出 (exit 1)
    ↓
═══════════════════════════════════════
    ↓
Claude 输出 <completion-assessment>
    ↓
尝试退出 (Stop)
    ↓
smart-stop-hook.ps1 执行
    ↓
从 transcript 提取 AI 评估
    ↓
决策: 继续/切换/完成
    ↓
IF 任务完成:
    切换到下一个任务
    注入新任务提示
    阻止退出 (exit 1)
ELSE IF 所有任务完成:
    显示完成总结
    允许退出 (exit 0)
ELSE:
    注入继续提示
    阻止退出 (exit 1)
```

---

## 5. 状态文件格式

**位置**: `.claude/ralph-smart/state.md`

**格式**: YAML frontmatter + Markdown

**示例**:
```yaml
---
active: true
task_file: "tasks.md"
current_task_index: 1
total_tasks: 3
iteration: 8
max_iterations: 50
completion_threshold: 90
auto_approve: false
stall_detection: 5
stall_count: 0
last_completion: 75
started_at: "2026-01-23T14:30:00Z"
---

## 任务 1: 修复 Windows 路径问题
修复反斜杠路径处理问题

**完成标准**:
- [x] 定位路径处理代码
- [x] 修复反斜杠问题
- [x] 测试 Windows 路径

**状态**: completed | **完成度**: 100% | **迭代**: 5

## 任务 2: 添加错误处理
在关键函数中添加错误处理,防止程序崩溃

**完成标准**:
- [x] 识别关键函数
- [x] 添加 try-catch
- [ ] 测试错误场景

**状态**: in_progress | **完成度**: 75% | **迭代**: 3

## 任务 3: 编写 README
创建使用说明文档

**完成标准**:
- [ ] 编写安装步骤
- [ ] 编写使用示例
- [ ] 添加常见问题

**状态**: pending | **完成度**: 0% | **迭代**: 0
```

---

## 6. 命令接口

### 6.1 主命令

```bash
/ralph-smart <任务文件路径> [选项]
```

**参数**:
- `<任务文件路径>`: 任务描述文件(任意格式)
- `--max-iterations <n>`: 最大迭代次数(默认: 50)
- `--completion-threshold <n>`: 完成度阈值(默认: 90)
- `--auto-approve`: 自动切换任务,不询问
- `--strict-mode`: 严格模式,要求 100% 完成
- `--stall-detection <n>`: 停滞检测阈值(默认: 5)
- `--verbose`: 显示详细信息

**示例**:
```bash
# 最简单 - 使用默认配置
/ralph-smart tasks.md

# 自定义参数
/ralph-smart tasks.txt --max-iterations 100 --completion-threshold 95

# 自动模式
/ralph-smart sprint.md --auto-approve
```

### 6.2 配置管理

```bash
/ralph-config [选项]
```

**功能**:
- 查看当前配置
- 修改默认配置
- 重置为默认值

**示例**:
```bash
# 查看配置
/ralph-config

# 修改配置
/ralph-config --max-iterations 100
/ralph-config --auto-approve true

# 重置配置
/ralph-config --reset
```

### 6.3 会话恢复

```bash
/ralph-resume [选项]
```

**功能**:
- 恢复当前会话
- 查看历史会话
- 恢复历史会话

**示例**:
```bash
# 恢复当前会话
/ralph-resume

# 查看历史
/ralph-resume --history

# 恢复历史会话
/ralph-resume --restore 20260123-143000
```

### 6.4 其他命令

```bash
# 取消当前会话
/cancel-ralph

# 清理所有数据
/ralph-clean
```

---

## 7. 关键函数

### 7.1 任务解析

```powershell
# 从 AI 输出提取任务分析
Extract-TaskAnalysis -Output $claudeOutput

# 解析为结构化数据
Parse-TaskAnalysis -AnalysisText $analysisText

# 生成任务提示
Get-TaskPrompt -Task $task
```

### 7.2 完成度检查

```powershell
# 规则检查
Get-RuleBasedCompletion -State $state
  ├─ Get-FileChanges
  ├─ Get-TestStatus
  ├─ Get-ChecklistProgress
  └─ Get-ErrorCount

# 提取 AI 评估
Extract-AIAssessment -TranscriptFile $transcriptFile

# 构建评估提示
Build-AssessmentPrompt -State $state -RuleSignals $signals
```

### 7.3 状态管理

```powershell
# 解析状态文件
Parse-StateFile -Content $content

# 更新状态文件
Update-StateFile -State $state

# 初始化状态文件
Initialize-StateFile -TaskFile $file -Tasks $tasks -Config $config
```

### 7.4 决策逻辑

```powershell
Decide-NextAction -State $state -RuleSignals $signals -AIAssessment $assessment
  → "TASK_COMPLETED"  # 切换下一个任务
  → "CONTINUE"        # 继续当前任务
  → "MAX_ITERATIONS"  # 达到最大迭代
  → "STALLED"         # 检测到停滞
  → "BLOCKED"         # 任务被阻塞
```

---

## 8. 错误处理

### 8.1 状态文件损坏

- 自动创建备份 (state.md.backup)
- 检测损坏并尝试从备份恢复
- 如果无法恢复,提示用户清理并重新开始

### 8.2 会话冲突

- 启动新会话前检查活跃会话
- 如果有活跃会话,拒绝启动并提示取消
- 如果有未完成会话,提示用户选择

### 8.3 任务文件问题

- 验证文件存在性
- 检查文件大小(警告过大文件)
- 验证文件编码(UTF-8)
- AI 解析失败时提供清晰错误信息

### 8.4 安全检查

- 磁盘空间检查
- 迭代次数上限保护
- 停滞检测
- 重复错误检测

---

## 9. 用户体验

### 9.1 启动时

```
🚀 Smart Ralph 启动
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 任务文件: tasks.md
🎯 完成阈值: 90%
🔁 最大迭代: 50
⚙️  自动批准: false
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 正在分析任务文件...
```

### 9.2 迭代过程

```
🔄 Smart Ralph - 迭代 8
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 任务: 2/3 (添加错误处理)
📊 完成度: 75%
🔁 当前任务迭代: 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 9.3 任务完成

```
✅ 任务 2 完成! (添加错误处理)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 统计:
  • 迭代次数: 3
  • 完成度: 100%

🎯 切换到下一个任务...

开始执行任务 3/3: 编写 README
```

### 9.4 全部完成

```
🎉 所有任务已完成!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 总体统计:
  • 总任务数: 3
  • 总迭代次数: 15
  • 平均每任务: 5.0 次迭代

✅ 已完成任务:
  1. 修复 Windows 路径问题 (5 次迭代)
  2. 添加错误处理 (3 次迭代)
  3. 编写 README (7 次迭代)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 10. 实施计划

### 阶段 1: 核心功能 (MVP)

**目标**: 实现单任务智能判断

**交付物**:
- [ ] AI 任务解析 (setup 脚本)
- [ ] 规则检查函数库
- [ ] AI 评估提示和提取
- [ ] 基本的 stop hook 逻辑
- [ ] 状态文件管理

### 阶段 2: 多任务支持

**目标**: 实现多任务自动切换

**交付物**:
- [ ] 任务队列管理
- [ ] 任务切换逻辑
- [ ] 进度显示
- [ ] 完成总结

### 阶段 3: 配置与恢复

**目标**: 完善用户体验

**交付物**:
- [ ] 配置文件支持
- [ ] 配置管理命令
- [ ] 会话恢复机制
- [ ] 历史会话管理

### 阶段 4: 完善与测试

**目标**: 错误处理和优化

**交付物**:
- [ ] 错误处理和恢复
- [ ] 安全检查
- [ ] 日志记录(可选)
- [ ] 完整测试
- [ ] 文档和示例

---

## 11. 成功标准

### 11.1 功能完整性

- ✅ 支持任意格式的任务文件
- ✅ 智能判断任务完成(准确率 > 85%)
- ✅ 自动多任务切换
- ✅ 配置化设计
- ✅ 会话恢复

### 11.2 用户体验

- ✅ 零学习成本(默认参数即可使用)
- ✅ 清晰的进度显示
- ✅ 友好的错误提示
- ✅ 可靠的恢复机制

### 11.3 性能指标

- ✅ 任务解析时间 < 5 秒
- ✅ 状态文件读写 < 100ms
- ✅ 减少 30% 不必要的迭代

---

## 12. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| AI 解析任务不准确 | 高 | 提供清晰的解析提示,支持手动编辑状态文件 |
| AI 评估完成度不准确 | 高 | 结合规则检查,设置置信度阈值 |
| 状态文件损坏 | 中 | 自动备份,损坏检测和恢复 |
| 无限循环 | 高 | 强制最大迭代限制,停滞检测 |
| 跨平台兼容性 | 中 | 同时维护 PowerShell 和 Bash 版本 |

---

## 13. 附录

### 13.1 示例任务文件

**示例 1: 自由格式**
```
帮我做这几件事:
1. 修复那个登录的bug
2. 加上错误处理
3. 写个README
```

**示例 2: Markdown 格式**
```markdown
## 修复登录bug
用户无法登录,检查认证逻辑
- [ ] 重现问题
- [ ] 修复代码
- [ ] 测试

## 添加错误处理
在关键函数加 try-catch
```

**示例 3: 详细格式**
```markdown
# 项目开发任务

## 任务 1: 实现用户认证
**描述**: 创建完整的登录注册系统

**完成标准**:
- [ ] 创建 User 模型
- [ ] 实现注册 API
- [ ] 实现登录 API
- [ ] 添加 JWT 验证
- [ ] 测试通过

## 任务 2: 实现个人资料
**描述**: 用户可以查看和编辑个人信息

**完成标准**:
- [ ] 创建个人资料 API
- [ ] 实现前端页面
- [ ] 测试通过
```

### 13.2 AI 评估示例

```xml
<completion-assessment>
**完成状态**: in_progress

**完成度**: 75%

**置信度**: 85%

**已完成项**:
- 识别关键函数
- 添加 try-catch 块

**未完成项**:
- 测试错误场景

**阻塞问题**: 无

**建议**: 编写单元测试来验证错误处理是否正确工作
</completion-assessment>
```

---

**文档状态**: ✅ 设计完成
**下一步**: 开始实施阶段 1
