# Task Parser Library for Smart Ralph
# Parses task files in various formats (Markdown, YAML, plain text)

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskFilePath
)

$ErrorActionPreference = "Stop"

# Check if file exists
if (-not (Test-Path $TaskFilePath)) {
    Write-Error "Task file not found: $TaskFilePath"
    exit 1
}

# Read file content
$content = Get-Content $TaskFilePath -Raw -Encoding UTF8

# Detect file format
function Get-FileFormat {
    param([string]$Content)

    if ($Content -match '(?m)^tasks:\s*$' -and $Content -match '(?m)^\s+-\s+id:') {
        return "yaml"
    } elseif ($Content -match '(?m)^##\s+任务\s+\d+:' -or $Content -match '(?m)^##\s+Task\s+\d+:') {
        return "markdown"
    } else {
        return "text"
    }
}

# Parse Markdown format
function Parse-MarkdownTasks {
    param([string]$Content)

    $tasks = @()
    $taskId = 0

    # Split by task headers (## 任务 N: or ## Task N:)
    $taskPattern = '(?m)^##\s+(?:任务|Task)\s+(\d+):\s*(.+?)$'
    $matches = [regex]::Matches($Content, $taskPattern)

    foreach ($match in $matches) {
        $taskId++
        $taskNumber = $match.Groups[1].Value
        $taskTitle = $match.Groups[2].Value.Trim()

        # Find the content between this task and the next task (or end of file)
        $startPos = $match.Index + $match.Length
        $nextMatch = $matches | Where-Object { $_.Index -gt $match.Index } | Select-Object -First 1
        $endPos = if ($nextMatch) { $nextMatch.Index } else { $Content.Length }

        $taskContent = $Content.Substring($startPos, $endPos - $startPos)

        # Extract description
        $descPattern = '\*\*(?:描述|目标|Description|Goal)\*\*:\s*(.+?)(?=\n\n|\*\*|$)'
        $descMatch = [regex]::Match($taskContent, $descPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $description = if ($descMatch.Success) { $descMatch.Groups[1].Value.Trim() } else { "" }

        # Extract acceptance criteria (checklist items)
        $criteriaPattern = '(?m)^-\s+\[([ x])\]\s+(.+?)$'
        $criteriaMatches = [regex]::Matches($taskContent, $criteriaPattern)

        $criteria = @()
        $completedCount = 0

        foreach ($criteriaMatch in $criteriaMatches) {
            $isCompleted = $criteriaMatch.Groups[1].Value -eq 'x'
            $criteriaText = $criteriaMatch.Groups[2].Value.Trim()

            $criteria += @{
                text = $criteriaText
                completed = $isCompleted
            }

            if ($isCompleted) {
                $completedCount++
            }
        }

        # Calculate completion percentage
        $completion = if ($criteria.Count -gt 0) {
            [math]::Round(($completedCount / $criteria.Count) * 100)
        } else {
            0
        }

        $tasks += @{
            id = $taskId
            title = $taskTitle
            description = $description
            acceptance_criteria = $criteria
            status = if ($completion -eq 100) { "completed" } elseif ($completion -gt 0) { "in_progress" } else { "pending" }
            completion = $completion
            iterations = 0
        }
    }

    return $tasks
}

# Parse YAML format
function Parse-YamlTasks {
    param([string]$Content)

    # Simple YAML parser (basic implementation)
    # For production, consider using a proper YAML library

    $tasks = @()
    $taskId = 0

    # Extract tasks section
    $tasksPattern = '(?s)tasks:\s*\n(.*?)(?=\n\S|$)'
    $tasksMatch = [regex]::Match($Content, $tasksPattern)

    if (-not $tasksMatch.Success) {
        return $tasks
    }

    $tasksContent = $tasksMatch.Groups[1].Value

    # Split by task items (- id:)
    $taskPattern = '(?m)^\s+-\s+id:\s+(\d+)\s*\n(.*?)(?=^\s+-\s+id:|$)'
    $matches = [regex]::Matches($tasksContent, $taskPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    foreach ($match in $matches) {
        $taskId++
        $taskIdValue = $match.Groups[1].Value
        $taskContent = $match.Groups[2].Value

        # Extract title
        $titleMatch = [regex]::Match($taskContent, '(?m)^\s+title:\s*"?(.+?)"?\s*$')
        $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Task $taskId" }

        # Extract description
        $descMatch = [regex]::Match($taskContent, '(?m)^\s+description:\s*"?(.+?)"?\s*$')
        $description = if ($descMatch.Success) { $descMatch.Groups[1].Value.Trim() } else { "" }

        # Extract acceptance criteria
        $criteriaPattern = '(?m)^\s+-\s+"?(.+?)"?\s*$'
        $criteriaSection = [regex]::Match($taskContent, '(?s)acceptance_criteria:\s*\n(.*?)(?=\n\s+\w+:|$)')

        $criteria = @()
        if ($criteriaSection.Success) {
            $criteriaMatches = [regex]::Matches($criteriaSection.Groups[1].Value, $criteriaPattern)
            foreach ($criteriaMatch in $criteriaMatches) {
                $criteria += @{
                    text = $criteriaMatch.Groups[1].Value.Trim()
                    completed = $false
                }
            }
        }

        $tasks += @{
            id = $taskId
            title = $title
            description = $description
            acceptance_criteria = $criteria
            status = "pending"
            completion = 0
            iterations = 0
        }
    }

    return $tasks
}

# Parse plain text format
function Parse-TextTasks {
    param([string]$Content)

    $tasks = @()
    $taskId = 0

    # Split by task headers (任务 N: or Task N:)
    $taskPattern = '(?m)^(?:任务|Task)\s+(\d+):\s*(.+?)$'
    $matches = [regex]::Matches($Content, $taskPattern)

    foreach ($match in $matches) {
        $taskId++
        $taskNumber = $match.Groups[1].Value
        $taskTitle = $match.Groups[2].Value.Trim()

        # Find the content between this task and the next task
        $startPos = $match.Index + $match.Length
        $nextMatch = $matches | Where-Object { $_.Index -gt $match.Index } | Select-Object -First 1
        $endPos = if ($nextMatch) { $nextMatch.Index } else { $Content.Length }

        $taskContent = $Content.Substring($startPos, $endPos - $startPos)

        # Extract criteria (lines starting with -)
        $criteriaPattern = '(?m)^-\s+(.+?)$'
        $criteriaMatches = [regex]::Matches($taskContent, $criteriaPattern)

        $criteria = @()
        foreach ($criteriaMatch in $criteriaMatches) {
            $criteria += @{
                text = $criteriaMatch.Groups[1].Value.Trim()
                completed = $false
            }
        }

        $tasks += @{
            id = $taskId
            title = $taskTitle
            description = ""
            acceptance_criteria = $criteria
            status = "pending"
            completion = 0
            iterations = 0
        }
    }

    return $tasks
}

# Main parsing logic
$format = Get-FileFormat -Content $content

$tasks = switch ($format) {
    "markdown" { Parse-MarkdownTasks -Content $content }
    "yaml" { Parse-YamlTasks -Content $content }
    "text" { Parse-TextTasks -Content $content }
    default { @() }
}

if ($tasks.Count -eq 0) {
    Write-Error "No tasks found in file. Please check the format."
    exit 1
}

# Output as JSON
$result = @{
    format = $format
    total_tasks = $tasks.Count
    tasks = $tasks
}

$result | ConvertTo-Json -Depth 10 -Compress
