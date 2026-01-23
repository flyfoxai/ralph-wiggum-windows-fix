# Smart Ralph Loop Engine
# Manages autonomous iteration with progress tracking and state management

param(
    [Parameter(Mandatory=$false)]
    [string]$Prompt,

    [Parameter(Mandatory=$false)]
    [int]$MaxIterations = 10,

    [Parameter(Mandatory=$false)]
    [string]$CompletionPromise = ""
)

$ErrorActionPreference = "Stop"

# State file location
$script:StateFile = Join-Path $env:TEMP "smart-ralph-state.json"

# Initialize Ralph Loop state
function Initialize-RalphState {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [int]$MaxIterations = 10,

        [Parameter(Mandatory=$false)]
        [string]$CompletionPromise = ""
    )

    $state = @{
        prompt = $Prompt
        maxIterations = $MaxIterations
        completionPromise = $CompletionPromise
        currentIteration = 0
        startTime = (Get-Date).ToString("o")
        status = "running"
        endTime = $null
    }

    $state | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8

    return $state
}

# Update Ralph Loop state
function Update-RalphState {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Updates
    )

    if (-not (Test-Path $StateFile)) {
        Write-Error "State file not found: $StateFile"
        return $null
    }

    $state = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable

    foreach ($key in $Updates.Keys) {
        $state[$key] = $Updates[$key]
    }

    $state | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8

    return $state
}

# Get Ralph Loop state
function Get-RalphState {
    if (-not (Test-Path $StateFile)) {
        return $null
    }

    $state = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    return $state
}

# Clear Ralph Loop state
function Clear-RalphState {
    if (Test-Path $StateFile) {
        Remove-Item $StateFile -Force
        Write-Verbose "State file cleaned up: $StateFile"
    }
}

# Export functions (only if running as a module)
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    # Running as a script - functions are already available
} else {
    # Running as a module
    Export-ModuleMember -Function Initialize-RalphState, Update-RalphState, Get-RalphState, Clear-RalphState
}
