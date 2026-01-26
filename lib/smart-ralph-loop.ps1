# Smart Ralph Loop Engine
# Manages autonomous iteration with progress tracking and state management

param(
    [Parameter(Mandatory=$false)]
    [string]$Prompt,

    [Parameter(Mandatory=$false)]
    [int]$MaxIterations = 0,

    [Parameter(Mandatory=$false)]
    [string]$CompletionPromise = ""
)

$ErrorActionPreference = "Stop"

# Import configuration module
$configModule = Join-Path $PSScriptRoot "ralph-config.ps1"
if (Test-Path $configModule) {
    Import-Module $configModule -Force
}

# Import task queue manager
$taskQueueModule = Join-Path $PSScriptRoot "task-queue-manager.ps1"
if (Test-Path $taskQueueModule) {
    Import-Module $taskQueueModule -Force
}

# Import task order evaluator
$taskOrderModule = Join-Path $PSScriptRoot "task-order-evaluator.ps1"
if (Test-Path $taskOrderModule) {
    Import-Module $taskOrderModule -Force
}

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

# Parse tasks from file content
function Get-TasksFromFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    # Use task-parser.ps1 to parse tasks
    $taskParserPath = Join-Path $PSScriptRoot "task-parser.ps1"

    if (-not (Test-Path $taskParserPath)) {
        Write-Warning "Task parser not found: $taskParserPath"
        return $null
    }

    try {
        $result = & $taskParserPath -TaskFilePath $FilePath 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Task parser failed with exit code: $LASTEXITCODE"
            return $null
        }

        $taskData = $result | ConvertFrom-Json

        if ($taskData.tasks.Count -gt 1) {
            return $taskData.tasks
        }

        return $null
    } catch {
        Write-Warning "Failed to parse tasks from file: $_"
        return $null
    }
}

# Show multi-task progress
function Show-MultiTaskProgress {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$State
    )

    $completedCount = @($State.tasks | Where-Object { $_.status -eq "completed" }).Count
    $totalCount = $State.tasks.Count
    $progressPercent = if ($totalCount -gt 0) {
        [math]::Round(($completedCount / $totalCount) * 100)
    } else {
        0
    }

    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🔄 Smart Ralph - 多任务进度" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📋 总进度: $completedCount/$totalCount 任务完成 ($progressPercent%)" -ForegroundColor White
    Write-Host "🔁 总迭代: $($State.totalIterations) 次" -ForegroundColor White
    Write-Host ""

    for ($i = 0; $i -lt $State.tasks.Count; $i++) {
        $task = $State.tasks[$i]
        $isCurrent = ($i -eq $State.currentTaskIndex)

        $statusIcon = switch ($task.status) {
            "completed" { "✅" }
            "in_progress" { "●" }
            default { "☐" }
        }

        $taskLine = "$statusIcon 任务$($task.id): $($task.title) ($($task.completion)%"

        if ($task.iterations -gt 0) {
            $taskLine += " - $($task.iterations)次迭代"
        }

        $taskLine += ")"

        if ($isCurrent) {
            $taskLine += " ← 当前"
            Write-Host $taskLine -ForegroundColor Yellow
        } elseif ($task.status -eq "completed") {
            Write-Host $taskLine -ForegroundColor Green
        } else {
            Write-Host $taskLine -ForegroundColor Gray
        }
    }

    if ($State.aiAnalysis -and $State.aiAnalysis.reasoning) {
        Write-Host ""
        Write-Host "🤖 AI 建议顺序: $($State.aiOrderedTaskIds -join ' → ')" -ForegroundColor Cyan
        Write-Host "   理由: $($State.aiAnalysis.reasoning)" -ForegroundColor Gray
    }

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
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
        [Parameter(Mandatory=$false)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 0,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = ""
    )

    # Check if Prompt is a file path
    if ($Prompt -and (Test-IsFilePath -Argument $Prompt)) {
        Write-Host "📄 Reading prompt from file: $Prompt" -ForegroundColor Cyan

        # Check if this is a multi-task file
        $tasks = Get-TasksFromFile -FilePath $Prompt

        if ($tasks -and $tasks.Count -gt 1) {
            # Multi-task mode detected!
            Write-Host "✅ Detected multi-task file with $($tasks.Count) tasks" -ForegroundColor Green
            Write-Host ""

            # Initialize multi-task mode
            return Start-MultiTaskRalphLoop -TaskFile $Prompt -Tasks $tasks -MaxIterations $MaxIterations
        }

        # Single task or regular prompt file
        try {
            $Prompt = Read-PromptFromFile -FilePath $Prompt
            Write-Host "✅ Loaded prompt ($($Prompt.Length) characters)" -ForegroundColor Green
            Write-Host ""
        } catch {
            Write-Error "Failed to read prompt file: $_"
            return @{
                status = "error"
                reason = "Failed to read prompt file: $_"
                iterations = 0
            }
        }
    }

    # Validate prompt
    if ([string]::IsNullOrWhiteSpace($Prompt)) {
        Write-Error "Prompt is required. Provide a prompt string or file path."
        return @{
            status = "error"
            reason = "No prompt provided"
            iterations = 0
        }
    }

    # Get default max iterations if not specified
    if ($MaxIterations -le 0) {
        try {
            $MaxIterations = Get-DefaultMaxIterations
            Write-Host "ℹ️  Using default max iterations: $MaxIterations" -ForegroundColor Gray
            Write-Host "   (Set with /ralph-smart-setmaxiterations <n>)" -ForegroundColor Gray
            Write-Host ""
        } catch {
            # Fallback to 15 if config fails
            $MaxIterations = 15
            Write-Warning "Failed to read config, using fallback: $MaxIterations iterations"
        }
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

# Start Multi-Task Ralph Loop
function Start-MultiTaskRalphLoop {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskFile,

        [Parameter(Mandatory=$true)]
        [array]$Tasks,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 50
    )

    Write-Host "🚀 Starting Multi-Task Ralph Loop" -ForegroundColor Cyan
    Write-Host "Task File: $TaskFile" -ForegroundColor White
    Write-Host "Total Tasks: $($Tasks.Count)" -ForegroundColor White
    Write-Host "Max Iterations: $MaxIterations" -ForegroundColor White
    Write-Host ""

    # Step 1: Get AI task order evaluation
    Write-Host "🤖 Requesting AI task order evaluation..." -ForegroundColor Cyan

    $evaluation = Invoke-TaskOrderEvaluation -Tasks $Tasks

    if (-not $evaluation) {
        Write-Error "Failed to create task order evaluation"
        return @{
            status = "error"
            reason = "Failed to create task order evaluation"
            iterations = 0
        }
    }

    # For now, use default order (AI evaluation will happen in the loop)
    # In a real implementation, we would send the prompt to Claude and parse the response
    $aiAnalysis = $evaluation.defaultOrder

    Write-Host "✅ Using task order: $($aiAnalysis.recommended_order -join ', ')" -ForegroundColor Green
    Write-Host "   Reasoning: $($aiAnalysis.reasoning)" -ForegroundColor Gray
    Write-Host ""

    # Step 2: Initialize task queue
    try {
        $state = Initialize-TaskQueue `
            -Tasks $Tasks `
            -OrderedTaskIds $aiAnalysis.recommended_order `
            -AIAnalysis $aiAnalysis `
            -MaxIterations $MaxIterations `
            -TaskFile $TaskFile

        Write-Host "✅ Task queue initialized" -ForegroundColor Green
    } catch {
        Write-Error "Failed to initialize task queue: $_"
        return @{
            status = "error"
            reason = "Failed to initialize task queue: $_"
            iterations = 0
        }
    }

    # Step 3: Show initial progress
    Show-MultiTaskProgress -State $state

    # Step 4: Start with first task
    $firstTask = $state.tasks[0]

    $initialPrompt = @"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 多任务模式：开始任务 $($firstTask.id)/$($Tasks.Count)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**任务标题**: $($firstTask.title)

**描述**: $($firstTask.description)

**验收标准**:
$($firstTask.acceptance_criteria | ForEach-Object { "- [ ] $($_.text)" } | Out-String)

请开始实现此任务。完成后，请确保所有验收标准都已满足。

注意：这是多任务模式，完成此任务后会自动切换到下一个任务。
"@

    Write-Host "📝 Starting first task..." -ForegroundColor Cyan
    Write-Host ""

    # Initialize Ralph Loop state for first task
    Initialize-RalphState -Prompt $initialPrompt -MaxIterations $MaxIterations -CompletionPromise "" | Out-Null

    Write-RalphLog "Starting Multi-Task Ralph Loop: $TaskFile" "INFO"
    Write-RalphLog "Total tasks: $($Tasks.Count)" "INFO"
    Write-RalphLog "Max iterations: $MaxIterations" "INFO"

    # Note: The actual loop execution happens through the stop hook
    # This function just sets up the initial state
    # The stop hook will handle task switching and progress tracking

    Write-Host "✅ Multi-task mode initialized. The Ralph Loop will now execute tasks sequentially." -ForegroundColor Green
    Write-Host "   Use Ctrl+C to interrupt at any time." -ForegroundColor Gray
    Write-Host ""

    return @{
        status = "initialized"
        reason = "Multi-task mode initialized"
        totalTasks = $Tasks.Count
        iterations = 0
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

# Functions are automatically available when script is imported
