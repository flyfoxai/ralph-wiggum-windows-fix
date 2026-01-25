# Ralph Loop 新功能说明
# New Features Documentation

**版本**: 1.20+
**日期**: 2026-01-25

---

## 🎯 新功能概述

本次更新为 Ralph Loop 添加了三个重要的新功能，使其更加灵活和易用。

---

## 1. 默认最大迭代次数配置 ⚙️

### 功能说明

现在可以设置一个全局的默认最大迭代次数，所有 Ralph 命令都会使用这个默认值（除非显式指定 `--max-iterations` 参数）。

### 使用方法

#### 设置默认值

```bash
/ralph-smart-setmaxiterations 20
```

这会将默认最大迭代次数设置为 20。

#### 查看当前配置

配置存储在: `~/.claude/ralph-config.json`

```json
{
  "defaultMaxIterations": 20,
  "lastUpdated": "2026-01-25T19:31:36Z"
}
```

### 优势

- ✅ 不需要每次都输入 `--max-iterations`
- ✅ 统一管理所有 Ralph 循环的默认行为
- ✅ 可以随时修改默认值
- ✅ 仍然可以用参数覆盖默认值

### 示例

```bash
# 设置默认值为 25
/ralph-smart-setmaxiterations 25

# 使用默认值 (25 次迭代)
/ralph-smart "Build a REST API"

# 覆盖默认值 (使用 30 次迭代)
/ralph-smart "Complex task" --max-iterations 30
```

---

## 2. 可选的 max-iterations 参数 📝

### 功能说明

`--max-iterations` 参数现在是可选的。如果不指定，命令会自动使用配置的默认值。

### 之前的用法

```bash
# 必须指定 --max-iterations
/ralph-smart "Your task" --max-iterations 15
/ralph-loop "Your task" --max-iterations 20
```

### 现在的用法

```bash
# 不需要指定 --max-iterations (使用默认值)
/ralph-smart "Your task"
/ralph-loop "Your task"

# 仍然可以指定 (覆盖默认值)
/ralph-smart "Your task" --max-iterations 30
```

### 默认值

如果没有设置配置，默认使用 **15 次迭代**。

---

## 3. 从文件读取提示 📄

### 功能说明

现在可以将任务描述保存在文本文件中，然后通过文件路径来启动 Ralph 循环。这对于复杂的、多行的任务描述特别有用。

### 支持的文件格式

- `.txt` - 纯文本文件
- `.md` - Markdown 文件
- `.markdown` - Markdown 文件
- 任何文本文件

### 使用方法

#### 1. 创建提示文件

**prompt.txt**:
```
Build a REST API for managing todos.

Requirements:
- CRUD operations (Create, Read, Update, Delete)
- Input validation
- Error handling
- Unit tests with 80% coverage
- API documentation (OpenAPI/Swagger)
- Rate limiting
- Authentication (JWT)

Technical Stack:
- Node.js + Express
- PostgreSQL database
- Jest for testing

Output "COMPLETE" when all requirements are met and tests pass.
```

#### 2. 使用文件路径启动循环

```bash
# 相对路径
/ralph-smart ./prompt.txt
/ralph-smart ../tasks/task1.md

# 绝对路径
/ralph-smart C:\projects\prompts\api-task.txt
/ralph-smart /home/user/tasks/feature.md

# 仍然可以添加其他参数
/ralph-smart ./prompt.txt --max-iterations 30
/ralph-smart task.md --completion-promise "DONE"
```

### 文件路径检测

系统会自动检测参数是否为文件路径，支持以下模式：

- `./file` 或 `../file` - 相对路径
- `C:\path\file` - Windows 绝对路径
- `/path/file` - Unix 绝对路径
- `file.txt` 或 `file.md` - 带扩展名的文件

### 优势

- ✅ 支持复杂的多行任务描述
- ✅ 可以重用任务模板
- ✅ 便于版本控制和团队协作
- ✅ 支持 Markdown 格式化
- ✅ 可以包含详细的需求和检查清单

### 示例文件

**examples/api-development.md**:
```markdown
# REST API Development Task

## Objective
Build a production-ready REST API for todo management.

## Requirements

### Core Features
- [ ] CRUD operations
- [ ] Input validation
- [ ] Error handling
- [ ] Pagination
- [ ] Filtering and sorting

### Quality
- [ ] Unit tests (80% coverage)
- [ ] Integration tests
- [ ] API documentation
- [ ] Error logging

### Security
- [ ] JWT authentication
- [ ] Rate limiting
- [ ] Input sanitization

## Completion Criteria
Output "API_COMPLETE" when:
1. All features implemented
2. All tests passing
3. Documentation complete
4. Code reviewed
```

使用:
```bash
/ralph-smart examples/api-development.md --completion-promise "API_COMPLETE"
```

---

## 🔄 完整工作流示例

### 场景 1: 快速任务

```bash
# 设置默认迭代次数
/ralph-smart-setmaxiterations 15

# 直接运行 (使用默认值)
/ralph-smart "Fix the authentication bug"
```

### 场景 2: 复杂项目

```bash
# 1. 创建详细的任务文件
# tasks/feature-x.md

# 2. 设置较高的迭代次数
/ralph-smart-setmaxiterations 30

# 3. 从文件启动
/ralph-smart tasks/feature-x.md --completion-promise "FEATURE_COMPLETE"
```

### 场景 3: 团队协作

```bash
# 团队共享任务模板
# templates/api-task.md
# templates/ui-task.md
# templates/test-task.md

# 每个开发者使用相同的模板
/ralph-smart templates/api-task.md

# 可以根据需要调整迭代次数
/ralph-smart templates/ui-task.md --max-iterations 20
```

---

## 📊 功能对比

| 功能 | 之前 | 现在 |
|------|------|------|
| **max-iterations** | 必须指定 | 可选（使用默认值） |
| **默认配置** | 无 | 全局配置文件 |
| **提示输入** | 仅命令行字符串 | 字符串或文件路径 |
| **复杂任务** | 难以管理 | 使用文件轻松管理 |
| **任务重用** | 需要复制粘贴 | 直接引用文件 |

---

## 🛠️ 技术实现

### 配置管理

- **配置文件**: `~/.claude/ralph-config.json`
- **模块**: `lib/ralph-config.ps1`
- **函数**:
  - `Get-RalphConfig` - 读取配置
  - `Set-RalphConfig` - 保存配置
  - `Get-DefaultMaxIterations` - 获取默认值
  - `Set-DefaultMaxIterations` - 设置默认值

### 文件读取

- **函数**:
  - `Test-IsFilePath` - 检测是否为文件路径
  - `Read-PromptFromFile` - 从文件读取内容
- **支持**: UTF-8 编码，自动去除首尾空白

### 命令更新

- **ralph-smart.md** - 更新参数说明
- **ralph-loop.md** - 更新参数说明
- **ralph-smart-setmaxiterations.md** - 新命令
- **smart-ralph-loop.ps1** - 支持配置和文件
- **setup-ralph-loop.ps1** - 支持配置和文件

---

## ✅ 测试验证

运行测试脚本验证所有功能:

```powershell
.\tests\test-new-features.ps1
```

**测试结果**:
- ✅ 配置管理功能正常
- ✅ 文件路径检测功能正常 (7/7 测试通过)
- ✅ 从文件读取提示功能正常
- ✅ 默认最大迭代次数功能正常

---

## 📝 最佳实践

### 1. 设置合理的默认值

```bash
# 对于大多数任务，15-25 次迭代是合理的
/ralph-smart-setmaxiterations 20
```

### 2. 使用文件管理复杂任务

```bash
# 创建任务模板目录
mkdir tasks
mkdir templates

# 保存常用任务
echo "Your task description" > tasks/current-task.md

# 使用模板
/ralph-smart tasks/current-task.md
```

### 3. 版本控制任务文件

```bash
# 将任务文件加入 git
git add tasks/*.md
git commit -m "Add task templates"

# 团队成员可以共享任务
/ralph-smart tasks/shared-task.md
```

### 4. 组合使用所有功能

```bash
# 1. 设置默认值
/ralph-smart-setmaxiterations 25

# 2. 创建任务文件
cat > task.md << 'EOF'
Build feature X with tests and documentation.
Output "DONE" when complete.
EOF

# 3. 启动循环
/ralph-smart task.md --completion-promise "DONE"
```

---

## 🔗 相关文档

- **[README.md](../README.md)** - 项目主文档
- **[README_CN.md](../README_CN.md)** - 中文文档
- **[commands/ralph-smart.md](../commands/ralph-smart.md)** - Smart Ralph 命令
- **[commands/ralph-loop.md](../commands/ralph-loop.md)** - Ralph Loop 命令
- **[commands/ralph-smart-setmaxiterations.md](../commands/ralph-smart-setmaxiterations.md)** - 配置命令

---

**更新日期**: 2026-01-25
**版本**: 1.20+
