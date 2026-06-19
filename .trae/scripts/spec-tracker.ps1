# spec-tracker.ps1 â€?Spec Lifecycle Manager
# Manages spec.md files with progress tracking, auto-update, and change logging

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("init","update","link","verify","delta","summary")]
    [string]$Action,

    [string]$TaskName,

    [string]$ScenarioId,

    [ValidateSet("pending","in-progress","done")]
    [string]$Status,

    [string[]]$Tasks,

    [string]$Agent,

    [string[]]$Files
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$WorkspaceRoot = "E:\UEGameDevelopment"
$TasksRoot = Join-Path $WorkspaceRoot ".trae\tasks"

function Get-SpecPath {
    param([string]$Name)
    if (-not $Name) {
        # Try to detect from .task.yaml
        $taskFiles = Get-ChildItem -LiteralPath $TasksDir -Recurse -Filter ".task.yaml" -Depth 1 -ErrorAction SilentlyContinue
        $active = $taskFiles | Where-Object {
            $yaml = Get-Content -LiteralPath $_.FullName -Raw
            $yaml -match 'phase:\s*(implement|review|verify)'
        }
        if ($active) {
            $Name = Split-Path -Parent $active[0].FullName | Split-Path -Leaf
        }
        else {
            throw "No active task found. Use -TaskName to specify."
        }
    }
    return Join-Path $TasksDir $Name
}

function Read-Spec {
    param([string]$SpecPath)
    if (-not (Test-Path -LiteralPath $SpecPath)) {
        Write-Host "[spec-tracker] Spec not found: $SpecPath"
        return $null
    }
    return Get-Content -LiteralPath $SpecPath -Raw
}

function Write-Spec {
    param([string]$SpecPath, [string]$Content)
    $dir = Split-Path -Parent $SpecPath
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $Content | Set-Content -LiteralPath $SpecPath -Encoding UTF8
}

function Get-ScenariosFromSpec {
    param([string]$Content)
    $scenarios = @()
    $lines = $Content -split "`n"
    $currentScenario = $null
    foreach ($line in $lines) {
        if ($line -match '###\s+(S\d+):\s+(.+)') {
            if ($currentScenario) {
                $scenarios += $currentScenario
            }
            $currentScenario = @{
                id = $Matches[1]
                name = $Matches[2].Trim()
                status = "pending"
                tasks = @()
                files = @()
                verified_by = ""
            }
        }
        if ($currentScenario) {
            if ($line -match '\*\*Status\*\*:\s*\[(.)\]') {
                $marker = $Matches[1]
                $currentScenario.status = if ($marker -eq 'x') { "done" } elseif ($marker -eq '/') { "in-progress" } else { "pending" }
            }
            if ($line -match '\*\*Tasks\*\*:\s*(.+)') {
                $currentScenario.tasks = ($Matches[1] -split ',\s*' | Where-Object { $_ -ne 'â€? -and $_ -ne '' })
            }
            if ($line -match '\*\*Linked files\*\*:\s*(.+)') {
                $currentScenario.files = ($Matches[1] -split ',\s*' | Where-Object { $_ -ne 'â€? -and $_ -ne '' })
            }
        }
    }
    if ($currentScenario) {
        $scenarios += $currentScenario
    }
    return $scenarios
}

function Get-ProgressSummary {
    param([string]$Content)
    $lines = $Content -split "`n"
    $summaryLines = @()
    $inTable = $false
    foreach ($line in $lines) {
        if ($line -match '^\|\s*Scenario\s*\|') {
            $inTable = $true
            continue
        }
        if ($inTable) {
            if ($line -match '^\s*$' -and $summaryLines.Count -gt 0) {
                break
            }
            if ($line -match '^\|') {
                $summaryLines += $line
            }
            elseif ($line -match '^\s*$') {
                if ($summaryLines.Count -gt 0) {
                    break
                }
            }
        }
    }
    return $summaryLines
}

function Update-ProgressSummary {
    param([array]$Scenarios)
    $lines = @()
    foreach ($s in $Scenarios) {
        $marker = if ($s.status -eq "done") { "x" } elseif ($s.status -eq "in-progress") { "/" } else { " " }
        $tasks = if ($s.tasks.Count -gt 0) { ($s.tasks -join ', ') } else { "â€? }
        $verified = if ($s.verified_by) { $s.verified_by } else { "â€? }
        $files = if ($s.files.Count -gt 0) { ($s.files | ForEach-Object { Split-Path -Leaf $_ }) -join ', ' } else { "â€? }
        $lines += "| S$($s.id): $($s.name) | [$marker] | $tasks | $verified | $files |"
    }
    return $lines
}

function Add-ChangeLog {
    param([string]$Content, [string]$Change, [string]$Reason)
    $date = Get-Date -Format "yyyy-MM-dd HH:mm"
    $entry = "| $date | $Change | $Reason |"
    $content = $Content -replace '(\|------\|------\|------\|)', ('|------|------|------|' + "`n" + $entry)
    return $content
}

function Update-StatusLine {
    param([string]$Content, [string]$NewStatus)
    return $Content -replace '\*\*Status\*\*:\s*`[^`]+`', "**Status**: ``$NewStatus``"
}

function Get-TaskDir {
    param([string]$Name)
    if (-not $Name) {
        $taskFiles = Get-ChildItem -LiteralPath $TasksDir -Recurse -Filter ".task.yaml" -Depth 1 -ErrorAction SilentlyContinue
        $all = $taskFiles | Where-Object {
            $yaml = Get-Content -LiteralPath $_.FullName -Raw
            $yaml -match 'task_id:'
        }
        if ($all.Count -gt 0) {
            $Name = Split-Path -Parent $all[0].FullName | Split-Path -Leaf
        }
        else {
            throw "No tasks found. Use -TaskName."
        }
    }
    return Join-Path $TasksDir $Name
}

# ===== Actions =====

switch ($Action) {
    "init" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Join-Path $dir "spec.md"
        if (Test-Path -LiteralPath $specPath) {
            Write-Host "[spec-tracker] Spec exists, skipping init."
            break
        }
        $template = Get-Content -LiteralPath "$WorkspaceRoot\.trae\scripts\spec-template.md" -Raw
        $template = $template -replace '<task-name>', (Split-Path -Leaf $dir)
        $template = $template -replace '<date>', (Get-Date -Format "yyyy-MM-dd HH:mm")
        $template = $template -replace '<auto-filled>', (Get-Date -Format "yyyy-MM-dd HH:mm")
        $template = Update-StatusLine -Content $template -NewStatus "plan"
        Write-Spec -SpecPath $specPath -Content $template
        Write-Host "[spec-tracker] Created: $specPath"
    }

    "update" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Join-Path $dir "spec.md"
        $content = Read-Spec -SpecPath $specPath
        if (-not $content) { break }

        $scenarios = Get-ScenariosFromSpec -Content $content
        if ($ScenarioId) {
            $match = $scenarios | Where-Object { $_.id -eq $ScenarioId }
            if ($match) {
                $oldStatus = $match.status
                $match.status = $Status
                if ($Files) { $match.files += $Files }
                $content = Add-ChangeLog -Content $content -Change "Updated $ScenarioId from $oldStatus â†?$Status" -Reason "Task progress"
            }
            else {
                # Append new scenario
                $newScenario = @{
                    id = $ScenarioId
                    name = "New Scenario"
                    status = $Status
                    tasks = @()
                    files = @()
                    verified_by = ""
                }
                $scenarios += $newScenario
                $content = Add-ChangeLog -Content $content -Change "Added $ScenarioId" -Reason "Discovered during implementation"
            }
        }

        # Rebuild Progress Summary
        $newSummary = Update-ProgressSummary -Scenarios $scenarios
        $lines = $content -split "`n"
        $output = @()
        $inOldSummary = $false
        $summaryReplaced = $false
        foreach ($line in $lines) {
            if ($line -match '^\|\s*Scenario\s*\|' -and -not $summaryReplaced) {
                $inOldSummary = $true
                $output += $line
                $output += "|----------|--------|----------|-------------|-------------|"
                $output += $newSummary
                $output += ""
                $summaryReplaced = $true
                continue
            }
            if ($inOldSummary) {
                if ($line -match '^\s*$' -and $output[-1] -eq "") {
                    continue
                }
                if ($line -match '^##\s') {
                    $inOldSummary = $false
                    $output += $line
                    continue
                }
                if ($line -match '^\s*$') {
                    continue
                }
                if (-not ($line -match '^\|')) {
                    $inOldSummary = $false
                    $output += $line
                }
                continue
            }
            $output += $line
        }

        # Check if all scenarios done
        $allDone = ($scenarios | Where-Object { $_.status -ne "done" }).Count -eq 0
        if ($allDone) {
            $output = $output -replace '\*\*Status\*\*:\s*`[^`]+`', "**Status**: ``review``"
        }
        else {
            $output = $output -replace '\*\*Status\*\*:\s*`[^`]+`', "**Status**: ``implement``"
        }

        $newContent = $output -join "`n"
        Write-Spec -SpecPath $specPath -Content $newContent
        Write-Host "[spec-tracker] Updated: $ScenarioId â†?$Status"
    }

    "link" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Join-Path $dir "spec.md"
        $content = Read-Spec -SpecPath $specPath
        if (-not $content) { break }

        $scenarios = Get-ScenariosFromSpec -Content $content
        if ($ScenarioId) {
            $match = $scenarios | Where-Object { $_.id -eq $ScenarioId }
            if ($match) {
                if ($Tasks) { $match.tasks += $Tasks }
                if ($Files) { $match.files += $Files }
                $newSummary = Update-ProgressSummary -Scenarios $scenarios
                $lines = $content -split "`n"
                $output = @()
                $inOldSummary = $false
                $summaryReplaced = $false
                foreach ($line in $lines) {
                    if ($line -match '^\|\s*Scenario\s*\|' -and -not $summaryReplaced) {
                        $inOldSummary = $true
                        $output += $line
                        $output += "|----------|--------|----------|-------------|-------------|"
                        $output += $newSummary
                        $output += ""
                        $summaryReplaced = $true
                        continue
                    }
                    if ($inOldSummary) {
                        if ($line -match '^##\s') { $inOldSummary = $false; $output += $line; continue }
                        if ($line -match '^\s*$') { continue }
                        if (-not ($line -match '^\|')) { $inOldSummary = $false; $output += $line }
                        continue
                    }
                    $output += $line
                }
                $newContent = $output -join "`n"
                Write-Spec -SpecPath $specPath -Content $newContent
                Write-Host "[spec-tracker] Linked: $ScenarioId â†?Tasks: $($Tasks -join ','), Files: $($Files -join ',')"
            }
        }
    }

    "verify" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Join-Path $dir "spec.md"
        $content = Read-Spec -SpecPath $specPath
        if (-not $content) { break }

        $scenarios = Get-ScenariosFromSpec -Content $content
        if ($ScenarioId) {
            $match = $scenarios | Where-Object { $_.id -eq $ScenarioId }
            if ($match) {
                $match.verified_by = $Agent
                $match.status = "done"
                $newSummary = Update-ProgressSummary -Scenarios $scenarios
                $content = Add-ChangeLog -Content $content -Change "Verified $ScenarioId by $Agent" -Reason "Verification passed"
                $allDone = ($scenarios | Where-Object { $_.status -ne "done" }).Count -eq 0
                if ($allDone) {
                    $content = Update-StatusLine -Content $content -NewStatus "complete"
                }
                $lines = $content -split "`n"
                $output = @()
                $inOldSummary = $false
                $summaryReplaced = $false
                foreach ($line in $lines) {
                    if ($line -match '^\|\s*Scenario\s*\|' -and -not $summaryReplaced) {
                        $inOldSummary = $true
                        $output += $line
                        $output += "|----------|--------|----------|-------------|-------------|"
                        $output += $newSummary
                        $output += ""
                        $summaryReplaced = $true
                        continue
                    }
                    if ($inOldSummary) {
                        if ($line -match '^##\s') { $inOldSummary = $false; $output += $line; continue }
                        if ($line -match '^\s*$') { continue }
                        if (-not ($line -match '^\|')) { $inOldSummary = $false; $output += $line }
                        continue
                    }
                    $output += $line
                }
                $newContent = $output -join "`n"
                Write-Spec -SpecPath $specPath -Content $newContent
                Write-Host "[spec-tracker] Verified: $ScenarioId by $Agent"
            }
        }
    }

    "delta" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Join-Path $dir "spec.md"
        $content = Read-Spec -SpecPath $specPath
        if (-not $content) { break }

        $scenarios = Get-ScenariosFromSpec -Content $content
        Write-Host "=== Spec Delta: $(Split-Path -Leaf $dir) ==="
        Write-Host ""
        $done = ($scenarios | Where-Object { $_.status -eq "done" }).Count
        $progress = ($scenarios | Where-Object { $_.status -eq "in-progress" }).Count
        $pending = ($scenarios | Where-Object { $_.status -eq "pending" }).Count
        Write-Host "Complete: $done | In Progress: $progress | Pending: $pending"
        Write-Host ""
        Write-Host "Change log (last 5):"
        $clLines = $content -split "`n"
        $inCL = $false
        $clCount = 0
        foreach ($l in $clLines) {
            if ($l -eq "## Change Log") { $inCL = $true; continue }
            if ($inCL) {
                if ($l -match '^\|' -and $l -notmatch 'Date\|Change') {
                    if ($clCount -lt 5) {
                        Write-Host "  $($l.Trim())"
                        $clCount++
                    }
                }
                if ($l -match '^##\s' -and $l -notmatch 'Change Log') { break }
            }
        }
    }

    "summary" {
        $dir = Get-TaskDir -Name $TaskName
        $specPath = Join-Path $dir "spec.md"
        $content = Read-Spec -SpecPath $specPath
        if (-not $content) { break }

        $summaryLines = Get-ProgressSummary -Content $content
        Write-Host "=== Spec Summary: $(Split-Path -Leaf $dir) ==="
        Write-Host ""
        if ($content -match '\*\*Status\*\*:\s*`([^`]+)`') {
            Write-Host "Status: $($Matches[1])"
        }
        Write-Host ""
        Write-Host "| Scenario | Status | Task IDs | Verified By | File Impact |"
        Write-Host "|----------|--------|----------|-------------|-------------|"
        foreach ($l in $summaryLines) {
            Write-Host $l.Trim()
        }
    }
}
