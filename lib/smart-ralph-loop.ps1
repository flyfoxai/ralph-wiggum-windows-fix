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

# Parse task progress from Claude output
function Parse-TaskProgress {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Output
    )

    # Parse todo list from output
    # Supports formats:
    # - ☒ Task (completed)
    # - ☐ Task (pending)
    # - ● Task (in progress)

    $tasks = @()

    # Pattern to match todo items
    $todoPattern = '(?m)^[\s-]*[☒☐●✓✗×]\s+(.+?)$'
    $matches = [regex]::Matches($Output, $todoPattern)

    if ($matches.Count -eq 0) {
        return @{
            hasTasks = $false
            totalTasks = 0
            completedTasks = 0
            progress = 0
            tasks = @()
        }
    }

    foreach ($match in $matches) {
        $line = $match.Value.Trim()
        $taskText = $match.Groups[1].Value.Trim()

        # Check status based on symbol
        $isCompleted = $line -match '^[\s-]*[☒✓×]'
        $isInProgress = $line -match '^[\s-]*●'
        $isPending = $line -match '^[\s-]*[☐✗]'

        $status = if ($isCompleted) { "completed" }
                  elseif ($isInProgress) { "in_progress" }
                  else { "pending" }

        $tasks += @{
            text = $taskText
            status = $status
        }
    }

    $completedCount = @($tasks | Where-Object { $_.status -eq "completed" }).Count
    $totalCount = $tasks.Count
    $progress = if ($totalCount -gt 0) {
        [math]::Round(($completedCount / $totalCount) * 100, 2)
    } else {
        0
    }

    $result = @{
        hasTasks = $true
        totalTasks = $totalCount
        completedTasks = $completedCount
        progress = $progress
        tasks = $tasks
    }

    return $result
}

# Export functions (only if running as a module)
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    # Running as a script - functions are already available
} else {
    # Running as a module
    Export-ModuleMember -Function Initialize-RalphState, Update-RalphState, Get-RalphState, Clear-RalphState, Parse-TaskProgress
}
