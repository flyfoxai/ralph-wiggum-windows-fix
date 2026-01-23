# Smart Ralph Loop

## Overview

The Smart Ralph Loop is an autonomous task execution system that enables Claude to work iteratively on complex tasks with intelligent progress tracking and automatic completion detection.

## Features

- **Autonomous Iteration**: Automatically continues working until task completion
- **Intelligent Completion Detection**: Multiple criteria for detecting when work is done
- **Progress Tracking**: Monitors todo lists and calculates completion percentage
- **Graceful Interruption**: Ctrl+C saves state and stops cleanly
- **State Persistence**: Maintains state across interruptions
- **Flexible Configuration**: Customize iterations and completion criteria

## Quick Start

```bash
/ralph-smart "Your task description" --max-iterations 15
```

## Architecture

### Components

1. **State Management** (`Initialize-RalphState`, `Update-RalphState`, `Get-RalphState`, `Clear-RalphState`)
   - Stores loop state in JSON format
   - Tracks prompt, iterations, status, timestamps
   - Persists to `$env:TEMP\smart-ralph-state.json`

2. **Task Parser** (`Parse-TaskProgress`)
   - Parses todo lists from Claude output
   - Supports multiple checkbox formats (☒☐●✓✗×)
   - Calculates completion percentage

3. **Completion Detection** (`Test-CompletionCriteria`)
   - Explicit completion signals
   - Completion promise matching
   - 100% task completion
   - Blocking error detection

4. **Main Loop** (`Start-SmartRalphLoop`)
   - Iterates until completion or max iterations
   - Displays progress information
   - Handles interruptions gracefully

5. **Interruption Handling** (`Test-InterruptionRequested`)
   - Ctrl+C handler via PowerShell events
   - State preservation on interruption
   - Integration with stop-hook

## Usage

### Basic Command

```bash
/ralph-smart "Fix all TypeScript errors"
```

### With Options

```bash
/ralph-smart "Implement dark mode" --max-iterations 20 --completion-promise "All tests passing"
```

### Parameters

- `PROMPT` (required): The task description
- `--max-iterations` (optional): Maximum iterations (default: 10)
- `--completion-promise` (optional): Text that signals completion

## Completion Criteria

The loop stops when ANY of these conditions are met:

1. **Explicit Completion Signal**: Output contains phrases like:
   - "task completed"
   - "all done"
   - "finished successfully"
   - "implementation complete"

2. **Completion Promise**: Output contains the user-specified completion text

3. **All Tasks Complete**: 100% of todos are marked as completed

4. **Max Iterations**: Iteration limit reached

5. **Blocking Error**: Fatal error detected in output

6. **User Interruption**: Ctrl+C pressed

## State Management

State is stored in `$env:TEMP\smart-ralph-state.json`:

```json
{
  "prompt": "Task description",
  "maxIterations": 10,
  "completionPromise": "Done",
  "currentIteration": 3,
  "startTime": "2026-01-24T10:00:00",
  "status": "running",
  "endTime": null
}
```

### Status Values

- `running`: Loop is active
- `completed`: Task completed successfully
- `interrupted`: User interrupted with Ctrl+C
- `error`: Blocking error detected
- `max_iterations`: Iteration limit reached

## Programmatic Usage

```powershell
# Import the module
Import-Module .\lib\smart-ralph-loop.ps1 -Force

# Start a loop
$result = Start-SmartRalphLoop -Prompt "Test task" -MaxIterations 10

# Check result
Write-Host "Status: $($result.status)"
Write-Host "Iterations: $($result.iterations)"
Write-Host "Reason: $($result.reason)"

# Get current state
$state = Get-RalphState

# Clear state
Clear-RalphState
```

## Best Practices

1. **Clear Prompts**: Provide specific, actionable task descriptions
2. **Reasonable Limits**: Set max-iterations based on task complexity
3. **Specific Completion Promises**: Use unique, specific phrases
4. **Monitor Progress**: Watch the progress output
5. **Safe Interruption**: Use Ctrl+C, don't force-kill

## Troubleshooting

### Loop Doesn't Stop

- Check completion promise matches output exactly
- Verify tasks are being marked as completed
- Increase max-iterations if needed

### State File Issues

```powershell
# Check state
$stateFile = Join-Path $env:TEMP "smart-ralph-state.json"
Get-Content $stateFile | ConvertFrom-Json

# Delete if corrupted
Remove-Item $stateFile -Force
```

### Interruption Not Working

- Ensure using PowerShell 7+ (`pwsh`)
- Check stop-hook is properly configured
- Verify no other signal handlers interfering

## Technical Details

### Task Parsing

Supports these todo formats:
- `☒ Task` - Completed
- `☐ Task` - Pending
- `● Task` - In progress
- `✓ Task` - Completed
- `✗ Task` - Pending
- `× Task` - Completed

### Completion Detection Logic

```
shouldComplete = (hasCompletionSignal OR meetsPromise OR allTasksComplete)
                 AND NOT hasBlockingError
```

### Interruption Handling

Uses PowerShell event system:
```powershell
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $InterruptHandler
```

## Integration

### With Stop-Hook

The stop-hook automatically detects Smart Ralph Loop state and marks it as interrupted on session exit.

### With Commands

The `/ralph-smart` command provides a user-friendly interface to the loop engine.

## Examples

See `examples/smart-ralph-examples.md` for comprehensive examples including:
- Basic usage
- Complex tasks
- Monitoring progress
- Interruption handling
- Troubleshooting
- Use case examples

## Requirements

- PowerShell 7+ (`pwsh`)
- Windows, macOS, or Linux
- Claude Code plugin system

## Files

- `lib/smart-ralph-loop.ps1` - Main loop engine
- `commands/ralph-smart.md` - Command definition
- `examples/smart-ralph-examples.md` - Usage examples
- `hooks/stop-hook.ps1` - Interruption handling
- `docs/smart-ralph-loop.md` - This documentation

## License

Part of the Ralph Wiggum plugin for Claude Code.
