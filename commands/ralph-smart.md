---
description: "Start Smart Ralph Loop with intelligent completion detection"
argument-hint: "PROMPT|FILE [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(pwsh:*)"]
hide-from-slash-command-tool: "false"
---

# Smart Ralph Loop Command

Start an intelligent Ralph loop that automatically detects task completion.

**Usage:**
```
/ralph-smart "Your task description"
/ralph-smart path/to/prompt.txt
/ralph-smart "Your task" --max-iterations 20
/ralph-smart prompt.md --completion-promise "All done"
```

**Arguments:**
- `PROMPT` - Task description as a string
- `FILE` - Path to a text file containing the task description

**Options:**
- `--max-iterations <n>` - Maximum iterations (optional, uses default if not specified)
- `--completion-promise <text>` - Phrase that signals completion

**Features:**
- Autonomous iteration with progress tracking
- Intelligent completion detection
- Graceful interruption handling (Ctrl+C)
- Task progress monitoring
- State persistence
- Read prompts from files
- Uses default max iterations from config

**The loop will automatically stop when:**
- Task completion is detected
- All todos are marked complete
- Completion promise text is found
- Max iterations reached
- User interrupts (Ctrl+C)

**Setting Default Max Iterations:**
```
/ralph-smart-setmaxiterations 20
```

Execute the Smart Ralph Loop:

```
pwsh -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '${CLAUDE_PLUGIN_ROOT}/lib/smart-ralph-loop.ps1' -Force; Start-SmartRalphLoop -Prompt '${ARGS}'"
```

Please work on the task. The Smart Ralph Loop will monitor your progress and automatically complete when done.

CRITICAL RULE: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE. Do not output false promises to escape the loop.
