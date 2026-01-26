# Test Critical Fixes
# Validates the Phase 1 and Phase 2 critical fixes

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Critical Fixes Validation Test Suite" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibDir = Join-Path $ScriptDir "..\lib"
$SmartRalphScript = Join-Path $LibDir "smart-ralph-loop-improved.ps1"

$TestResults = @{
    Passed = 0
    Failed = 0
    Tests = @()
}

function Test-Fix {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$FixNumber
    )

    Write-Host "Testing Fix #$FixNumber : $Name" -ForegroundColor Yellow -NoNewline

    try {
        $result = & $Test
        if ($result) {
            Write-Host " ✅ PASS" -ForegroundColor Green
            $TestResults.Passed++
            $TestResults.Tests += @{
                Name = $Name
                FixNumber = $FixNumber
                Status = "PASS"
            }
            return $true
        } else {
            Write-Host " ❌ FAIL" -ForegroundColor Red
            $TestResults.Failed++
            $TestResults.Tests += @{
                Name = $Name
                FixNumber = $FixNumber
                Status = "FAIL"
            }
            return $false
        }
    } catch {
        Write-Host " ❌ FAIL" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "   Error: $_" -ForegroundColor Red
        }
        $TestResults.Failed++
        $TestResults.Tests += @{
            Name = $Name
            FixNumber = $FixNumber
            Status = "FAIL"
            Error = $_.Exception.Message
        }
        return $false
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  Fix #1: Mutex Resource Cleanup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Fix "Script has finally block in Start-SmartRalphLoop" {
    $content = Get-Content $SmartRalphScript -Raw
    $content -match 'finally\s*\{[^}]*StateLock[^}]*Dispose'
} -FixNumber "1"

Test-Fix "Mutex is set to null after disposal" {
    $content = Get-Content $SmartRalphScript -Raw
    $content -match 'StateLock\s*=\s*\$null'
} -FixNumber "1"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  Fix #2: State File Concurrent Access" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Fix "Get-RalphState uses mutex lock" {
    $content = Get-Content $SmartRalphScript -Raw
    # Check if Get-RalphState function contains WaitOne
    $content -match 'function Get-RalphState\s*\{[^}]*WaitOne'
} -FixNumber "2"

Test-Fix "Get-RalphState has finally block with ReleaseMutex" {
    $content = Get-Content $SmartRalphScript -Raw
    # Use singleline mode to match across lines
    $content -match '(?s)function Get-RalphState\s*\{.*?finally\s*\{.*?ReleaseMutex'
} -FixNumber "2"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  Fix #3: Event Handler Registration" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Fix "Event registration checks for existing subscription" {
    $content = Get-Content $SmartRalphScript -Raw
    $content -match 'Get-EventSubscriber.*PowerShell\.Exiting'
} -FixNumber "3"

Test-Fix "Event registration has proper error handling" {
    $content = Get-Content $SmartRalphScript -Raw
    $content -match 'if\s*\(\s*-not\s+\$existing\s*\)'
} -FixNumber "3"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  Fix #4: Task Symbol Conflict" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Fix "Pending pattern no longer includes ✗" {
    $content = Get-Content $SmartRalphScript -Raw
    # Check that ✗ is NOT in the pending pattern
    $pendingLine = ($content -split "`n" | Where-Object { $_ -match '\$isPending.*match' })[0]
    if ($pendingLine) {
        $pendingLine -notmatch '✗'
    } else {
        $false
    }
} -FixNumber "4"

Test-Fix "Completed pattern includes × symbol" {
    $content = Get-Content $SmartRalphScript -Raw
    # Check for the × character in the completed pattern
    $content -match '\$isCompleted.*\[☒✓×\]'
} -FixNumber "4"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  Fix #5: Max Iterations Hard Limit" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Fix "Max iterations throws exception instead of warning" {
    $content = Get-Content $SmartRalphScript -Raw
    $content -match 'if\s*\(\s*\$MaxIterations\s*-gt\s*1000\s*\)\s*\{[^}]*throw'
} -FixNumber "5"

Test-Fix "Exception message mentions cannot exceed" {
    $content = Get-Content $SmartRalphScript -Raw
    $content -match 'cannot exceed 1000'
} -FixNumber "5"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$total = $TestResults.Passed + $TestResults.Failed
$passRate = if ($total -gt 0) { [math]::Round(($TestResults.Passed / $total) * 100, 1) } else { 0 }

Write-Host "  ✅ Passed:  $($TestResults.Passed)" -ForegroundColor Green
Write-Host "  ❌ Failed:  $($TestResults.Failed)" -ForegroundColor Red
Write-Host "  📊 Total:   $total" -ForegroundColor Cyan
Write-Host "  📈 Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } elseif ($passRate -ge 80) { "Yellow" } else { "Red" })
Write-Host ""

if ($TestResults.Failed -gt 0) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "  Failed Tests Details" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""

    $TestResults.Tests | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  ❌ Fix #$($_.FixNumber): $($_.Name)" -ForegroundColor Red
        if ($_.Error) {
            Write-Host "     Error: $($_.Error)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Exit with appropriate code
if ($TestResults.Failed -gt 0) {
    exit 1
} else {
    exit 0
}
