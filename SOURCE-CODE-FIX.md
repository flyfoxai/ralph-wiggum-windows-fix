# 源码级别修复报告

## 修复日期
2026-01-25

## 问题描述
在 Git Bash 环境下，Claude Code 错误地尝试执行 Linux/macOS 的 bash hook，导致错误：
```
Stop hook error: Failed with non-blocking status code: /bin/bash:
C:Usersdooji.claudepluginscacheralph-wiggum-cross-platformralph-wiggum1.0.0/hooks/stop-hook.sh: No such file or directory
```

## 根本原因
原始的 `hooks.json` 配置直接调用特定平台的脚本：
- Windows: `stop-hook.ps1`
- Linux/macOS: `stop-hook.sh`

在 Git Bash 环境下，Claude Code 可能错误地识别平台，选择了错误的 hook。

## 源码修复方案

### 修改文件
`hooks/hooks.json`

### 修复内容
将直接调用改为使用**智能路由脚本**：

**修复前**：
```json
{
  "type": "command",
  "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook.ps1\"",
  "platforms": ["win32"]
}
```

**修复后**：
```json
{
  "type": "command",
  "comment": "Windows - use router for intelligent environment detection (Git Bash, WSL, Cygwin)",
  "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.ps1\"",
  "platforms": ["win32"]
}
```

### 路由脚本的优势

`stop-hook-router.ps1` 会自动检测并适配以下环境：

1. **Git Bash / MSYS**
   - 检测方式：`$env:MSYSTEM` 环境变量
   - 处理方式：使用 POSIX 兼容的 `stop-hook-posix.sh`

2. **WSL (Windows Subsystem for Linux)**
   - 检测方式：`$env:WSL_DISTRO_NAME` 或 `$env:WSL_INTEROP`
   - 处理方式：使用 WSL 特定的实现

3. **Cygwin**
   - 检测方式：`$env:CYGWIN` 环境变量
   - 处理方式：使用 POSIX 兼容的实现

4. **Native Windows**
   - 检测方式：默认
   - 处理方式：使用 PowerShell 实现 `stop-hook.ps1`

## 验证步骤

### 1. 检查源码修改
```powershell
Get-Content hooks\hooks.json
```

应该看到使用 `stop-hook-router.ps1` 而不是直接的 `stop-hook.ps1`。

### 2. 检查路由脚本存在
```powershell
Test-Path hooks\stop-hook-router.ps1
Test-Path hooks\stop-hook-router.sh
```

两个都应该返回 `True`。

### 3. 重新安装插件
```bash
# 如果插件已安装，需要重新安装以应用源码修改
claude plugin uninstall ralph-wiggum
claude plugin install .
```

### 4. 测试 Stop Hook
在 Git Bash 环境下运行 Claude Code，然后按 Ctrl+C 停止，应该不再出现错误。

## 备份信息
原始配置已备份到：`hooks/hooks.json.backup`

如需恢复：
```powershell
Copy-Item hooks\hooks.json.backup hooks\hooks.json -Force
```

## 技术细节

### 路由脚本检测逻辑
```powershell
# Git Bash 检测
if ($env:MSYSTEM) {
    # 使用 POSIX 兼容脚本
    & bash "$ScriptDir/stop-hook-posix.sh"
}

# WSL 检测
if ($env:WSL_DISTRO_NAME -or $env:WSL_INTEROP) {
    # 使用 WSL 特定实现
}

# Cygwin 检测
if ($env:CYGWIN) {
    # 使用 POSIX 兼容脚本
}

# 默认：Native Windows
# 使用 PowerShell 实现
```

## 优势对比

| 特性 | 直接调用 | 路由脚本 |
|------|---------|---------|
| Git Bash 支持 | ❌ 可能失败 | ✅ 自动检测 |
| WSL 支持 | ❌ 需要手动配置 | ✅ 自动检测 |
| Cygwin 支持 | ❌ 不支持 | ✅ 自动检测 |
| Native Windows | ✅ 支持 | ✅ 支持 |
| 维护性 | ❌ 需要多个配置 | ✅ 单一配置 |
| 可扩展性 | ❌ 难以扩展 | ✅ 易于扩展 |

## 长期维护

这是**永久性修复**，因为：
1. ✅ 修改的是项目源代码，不是插件缓存
2. ✅ 插件更新时会使用新的源码配置
3. ✅ 其他用户安装插件时会自动获得修复

## 相关文件

- `hooks/hooks.json` - 主配置文件（已修复）
- `hooks/hooks-enhanced.json` - 增强配置参考
- `hooks/stop-hook-router.ps1` - Windows 路由脚本
- `hooks/stop-hook-router.sh` - Unix 路由脚本
- `hooks/stop-hook.ps1` - Windows 原生实现
- `hooks/stop-hook-posix.sh` - POSIX 兼容实现
- `hooks/stop-hook.sh` - Unix 原生实现

## 测试建议

在以下环境中测试：
1. ✅ Git Bash (Windows)
2. ✅ PowerShell (Windows)
3. ✅ WSL1/WSL2
4. ✅ Cygwin
5. ✅ Native Windows Terminal

## 问题排查

如果仍然出现错误：

1. **检查路由脚本权限**
   ```powershell
   Get-Acl hooks\stop-hook-router.ps1
   ```

2. **手动测试路由脚本**
   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File hooks\stop-hook-router.ps1 -Debug
   ```

3. **检查环境变量**
   ```powershell
   Get-ChildItem Env: | Where-Object { $_.Name -match 'MSYSTEM|WSL|CYGWIN' }
   ```

## 总结

✅ **修复完成**：源码级别的永久性修复
✅ **智能路由**：自动检测并适配多种 Windows 环境
✅ **向后兼容**：保持对所有平台的支持
✅ **易于维护**：单一配置，统一管理
