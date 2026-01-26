---
description: "Start Smart Ralph Loop with intelligent completion detection"
argument-hint: "PROMPT|FILE"
allowed-tools: ["Bash(pwsh:*)"]
hide-from-slash-command-tool: "false"
---

# Smart Ralph Loop Command

Start an intelligent Ralph loop that automatically detects task completion.

**Usage:**
```
/ralph-smart "Your task description"
/ralph-smart path/to/prompt.txt
/ralph-smart tasks.md
```

**Arguments:**
- `PROMPT` - Task description as a string
- `FILE` - Path to a text file containing the task description or multiple tasks

**Features:**
- Autonomous iteration with progress tracking
- Intelligent completion detection
- Graceful interruption handling (Ctrl+C)
- Task progress monitoring
- State persistence
- Read prompts from files
- Multi-task support (NEW in v1.30)
- Uses default max iterations from config (default: 10)

**The loop will automatically stop when:**
- Task completion is detected
- All todos are marked complete
- Max iterations reached (configured via `/ralph-smart-setmaxiterations`)
- User interrupts (Ctrl+C)

**Setting Default Max Iterations:**
```
/ralph-smart-setmaxiterations 10
/ralph-smart-setmaxiterations 20
```

**Note**: `/ralph-smart` does not accept `--max-iterations` parameter. Use `/ralph-smart-setmaxiterations` to configure the default value.

Execute the Smart Ralph Loop:

```
pwsh -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '${CLAUDE_PLUGIN_ROOT}/lib/smart-ralph-loop.ps1' -Force; Start-SmartRalphLoop -Prompt '${ARGS}'"
```

Please work on the task. The Smart Ralph Loop will monitor your progress and automatically complete when done.
