# Test PowerShell calling sh with script
$ErrorActionPreference = "Continue"

Write-Host "Testing PowerShell -> sh execution" -ForegroundColor Cyan
Write-Host ""

$shScript = "C:\projects\ralph-wiggum-fix-win\hooks\stop-hook-posix.sh"

Write-Host "1. Test with & operator" -ForegroundColor Yellow
Write-Host "   Command: & sh `"$shScript`"" -ForegroundColor Gray
try {
    $testInput = '{"transcript_path":"test.jsonl"}'
    $result = $testInput | & sh $shScript 2>&1
    Write-Host "   ✓ Success" -ForegroundColor Green
    Write-Host "   Output: $result" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "2. Test with Start-Process" -ForegroundColor Yellow
try {
    $testInput = '{"transcript_path":"test.jsonl"}'
    $proc = Start-Process -FilePath "sh" -ArgumentList $shScript -NoNewWindow -Wait -PassThru -RedirectStandardInput ([System.IO.Path]::GetTempFileName())
    Write-Host "   Exit code: $($proc.ExitCode)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "3. Test with bash instead of sh" -ForegroundColor Yellow
Write-Host "   Command: & bash `"$shScript`"" -ForegroundColor Gray
try {
    $testInput = '{"transcript_path":"test.jsonl"}'
    $result = $testInput | & bash $shScript 2>&1
    Write-Host "   ✓ Success" -ForegroundColor Green
    Write-Host "   Output: $result" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "4. Check what 'sh' resolves to" -ForegroundColor Yellow
$shCmd = Get-Command sh -ErrorAction SilentlyContinue
if ($shCmd) {
    Write-Host "   Name: $($shCmd.Name)" -ForegroundColor Gray
    Write-Host "   Source: $($shCmd.Source)" -ForegroundColor Gray
    Write-Host "   Type: $($shCmd.CommandType)" -ForegroundColor Gray
}
Write-Host ""

Write-Host "5. Test router script directly" -ForegroundColor Yellow
$routerScript = "C:\projects\ralph-wiggum-fix-win\hooks\stop-hook-router.ps1"
Write-Host "   Running: $routerScript" -ForegroundColor Gray
try {
    $testInput = '{"transcript_path":"test.jsonl"}'
    $result = $testInput | & pwsh -NoProfile -ExecutionPolicy Bypass -File $routerScript 2>&1
    Write-Host "   Output:" -ForegroundColor Gray
    $result | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }
} catch {
    Write-Host "   ✗ Failed: $_" -ForegroundColor Red
}
