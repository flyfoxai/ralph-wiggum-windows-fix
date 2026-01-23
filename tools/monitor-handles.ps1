# Windows 句柄泄漏监控脚本
# 用于检测进程句柄泄漏问题
# 作者: Claude Code
# 日期: 2026-01-23

param(
    [int]$TopN = 15,           # 显示前 N 个进程
    [int]$Interval = 30,       # 监控间隔(秒)
    [int]$Duration = 10,       # 监控次数
    [int]$AlertThreshold = 50000  # 句柄数警告阈值
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows 句柄泄漏监控工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "监控间隔: $Interval 秒" -ForegroundColor Yellow
Write-Host "监控次数: $Duration 次" -ForegroundColor Yellow
Write-Host "警告阈值: $AlertThreshold 句柄" -ForegroundColor Yellow
Write-Host ""

# 存储历史数据
$history = @{}

1..$Duration | ForEach-Object {
    $iteration = $_
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Write-Host "[$time] 第 $iteration/$Duration 次检查" -ForegroundColor Green
    Write-Host ("=" * 80)

    # 获取所有进程的句柄数
    $processes = Get-Process | Select-Object Name, Id, HandleCount |
                 Sort-Object HandleCount -Descending |
                 Select-Object -First $TopN

    # 显示进程信息
    $processes | ForEach-Object {
        $processKey = "$($_.Name)-$($_.Id)"
        $currentHandles = $_.HandleCount

        # 检查是否超过阈值
        $alert = ""
        if ($currentHandles -gt $AlertThreshold) {
            $alert = " ⚠️ 警告: 句柄数异常!"
            Write-Host "$($_.Name) (PID: $($_.Id)) - $currentHandles 句柄$alert" -ForegroundColor Red
        } else {
            # 计算变化
            if ($history.ContainsKey($processKey)) {
                $change = $currentHandles - $history[$processKey]
                $changeStr = if ($change -gt 0) { "+$change" } elseif ($change -lt 0) { "$change" } else { "0" }
                Write-Host "$($_.Name) (PID: $($_.Id)) - $currentHandles 句柄 ($changeStr)" -ForegroundColor White
            } else {
                Write-Host "$($_.Name) (PID: $($_.Id)) - $currentHandles 句柄" -ForegroundColor White
            }
        }

        # 更新历史记录
        $history[$processKey] = $currentHandles
    }

    Write-Host ""

    # 特别监控 explorer.exe
    $explorers = Get-Process explorer -ErrorAction SilentlyContinue
    if ($explorers) {
        Write-Host "Explorer.exe 详细信息:" -ForegroundColor Cyan
        $explorers | ForEach-Object {
            Write-Host "  PID $($_.Id): $($_.HandleCount) 句柄, 内存: $([math]::Round($_.WorkingSet/1MB, 2)) MB"
        }
        Write-Host ""
    }

    # 如果不是最后一次,等待
    if ($iteration -lt $Duration) {
        Write-Host "等待 $Interval 秒..." -ForegroundColor Gray
        Write-Host ""
        Start-Sleep -Seconds $Interval
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "监控完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# 生成报告
Write-Host ""
Write-Host "句柄数变化总结:" -ForegroundColor Yellow
$history.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value) 句柄"
}
