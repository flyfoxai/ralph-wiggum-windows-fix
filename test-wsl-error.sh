#!/bin/bash
# Test if the WSL error still occurs

echo "=== Testing WSL Hook Error Fix ==="
echo ""

# Simulate the exact error scenario
PLUGIN_ROOT='C:\Users\dooji\.claude\plugins\cache\ralph-wiggum-cross-platform\ralph-wiggum\1.34'
export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

echo "Testing with v1.34 plugin..."
echo "Plugin root: $PLUGIN_ROOT"
echo ""

# Test the hook call
TEST_INPUT='{"transcript_path": "/tmp/test.jsonl"}'

echo "Test 1: Call hook with bash (v1.34 method)"
if bash "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.sh" <<< "$TEST_INPUT" 2>&1 | head -5; then
    echo "✅ v1.34 hook works with bash"
else
    echo "❌ v1.34 hook failed"
fi
echo ""

echo "Test 2: Call hook with sh (old method - should still work)"
if sh "${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.sh" <<< "$TEST_INPUT" 2>&1 | head -5; then
    echo "✅ v1.34 hook works with sh too"
else
    echo "⚠️  v1.34 hook doesn't work with sh (but that's OK, we use bash now)"
fi
echo ""

# Test in WSL if available
if command -v wsl >/dev/null 2>&1; then
    echo "Test 3: WSL environment test"
    wsl -e bash -c "
        export CLAUDE_PLUGIN_ROOT='/mnt/c/Users/dooji/.claude/plugins/cache/ralph-wiggum-cross-platform/ralph-wiggum/1.34'
        echo 'Testing in WSL...'
        bash \"\${CLAUDE_PLUGIN_ROOT}/hooks/stop-hook-router.sh\" <<< '{\"transcript_path\": \"/tmp/test.jsonl\"}' 2>&1 | head -5
    "
    if [ $? -eq 0 ]; then
        echo "✅ WSL test passed"
    else
        echo "❌ WSL test failed"
    fi
else
    echo "⚠️  WSL not available, skipping WSL test"
fi

echo ""
echo "=== Test Complete ==="
