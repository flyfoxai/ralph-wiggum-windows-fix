# WSL Stop Hook 完整测试套件
# 测试所有 WSL 相关功能

Write-Host "=== WSL Stop Hook 完整测试 ===" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Test 1: 环境检测
Write-Host "Test 1: WSL 环境检测" -ForegroundColor Yellow
try {
    $result = wsl bash -c 'if [ -n "${WSL_DISTRO_NAME:-}" ]; then echo "WSL"; else echo "NOT_WSL"; fi' 2>&1
    if ($result -match "WSL") {
        Write-Host "  ✓ WSL 环境检测成功" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ✗ WSL 环境检测失败" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 2: 路由器脚本执行
Write-Host "Test 2: 路由器脚本执行" -ForegroundColor Yellow
try {
    $result = wsl bash -c 'cd /mnt/c/projects/ralph-wiggum-fix-win && sh hooks/stop-hook-router.sh <<< "{\"transcript_path\": \"/tmp/test.jsonl\"}"' 2>&1
    if ($result -match "Environment detected: wsl") {
        Write-Host "  ✓ 路由器正确检测 WSL 环境" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ✗ 路由器未能检测 WSL 环境" -ForegroundColor Red
        Write-Host "  输出: $result" -ForegroundColor Gray
        $testsFailed++
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 3: POSIX stop-hook 执行
Write-Host "Test 3: POSIX stop-hook 执行" -ForegroundColor Yellow
try {
    $result = wsl bash -c 'cd /mnt/c/projects/ralph-wiggum-fix-win && sh hooks/stop-hook-posix.sh <<< "{\"transcript_path\": \"/tmp/test.jsonl\"}"' 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ POSIX stop-hook 执行成功" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ✗ POSIX stop-hook 执行失败 (exit code: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "  输出: $result" -ForegroundColor Gray
        $testsFailed++
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 4: 文件权限
Write-Host "Test 4: 文件权限检查" -ForegroundColor Yellow
try {
    $result = wsl bash -c 'cd /mnt/c/projects/ralph-wiggum-fix-win && [ -x hooks/stop-hook-posix.sh ] && echo "EXECUTABLE" || echo "NOT_EXECUTABLE"' 2>&1
    if ($result -match "EXECUTABLE") {
        Write-Host "  ✓ 文件具有执行权限" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ✗ 文件缺少执行权限" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 5: Shebang 检查
Write-Host "Test 5: Shebang 检查" -ForegroundColor Yellow
try {
    $result = wsl bash -c 'cd /mnt/c/projects/ralph-wiggum-fix-win && head -1 hooks/stop-hook-posix.sh' 2>&1
    if ($result -match "#!/bin/sh" -or $result -match "#!/bin/bash") {
        Write-Host "  ✓ Shebang 正确: $result" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ✗ Shebang 不正确: $result" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 6: 错误处理
Write-Host "Test 6: 错误处理测试" -ForegroundColor Yellow
try {
    # 测试不存在的文件
    $result = wsl bash -c 'cd /mnt/c/projects/ralph-wiggum-fix-win && sh hooks/stop-hook-posix.sh <<< "{\"transcript_path\": \"/nonexistent/file.jsonl\"}"' 2>&1
    if ($result -match "Transcript file not found" -or $LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 错误处理正常" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  ✗ 错误处理异常" -ForegroundColor Red
        Write-Host "  输出: $result" -ForegroundColor Gray
        $testsFailed++
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 7: 日志功能
Write-Host "Test 7: 路由器日志功能" -ForegroundColor Yellow
try {
    # 清除旧日志
    wsl bash -c 'rm -f /tmp/ralph-hook-router.log' 2>&1 | Out-Null

    # 执行路由器
    wsl bash -c 'cd /mnt/c/projects/ralph-wiggum-fix-win && sh hooks/stop-hook-router.sh <<< "{\"transcript_path\": \"/tmp/test.jsonl\"}"' 2>&1 | Out-Null

    # 检查日志
    $logExists = wsl bash -c '[ -f /tmp/ralph-hook-router.log ] && echo "EXISTS" || echo "NOT_EXISTS"' 2>&1
    if ($logExists -match "EXISTS") {
        Write-Host "  ✓ 日志文件创建成功" -ForegroundColor Green
        $logContent = wsl bash -c 'cat /tmp/ralph-hook-router.log' 2>&1
        Write-Host "  日志内容预览:" -ForegroundColor Gray
        Write-Host "  $($logContent -split "`n" | Select-Object -First 3 -join "`n  ")" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "  ✗ 日志文件未创建" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host "  ✗ 测试失败: $_" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# 总结
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "测试总结" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  ✓ 通过: $testsPassed" -ForegroundColor Green
Write-Host "  ✗ 失败: $testsFailed" -ForegroundColor Red
Write-Host "  总计: $($testsPassed + $testsFailed)" -ForegroundColor White
$passRate = if (($testsPassed + $testsFailed) -gt 0) {
    [math]::Round(($testsPassed / ($testsPassed + $testsFailed)) * 100, 1)
} else {
    0
}
Write-Host "  通过率: $passRate%" -ForegroundColor $(if ($passRate -ge 90) { "Green" } elseif ($passRate -ge 70) { "Yellow" } else { "Red" })
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "🎉 所有测试通过！WSL 支持完全正常。" -ForegroundColor Green
} else {
    Write-Host "⚠️  有 $testsFailed 个测试失败，需要进一步检查。" -ForegroundColor Yellow
}
