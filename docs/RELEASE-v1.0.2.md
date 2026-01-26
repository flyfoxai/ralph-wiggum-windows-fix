# Release v1.0.2 - Stop Hook Fix

## 🎉 发布成功！

版本 **v1.0.2** 已成功发布到 GitHub。

## 📦 发布内容

### Git提交
- **Commit**: `5be6130`
- **Tag**: `v1.0.2`
- **Branch**: `main`
- **Remote**: https://github.com/flyfoxai/ralph-wiggum-windows-fix.git

### 修复的问题

✅ **Critical Bug**: 修复了hooks.json嵌套结构导致stop hooks执行两次的问题

**症状**:
```
● Ran 2 stop hooks
  ⎿  Stop hook error: Failed with non-blocking status code:
     /usr/bin/sh: /usr/bin/sh: cannot execute binary file
```

**根本原因**:
- hooks.json使用了错误的嵌套结构
- 导致每个hook被执行两次
- 造成资源竞争和sh执行错误

**解决方案**:
- 移除多余的嵌套"hooks"层
- 使用正确的扁平数组结构
- 每个平台现在只执行一次对应的hook

## 📝 更新的文件

### 核心修复
- ✅ `hooks/hooks.json` - 修复嵌套结构
- ✅ `.claude-plugin/plugin.json` - 版本升级到1.0.2
- ✅ `.claude-plugin/marketplace.json` - 版本升级到1.0.2

### 新增文件
- ✅ `CHANGELOG.md` - 版本变更日志
- ✅ `docs/STOP-HOOK-ERROR-FIX.md` - 详细修复文档
- ✅ `tests/diagnose-hook-error.ps1` - 诊断脚本
- ✅ `tests/validate-hooks-fix.ps1` - 验证脚本

## 🧪 测试验证

所有测试通过：
- ✅ JSON语法验证
- ✅ 结构验证（无嵌套hooks）
- ✅ Hook属性验证
- ✅ 平台覆盖验证（win32, darwin, linux）

## 📊 影响

### 性能改进
- 🚀 Hook执行速度提升（减少50%重复执行）
- 🚀 消除资源竞争条件
- 🚀 减少错误日志输出

### 稳定性提升
- ✅ 消除持续存在的sh执行错误
- ✅ 防止状态文件并发访问问题
- ✅ 提高跨平台兼容性

## 🔄 升级指南

### 对于现有用户

1. **拉取最新代码**:
   ```bash
   git pull origin main
   ```

2. **验证修复**:
   ```powershell
   pwsh -File tests/validate-hooks-fix.ps1
   ```

3. **重新加载plugin**:
   - 重启Claude Code CLI
   - 或重新加载plugin配置

### 对于新用户

直接安装v1.0.2版本：
```bash
git clone https://github.com/flyfoxai/ralph-wiggum-windows-fix.git
cd ralph-wiggum-windows-fix
git checkout v1.0.2
```

## 📚 相关文档

- [CHANGELOG.md](../CHANGELOG.md) - 完整变更历史
- [STOP-HOOK-ERROR-FIX.md](../docs/STOP-HOOK-ERROR-FIX.md) - 详细技术文档
- [README.md](../README.md) - 项目说明

## 🙏 致谢

感谢用户报告这个持续存在的问题，使我们能够定位并修复这个关键bug。

---

**发布时间**: 2026-01-25
**发布者**: FlyfoxAI Team
**协作者**: Claude Sonnet 4.5
