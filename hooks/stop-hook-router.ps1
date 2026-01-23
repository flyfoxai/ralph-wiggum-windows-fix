# Smart Stop Hook Router (PowerShell)
# Automatically detects Windows environment and routes to the appropriate implementation
# Supports: Native Windows, WSL (called from Windows), Git Bash, Cygwin

param(
    [switch]$Debug
)

$ErrorActionPreference = "Stop"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-DebugInfo {
    param([string]$Message)
    if ($Debug) {
        Write-Host "🔍 $Message" -ForegroundColor Cyan
    }
}

function Detect-Environment {
    Write-DebugInfo "Detecting environment..."

    # Check for WSL environment variables
    if ($env:WSL_DISTRO_NAME -or $env:WSL_INTEROP) {
        Write-DebugInfo "Detected: WSL (via environment variables)"
        return "wsl"
    }

    # Check for Git Bash / MSYS
    if ($env:MSYSTEM) {
        Write-DebugInfo "Detected: Git Bash/MSYS (via MSYSTEM)"
        return "gitbash"
    }

    # Check for Cygwin
    if ($env:CYGWIN) {
        Write-DebugInfo "Detected: Cygwin (via CYGWIN env)"
        return "cygwin"
    }

    # Check if WSL is available
    $wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslAvailable) {
        Write-DebugInfo "WSL command available, checking if we should use it..."
        # Check if there's a default WSL distribution
        try {
            $wslList = wsl --list --quiet 2>&1
            if ($LASTEXITCODE -eq 0 -and $wslList) {
                Write-DebugInfo "WSL distributions found, but running in native Windows"
            }
        } catch {
            Write-DebugInfo "WSL check failed: $_"
        }
    }

    # Native Windows
    Write-DebugInfo "Detected: Native Windows"
    return "windows"
}

function Detect-Shell {
    Write-DebugInfo "Detecting available shells..."

    # Check for bash
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if ($bash) {
        Write-DebugInfo "Found: bash at $($bash.Source)"
        return "bash"
    }

    # Check for sh
    $sh = Get-Command sh -ErrorAction SilentlyContinue
    if ($sh) {
        Write-DebugInfo "Found: sh at $($sh.Source)"
        return "sh"
    }

    # Check for WSL
    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wsl) {
        Write-DebugInfo "Found: wsl at $($wsl.Source)"
        return "wsl"
    }

    Write-DebugInfo "No Unix shell found"
    return "none"
}

# Main routing logic
$env = Detect-Environment
$shell = Detect-Shell

Write-Host "🔍 Environment: $env | Shell: $shell" -ForegroundColor Yellow

switch ($env) {
    "windows" {
        # Native Windows - use PowerShell implementation
        Write-Host "📍 Using PowerShell stop-hook for native Windows" -ForegroundColor Green
        $psScript = Join-Path $ScriptDir "stop-hook.ps1"

        if (Test-Path $psScript) {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $psScript
            exit $LASTEXITCODE
        } else {
            Write-Error "PowerShell stop-hook not found: $psScript"
            exit 1
        }
    }

    "wsl" {
        # Running inside WSL but called from PowerShell (unusual case)
        Write-Host "📍 Detected WSL environment, using POSIX-compatible stop-hook" -ForegroundColor Green

        if ($shell -eq "wsl") {
            # Use WSL to execute the script
            $shScript = Join-Path $ScriptDir "stop-hook-posix.sh"
            wsl sh $shScript
            exit $LASTEXITCODE
        } elseif ($shell -eq "bash" -or $shell -eq "sh") {
            # Use available shell
            $shScript = Join-Path $ScriptDir "stop-hook-posix.sh"
            & $shell $shScript
            exit $LASTEXITCODE
        } else {
            Write-Error "No suitable shell found for WSL environment"
            exit 1
        }
    }

    "gitbash" {
        # Git Bash on Windows
        Write-Host "📍 Using POSIX-compatible stop-hook for Git Bash" -ForegroundColor Green

        if ($shell -eq "bash" -or $shell -eq "sh") {
            $shScript = Join-Path $ScriptDir "stop-hook-posix.sh"
            & $shell $shScript
            exit $LASTEXITCODE
        } else {
            # Fallback to PowerShell
            Write-Host "⚠️  No bash/sh found, falling back to PowerShell" -ForegroundColor Yellow
            $psScript = Join-Path $ScriptDir "stop-hook.ps1"
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $psScript
            exit $LASTEXITCODE
        }
    }

    "cygwin" {
        # Cygwin on Windows
        Write-Host "📍 Using POSIX-compatible stop-hook for Cygwin" -ForegroundColor Green

        if ($shell -eq "bash" -or $shell -eq "sh") {
            $shScript = Join-Path $ScriptDir "stop-hook-posix.sh"
            & $shell $shScript
            exit $LASTEXITCODE
        } else {
            Write-Error "No suitable shell found for Cygwin environment"
            exit 1
        }
    }

    default {
        # Unknown environment - try PowerShell
        Write-Host "⚠️  Unknown environment, attempting PowerShell implementation" -ForegroundColor Yellow
        $psScript = Join-Path $ScriptDir "stop-hook.ps1"

        if (Test-Path $psScript) {
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $psScript
            exit $LASTEXITCODE
        } else {
            Write-Error "No suitable stop-hook implementation found"
            exit 1
        }
    }
}
