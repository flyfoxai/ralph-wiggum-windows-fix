# Interactive Environment Testing Tool
# Tests Ralph Wiggum stop-hook in specific environments

param(
    [Parameter(Position=0)]
    [ValidateSet('auto', 'windows', 'wsl', 'gitbash', 'all', 'menu')]
    [string]$Environment = 'menu',

    [switch]$VerboseOutput,
    [switch]$CreateMockState
)

$ErrorActionPreference = "Stop"

# Colors
$ColorHeader = "Cyan"
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Gray"

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $ColorHeader
    Write-Host "  $Text" -ForegroundColor $ColorHeader
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $ColorHeader
    Write-Host ""
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $ColorInfo
    Write-Host "  $Text" -ForegroundColor $ColorInfo
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $ColorInfo
}

function Write-Step {
    param([string]$Text, [string]$Status = "")
    if ($Status -eq "OK") {
        Write-Host "  ✅ $Text" -ForegroundColor $ColorSuccess
    } elseif ($Status -eq "FAIL") {
        Write-Host "  ❌ $Text" -ForegroundColor $ColorError
    } elseif ($Status -eq "WARN") {
        Write-Host "  ⚠️  $Text" -ForegroundColor $ColorWarning
    } else {
        Write-Host "  🔹 $Text" -ForegroundColor $ColorInfo
    }
}

function Show-Menu {
    Write-Header "Ralph Wiggum Environment Testing Tool"

    Write-Host "请选择要测试的环境:" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "  1. 自动检测当前环境并测试" -ForegroundColor White
    Write-Host "  2. 测试 Windows 原生环境 (PowerShell)" -ForegroundColor White
    Write-Host "  3. 测试 WSL 环境" -ForegroundColor White
    Write-Host "  4. 测试 Git Bash 环境" -ForegroundColor White
    Write-Host "  5. 测试所有可用环境" -ForegroundColor White
    Write-Host "  6. 查看环境信息" -ForegroundColor White
    Write-Host "  0. 退出" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "请输入选项 (0-6)"

    switch ($choice) {
        "1" { return "auto" }
        "2" { return "windows" }
        "3" { return "wsl" }
        "4" { return "gitbash" }
        "5" { return "all" }
        "6" { return "info" }
        "0" { exit 0 }
        default {
            Write-Host "无效选项，请重新选择" -ForegroundColor $ColorError
            Start-Sleep -Seconds 1
            return Show-Menu
        }
    }
}

function Get-CurrentEnvironment {
    Write-Section "检测当前环境"

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $detector = Join-Path $scriptDir "hooks\detect-environment.ps1"

    if (Test-Path $detector) {
        $env = & pwsh -NoProfile -ExecutionPolicy Bypass -File $detector env
        Write-Step "当前环境: $env" "OK"
        return $env
    } else {
        Write-Step "环境检测脚本未找到" "FAIL"
        return "unknown"
    }
}

function Show-EnvironmentInfo {
    Write-Header "环境信息"

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $detector = Join-Path $scriptDir "hooks\detect-environment.ps1"

    if (Test-Path $detector) {
        Write-Section "完整环境信息"
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $detector all
        Write-Host ""
    }

    Write-Section "系统信息"
    Write-Step "操作系统: $($env:OS)"
    Write-Step "计算机名: $($env:COMPUTERNAME)"
    Write-Step "用户名: $($env:USERNAME)"
    Write-Step "PowerShell 版本: $($PSVersionTable.PSVersion)"

    Write-Section "可用工具"

    $tools = @(
        @{Name="pwsh"; Command="pwsh"},
        @{Name="powershell"; Command="powershell"},
        @{Name="bash"; Command="bash"},
        @{Name="sh"; Command="sh"},
        @{Name="wsl"; Command="wsl"},
        @{Name="git"; Command="git"},
        @{Name="jq"; Command="jq"}
    )

    foreach ($tool in $tools) {
        $cmd = Get-Command $tool.Command -ErrorAction SilentlyContinue
        if ($cmd) {
            Write-Step "$($tool.Name): $($cmd.Source)" "OK"
        } else {
            Write-Step "$($tool.Name): 未安装" "WARN"
        }
    }

    Write-Host ""
    Read-Host "按 Enter 继续"
}

function Create-MockState {
    param([string]$StateFile)

    Write-Section "创建模拟状态文件"

    $stateDir = Split-Path -Parent $StateFile
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        Write-Step "创建目录: $stateDir" "OK"
    }

    $mockContent = @"
---
iteration: 1
max_iterations: 5
completion_promise: "DONE"
---

这是一个测试任务。请输出 <promise>DONE</promise> 来完成测试。
"@

    Set-Content -Path $StateFile -Value $mockContent -Encoding UTF8
    Write-Step "创建状态文件: $StateFile" "OK"

    # Create mock transcript
    $transcriptFile = ".claude\transcript-test.jsonl"
    $transcriptDir = Split-Path -Parent $transcriptFile
    if (-not (Test-Path $transcriptDir)) {
        New-Item -ItemType Directory -Path $transcriptDir -Force | Out-Null
    }

    $mockTranscript = @'
{"role":"user","message":{"content":[{"type":"text","text":"Test message"}]}}
{"role":"assistant","message":{"content":[{"type":"text","text":"Test response without promise"}]}}
'@

    Set-Content -Path $transcriptFile -Value $mockTranscript -Encoding UTF8
    Write-Step "创建模拟 transcript: $transcriptFile" "OK"

    return $transcriptFile
}

function Test-WindowsEnvironment {
    Write-Header "测试 Windows 原生环境"

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $stopHook = Join-Path $scriptDir "hooks\stop-hook.ps1"

    Write-Section "1. 检查文件"
    if (Test-Path $stopHook) {
        Write-Step "stop-hook.ps1 存在" "OK"
    } else {
        Write-Step "stop-hook.ps1 不存在" "FAIL"
        return $false
    }

    Write-Section "2. 检查语法"
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $stopHook -Raw), [ref]$null)
        Write-Step "PowerShell 语法有效" "OK"
    } catch {
        Write-Step "PowerShell 语法错误: $_" "FAIL"
        return $false
    }

    Write-Section "3. 创建测试环境"
    $stateFile = ".claude\ralph-loop.local.md"
    $transcriptFile = Create-MockState -StateFile $stateFile

    Write-Section "4. 测试执行"
    try {
        $hookInput = @{
            transcript_path = $transcriptFile
        } | ConvertTo-Json -Compress

        Write-Step "Hook 输入: $hookInput"

        $result = $hookInput | pwsh -NoProfile -ExecutionPolicy Bypass -File $stopHook 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Step "执行成功 (退出码: 0)" "OK"
            if ($VerboseOutput) {
                Write-Host "输出:" -ForegroundColor $ColorInfo
                Write-Host $result -ForegroundColor $ColorInfo
            }
        } else {
            Write-Step "执行失败 (退出码: $LASTEXITCODE)" "FAIL"
            Write-Host "错误输出:" -ForegroundColor $ColorError
            Write-Host $result -ForegroundColor $ColorError
        }
    } catch {
        Write-Step "执行异常: $_" "FAIL"
        return $false
    } finally {
        # Cleanup
        if (Test-Path $stateFile) {
            Remove-Item $stateFile -Force
            Write-Step "清理状态文件" "OK"
        }
        if (Test-Path $transcriptFile) {
            Remove-Item $transcriptFile -Force
            Write-Step "清理 transcript 文件" "OK"
        }
    }

    Write-Section "测试结果"
    Write-Step "Windows 环境测试完成" "OK"
    return $true
}

function Test-WSLEnvironment {
    Write-Header "测试 WSL 环境"

    Write-Section "1. 检查 WSL 可用性"
    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wsl) {
        Write-Step "WSL 未安装" "FAIL"
        return $false
    }
    Write-Step "WSL 已安装: $($wsl.Source)" "OK"

    Write-Section "2. 检查 WSL 分发版"
    try {
        $wslList = wsl --list --quiet 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Step "WSL 分发版:" "OK"
            $wslList | ForEach-Object { Write-Host "    - $_" -ForegroundColor $ColorInfo }
        } else {
            Write-Step "无法列出 WSL 分发版" "WARN"
        }
    } catch {
        Write-Step "WSL 列表查询失败: $_" "WARN"
    }

    Write-Section "3. 检查 WSL 中的 shell"
    $shPath = wsl which sh 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Step "sh 可用: $shPath" "OK"
    } else {
        Write-Step "sh 不可用" "FAIL"
        return $false
    }

    $bashPath = wsl which bash 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Step "bash 可用: $bashPath" "OK"
    } else {
        Write-Step "bash 不可用 (将使用 sh)" "WARN"
    }

    Write-Section "4. 检查脚本文件"
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $stopHook = Join-Path $scriptDir "hooks\stop-hook-posix.sh"

    if (Test-Path $stopHook) {
        Write-Step "stop-hook-posix.sh 存在" "OK"
    } else {
        Write-Step "stop-hook-posix.sh 不存在" "FAIL"
        return $false
    }

    Write-Section "5. 转换路径到 WSL 格式"
    # Convert Windows path to WSL path
    $wslPath = $stopHook -replace '\\', '/' -replace '^([A-Z]):', '/mnt/$1' -replace '^/mnt/([A-Z])', { "/mnt/$($_.Groups[1].Value.ToLower())" }
    Write-Step "Windows 路径: $stopHook"
    Write-Step "WSL 路径: $wslPath"

    Write-Section "6. 测试脚本语法"
    $syntaxCheck = wsl sh -n $wslPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Step "脚本语法有效" "OK"
    } else {
        Write-Step "脚本语法错误" "FAIL"
        Write-Host $syntaxCheck -ForegroundColor $ColorError
        return $false
    }

    Write-Section "7. 测试环境检测"
    $detectorPath = Join-Path $scriptDir "hooks\detect-environment.sh"
    $wslDetectorPath = $detectorPath -replace '\\', '/' -replace '^([A-Z]):', '/mnt/$1' -replace '^/mnt/([A-Z])', { "/mnt/$($_.Groups[1].Value.ToLower())" }

    $envResult = wsl sh $wslDetectorPath env 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Step "环境检测: $envResult" "OK"
    } else {
        Write-Step "环境检测失败" "WARN"
    }

    Write-Section "测试结果"
    Write-Step "WSL 环境测试完成" "OK"
    return $true
}

function Test-GitBashEnvironment {
    Write-Header "测试 Git Bash 环境"

    Write-Section "1. 检查 Git Bash 可用性"
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bash) {
        Write-Step "bash 未安装" "FAIL"
        return $false
    }
    Write-Step "bash 已安装: $($bash.Source)" "OK"

    Write-Section "2. 检查是否为 Git Bash"
    $bashVersion = bash --version 2>&1 | Select-Object -First 1
    Write-Step "Bash 版本: $bashVersion"

    if ($env:MSYSTEM) {
        Write-Step "检测到 MSYSTEM: $($env:MSYSTEM)" "OK"
    } else {
        Write-Step "未检测到 MSYSTEM 环境变量" "WARN"
    }

    Write-Section "3. 检查脚本文件"
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $stopHook = Join-Path $scriptDir "hooks\stop-hook-posix.sh"

    if (Test-Path $stopHook) {
        Write-Step "stop-hook-posix.sh 存在" "OK"
    } else {
        Write-Step "stop-hook-posix.sh 不存在" "FAIL"
        return $false
    }

    Write-Section "4. 测试脚本语法"
    $syntaxCheck = bash -n $stopHook 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Step "脚本语法有效" "OK"
    } else {
        Write-Step "脚本语法错误" "FAIL"
        Write-Host $syntaxCheck -ForegroundColor $ColorError
        return $false
    }

    Write-Section "5. 测试环境检测"
    $detector = Join-Path $scriptDir "hooks\detect-environment.sh"
    if (Test-Path $detector) {
        $envResult = bash $detector env 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Step "环境检测: $envResult" "OK"
        } else {
            Write-Step "环境检测失败" "WARN"
        }
    }

    Write-Section "测试结果"
    Write-Step "Git Bash 环境测试完成" "OK"
    return $true
}

function Test-AllEnvironments {
    Write-Header "测试所有可用环境"

    $results = @{}

    # Test Windows
    Write-Host ""
    $results["Windows"] = Test-WindowsEnvironment

    # Test WSL if available
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        Write-Host ""
        $results["WSL"] = Test-WSLEnvironment
    } else {
        Write-Step "跳过 WSL 测试 (未安装)" "WARN"
        $results["WSL"] = $null
    }

    # Test Git Bash if available
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        Write-Host ""
        $results["GitBash"] = Test-GitBashEnvironment
    } else {
        Write-Step "跳过 Git Bash 测试 (未安装)" "WARN"
        $results["GitBash"] = $null
    }

    # Summary
    Write-Header "测试总结"

    foreach ($env in $results.Keys) {
        $status = $results[$env]
        if ($null -eq $status) {
            Write-Step "$env : 跳过" "WARN"
        } elseif ($status) {
            Write-Step "$env : 通过" "OK"
        } else {
            Write-Step "$env : 失败" "FAIL"
        }
    }

    Write-Host ""
}

# Main execution
if ($Environment -eq 'menu') {
    $Environment = Show-Menu
}

switch ($Environment) {
    'auto' {
        $currentEnv = Get-CurrentEnvironment
        switch ($currentEnv) {
            'windows' { Test-WindowsEnvironment }
            'wsl' { Test-WSLEnvironment }
            'gitbash' { Test-GitBashEnvironment }
            default {
                Write-Host "未知环境: $currentEnv" -ForegroundColor $ColorError
                Write-Host "尝试测试所有环境..." -ForegroundColor $ColorWarning
                Test-AllEnvironments
            }
        }
    }
    'windows' { Test-WindowsEnvironment }
    'wsl' { Test-WSLEnvironment }
    'gitbash' { Test-GitBashEnvironment }
    'all' { Test-AllEnvironments }
    'info' { Show-EnvironmentInfo }
}

Write-Host ""
Write-Host "测试完成!" -ForegroundColor $ColorSuccess
Write-Host ""
