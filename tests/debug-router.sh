#!/bin/sh
# Debug script to test stop-hook-router.sh

set -x  # Enable debug mode

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "Current directory: $(pwd)"

# Check if stop-hook-posix.sh exists
POSIX_SCRIPT="$SCRIPT_DIR/../hooks/stop-hook-posix.sh"
echo "Looking for: $POSIX_SCRIPT"

if [ -f "$POSIX_SCRIPT" ]; then
    echo "✓ POSIX script found"
    ls -la "$POSIX_SCRIPT"
else
    echo "✗ POSIX script NOT found"
fi

# Test bash availability
if command -v bash >/dev/null 2>&1; then
    BASH_PATH=$(command -v bash)
    echo "✓ bash found at: $BASH_PATH"
else
    echo "✗ bash not found"
fi

# Test sh availability
if command -v sh >/dev/null 2>&1; then
    SH_PATH=$(command -v sh)
    echo "✓ sh found at: $SH_PATH"
else
    echo "✗ sh not found"
fi

# Try to execute the POSIX script with a test input
echo ""
echo "Testing POSIX script execution..."
echo '{"transcript_path":"test.jsonl"}' | sh "$POSIX_SCRIPT" 2>&1 || echo "Exit code: $?"
