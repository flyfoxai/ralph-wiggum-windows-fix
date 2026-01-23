# Integration Tests for Smart Ralph Loop
# Tests end-to-end workflows

$ErrorActionPreference = "Stop"

# Import the module
Import-Module "$PSScriptRoot\..\lib\smart-ralph-loop.ps1" -Force

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Ralph Loop - Integration Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Test 1: Full loop execution
Write-Host "Test 1: Full loop execution" -ForegroundColor Yellow
Write-Host ""

$result = Start-SmartRalphLoop -Prompt "Integration test" -MaxIterations 10

if ($result.status -eq "completed" -and $result.iterations -gt 0) {
    Write-Host "✅ PASS: Loop executed and completed" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "❌ FAIL: Loop did not complete correctly" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""

# Test 2: State persistence across operations
Write-Host "Test 2: State persistence" -ForegroundColor Yellow

$state = Get-RalphState
if ($state -and $state.prompt -eq "Integration test" -and $state.status -eq "completed") {
    Write-Host "✅ PASS: State persisted correctly" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "❌ FAIL: State not persisted" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""

# Test 3: State cleanup
Write-Host "Test 3: State cleanup" -ForegroundColor Yellow

Clear-RalphState
$state = Get-RalphState
if (-not $state) {
    Write-Host "✅ PASS: State cleaned up successfully" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "❌ FAIL: State not cleaned up" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""

# Test 4: Multiple loop executions
Write-Host "Test 4: Multiple loop executions" -ForegroundColor Yellow

$result1 = Start-SmartRalphLoop -Prompt "Test 1" -MaxIterations 5
$result2 = Start-SmartRalphLoop -Prompt "Test 2" -MaxIterations 5

if ($result1.status -eq "completed" -and $result2.status -eq "completed") {
    Write-Host "✅ PASS: Multiple loops executed successfully" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "❌ FAIL: Multiple loops failed" -ForegroundColor Red
    $testsFailed++
}

Clear-RalphState

Write-Host ""

# Test 5: Error handling
Write-Host "Test 5: Error handling" -ForegroundColor Yellow

try {
    # Try to get state when none exists
    $state = Get-RalphState
    if ($null -eq $state) {
        Write-Host "✅ PASS: Handles missing state gracefully" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "❌ FAIL: Should return null for missing state" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "❌ FAIL: Error handling failed: $_" -ForegroundColor Red
    $testsFailed++
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Integration Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($testsFailed -gt 0) {
    Write-Host "❌ Some integration tests failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ All integration tests passed!" -ForegroundColor Green
    exit 0
}
