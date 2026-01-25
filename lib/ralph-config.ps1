# Ralph Configuration Manager
# Manages default settings for Ralph loops

$ErrorActionPreference = "Stop"

# Configuration file location
$script:ConfigFile = Join-Path $env:USERPROFILE ".claude" "ralph-config.json"

# Get default configuration
function Get-DefaultConfig {
    return @{
        defaultMaxIterations = 15
        lastUpdated = (Get-Date).ToString("o")
    }
}

# Get Ralph configuration
function Get-RalphConfig {
    if (-not (Test-Path $ConfigFile)) {
        # Create default config
        $config = Get-DefaultConfig
        Set-RalphConfig -Config $config
        return $config
    }

    try {
        $config = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        return $config
    } catch {
        Write-Warning "Failed to read config file, using defaults: $_"
        return Get-DefaultConfig
    }
}

# Set Ralph configuration
function Set-RalphConfig {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )

    # Ensure .claude directory exists
    $claudeDir = Split-Path $ConfigFile -Parent
    if (-not (Test-Path $claudeDir)) {
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
    }

    # Update timestamp
    $Config.lastUpdated = (Get-Date).ToString("o")

    # Save config
    $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -Encoding UTF8
}

# Get default max iterations
function Get-DefaultMaxIterations {
    $config = Get-RalphConfig
    return $config.defaultMaxIterations
}

# Set default max iterations
function Set-DefaultMaxIterations {
    param(
        [Parameter(Mandatory=$true)]
        [int]$MaxIterations
    )

    if ($MaxIterations -lt 1) {
        throw "Max iterations must be at least 1"
    }

    if ($MaxIterations -gt 100) {
        Write-Warning "Max iterations is very high ($MaxIterations). Consider using a lower value."
    }

    $config = Get-RalphConfig
    $config.defaultMaxIterations = $MaxIterations
    Set-RalphConfig -Config $config

    Write-Host "✅ Default max iterations set to: $MaxIterations" -ForegroundColor Green
    Write-Host "   This will be used for all /ralph-loop and /ralph-smart commands" -ForegroundColor Gray
    Write-Host "   unless explicitly overridden with --max-iterations parameter." -ForegroundColor Gray
}

# Read prompt from file
function Read-PromptFromFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    # Resolve path
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)

    if (-not (Test-Path $resolvedPath)) {
        throw "Prompt file not found: $resolvedPath"
    }

    # Read file content
    $content = Get-Content $resolvedPath -Raw -Encoding UTF8

    if ([string]::IsNullOrWhiteSpace($content)) {
        throw "Prompt file is empty: $resolvedPath"
    }

    Write-Verbose "Read prompt from file: $resolvedPath ($($content.Length) chars)"
    return $content.Trim()
}

# Test if argument is a file path
function Test-IsFilePath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Argument
    )

    # Check if it looks like a file path
    # Patterns: ./file, ../file, /path/file, C:\path\file, file.txt, file.md
    $filePatterns = @(
        '^\.{1,2}[/\\]',           # Starts with ./ or ../
        '^[a-zA-Z]:[/\\]',         # Windows absolute path
        '^/',                       # Unix absolute path
        '\.(txt|md|markdown)$'     # Has file extension
    )

    foreach ($pattern in $filePatterns) {
        if ($Argument -match $pattern) {
            return $true
        }
    }

    # Check if file actually exists
    try {
        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Argument)
        if (Test-Path $resolvedPath) {
            return $true
        }
    } catch {
        # Not a valid path
    }

    return $false
}

# Only export if running as a module
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    # Running as script, don't export
} else {
    # Running as module, export functions
    Export-ModuleMember -Function @(
        'Get-RalphConfig',
        'Set-RalphConfig',
        'Get-DefaultMaxIterations',
        'Set-DefaultMaxIterations',
        'Read-PromptFromFile',
        'Test-IsFilePath'
    )
}
