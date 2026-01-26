---
description: "Start Smart Ralph Loop with intelligent completion detection (Improved)"
argument-hint: "PROMPT [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(pwsh:*)"]
hide-from-slash-command-tool: "false"
---

# Smart Ralph Loop Command (Improved Version)

Start an intelligent Ralph loop that automatically detects task completion with enhanced error handling.

**Usage:**
```
/ralph-smart-improved "Your task description" --max-iterations 15 --completion-promise "All done"
```

**Features:**
- Autonomous iteration with progress tracking
- Intelligent completion detection
- Graceful interruption handling (Ctrl+C)
- Task progress monitoring
- State persistence
- **Enhanced error handling and validation**
- **Thread-safe state management**
- **Robust edge case handling**

**The loop will automatically stop when:**
- Task completion is detected
- All todos are marked complete
- Completion promise text is found
- Max iterations reached
- User interrupts (Ctrl+C)

Execute the Smart Ralph Loop with argument parsing:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -Command "
    # Parse arguments
    \$argsString = '${ARGS}'
    \$prompt = ''
    \$maxIterations = 10
    \$completionPromise = ''

    # Extract --max-iterations
    if (\$argsString -match '--max-iterations\s+(\d+)') {
        \$maxIterations = [int]\$matches[1]
        \$argsString = \$argsString -replace '--max-iterations\s+\d+', ''
    }

    # Extract --completion-promise
    if (\$argsString -match '--completion-promise\s+[\"'']([^\"'']+)[\"'']') {
        \$completionPromise = \$matches[1]
        \$argsString = \$argsString -replace '--completion-promise\s+[\"''][^\"'']+[\"'']', ''
    } elseif (\$argsString -match '--completion-promise\s+(\S+)') {
        \$completionPromise = \$matches[1]
        \$argsString = \$argsString -replace '--completion-promise\s+\S+', ''
    }

    # Remaining text is the prompt
    \$prompt = \$argsString.Trim()

    # Validate prompt
    if ([string]::IsNullOrWhiteSpace(\$prompt)) {
        Write-Error 'Prompt cannot be empty. Usage: /ralph-smart-improved \"Your task\" --max-iterations 15'
        exit 1
    }

    # Import module and start loop
    Import-Module '${CLAUDE_PLUGIN_ROOT}/lib/smart-ralph-loop-improved.ps1' -Force
    Start-SmartRalphLoop -Prompt \$prompt -MaxIterations \$maxIterations -CompletionPromise \$completionPromise
"
```

Please work on the task. The Smart Ralph Loop will monitor your progress and automatically complete when done.

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop.
