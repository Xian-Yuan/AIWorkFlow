# Basic Memory Retrieval And Mem0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为当前工作区落地 `Basic Memory` 第二阶段：新增本地 failure memory 检索脚本、`Mem0` 本地实验接入与同步脚本，并把 `Router + Implement` 的 memory 检索从文档契约升级成真实脚本调用。

**Architecture:** 继续坚持 `Docs/Memory/` 是主真相源，新增统一的 `.trae/scripts/memory-retrieve.ps1` 作为检索入口。`Mem0` 采用本地实验方式接入，但在当前 PowerShell 工作流中优先使用其自托管 REST API，而不是把 Python/Node SDK 直接嵌进 agent 提示链；脚本始终先查本地索引和正式 memory，再按需补查 `Mem0`，保证 fail-soft 回退。

**Tech Stack:** PowerShell 5, Markdown frontmatter parsing, JSON config, Mem0 OSS self-hosted REST API, Docker Desktop

---

## File Map

**Create**
- `.trae/memory/mem0.config.json`
- `.trae/scripts/mem0-healthcheck.ps1`
- `.trae/scripts/memory-retrieve.ps1`
- `.trae/scripts/mem0-sync.ps1`
- `.trae/scripts/test-memory-retrieval.ps1`
- `Docs/Memory/failures/2026-05-31-router-save-system-missing-memory.md`

**Modify**
- `Docs/Memory/README.md`
- `Docs/Memory/indexes/memory-index.md`
- `Docs/AI/01-AI-Development-Playbook.md`
- `Docs/AI/02-Project-Truth-Source.md`
- `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`
- `CLAUDE.md`
- `.opencode/agents/ue-project-router.md`
- `.opencode/agents/ue-lyra-gas-implementer.md`
- `.opencode/agents/web-implementer.md`
- `.opencode/agents/code-quality-reviewer.md`
- `.trae/skills/ue-project-router/SKILL.md`

**Verification**
- PowerShell parser check for all new scripts
- `GetDiagnostics` on every edited file
- Run `.trae/scripts/test-memory-retrieval.ps1`
- Run targeted `memory-retrieve.ps1` commands for router and implement scopes

## External Implementation Notes

- Mem0 OSS supports two self-hosted paths: library mode and self-hosted server mode. For this workspace, use the self-hosted REST server because current automation is PowerShell-first and already favors scriptable HTTP entry points. See [Mem0 Overview](https://docs.mem0.ai/open-source/overview), [Self-Hosted Setup](https://docs.mem0.ai/open-source/setup), and [REST API Server](https://docs.mem0.ai/open-source/features/rest-api).
- Local self-hosted development exposes the API on `http://localhost:8888` by default when using the official server stack. Do not assume cloud endpoints or platform-only `/v1/` routes.
- The plan keeps `Mem0` disabled by default. Scripts must work when no local Mem0 service is running.

### Task 1: Add Local Mem0 Config And Health Check

**Files:**
- Create: `.trae/memory/mem0.config.json`
- Create: `.trae/scripts/mem0-healthcheck.ps1`
- Modify: `Docs/Memory/README.md`
- Modify: `Docs/AI/02-Project-Truth-Source.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Create the local Mem0 config file**

Write `.trae/memory/mem0.config.json` with this initial content:

```json
{
  "enabled": false,
  "mode": "local-experiment",
  "endpoint": "http://127.0.0.1:8888",
  "project": "UEGameDevelopment",
  "use_for_scopes": ["router", "implement"],
  "sync_only_promoted_failures": true,
  "max_results_router": 3,
  "max_results_implement": 2,
  "timeout_ms": 1500
}
```

This must stay secret-free. Do not add API keys or tokens to the repo.

- [ ] **Step 2: Write the health-check script**

Create `.trae/scripts/mem0-healthcheck.ps1` with these functions and command flow:

```powershell
param(
    [string]$ConfigPath = ".trae\memory\mem0.config.json"
)

$ErrorActionPreference = "Stop"

function Read-Mem0Config {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return @{ status = "misconfigured"; reason = "config_missing" }
    }
    try {
        $json = Get-Content $Path -Raw | ConvertFrom-Json -AsHashtable
        return @{ status = "ok"; config = $json }
    } catch {
        return @{ status = "misconfigured"; reason = "config_invalid_json" }
    }
}

function Test-Mem0Endpoint {
    param([string]$Endpoint, [int]$TimeoutMs)
    try {
        $response = Invoke-WebRequest -Uri $Endpoint -Method Get -TimeoutSec ([Math]::Ceiling($TimeoutMs / 1000.0))
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
    } catch {
        return $false
    }
}

$configResult = Read-Mem0Config -Path $ConfigPath
if ($configResult.status -ne "ok") {
    [pscustomobject]@{
        status = $configResult.status
        reason = $configResult.reason
    } | ConvertTo-Json -Depth 4
    exit 0
}

$config = $configResult.config
if (-not $config.enabled) {
    [pscustomobject]@{
        status = "unavailable"
        reason = "disabled"
        endpoint = $config.endpoint
    } | ConvertTo-Json -Depth 4
    exit 0
}

$reachable = Test-Mem0Endpoint -Endpoint $config.endpoint -TimeoutMs ([int]$config.timeout_ms)

[pscustomobject]@{
    status = $(if ($reachable) { "available" } else { "unavailable" })
    reason = $(if ($reachable) { "ok" } else { "endpoint_unreachable" })
    endpoint = $config.endpoint
    mode = $config.mode
} | ConvertTo-Json -Depth 4
```

- [ ] **Step 3: Verify the health-check script parses**

Run:

```powershell
powershell -NoProfile -Command "[void][System.Management.Automation.Language.Parser]::ParseFile('g:\UEGameDevelopment\.trae\scripts\mem0-healthcheck.ps1',[ref]$null,[ref]$null); 'PARSE_OK'"
```

Expected: `PARSE_OK`

- [ ] **Step 4: Register Phase 2 memory files in docs**

Update docs so the workspace knows these new files are official:

```md
- `.trae/memory/mem0.config.json`：Mem0 本地实验配置
- `.trae/scripts/mem0-healthcheck.ps1`：Mem0 可用性检查
- `.trae/scripts/memory-retrieve.ps1`：统一 failure memory 检索入口
- `.trae/scripts/mem0-sync.ps1`：正式 memory 同步到 Mem0
```

Add the above to `Docs/AI/02-Project-Truth-Source.md` and `CLAUDE.md`. In `Docs/Memory/README.md`, add one short section:

```md
## Phase 2 Retrieval

- local retrieval is handled by `.trae/scripts/memory-retrieve.ps1`
- Mem0 is optional and must pass `.trae/scripts/mem0-healthcheck.ps1`
- local files remain the source of truth
```

- [ ] **Step 5: Run diagnostics on the new config/docs files**

Run diagnostics on:

```text
file:///g:/UEGameDevelopment/.trae/scripts/mem0-healthcheck.ps1
file:///g:/UEGameDevelopment/Docs/Memory/README.md
file:///g:/UEGameDevelopment/Docs/AI/02-Project-Truth-Source.md
file:///g:/UEGameDevelopment/CLAUDE.md
```

Expected: `0 diagnostics` for Markdown files, no PowerShell syntax diagnostics if available.

### Task 2: Seed One Real Failure Memory And Local Index Entry

**Files:**
- Create: `Docs/Memory/failures/2026-05-31-router-save-system-missing-memory.md`
- Modify: `Docs/Memory/indexes/memory-index.md`
- Test: `.trae/scripts/test-memory-retrieval.ps1`

- [ ] **Step 1: Create a real promoted failure memory**

Write `Docs/Memory/failures/2026-05-31-router-save-system-missing-memory.md`:

```md
---
id: memory-router-save-system-missing-2026-05-31
type: failure_memory
phase: plan
project_type: ue5
module: router
tags:
  - router
  - save
  - implicit-requirement
severity: high
write_trigger: verify_fail
retrieval_scope:
  - router
  - implement
token_budget: small
mem0_sync_status: not_synced
mem0_memory_id: null
memory_version: v1
---

# 路由阶段遗漏保存系统前置依赖

## Symptom
用户提出“退出时提醒是否保存”，agent 直接实现弹窗，没有先确认保存系统是否存在。

## Root Cause
把表层 UI 需求当成独立需求，没有反向推导 SaveGame、dirty state 和退出流程依赖。

## Bad Pattern
- 看到退出弹窗需求就直接做 UI
- 没有先追问保存系统
- 没有在 Plan 阶段识别隐式依赖

## Correct Rule
当需求涉及保存、退出确认、继续游戏或加载状态时，先确认保存系统是否存在，再决定是否实现 UI 提醒。

## Retrieval Hint
适用于 router 和 implement 阶段对 save/load/exit 类需求的预提醒。

## Verification
routing.md 或 analysis.md 必须明确保存系统依赖，或明确记录“当前无保存系统，需要用户确认”。
```

- [ ] **Step 2: Add a matching index row**

Append this row to `Docs/Memory/indexes/memory-index.md`:

```md
| memory-router-save-system-missing-2026-05-31 | 路由阶段遗漏保存系统前置依赖 | plan | router | high | router,implement | router,save,implicit-requirement | ./../failures/2026-05-31-router-save-system-missing-memory.md |
```

- [ ] **Step 3: Create a retrieval test runner**

Create `.trae/scripts/test-memory-retrieval.ps1` with focused positive and negative checks:

```powershell
$ErrorActionPreference = "Stop"

function Assert-Contains {
    param([string]$Text, [string]$Expected, [string]$Label)
    if ($Text -notmatch [Regex]::Escape($Expected)) {
        throw "ASSERT FAIL [$Label]: expected '$Expected'"
    }
}

function Assert-Equals {
    param($Actual, $Expected, [string]$Label)
    if ($Actual -ne $Expected) {
        throw "ASSERT FAIL [$Label]: expected '$Expected', got '$Actual'"
    }
}

$routerOutput = & "g:\UEGameDevelopment\.trae\scripts\memory-retrieve.ps1" `
  -Phase plan `
  -ProjectType ue5 `
  -Scope router `
  -Module router `
  -Tags @("save","implicit-requirement") `
  -Limit 2 `
  -UseMem0 $false `
  -TaskName regression-memory

Assert-Contains -Text $routerOutput -Expected "Relevant Failure Memories" -Label "router-header"
Assert-Contains -Text $routerOutput -Expected "先确认保存系统是否存在" -Label "router-rule"

$emptyOutput = & "g:\UEGameDevelopment\.trae\scripts\memory-retrieve.ps1" `
  -Phase implement `
  -ProjectType web `
  -Scope implement `
  -Module ui `
  -Tags @("unrelated-tag") `
  -Limit 1 `
  -UseMem0 $false `
  -TaskName regression-memory

Assert-Equals -Actual ([string]::IsNullOrWhiteSpace($emptyOutput)) -Expected $true -Label "empty-result"

"MEMORY_RETRIEVAL_TESTS_PASS"
```

- [ ] **Step 4: Run the seeded file diagnostics**

Run diagnostics on:

```text
file:///g:/UEGameDevelopment/Docs/Memory/failures/2026-05-31-router-save-system-missing-memory.md
file:///g:/UEGameDevelopment/Docs/Memory/indexes/memory-index.md
```

Expected: `0 diagnostics`

### Task 3: Implement Local Retrieval Script

**Files:**
- Create: `.trae/scripts/memory-retrieve.ps1`
- Modify: `.opencode/agents/ue-project-router.md`
- Modify: `.opencode/agents/ue-lyra-gas-implementer.md`
- Modify: `.opencode/agents/web-implementer.md`
- Modify: `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`
- Test: `.trae/scripts/test-memory-retrieval.ps1`

- [ ] **Step 1: Write the local retrieval script**

Create `.trae/scripts/memory-retrieve.ps1` with these major parts:

```powershell
param(
    [Parameter(Mandatory=$true)][ValidateSet("plan","implement")][string]$Phase,
    [Parameter(Mandatory=$true)][ValidateSet("ue5","web","other")][string]$ProjectType,
    [Parameter(Mandatory=$true)][ValidateSet("router","implement")][string]$Scope,
    [Parameter(Mandatory=$true)][string]$Module,
    [string[]]$Tags = @(),
    [int]$Limit = 1,
    [bool]$UseMem0 = $false,
    [string]$TaskName = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$IndexPath = Join-Path $RepoRoot "Docs\Memory\indexes\memory-index.md"

function Get-IndexRows {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }
    $lines = Get-Content $Path
    $rows = @()
    foreach ($line in $lines) {
        if (-not $line.StartsWith("| memory-")) { continue }
        $parts = ($line.Trim("|") -split "\|").ForEach({ $_.Trim() })
        if ($parts.Count -lt 8) { continue }
        $rows += [pscustomobject]@{
            Id = $parts[0]
            Title = $parts[1]
            Phase = $parts[2]
            Module = $parts[3]
            Severity = $parts[4]
            Scope = $parts[5]
            Tags = $parts[6]
            File = $parts[7]
        }
    }
    return $rows
}

function Get-MemorySections {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw
    $badPattern = [regex]::Match($content, '## Bad Pattern\s*(?<body>[\s\S]*?)\s*## Correct Rule').Groups['body'].Value.Trim()
    $correctRule = [regex]::Match($content, '## Correct Rule\s*(?<body>[\s\S]*?)\s*## Retrieval Hint').Groups['body'].Value.Trim()
    $verification = [regex]::Match($content, '## Verification\s*(?<body>[\s\S]*)$').Groups['body'].Value.Trim()
    return [pscustomobject]@{
        BadPattern = ($badPattern -replace '\r?\n', ' ')
        CorrectRule = ($correctRule -replace '\r?\n', ' ')
        Verification = ($verification -replace '\r?\n', ' ')
    }
}

function Score-Row {
    param($Row, [string]$Phase, [string]$Module, [string[]]$Tags, [string]$Scope)
    $score = 0
    if ($Row.Phase -eq $Phase) { $score += 4 }
    if ($Row.Module -eq $Module) { $score += 3 }
    if ($Row.Scope -match [regex]::Escape($Scope)) { $score += 2 }
    foreach ($tag in $Tags) {
        if ($Row.Tags -match [regex]::Escape($tag)) { $score += 1 }
    }
    return $score
}

$rows = Get-IndexRows -Path $IndexPath | ForEach-Object {
    $row = $_
    $score = Score-Row -Row $row -Phase $Phase -Module $Module -Tags $Tags -Scope $Scope
    if ($score -gt 0) {
        [pscustomobject]@{ Row = $row; Score = $score }
    }
} | Sort-Object Score -Descending

$selected = $rows | Select-Object -First $Limit
if (-not $selected) { return "" }

$items = foreach ($entry in $selected) {
    $resolved = Join-Path (Split-Path $IndexPath -Parent) $entry.Row.File
    $sections = Get-MemorySections -FilePath $resolved
    [pscustomobject]@{
        Title = $entry.Row.Title
        BadPattern = $sections.BadPattern
        CorrectRule = $sections.CorrectRule
        Verification = $sections.Verification
    }
}

if ($Scope -eq "router") {
    $lines = @("Relevant Failure Memories")
    $i = 1
    foreach ($item in $items) {
        $lines += ("{0}. {1} Rule: {2} Verify: {3}" -f $i, $item.BadPattern, $item.CorrectRule, $item.Verification)
        $i++
    }
    $lines -join "`n"
} else {
    $lines = @("Pre-Edit Failure Reminder")
    $i = 1
    foreach ($item in $items) {
        $lines += ("{0}. {1} Rule: {2} Verify: {3}" -f $i, $item.BadPattern, $item.CorrectRule, $item.Verification)
        $i++
    }
    $lines -join "`n"
}
```

This first version only needs local retrieval and formatting. Do not add `Mem0` calls yet.

- [ ] **Step 2: Parse-check the retrieval script**

Run:

```powershell
powershell -NoProfile -Command "[void][System.Management.Automation.Language.Parser]::ParseFile('g:\UEGameDevelopment\.trae\scripts\memory-retrieve.ps1',[ref]$null,[ref]$null); 'PARSE_OK'"
```

Expected: `PARSE_OK`

- [ ] **Step 3: Run the retrieval tests**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "g:\UEGameDevelopment\.trae\scripts\test-memory-retrieval.ps1"
```

Expected: `MEMORY_RETRIEVAL_TESTS_PASS`

- [ ] **Step 4: Upgrade router and implementer prompts to use the script**

Replace the current “read `Docs/Memory/indexes/memory-index.md` manually” wording with concrete script calls.

In `.opencode/agents/ue-project-router.md`, add wording like:

```text
在依赖链推导前，优先执行：
& .\.trae\scripts\memory-retrieve.ps1 -Phase plan -ProjectType <ue5|web|other> -Scope router -Module <module> -Tags @(<tags>) -Limit 2 -UseMem0 $false -TaskName <task-name>
若脚本返回非空，输出 `Relevant Failure Memories` 摘要；若为空，不凑满。
```

In `.opencode/agents/ue-lyra-gas-implementer.md` and `.opencode/agents/web-implementer.md`, add:

```text
`can-edit` 通过后、首次编辑前，优先执行：
& .\.trae\scripts\memory-retrieve.ps1 -Phase implement -ProjectType <project-type> -Scope implement -Module <module> -Tags @(<tags>) -Limit 1 -UseMem0 $false -TaskName <task-name>
若返回非空，输出 `Pre-Edit Failure Reminder`；若为空，继续。
```

In `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md`, mirror the same behavior using short, hard constraints.

- [ ] **Step 5: Run diagnostics on prompt and script files**

Check diagnostics for:

```text
file:///g:/UEGameDevelopment/.trae/scripts/memory-retrieve.ps1
file:///g:/UEGameDevelopment/.opencode/agents/ue-project-router.md
file:///g:/UEGameDevelopment/.opencode/agents/ue-lyra-gas-implementer.md
file:///g:/UEGameDevelopment/.opencode/agents/web-implementer.md
file:///g:/UEGameDevelopment/Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md
```

Expected: no new diagnostics

### Task 4: Add Mem0 Fallback Retrieval And Sync

**Files:**
- Create: `.trae/scripts/mem0-sync.ps1`
- Modify: `.trae/scripts/memory-retrieve.ps1`
- Modify: `.opencode/agents/code-quality-reviewer.md`
- Modify: `.trae/skills/ue-project-router/SKILL.md`

- [ ] **Step 1: Extend the retrieval script with optional Mem0 fallback**

Add these helper functions into `.trae/scripts/memory-retrieve.ps1`:

```powershell
function Read-Mem0Health {
    $raw = & "g:\UEGameDevelopment\.trae\scripts\mem0-healthcheck.ps1"
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try { return $raw | ConvertFrom-Json -AsHashtable } catch { return $null }
}

function Search-Mem0 {
    param(
        [hashtable]$Health,
        [string]$Scope,
        [string]$Module,
        [string[]]$Tags,
        [int]$Limit
    )
    if (-not $Health -or $Health.status -ne "available") { return @() }

    $query = @($Module) + $Tags | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $payload = @{
        query = ($query -join " ")
        limit = $Limit
        filters = @{
            project = "UEGameDevelopment"
            scope = @($Scope)
        }
    } | ConvertTo-Json -Depth 6

    try {
        $result = Invoke-RestMethod -Uri ($Health.endpoint.TrimEnd("/") + "/memories/search") -Method Post -ContentType "application/json" -Body $payload -TimeoutSec 2
        return @($result.results)
    } catch {
        return @()
    }
}
```

Then update the selection flow:

```powershell
$health = $(if ($UseMem0) { Read-Mem0Health } else { $null })
$needsMem0 = ($UseMem0 -and (($Scope -eq "router" -and $items.Count -lt 2) -or ($Scope -eq "implement" -and $items.Count -lt 1)))
if ($needsMem0) {
    $mem0Items = Search-Mem0 -Health $health -Scope $Scope -Module $Module -Tags $Tags -Limit ($Limit - $items.Count)
    foreach ($hit in $mem0Items) {
        $items += [pscustomobject]@{
            Title = $hit.memory
            BadPattern = $hit.metadata.bad_pattern
            CorrectRule = $hit.metadata.correct_rule
            Verification = $hit.metadata.verification
        }
    }
}
```

Keep the script fail-soft. If `Mem0` is unavailable, local retrieval must still return successfully.

- [ ] **Step 2: Create the sync script**

Create `.trae/scripts/mem0-sync.ps1`:

```powershell
param(
    [string]$MemoryRoot = "g:\UEGameDevelopment\Docs\Memory\failures",
    [string]$ConfigPath = "g:\UEGameDevelopment\.trae\memory\mem0.config.json"
)

$ErrorActionPreference = "Stop"

function Get-FrontmatterValue {
    param([string]$Content, [string]$Field)
    $match = [regex]::Match($Content, "(?m)^$Field:\s*(.+)$")
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return $null
}

function Update-FrontmatterValue {
    param([string]$Path, [string]$Field, [string]$Value)
    $content = Get-Content $Path -Raw
    $pattern = "(?m)^$Field:\s*.*$"
    if ($content -match $pattern) {
        $content = $content -replace $pattern, "$Field: $Value"
    } else {
        throw "Missing frontmatter field: $Field"
    }
    Set-Content -Path $Path -Value $content -NoNewline
}

$health = & "g:\UEGameDevelopment\.trae\scripts\mem0-healthcheck.ps1" | ConvertFrom-Json -AsHashtable
if ($health.status -ne "available") {
    throw "Mem0 unavailable: $($health.reason)"
}

$files = Get-ChildItem -Path $MemoryRoot -Filter "*.md"
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $syncStatus = Get-FrontmatterValue -Content $content -Field "mem0_sync_status"
    if ($syncStatus -notin @("not_synced","stale","sync_failed")) { continue }

    $payload = @{
        messages = @(
            @{
                role = "system"
                content = "Failure memory sync"
            },
            @{
                role = "user"
                content = ([regex]::Match($content, "(?s)^---.*?---\s*(?<body>.*)$").Groups["body"].Value.Trim())
            }
        )
        metadata = @{
            bad_pattern = ([regex]::Match($content, '## Bad Pattern\s*(?<body>[\s\S]*?)\s*## Correct Rule').Groups['body'].Value.Trim() -replace '\r?\n', ' ')
            correct_rule = ([regex]::Match($content, '## Correct Rule\s*(?<body>[\s\S]*?)\s*## Retrieval Hint').Groups['body'].Value.Trim() -replace '\r?\n', ' ')
            verification = ([regex]::Match($content, '## Verification\s*(?<body>[\s\S]*)$').Groups['body'].Value.Trim() -replace '\r?\n', ' ')
            project = "UEGameDevelopment"
        }
        user_id = "workspace-memory"
    } | ConvertTo-Json -Depth 8

    try {
        $response = Invoke-RestMethod -Uri ($health.endpoint.TrimEnd("/") + "/memories") -Method Post -ContentType "application/json" -Body $payload -TimeoutSec 4
        Update-FrontmatterValue -Path $file.FullName -Field "mem0_sync_status" -Value "synced"
        if ($response.results -and $response.results[0].id) {
            Update-FrontmatterValue -Path $file.FullName -Field "mem0_memory_id" -Value $response.results[0].id
        }
    } catch {
        Update-FrontmatterValue -Path $file.FullName -Field "mem0_sync_status" -Value "sync_failed"
    }
}
```

This script is intentionally narrow: promoted failures only, no candidate sync.

- [ ] **Step 3: Add explicit sync responsibility to reviewer and router skill**

Update `.opencode/agents/code-quality-reviewer.md` and `.trae/skills/ue-project-router/SKILL.md` so they say:

```text
Promoted failure memories may be synced by `.trae/scripts/mem0-sync.ps1`, but only after promotion to `Docs/Memory/failures/`.
Never sync candidates.
```

- [ ] **Step 4: Parse-check the sync path**

Run:

```powershell
powershell -NoProfile -Command "[void][System.Management.Automation.Language.Parser]::ParseFile('g:\UEGameDevelopment\.trae\scripts\mem0-sync.ps1',[ref]$null,[ref]$null); [void][System.Management.Automation.Language.Parser]::ParseFile('g:\UEGameDevelopment\.trae\scripts\memory-retrieve.ps1',[ref]$null,[ref]$null); 'PARSE_OK'"
```

Expected: `PARSE_OK`

### Task 5: Verify The Full Retrieval Loop

**Files:**
- Test: `.trae/scripts/test-memory-retrieval.ps1`
- Test: `.trae/scripts/mem0-healthcheck.ps1`
- Test: `.trae/scripts/memory-retrieve.ps1`
- Test: `.trae/scripts/mem0-sync.ps1`

- [ ] **Step 1: Verify healthcheck in disabled mode**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "g:\UEGameDevelopment\.trae\scripts\mem0-healthcheck.ps1"
```

Expected JSON contains:

```json
{
  "status": "unavailable",
  "reason": "disabled"
}
```

- [ ] **Step 2: Verify local router retrieval**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'g:\UEGameDevelopment\.trae\scripts\memory-retrieve.ps1' -Phase plan -ProjectType ue5 -Scope router -Module router -Tags @('save','implicit-requirement') -Limit 2 -UseMem0 \$false -TaskName demo"
```

Expected output starts with:

```text
Relevant Failure Memories
```

and contains:

```text
先确认保存系统是否存在
```

- [ ] **Step 3: Verify local implement retrieval**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'g:\UEGameDevelopment\.trae\scripts\memory-retrieve.ps1' -Phase implement -ProjectType ue5 -Scope implement -Module router -Tags @('save') -Limit 1 -UseMem0 \$false -TaskName demo"
```

Expected output starts with:

```text
Pre-Edit Failure Reminder
```

- [ ] **Step 4: Run the scripted retrieval test suite**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "g:\UEGameDevelopment\.trae\scripts\test-memory-retrieval.ps1"
```

Expected:

```text
MEMORY_RETRIEVAL_TESTS_PASS
```

- [ ] **Step 5: Run diagnostics and inspect final diff**

Run diagnostics on all new and modified files, then inspect the diff:

```powershell
git diff --stat
```

Expected: changes limited to `Docs/Memory/`, `.trae/scripts/`, `.opencode/agents/`, `.trae/skills/`, `Docs/AI/`, and `CLAUDE.md`

## Self-Review

**Spec coverage**
- Local retrieval script: covered by Task 3
- Mem0 healthcheck/config/sync: covered by Tasks 1 and 4
- Router + Implement integration: covered by Tasks 3 and 4
- Token/fail-soft behavior: enforced in Task 3 output shape and Task 4 fallback logic
- Formal validation path: covered by Task 5

**Placeholder scan**
- No `TODO`, `TBD`, or “implement later” steps remain
- Each task has exact files and commands

**Type consistency**
- Script names are consistent: `memory-retrieve.ps1`, `mem0-healthcheck.ps1`, `mem0-sync.ps1`
- Summary names are consistent: `Relevant Failure Memories`, `Pre-Edit Failure Reminder`
- Config file name is consistent: `mem0.config.json`

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-31-basic-memory-retrieval-and-mem0-implementation-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using `executing-plans`, batch execution with checkpoints

Which approach?
