# Smart Ralph Loop Engine - Improved Version
# Manages autonomous iteration with progress tracking and state management
# Enhanced with comprehensive error handling and edge case coverage

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
$script:StateLock = [System.Threading.Mutex]::new($false, "SmartRalphStateLock")

# Interruption handler
$script:InterruptHandler = {
    Write-Host "`n⏸️  Interruption detected, saving state..." -ForegroundColor Yellow
    $script:IsRunning = $false
}

# Register Ctrl+C handler
try {
    [Console]::TreatControlCAsInput = $false
    # Check if already registered to avoid duplicates
    $existing = Get-EventSubscriber -SourceIdentifier PowerShell.Exiting -ErrorAction SilentlyContinue
    if (-not $existing) {
        $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $script:InterruptHandler
    }
} catch {
    Write-RalphLog "Failed to register interruption handler: $_" "WARN"
}

# Test if interruption was requested
function Test-InterruptionRequested {
    return -not $script:IsRunning
}

# Show progress bar with bounds checking
function Show-ProgressBar {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Percent
    )

    # Clamp percent to valid range [0, 100]
    $Percent = [Math]::Max(0, [Math]::Min(100, $Percent))

    $barLength = 40
    $filled = [math]::Floor($barLength * $Percent / 100)
    $empty = $barLength - $filled

    $bar = "[" + ("=" * $filled) + ("." * $empty) + "]"
    Write-Host "$bar $Percent%" -ForegroundColor Cyan
}

# Write log message with error handling
function Write-RalphLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"

        $logFile = Join-Path $env:TEMP "smart-ralph-loop.log"

        # Ensure log directory exists
        $logDir = Split-Path $logFile -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8 -ErrorAction Stop

        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "Gray" }
        }

        if ($Level -ne "INFO") {
            Write-Host $logMessage -ForegroundColor $color
        }
    } catch {
        # Fallback: write to console if logging fails
        Write-Warning "Failed to write log: $_"
        Write-Host "[$Level] $Message" -ForegroundColor Yellow
    }
}

# Initialize Ralph Loop state with error handling
function Initialize-RalphState {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 10,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = ""
    )

    try {
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($Prompt)) {
            throw "Prompt cannot be empty"
        }

        if ($MaxIterations -lt 1) {
            throw "MaxIterations must be at least 1"
        }

        $state = @{
            prompt = $Prompt
            maxIterations = $MaxIterations
            completionPromise = $CompletionPromise
            currentIteration = 0
            startTime = (Get-Date).ToString("o")
            status = "running"
            endTime = $null
        }

        # Ensure state directory exists
        $stateDir = Split-Path $StateFile -Parent
        if (-not (Test-Path $stateDir)) {
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        $state | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8 -ErrorAction Stop

        Write-RalphLog "State initialized successfully" "INFO"
        return $state
    } catch {
        Write-RalphLog "Failed to initialize state: $_" "ERROR"
        throw
    }
}

# Update Ralph Loop state with error handling and locking
function Update-RalphState {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Updates
    )

    try {
        # Acquire lock for thread safety
        $null = $script:StateLock.WaitOne()

        if (-not (Test-Path $StateFile)) {
            throw "State file not found: $StateFile"
        }

        $stateJson = Get-Content $StateFile -Raw -Encoding UTF8 -ErrorAction Stop

        # Validate JSON before parsing
        if ([string]::IsNullOrWhiteSpace($stateJson)) {
            throw "State file is empty or corrupted"
        }

        $state = $stateJson | ConvertFrom-Json -AsHashtable -ErrorAction Stop

        foreach ($key in $Updates.Keys) {
            $state[$key] = $Updates[$key]
        }

        $state | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8 -ErrorAction Stop

        return $state
    } catch {
        Write-RalphLog "Failed to update state: $_" "ERROR"
        return $null
    } finally {
        # Always release lock
        $script:StateLock.ReleaseMutex()
    }
}

# Get Ralph Loop state with error handling
function Get-RalphState {
    try {
        # Acquire lock for thread safety
        $null = $script:StateLock.WaitOne()

        if (-not (Test-Path $StateFile)) {
            return $null
        }

        $stateJson = Get-Content $StateFile -Raw -Encoding UTF8 -ErrorAction Stop

        # Validate JSON before parsing
        if ([string]::IsNullOrWhiteSpace($stateJson)) {
            Write-RalphLog "State file is empty" "WARN"
            return $null
        }

        $state = $stateJson | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        return $state
    } catch {
        Write-RalphLog "Failed to read state: $_" "ERROR"
        return $null
    } finally {
        # Always release lock
        $script:StateLock.ReleaseMutex()
    }
}

# Clear Ralph Loop state with error handling
function Clear-RalphState {
    try {
        if (Test-Path $StateFile) {
            Remove-Item $StateFile -Force -ErrorAction Stop
            Write-Verbose "State file cleaned up: $StateFile"
        }
    } catch {
        Write-RalphLog "Failed to clear state: $_" "WARN"
    }
}

# Parse task progress from Claude output with improved edge case handling
function Parse-TaskProgress {
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Output
    )

    # Handle empty or null output
    if ([string]::IsNullOrWhiteSpace($Output)) {
        return @{
            hasTasks = $false
            totalTasks = 0
            completedTasks = 0
            progress = 0
            tasks = @()
        }
    }

    # Parse todo list from output
    # Supports formats:
    # - ☒ Task (completed)
    # - ☐ Task (pending)
    # - ● Task (in progress)
    # - ✓ Task (completed)
    # - × Task (completed)

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

        # Skip empty task text
        if ([string]::IsNullOrWhiteSpace($taskText)) {
            continue
        }

        # Check status based on symbol (order matters - check completed first!)
        # Priority: completed > in_progress > pending
        # ☒ ✓ × = completed
        # ● = in progress
        # ☐ = pending
        # Note: ✗ removed from pending to avoid conflict with ×
        $isCompleted = $line -match '^[\s-]*[☒✓×]'
        $isInProgress = $line -match '^[\s-]*●'
        $isPending = $line -match '^[\s-]*☐'

        $status = if ($isCompleted) { "completed" }
                  elseif ($isInProgress) { "in_progress" }
                  elseif ($isPending) { "pending" }
                  else { "pending" }  # Default to pending

        $tasks += @{
            text = $taskText
            status = $status
        }
    }

    # Handle case where all tasks were empty
    if ($tasks.Count -eq 0) {
        return @{
            hasTasks = $false
            totalTasks = 0
            completedTasks = 0
            progress = 0
            tasks = @()
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

# Test completion criteria with improved error detection
function Test-CompletionCriteria {
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Output,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = "",

        [Parameter(Mandatory=$true)]
        [hashtable]$TaskProgress
    )

    # Handle empty output
    if ([string]::IsNullOrWhiteSpace($Output)) {
        return @{
            shouldComplete = $false
            reason = "empty output"
            hasError = $false
            hasCompletionSignal = $false
            meetsPromise = $false
            allTasksComplete = $false
        }
    }

    # Check explicit completion signals (case-insensitive)
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
        if ($Output -match "(?i)$([regex]::Escape($signal))") {
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

    # Check for blocking errors (more precise patterns)
    # Only match errors that indicate the loop should stop
    $blockingErrorPatterns = @(
        "fatal error:",           # Fatal errors only
        "cannot proceed",         # Explicit blocking
        "blocked by",             # Explicit blocking
        "failed to start",        # Critical startup failures
        "unrecoverable error"     # Explicit unrecoverable
    )

    $hasBlockingError = $false
    foreach ($pattern in $blockingErrorPatterns) {
        if ($Output -match "(?i)$([regex]::Escape($pattern))") {
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

# Start Smart Ralph Loop with comprehensive error handling
function Start-SmartRalphLoop {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 10,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = ""
    )

    try {
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($Prompt)) {
            throw "Prompt cannot be empty"
        }

        if ($MaxIterations -lt 1) {
            throw "MaxIterations must be at least 1"
        }

        if ($MaxIterations -gt 1000) {
            throw "MaxIterations cannot exceed 1000"
        }

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
            $updateResult = Update-RalphState -Updates @{ currentIteration = $i }
            if ($null -eq $updateResult) {
                Write-Warning "Failed to update state, continuing anyway..."
            }

            # In real implementation, this would call Claude
            # For testing, we use mock responses
            try {
                $response = Invoke-MockClaudeIteration -Prompt $currentPrompt -Iteration $i
            } catch {
                Write-RalphLog "Failed to get Claude response: $_" "ERROR"
                return @{
                    status = "error"
                    reason = "Failed to get Claude response: $_"
                    iterations = $i
                }
            }

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
    } catch {
        Write-RalphLog "Fatal error in Smart Ralph Loop: $_" "ERROR"
        throw
    } finally {
        # Clean up resources
        if ($script:StateLock) {
            try {
                $script:StateLock.Dispose()
                $script:StateLock = $null
            } catch {
                Write-RalphLog "Failed to dispose Mutex: $_" "WARN"
            }
        }
    }
}

# Mock Claude iteration (for testing only - remove in production)
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
