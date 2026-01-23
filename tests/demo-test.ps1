# 特定环境测试 - 快速演示
# Quick Environment Testing Demo

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Ralph Wiggum 环境测试演示" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $PSScriptRoot

# 1. 检测当前环境
Write-Host "━━━ 1. 检测当前环境 ━━━" -ForegroundColor Yellow
Write-Host ""

$detector = Join-Path $scriptDir "hooks\detect-environment.ps1"
if (Test-Path $detector) {
    Write-Host "运行环境检测..." -ForegroundColor Gray
    $env = & pwsh -NoProfile -ExecutionPolicy Bypass -File $detector env 2>&1
    Write-Host "✅ 当前环境: " -NoNewline -ForegroundColor Green
    Write-Host $env -ForegroundColor White
} else {
    Write-Host "❌ 环境检测脚本未找到" -ForegroundColor Red
}

Write-Host ""

# 2. 检查可用工具
Write-Host "━━━ 2. 检查可用工具 ━━━" -ForegroundColor Yellow
Write-Host ""

$tools = @{
    "PowerShell 7+" = "pwsh"
    "Windows PowerShell" = "powershell"
    "Bash" = "bash"
    "Shell (sh)" = "sh"
    "WSL" = "wsl"
    "Git" = "git"
    "jq" = "jq"
}

foreach ($name in $tools.Keys) {
    $cmd = Get-Command $tools[$name] -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  ✅ $name : " -NoNewline -ForegroundColor Green
        Write-Host $cmd.Source -ForegroundColor Gray
    } else {
        Write-Host "  ❌ $name : 未安装" -ForegroundColor Red
    }
}

Write-Host ""

# 3. 检查脚本文件
Write-Host "━━━ 3. 检查脚本文件 ━━━" -ForegroundColor Yellow
Write-Host ""

$scripts = @(
    "hooks\stop-hook.ps1",
    "hooks\stop-hook.sh",
    "hooks\stop-hook-posix.sh",
    "hooks\stop-hook-router.ps1",
    "hooks\stop-hook-router.sh",
    "hooks\detect-environment.ps1",
    "hooks\detect-environment.sh"
)

foreach ($script in $scripts) {
    $path = Join-Path $scriptDir $script
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        Write-Host "  ✅ $script " -NoNewline -ForegroundColor Green
        Write-Host "($size bytes)" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ $script : 不存在" -ForegroundColor Red
    }
}

Write-Host ""

# 4. 测试建议
Write-Host "━━━ 4. 如何测试特定环境 ━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "根据您的系统,可以使用以下命令测试:" -ForegroundColor White
Write-Host ""

# Windows 测试
Write-Host "📌 测试 Windows 原生环境:" -ForegroundColor Cyan
Write-Host "   pwsh -NoProfile -ExecutionPolicy Bypass -File .\hooks\detect-environment.ps1 all" -ForegroundColor Gray
Write-Host ""

# WSL 测试
$wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
if ($wslAvailable) {
    Write-Host "📌 测试 WSL 环境:" -ForegroundColor Cyan
    Write-Host "   wsl sh ./hooks/detect-environment.sh all" -ForegroundColor Gray
    Write-Host ""
}

# Git Bash 测试
$bashAvailable = Get-Command bash -ErrorAction SilentlyContinue
if ($bashAvailable) {
    Write-Host "📌 测试 Git Bash 环境:" -ForegroundColor Cyan
    Write-Host "   bash ./hooks/detect-environment.sh all" -ForegroundColor Gray
    Write-Host ""
}

# 5. 运行简单测试
Write-Host "━━━ 5. 运行简单测试 ━━━" -ForegroundColor Yellow
Write-Host ""

Write-Host "测试环境检测功能..." -ForegroundColor White
Write-Host ""

# Test PowerShell detector
Write-Host "PowerShell 检测器:" -ForegroundColor Cyan
$psDetector = Join-Path $scriptDir "hooks\detect-environment.ps1"
if (Test-Path $psDetector) {
    $result = & pwsh -NoProfile -ExecutionPolicy Bypass -File $psDetector all 2>&1
    Write-Host $result -ForegroundColor Gray
} else {
    Write-Host "  未找到" -ForegroundColor Red
}

Write-Host ""

# Test WSL if available
if ($wslAvailable) {
    Write-Host "WSL 检测器:" -ForegroundColor Cyan
    $shDetector = Join-Path $scriptDir "hooks\detect-environment.sh"
    $wslPath = $shDetector -replace '\\', '/' -replace '^([A-Z]):', '/mnt/$1' -replace '^/mnt/([A-Z])', { "/mnt/$($_.Groups[1].Value.ToLower())" }

    $result = wsl sh $wslPath all 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host $result -ForegroundColor Gray
    } else {
        Write-Host "  执行失败" -ForegroundColor Red
    }
    Write-Host ""
}

# Test Git Bash if available
if ($bashAvailable) {
    Write-Host "Git Bash 检测器:" -ForegroundColor Cyan
    $shDetector = Join-Path $scriptDir "hooks\detect-environment.sh"

    $result = bash $shDetector all 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host $result -ForegroundColor Gray
    } else {
        Write-Host "  执行失败" -ForegroundColor Red
    }
    Write-Host ""
}

# 6. 总结
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  测试完成" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📚 更多测试选项:" -ForegroundColor White
Write-Host "   - 查看详细测试指南: cat TESTING-GUIDE.md" -ForegroundColor Gray
Write-Host "   - 运行完整测试: .\test-cross-platform.ps1" -ForegroundColor Gray
Write-Host "   - 交互式测试: .\test-environment.ps1" -ForegroundColor Gray
Write-Host ""
