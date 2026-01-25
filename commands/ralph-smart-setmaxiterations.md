---
description: "Set default max iterations for Ralph loops"
argument-hint: "MAX_ITERATIONS"
allowed-tools: ["Bash(pwsh:*)"]
hide-from-slash-command-tool: "false"
---

# Set Default Max Iterations

Configure the default maximum iterations for all Ralph loop commands.

**Usage:**
```
/ralph-smart-setmaxiterations <number>
```

**Examples:**
```
/ralph-smart-setmaxiterations 20
/ralph-smart-setmaxiterations 30
```

**What this does:**
- Sets the default max iterations for `/ralph-loop` and `/ralph-smart`
- This value is used when you don't specify `--max-iterations` parameter
- Recommended range: 15-30 iterations
- Stored in: `~/.claude/ralph-config.json`

Execute the configuration:

```
pwsh -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '${CLAUDE_PLUGIN_ROOT}/lib/ralph-config.ps1' -Force; Set-DefaultMaxIterations -MaxIterations ${ARGS}"
```

The default max iterations has been updated. All future `/ralph-loop` and `/ralph-smart` commands will use this value unless you explicitly specify `--max-iterations`.
