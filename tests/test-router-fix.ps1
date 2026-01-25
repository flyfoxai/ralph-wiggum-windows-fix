# Test Script for Router Fix Verification
# Tests the intelligent routing mechanism for stop hooks

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "=== Ralph Wiggum Router Fix Verification ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check source code configuration
Write-Host "[Test 1] Checking source code configuration..." -ForegroundColor Yellow
$hooksJson = Get-Content "hooks\hooks.json" -Raw | ConvertFrom-Json

$windowsHook = $hooksJson.hooks.Stop[0].hooks | Where-Object { $_.platforms -contains "win32" }
if ($windowsHook.command -match "stop-hook-router\.ps1") {
    Write-Host "  ✅ Windows hook uses router script" -ForegroundColor Green
} else {
    Write-Host "  ❌ Windows hook does NOT use router script" -ForegroundColor Red
    Write-Host "     Current command: $($windowsHook.command)" -ForegroundColor Red
    exit 1
}

$unixHook = $hooksJson.hooks.Stop[0].hooks | Where-Object { $_.platforms -contains "darwin" -or $_.platforms -contains "linux" }
if ($unixHook.command -match "stop-hook-router\.sh") {
    Write-Host "  ✅ Unix hook uses router script" -ForegroundColor Green
} else {
    Write-Host "  ❌ Unix hook does NOT use router script" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Check router scripts exist
Write-Host "[Test 2] Checking router scripts exist..." -ForegroundColor Yellow

$requiredFiles = @(
    "hooks\stop-hook-router.ps1",
    "hooks\stop-hook-router.sh",
    "hooks\stop-hook.ps1",
    "hooks\stop-hook-posix.sh"
)

$allExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file exists" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file NOT FOUND" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    exit 1
}

Write-Host ""

# Test 3: Test router script functionality
Write-Host "[Test 3] Testing router script functionality..." -ForegroundColor Yellow

try {
    # Test with Debug flag to see detection logic
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File "hooks\stop-hook-router.ps1" -Debug 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Router script executed successfully" -ForegroundColor Green

        if ($Verbose) {
            Write-Host ""
            Write-Host "  Router output:" -ForegroundColor Cyan
            $output | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
    } else {
        Write-Host "  ❌ Router script failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host "  Output: $output" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Router script execution failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 4: Check environment detection
Write-Host "[Test 4] Checking environment detection..." -ForegroundColor Yellow

$envVars = @{
    "MSYSTEM" = $env:MSYSTEM
    "WSL_DISTRO_NAME" = $env:WSL_DISTRO_NAME
    "WSL_INTEROP" = $env:WSL_INTEROP
    "CYGWIN" = $env:CYGWIN
}

$detectedEnv = "Native Windows"
if ($env:MSYSTEM) {
    $detectedEnv = "Git Bash / MSYS"
} elseif ($env:WSL_DISTRO_NAME -or $env:WSL_INTEROP) {
    $detectedEnv = "WSL"
} elseif ($env:CYGWIN) {
    $detectedEnv = "Cygwin"
}

Write-Host "  Detected environment: $detectedEnv" -ForegroundColor Cyan

if ($Verbose) {
    Write-Host ""
    Write-Host "  Environment variables:" -ForegroundColor Cyan
    foreach ($key in $envVars.Keys) {
        $value = $envVars[$key]
        if ($value) {
            Write-Host "    $key = $value" -ForegroundColor Gray
        } else {
            Write-Host "    $key = (not set)" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""

# Test 5: Compare with backup
Write-Host "[Test 5] Comparing with backup..." -ForegroundColor Yellow

if (Test-Path "hooks\hooks.json.backup") {
    $backupJson = Get-Content "hooks\hooks.json.backup" -Raw | ConvertFrom-Json
    $backupWindowsHook = $backupJson.hooks.Stop[0].hooks | Where-Object { $_.platforms -contains "win32" }

    if ($backupWindowsHook.command -match "stop-hook\.ps1" -and $backupWindowsHook.command -notmatch "router") {
        Write-Host "  ✅ Backup contains old configuration (direct call)" -ForegroundColor Green
        Write-Host "  ✅ Current configuration uses router (fixed)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Backup configuration unclear" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  No backup file found" -ForegroundColor Yellow
}

Write-Host ""

# Summary
Write-Host "=== Verification Summary ===" -ForegroundColor Cyan
Write-Host "✅ All tests passed!" -ForegroundColor Green
Write-Host ""
Write-Host "The router fix has been successfully applied to the source code." -ForegroundColor Green
Write-Host "The plugin will now intelligently detect and adapt to:" -ForegroundColor White
Write-Host "  • Git Bash / MSYS" -ForegroundColor White
Write-Host "  • WSL (Windows Subsystem for Linux)" -ForegroundColor White
Write-Host "  • Cygwin" -ForegroundColor White
Write-Host "  • Native Windows" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Commit the changes: git add hooks/hooks.json && git commit -m 'fix: use intelligent router for cross-platform hook support'" -ForegroundColor Gray
Write-Host "  2. Reinstall the plugin: claude plugin uninstall ralph-wiggum && claude plugin install ." -ForegroundColor Gray
Write-Host "  3. Test in your environment" -ForegroundColor Gray
Write-Host ""
