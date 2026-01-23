# Comprehensive Test Suite for Smart Ralph Loop
# Tests all components: state management, task parsing, completion detection, main loop

$ErrorActionPreference = "Stop"

# Import the module
Import-Module "$PSScriptRoot\..\lib\smart-ralph-loop.ps1" -Force

$totalTests = 0
$passedTests = 0
$failedTests = 0

function Test-Component {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    $script:totalTests++

    try {
        & $Test
        Write-Host "✅ $Name" -ForegroundColor Green
        $script:passedTests++
        return $true
    } catch {
        Write-Host "❌ $Name" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
        $script:failedTests++
        return $false
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Ralph Loop - Comprehensive Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ===== State Management Tests =====
Write-Host "State Management Tests" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow

Test-Component "Initialize state" {
    $state = Initialize-RalphState -Prompt "Test" -MaxIterations 5
    if ($state.prompt -ne "Test" -or $state.maxIterations -ne 5) {
        throw "State initialization failed"
    }
}

Test-Component "Get state" {
    $state = Get-RalphState
    if (-not $state -or $state.prompt -ne "Test") {
        throw "Get state failed"
    }
}

Test-Component "Update state" {
    $state = Update-RalphState -Updates @{ currentIteration = 3 }
    if ($state.currentIteration -ne 3) {
        throw "Update state failed"
    }
}

Test-Component "Clear state" {
    Clear-RalphState
    $state = Get-RalphState
    if ($state) {
        throw "Clear state failed"
    }
}

Write-Host ""

# ===== Task Parser Tests =====
Write-Host "Task Parser Tests" -ForegroundColor Yellow
Write-Host "-----------------" -ForegroundColor Yellow

Test-Component "Parse no tasks" {
    $result = Parse-TaskProgress -Output "No tasks here"
    if ($result.hasTasks) {
        throw "Should have no tasks"
    }
}

Test-Component "Parse mixed tasks" {
    $output = "Todos`n☒ Task 1`n☐ Task 2`n● Task 3"
    $result = Parse-TaskProgress -Output $output
    if ($result.totalTasks -ne 3 -or $result.completedTasks -ne 1) {
        throw "Task parsing incorrect"
    }
}

Test-Component "Parse 100% completion" {
    $output = "☒ Task 1`n☒ Task 2`n☒ Task 3"
    $result = Parse-TaskProgress -Output $output
    if ($result.progress -ne 100) {
        throw "Should be 100% complete"
    }
}

Test-Component "Parse alternative checkmarks" {
    $output = "✓ Done`n✗ Pending`n× Complete"
    $result = Parse-TaskProgress -Output $output
    if ($result.completedTasks -ne 2) {
        throw "Alternative checkmarks not parsed"
    }
}

Write-Host ""

# ===== Completion Detection Tests =====
Write-Host "Completion Detection Tests" -ForegroundColor Yellow
Write-Host "--------------------------" -ForegroundColor Yellow

Test-Component "Detect completion signal" {
    $taskProgress = @{ hasTasks = $false; progress = 0 }
    $result = Test-CompletionCriteria -Output "Task completed!" -CompletionPromise "" -TaskProgress $taskProgress
    if (-not $result.shouldComplete) {
        throw "Should detect completion"
    }
}

Test-Component "Detect completion promise" {
    $taskProgress = @{ hasTasks = $false; progress = 0 }
    $result = Test-CompletionCriteria -Output "All tests passing" -CompletionPromise "All tests passing" -TaskProgress $taskProgress
    if (-not $result.shouldComplete) {
        throw "Should detect promise"
    }
}

Test-Component "Detect 100% tasks" {
    $taskProgress = @{ hasTasks = $true; progress = 100 }
    $result = Test-CompletionCriteria -Output "Working..." -CompletionPromise "" -TaskProgress $taskProgress
    if (-not $result.shouldComplete) {
        throw "Should detect 100% completion"
    }
}

Test-Component "Detect blocking error" {
    $taskProgress = @{ hasTasks = $false; progress = 0 }
    $result = Test-CompletionCriteria -Output "Fatal error occurred" -CompletionPromise "" -TaskProgress $taskProgress
    if ($result.shouldComplete) {
        throw "Should not complete on error"
    }
}

Test-Component "No completion criteria" {
    $taskProgress = @{ hasTasks = $true; progress = 50 }
    $result = Test-CompletionCriteria -Output "Still working..." -CompletionPromise "" -TaskProgress $taskProgress
    if ($result.shouldComplete) {
        throw "Should not complete"
    }
}

Write-Host ""

# ===== Main Loop Tests =====
Write-Host "Main Loop Tests" -ForegroundColor Yellow
Write-Host "---------------" -ForegroundColor Yellow

Test-Component "Loop completes on task completion" {
    $result = Start-SmartRalphLoop -Prompt "Test" -MaxIterations 10
    if ($result.status -ne "completed") {
        throw "Loop should complete"
    }
}

Test-Component "State persisted correctly" {
    $state = Get-RalphState
    if ($state.status -ne "completed") {
        throw "State not persisted"
    }
}

# Clean up
Clear-RalphState

Write-Host ""

# ===== Interruption Tests =====
Write-Host "Interruption Tests" -ForegroundColor Yellow
Write-Host "------------------" -ForegroundColor Yellow

Test-Component "Interruption flag check" {
    $isRunning = -not (Test-InterruptionRequested)
    if (-not $isRunning) {
        throw "Should be running"
    }
}

Test-Component "State marked as interrupted" {
    Initialize-RalphState -Prompt "Test" -MaxIterations 10 | Out-Null
    Update-RalphState -Updates @{ status = "interrupted" } | Out-Null
    $state = Get-RalphState
    if ($state.status -ne "interrupted") {
        throw "State not marked as interrupted"
    }
}

# Clean up
Clear-RalphState

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $totalTests" -ForegroundColor White
Write-Host "Passed:       $passedTests" -ForegroundColor Green
Write-Host "Failed:       $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate:    $([math]::Round(($passedTests / $totalTests) * 100, 1))%" -ForegroundColor $(if ($failedTests -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($failedTests -gt 0) {
    Write-Host "❌ Some tests failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
    exit 0
}
