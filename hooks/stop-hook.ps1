# Ralph Wiggum Stop Hook (PowerShell version for Windows)
# Prevents session exit when a ralph-loop is active
# Feeds Claude's output back as input to continue the loop

$ErrorActionPreference = "Stop"

# Read hook input from stdin (advanced stop hook API)
$hookInput = [Console]::In.ReadToEnd()

# Import task queue manager for multi-task support
$taskQueueManagerPath = Join-Path $PSScriptRoot "..\lib\task-queue-manager.ps1"
if (Test-Path $taskQueueManagerPath) {
    Import-Module $taskQueueManagerPath -Force -ErrorAction SilentlyContinue
}

# Check for Multi-Task Ralph Loop state file
$multiTaskStateFile = Join-Path $env:TEMP "smart-ralph-multi-task-state.json"
$isMultiTaskMode = Test-Path $multiTaskStateFile

# Check for Smart Ralph Loop state file
$smartRalphStateFile = Join-Path $env:TEMP "smart-ralph-state.json"
if (Test-Path $smartRalphStateFile) {
    try {
        $smartState = Get-Content $smartRalphStateFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($smartState.status -eq "running") {
            Write-Host "⏸️  Smart Ralph Loop detected - marking as interrupted"
            $smartState.status = "interrupted"
            $smartState.endTime = (Get-Date).ToString("o")
            $smartState | ConvertTo-Json -Depth 10 | Set-Content $smartRalphStateFile -Encoding UTF8
        }
    } catch {
        # Ignore errors in Smart Ralph state handling
    }
}

# Check if ralph-loop is active
$ralphStateFile = ".claude/ralph-loop.local.md"

if (-not (Test-Path $ralphStateFile)) {
    # No active loop - allow exit
    exit 0
}

# Read the state file
$stateContent = Get-Content $ralphStateFile -Raw -Encoding UTF8

# Parse markdown frontmatter (YAML between ---) and extract values
$frontmatterMatch = [regex]::Match($stateContent, '(?s)^---\r?\n(.*?)\r?\n---')
if (-not $frontmatterMatch.Success) {
    Write-Error "⚠️  Ralph loop: State file corrupted - no frontmatter found"
    Remove-Item $ralphStateFile -Force
    exit 0
}

$frontmatter = $frontmatterMatch.Groups[1].Value

# Extract iteration
$iterationMatch = [regex]::Match($frontmatter, 'iteration:\s*(\d+)')
if (-not $iterationMatch.Success) {
    Write-Error "⚠️  Ralph loop: State file corrupted - iteration field missing or invalid"
    Remove-Item $ralphStateFile -Force
    exit 0
}
$iteration = [int]$iterationMatch.Groups[1].Value

# Extract max_iterations
$maxIterationsMatch = [regex]::Match($frontmatter, 'max_iterations:\s*(\d+)')
if (-not $maxIterationsMatch.Success) {
    Write-Error "⚠️  Ralph loop: State file corrupted - max_iterations field missing or invalid"
    Remove-Item $ralphStateFile -Force
    exit 0
}
$maxIterations = [int]$maxIterationsMatch.Groups[1].Value

# Extract completion_promise and strip surrounding quotes if present
$completionPromiseMatch = [regex]::Match($frontmatter, 'completion_promise:\s*"?([^"\r\n]*)"?')
$completionPromise = if ($completionPromiseMatch.Success) {
    $completionPromiseMatch.Groups[1].Value
} else {
    $null
}

# Check if max iterations reached
if ($maxIterations -gt 0 -and $iteration -ge $maxIterations) {
    Write-Host "🛑 Ralph loop: Max iterations ($maxIterations) reached."
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Get transcript path from hook input
try {
    $hookData = $hookInput | ConvertFrom-Json
    $transcriptPath = $hookData.transcript_path
} catch {
    Write-Error "⚠️  Ralph loop: Failed to parse hook input JSON"
    Remove-Item $ralphStateFile -Force
    exit 0
}

if (-not (Test-Path $transcriptPath)) {
    Write-Error "⚠️  Ralph loop: Transcript file not found: $transcriptPath"
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Read last assistant message from transcript (JSONL format - one JSON per line)
$transcriptLines = Get-Content $transcriptPath -Encoding UTF8
$assistantLines = @($transcriptLines | Where-Object { $_ -match '"role"\s*:\s*"assistant"' })

if ($assistantLines.Count -eq 0) {
    Write-Error "⚠️  Ralph loop: No assistant messages found in transcript"
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Get the last assistant message
$lastLine = $assistantLines[$assistantLines.Count - 1]

try {
    $lastMessage = $lastLine | ConvertFrom-Json
    $textContents = $lastMessage.message.content | Where-Object { $_.type -eq "text" }
    $lastOutput = ($textContents | ForEach-Object { $_.text }) -join "`n"
} catch {
    Write-Error "⚠️  Ralph loop: Failed to parse assistant message JSON: $($_.Exception.Message)"
    Remove-Item $ralphStateFile -Force
    exit 0
}

if ([string]::IsNullOrWhiteSpace($lastOutput)) {
    Write-Error "⚠️  Ralph loop: Assistant message contained no text content"
    Remove-Item $ralphStateFile -Force
    exit 0
}

# ============================================
# MULTI-TASK MODE HANDLING
# ============================================
if ($isMultiTaskMode) {
    try {
        # Load multi-task state
        $multiStateJson = Get-Content $multiTaskStateFile -Raw -Encoding UTF8
        $multiStateObj = $multiStateJson | ConvertFrom-Json

        # Convert to hashtable for easier manipulation
        $multiState = @{}
        $multiStateObj.PSObject.Properties | ForEach-Object {
            $multiState[$_.Name] = $_.Value
        }

        # Get current task
        $currentTaskIndex = $multiState.currentTaskIndex
        $currentTask = $multiState.tasks[$currentTaskIndex]

        # Increment total iterations
        $multiState.totalIterations++
        $multiState.tasks[$currentTaskIndex].iterations++

        # Parse task progress from output (check for completion criteria)
        $criteriaPattern = '-\s+\[(x| )\]\s+(.+?)(?:\r?\n|$)'
        $criteriaMatches = [regex]::Matches($lastOutput, $criteriaPattern)

        $completedCriteria = 0
        $totalCriteria = $currentTask.acceptance_criteria.Count

        if ($criteriaMatches.Count -gt 0) {
            foreach ($match in $criteriaMatches) {
                $isChecked = $match.Groups[1].Value -eq 'x'
                if ($isChecked) {
                    $completedCriteria++
                }
            }
            $totalCriteria = [math]::Max($totalCriteria, $criteriaMatches.Count)
        }

        # Calculate completion percentage
        $completionPercent = if ($totalCriteria -gt 0) {
            [math]::Round(($completedCriteria / $totalCriteria) * 100)
        } else {
            0
        }

        # Update task progress
        $multiState.tasks[$currentTaskIndex].completion = $completionPercent

        # Check if current task is complete (>= 90%)
        if ($completionPercent -ge 90) {
            Write-Host "✅ Task $($currentTask.id) completed: $($currentTask.title) ($completionPercent%)" -ForegroundColor Green

            # Mark task as completed
            $multiState.tasks[$currentTaskIndex].status = "completed"
            $multiState.tasks[$currentTaskIndex].completion = 100
            $multiState.tasks[$currentTaskIndex].endTime = (Get-Date).ToString("o")

            # Move to next task
            $multiState.currentTaskIndex++

            # Check if there are more tasks
            if ($multiState.currentTaskIndex -lt $multiState.tasks.Count) {
                # Start next task
                $nextTask = $multiState.tasks[$multiState.currentTaskIndex]
                $nextTask.status = "in_progress"
                $nextTask.startTime = (Get-Date).ToString("o")

                # Save updated state
                $multiState | ConvertTo-Json -Depth 10 | Set-Content $multiTaskStateFile -Encoding UTF8

                # Build prompt for next task
                $taskPrompt = @"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 开始任务 $($nextTask.id): $($nextTask.title)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**描述**: $($nextTask.description)

**验收标准**:
$($nextTask.acceptance_criteria | ForEach-Object { "- [ ] $($_.text)" } | Out-String)

请开始实现此任务。完成后，请确保所有验收标准都已满足。
"@

                # Update iteration in frontmatter
                $nextIteration = $iteration + 1
                $newContent = $stateContent -replace 'iteration:\s*\d+', "iteration: $nextIteration"
                Set-Content -Path $ralphStateFile -Value $newContent -Encoding UTF8 -NoNewline

                # Build system message
                $systemMsg = "🔄 Ralph iteration $nextIteration | Multi-Task: $($multiState.currentTaskIndex + 1)/$($multiState.tasks.Count) | Task $($nextTask.id): $($nextTask.title)"

                # Output JSON to block exit and feed next task prompt
                $response = @{
                    decision = "block"
                    reason = $taskPrompt
                    systemMessage = $systemMsg
                } | ConvertTo-Json -Compress

                Write-Output $response
                exit 0
            } else {
                # All tasks completed!
                Write-Host "🎉 All tasks completed!" -ForegroundColor Green

                # Clean up state files
                Remove-Item $multiTaskStateFile -Force -ErrorAction SilentlyContinue
                Remove-Item $ralphStateFile -Force -ErrorAction SilentlyContinue

                # Allow exit
                exit 0
            }
        } else {
            # Task not complete - continue current task
            Write-Host "⏳ Task $($currentTask.id) in progress: $completionPercent% complete" -ForegroundColor Yellow

            # Save updated state
            $multiState | ConvertTo-Json -Depth 10 | Set-Content $multiTaskStateFile -Encoding UTF8

            # Continue with current task prompt
            $continuePrompt = @"
继续任务 $($currentTask.id): $($currentTask.title)

当前进度: $completionPercent% ($completedCriteria/$totalCriteria 验收标准完成)

请继续完成剩余的验收标准。
"@

            # Update iteration
            $nextIteration = $iteration + 1
            $newContent = $stateContent -replace 'iteration:\s*\d+', "iteration: $nextIteration"
            Set-Content -Path $ralphStateFile -Value $newContent -Encoding UTF8 -NoNewline

            # Build system message
            $systemMsg = "🔄 Ralph iteration $nextIteration | Multi-Task: $($currentTaskIndex + 1)/$($multiState.tasks.Count) | Task $($currentTask.id): $completionPercent%"

            # Output JSON to block exit
            $response = @{
                decision = "block"
                reason = $continuePrompt
                systemMessage = $systemMsg
            } | ConvertTo-Json -Compress

            Write-Output $response
            exit 0
        }
    } catch {
        Write-Warning "⚠️  Multi-task mode error: $_. Falling back to single-task mode."
        # Fall through to single-task mode
    }
}

# ============================================
# SINGLE-TASK MODE HANDLING (Original Logic)
# ============================================

# Check for completion promise (only if set)
if ($completionPromise -and $completionPromise -ne "null" -and $completionPromise.Length -gt 0) {
    # Extract text from <promise> tags
    $promiseMatch = [regex]::Match($lastOutput, '<promise>(.*?)</promise>', [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($promiseMatch.Success) {
        $promiseText = $promiseMatch.Groups[1].Value.Trim()

        # Use exact string comparison
        if ($promiseText -eq $completionPromise) {
            Write-Host "✅ Ralph loop: Detected <promise>$completionPromise</promise>"
            Remove-Item $ralphStateFile -Force
            exit 0
        }
    }
}

# Not complete - continue loop with SAME PROMPT
$nextIteration = $iteration + 1

# Extract prompt (everything after the closing ---)
$promptMatch = [regex]::Match($stateContent, '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$')
if (-not $promptMatch.Success) {
    Write-Error "⚠️  Ralph loop: State file corrupted - no prompt text found"
    Remove-Item $ralphStateFile -Force
    exit 0
}

$promptText = $promptMatch.Groups[1].Value.Trim()

if ([string]::IsNullOrWhiteSpace($promptText)) {
    Write-Error "⚠️  Ralph loop: State file corrupted - prompt text is empty"
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Update iteration in frontmatter
$newContent = $stateContent -replace 'iteration:\s*\d+', "iteration: $nextIteration"
Set-Content -Path $ralphStateFile -Value $newContent -Encoding UTF8 -NoNewline

# Build system message with iteration count and completion promise info
if ($completionPromise -and $completionPromise -ne "null" -and $completionPromise.Length -gt 0) {
    $systemMsg = "🔄 Ralph iteration $nextIteration | To stop: output <promise>$completionPromise</promise> (ONLY when statement is TRUE - do not lie to exit!)"
} else {
    $systemMsg = "🔄 Ralph iteration $nextIteration | No completion promise set - loop runs infinitely"
}

# Output JSON to block the stop and feed prompt back
# The "reason" field contains the prompt that will be sent back to Claude
$response = @{
    decision = "block"
    reason = $promptText
    systemMessage = $systemMsg
} | ConvertTo-Json -Compress

Write-Output $response

# Exit 0 for successful hook execution
exit 0
