# Task Queue Manager for Smart Ralph Multi-Task Support
# Manages task queue state, switching, and progress tracking

$ErrorActionPreference = "Stop"

# State file location
$script:MultiTaskStateFile = Join-Path $env:TEMP "smart-ralph-multi-task-state.json"

# Initialize task queue
function Initialize-TaskQueue {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,

        [Parameter(Mandatory=$true)]
        [array]$OrderedTaskIds,

        [Parameter(Mandatory=$true)]
        [hashtable]$AIAnalysis,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 50,

        [Parameter(Mandatory=$false)]
        [string]$TaskFile = ""
    )

    # Reorder tasks based on AI analysis
    $orderedTasks = @()
    foreach ($taskId in $OrderedTaskIds) {
        $task = $Tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
        if ($task) {
            # Ensure task has required fields
            if (-not $task.status) { $task.status = "pending" }
            if (-not $task.completion) { $task.completion = 0 }
            if (-not $task.iterations) { $task.iterations = 0 }
            if (-not $task.startTime) { $task.startTime = $null }
            if (-not $task.endTime) { $task.endTime = $null }

            $orderedTasks += $task
        }
    }

    # Set first task to in_progress
    if ($orderedTasks.Count -gt 0) {
        $orderedTasks[0].status = "in_progress"
        $orderedTasks[0].startTime = (Get-Date).ToString("o")
    }

    # Create state object
    $state = @{
        taskFile = $TaskFile
        aiOrderedTaskIds = $OrderedTaskIds
        aiAnalysis = $AIAnalysis
        tasks = $orderedTasks
        currentTaskIndex = 0
        totalIterations = 0
        maxIterations = $MaxIterations
        startTime = (Get-Date).ToString("o")
        lastUpdateTime = (Get-Date).ToString("o")
    }

    # Save state
    Save-TaskQueueState -State $state

    Write-Verbose "Task queue initialized with $($orderedTasks.Count) tasks"
    return $state
}

# Save task queue state
function Save-TaskQueueState {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$State
    )

    try {
        $State.lastUpdateTime = (Get-Date).ToString("o")
        $json = $State | ConvertTo-Json -Depth 10
        $json | Set-Content -Path $script:MultiTaskStateFile -Encoding UTF8 -Force
        Write-Verbose "Task queue state saved to: $script:MultiTaskStateFile"
    } catch {
        Write-Error "Failed to save task queue state: $_"
    }
}

# Load task queue state
function Get-TaskQueueState {
    if (-not (Test-Path $script:MultiTaskStateFile)) {
        return $null
    }

    try {
        $json = Get-Content -Path $script:MultiTaskStateFile -Raw -Encoding UTF8
        $state = $json | ConvertFrom-Json

        # Convert PSCustomObject to hashtable for easier manipulation
        $hashtable = @{}
        $state.PSObject.Properties | ForEach-Object {
            $hashtable[$_.Name] = $_.Value
        }

        return $hashtable
    } catch {
        Write-Error "Failed to load task queue state: $_"
        return $null
    }
}

# Get current task
function Get-CurrentTask {
    $state = Get-TaskQueueState

    if (-not $state) {
        return $null
    }

    if ($state.currentTaskIndex -ge $state.tasks.Count) {
        return $null
    }

    return $state.tasks[$state.currentTaskIndex]
}

# Get task by ID
function Get-TaskById {
    param(
        [Parameter(Mandatory=$true)]
        [int]$TaskId
    )

    $state = Get-TaskQueueState

    if (-not $state) {
        return $null
    }

    return $state.tasks | Where-Object { $_.id -eq $TaskId } | Select-Object -First 1
}

# Update task progress
function Update-TaskProgress {
    param(
        [Parameter(Mandatory=$true)]
        [int]$TaskId,

        [Parameter(Mandatory=$false)]
        [int]$Completion = -1,

        [Parameter(Mandatory=$false)]
        [string]$Status = "",

        [Parameter(Mandatory=$false)]
        [int]$Iterations = -1
    )

    $state = Get-TaskQueueState

    if (-not $state) {
        Write-Error "No task queue state found"
        return $false
    }

    # Find task
    $taskIndex = -1
    for ($i = 0; $i -lt $state.tasks.Count; $i++) {
        if ($state.tasks[$i].id -eq $TaskId) {
            $taskIndex = $i
            break
        }
    }

    if ($taskIndex -eq -1) {
        Write-Error "Task ID $TaskId not found"
        return $false
    }

    # Update fields
    if ($Completion -ge 0) {
        $state.tasks[$taskIndex].completion = $Completion
    }

    if ($Status -ne "") {
        $state.tasks[$taskIndex].status = $Status
    }

    if ($Iterations -ge 0) {
        $state.tasks[$taskIndex].iterations = $Iterations
    }

    # Update timestamps
    if ($Status -eq "completed") {
        $state.tasks[$taskIndex].endTime = (Get-Date).ToString("o")
    }

    # Save state
    Save-TaskQueueState -State $state

    return $true
}

# Switch to next task
function Switch-ToNextTask {
    $state = Get-TaskQueueState

    if (-not $state) {
        Write-Error "No task queue state found"
        return $null
    }

    # Mark current task as completed
    if ($state.currentTaskIndex -lt $state.tasks.Count) {
        $currentTask = $state.tasks[$state.currentTaskIndex]
        $currentTask.status = "completed"
        $currentTask.completion = 100
        $currentTask.endTime = (Get-Date).ToString("o")
    }

    # Move to next task
    $state.currentTaskIndex++

    # Check if there are more tasks
    if ($state.currentTaskIndex -ge $state.tasks.Count) {
        Save-TaskQueueState -State $state
        return $null
    }

    # Set next task to in_progress
    $nextTask = $state.tasks[$state.currentTaskIndex]
    $nextTask.status = "in_progress"
    $nextTask.startTime = (Get-Date).ToString("o")

    # Save state
    Save-TaskQueueState -State $state

    Write-Verbose "Switched to task $($nextTask.id): $($nextTask.title)"
    return $nextTask
}

# Test if all tasks are complete
function Test-AllTasksComplete {
    $state = Get-TaskQueueState

    if (-not $state) {
        return $false
    }

    # Check if current index is beyond task count
    if ($state.currentTaskIndex -ge $state.tasks.Count) {
        return $true
    }

    # Check if all tasks have completed status
    $allComplete = $true
    foreach ($task in $state.tasks) {
        if ($task.status -ne "completed") {
            $allComplete = $false
            break
        }
    }

    return $allComplete
}

# Test if more tasks remain
function Test-HasMoreTasks {
    $state = Get-TaskQueueState

    if (-not $state) {
        return $false
    }

    return ($state.currentTaskIndex + 1) -lt $state.tasks.Count
}

# Increment total iterations
function Add-TotalIteration {
    $state = Get-TaskQueueState

    if (-not $state) {
        return
    }

    $state.totalIterations++

    # Also increment current task iterations
    if ($state.currentTaskIndex -lt $state.tasks.Count) {
        $state.tasks[$state.currentTaskIndex].iterations++
    }

    Save-TaskQueueState -State $state
}

# Clear task queue state
function Clear-TaskQueueState {
    if (Test-Path $script:MultiTaskStateFile) {
        Remove-Item -Path $script:MultiTaskStateFile -Force
        Write-Verbose "Task queue state cleared"
    }
}

# Get task queue statistics
function Get-TaskQueueStats {
    $state = Get-TaskQueueState

    if (-not $state) {
        return $null
    }

    $completedCount = @($state.tasks | Where-Object { $_.status -eq "completed" }).Count
    $inProgressCount = @($state.tasks | Where-Object { $_.status -eq "in_progress" }).Count
    $pendingCount = @($state.tasks | Where-Object { $_.status -eq "pending" }).Count

    $totalTasks = $state.tasks.Count
    $progressPercent = if ($totalTasks -gt 0) {
        [math]::Round(($completedCount / $totalTasks) * 100, 2)
    } else {
        0
    }

    return @{
        totalTasks = $totalTasks
        completedTasks = $completedCount
        inProgressTasks = $inProgressCount
        pendingTasks = $pendingCount
        progressPercent = $progressPercent
        currentTaskIndex = $state.currentTaskIndex
        totalIterations = $state.totalIterations
        maxIterations = $state.maxIterations
    }
}

# Get multi-task state file path
function Get-MultiTaskStateFilePath {
    return $script:MultiTaskStateFile
}

# Functions are exported automatically when imported as a module
