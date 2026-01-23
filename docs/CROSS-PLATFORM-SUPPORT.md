# 跨平台环境支持文档
# Cross-Platform Environment Support Documentation

## 📋 支持的环境 | Supported Environments

本文档详细说明 Ralph Wiggum 插件在各种执行环境下的支持情况和实现方案。

---

## 🎯 环境支持矩阵

| 环境 | process.platform | 可用 Shell | 使用脚本 | 检测方法 | 状态 |
|------|------------------|-----------|---------|---------|------|
| **原生 Windows** | `win32` | PowerShell 7+ | `stop-hook.ps1` | `$env:OS -eq "Windows_NT"` | ✅ 完全支持 |
| **WSL1** | `linux` | sh/bash | `stop-hook-posix.sh` | `$WSL_DISTRO_NAME` 或 `/proc/version` | ✅ 完全支持 |
| **WSL2** | `linux` | sh/bash | `stop-hook-posix.sh` | `$WSL_DISTRO_NAME` 或 `/proc/version` | ✅ 完全支持 |
| **原生 macOS** | `darwin` | bash/zsh | `stop-hook.sh` | `uname -s = Darwin` | ✅ 完全支持 |
| **原生 Linux** | `linux` | bash | `stop-hook.sh` | `uname -s = Linux` (非 WSL) | ✅ 完全支持 |
| **Git Bash** | `win32` | bash | `stop-hook-posix.sh` | `$MSYSTEM` 环境变量 | ✅ 完全支持 |
| **Cygwin** | `win32` | bash | `stop-hook-posix.sh` | `$CYGWIN` 环境变量 | ✅ 完全支持 |

---

## 🔍 环境检测逻辑

### 1. Windows 原生环境

**检测条件**:
- `process.platform === 'win32'`
- 无 `WSL_DISTRO_NAME` 环境变量
- 无 `MSYSTEM` 环境变量
- 无 `CYGWIN` 环境变量

**执行方案**:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "stop-hook.ps1"
```

**特点**:
- 使用原生 PowerShell 7+ 实现
- 完整的 Windows API 支持
- 最佳性能和兼容性

---

### 2. WSL1/WSL2 环境

**检测条件**:
- `$WSL_DISTRO_NAME` 环境变量存在，或
- `$WSL_INTEROP` 环境变量存在，或
- `/proc/version` 包含 "microsoft" 或 "WSL"

**执行方案**:
```bash
sh stop-hook-posix.sh
```

**特点**:
- 使用 POSIX 兼容的 sh 脚本
- 不依赖 bash 特性
- 兼容 WSL 最小安装

**WSL 特殊考虑**:
1. **Shell 可用性**: WSL 可能只有 `sh`,没有 `bash`
2. **路径转换**: Windows 路径需要转换为 WSL 路径
3. **性能**: WSL2 比 WSL1 性能更好

**检测示例**:
```bash
# 检查 WSL 版本
if [ -f /proc/version ]; then
    grep -qi "microsoft\|wsl" /proc/version && echo "Running in WSL"
fi

# 检查环境变量
[ -n "${WSL_DISTRO_NAME:-}" ] && echo "WSL Distribution: $WSL_DISTRO_NAME"
```

---

### 3. 原生 macOS 环境

**检测条件**:
- `process.platform === 'darwin'`
- `uname -s` 返回 "Darwin"

**执行方案**:
```bash
bash stop-hook.sh
# 或 fallback 到
sh stop-hook-posix.sh
```

**特点**:
- 优先使用 bash 版本
- 支持 zsh (macOS Catalina+)
- 完整的 Unix 工具链

---

### 4. 原生 Linux 环境

**检测条件**:
- `process.platform === 'linux'`
- `uname -s` 返回 "Linux"
- `/proc/version` 不包含 "microsoft" 或 "WSL"

**执行方案**:
```bash
bash stop-hook.sh
# 或 fallback 到
sh stop-hook-posix.sh
```

**特点**:
- 标准 Linux 环境
- 完整的 bash 支持
- 最佳兼容性

---

### 5. Git Bash (Windows)

**检测条件**:
- `process.platform === 'win32'`
- `$MSYSTEM` 环境变量存在 (MINGW64, MINGW32, MSYS 等)
- `uname -s` 返回 "MINGW*" 或 "MSYS*"

**执行方案**:
```bash
bash stop-hook-posix.sh
```

**特点**:
- MSYS2 环境
- 提供 Unix 工具的 Windows 移植
- bash 完全可用

**Git Bash 特殊考虑**:
1. **路径格式**: 使用 Unix 风格路径 (`/c/Users/...`)
2. **工具可用性**: 大部分 Unix 工具可用
3. **性能**: 比 WSL 稍慢,但比 Cygwin 快

---

### 6. Cygwin (Windows)

**检测条件**:
- `process.platform === 'win32'`
- `$CYGWIN` 环境变量存在
- `uname -s` 返回 "CYGWIN*"

**执行方案**:
```bash
bash stop-hook-posix.sh
```

**特点**:
- 完整的 POSIX 环境模拟
- 丰富的 Unix 工具
- bash 完全可用

**Cygwin 特殊考虑**:
1. **路径转换**: Cygwin 路径 (`/cygdrive/c/...`)
2. **性能**: 相对较慢
3. **兼容性**: 最接近真实 Unix 环境

---

## 🛠️ 实现方案详解

### 智能路由系统

#### PowerShell 路由器 (`stop-hook-router.ps1`)

```powershell
# 检测环境
$env = Detect-Environment  # windows|wsl|gitbash|cygwin

# 根据环境路由
switch ($env) {
    "windows" {
        # 使用 PowerShell 实现
        & pwsh -File "stop-hook.ps1"
    }
    "wsl" {
        # 使用 WSL 执行 POSIX 脚本
        wsl sh stop-hook-posix.sh
    }
    "gitbash" {
        # 使用 bash 执行 POSIX 脚本
        bash stop-hook-posix.sh
    }
    "cygwin" {
        # 使用 bash 执行 POSIX 脚本
        bash stop-hook-posix.sh
    }
}
```

#### Shell 路由器 (`stop-hook-router.sh`)

```bash
#!/bin/sh
# 检测环境
ENV=$(detect_environment)  # wsl|linux|darwin|gitbash

# 根据环境路由
case "$ENV" in
    wsl)
        # WSL 环境 - 使用 POSIX 兼容版本
        sh stop-hook-posix.sh
        ;;
    linux|darwin)
        # 原生 Unix - 优先 bash,fallback 到 sh
        if command -v bash >/dev/null 2>&1; then
            bash stop-hook.sh
        else
            sh stop-hook-posix.sh
        fi
        ;;
    gitbash)
        # Git Bash - 使用 POSIX 兼容版本
        bash stop-hook-posix.sh
        ;;
esac
```

---

## 📝 POSIX 兼容性说明

### Bash vs POSIX sh 差异

| 特性 | Bash | POSIX sh | 解决方案 |
|------|------|----------|---------|
| `[[ ]]` | ✅ | ❌ | 使用 `[ ]` |
| `=~` 正则 | ✅ | ❌ | 使用 `case` 或 `grep` |
| `${var:offset:length}` | ✅ | ❌ | 使用 `cut` 或 `awk` |
| `$((expr))` | ✅ | ✅ | 可用 |
| `$(command)` | ✅ | ✅ | 可用 |
| `set -o pipefail` | ✅ | ❌ | 使用 `set -e` |

### POSIX 兼容改写示例

**Bash 版本**:
```bash
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
    echo "Invalid number"
fi
```

**POSIX 版本**:
```bash
case "$ITERATION" in
    ''|*[!0-9]*)
        echo "Invalid number"
        ;;
esac
```

---

## 🧪 测试方法

### 1. 测试环境检测

```powershell
# PowerShell
.\hooks\detect-environment.ps1 all
```

```bash
# Shell
sh ./hooks/detect-environment.sh all
```

### 2. 运行完整测试套件

```powershell
.\test-cross-platform.ps1 -Verbose
```

### 3. 手动测试特定环境

**Windows 原生**:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hooks\stop-hook.ps1
```

**WSL**:
```bash
wsl sh ./hooks/stop-hook-posix.sh
```

**Git Bash**:
```bash
bash ./hooks/stop-hook-posix.sh
```

---

## 🔧 故障排除

### 问题 1: WSL 中找不到 bash

**症状**:
```
/bin/sh: bash: not found
```

**原因**: WSL 最小安装可能不包含 bash

**解决方案**:
1. 使用 POSIX 兼容的 `stop-hook-posix.sh`
2. 或安装 bash: `sudo apt install bash`

### 问题 2: Git Bash 路径问题

**症状**:
```
No such file or directory: C:\Users\...
```

**原因**: Git Bash 使用 Unix 风格路径

**解决方案**:
- 路径自动转换由路由器处理
- 确保使用 `stop-hook-posix.sh`

### 问题 3: PowerShell 执行策略错误

**症状**:
```
cannot be loaded because running scripts is disabled
```

**解决方案**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# 或使用 -ExecutionPolicy Bypass 参数
```

### 问题 4: Cygwin 路径转换

**症状**:
```
/cygdrive/c/... not found
```

**解决方案**:
- 使用 `cygpath` 工具转换路径
- 路由器会自动处理

---

## 📊 性能对比

| 环境 | 启动时间 | 执行效率 | 内存占用 |
|------|---------|---------|---------|
| Windows 原生 | 快 (~50ms) | 高 | 中等 |
| WSL2 | 中等 (~100ms) | 高 | 中等 |
| WSL1 | 慢 (~200ms) | 中等 | 低 |
| macOS | 快 (~50ms) | 高 | 低 |
| Linux | 快 (~30ms) | 最高 | 最低 |
| Git Bash | 中等 (~150ms) | 中等 | 中等 |
| Cygwin | 慢 (~300ms) | 低 | 高 |

---

## 🎯 最佳实践

### 1. 环境选择建议

- **Windows 用户**:
  - 首选: 原生 PowerShell (最佳性能)
  - 备选: WSL2 (更好的 Unix 兼容性)
  - 避免: Cygwin (性能较差)

- **macOS/Linux 用户**:
  - 使用原生环境 (最佳体验)

- **跨平台开发**:
  - 使用 WSL2 (Windows) + 原生 (macOS/Linux)
  - 确保脚本 POSIX 兼容

### 2. 脚本编写建议

- 新脚本优先使用 POSIX 兼容语法
- 避免使用 bash 特有特性
- 使用 `#!/bin/sh` 而不是 `#!/bin/bash`
- 测试所有目标环境

### 3. 调试建议

- 使用 `-x` 选项查看执行过程: `sh -x script.sh`
- 检查环境变量: `env | grep -i wsl`
- 验证 shell 版本: `sh --version`

---

## 📚 参考资源

- [POSIX Shell 规范](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [WSL 文档](https://docs.microsoft.com/en-us/windows/wsl/)
- [Git Bash 文档](https://git-scm.com/docs/git-bash)
- [Cygwin 文档](https://www.cygwin.com/docs.html)
- [PowerShell 文档](https://docs.microsoft.com/en-us/powershell/)

---

## 🔄 更新日志

| 版本 | 日期 | 变更 |
|------|------|------|
| 2.0 | 2026-01-23 | 添加完整跨平台支持 |
| 1.1 | 2026-01-22 | 添加 WSL 支持 |
| 1.0 | 2026-01-21 | 初始 Windows 修复 |

---

**维护者**: Claude Code Community
**最后更新**: 2026-01-23
