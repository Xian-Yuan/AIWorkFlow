?# Task Metrics �?Agent 评估指标收集
# 用法: task-metrics.ps1 <task-name>
# 输出: 写入 .trae/tasks/<task-name>/metrics.yaml

param(
    [Parameter(Mandatory=$true)][string]$TaskName
)

$ErrorActionPreference = "Stop"

$TASKS_ROOT = ".trae\tasks"; $PROJECTS = @("airpgweb", "characterdesigntool", "rts", "_shared")
$resolved = Resolve-TaskPath $TaskName; $TASK_DIR = $resolved.Dir
$YAML_FILE = Join-Path $TASK_DIR ".task.yaml"
$METRICS_FILE = Join-Path $TASK_DIR "metrics.yaml"

function Get-YamlField {
    param([string]$Field)
    if (-not (Test-Path $YAML_FILE)) { return $null }
    $line = Select-String -Path $YAML_FILE -Pattern "^${Field}:" | Select-Object -First 1
    if ($null -eq $line) { return $null }
    $value = $line.Line -replace "^${Field}:\s*", ""
    $value = $value.Trim() -replace '^["'']|["'']$', ''
    if ($value -eq "null") { return $null }
    return $value
}

$tasksFile = Join-Path $TASK_DIR "tasks.md"
$totalTasks = 0
$doneTasks = 0
if (Test-Path $tasksFile) {
    $content = Get-Content $tasksFile -Raw
    $totalTasks = ([regex]::Matches($content, '-\s+\[')).Count
    $doneTasks = ([regex]::Matches($content, '-\s+\[x\]')).Count
}

$phase = Get-YamlField "phase"
$workflow = Get-YamlField "workflow"
$reviewResult = Get-YamlField "review_result"
$verifyResult = Get-YamlField "verify_result"
$archived = Get-YamlField "archived"
$createdAt = Get-YamlField "created_at"
$verifiedAt = Get-YamlField "verified_at"
$projectType = Get-YamlField "project_type"

$successRate = if ($totalTasks -gt 0) { [math]::Round($doneTasks / $totalTasks * 100, 1) } else { 0 }

# 阶段耗时估算（基�?.task.yaml 的时间戳字段�?$daysActive = ""
if ($createdAt -and $createdAt -ne "null") {
    try {
        $created = [datetime]::Parse($createdAt)
        $daysActive = [math]::Round(((Get-Date) - $created).TotalDays, 1)
    } catch { }
}

# 回退检测：如果 phase �?implement �?review_result �?fail，表示曾发生回退
$hasRollback = ($reviewResult -eq "fail") -or ($verifyResult -eq "fail")

@"
# Agent Evaluation Metrics �?$TaskName
collected_at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

project_type: $projectType
workflow: $workflow
phase: $phase
days_active: $daysActive

# 任务完成�?total_tasks: $totalTasks
done_tasks: $doneTasks
task_success_rate_pct: $successRate

# 审查结果
review_result: $reviewResult
verify_result: $verifyResult

# 回退
has_rollback: $hasRollback

# 归档
archived: $archived
verified_at: $verifiedAt
"@ | Set-Content -Path $METRICS_FILE -NoNewline

Write-Host "=== Agent Evaluation Metrics ===" -ForegroundColor Cyan
Write-Host "Project Type : $projectType" -ForegroundColor White
Write-Host "Workflow     : $workflow" -ForegroundColor White
Write-Host "Phase        : $phase" -ForegroundColor White
Write-Host "Days Active  : $daysActive" -ForegroundColor White
Write-Host "Tasks        : $doneTasks / $totalTasks ($successRate%)" -ForegroundColor $(if ($successRate -ge 100) { "Green" } elseif ($successRate -ge 50) { "Yellow" } else { "Red" })
Write-Host "Review       : $reviewResult" -ForegroundColor $(if ($reviewResult -eq "pass") { "Green" } else { "Yellow" })
Write-Host "Verify       : $verifyResult" -ForegroundColor $(if ($verifyResult -eq "pass") { "Green" } else { "Yellow" })
Write-Host "Rollback     : $hasRollback" -ForegroundColor $(if ($hasRollback) { "Red" } else { "Green" })
Write-Host "Metrics saved to: $METRICS_FILE" -ForegroundColor Gray
