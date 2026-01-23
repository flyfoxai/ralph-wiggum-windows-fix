# Smart Ralph Loop Examples

## Basic Usage

Start a Smart Ralph Loop with a simple task:

```bash
/ralph-smart "Fix all TypeScript errors in the project"
```

The loop will:
- Start working on the task
- Track progress automatically
- Stop when completion is detected

## With Custom Max Iterations

Set a higher iteration limit for complex tasks:

```bash
/ralph-smart "Implement dark mode" --max-iterations 20
```

## With Completion Promise

Specify exact text that signals completion:

```bash
/ralph-smart "Add user authentication" --completion-promise "All tests passing"
```

The loop will stop when it detects "All tests passing" in the output.

## Complex Task Example

```bash
/ralph-smart "Refactor the API layer to use async/await" --max-iterations 25 --completion-promise "Refactoring complete and tested"
```

## Monitoring Progress

The loop displays:
- Current iteration number (e.g., "Iteration 3/10")
- Task progress (e.g., "Progress: 2/5 tasks (40%)")
- Completion percentage
- Reason for stopping

Example output:
```
🔄 Starting Smart Ralph Loop
Prompt: Implement user authentication
Max Iterations: 15

--- Iteration 1/15 ---
Response received (1234 chars)
Progress: 0/3 tasks (0%)

--- Iteration 2/15 ---
Response received (2345 chars)
Progress: 1/3 tasks (33.33%)

--- Iteration 3/15 ---
Response received (3456 chars)
Progress: 3/3 tasks (100%)
✅ Loop completed: all tasks completed
```

## Interrupting the Loop

Press `Ctrl+C` to gracefully stop the loop:

```
--- Iteration 5/15 ---
^C
⏸️  Interruption detected, saving state...
⏸️  Loop interrupted by user
```

The state is saved and can be inspected:

```powershell
# Check the state
$state = Get-Content $env:TEMP\smart-ralph-state.json | ConvertFrom-Json
$state.status  # "interrupted"
$state.currentIteration  # 5
```

## Completion Detection

The loop automatically detects completion through:

### 1. Explicit Completion Signals

These phrases trigger completion:
- "task completed"
- "all done"
- "finished successfully"
- "implementation complete"
- "work is complete"
- "completed successfully"

### 2. Completion Promise

User-specified text that signals completion:

```bash
/ralph-smart "Deploy to production" --completion-promise "Deployment successful"
```

### 3. Task Completion

When all todos are marked as completed (100% progress):

```
Todos
☒ Task 1: Setup
☒ Task 2: Implementation
☒ Task 3: Testing
```

### 4. Blocking Errors

The loop stops if it detects blocking errors:
- "fatal error"
- "cannot proceed"
- "blocked"
- "failed to"

## Best Practices

### 1. Clear Prompts

Provide specific, actionable task descriptions:

✅ Good:
```bash
/ralph-smart "Add input validation to the user registration form with email and password checks"
```

❌ Bad:
```bash
/ralph-smart "Make it better"
```

### 2. Reasonable Iteration Limits

Set limits based on task complexity:
- Simple tasks: 5-10 iterations
- Medium tasks: 10-20 iterations
- Complex tasks: 20-30 iterations

### 3. Specific Completion Promises

Use unique, specific phrases:

✅ Good:
```bash
--completion-promise "All 15 unit tests passing with 100% coverage"
```

❌ Bad:
```bash
--completion-promise "done"
```

### 4. Monitor Progress

Watch the progress output to understand:
- How many tasks are being tracked
- Current completion percentage
- Whether the loop is making progress

### 5. Use Interruption Safely

If you need to stop:
- Press `Ctrl+C` once
- Wait for the "Interruption detected" message
- Don't force-kill the process

## Troubleshooting

### Loop Doesn't Stop

**Problem:** Loop continues even though task seems done.

**Solutions:**
- Ensure completion promise matches output exactly
- Verify tasks are being marked as completed (☒)
- Check if blocking errors are preventing completion
- Increase max-iterations if needed

### State File Issues

**Problem:** State file corrupted or not found.

**Solutions:**
```powershell
# Check state file location
$stateFile = Join-Path $env:TEMP "smart-ralph-state.json"
Test-Path $stateFile

# View state
Get-Content $stateFile | ConvertFrom-Json

# Manually delete if corrupted
Remove-Item $stateFile -Force
```

### Interruption Not Working

**Problem:** Ctrl+C doesn't stop the loop.

**Solutions:**
- Ensure using PowerShell 7+ (`pwsh`)
- Check stop-hook is properly configured
- Verify no other signal handlers are interfering

## Advanced Usage

### Checking State Programmatically

```powershell
# Import the module
Import-Module .\lib\smart-ralph-loop.ps1 -Force

# Get current state
$state = Get-RalphState

# Check status
if ($state.status -eq "running") {
    Write-Host "Loop is running"
    Write-Host "Iteration: $($state.currentIteration)/$($state.maxIterations)"
}

# Clear state
Clear-RalphState
```

### Custom Completion Detection

The loop detects completion through multiple criteria. You can combine them:

```bash
/ralph-smart "Implement feature X" --max-iterations 20 --completion-promise "Feature X complete"
```

This will stop when:
- "Feature X complete" appears in output, OR
- All tasks are 100% complete, OR
- Any standard completion signal is detected

## Examples by Use Case

### Bug Fixing

```bash
/ralph-smart "Fix the authentication bug where users can't log in with special characters in password" --max-iterations 10 --completion-promise "Bug fixed and tested"
```

### Feature Implementation

```bash
/ralph-smart "Add dark mode toggle to settings page with persistence" --max-iterations 15 --completion-promise "Dark mode fully implemented"
```

### Refactoring

```bash
/ralph-smart "Refactor UserService to use dependency injection" --max-iterations 12 --completion-promise "Refactoring complete with all tests passing"
```

### Testing

```bash
/ralph-smart "Write comprehensive unit tests for PaymentProcessor class" --max-iterations 8 --completion-promise "All tests written and passing"
```

### Documentation

```bash
/ralph-smart "Add JSDoc comments to all public API functions" --max-iterations 10 --completion-promise "Documentation complete"
```
