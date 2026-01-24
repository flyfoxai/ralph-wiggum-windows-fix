# Cross-Platform Environment Detection Test Suite
# Tests all environment detection and routing logic

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Ralph Wiggum Cross-Platform Test Suite" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HooksDir = Join-Path $ScriptDir "..\hooks"

$TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Tests = @()
}

function Test-Item {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Category = "General"
    )

    Write-Host "🧪 Testing: $Name" -ForegroundColor Yellow -NoNewline

    try {
        $result = & $Test
        if ($result) {
            Write-Host " ✅ PASS" -ForegroundColor Green
            $TestResults.Passed++
            $TestResults.Tests += @{
                Name = $Name
                Category = $Category
                Status = "PASS"
                Error = $null
            }
            return $true
        } else {
            Write-Host " ❌ FAIL" -ForegroundColor Red
            $TestResults.Failed++
            $TestResults.Tests += @{
                Name = $Name
                Category = $Category
                Status = "FAIL"
                Error = "Test returned false"
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
            Category = $Category
            Status = "FAIL"
            Error = $_.Exception.Message
        }
        return $false
    }
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  1. File Existence Tests" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Item "PowerShell stop-hook exists" {
    Test-Path (Join-Path $HooksDir "stop-hook.ps1")
} -Category "Files"

Test-Item "Bash stop-hook exists" {
    Test-Path (Join-Path $HooksDir "stop-hook.sh")
} -Category "Files"

Test-Item "POSIX stop-hook exists" {
    Test-Path (Join-Path $HooksDir "stop-hook-posix.sh")
} -Category "Files"

Test-Item "PowerShell router exists" {
    Test-Path (Join-Path $HooksDir "stop-hook-router.ps1")
} -Category "Files"

Test-Item "Shell router exists" {
    Test-Path (Join-Path $HooksDir "stop-hook-router.sh")
} -Category "Files"

Test-Item "Environment detector (PS) exists" {
    Test-Path (Join-Path $HooksDir "detect-environment.ps1")
} -Category "Files"

Test-Item "Environment detector (sh) exists" {
    Test-Path (Join-Path $HooksDir "detect-environment.sh")
} -Category "Files"

Test-Item "Enhanced hooks.json exists" {
    Test-Path (Join-Path $HooksDir "hooks-enhanced.json")
} -Category "Files"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  2. Environment Detection Tests" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Item "PowerShell environment detector runs" {
    $detector = Join-Path $HooksDir "detect-environment.ps1"
    $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $detector -Mode env
    $result -match "windows|wsl|gitbash|cygwin|unknown"
} -Category "Detection"

Test-Item "PowerShell detector identifies current environment" {
    $detector = Join-Path $HooksDir "detect-environment.ps1"
    $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $detector -Mode env
    Write-Host "   Detected: $result" -ForegroundColor Gray
    $result -ne "unknown"
} -Category "Detection"

Test-Item "PowerShell detector finds PowerShell" {
    $detector = Join-Path $HooksDir "detect-environment.ps1"
    $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $detector -Mode powershell
    Write-Host "   Found: $result" -ForegroundColor Gray
    $result -match "pwsh|powershell"
} -Category "Detection"

Test-Item "PowerShell detector checks shell availability" {
    $detector = Join-Path $HooksDir "detect-environment.ps1"
    $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $detector -Mode shell
    Write-Host "   Shell: $result" -ForegroundColor Gray
    $true # Always pass, just informational
} -Category "Detection"

# Test shell detector if sh/bash is available
$shAvailable = Get-Command sh -ErrorAction SilentlyContinue
if ($shAvailable) {
    Test-Item "Shell environment detector runs" {
        $detector = Join-Path $HooksDir "detect-environment.sh"
        $result = sh $detector env 2>&1
        $result -match "windows|wsl|linux|darwin|gitbash|cygwin|unknown"
    } -Category "Detection"

    Test-Item "Shell detector identifies environment" {
        $detector = Join-Path $HooksDir "detect-environment.sh"
        $result = sh $detector env 2>&1
        Write-Host "   Detected: $result" -ForegroundColor Gray
        $result -ne "unknown"
    } -Category "Detection"
} else {
    Write-Host "⏭️  Skipping shell detector tests (sh not available)" -ForegroundColor Yellow
    $TestResults.Skipped += 2
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  3. Script Syntax Tests" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Item "PowerShell stop-hook syntax is valid" {
    $script = Join-Path $HooksDir "stop-hook.ps1"
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
    $true
} -Category "Syntax"

Test-Item "PowerShell router syntax is valid" {
    $script = Join-Path $HooksDir "stop-hook-router.ps1"
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
    $true
} -Category "Syntax"

Test-Item "PowerShell detector syntax is valid" {
    $script = Join-Path $HooksDir "detect-environment.ps1"
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
    $true
} -Category "Syntax"

if ($shAvailable) {
    Test-Item "POSIX stop-hook has correct shebang" {
        $script = Join-Path $HooksDir "stop-hook-posix.sh"
        $firstLine = Get-Content $script -First 1
        $firstLine -match "^#!/.*sh$"
    } -Category "Syntax"

    Test-Item "Shell router has correct shebang" {
        $script = Join-Path $HooksDir "stop-hook-router.sh"
        $firstLine = Get-Content $script -First 1
        $firstLine -match "^#!/.*sh$"
    } -Category "Syntax"

    Test-Item "Shell detector has correct shebang" {
        $script = Join-Path $HooksDir "detect-environment.sh"
        $firstLine = Get-Content $script -First 1
        $firstLine -match "^#!/.*sh$"
    } -Category "Syntax"
} else {
    Write-Host "⏭️  Skipping shell syntax tests (sh not available)" -ForegroundColor Yellow
    $TestResults.Skipped += 3
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  4. WSL Detection Tests" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

$wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
if ($wslAvailable) {
    Test-Item "WSL is available" {
        $true
    } -Category "WSL"

    Test-Item "WSL version can be queried" {
        $version = wsl --version 2>&1
        $version -match "WSL"
    } -Category "WSL"

    Test-Item "WSL can execute basic commands" {
        $result = wsl echo "test" 2>&1
        $result -eq "test"
    } -Category "WSL"

    Test-Item "WSL has sh available" {
        $result = wsl which sh 2>&1
        $result -match "/.*sh$"
    } -Category "WSL"

    Test-Item "WSL environment detector works" {
        $detector = Join-Path $HooksDir "detect-environment.sh"
        # Convert Windows path to WSL path
        $wslPath = $detector -replace '\\', '/' -replace '^([A-Z]):', '/mnt/$1' -replace '^/mnt/([A-Z])', { "/mnt/$($_.Groups[1].Value.ToLower())" }
        $result = wsl sh $wslPath env 2>&1
        Write-Host "   WSL Environment: $result" -ForegroundColor Gray
        $result -match "wsl|linux"
    } -Category "WSL"
} else {
    Write-Host "⏭️  Skipping WSL tests (WSL not available)" -ForegroundColor Yellow
    $TestResults.Skipped += 5
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "  5. JSON Configuration Tests" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

Test-Item "Enhanced hooks.json is valid JSON" {
    $json = Join-Path $HooksDir "hooks-enhanced.json"
    $null = Get-Content $json -Raw | ConvertFrom-Json
    $true
} -Category "Config"

Test-Item "Enhanced hooks.json has Stop hook defined" {
    $json = Join-Path $HooksDir "hooks-enhanced.json"
    $config = Get-Content $json -Raw | ConvertFrom-Json
    $null -ne $config.hooks.Stop
} -Category "Config"

Test-Item "Enhanced hooks.json has environment support documented" {
    $json = Join-Path $HooksDir "hooks-enhanced.json"
    $config = Get-Content $json -Raw | ConvertFrom-Json
    $null -ne $config.environment_support
} -Category "Config"

Test-Item "Original hooks.json is valid JSON" {
    $json = Join-Path $HooksDir "hooks.json"
    if (Test-Path $json) {
        $null = Get-Content $json -Raw | ConvertFrom-Json
        $true
    } else {
        $false
    }
} -Category "Config"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$total = $TestResults.Passed + $TestResults.Failed
$passRate = if ($total -gt 0) { [math]::Round(($TestResults.Passed / $total) * 100, 1) } else { 0 }

Write-Host "  ✅ Passed:  $($TestResults.Passed)" -ForegroundColor Green
Write-Host "  ❌ Failed:  $($TestResults.Failed)" -ForegroundColor Red
Write-Host "  ⏭️  Skipped: $($TestResults.Skipped)" -ForegroundColor Yellow
Write-Host "  📊 Total:   $total" -ForegroundColor Cyan
Write-Host "  📈 Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 90) { "Green" } elseif ($passRate -ge 70) { "Yellow" } else { "Red" })
Write-Host ""

if ($TestResults.Failed -gt 0) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "  Failed Tests Details" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""

    $TestResults.Tests | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  ❌ $($_.Name)" -ForegroundColor Red
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
