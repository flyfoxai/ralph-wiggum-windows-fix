# Stop Hook 详细测试
# 测试 stop-hook.ps1 的所有核心功能

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
Write-Host "Stop Hook - Detailed Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$stopHookPath = Join-Path $PSScriptRoot "..\hooks\stop-hook.ps1"

# Helper function to call stop hook with proper stdin
function Invoke-StopHook {
    param(
        [string]$TranscriptPath,
        [string]$WorkingDirectory
    )

    $hookInput = @{
        transcript_path = $TranscriptPath
    } | ConvertTo-Json

    $tempJsonFile = Join-Path $WorkingDirectory "hook-input-$(Get-Random).json"
    Set-Content -Path $tempJsonFile -Value $hookInput -Encoding UTF8 -NoNewline

    try {
        # Use cmd to properly redirect stdin
        $result = cmd /c "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$stopHookPath`" < `"$tempJsonFile`"" 2>&1
        return @{
            Output = $result
            ExitCode = $LASTEXITCODE
        }
    } finally {
        Remove-Item $tempJsonFile -Force -ErrorAction SilentlyContinue
    }
}

# ===== Setup Test Environment =====
Write-Host "Setup Test Environment" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Yellow

$testDir = Join-Path $env:TEMP "ralph-test-$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
$testClaudeDir = Join-Path $testDir ".claude"
New-Item -ItemType Directory -Path $testClaudeDir -Force | Out-Null
$testStateFile = Join-Path $testClaudeDir "ralph-loop.local.md"
$testTranscriptFile = Join-Path $testDir "transcript.jsonl"

Write-Host "Test directory: $testDir" -ForegroundColor Gray
Write-Host ""

# ===== Test 1: No State File (Allow Exit) =====
Write-Host "Test 1: No State File" -ForegroundColor Yellow
Write-Host "---------------------" -ForegroundColor Yellow

Test-Component "Allow exit when no state file exists" {
    # Create test directory without state file
    Push-Location $testDir
    try {
        $hookResult = Invoke-StopHook -TranscriptPath $testTranscriptFile -WorkingDirectory $testDir

        if ($hookResult.ExitCode -ne 0) {
            throw "Expected exit code 0, got $($hookResult.ExitCode)"
        }
    } finally {
        Pop-Location
    }
}

Write-Host ""

# ===== Test 2: State File Parsing =====
Write-Host "Test 2: State File Parsing" -ForegroundColor Yellow
Write-Host "---------------------------" -ForegroundColor Yellow

Test-Component "Parse valid state file" {
    $stateContent = @"
---
iteration: 1
max_iterations: 5
completion_promise: "完成"
---
测试任务
"@
    Set-Content -Path $testStateFile -Value $stateContent -Encoding UTF8

    # Verify file was created
    if (-not (Test-Path $testStateFile)) {
        throw "State file was not created"
    }

    # Parse the file
    $content = Get-Content $testStateFile -Raw -Encoding UTF8
    $frontmatterMatch = [regex]::Match($content, '(?s)^---\r?\n(.*?)\r?\n---')

    if (-not $frontmatterMatch.Success) {
        throw "Failed to parse frontmatter"
    }

    $frontmatter = $frontmatterMatch.Groups[1].Value
    $iterationMatch = [regex]::Match($frontmatter, 'iteration:\s*(\d+)')

    if (-not $iterationMatch.Success) {
        throw "Failed to extract iteration"
    }

    $iteration = [int]$iterationMatch.Groups[1].Value
    if ($iteration -ne 1) {
        throw "Expected iteration 1, got $iteration"
    }
}

Test-Component "Handle corrupted state file (no frontmatter)" {
    $stateContent = "No frontmatter here"
    Set-Content -Path $testStateFile -Value $stateContent -Encoding UTF8

    Push-Location $testDir
    try {
        $hookResult = Invoke-StopHook -TranscriptPath $testTranscriptFile -WorkingDirectory $testDir

        # Hook should detect error and exit with non-zero code or show error message
        $hasError = ($hookResult.ExitCode -ne 0) -or ($hookResult.Output -match "State file corrupted")

        if (-not $hasError) {
            throw "Expected hook to detect corrupted state file. Exit code: $($hookResult.ExitCode), Output: $($hookResult.Output)"
        }
    } finally {
        Pop-Location
        # Clean up for next test
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Test-Component "Handle missing iteration field" {
    $stateContent = @"
---
max_iterations: 5
---
测试任务
"@
    Set-Content -Path $testStateFile -Value $stateContent -Encoding UTF8

    Push-Location $testDir
    try {
        $hookResult = Invoke-StopHook -TranscriptPath $testTranscriptFile -WorkingDirectory $testDir

        # Hook should detect error and exit with non-zero code or show error message
        $hasError = ($hookResult.ExitCode -ne 0) -or ($hookResult.Output -match "iteration field missing")

        if (-not $hasError) {
            throw "Expected hook to detect missing iteration field. Exit code: $($hookResult.ExitCode), Output: $($hookResult.Output)"
        }
    } finally {
        Pop-Location
        # Clean up for next test
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Write-Host ""

# ===== Test 3: Max Iterations Check =====
Write-Host "Test 3: Max Iterations Check" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Yellow

Test-Component "Exit when max iterations reached" {
    # Recreate state file for this test
    $stateContent = @"
---
iteration: 5
max_iterations: 5
completion_promise: "完成"
---
测试任务
"@
    Set-Content -Path $testStateFile -Value $stateContent -Encoding UTF8

    # Create a dummy transcript file (won't be read since max iterations reached)
    $transcriptContent = @"
{"role":"assistant","message":{"content":[{"type":"text","text":"dummy"}]}}
"@
    Set-Content -Path $testTranscriptFile -Value $transcriptContent -Encoding UTF8

    Push-Location $testDir
    try {
        $hookResult = Invoke-StopHook -TranscriptPath $testTranscriptFile -WorkingDirectory $testDir

        # Should exit 0 and remove state file
        if ($hookResult.ExitCode -ne 0) {
            throw "Expected exit code 0, got $($hookResult.ExitCode)"
        }

        if (Test-Path $testStateFile) {
            throw "State file should have been removed when max iterations reached"
        }
    } finally {
        Pop-Location
    }
}

Test-Component "Continue when under max iterations" {
    # Recreate state file for this test
    $stateContent = @"
---
iteration: 3
max_iterations: 5
completion_promise: "完成"
---
测试任务
"@
    Set-Content -Path $testStateFile -Value $stateContent -Encoding UTF8

    # Create a valid transcript file
    $transcriptContent = @"
{"role":"assistant","message":{"content":[{"type":"text","text":"继续工作中"}]}}
"@
    Set-Content -Path $testTranscriptFile -Value $transcriptContent -Encoding UTF8

    # Verify files exist before running hook
    if (-not (Test-Path $testStateFile)) {
        throw "State file was not created: $testStateFile"
    }
    if (-not (Test-Path $testTranscriptFile)) {
        throw "Transcript file was not created: $testTranscriptFile"
    }

    Push-Location $testDir
    try {
        $hookResult = Invoke-StopHook -TranscriptPath $testTranscriptFile -WorkingDirectory $testDir

        # Should return JSON with decision: "block"
        if ($hookResult.ExitCode -ne 0) {
            throw "Expected exit code 0, got $($hookResult.ExitCode). Output: $($hookResult.Output)"
        }

        # Parse JSON response
        $jsonLine = $hookResult.Output | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        if (-not $jsonLine) {
            throw "No JSON response found in output: $($hookResult.Output)"
        }

        $response = $jsonLine | ConvertFrom-Json
        if ($response.decision -ne "block") {
            throw "Expected decision 'block', got '$($response.decision)'"
        }

        # Verify iteration was incremented in state file
        if (-not (Test-Path $testStateFile)) {
            throw "State file was removed unexpectedly"
        }

        $updatedContent = Get-Content $testStateFile -Raw -Encoding UTF8
        if ($updatedContent -notmatch 'iteration:\s*4') {
            throw "Expected iteration to be incremented to 4, got: $updatedContent"
        }
    } finally {
        Pop-Location
    }
}

Write-Host ""

# ===== Test 4: Transcript File Parsing =====
Write-Host "Test 4: Transcript File Parsing" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow

Test-Component "Parse valid JSONL transcript" {
    $transcriptContent = @"
{"role":"user","message":{"content":[{"type":"text","text":"测试"}]}}
{"role":"assistant","message":{"content":[{"type":"text","text":"回复1"}]}}
{"role":"assistant","message":{"content":[{"type":"text","text":"回复2"}]}}
"@
    Set-Content -Path $testTranscriptFile -Value $transcriptContent -Encoding UTF8

    # Read and parse
    $lines = Get-Content $testTranscriptFile -Encoding UTF8
    $assistantLines = @($lines | Where-Object { $_ -match '"role"\s*:\s*"assistant"' })

    if ($assistantLines.Count -ne 2) {
        throw "Expected 2 assistant messages, got $($assistantLines.Count)"
    }

    $lastLine = $assistantLines[$assistantLines.Count - 1]
    $lastMessage = $lastLine | ConvertFrom-Json
    $text = $lastMessage.message.content[0].text

    if ($text -ne "回复2") {
        throw "Expected '回复2', got '$text'"
    }
}

Test-Component "Handle missing transcript file" {
    # Recreate state file for this test
    $stateContent = @"
---
iteration: 1
max_iterations: 5
completion_promise: "完成"
---
测试任务
"@
    Set-Content -Path $testStateFile -Value $stateContent -Encoding UTF8

    # Remove transcript file
    if (Test-Path $testTranscriptFile) {
        Remove-Item $testTranscriptFile -Force
    }

    Push-Location $testDir
    try {
        $hookResult = Invoke-StopHook -TranscriptPath $testTranscriptFile -WorkingDirectory $testDir

        # Hook should detect error and exit with non-zero code or show error message
        $hasError = ($hookResult.ExitCode -ne 0) -or ($hookResult.Output -match "Transcript file not found")

        if (-not $hasError) {
            throw "Expected hook to detect missing transcript file. Exit code: $($hookResult.ExitCode), Output: $($hookResult.Output)"
        }
    } finally {
        Pop-Location
        # Clean up for next test
        if (Test-Path $testStateFile) {
            Remove-Item $testStateFile -Force
        }
    }
}

Write-Host ""

# ===== Test 5: Promise Detection =====
Write-Host "Test 5: Promise Detection" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow

Test-Component "Detect completion promise in output" {
    $output = "工作进行中 <promise>完成</promise> 任务完成"
    $promiseMatch = [regex]::Match($output, '<promise>(.*?)</promise>')

    if (-not $promiseMatch.Success) {
        throw "Failed to detect promise tag"
    }

    $promiseText = $promiseMatch.Groups[1].Value.Trim()
    if ($promiseText -ne "完成") {
        throw "Expected '完成', got '$promiseText'"
    }
}

Test-Component "No false positive for promise detection" {
    $output = "工作进行中，没有完成标记"
    $promiseMatch = [regex]::Match($output, '<promise>(.*?)</promise>')

    if ($promiseMatch.Success) {
        throw "Should not detect promise when none exists"
    }
}

Write-Host ""

# ===== Test 6: Iteration Update =====
Write-Host "Test 6: Iteration Update" -ForegroundColor Yellow
Write-Host "------------------------" -ForegroundColor Yellow

Test-Component "Increment iteration count" {
    $stateContent = @"
---
iteration: 2
max_iterations: 5
completion_promise: "完成"
---
测试任务
"@
    # Test the regex replacement
    $newContent = $stateContent -replace 'iteration:\s*\d+', "iteration: 3"

    if ($newContent -notmatch 'iteration:\s*3') {
        throw "Failed to increment iteration"
    }

    if ($newContent -match 'iteration:\s*2') {
        throw "Old iteration value still present"
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
