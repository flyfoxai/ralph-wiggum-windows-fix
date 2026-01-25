# Diagnose Stop Hook Error
# This script helps identify the cause of the "/usr/bin/sh: cannot execute binary file" error

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stop Hook Error Diagnosis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check environment
Write-Host "1. Environment Detection" -ForegroundColor Yellow
Write-Host "   Platform: $($PSVersionTable.Platform)" -ForegroundColor Gray
Write-Host "   OS: $($PSVersionTable.OS)" -ForegroundColor Gray
Write-Host "   PSVersion: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host ""

# 2. Check for sh command
Write-Host "2. Shell Command Detection" -ForegroundColor Yellow
$sh = Get-Command sh -ErrorAction SilentlyContinue
if ($sh) {
    Write-Host "   ✓ sh found: $($sh.Source)" -ForegroundColor Green
    Write-Host "   Type: $($sh.CommandType)" -ForegroundColor Gray

    # Try to get version
    try {
        $shVersion = & sh --version 2>&1
        Write-Host "   Version: $shVersion" -ForegroundColor Gray
    } catch {
        Write-Host "   Version check failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ sh not found" -ForegroundColor Red
}
Write-Host ""

# 3. Check environment variables
Write-Host "3. Environment Variables" -ForegroundColor Yellow
$envVars = @("MSYSTEM", "WSL_DISTRO_NAME", "WSL_INTEROP", "CYGWIN")
foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        Write-Host "   $var = $value" -ForegroundColor Green
    } else {
        Write-Host "   $var = (not set)" -ForegroundColor Gray
    }
}
Write-Host ""

# 4. Test router script
Write-Host "4. Testing Router Script" -ForegroundColor Yellow
$routerScript = Join-Path $PSScriptRoot "..\hooks\stop-hook-router.ps1"
if (Test-Path $routerScript) {
    Write-Host "   ✓ Router script exists: $routerScript" -ForegroundColor Green

    # Run with debug flag
    Write-Host "   Running router with debug..." -ForegroundColor Gray
    try {
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $routerScript -Debug 2>&1 | ForEach-Object {
            Write-Host "     $_" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "   ✗ Router failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ Router script not found" -ForegroundColor Red
}
Write-Host ""

# 5. Test POSIX script directly
Write-Host "5. Testing POSIX Script Directly" -ForegroundColor Yellow
$posixScript = Join-Path $PSScriptRoot "..\hooks\stop-hook-posix.sh"
if (Test-Path $posixScript) {
    Write-Host "   ✓ POSIX script exists: $posixScript" -ForegroundColor Green

    # Try to execute with sh
    if ($sh) {
        Write-Host "   Testing execution with sh..." -ForegroundColor Gray

        # Create a test input
        $testInput = @{
            transcript_path = "test.jsonl"
        } | ConvertTo-Json

        try {
            $result = $testInput | & sh $posixScript 2>&1
            Write-Host "   Result: $result" -ForegroundColor Gray
        } catch {
            Write-Host "   ✗ Execution failed: $_" -ForegroundColor Red
            Write-Host "   Error details: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ✗ POSIX script not found" -ForegroundColor Red
}
Write-Host ""

# 6. Check hooks configuration
Write-Host "6. Hooks Configuration" -ForegroundColor Yellow
$hooksJson = Join-Path $PSScriptRoot "..\hooks\hooks.json"
if (Test-Path $hooksJson) {
    Write-Host "   ✓ hooks.json exists" -ForegroundColor Green
    $hooks = Get-Content $hooksJson | ConvertFrom-Json
    $stopHooks = $hooks.hooks.Stop
    Write-Host "   Number of Stop hook groups: $($stopHooks.Count)" -ForegroundColor Gray

    foreach ($group in $stopHooks) {
        Write-Host "   Hook group has $($group.hooks.Count) hooks:" -ForegroundColor Gray
        foreach ($hook in $group.hooks) {
            Write-Host "     - Platform: $($hook.platforms -join ', ')" -ForegroundColor DarkGray
            Write-Host "       Command: $($hook.command)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "   ✗ hooks.json not found" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnosis Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
