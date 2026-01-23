# 特定环境测试指南
# Environment-Specific Testing Guide

## 🎯 测试目的

本指南帮助您在不同环境下测试 Ralph Wiggum 插件的 stop-hook 功能。

---

## 🚀 快速开始

### 使用交互式测试工具 (推荐)

```powershell
.\test-environment.ps1
```

这将显示一个菜单,让您选择要测试的环境。

---

## 📋 测试方法

### 方法 1: 交互式菜单 (最简单)

```powershell
# 运行交互式测试工具
.\test-environment.ps1

# 或直接指定环境
.\test-environment.ps1 auto      # 自动检测并测试
.\test-environment.ps1 windows   # 测试 Windows
.\test-environment.ps1 wsl       # 测试 WSL
.\test-environment.ps1 gitbash   # 测试 Git Bash
.\test-environment.ps1 all       # 测试所有环境
```

### 方法 2: 手动测试 (详细控制)

#### 测试 Windows 原生环境

```powershell
# 1. 检查环境
.\hooks\detect-environment.ps1 all

# 2. 检查脚本存在
Test-Path .\hooks\stop-hook.ps1

# 3. 创建测试状态文件
$testState = @"
---
iteration: 1
max_iterations: 5
completion_promise: "DONE"
---

测试任务
"@
New-Item -ItemType Directory -Path .claude -Force
Set-Content -Path .claude\ralph-loop.local.md -Value $testState

# 4. 创建模拟 transcript
$testTranscript = @'
{"role":"assistant","message":{"content":[{"type":"text","text":"Test"}]}}
'@
Set-Content -Path .claude\transcript-test.jsonl -Value $testTranscript

# 5. 测试执行
$hookInput = '{"transcript_path": ".claude\\transcript-test.jsonl"}'
$hookInput | pwsh -NoProfile -ExecutionPolicy Bypass -File .\hooks\stop-hook.ps1

# 6. 清理
Remove-Item .claude\ralph-loop.local.md -Force
Remove-Item .claude\transcript-test.jsonl -Force
```

#### 测试 WSL 环境

```powershell
# 1. 检查 WSL 可用性
wsl --version

# 2. 检查 WSL 中的 shell
wsl which sh
wsl which bash

# 3. 检查环境检测
wsl sh ./hooks/detect-environment.sh all

# 4. 转换路径到 WSL 格式
$winPath = "C:\projects\ralph-wiggum-fix-win\hooks\stop-hook-posix.sh"
$wslPath = "/mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-posix.sh"

# 5. 测试脚本语法
wsl sh -n $wslPath

# 6. 测试执行 (需要创建测试文件)
wsl sh $wslPath
```

#### 测试 Git Bash 环境

```powershell
# 1. 检查 bash 可用性
bash --version

# 2. 检查环境
bash ./hooks/detect-environment.sh all

# 3. 测试脚本语法
bash -n ./hooks/stop-hook-posix.sh

# 4. 测试执行
bash ./hooks/stop-hook-posix.sh
```

---

## 🔍 测试检查清单

### Windows 原生环境

- [ ] PowerShell 7+ 已安装 (`pwsh --version`)
- [ ] `stop-hook.ps1` 文件存在
- [ ] PowerShell 脚本语法有效
- [ ] 环境检测返回 "windows"
- [ ] 脚本能成功执行
- [ ] 能正确解析状态文件
- [ ] 能正确解析 transcript
- [ ] JSON 输出格式正确

### WSL 环境

- [ ] WSL 已安装 (`wsl --version`)
- [ ] WSL 分发版已安装 (`wsl --list`)
- [ ] sh 可用 (`wsl which sh`)
- [ ] `stop-hook-posix.sh` 文件存在
- [ ] 脚本语法有效 (`wsl sh -n script.sh`)
- [ ] 环境检测返回 "wsl"
- [ ] 路径转换正确 (Windows → WSL)
- [ ] 脚本能在 WSL 中执行
- [ ] jq 可用 (`wsl which jq`)

### Git Bash 环境

- [ ] Git Bash 已安装 (`bash --version`)
- [ ] `stop-hook-posix.sh` 文件存在
- [ ] 脚本语法有效 (`bash -n script.sh`)
- [ ] 环境检测返回 "gitbash"
- [ ] MSYSTEM 环境变量存在
- [ ] 脚本能在 Git Bash 中执行
- [ ] jq 可用 (`bash -c "which jq"`)

### macOS 环境

- [ ] bash 或 zsh 可用
- [ ] `stop-hook.sh` 或 `stop-hook-posix.sh` 存在
- [ ] 脚本语法有效
- [ ] 环境检测返回 "darwin"
- [ ] 脚本能成功执行
- [ ] jq 可用 (`which jq`)

### Linux 环境

- [ ] bash 可用
- [ ] `stop-hook.sh` 或 `stop-hook-posix.sh` 存在
- [ ] 脚本语法有效
- [ ] 环境检测返回 "linux"
- [ ] 不是 WSL 环境
- [ ] 脚本能成功执行
- [ ] jq 可用 (`which jq`)

---

## 🧪 测试场景

### 场景 1: 正常循环继续

**目的**: 测试 hook 能正确阻止退出并继续循环

**步骤**:
1. 创建状态文件 (iteration < max_iterations)
2. 创建 transcript (无 completion promise)
3. 执行 stop-hook
4. 验证输出 JSON 包含 `"decision": "block"`
5. 验证 iteration 增加

**预期结果**:
```json
{
  "decision": "block",
  "reason": "任务提示",
  "systemMessage": "🔄 Ralph iteration 2 | ..."
}
```

### 场景 2: 达到最大迭代次数

**目的**: 测试达到上限时正确退出

**步骤**:
1. 创建状态文件 (iteration >= max_iterations)
2. 执行 stop-hook
3. 验证允许退出 (exit 0)
4. 验证状态文件被删除

**预期结果**:
- 输出: "🛑 Ralph loop: Max iterations (N) reached."
- 退出码: 0
- 状态文件被删除

### 场景 3: 检测到 completion promise

**目的**: 测试完成条件检测

**步骤**:
1. 创建状态文件 (设置 completion_promise)
2. 创建 transcript (包含匹配的 `<promise>` 标签)
3. 执行 stop-hook
4. 验证允许退出

**预期结果**:
- 输出: "✅ Ralph loop: Detected <promise>DONE</promise>"
- 退出码: 0
- 状态文件被删除

### 场景 4: 状态文件损坏

**目的**: 测试错误处理

**步骤**:
1. 创建损坏的状态文件 (无效的 YAML)
2. 执行 stop-hook
3. 验证错误消息清晰
4. 验证安全退出

**预期结果**:
- 输出错误消息
- 退出码: 0
- 状态文件被删除

---

## 📊 测试结果记录

### 测试记录模板

```markdown
## 测试日期: YYYY-MM-DD
## 测试者: [姓名]
## 环境: [Windows/WSL/Git Bash/macOS/Linux]

### 系统信息
- OS:
- Shell:
- PowerShell 版本:
- Bash 版本:

### 测试结果

| 测试项 | 结果 | 备注 |
|--------|------|------|
| 文件存在 | ✅/❌ | |
| 语法检查 | ✅/❌ | |
| 环境检测 | ✅/❌ | |
| 场景1: 正常循环 | ✅/❌ | |
| 场景2: 达到上限 | ✅/❌ | |
| 场景3: 完成检测 | ✅/❌ | |
| 场景4: 错误处理 | ✅/❌ | |

### 问题和建议
[记录遇到的问题和改进建议]
```

---

## 🔧 常见问题

### Q1: 如何在 WSL 中测试?

**A**: 使用交互式工具:
```powershell
.\test-environment.ps1 wsl
```

或手动:
```powershell
# 转换路径
$wslPath = "/mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-posix.sh"

# 测试
wsl sh $wslPath
```

### Q2: 如何测试路由器?

**A**: 路由器会自动选择正确的实现:
```powershell
# Windows 路由器
.\hooks\stop-hook-router.ps1

# Unix 路由器 (在 WSL/Git Bash 中)
sh ./hooks/stop-hook-router.sh
```

### Q3: 如何创建测试数据?

**A**: 使用 `-CreateMockState` 参数:
```powershell
.\test-environment.ps1 -CreateMockState
```

或手动创建:
```powershell
# 状态文件
$state = @"
---
iteration: 1
max_iterations: 5
completion_promise: "DONE"
---
测试任务
"@
Set-Content -Path .claude\ralph-loop.local.md -Value $state

# Transcript 文件
$transcript = '{"role":"assistant","message":{"content":[{"type":"text","text":"Test"}]}}'
Set-Content -Path .claude\transcript-test.jsonl -Value $transcript
```

### Q4: 如何调试脚本执行?

**A**: 使用 verbose 模式:

**PowerShell**:
```powershell
.\test-environment.ps1 -Verbose
```

**Shell**:
```bash
# 显示执行过程
sh -x ./hooks/stop-hook-posix.sh

# 或
bash -x ./hooks/stop-hook-posix.sh
```

### Q5: 如何测试特定的 shell?

**A**: 直接调用:
```bash
# 测试 sh
sh ./hooks/stop-hook-posix.sh

# 测试 bash
bash ./hooks/stop-hook-posix.sh

# 测试 dash (如果可用)
dash ./hooks/stop-hook-posix.sh
```

---

## 📈 性能测试

### 测量执行时间

**PowerShell**:
```powershell
Measure-Command {
    $hookInput = '{"transcript_path": ".claude\\transcript-test.jsonl"}'
    $hookInput | pwsh -NoProfile -ExecutionPolicy Bypass -File .\hooks\stop-hook.ps1
}
```

**Shell**:
```bash
time sh ./hooks/stop-hook-posix.sh
```

### 性能基准

| 环境 | 预期时间 | 可接受范围 |
|------|---------|-----------|
| Windows 原生 | ~50ms | < 100ms |
| WSL2 | ~100ms | < 200ms |
| WSL1 | ~200ms | < 400ms |
| macOS | ~50ms | < 100ms |
| Linux | ~30ms | < 80ms |
| Git Bash | ~120ms | < 250ms |
| Cygwin | ~300ms | < 500ms |

---

## 🎓 高级测试

### 并发测试

测试多个 Ralph loop 同时运行:

```powershell
# 创建多个状态文件
1..3 | ForEach-Object {
    $state = @"
---
iteration: $_
max_iterations: 5
completion_promise: "DONE$_"
---
任务 $_
"@
    Set-Content -Path ".claude\ralph-loop-$_.local.md" -Value $state
}

# 并发测试
1..3 | ForEach-Object {
    Start-Job -ScriptBlock {
        param($n)
        # 测试逻辑
    } -ArgumentList $_
}

Get-Job | Wait-Job | Receive-Job
```

### 压力测试

测试大量迭代:

```powershell
# 创建高迭代次数的状态
$state = @"
---
iteration: 1
max_iterations: 1000
completion_promise: null
---
压力测试任务
"@
Set-Content -Path .claude\ralph-loop.local.md -Value $state

# 循环测试
1..100 | ForEach-Object {
    Write-Host "迭代 $_"
    # 执行 stop-hook
    # 检查内存和性能
}
```

---

## 📚 参考资源

- **CROSS-PLATFORM-SUPPORT.md** - 跨平台支持详细文档
- **QUICK-REFERENCE.md** - 快速参考指南
- **test-cross-platform.ps1** - 综合测试套件
- **test-environment.ps1** - 交互式环境测试工具

---

## ✅ 测试完成标准

测试通过需要满足:

- [ ] 所有文件存在性检查通过
- [ ] 脚本语法检查通过
- [ ] 环境检测正确
- [ ] 至少 3 个测试场景通过
- [ ] 无严重错误或异常
- [ ] 性能在可接受范围内
- [ ] 清理操作正常工作

---

**最后更新**: 2026-01-23
**版本**: 1.0
