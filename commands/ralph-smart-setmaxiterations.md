---
description: "Set default max iterations for Ralph loops"
argument-hint: "MAX_ITERATIONS"
allowed-tools: ["Bash(pwsh:*)"]
hide-from-slash-command-tool: "false"
---

# Set Default Max Iterations

Configure the default maximum iterations for `/ralph-smart` command.

**Usage:**
```
/ralph-smart-setmaxiterations <number>
```

**Examples:**
```
/ralph-smart-setmaxiterations 10
/ralph-smart-setmaxiterations 20
/ralph-smart-setmaxiterations 30
```

**What this does:**
- Sets the default max iterations for `/ralph-smart` command
- Default value after installation: 10 iterations
- Recommended range: 10-30 iterations
- Stored in: `~/.claude/ralph-config.json`

**Note**: This setting only affects `/ralph-smart`. The `/ralph-loop` command requires explicit `--max-iterations` parameter.

Execute the configuration:

```
pwsh -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '${CLAUDE_PLUGIN_ROOT}/lib/ralph-config.ps1' -Force; Set-DefaultMaxIterations -MaxIterations ${ARGS}"
```

The default max iterations has been updated. All future `/ralph-smart` commands will use this value.
