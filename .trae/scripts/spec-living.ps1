# spec-living.ps1 â€?Living Spec Manager
# Manages the full lifecycle of a Living Spec: status, tasks, decisions, changelog, verification

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("init","task","decide","changelog","verify","status","onboard")]
    [string]$Action,

    [string]$TaskName,
    [string]$TaskId,
    [ValidateSet("pending","in-progress","done")]
    [string]$Status = "done",
    [string]$ScenarioId,
    [string]$Decision,
    [string]$Rationale,
    [string]$File,
    [ValidateSet("Added","Modified","Deleted")]
    [string]$ChangeType = "Modified",
    [string]$Description,
    [ValidateSet("Compile","Test","Runtime")]
    [string]$Check,
    [ValidateSet("pass","fail")]
    [string]$VerifyStatus,
    [string]$Detail
)

$ErrorActionPreference = "Stop"
$WorkspaceRoot = "E:\UEGameDevelopment"
$TasksRoot = Join-Path $WorkspaceRoot ".trae\tasks"

function Get-TaskDir {
    param([string]$Name)
    if (-not $Name) {
        $yamlFiles = Get-ChildItem -LiteralPath $TasksRoot -Recurse -Filter ".task.yaml" -Depth 2 -ErrorAction SilentlyContinue
        foreach ($f in $yamlFiles) {
            $phase = (Select-String -Path $f.FullName -Pattern "^(phase|archived):" | Select-Object -First 1).Line -replace "^\w+:\s*",""
            if ($phase -in @("plan","implement","review","verify")) {
                return Split-Path -Parent $f.FullName
            }
        }
        throw "No active task found. Use -TaskName."
    }
    return Join-Path $TasksRoot ($Name -replace "/", "\")
}

function Get-SpecPath { param([string]$Dir) return Join-Path $Dir "spec.md" }

function Read-Spec { param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    return Get-Content -LiteralPath $Path -Raw
}

function Write-Spec { param([string]$Path, [string]$Content)
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Update-Field {
    param([string]$Content, [string]$Field, [string]$Value)
    $pattern = "(?m)^- \*\*${Field}\*\*: .*$"
    if ($Content -match $pattern) {
        return $Content -replace $pattern, "- **${Field}**: ${Value}"
    }
    return $Content
}

function Update-ProgressCount {
    param([string]$Content)
    $doneMatch = [regex]::Matches($Content, '\|\s*T\d+\s*\|.*\|\s*S?\d*\s*\|\s*\[x\]')
    $totalMatch = [regex]::Matches($Content, '\|\s*T\d+\s*\|')
    $done = $doneMatch.Count
    $total = $totalMatch.Count
    $next = ""
    $lines = $Content -split "`n"
    foreach ($l in $lines) {
        if ($l -match '\|\s*(T\d+)\s*\|.*\|\s*S?\d*\s*\|\s*\[ \]') {
            $next = "$($Matches[1]): $($Matches[2] -replace '\|.*$','')".Trim() -replace '\s*\|\s*.*',''
            break
        }
        if ($l -match '\|\s*(T\d+)\s*\|.*\|\s*S?\d*\s*\|\s*\[/\]') {
            $next = "$($Matches[1]): $($Matches[2] -replace '\|.*$','')".Trim() -replace '\s*\|\s*.*',''
            break
        }
    }
    $Content = $Content -replace '(?m)^- \*\*Progress\*\*: .*$', "- **Progress**: $done/$total tasks done"
    if ($next) {
        $Content = $Content -replace '(?m)^- \*\*Next Step\*\*: .*$', "- **Next Step**: $next"
    }
    if ($done -eq $total -and $total -gt 0) {
        $Content = Update-Field $Content "Next Step" "All tasks complete - ready for review"
    }
    return $Content
}

switch ($Action) {
    "init" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Get-SpecPath $dir
        if (Test-Path -LiteralPath $specPath) {
            Write-Host "[spec-living] Spec exists, skipping init."
            break
        }
        $template = Get-Content -LiteralPath "$WorkspaceRoot\.trae\scripts\spec-living-template.md" -Raw
        $today = Get-Date -Format "yyyy-MM-dd HH:mm"
        $template = $template -replace '<task-name>', (Split-Path -Leaf $dir)
        $template = $template -replace '<auto-filled>', $today
        Write-Spec $specPath $template
        Write-Host "[spec-living] Created Living Spec: $specPath"
    }

    "task" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Get-SpecPath $dir
        $content = Read-Spec $specPath
        if (-not $content) { Write-Host "[spec-living] No spec found."; break }

        $now = Get-Date -Format "yyyy-MM-dd HH:mm"
        $marker = if ($Status -eq "done") { "x" } elseif ($Status -eq "in-progress") { "/" } else { " " }

        # Update task row in Implementation Progress
        $pattern = "(\| ${TaskId} \|.*\| S?\d* \|) \[[ x/]?\] (\|.*\|)"
        $replacement = "`${1} [${marker}] `${2}"
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacement
        }

        # Update scenario status if linked
        if ($ScenarioId) {
            $scPattern = if ($Status -eq "done") { "x" } elseif ($Status -eq "in-progress") { "/" } else { " " }
            $scLine = "#### ${ScenarioId}:"
            $statusLine = "\*\*Status\*\*:\s*\[[ x/]?\]"
            $content = $content -replace "($scLine[\s\S]*?)${statusLine}", "`${1}**Status**: [${scPattern}]"
        }

        # Set completion timestamp
        if ($Status -eq "done") {
            $content = $content -replace "(\| ${TaskId} \|.*\| S?\d* \| \[x\] \|) .* (\|)", "`${1} ${now} `$2"
        }

        $content = Update-ProgressCount $content
        $content = Update-Field $content "Last Updated" $now
        Write-Spec $specPath $content
        Write-Host "[spec-living] Task $TaskId -> $Status"
    }

    "decide" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Get-SpecPath $dir
        $content = Read-Spec $specPath
        if (-not $content) { break }

        $now = Get-Date -Format "yyyy-MM-dd"
        $decisionRow = "| $now | $Decision | $Rationale | $Impact |"
        $content = $content -replace '(\| Date \| Decision \| Rationale \| Impact \|[\r\n]+\|------\|----------\|-----------\|--------\|\s*)', "`${1}${decisionRow}`n"

        $content = Update-Field $content "Last Updated" (Get-Date -Format "yyyy-MM-dd HH:mm")
        Write-Spec $specPath $content
        Write-Host "[spec-living] Decision recorded: $Decision"
    }

    "changelog" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Get-SpecPath $dir
        $content = Read-Spec $specPath
        if (-not $content) { break }

        $now = Get-Date -Format "yyyy-MM-dd HH:mm"
        $desc = if ($Description) { $Description } else { "$ChangeType $File" }
        $logRow = "| $now | $File | $ChangeType | $desc |"
        $content = $content -replace '(\| Date \| File \| Change Type \| Description \|[\r\n]+\|------\|------\|-------------\|-------------*\|\s*)', "`${1}${logRow}`n"

        $content = Update-Field $content "Last Updated" $now
        Write-Spec $specPath $content
        Write-Host "[spec-living] Change log: $File $ChangeType"
    }

    "verify" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Get-SpecPath $dir
        $content = Read-Spec $specPath
        if (-not $content) { break }

        $now = Get-Date -Format "yyyy-MM-dd HH:mm"
        $statusEmoji = if ($VerifyStatus -eq "pass") { "PASS" } else { "FAIL" }
        $detail = if ($Detail) { $Detail } else { $VerifyStatus }

        # Update verification table row
        $pattern = "(?m)^\| ${Check} \| .* \| .* \|$"
        $replacement = "| $Check | $statusEmoji | $detail |"
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacement
        }

        $content = Update-Field $content "Last Updated" $now
        Write-Spec $specPath $content
        Write-Host "[spec-living] Verify $Check = $statusEmoji"
    }

    "status" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Get-SpecPath $dir
        $content = Read-Spec $specPath
        if (-not $content) { Write-Host "[spec-living] No spec found."; break }

        $now = Get-Date -Format "yyyy-MM-dd HH:mm"
        $content = Update-ProgressCount $content
        $content = Update-Field $content "Last Updated" $now

        # Detect phase from tasks.md or .task.yaml
        $yaml = Join-Path $dir ".task.yaml"
        if (Test-Path -LiteralPath $yaml) {
            $phase = (Select-String -Path $yaml -Pattern "^phase:" | Select-Object -First 1).Line -replace "phase:\s*",""
            $content = Update-Field $content "Current Phase" $phase
        }

        Write-Spec $specPath $content
        Write-Host "[spec-living] Status refreshed."
    }

    "onboard" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Get-SpecPath $dir
        $content = Read-Spec $specPath
        if (-not $content) { Write-Host "[spec-living] No spec found. Run init first."; break }

        # Extract key fields
        $phase = if ($content -match '(?m)^- \*\*Current Phase\*\*: (.+)$') { $Matches[1] } else { "unknown" }
        $progress = if ($content -match '(?m)^- \*\*Progress\*\*: (.+)$') { $Matches[1] } else { "unknown" }
        $next = if ($content -match '(?m)^- \*\*Next Step\*\*: (.+)$') { $Matches[1] } else { "-" }
        $blockers = if ($content -match '(?m)^- \*\*Blockers\*\*: (.+)$') { $Matches[1] } else { "None" }

        $decisionsCount = ([regex]::Matches($content, '^\| \d{4}-\d{2}-\d{2} \|').Count)
        $scenariosCount = ([regex]::Matches($content, '^#### S\d+:').Count)

        $compile = if ($content -match '(?m)^\| Compile \| (.+?) \|') { $Matches[1] } else { "-" }
        $test = if ($content -match '(?m)^\| Test \| (.+?) \|') { $Matches[1] } else { "-" }

        Write-Host ""
        Write-Host "============================================"
        Write-Host "  LIVING SPEC: $(Split-Path -Leaf $dir)"
        Write-Host "============================================"
        Write-Host "Phase: $phase | Progress: $progress"
        Write-Host "Next: $next"
        Write-Host "Decisions: $decisionsCount | Scenarios: $scenariosCount | Blockers: $blockers"
        Write-Host "Verify: Compile $compile | Test $test"
        Write-Host "============================================"
        Write-Host ""
    }
}
