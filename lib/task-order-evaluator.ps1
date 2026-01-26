# Task Order Evaluator for Smart Ralph Multi-Task Support
# Analyzes tasks and generates AI-driven execution order

$ErrorActionPreference = "Stop"

# Build AI prompt for task order evaluation
function Build-TaskOrderPrompt {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    $taskList = ""
    $taskIndex = 1

    foreach ($task in $Tasks) {
        $taskList += "$taskIndex. Title: $($task.title)`n"
        $taskList += "   Description: $($task.description)`n"

        if ($task.acceptance_criteria -and $task.acceptance_criteria.Count -gt 0) {
            $criteria = ($task.acceptance_criteria | ForEach-Object { $_.text }) -join ", "
            $taskList += "   Acceptance Criteria: $criteria`n"
        }

        $taskList += "`n"
        $taskIndex++
    }

    $prompt = @"
Analyze the following tasks and determine the optimal execution order:

Task List:
$taskList

Please analyze:
1. Dependencies between tasks (which tasks depend on others)
2. Task complexity (simple/medium/complex)
3. Recommended execution order

Output format (JSON):
{
  "analysis": {
    "dependencies": {
      "task_2": ["task_1"],
      "task_3": ["task_1"]
    },
    "complexity": {
      "task_1": "medium",
      "task_2": "simple",
      "task_3": "complex"
    },
    "recommended_order": [1, 2, 3],
    "reasoning": "Task 1 is the foundation and must be completed first. Tasks 2 and 3 both depend on task 1..."
  }
}

Please output the JSON within <task-order-analysis> tags.
"@

    return $prompt
}

# Parse AI analysis from output
function Parse-AIAnalysis {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Output
    )

    # Extract JSON from <task-order-analysis> tags
    $pattern = '<task-order-analysis>\s*(\{.*?\})\s*</task-order-analysis>'
    $match = [regex]::Match($Output, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if (-not $match.Success) {
        Write-Warning "No <task-order-analysis> tags found in output. Using default order."
        return $null
    }

    $jsonText = $match.Groups[1].Value.Trim()

    try {
        $analysis = $jsonText | ConvertFrom-Json

        # Validate structure
        if (-not $analysis.analysis) {
            Write-Warning "Invalid analysis structure. Using default order."
            return $null
        }

        if (-not $analysis.analysis.recommended_order) {
            Write-Warning "No recommended_order found. Using default order."
            return $null
        }

        return $analysis.analysis
    } catch {
        Write-Warning "Failed to parse AI analysis JSON: $_. Using default order."
        return $null
    }
}

# Generate default order (sequential)
function Get-DefaultTaskOrder {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    $order = @()
    foreach ($task in $Tasks) {
        $order += $task.id
    }

    return @{
        dependencies = @{}
        complexity = @{}
        recommended_order = $order
        reasoning = "Default sequential order (no AI analysis available)"
    }
}

# Invoke task order evaluation
# Note: This function returns a prompt that should be sent to Claude
# The actual AI evaluation happens in the Ralph Loop
function Invoke-TaskOrderEvaluation {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks
    )

    if ($Tasks.Count -eq 0) {
        Write-Error "No tasks provided for evaluation"
        return $null
    }

    if ($Tasks.Count -eq 1) {
        # Single task - no ordering needed
        return @{
            dependencies = @{}
            complexity = @{ "task_1" = "simple" }
            recommended_order = @($Tasks[0].id)
            reasoning = "Single task - no ordering needed"
        }
    }

    # Build the evaluation prompt
    $prompt = Build-TaskOrderPrompt -Tasks $Tasks

    return @{
        prompt = $prompt
        defaultOrder = Get-DefaultTaskOrder -Tasks $Tasks
    }
}

# Validate task order
function Test-TaskOrder {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,

        [Parameter(Mandatory=$true)]
        [array]$Order
    )

    # Check if all task IDs are present
    $taskIds = $Tasks | ForEach-Object { $_.id }

    foreach ($orderId in $Order) {
        if ($orderId -notin $taskIds) {
            Write-Warning "Task ID $orderId in order not found in task list"
            return $false
        }
    }

    # Check if all tasks are in the order
    foreach ($taskId in $taskIds) {
        if ($taskId -notin $Order) {
            Write-Warning "Task ID $taskId not found in recommended order"
            return $false
        }
    }

    return $true
}

# Reorder tasks based on AI analysis
function Invoke-TaskReordering {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,

        [Parameter(Mandatory=$true)]
        [hashtable]$Analysis
    )

    $order = $Analysis.recommended_order

    # Validate order
    if (-not (Test-TaskOrder -Tasks $Tasks -Order $order)) {
        Write-Warning "Invalid task order detected. Using default order."
        $defaultAnalysis = Get-DefaultTaskOrder -Tasks $Tasks
        $order = $defaultAnalysis.recommended_order
    }

    # Reorder tasks
    $orderedTasks = @()
    foreach ($taskId in $order) {
        $task = $Tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
        if ($task) {
            $orderedTasks += $task
        }
    }

    return $orderedTasks
}

# Functions are exported automatically when imported as a module
