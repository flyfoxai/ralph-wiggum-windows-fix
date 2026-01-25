# Stop Hook Error Fix

## 问题描述

用户报告了一个持续存在的stop hook错误：

```
● Ran 2 stop hooks
  ⎿  Stop hook error: Failed with non-blocking status code: /usr/bin/sh: /usr/bin/sh: cannot execute binary file
```

## 根本原因

问题出在 `hooks/hooks.json` 的结构上。原始配置使用了**嵌套的hooks结构**：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [          // ❌ 错误：多余的嵌套层
          { "type": "command", ... },
          { "type": "command", ... }
        ]
      }
    ]
  }
}
```

这种嵌套结构导致：
1. **Hooks被执行两次** - 错误信息"Ran 2 stop hooks"证实了这一点
2. **可能的执行顺序问题** - 导致sh命令被错误调用
3. **资源竞争** - 两个hooks同时尝试访问相同的状态文件

## 解决方案

移除多余的嵌套层，使用正确的扁平结构：

```json
{
  "hooks": {
    "Stop": [              // ✅ 正确：直接包含hook对象
      { "type": "command", ... },
      { "type": "command", ... }
    ]
  }
}
```

## 修复内容

**文件**: `hooks/hooks.json`

**修改前**:
- Stop数组包含一个对象，该对象又包含hooks数组
- 导致hooks被重复执行

**修改后**:
- Stop数组直接包含hook对象
- 每个平台只执行一次对应的hook

## 验证

修复后的配置已通过以下验证：

✅ JSON语法有效
✅ 结构正确（无嵌套hooks）
✅ 所有hook都有必需的属性（type, command, platforms）
✅ 覆盖所有主要平台（win32, darwin, linux）

## 测试

运行以下命令验证修复：

```powershell
pwsh -File tests/validate-hooks-fix.ps1
```

## 预期结果

修复后：
- ✅ 只运行1个stop hook（而不是2个）
- ✅ 不再出现 `/usr/bin/sh: cannot execute binary file` 错误
- ✅ Hook执行更快（减少了重复执行）
- ✅ 避免了潜在的状态文件竞争条件

## 相关文件

- `hooks/hooks.json` - 主配置文件（已修复）
- `hooks/stop-hook-router.ps1` - Windows路由器
- `hooks/stop-hook-router.sh` - Unix路由器
- `tests/validate-hooks-fix.ps1` - 验证脚本
- `tests/diagnose-hook-error.ps1` - 诊断脚本

## 注意事项

如果错误仍然出现，可能需要：
1. 重新加载Claude Code配置
2. 重启Claude Code CLI
3. 检查是否有其他hooks.json文件被加载

## 技术细节

Claude Code的hook系统期望的结构是：
```
hooks.Stop = Array<HookObject>
```

而不是：
```
hooks.Stop = Array<{ hooks: Array<HookObject> }>
```

嵌套结构可能被解释为hook组，导致每个组内的hooks都被执行，从而造成重复执行。
