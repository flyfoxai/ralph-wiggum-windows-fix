# 如何测试特定环境 - 完整指南
# How to Test Specific Environments - Complete Guide

## 🎯 快速开始

### 最简单的方法: 运行演示脚本

```powershell
.\demo-test.ps1
```

这将:
- ✅ 检测当前环境
- ✅ 显示可用工具
- ✅ 检查所有脚本文件
- ✅ 提供测试命令建议
- ✅ 运行基本环境检测

---

## 📋 测试方法总览

| 方法 | 难度 | 适用场景 | 命令 |
|------|------|---------|------|
| **演示脚本** | ⭐ 最简单 | 快速检查 | `.\demo-test.ps1` |
| **环境检测** | ⭐⭐ 简单 | 确认环境 | `.\hooks\detect-environment.ps1 all` |
| **综合测试** | ⭐⭐⭐ 中等 | 完整验证 | `.\test-cross-platform.ps1` |
| **交互测试** | ⭐⭐⭐ 中等 | 特定环境 | `.\test-environment.ps1` |
| **手动测试** | ⭐⭐⭐⭐ 高级 | 深度调试 | 见下文 |

---

## 🔍 按环境测试

### 1️⃣ Windows 原生环境

#### 快速测试
```powershell
# 检测环境
.\hooks\detect-environment.ps1 all

# 输出示例:
# Environment: windows
# Shell: bash
# PowerShell: pwsh
```

#### 完整测试
```powershell
# 1. 检查文件
Test-Path .\hooks\stop-hook.ps1

# 2. 检查语法
$null = [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content .\hooks\stop-hook.ps1 -Raw),
    [ref]$null
)

# 3. 测试路由器
.\hooks\stop-hook-router.ps1

# 4. 运行综合测试
.\test-cross-platform.ps1
```

#### 预期结果
- ✅ 环境检测返回 "windows"
- ✅ PowerShell 脚本语法有效
- ✅ 路由器选择 `stop-hook.ps1`

---

### 2️⃣ WSL 环境

#### 快速测试
```powershell
# 检查 WSL 可用性
wsl --version

# 检测环境 (在 WSL 内)
wsl sh ./hooks/detect-environment.sh all

# 输出示例:
# Environment: wsl
# Shell: sh
```

#### 完整测试
```powershell
# 1. 检查 WSL 分发版
wsl --list

# 2. 检查 shell 可用性
wsl which sh
wsl which bash

# 3. 转换路径到 WSL 格式
$winPath = "C:\projects\ralph-wiggum-fix-win\hooks\stop-hook-posix.sh"
$wslPath = "/mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-posix.sh"

# 4. 测试脚本语法
wsl sh -n $wslPath

# 5. 测试环境检测
wsl sh /mnt/c/projects/ralph-wiggum-fix-win/hooks/detect-environment.sh env
```

#### 预期结果
- ✅ 环境检测返回 "wsl"
- ✅ sh 可用 (bash 可能不可用)
- ✅ POSIX 脚本语法有效
- ✅ 路径转换正确

#### 常见问题

**Q: bash: not found**
```powershell
# 解决: 使用 sh 而不是 bash
wsl sh ./hooks/stop-hook-posix.sh
```

**Q: No such file or directory**
```powershell
# 解决: 转换 Windows 路径到 WSL 路径
# Windows: C:\projects\...
# WSL:     /mnt/c/projects/...
```

---

### 3️⃣ Git Bash 环境

#### 快速测试
```powershell
# 检测环境
bash ./hooks/detect-environment.sh all

# 输出示例:
# Environment: gitbash
# Shell: bash
```

#### 完整测试
```powershell
# 1. 检查 bash 版本
bash --version

# 2. 检查 MSYSTEM 环境变量
$env:MSYSTEM  # 应该是 MINGW64, MINGW32 等

# 3. 测试脚本语法
bash -n ./hooks/stop-hook-posix.sh

# 4. 测试环境检测
bash ./hooks/detect-environment.sh env

# 5. 测试路由器
bash ./hooks/stop-hook-router.sh

# 6. 模拟 hooks.json 调用 (Windows 路径)
export CLAUDE_PLUGIN_ROOT="$(pwd)"
bash -lc 'ROOT="$CLAUDE_PLUGIN_ROOT"; if [ "${ROOT#/}" = "$ROOT" ]; then if command -v wslpath >/dev/null 2>&1; then ROOT=$(wslpath -a "$ROOT"); elif command -v cygpath >/dev/null 2>&1; then ROOT=$(cygpath -u "$ROOT"); fi; fi; exec bash "$ROOT/hooks/stop-hook-router.sh"'
```

#### 预期结果
- ✅ 环境检测返回 "gitbash"
- ✅ MSYSTEM 环境变量存在
- ✅ bash 完全可用
- ✅ 路由器选择 `stop-hook-posix.sh`

---

### 4️⃣ macOS 环境

#### 快速测试
```bash
# 检测环境
sh ./hooks/detect-environment.sh all

# 输出示例:
# Environment: darwin
# Shell: bash
```

#### 完整测试
```bash
# 1. 检查 shell
which bash
which sh
which zsh

# 2. 测试脚本语法
bash -n ./hooks/stop-hook.sh
sh -n ./hooks/stop-hook-posix.sh

# 3. 测试环境检测
sh ./hooks/detect-environment.sh env

# 4. 测试路由器
bash ./hooks/stop-hook-router.sh
```

#### 预期结果
- ✅ 环境检测返回 "darwin"
- ✅ bash 和 sh 都可用
- ✅ 路由器优先选择 `stop-hook.sh`

---

### 5️⃣ Linux 环境

#### 快速测试
```bash
# 检测环境
sh ./hooks/detect-environment.sh all

# 输出示例:
# Environment: linux
# Shell: bash
```

#### 完整测试
```bash
# 1. 确认不是 WSL
cat /proc/version  # 不应包含 "microsoft" 或 "WSL"

# 2. 检查 shell
which bash
which sh

# 3. 测试脚本语法
bash -n ./hooks/stop-hook.sh
sh -n ./hooks/stop-hook-posix.sh

# 4. 测试环境检测
sh ./hooks/detect-environment.sh env

# 5. 测试路由器
bash ./hooks/stop-hook-router.sh
```

#### 预期结果
- ✅ 环境检测返回 "linux"
- ✅ bash 完全可用
- ✅ 路由器选择 `stop-hook.sh`

---

## 🧪 测试场景

### 场景 1: 验证环境检测

**目的**: 确认系统能正确识别当前环境

**步骤**:
```powershell
# PowerShell
.\hooks\detect-environment.ps1 env

# Shell (WSL/Git Bash/macOS/Linux)
sh ./hooks/detect-environment.sh env
```

**预期输出**:
- Windows: `windows`
- WSL: `wsl`
- Git Bash: `gitbash`
- macOS: `darwin`
- Linux: `linux`

---

### 场景 2: 验证路由器选择

**目的**: 确认路由器选择正确的实现

**步骤**:
```powershell
# Windows
.\hooks\stop-hook-router.ps1

# Unix (macOS/Linux)
bash ./hooks/stop-hook-router.sh

# Unix (WSL/Git Bash, Windows 路径)
bash -lc 'ROOT="$CLAUDE_PLUGIN_ROOT"; if [ "${ROOT#/}" = "$ROOT" ]; then if command -v wslpath >/dev/null 2>&1; then ROOT=$(wslpath -a "$ROOT"); elif command -v cygpath >/dev/null 2>&1; then ROOT=$(cygpath -u "$ROOT"); fi; fi; exec bash "$ROOT/hooks/stop-hook-router.sh"'
```

**预期行为**:
| 环境 | 应选择的脚本 |
|------|------------|
| Windows | `stop-hook.ps1` |
| WSL | `stop-hook-posix.sh` (使用 sh) |
| Git Bash | `stop-hook-posix.sh` (使用 bash) |
| macOS | `stop-hook.sh` (使用 bash) |
| Linux | `stop-hook.sh` (使用 bash) |

---

### 场景 3: 验证脚本语法

**目的**: 确认脚本没有语法错误

**PowerShell**:
```powershell
# 检查 PowerShell 脚本
$null = [System.Management.Automation.PSParser]::Tokenize(
    (Get-Content .\hooks\stop-hook.ps1 -Raw),
    [ref]$null
)
Write-Host "✅ 语法有效"
```

**Shell**:
```bash
# 检查 shell 脚本
sh -n ./hooks/stop-hook-posix.sh && echo "✅ 语法有效"
bash -n ./hooks/stop-hook.sh && echo "✅ 语法有效"
```

---

## 📊 测试结果判断

### 成功标准

| 测试项 | 成功标准 |
|--------|---------|
| **环境检测** | 返回正确的环境名称 |
| **文件存在** | 所有必需脚本存在 |
| **语法检查** | 无语法错误 |
| **路由选择** | 选择正确的实现 |
| **执行测试** | 退出码为 0 |

### 失败诊断

| 症状 | 可能原因 | 解决方案 |
|------|---------|---------|
| "未找到命令" | 工具未安装 | 安装相应工具 |
| "语法错误" | 脚本损坏 | 重新下载脚本 |
| "权限被拒绝" | 执行权限缺失 | `chmod +x *.sh` |
| "路径不存在" | 路径转换错误 | 检查路径格式 |
| "环境检测失败" | 检测脚本问题 | 查看详细错误 |

---

## 🎓 高级测试

### 调试模式

**PowerShell**:
```powershell
# 显示详细执行过程
Set-PSDebug -Trace 1
.\hooks\stop-hook.ps1
Set-PSDebug -Trace 0
```

**Shell**:
```bash
# 显示执行过程
sh -x ./hooks/stop-hook-posix.sh

# 或
bash -x ./hooks/stop-hook.sh
```

### 性能测试

**PowerShell**:
```powershell
Measure-Command {
    .\hooks\detect-environment.ps1 env
}
```

**Shell**:
```bash
time sh ./hooks/detect-environment.sh env
```

### 并发测试

```powershell
# 测试多个环境同时运行
1..5 | ForEach-Object -Parallel {
    .\hooks\detect-environment.ps1 env
}
```

---

## 📚 相关文档

- **TESTING-GUIDE.md** - 详细测试指南
- **CROSS-PLATFORM-SUPPORT.md** - 跨平台支持文档
- **QUICK-REFERENCE.md** - 快速参考
- **demo-test.ps1** - 演示测试脚本
- **test-environment.ps1** - 交互式测试工具
- **test-cross-platform.ps1** - 综合测试套件

---

## ✅ 测试检查清单

在提交或部署前,确保:

- [ ] 运行 `.\demo-test.ps1` 无错误
- [ ] 环境检测返回正确结果
- [ ] 所有脚本文件存在
- [ ] 语法检查通过
- [ ] 至少在一个环境中测试成功
- [ ] 查看 TESTING-GUIDE.md 了解详细信息

---

## 💡 最佳实践

1. **从简单开始**: 先运行 `.\demo-test.ps1`
2. **逐步深入**: 然后运行 `.\test-cross-platform.ps1`
3. **针对性测试**: 使用 `.\test-environment.ps1` 测试特定环境
4. **记录结果**: 保存测试输出用于对比
5. **多环境验证**: 在所有可用环境中测试

---

**最后更新**: 2026-01-27
**版本**: 1.1
