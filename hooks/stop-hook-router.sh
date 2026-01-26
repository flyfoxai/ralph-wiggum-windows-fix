#!/bin/sh
# Smart Stop Hook Router
# Automatically detects environment and routes to the appropriate stop-hook implementation
# Supports: Windows (native), WSL1/2, Linux, macOS, Git Bash, Cygwin

set -eu

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Log file for debugging
LOG_FILE="${TMPDIR:-/tmp}/ralph-hook-router.log"

# Log function
log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null || true
}

log_debug "=== Router started ==="
log_debug "Script dir: $SCRIPT_DIR"
log_debug "Args: $*"
log_debug "PWD: $(pwd)"

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

log_debug "Environment: $ENV"
log_debug "Shell: $SHELL_TYPE"

# Log environment detection (to stderr for debugging)
echo "🔍 Environment detected: $ENV | Shell: $SHELL_TYPE" >&2

# Verify target script exists before exec
verify_script() {
    local script_path="$1"
    if [ ! -f "$script_path" ]; then
        echo "❌ Error: Stop hook script not found: $script_path" >&2
        log_debug "ERROR: Script not found: $script_path"
        exit 1
    fi
    if [ ! -r "$script_path" ]; then
        echo "❌ Error: Stop hook script not readable: $script_path" >&2
        log_debug "ERROR: Script not readable: $script_path"
        exit 1
    fi
    log_debug "Script verified: $script_path"
}

case "$ENV" in
    wsl)
        # WSL environment - use POSIX-compatible version with sh
        echo "📍 Using POSIX-compatible stop-hook for WSL" >&2
        TARGET_SCRIPT="$SCRIPT_DIR/stop-hook-posix.sh"
        verify_script "$TARGET_SCRIPT"
        log_debug "Executing: $SHELL_TYPE $TARGET_SCRIPT"
        if [ "$SHELL_TYPE" = "bash" ]; then
            exec bash "$TARGET_SCRIPT"
        else
            exec sh "$TARGET_SCRIPT"
        fi
        ;;

    linux|darwin)
        # Native Linux or macOS - prefer bash, fallback to POSIX
        echo "📍 Using stop-hook for $ENV" >&2
        if [ "$SHELL_TYPE" = "bash" ] && [ -f "$SCRIPT_DIR/stop-hook.sh" ]; then
            TARGET_SCRIPT="$SCRIPT_DIR/stop-hook.sh"
            verify_script "$TARGET_SCRIPT"
            log_debug "Executing: bash $TARGET_SCRIPT"
            exec bash "$TARGET_SCRIPT"
        else
            TARGET_SCRIPT="$SCRIPT_DIR/stop-hook-posix.sh"
            verify_script "$TARGET_SCRIPT"
            log_debug "Executing: sh $TARGET_SCRIPT"
            exec sh "$TARGET_SCRIPT"
        fi
        ;;

    gitbash)
        # Git Bash on Windows - use POSIX-compatible version
        echo "📍 Using POSIX-compatible stop-hook for Git Bash" >&2
        TARGET_SCRIPT="$SCRIPT_DIR/stop-hook-posix.sh"
        verify_script "$TARGET_SCRIPT"
        log_debug "Executing: $SHELL_TYPE $TARGET_SCRIPT"
        if [ "$SHELL_TYPE" = "bash" ]; then
            exec bash "$TARGET_SCRIPT"
        else
            exec sh "$TARGET_SCRIPT"
        fi
        ;;

    *)
        # Unknown environment - try POSIX version
        echo "⚠️  Unknown environment, attempting POSIX-compatible version" >&2
        TARGET_SCRIPT="$SCRIPT_DIR/stop-hook-posix.sh"
        verify_script "$TARGET_SCRIPT"
        log_debug "Executing: sh $TARGET_SCRIPT"
        exec sh "$TARGET_SCRIPT"
        ;;
esac
