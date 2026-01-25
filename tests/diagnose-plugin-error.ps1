# 插件错误诊断和修复脚本
# Plugin Error Diagnosis and Fix Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ralph Wiggum 插件诊断工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$pluginPath = "C:\Users\dooji\.claude\plugins\cache\ralph-wiggum-cross-platform\ralph-wiggum"

# 检查所有版本
Write-Host "检查已安装的插件版本..." -ForegroundColor Yellow
$versions = Get-ChildItem $pluginPath | Select-Object -ExpandProperty Name
Write-Host "找到版本: $($versions -join ', ')" -ForegroundColor Green
Write-Host ""

# 检查每个版本的 hooks.json
foreach ($version in $versions) {
    $hooksFile = Join-Path $pluginPath "$version\hooks\hooks.json"

    Write-Host "检查版本 $version..." -ForegroundColor Cyan

    if (Test-Path $hooksFile) {
        try {
            $json = Get-Content $hooksFile -Raw | ConvertFrom-Json

            # 验证结构
            if ($json.hooks.Stop -and $json.hooks.Stop.Count -gt 0) {
                $firstStop = $json.hooks.Stop[0]

                if ($firstStop.hooks) {
                    Write-Host "  ✅ hooks.json 结构正确" -ForegroundColor Green
                    Write-Host "     - Stop hooks 数量: $($json.hooks.Stop.Count)" -ForegroundColor Gray
                    Write-Host "     - 嵌套 hooks 数量: $($firstStop.hooks.Count)" -ForegroundColor Gray
                } else {
                    Write-Host "  ❌ 错误: 缺少嵌套的 'hooks' 数组" -ForegroundColor Red
                    Write-Host "     需要修复此版本!" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  ❌ 错误: 缺少 Stop hooks" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ❌ JSON 解析错误: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  ⚠️  hooks.json 文件不存在" -ForegroundColor Yellow
    }
    Write-Host ""
}

# 检查 Claude Code 配置
Write-Host "检查 Claude Code 配置..." -ForegroundColor Yellow
$claudeConfig = "$env:USERPROFILE\.claude\config.json"
if (Test-Path $claudeConfig) {
    Write-Host "  ✅ 配置文件存在: $claudeConfig" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  配置文件不存在" -ForegroundColor Yellow
}
Write-Host ""

# 建议的修复步骤
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "建议的修复步骤" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 重启 Claude Code CLI" -ForegroundColor Yellow
Write-Host "   - 完全退出 Claude Code" -ForegroundColor Gray
Write-Host "   - 重新启动" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 清除插件缓存" -ForegroundColor Yellow
Write-Host "   运行命令: /plugin" -ForegroundColor Gray
Write-Host "   然后禁用并重新启用插件" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 如果问题仍然存在,手动清除缓存:" -ForegroundColor Yellow
Write-Host "   - 关闭 Claude Code" -ForegroundColor Gray
Write-Host "   - 删除目录: $pluginPath" -ForegroundColor Gray
Write-Host "   - 重新启动 Claude Code" -ForegroundColor Gray
Write-Host "   - 重新安装插件" -ForegroundColor Gray
Write-Host ""

# WSL 错误诊断
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WSL 错误诊断" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "检查 WSL 状态..." -ForegroundColor Yellow

try {
    $wslList = wsl --list --verbose 2>&1
    Write-Host $wslList -ForegroundColor Gray
    Write-Host ""

    Write-Host "WSL 错误可能的原因:" -ForegroundColor Yellow
    Write-Host "1. systemd 配置问题" -ForegroundColor Gray
    Write-Host "   在 WSL 中运行: cat /etc/wsl.conf" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. shell 二进制文件损坏" -ForegroundColor Gray
    Write-Host "   在 WSL 中运行: file /usr/bin/sh" -ForegroundColor Gray
    Write-Host "   修复命令: sudo apt-get install --reinstall dash" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. 重启 WSL" -ForegroundColor Gray
    Write-Host "   运行: wsl --shutdown" -ForegroundColor Gray
    Write-Host "   然后: wsl" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "  ⚠️  无法检查 WSL 状态" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "诊断完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
