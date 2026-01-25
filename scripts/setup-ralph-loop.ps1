# Ralph Loop Setup Script (PowerShell version for Windows)
# Creates state file for in-session Ralph loop

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

# Import configuration module
$configModule = Join-Path $PSScriptRoot ".." "lib" "ralph-config.ps1"
if (Test-Path $configModule) {
    Import-Module $configModule -Force
}

# Join all arguments into a single string
$allArgs = $Arguments -join ' '

# Parse arguments manually
$promptParts = @()
$maxIterations = 0
$completionPromise = "null"
$promptFromFile = $false

# Check if first argument is a file path
if ($Arguments.Count -gt 0 -and (Test-IsFilePath -Argument $Arguments[0])) {
    Write-Host "📄 Reading prompt from file: $($Arguments[0])" -ForegroundColor Cyan
    try {
        $prompt = Read-PromptFromFile -FilePath $Arguments[0]
        $promptFromFile = $true
        Write-Host "✅ Loaded prompt ($($prompt.Length) characters)" -ForegroundColor Green
        Write-Host ""
        # Skip first argument since it's the file
        $i = 1
    } catch {
        Write-Error "Failed to read prompt file: $_"
        exit 1
    }
} else {
    $i = 0
}
while ($i -lt $Arguments.Count) {
    $arg = $Arguments[$i]

    switch ($arg) {
        '-h' {
            Write-Host @"
Ralph Loop - Interactive self-referential development loop

USAGE:
  /ralph-loop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: unlimited)
  --completion-promise '<text>'  Promise phrase (USE QUOTES for multi-word)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts a Ralph Wiggum loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  To signal completion, you must output: <promise>YOUR_PHRASE</promise>

EXAMPLES:
  /ralph-loop Build a todo API --completion-promise 'DONE' --max-iterations 20
  /ralph-loop --max-iterations 10 Fix the auth bug
  /ralph-loop Refactor cache layer  (runs forever)

STOPPING:
  Only by reaching --max-iterations or detecting --completion-promise
  No manual stop - Ralph runs infinitely by default!
"@
            exit 0
        }
        '--help' {
            # Same as -h
            $i--
            continue
        }
        '--max-iterations' {
            if ($i + 1 -ge $Arguments.Count) {
                Write-Error "Error: --max-iterations requires a number argument"
                exit 1
            }
            $maxIterations = [int]$Arguments[$i + 1]
            $i += 2
            continue
        }
        '--completion-promise' {
            if ($i + 1 -ge $Arguments.Count) {
                Write-Error "Error: --completion-promise requires a text argument"
                exit 1
            }
            $completionPromise = $Arguments[$i + 1]
            $i += 2
            continue
        }
        default {
            $promptParts += $arg
            $i++
        }
    }
}

# Join prompt parts (if not from file)
if (-not $promptFromFile) {
    $prompt = $promptParts -join ' '
}

if ([string]::IsNullOrWhiteSpace($prompt)) {
    Write-Error "Error: No prompt provided"
    exit 1
}

# Get default max iterations if not specified
if ($maxIterations -le 0) {
    try {
        $maxIterations = Get-DefaultMaxIterations
        Write-Host "ℹ️  Using default max iterations: $maxIterations" -ForegroundColor Gray
        Write-Host "   (Set with /ralph-smart-setmaxiterations <n>)" -ForegroundColor Gray
        Write-Host ""
    } catch {
        # Fallback to 15 if config fails
        $maxIterations = 15
        Write-Warning "Failed to read config, using fallback: $maxIterations iterations"
    }
}

# Create .claude directory if it doesn't exist
$claudeDir = Join-Path $PWD ".claude"
if (!(Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir | Out-Null
}

# Create state file
$stateFile = Join-Path $claudeDir "ralph-loop.local.md"
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$completionPromiseYaml = if ($completionPromise -ne "null") { "`"$completionPromise`"" } else { "null" }

$content = @"
---
active: true
iteration: 1
max_iterations: $maxIterations
completion_promise: $completionPromiseYaml
started_at: "$timestamp"
---

$prompt
"@

Set-Content -Path $stateFile -Value $content -Encoding UTF8

# Output setup message
Write-Host "🔄 Ralph loop activated in this session!"
Write-Host ""
Write-Host "Iteration: 1"
Write-Host "Max iterations: $(if ($maxIterations -gt 0) { $maxIterations } else { 'unlimited' })"
Write-Host "Completion promise: $(if ($completionPromise -ne 'null') { "$completionPromise (ONLY output when TRUE - do not lie!)" } else { 'none (runs forever)' })"
Write-Host ""
Write-Host "The stop hook is now active. When you try to exit, the SAME PROMPT will be"
Write-Host "fed back to you. You'll see your previous work in files, creating a"
Write-Host "self-referential loop where you iteratively improve on the same task."
Write-Host ""
Write-Host "To monitor: head -10 .claude/ralph-loop.local.md"
Write-Host ""
Write-Host "⚠️  WARNING: This loop cannot be stopped manually! It will run infinitely"
Write-Host "    unless you set --max-iterations or --completion-promise."
Write-Host ""
Write-Host "🔄"
Write-Host ""
Write-Host $prompt

if ($completionPromise -ne "null") {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════"
    Write-Host "CRITICAL - Ralph Loop Completion Promise"
    Write-Host "═══════════════════════════════════════════════════════════"
    Write-Host ""
    Write-Host "To complete this loop, output this EXACT text:"
    Write-Host "  <promise>$completionPromise</promise>"
    Write-Host ""
    Write-Host "STRICT REQUIREMENTS (DO NOT VIOLATE):"
    Write-Host "  ✓ Use <promise> XML tags EXACTLY as shown above"
    Write-Host "  ✓ The statement MUST be completely and unequivocally TRUE"
    Write-Host "  ✓ Do NOT output false statements to exit the loop"
    Write-Host "  ✓ Do NOT lie even if you think you should exit"
    Write-Host ""
    Write-Host "IMPORTANT - Do not circumvent the loop:"
    Write-Host "  Even if you believe you're stuck, the task is impossible,"
    Write-Host "  or you've been running too long - you MUST NOT output a"
    Write-Host "  false promise statement. The loop is designed to continue"
    Write-Host "  until the promise is GENUINELY TRUE. Trust the process."
    Write-Host ""
    Write-Host "  If the loop should stop, the promise statement will become"
    Write-Host "  true naturally. Do not force it by lying."
    Write-Host "═══════════════════════════════════════════════════════════"
}
