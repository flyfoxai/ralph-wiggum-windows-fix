#!/bin/bash
# WSL Hook Diagnostic Script

echo "=== WSL Hook Diagnostic ==="
echo ""

# Test different command formats
echo "Test 1: Direct sh execution"
sh /mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-router.sh <<< '{"transcript_path": "/tmp/test.jsonl"}' 2>&1 | head -3
echo "Exit code: $?"
echo ""

echo "Test 2: sh with quoted path"
sh "/mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-router.sh" <<< '{"transcript_path": "/tmp/test.jsonl"}' 2>&1 | head -3
echo "Exit code: $?"
echo ""

echo "Test 3: bash execution"
bash /mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-router.sh <<< '{"transcript_path": "/tmp/test.jsonl"}' 2>&1 | head -3
echo "Exit code: $?"
echo ""

echo "Test 4: Direct execution (with shebang)"
/mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-router.sh <<< '{"transcript_path": "/tmp/test.jsonl"}' 2>&1 | head -3
echo "Exit code: $?"
echo ""

echo "Test 5: Check file type"
file /mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-router.sh
echo ""

echo "Test 6: Check shebang"
head -1 /mnt/c/projects/ralph-wiggum-fix-win/hooks/stop-hook-router.sh | od -c
echo ""

echo "=== Diagnostic Complete ==="
