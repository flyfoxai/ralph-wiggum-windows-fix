#!/bin/sh
# Test WSL stop hook execution

echo "=== WSL Stop Hook Test ==="
echo ""

# Test 1: Check if we're in WSL
echo "Test 1: Environment Detection"
if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
    echo "  ✓ Running in WSL: $WSL_DISTRO_NAME"
else
    echo "  ✗ Not in WSL"
fi
echo ""

# Test 2: Check sh availability
echo "Test 2: Shell Availability"
if command -v sh >/dev/null 2>&1; then
    echo "  ✓ sh is available"
    sh --version 2>&1 | head -1 || echo "  (version check failed)"
else
    echo "  ✗ sh not found"
fi
echo ""

# Test 3: Check bash availability
echo "Test 3: Bash Availability"
if command -v bash >/dev/null 2>&1; then
    echo "  ✓ bash is available"
    bash --version | head -1
else
    echo "  ✗ bash not found"
fi
echo ""

# Test 4: Test script execution
echo "Test 4: Script Execution Test"
SCRIPT_DIR=$(cd "$(dirname "$0")/../hooks" && pwd)
echo "  Script directory: $SCRIPT_DIR"

if [ -f "$SCRIPT_DIR/stop-hook-posix.sh" ]; then
    echo "  ✓ stop-hook-posix.sh exists"

    # Try to execute with sh
    echo "  Testing execution with sh..."
    if sh "$SCRIPT_DIR/stop-hook-posix.sh" <<EOF 2>&1 | head -5
{"transcript_path": "/tmp/test.jsonl"}
EOF
    then
        echo "  ✓ Execution successful"
    else
        echo "  ✗ Execution failed with exit code: $?"
    fi
else
    echo "  ✗ stop-hook-posix.sh not found"
fi
echo ""

# Test 5: Check file permissions
echo "Test 5: File Permissions"
if [ -f "$SCRIPT_DIR/stop-hook-posix.sh" ]; then
    ls -l "$SCRIPT_DIR/stop-hook-posix.sh"
    if [ -x "$SCRIPT_DIR/stop-hook-posix.sh" ]; then
        echo "  ✓ File is executable"
    else
        echo "  ✗ File is not executable"
    fi
else
    echo "  ✗ File not found"
fi
echo ""

echo "=== Test Complete ==="
