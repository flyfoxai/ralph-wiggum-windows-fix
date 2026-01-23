#!/bin/sh
# Environment Detection Utility for Ralph Wiggum Plugin
# Detects the actual execution environment across all platforms
# Returns: windows|wsl|linux|darwin|gitbash|cygwin|unknown

set -eu

# Function to detect environment
detect_env() {
    # Check for WSL (highest priority for Linux detection)
    if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
        echo "wsl"
        return 0
    fi

    # Check /proc/version for WSL signature (WSL1 and WSL2)
    if [ -f /proc/version ]; then
        if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
            echo "wsl"
            return 0
        fi
    fi

    # Detect platform using uname
    UNAME_S=$(uname -s 2>/dev/null || echo "unknown")

    case "$UNAME_S" in
        Linux*)
            # Native Linux
            echo "linux"
            ;;
        Darwin*)
            # macOS
            echo "darwin"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            # Git Bash, Cygwin, MSYS2 on Windows
            if [ -n "${MSYSTEM:-}" ]; then
                # MSYS2/Git Bash
                echo "gitbash"
            elif echo "$UNAME_S" | grep -qi "cygwin"; then
                echo "cygwin"
            else
                echo "gitbash"
            fi
            ;;
        *)
            # Unknown environment
            echo "unknown"
            ;;
    esac
}

# Function to detect available shell
detect_shell() {
    if command -v bash >/dev/null 2>&1; then
        echo "bash"
    elif command -v sh >/dev/null 2>&1; then
        echo "sh"
    else
        echo "none"
    fi
}

# Function to detect PowerShell availability
detect_powershell() {
    if command -v pwsh >/dev/null 2>&1; then
        echo "pwsh"
    elif command -v powershell >/dev/null 2>&1; then
        echo "powershell"
    else
        echo "none"
    fi
}

# Main execution
case "${1:-env}" in
    env)
        detect_env
        ;;
    shell)
        detect_shell
        ;;
    powershell)
        detect_powershell
        ;;
    all)
        echo "Environment: $(detect_env)"
        echo "Shell: $(detect_shell)"
        echo "PowerShell: $(detect_powershell)"
        ;;
    *)
        echo "Usage: $0 {env|shell|powershell|all}"
        exit 1
        ;;
esac
