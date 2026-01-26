# Argument Parsing Tests
# Tests setup-ralph-loop.ps1 parameter parsing with various inputs

$ErrorActionPreference = "Stop"

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
Write-Host "Argument Parsing - Detailed Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$setupScriptPath = Join-Path $PSScriptRoot "..\scripts\setup-ralph-loop.ps1"

# ===== Setup Test Environment =====
Write-Host "Setup Test Environment" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow

$testDir = Join-Path $env:TEMP "ralph-arg-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
$testClaudeDir = Join-Path $testDir ".claude"
New-Item -ItemType Directory -Path $testClaudeDir -Force | Out-Null
$testStateFile = Join-Path $testClaudeDir "ralph-loop.local.md"

Write-Host "Test directory: $testDir" -ForegroundColor Gray
Write-Host ""

# ===== Test 1: Basic Prompt Parsing =====
Write-Host "Test 1: Basic Prompt Parsing" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Yellow

Test-Component "Parse simple English prompt" {
    Push-Location $testDir
    try {
        & $setupScriptPath "Complete the task" --max-iterations 5 --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch "Complete the task") {
            throw "Prompt not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Parse Chinese prompt" {
    Push-Location $testDir
    try {
        & $setupScriptPath "完成任务" --max-iterations 5 --completion-promise "完成"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch "完成任务") {
            throw "Chinese prompt not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Parse mixed Chinese-English prompt" {
    Push-Location $testDir
    try {
        & $setupScriptPath "Complete 任务 with tests" --max-iterations 5 --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch "Complete 任务 with tests") {
            throw "Mixed prompt not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Write-Host ""

# ===== Test 2: Special Characters =====
Write-Host "Test 2: Special Characters" -ForegroundColor Yellow
Write-Host "--------------------------" -ForegroundColor Yellow

Test-Component "Parse prompt with quotes" {
    Push-Location $testDir
    try {
        & $setupScriptPath 'Say "hello world"' --max-iterations 5 --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch 'Say "hello world"') {
            throw "Prompt with quotes not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Parse prompt with special chars" {
    Push-Location $testDir
    try {
        $specialPrompt = "Test with & | < > $ @ # % symbols"
        & $setupScriptPath $specialPrompt --max-iterations 5 --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch [regex]::Escape($specialPrompt)) {
            throw "Prompt with special chars not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Parse prompt with newlines" {
    Push-Location $testDir
    try {
        $multilinePrompt = "Line 1`nLine 2`nLine 3"
        & $setupScriptPath $multilinePrompt --max-iterations 5 --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch "Line 1") {
            throw "Multiline prompt not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Write-Host ""

# ===== Test 3: Parameter Values =====
Write-Host "Test 3: Parameter Values" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow

Test-Component "Parse max-iterations parameter" {
    Push-Location $testDir
    try {
        & $setupScriptPath "Test" --max-iterations 10 --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        # Match either "max_iterations: 10" or "max_iterations:10" (with or without space)
        if ($content -notmatch "max_iterations:\s*10") {
            # Debug: show what we got
            Write-Host "   DEBUG: State file content:" -ForegroundColor Gray
            Write-Host $content -ForegroundColor Gray
            throw "Max iterations not set correctly (expected 10)"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Parse completion-promise parameter" {
    Push-Location $testDir
    try {
        & $setupScriptPath "Test" --max-iterations 5 --completion-promise "完成了"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        # Match completion_promise with the Chinese text, with or without quotes
        if ($content -notmatch "completion_promise") {
            # Debug: show what we got
            Write-Host "   DEBUG: State file content:" -ForegroundColor Gray
            Write-Host $content -ForegroundColor Gray
            throw "Completion promise field not found"
        }
        if ($content -notmatch "完成了") {
            Write-Host "   DEBUG: State file content:" -ForegroundColor Gray
            Write-Host $content -ForegroundColor Gray
            throw "Completion promise value '完成了' not found"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Default max-iterations value" {
    Push-Location $testDir
    try {
        & $setupScriptPath "Test" --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        # Should have a default value (0 means unlimited)
        if ($content -notmatch "max_iterations:\s*\d+") {
            throw "Max iterations not set with default value"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Write-Host ""

# ===== Test 4: Long Prompts =====
Write-Host "Test 4: Long Prompts" -ForegroundColor Yellow
Write-Host "--------------------" -ForegroundColor Yellow

Test-Component "Parse long English prompt" {
    Push-Location $testDir
    try {
        $longPrompt = "This is a very long prompt that contains many words and should test the ability of the argument parser to handle long strings without truncation or corruption. " * 5
        & $setupScriptPath $longPrompt --max-iterations 5 --completion-promise "done"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch "This is a very long prompt") {
            throw "Long prompt not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Parse long Chinese prompt" {
    Push-Location $testDir
    try {
        $longChinesePrompt = "这是一个很长的中文提示，包含很多字符，用于测试参数解析器处理长字符串的能力，不应该出现截断或损坏。" * 5
        & $setupScriptPath $longChinesePrompt --max-iterations 5 --completion-promise "完成"

        if (-not (Test-Path $testStateFile)) {
            throw "State file was not created"
        }

        $content = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($content -notmatch "这是一个很长的中文提示") {
            throw "Long Chinese prompt not found in state file"
        }
    } finally {
        Pop-Location
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Write-Host ""

# ===== Cleanup =====
Write-Host "Cleanup" -ForegroundColor Yellow
Write-Host "-------" -ForegroundColor Yellow

if (Test-Path $testDir) {
    Remove-Item $testDir -Recurse -Force
    Write-Host "✅ Test directory cleaned up" -ForegroundColor Green
}

Write-Host ""

# ===== Test Results =====
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests:  $totalTests" -ForegroundColor White
Write-Host "Passed:       $passedTests" -ForegroundColor Green
Write-Host "Failed:       $failedTests" -ForegroundColor Red
Write-Host "Pass Rate:    $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($failedTests -eq 0) {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests failed!" -ForegroundColor Red
    exit 1
}
