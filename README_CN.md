# Ralph Wiggum 插件 - 跨平台版本

**版本 1.35** | [English](README.md) | 中文文档

> 支持 Windows、WSL、macOS 和 Linux 的跨平台 Ralph Wiggum 插件。

---

## 简介

A 修复：Stop hook 路径转换，避免 WSL/Git Bash 下的 bash 路径错误。
B 新增功能：`/ralph-smart` 多任务模式，支持顺序执行并自动完成检测（v1.30+）。

---

## 快速上手

1) 安装
```bash
/plugin install https://github.com/flyfoxai/ralph-wiggum-windows-fix.git
# 或：/plugin install ralph-wiggum-cross-platform
```

2) 运行任务
```bash
/ralph-smart "实现用户认证"
```

3) 可选：多任务或设置默认迭代次数
```bash
/ralph-smart tasks.md
/ralph-smart-setmaxiterations 15
```

提示：原版插件使用 `/plugin install ralph-wiggum`。

---

## Ralph 项目简介

Ralph 是一种基于持续 AI 代理循环的开发方法。本插件使用 Stop hook 拦截退出并回灌提示，直到完成或达到最大迭代次数。

```bash
/ralph-smart "实现用户认证"
# Claude Code 处理任务，尝试退出，Stop hook 阻止并继续。
```

---

## 命令速览

- `/ralph-smart` - 智能循环，自动完成检测。
- `/ralph-smart-setmaxiterations` - 设置 `/ralph-smart` 默认最大迭代次数。
- `/ralph-loop` - 基础循环，手动完成条件。
- `/cancel-ralph` - 取消当前循环。
- `/help` - 查看帮助。

---

## 文档

- 快速参考：`docs/QUICK-REFERENCE.md`
- 多任务指南：`docs/MULTI-TASK-GUIDE.md`
- 版本记录：`CHANGELOG.md`

---

## 许可证

见 `LICENSE`。
