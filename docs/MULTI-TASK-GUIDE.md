# Multi-Task Ralph Loop - Quick Start Guide

## What is Multi-Task Mode?

Multi-Task Mode allows Ralph Loop to automatically work through multiple tasks sequentially, switching from one task to the next as each completes. Perfect for complex projects with multiple related tasks.

## Quick Start

### 1. Create a Task File

Create a Markdown file with multiple tasks:

```markdown
# My Project Tasks

## Task 1: Create Database Schema
**Description**: Set up the database structure
**Acceptance Criteria**:
- [ ] Create User table
- [ ] Create Posts table
- [ ] Add foreign keys
- [ ] Create indexes

## Task 2: Implement User API
**Description**: Build REST API for user management
**Acceptance Criteria**:
- [ ] GET /users endpoint
- [ ] POST /users endpoint
- [ ] PUT /users/:id endpoint
- [ ] DELETE /users/:id endpoint
- [ ] Add input validation

## Task 3: Write Tests
**Description**: Comprehensive test coverage
**Acceptance Criteria**:
- [ ] Unit tests for API endpoints
- [ ] Integration tests for database
- [ ] Test coverage > 80%
- [ ] All tests passing
```

### 2. Run Multi-Task Ralph Loop

```bash
/ralph-smart my-tasks.md
```

### 3. Watch It Work

Ralph Loop will:
1. Parse all tasks from the file
2. Determine optimal execution order
3. Start with the first task
4. Work until acceptance criteria are met
5. Automatically switch to the next task
6. Continue until all tasks complete

## Progress Display

You'll see real-time progress like this:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Smart Ralph - Multi-Task Progress
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Total Progress: 1/3 tasks complete (33%)
🔁 Total Iterations: 15

✅ Task 1: Create Database Schema (100% - 8 iterations)
● Task 2: Implement User API (60% - 7 iterations) ← Current
☐ Task 3: Write Tests (0%)

🤖 AI Recommended Order: 1 → 2 → 3
   Reasoning: Database schema must be created first...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Task File Format

### Required Structure

Each task must have:
- **Header**: `## Task N: Title` (where N is the task number)
- **Description**: `**Description**: ...` (optional but recommended)
- **Acceptance Criteria**: Checklist items with `- [ ]` format

### Example Task

```markdown
## Task 2: Implement Authentication
**Description**: Add user authentication with JWT tokens
**Acceptance Criteria**:
- [ ] Create login endpoint
- [ ] Create registration endpoint
- [ ] Implement JWT token generation
- [ ] Add token validation middleware
- [ ] Add password hashing
```

### Supported Formats

Multi-Task Mode supports:
- ✅ Markdown format (recommended)
- ✅ YAML format
- ✅ Plain text format

## How Task Switching Works

### Completion Detection

A task is considered complete when:
- **90% or more** of acceptance criteria are checked
- Claude marks items as `- [x]` in the output

### Automatic Switching

When a task completes:
1. Current task is marked as completed
2. Next task is set to in-progress
3. Ralph Loop receives a new prompt for the next task
4. Work continues seamlessly

### Manual Interruption

You can interrupt at any time:
- Press `Ctrl+C` to pause
- State is automatically saved
- Resume by running the same command again

## Advanced Features

### Task Dependencies

The AI analyzes tasks to determine:
- Which tasks depend on others
- Optimal execution order
- Task complexity

### Progress Tracking

For each task, you can see:
- Completion percentage
- Number of iterations
- Start and end times
- Current status (pending/in_progress/completed)

### State Persistence

All progress is saved to:
```
$env:TEMP/smart-ralph-multi-task-state.json
```

This allows:
- Resume after interruption
- Progress inspection
- Debugging if needed

## Tips and Best Practices

### 1. Write Clear Acceptance Criteria

✅ **Good**:
```markdown
- [ ] Create User model with email, password, name fields
- [ ] Add email validation
- [ ] Add password hashing with bcrypt
```

❌ **Bad**:
```markdown
- [ ] Make user stuff
- [ ] Add security
```

### 2. Keep Tasks Focused

- Each task should be completable in 5-15 iterations
- Break large tasks into smaller ones
- Aim for 3-5 acceptance criteria per task

### 3. Order Tasks Logically

While AI can reorder tasks, it helps to:
- Put foundational tasks first
- Group related tasks together
- Note dependencies in descriptions

### 4. Monitor Progress

- Check the progress display regularly
- Verify acceptance criteria are being met
- Interrupt if something goes wrong

## Troubleshooting

### Task Not Switching

**Problem**: Task stays at 90%+ but doesn't switch

**Solution**:
- Check if acceptance criteria are marked with `[x]`
- Ensure criteria are in the correct format
- Manually verify task completion

### State File Issues

**Problem**: "State file corrupted" error

**Solution**:
```powershell
# Clear state and restart
Remove-Item "$env:TEMP\smart-ralph-multi-task-state.json"
/ralph-smart my-tasks.md
```

### Wrong Task Order

**Problem**: Tasks execute in wrong order

**Solution**:
- AI uses default sequential order (1, 2, 3...)
- Reorder tasks in your file if needed
- Future versions will support explicit dependencies

## Examples

### Example 1: Web Application

```markdown
## Task 1: Setup Project Structure
**Description**: Initialize project with necessary dependencies
**Acceptance Criteria**:
- [ ] Create package.json
- [ ] Install Express, Sequelize, Jest
- [ ] Setup folder structure
- [ ] Create .gitignore

## Task 2: Database Models
**Description**: Define Sequelize models
**Acceptance Criteria**:
- [ ] Create User model
- [ ] Create Post model
- [ ] Add associations
- [ ] Create migrations

## Task 3: API Endpoints
**Description**: Implement REST API
**Acceptance Criteria**:
- [ ] User CRUD endpoints
- [ ] Post CRUD endpoints
- [ ] Authentication middleware
- [ ] Error handling

## Task 4: Testing
**Description**: Write comprehensive tests
**Acceptance Criteria**:
- [ ] API endpoint tests
- [ ] Model tests
- [ ] Integration tests
- [ ] 80%+ coverage
```

### Example 2: Data Processing Pipeline

```markdown
## Task 1: Data Ingestion
**Description**: Read data from CSV files
**Acceptance Criteria**:
- [ ] CSV parser implementation
- [ ] Handle large files (streaming)
- [ ] Error handling for malformed data
- [ ] Progress logging

## Task 2: Data Transformation
**Description**: Clean and transform data
**Acceptance Criteria**:
- [ ] Remove duplicates
- [ ] Normalize date formats
- [ ] Handle missing values
- [ ] Validate data types

## Task 3: Data Storage
**Description**: Store processed data
**Acceptance Criteria**:
- [ ] Database schema creation
- [ ] Batch insert implementation
- [ ] Transaction handling
- [ ] Performance optimization

## Task 4: Reporting
**Description**: Generate summary reports
**Acceptance Criteria**:
- [ ] Calculate statistics
- [ ] Generate CSV reports
- [ ] Create visualizations
- [ ] Email report delivery
```

## Comparison: Single vs Multi-Task

### Single-Task Mode
```bash
/ralph-smart "Implement user authentication"
```
- One task at a time
- Manual switching between tasks
- Good for simple, focused work

### Multi-Task Mode
```bash
/ralph-smart tasks.md
```
- Multiple tasks in sequence
- Automatic task switching
- Progress tracking across all tasks
- Good for complex projects

## FAQ

**Q: Can I modify tasks while Ralph is running?**
A: No, tasks are loaded at startup. Stop and restart to use updated tasks.

**Q: What happens if a task fails?**
A: Ralph will continue trying until max iterations. You can interrupt and fix issues.

**Q: Can I skip a task?**
A: Not currently. All tasks must complete in order.

**Q: How many tasks can I have?**
A: No hard limit, but 3-10 tasks per file is recommended for manageability.

**Q: Can tasks run in parallel?**
A: No, tasks execute sequentially. This ensures dependencies are met.

**Q: Does this work with existing /ralph-smart features?**
A: Yes! Single-task mode still works exactly as before.

## Getting Help

If you encounter issues:
1. Check the state file: `$env:TEMP\smart-ralph-multi-task-state.json`
2. Review the log file: `$env:TEMP\smart-ralph-loop.log`
3. Run tests: `powershell tests\test-multi-task.ps1`
4. Report issues on GitHub

## Next Steps

1. Create your first multi-task file
2. Run `/ralph-smart your-tasks.md`
3. Watch Ralph work through your tasks
4. Enjoy automated task management!

---

**Happy Multi-Tasking! 🚀**
