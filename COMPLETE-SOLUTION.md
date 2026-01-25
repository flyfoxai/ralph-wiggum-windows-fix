# 插件错误完整解决方案
# Complete Plugin Error Solution

**日期**: 2026-01-25
**状态**: 诊断完成,等待用户操作

---

## 诊断结果 ✅

运行诊断脚本后发现:

### hooks.json 文件状态
- ✅ **版本 1.0.0**: hooks.json 结构正确
- ✅ **版本 1.0.1**: hooks.json 结构正确
- ✅ **版本 1.0.2**: hooks.json 结构正确
- ✅ **版本 1.10**: hooks.json 结构正确

**结论**: 所有版本的 hooks.json 文件结构都是正确的,包含了必需的嵌套 `hooks` 数组。

---

## 问题分析

既然文件结构正确,但插件仍然报错,可能的原因是:

### 1. Claude Code 缓存问题 (最可能)
- Claude Code 可能缓存了旧的错误状态
- 插件加载器没有重新读取更新后的文件
- 需要强制刷新缓存

### 2. 插件版本混淆
- 系统中有多个版本 (1.0.0, 1.0.1, 1.0.2, 1.10)
- Claude Code 可能在读取错误的版本
- 或者在版本切换时出现缓存不一致

---

## 解决方案

### 方案 1: 重启 Claude Code (推荐,最简单)

**步骤**:
1. 完全退出 Claude Code CLI
2. 重新启动 Claude Code
3. 运行 `/plugin` 检查插件状态
4. 如果仍有错误,尝试方案 2

**预期结果**: 插件应该正常加载,没有错误

---

### 方案 2: 禁用并重新启用插件

**步骤**:
1. 运行 `/plugin` 命令
2. 选择 ralph-wiggum 插件
3. 选择 "Disable plugin"
4. 再次运行 `/plugin`
5. 重新启用插件

**预期结果**: 强制重新加载插件配置

---

### 方案 3: 清除插件缓存 (如果方案 1 和 2 失败)

**步骤**:
1. **完全关闭 Claude Code**
2. **删除插件缓存目录**:
   ```powershell
   Remove-Item -Recurse -Force "C:\Users\dooji\.claude\plugins\cache\ralph-wiggum-cross-platform\ralph-wiggum"
   ```
3. **重新启动 Claude Code**
4. **重新安装插件**:
   - 运行 `/plugin`
   - 搜索并安装 ralph-wiggum

**注意**: 这会删除所有版本,需要重新下载

---

### 方案 4: 只保留最新版本

**步骤**:
1. **关闭 Claude Code**
2. **删除旧版本**:
   ```powershell
   Remove-Item -Recurse -Force "C:\Users\dooji\.claude\plugins\cache\ralph-wiggum-cross-platform\ralph-wiggum\1.0.0"
   Remove-Item -Recurse -Force "C:\Users\dooji\.claude\plugins\cache\ralph-wiggum-cross-platform\ralph-wiggum\1.0.1"
   Remove-Item -Recurse -Force "C:\Users\dooji\.claude\plugins\cache\ralph-wiggum-cross-platform\ralph-wiggum\1.0.2"
   ```
3. **只保留 1.10 版本**
4. **重新启动 Claude Code**

---

## WSL 错误解决方案

WSL 错误是**独立的环境问题**,与 hooks.json 无关。

### WSL 状态
```
Ubuntu-22.04: Stopped (WSL 2)
docker-desktop: Stopped (WSL 2)
```

### 修复步骤

#### 1. 启动 WSL
```powershell
wsl
```

#### 2. 检查 systemd 配置
在 WSL 中运行:
```bash
cat /etc/wsl.conf
```

应该包含:
```ini
[boot]
systemd=true
```

如果没有,创建或编辑:
```bash
sudo nano /etc/wsl.conf
```

添加:
```ini
[boot]
systemd=true
```

#### 3. 检查 shell 二进制文件
```bash
file /usr/bin/sh
ls -la /usr/bin/sh
```

如果显示错误或损坏,重新安装:
```bash
sudo apt-get update
sudo apt-get install --reinstall dash
```

#### 4. 重启 WSL
```powershell
wsl --shutdown
wsl
```

#### 5. 验证修复
在 WSL 中运行:
```bash
systemctl --user status
/usr/bin/sh --version
```

---

## 测试验证

### 测试 1: 验证插件加载
```
/plugin
```

**预期结果**:
- ralph-wiggum 插件状态: Enabled
- 没有 "Failed to load hooks" 错误
- 显示 4 个命令

### 测试 2: 测试 Stop Hook
创建一个简单的测试:
```
/ralph-loop "echo test"
```

然后停止,检查是否有 hook 错误。

### 测试 3: 测试 Smart Ralph
```
/ralph-smart "简单的测试任务"
```

---

## 推荐操作顺序

1. **首先**: 尝试方案 1 (重启 Claude Code)
2. **如果失败**: 尝试方案 2 (禁用/启用插件)
3. **如果仍失败**: 尝试方案 4 (删除旧版本)
4. **最后手段**: 方案 3 (完全清除缓存)
5. **WSL 问题**: 独立处理,不影响插件功能

---

## 预期结果

完成上述步骤后:
- ✅ 插件应该正常加载,没有错误
- ✅ Stop hooks 应该正常工作
- ⚠️ WSL 错误可能仍然存在(需要单独修复 WSL 环境)

---

## 如果问题仍然存在

如果完成所有步骤后问题仍然存在,可能需要:

1. **检查 Claude Code 版本**
   ```
   claude --version
   ```

2. **查看详细日志**
   - 检查 Claude Code 日志文件
   - 查找插件加载相关的错误信息

3. **报告问题**
   - 在 GitHub 上报告问题
   - 提供诊断脚本输出
   - 提供 Claude Code 版本信息

---

## 总结

- ✅ **hooks.json 文件**: 所有版本都是正确的
- ⚠️ **插件错误**: 可能是缓存问题,需要重启或清除缓存
- ⚠️ **WSL 错误**: 独立的环境问题,需要在 WSL 中修复

**下一步**: 请用户尝试方案 1 (重启 Claude Code),然后报告结果。

---

**最后更新**: 2026-01-25
**诊断工具**: tests/diagnose-plugin-error.ps1
