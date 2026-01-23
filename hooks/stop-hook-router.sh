#!/bin/sh
# Smart Stop Hook Router
# Automatically detects environment and routes to the appropriate stop-hook implementation
# Supports: Windows (native), WSL1/2, Linux, macOS, Git Bash, Cygwin

set -eu

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Detect environment
detect_environment() {
    # Check for WSL
    if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
        echo "wsl"
        return
    fi

    if [ -f /proc/version ]; then
        if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
            echo "wsl"
            return
        fi
    fi

    # Detect platform
    UNAME_S=$(uname -s 2>/dev/null || echo "unknown")

    case "$UNAME_S" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "darwin"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "gitbash"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect available shell
detect_shell() {
    if command -v bash >/dev/null 2>&1; then
        echo "bash"
    elif command -v sh >/dev/null 2>&1; then
        echo "sh"
    else
        echo "none"
    fi
}

# Main routing logic
ENV=$(detect_environment)
SHELL_TYPE=$(detect_shell)

# Log environment detection (to stderr for debugging)
echo "🔍 Environment detected: $ENV | Shell: $SHELL_TYPE" >&2

case "$ENV" in
    wsl)
        # WSL environment - use POSIX-compatible version with sh
        echo "📍 Using POSIX-compatible stop-hook for WSL" >&2
        if [ "$SHELL_TYPE" = "bash" ]; then
            exec bash "$SCRIPT_DIR/stop-hook-posix.sh"
        else
            exec sh "$SCRIPT_DIR/stop-hook-posix.sh"
        fi
        ;;

    linux|darwin)
        # Native Linux or macOS - prefer bash, fallback to POSIX
        echo "📍 Using stop-hook for $ENV" >&2
        if [ "$SHELL_TYPE" = "bash" ] && [ -f "$SCRIPT_DIR/stop-hook.sh" ]; then
            exec bash "$SCRIPT_DIR/stop-hook.sh"
        else
            exec sh "$SCRIPT_DIR/stop-hook-posix.sh"
        fi
        ;;

    gitbash)
        # Git Bash on Windows - use POSIX-compatible version
        echo "📍 Using POSIX-compatible stop-hook for Git Bash" >&2
        if [ "$SHELL_TYPE" = "bash" ]; then
            exec bash "$SCRIPT_DIR/stop-hook-posix.sh"
        else
            exec sh "$SCRIPT_DIR/stop-hook-posix.sh"
        fi
        ;;

    *)
        # Unknown environment - try POSIX version
        echo "⚠️  Unknown environment, attempting POSIX-compatible version" >&2
        exec sh "$SCRIPT_DIR/stop-hook-posix.sh"
        ;;
esac
