# 跨平台支持快速参考
# Cross-Platform Support Quick Reference

## 🚀 快速开始

### 检测当前环境

**PowerShell**:
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hooks\detect-environment.ps1 all
```

**Shell**:
```bash
sh ./hooks/detect-environment.sh all
```

---

## 📁 文件说明

### 核心脚本

| 文件 | 用途 | 适用环境 |
|------|------|---------|
| `stop-hook.ps1` | PowerShell 实现 | Windows 原生 |
| `stop-hook.sh` | Bash 实现 | macOS, Linux (原生) |
| `stop-hook-posix.sh` | POSIX sh 实现 | WSL, Git Bash, Cygwin |
| `stop-hook-router.ps1` | Windows 路由器 | Windows (所有) |
| `stop-hook-router.sh` | Unix 路由器 | macOS, Linux, WSL |

### 工具脚本

| 文件 | 用途 |
|------|------|
| `detect-environment.ps1` | PowerShell 环境检测 |
| `detect-environment.sh` | Shell 环境检测 |

---

## 🔍 环境识别

### 我在什么环境?

运行检测脚本查看:

```powershell
# PowerShell
.\hooks\detect-environment.ps1 env
```

```bash
# Shell
sh ./hooks/detect-environment.sh env
```

**可能的输出**:
- `windows` - Windows 原生
- `wsl` - WSL1 或 WSL2
- `linux` - 原生 Linux
- `darwin` - macOS
- `gitbash` - Git Bash
- `cygwin` - Cygwin
- `unknown` - 未知环境

---

## 🛠️ 使用方法

### 方案 A: 使用路由器 (推荐)

**更新 hooks.json**:
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.ps1\"",
            "platforms": ["win32"]
          },
          {
            "type": "command",
            "command": "sh \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.sh\"",
            "platforms": ["darwin", "linux"]
          }
        ]
      }
    ]
  }
}
```

### 方案 B: 直接指定脚本

**Windows 原生**:
```json
"command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.ps1\""
```

**WSL/Git Bash/Cygwin**:
```json
"command": "sh \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-posix.sh\""
```

**macOS/Linux**:
```json
"command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.sh\""
```

---

## 🧪 测试

### 运行完整测试

```powershell
.\test-cross-platform.ps1
```

### 测试特定脚本

**PowerShell 版本**:
```powershell
echo '{"transcript_path": "test.jsonl"}' | pwsh -NoProfile -ExecutionPolicy Bypass -File .\hooks\stop-hook.ps1
```

**POSIX 版本**:
```bash
echo '{"transcript_path": "test.jsonl"}' | sh ./hooks/stop-hook-posix.sh
```

---

## 🔧 故障排除

### 问题: WSL 中找不到 bash

**症状**:
```
/bin/sh: bash: not found
```

**解决**:
使用 POSIX 版本:
```bash
sh ./hooks/stop-hook-posix.sh
```

### 问题: PowerShell 执行策略错误

**症状**:
```
cannot be loaded because running scripts is disabled
```

**解决**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题: 路径找不到

**症状**:
```
No such file or directory
```

**检查**:
1. 确认文件存在: `ls hooks/`
2. 检查权限: `ls -la hooks/*.sh`
3. 设置执行权限: `chmod +x hooks/*.sh`

---

## 📊 环境对比

| 特性 | Windows | WSL | macOS | Linux | Git Bash | Cygwin |
|------|---------|-----|-------|-------|----------|--------|
| **使用脚本** | PS1 | POSIX | Bash | Bash | POSIX | POSIX |
| **性能** | 快 | 中 | 快 | 最快 | 中 | 慢 |
| **兼容性** | 高 | 高 | 高 | 最高 | 中 | 高 |
| **推荐度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

---

## 📚 相关文档

- **CROSS-PLATFORM-SUPPORT.md** - 详细支持文档
- **CROSS-PLATFORM-IMPLEMENTATION.md** - 实施总结
- **README.md** - 项目说明
- **WINDOWS-FIXES.md** - Windows 修复说明

---

## 🎯 最佳实践

### Windows 用户

1. **首选**: 原生 PowerShell (最佳性能)
2. **备选**: WSL2 (更好的 Unix 兼容性)
3. **避免**: Cygwin (性能较差)

### macOS/Linux 用户

1. 使用原生环境 (最佳体验)
2. 确保 bash 可用

### 跨平台开发

1. 使用路由器模式 (自动适配)
2. 测试所有目标环境
3. 编写 POSIX 兼容脚本

---

## ✅ 检查清单

部署前检查:

- [ ] 所有脚本文件存在
- [ ] Unix 脚本有执行权限 (`chmod +x`)
- [ ] hooks.json 配置正确
- [ ] 测试套件通过 (> 90%)
- [ ] 环境检测工作正常

---

**最后更新**: 2026-01-23
**版本**: 2.0
