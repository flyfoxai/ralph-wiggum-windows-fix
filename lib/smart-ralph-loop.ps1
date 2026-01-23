# Smart Ralph Loop Engine
# Manages autonomous iteration with progress tracking and state management

param(
    [Parameter(Mandatory=$false)]
    [string]$Prompt,

    [Parameter(Mandatory=$false)]
    [int]$MaxIterations = 10,

    [Parameter(Mandatory=$false)]
    [string]$CompletionPromise = ""
)

$ErrorActionPreference = "Stop"

# State file location
$script:StateFile = Join-Path $env:TEMP "smart-ralph-state.json"
$script:IsRunning = $true

# Interruption handler
$script:InterruptHandler = {
    Write-Host "`n⏸️  Interruption detected, saving state..." -ForegroundColor Yellow
    $script:IsRunning = $false
}

# Register Ctrl+C handler
try {
    [Console]::TreatControlCAsInput = $false
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $script:InterruptHandler -ErrorAction SilentlyContinue
} catch {
    # Silently ignore if already registered
}

# Test if interruption was requested
function Test-InterruptionRequested {
    return -not $script:IsRunning
}

# Show progress bar
function Show-ProgressBar {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Percent
    )

    $barLength = 40
    $filled = [math]::Floor($barLength * $Percent / 100)
    $empty = $barLength - $filled

    $bar = "[" + ("=" * $filled) + ("." * $empty) + "]"
    Write-Host "$bar $Percent%" -ForegroundColor Cyan
}

# Write log message
function Write-RalphLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    $logFile = Join-Path $env:TEMP "smart-ralph-loop.log"
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8

    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "Gray" }
    }

    if ($Level -ne "INFO") {
        Write-Host $logMessage -ForegroundColor $color
    }
}

# Initialize Ralph Loop state
function Initialize-RalphState {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 10,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = ""
    )

    $state = @{
        prompt = $Prompt
        maxIterations = $MaxIterations
        completionPromise = $CompletionPromise
        currentIteration = 0
        startTime = (Get-Date).ToString("o")
        status = "running"
        endTime = $null
    }

    $state | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8

    return $state
}

# Update Ralph Loop state
function Update-RalphState {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Updates
    )

    if (-not (Test-Path $StateFile)) {
        Write-Error "State file not found: $StateFile"
        return $null
    }

    $state = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable

    foreach ($key in $Updates.Keys) {
        $state[$key] = $Updates[$key]
    }

    $state | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8

    return $state
}

# Get Ralph Loop state
function Get-RalphState {
    if (-not (Test-Path $StateFile)) {
        return $null
    }

    $state = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    return $state
}

# Clear Ralph Loop state
function Clear-RalphState {
    if (Test-Path $StateFile) {
        Remove-Item $StateFile -Force
        Write-Verbose "State file cleaned up: $StateFile"
    }
}

# Parse task progress from Claude output
function Parse-TaskProgress {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Output
    )

    # Parse todo list from output
    # Supports formats:
    # - ☒ Task (completed)
    # - ☐ Task (pending)
    # - ● Task (in progress)

    $tasks = @()

    # Pattern to match todo items
    $todoPattern = '(?m)^[\s-]*[☒☐●✓✗×]\s+(.+?)$'
    $matches = [regex]::Matches($Output, $todoPattern)

    if ($matches.Count -eq 0) {
        return @{
            hasTasks = $false
            totalTasks = 0
            completedTasks = 0
            progress = 0
            tasks = @()
        }
    }

    foreach ($match in $matches) {
        $line = $match.Value.Trim()
        $taskText = $match.Groups[1].Value.Trim()

        # Check status based on symbol
        $isCompleted = $line -match '^[\s-]*[☒✓×]'
        $isInProgress = $line -match '^[\s-]*●'
        $isPending = $line -match '^[\s-]*[☐✗]'

        $status = if ($isCompleted) { "completed" }
                  elseif ($isInProgress) { "in_progress" }
                  else { "pending" }

        $tasks += @{
            text = $taskText
            status = $status
        }
    }

    $completedCount = @($tasks | Where-Object { $_.status -eq "completed" }).Count
    $totalCount = $tasks.Count
    $progress = if ($totalCount -gt 0) {
        [math]::Round(($completedCount / $totalCount) * 100, 2)
    } else {
        0
    }

    $result = @{
        hasTasks = $true
        totalTasks = $totalCount
        completedTasks = $completedCount
        progress = $progress
        tasks = $tasks
    }

    return $result
}

# Test completion criteria
function Test-CompletionCriteria {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Output,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = "",

        [Parameter(Mandatory=$true)]
        [hashtable]$TaskProgress
    )

    # Check explicit completion signals
    $completionSignals = @(
        "task completed",
        "all done",
        "finished successfully",
        "implementation complete",
        "work is complete",
        "completed successfully"
    )

    $hasCompletionSignal = $false
    foreach ($signal in $completionSignals) {
        if ($Output -match [regex]::Escape($signal)) {
            $hasCompletionSignal = $true
            break
        }
    }

    # Check if completion promise is met
    $meetsPromise = $false
    if ($CompletionPromise -and $CompletionPromise.Trim() -ne "") {
        $meetsPromise = $Output -match [regex]::Escape($CompletionPromise)
    }

    # Check task completion (100% progress)
    $allTasksComplete = $TaskProgress.hasTasks -and ($TaskProgress.progress -eq 100)

    # Check for blocking errors
    $blockingErrorPatterns = @(
        "fatal error",
        "cannot proceed",
        "blocked",
        "failed to",
        "error:",
        "exception:"
    )

    $hasBlockingError = $false
    foreach ($pattern in $blockingErrorPatterns) {
        if ($Output -match "(?i)$pattern") {
            $hasBlockingError = $true
            break
        }
    }

    # Determine if should complete
    $shouldComplete = ($hasCompletionSignal -or $meetsPromise -or $allTasksComplete) -and -not $hasBlockingError

    # Determine reason
    $reason = if ($hasBlockingError) {
        "blocking error detected"
    } elseif ($hasCompletionSignal) {
        "completion signal detected"
    } elseif ($meetsPromise) {
        "completion promise met"
    } elseif ($allTasksComplete) {
        "all tasks completed"
    } else {
        "criteria not met"
    }

    return @{
        shouldComplete = $shouldComplete
        reason = $reason
        hasError = $hasBlockingError
        hasCompletionSignal = $hasCompletionSignal
        meetsPromise = $meetsPromise
        allTasksComplete = $allTasksComplete
    }
}

# Start Smart Ralph Loop
function Start-SmartRalphLoop {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 10,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = ""
    )

    # Initialize state
    Initialize-RalphState -Prompt $Prompt -MaxIterations $MaxIterations -CompletionPromise $CompletionPromise | Out-Null

    Write-Host "🔄 Starting Smart Ralph Loop" -ForegroundColor Cyan
    Write-Host "Prompt: $Prompt" -ForegroundColor White
    Write-Host "Max Iterations: $MaxIterations" -ForegroundColor White
    if ($CompletionPromise) {
        Write-Host "Completion Promise: $CompletionPromise" -ForegroundColor White
    }
    Write-Host ""

    Write-RalphLog "Starting Smart Ralph Loop: $Prompt" "INFO"
    Write-RalphLog "Max iterations: $MaxIterations" "INFO"

    $currentPrompt = $Prompt

    for ($i = 1; $i -le $MaxIterations; $i++) {
        # Check for interruption
        if (Test-InterruptionRequested) {
            Write-Host "⏸️  Loop interrupted by user" -ForegroundColor Yellow
            Update-RalphState -Updates @{ status = "interrupted"; endTime = (Get-Date).ToString("o") } | Out-Null
            return @{
                status = "interrupted"
                reason = "User interrupted"
                iterations = $i - 1
            }
        }

        Write-Host "--- Iteration $i/$MaxIterations ---" -ForegroundColor Yellow

        # Update state
        Update-RalphState -Updates @{ currentIteration = $i } | Out-Null

        # Simulate Claude response (in real implementation, this calls Claude)
        # For now, we'll use a mock response for testing
        $response = Invoke-MockClaudeIteration -Prompt $currentPrompt -Iteration $i

        Write-Host "Response received (${response.Length} chars)" -ForegroundColor Gray

        # Parse task progress
        $taskProgress = Parse-TaskProgress -Output $response

        # Check completion
        $completion = Test-CompletionCriteria -Output $response -CompletionPromise $CompletionPromise -TaskProgress $taskProgress

        # Display progress
        if ($taskProgress.hasTasks) {
            Write-Host "Progress: $($taskProgress.completedTasks)/$($taskProgress.totalTasks) tasks ($($taskProgress.progress)%)" -ForegroundColor Cyan
            Show-ProgressBar -Percent ([int]$taskProgress.progress)
            Write-RalphLog "Progress: $($taskProgress.progress)% ($($taskProgress.completedTasks)/$($taskProgress.totalTasks) tasks)" "INFO"
        }

        # Check if should complete
        if ($completion.shouldComplete) {
            Write-Host "✅ Loop completed: $($completion.reason)" -ForegroundColor Green
            Write-RalphLog "Loop completed: $($completion.reason)" "SUCCESS"
            Update-RalphState -Updates @{ status = "completed"; endTime = (Get-Date).ToString("o") } | Out-Null
            return @{
                status = "completed"
                reason = $completion.reason
                iterations = $i
            }
        }

        # Check for blocking error
        if ($completion.hasError) {
            Write-Host "⚠️  Blocking error detected, stopping loop" -ForegroundColor Red
            Write-RalphLog "Blocking error detected: $($completion.reason)" "ERROR"
            Update-RalphState -Updates @{ status = "error"; endTime = (Get-Date).ToString("o") } | Out-Null
            return @{
                status = "error"
                reason = $completion.reason
                iterations = $i
            }
        }

        # Prepare next iteration prompt
        if ($taskProgress.hasTasks) {
            $currentPrompt = "Continue with the task. Previous progress: $($taskProgress.progress)%"
        } else {
            $currentPrompt = "Continue with: $Prompt"
        }

        Write-Host ""
    }

    Write-Host "⏱️  Max iterations reached" -ForegroundColor Yellow
    Write-RalphLog "Max iterations reached" "WARN"
    Update-RalphState -Updates @{ status = "max_iterations"; endTime = (Get-Date).ToString("o") } | Out-Null

    return @{
        status = "max_iterations"
        reason = "Maximum iterations reached"
        iterations = $MaxIterations
    }
}

# Mock Claude iteration (for testing)
function Invoke-MockClaudeIteration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$true)]
        [int]$Iteration
    )

    # Simulate different responses based on iteration
    switch ($Iteration) {
        1 {
            return @"
Starting work on the task...

Todos
☐ Task 1: Setup
☐ Task 2: Implementation
☐ Task 3: Testing
"@
        }
        2 {
            return @"
Making progress...

Todos
☒ Task 1: Setup
● Task 2: Implementation
☐ Task 3: Testing
"@
        }
        3 {
            return @"
Almost done...

Todos
☒ Task 1: Setup
☒ Task 2: Implementation
● Task 3: Testing
"@
        }
        default {
            return @"
Task completed successfully!

Todos
☒ Task 1: Setup
☒ Task 2: Implementation
☒ Task 3: Testing
"@
        }
    }
}

# Export functions (only if running as a module)
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    # Running as a script - functions are already available
} else {
    # Running as a module
    Export-ModuleMember -Function Initialize-RalphState, Update-RalphState, Get-RalphState, Clear-RalphState, Parse-TaskProgress, Test-CompletionCriteria, Start-SmartRalphLoop, Test-InterruptionRequested, Show-ProgressBar, Write-RalphLog
}
