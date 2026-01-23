# Environment Detection Utility for Ralph Wiggum Plugin (PowerShell)
# Detects the actual execution environment on Windows
# Returns: windows|wsl|gitbash|cygwin|unknown

param(
    [Parameter(Position=0)]
    [ValidateSet('env', 'shell', 'powershell', 'all')]
    [string]$Mode = 'env'
)

$ErrorActionPreference = "Stop"

function Detect-Environment {
    # Check if running inside WSL
    if ($env:WSL_DISTRO_NAME -or $env:WSL_INTEROP) {
        return "wsl"
    }

    # Check for Git Bash / MSYS environment
    if ($env:MSYSTEM) {
        return "gitbash"
    }

    # Check for Cygwin
    if ($env:CYGWIN) {
        return "cygwin"
    }

    # Check if running in Windows Terminal with WSL
    if ($env:WT_SESSION -and $env:WSL_DISTRO_NAME) {
        return "wsl"
    }

    # Native Windows
    if ($env:OS -eq "Windows_NT") {
        return "windows"
    }

    return "unknown"
}

function Detect-Shell {
    # Check for bash
    $bashPath = Get-Command bash -ErrorAction SilentlyContinue
    if ($bashPath) {
        return "bash"
    }

    # Check for sh
    $shPath = Get-Command sh -ErrorAction SilentlyContinue
    if ($shPath) {
        return "sh"
    }

    # Check for WSL
    $wslPath = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslPath) {
        return "wsl"
    }

    return "none"
}

function Detect-PowerShell {
    # Check for pwsh (PowerShell 7+)
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshPath) {
        return "pwsh"
    }

    # Check for powershell (Windows PowerShell 5.1)
    $powershellPath = Get-Command powershell -ErrorAction SilentlyContinue
    if ($powershellPath) {
        return "powershell"
    }

    return "none"
}

# Main execution
switch ($Mode) {
    'env' {
        Detect-Environment
    }
    'shell' {
        Detect-Shell
    }
    'powershell' {
        Detect-PowerShell
    }
    'all' {
        Write-Output "Environment: $(Detect-Environment)"
        Write-Output "Shell: $(Detect-Shell)"
        Write-Output "PowerShell: $(Detect-PowerShell)"
    }
}
