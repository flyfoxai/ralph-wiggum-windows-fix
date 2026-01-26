# Multi-Task Functionality Tests
# Tests for Smart Ralph multi-task support

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowVerbose
)

$ErrorActionPreference = "Stop"

if ($ShowVerbose) {
    $VerbosePreference = "Continue"
}

# Import required modules
$libPath = Join-Path $PSScriptRoot "..\lib"
Import-Module (Join-Path $libPath "task-queue-manager.ps1") -Force
Import-Module (Join-Path $libPath "task-order-evaluator.ps1") -Force

# Test counter
$script:TestsPassed = 0
$script:TestsFailed = 0

# Test helper functions
function Test-Assert {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestName,

        [Parameter(Mandatory=$true)]
        [bool]$Condition,

        [Parameter(Mandatory=$false)]
        [string]$Message = ""
    )

    if ($Condition) {
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        $script:TestsPassed++
    } else {
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "   $Message" -ForegroundColor Red
        }
        $script:TestsFailed++
    }
}

function Test-Section {
    param([string]$Name)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📋 $Name" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

# Clean up any existing state
function Clear-TestState {
    $stateFile = Join-Path $env:TEMP "smart-ralph-multi-task-state.json"
    if (Test-Path $stateFile) {
        Remove-Item $stateFile -Force
    }
}

# ============================================
# Test 1: Task Order Evaluator
# ============================================
Test-Section "Task Order Evaluator Tests"

# Test 1.1: Build task order prompt
$testTasks = @(
    @{
        id = 1
        title = "Task 1"
        description = "Create authentication system"
        acceptance_criteria = @(
            @{ text = "Create User model"; completed = $false },
            @{ text = "Implement registration API"; completed = $false }
        )
    },
    @{
        id = 2
        title = "Task 2"
        description = "User profile management"
        acceptance_criteria = @(
            @{ text = "Create profile API"; completed = $false }
        )
    }
)

$prompt = Build-TaskOrderPrompt -Tasks $testTasks
Test-Assert -TestName "Build task order prompt" `
    -Condition ($prompt -match "Task List" -and $prompt -match "Task 1") `
    -Message "Prompt should contain task list"

# Test 1.2: Parse AI analysis
$mockOutput = @'
Here is my analysis:

<task-order-analysis>
{
  "analysis": {
    "dependencies": {
      "task_2": ["task_1"]
    },
    "complexity": {
      "task_1": "medium",
      "task_2": "simple"
    },
    "recommended_order": [1, 2],
    "reasoning": "Task 1 must be completed first"
  }
}
</task-order-analysis>

That is my recommendation.
'@

$analysis = Parse-AIAnalysis -Output $mockOutput
Test-Assert -TestName "Parse AI analysis from tags" `
    -Condition ($analysis -ne $null -and $analysis.recommended_order.Count -eq 2) `
    -Message "Should parse JSON from tags"

# Test 1.3: Get default task order
$defaultOrder = Get-DefaultTaskOrder -Tasks $testTasks
Test-Assert -TestName "Get default task order" `
    -Condition ($defaultOrder.recommended_order.Count -eq 2 -and $defaultOrder.recommended_order[0] -eq 1) `
    -Message "Should return sequential order"

# Test 1.4: Validate task order
$validOrder = Test-TaskOrder -Tasks $testTasks -Order @(1, 2)
Test-Assert -TestName "Validate correct task order" `
    -Condition ($validOrder -eq $true) `
    -Message "Should validate correct order"

$invalidOrder = Test-TaskOrder -Tasks $testTasks -Order @(1, 3)
Test-Assert -TestName "Detect invalid task order" `
    -Condition ($invalidOrder -eq $false) `
    -Message "Should detect invalid order"

# Test 1.5: Reorder tasks
$reorderedTasks = Invoke-TaskReordering -Tasks $testTasks -Analysis $defaultOrder
Test-Assert -TestName "Reorder tasks" `
    -Condition ($reorderedTasks.Count -eq 2 -and $reorderedTasks[0].id -eq 1) `
    -Message "Should reorder tasks correctly"

# ============================================
# Test 2: Task Queue Manager
# ============================================
Test-Section "Task Queue Manager Tests"

Clear-TestState

# Test 2.1: Initialize task queue
$aiAnalysis = @{
    dependencies = @{}
    complexity = @{ "task_1" = "medium"; "task_2" = "simple" }
    recommended_order = @(1, 2)
    reasoning = "Sequential order"
}

$state = Initialize-TaskQueue `
    -Tasks $testTasks `
    -OrderedTaskIds @(1, 2) `
    -AIAnalysis $aiAnalysis `
    -MaxIterations 50 `
    -TaskFile "test-tasks.md"

Test-Assert -TestName "Initialize task queue" `
    -Condition ($state -ne $null -and $state.tasks.Count -eq 2) `
    -Message "Should initialize task queue"

Test-Assert -TestName "First task set to in_progress" `
    -Condition ($state.tasks[0].status -eq "in_progress") `
    -Message "First task should be in_progress"

# Test 2.2: Get current task
$currentTask = Get-CurrentTask
Test-Assert -TestName "Get current task" `
    -Condition ($currentTask -ne $null -and $currentTask.id -eq 1) `
    -Message "Should return first task"

# Test 2.3: Update task progress
$updated = Update-TaskProgress -TaskId 1 -Completion 50 -Status "in_progress"
Test-Assert -TestName "Update task progress" `
    -Condition ($updated -eq $true) `
    -Message "Should update task progress"

$updatedState = Get-TaskQueueState
Test-Assert -TestName "Verify task progress updated" `
    -Condition ($updatedState.tasks[0].completion -eq 50) `
    -Message "Task completion should be 50%"

# Test 2.4: Switch to next task
$nextTask = Switch-ToNextTask
Test-Assert -TestName "Switch to next task" `
    -Condition ($nextTask -ne $null -and $nextTask.id -eq 2) `
    -Message "Should switch to task 2"

$stateAfterSwitch = Get-TaskQueueState
Test-Assert -TestName "Previous task marked completed" `
    -Condition ($stateAfterSwitch.tasks[0].status -eq "completed") `
    -Message "Previous task should be completed"

Test-Assert -TestName "Current task set to in_progress" `
    -Condition ($stateAfterSwitch.tasks[1].status -eq "in_progress") `
    -Message "Current task should be in_progress"

# Test 2.5: Test has more tasks
$hasMore = Test-HasMoreTasks
Test-Assert -TestName "Test has more tasks (false)" `
    -Condition ($hasMore -eq $false) `
    -Message "Should return false when on last task"

# Test 2.6: Complete all tasks
$finalTask = Switch-ToNextTask
Test-Assert -TestName "Switch past last task returns null" `
    -Condition ($finalTask -eq $null) `
    -Message "Should return null when no more tasks"

$allComplete = Test-AllTasksComplete
Test-Assert -TestName "Test all tasks complete" `
    -Condition ($allComplete -eq $true) `
    -Message "Should return true when all tasks complete"

# Test 2.7: Get task queue stats
Clear-TestState
Initialize-TaskQueue `
    -Tasks $testTasks `
    -OrderedTaskIds @(1, 2) `
    -AIAnalysis $aiAnalysis `
    -MaxIterations 50 `
    -TaskFile "test-tasks.md" | Out-Null

$stats = Get-TaskQueueStats
Test-Assert -TestName "Get task queue stats" `
    -Condition ($stats -ne $null -and $stats.totalTasks -eq 2) `
    -Message "Should return queue statistics"

Test-Assert -TestName "Stats show correct progress" `
    -Condition ($stats.inProgressTasks -eq 1 -and $stats.pendingTasks -eq 1) `
    -Message "Should show 1 in progress, 1 pending"

# Test 2.8: Add total iteration
Add-TotalIteration
$stateAfterIteration = Get-TaskQueueState
Test-Assert -TestName "Add total iteration" `
    -Condition ($stateAfterIteration.totalIterations -eq 1) `
    -Message "Should increment total iterations"

Test-Assert -TestName "Add task iteration" `
    -Condition ($stateAfterIteration.tasks[0].iterations -eq 1) `
    -Message "Should increment current task iterations"

# Test 2.9: Clear task queue state
Clear-TaskQueueState
$clearedState = Get-TaskQueueState
Test-Assert -TestName "Clear task queue state" `
    -Condition ($clearedState -eq $null) `
    -Message "Should clear state file"

# ============================================
# Test Summary
# ============================================
Test-Section "Test Summary"

$totalTests = $script:TestsPassed + $script:TestsFailed
$passRate = if ($totalTests -gt 0) {
    [math]::Round(($script:TestsPassed / $totalTests) * 100, 2)
} else {
    0
}

Write-Host ""
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "Failed: $script:TestsFailed" -ForegroundColor $(if ($script:TestsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host ""

if ($script:TestsFailed -eq 0) {
    Write-Host "🎉 All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some tests failed. Please review the output above." -ForegroundColor Yellow
    exit 1
}
