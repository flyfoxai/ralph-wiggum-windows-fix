# Test to verify the hooks.json fix
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Hooks Configuration Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$hooksJson = "C:\projects\ralph-wiggum-fix-win\hooks\hooks.json"

# 1. Validate JSON syntax
Write-Host "1. JSON Syntax Validation" -ForegroundColor Yellow
try {
    $hooks = Get-Content $hooksJson | ConvertFrom-Json
    Write-Host "   ✓ Valid JSON" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Invalid JSON: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. Check structure
Write-Host "2. Structure Validation" -ForegroundColor Yellow
$stopHooks = $hooks.hooks.Stop

if ($stopHooks -is [Array]) {
    Write-Host "   ✓ Stop is an array" -ForegroundColor Green
    Write-Host "   Number of hooks: $($stopHooks.Count)" -ForegroundColor Gray
} else {
    Write-Host "   ✗ Stop is not an array" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 3. Check for nested hooks (the bug)
Write-Host "3. Nested Hooks Check" -ForegroundColor Yellow
$hasNestedHooks = $false
foreach ($hook in $stopHooks) {
    if ($hook.PSObject.Properties.Name -contains "hooks") {
        Write-Host "   ✗ Found nested 'hooks' property (BUG!)" -ForegroundColor Red
        $hasNestedHooks = $true
    }
}

if (-not $hasNestedHooks) {
    Write-Host "   ✓ No nested hooks found (FIXED!)" -ForegroundColor Green
} else {
    Write-Host "   This nested structure causes hooks to run multiple times" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 4. Validate hook properties
Write-Host "4. Hook Properties Validation" -ForegroundColor Yellow
$allValid = $true
for ($i = 0; $i -lt $stopHooks.Count; $i++) {
    $hook = $stopHooks[$i]
    Write-Host "   Hook $($i + 1):" -ForegroundColor Gray

    # Check required properties
    if ($hook.type) {
        Write-Host "     ✓ type: $($hook.type)" -ForegroundColor Green
    } else {
        Write-Host "     ✗ Missing 'type' property" -ForegroundColor Red
        $allValid = $false
    }

    if ($hook.command) {
        Write-Host "     ✓ command: $($hook.command.Substring(0, [Math]::Min(50, $hook.command.Length)))..." -ForegroundColor Green
    } else {
        Write-Host "     ✗ Missing 'command' property" -ForegroundColor Red
        $allValid = $false
    }

    if ($hook.platforms) {
        Write-Host "     ✓ platforms: $($hook.platforms -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "     ✗ Missing 'platforms' property" -ForegroundColor Red
        $allValid = $false
    }
}

if ($allValid) {
    Write-Host "   ✓ All hooks have required properties" -ForegroundColor Green
} else {
    exit 1
}
Write-Host ""

# 5. Platform coverage check
Write-Host "5. Platform Coverage Check" -ForegroundColor Yellow
$platforms = @()
foreach ($hook in $stopHooks) {
    $platforms += $hook.platforms
}
$uniquePlatforms = $platforms | Select-Object -Unique

Write-Host "   Covered platforms: $($uniquePlatforms -join ', ')" -ForegroundColor Gray

$expectedPlatforms = @("win32", "darwin", "linux")
$allCovered = $true
foreach ($platform in $expectedPlatforms) {
    if ($uniquePlatforms -contains $platform) {
        Write-Host "   ✓ $platform covered" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $platform NOT covered" -ForegroundColor Red
        $allCovered = $false
    }
}

if ($allCovered) {
    Write-Host "   ✓ All major platforms covered" -ForegroundColor Green
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Hooks configuration is valid!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
