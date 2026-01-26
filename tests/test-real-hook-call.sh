#!/bin/bash
# Test real hook call scenario - exactly as Claude Code calls it

echo "=== Real Hook Call Test ==="
echo "This test simulates the exact way Claude Code calls the stop hook"
echo ""

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

echo "Plugin root: $PLUGIN_ROOT"
echo ""

# Test 1: Simulate exact hook call from hooks.json
echo "Test 1: Exact hooks.json call (bash)"
TEST_INPUT='{"transcript_path": "/tmp/test-transcript.jsonl"}'

if bash "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.sh" <<< "$TEST_INPUT" 2>&1 | head -10; then
    echo "✅ Test 1 PASSED"
else
    EXIT_CODE=$?
    echo "❌ Test 1 FAILED with exit code: $EXIT_CODE"
fi
echo ""

# Test 2: Old problematic call (sh) - should we keep this working?
echo "Test 2: Old call method (sh) - for compatibility"
if sh "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.sh" <<< "$TEST_INPUT" 2>&1 | head -10; then
    echo "✅ Test 2 PASSED (sh still works)"
else
    EXIT_CODE=$?
    echo "⚠️  Test 2 FAILED (sh doesn't work, but bash does)"
fi
echo ""

# Test 3: Check log file
echo "Test 3: Log file verification"
LOG_FILE="${TMPDIR:-/tmp}/ralph-hook-router.log"
if [ -f "$LOG_FILE" ]; then
    echo "✅ Log file exists: $LOG_FILE"
    echo "Last 5 log entries:"
    tail -5 "$LOG_FILE"
else
    echo "⚠️  Log file not found (may not have been created yet)"
fi
echo ""

echo "=== Test Complete ==="
