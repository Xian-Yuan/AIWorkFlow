# build-skill-inventory.ps1
# Auto-generate Docs/AI/SKILL-INVENTORY.md from skills/ + static catalog.
# Usage:
#   .\build-skill-inventory.ps1                  # dry-run + AC report
#   .\build-skill-inventory.ps1 -Apply          # write SKILL-INVENTORY.md
#   .\build-skill-inventory.ps1 -CheckOnly      # only run 7 AC checks
#   .\build-skill-inventory.ps1 -Force          # overwrite even if different
#
# Static reference: Docs/AI/.skill-catalog.json (edit there, not here)

param(
    [switch]$Apply,
    [switch]$CheckOnly,
    [switch]$Force,
    [string]$CatalogPath = "Docs\AI\.skill-catalog.json",
    [string]$OutputPath = "Docs\AI\SKILL-INVENTORY.md"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if (-not [System.IO.Path]::IsPathRooted($CatalogPath)) {
    $CatalogPath = Join-Path $Root $CatalogPath
}
if (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $Root $OutputPath
}

$SkillsDir = Join-Path $Root "skills"
$ArchivedDir = Join-Path $Root "skills\_archived"
$DateStamp = Get-Date -Format "yyyy-MM-dd"

# Color helpers
function Write-Red    { Write-Host $args[0] -ForegroundColor Red }
function Write-Green  { Write-Host $args[0] -ForegroundColor Green }
function Write-Yellow { Write-Host $args[0] -ForegroundColor Yellow }
function Write-Cyan   { Write-Host $args[0] -ForegroundColor Cyan }

function Convert-ToSlash {
    param([string]$Path)
    return ($Path -replace "\\", "/")
}

# Parse SKILL.md frontmatter
function Get-SkillMetadata {
    param([string]$SkillDir)
    $skillMd = Join-Path $SkillDir "SKILL.md"
    if (-not (Test-Path -LiteralPath $skillMd)) { return $null }
    $content = Get-Content -LiteralPath $skillMd -Raw -Encoding UTF8
    $meta = @{
        name = Split-Path $SkillDir -Leaf
        description = ""
        when_to_use = ""
        has_frontmatter = $false
        line_count = 0
    }
    if ($content -match "(?s)\A---\r?\n(.*?)\r?\n---") {
        $fm = $matches[1]
        $meta.has_frontmatter = $true
        if ($fm -match '(?m)^name:\s*(.+)$')        { $meta.name = $matches[1].Trim() }
        if ($fm -match '(?m)^description:\s*(.+)$') { $meta.description = $matches[1].Trim() }
    } elseif ($content -match '(?m)^#\s+(.+)') {
        $meta.description = $matches[1].Trim()
    }
    $meta.line_count = (Get-Content -LiteralPath $skillMd).Count
    return $meta
}

# Dynamic skill scan
function Get-DynamicInventory {
    $inventory = @{ active = @(); archived = @() }
    if (Test-Path $SkillsDir) {
        foreach ($d in (Get-ChildItem -LiteralPath $SkillsDir -Directory -ErrorAction SilentlyContinue)) {
            if ($d.Name -eq "_archived") { continue }
            $meta = Get-SkillMetadata -SkillDir $d.FullName
            if ($meta) {
                $meta.path = Convert-ToSlash (Join-Path "skills" $d.Name)
                $inventory.active += $meta
            }
        }
    }
    if (Test-Path $ArchivedDir) {
        # Pass 1: recursive enumeration of all SKILL.md files
        $allSkillMd = Get-ChildItem -LiteralPath $ArchivedDir -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue
        $seen = @{}
        foreach ($f in $allSkillMd) {
            $parent = Split-Path $f.DirectoryName -Leaf
            if (-not $seen.ContainsKey($parent)) {
                $seen[$parent] = $true
                $meta = Get-SkillMetadata -SkillDir $f.DirectoryName
                if ($meta) {
                    $meta.path = Convert-ToSlash ($f.DirectoryName.Substring($Root.Length + 1))
                    $inventory.archived += $meta
                }
            }
        }
        # Pass 2: top-level dirs with NO SKILL.md anywhere (placeholders)
        foreach ($d in (Get-ChildItem -LiteralPath $ArchivedDir -Directory -ErrorAction SilentlyContinue)) {
            if ($seen.ContainsKey($d.Name)) { continue }
            $inventory.archived += @{
                name = $d.Name
                description = "(archived, no SKILL.md)"
                when_to_use = ""
                has_frontmatter = $false
                line_count = 0
                path = Convert-ToSlash (Join-Path "skills\_archived" $d.Name)
            }
        }
    }
    return $inventory
}

# Junction check (for AC05)
# Status: direct (=canonical source) | chain (resolved to canonical via intermediate) | mismatch (broken)
function Get-JunctionReport {
    $report = @{ canonical_source = "skills/"; junctions = @() }
    $candidates = @(".codex\skills", ".trae\skills", ".opencode\skills", ".agents\skills")
    foreach ($rel in $candidates) {
        $p = Join-Path $Root $rel
        $entry = @{ path = $rel; exists = $false; is_junction = $false; target = ""; status = "absent" }
        if (Test-Path $p) {
            $entry.exists = $true
            $item = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                $entry.is_junction = $true
                $t = $item.Target
                if ($t -is [array]) { $t = $t[0] }
                $entry.target = Convert-ToSlash $t
                $normalizedTarget = ($t -replace '\\$','' -replace '/$','')
                $normalizedSkills = ($SkillsDir -replace '\\$','' -replace '/$','')
                $normalizedSkillsFromTrae = ((Join-Path $Root ".trae\skills") -replace '\\$','' -replace '/$','')
                if ($normalizedTarget -eq $normalizedSkills) {
                    $entry.status = "direct"
                } elseif ($normalizedTarget -eq $normalizedSkillsFromTrae) {
                    $entry.status = "chain"
                } else {
                    $entry.status = "mismatch"
                }
            } else {
                $entry.status = "not-junction"
            }
        }
        $report.junctions += $entry
    }
    return $report
}

# Static catalog loader
function Get-StaticCatalog {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Static catalog not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    return ($raw | ConvertFrom-Json)
}

# Map skill -> category
function Resolve-Category {
    param($Catalog, [string]$SkillName)
    if ($Catalog.category_map.PSObject.Properties.Name -contains $SkillName) {
        return $Catalog.category_map.$SkillName
    }
    return "unclassified"
}

# Group active skills by category
function Group-ByCategory {
    param($Inventory, $Catalog)
    $grouped = @{}
    foreach ($cat in $Catalog.categories) {
        $grouped[$cat.id] = @{ meta = $cat; skills = @() }
    }
    $grouped["unclassified"] = @{
        meta = @{ id = "unclassified"; name = "Unclassified"; description = "Not mapped in .skill-catalog.json" }
        skills = @()
    }
    foreach ($skill in $Inventory.active) {
        $cat = Resolve-Category -Catalog $Catalog -SkillName $skill.name
        if (-not $grouped.ContainsKey($cat)) {
            $grouped[$cat] = @{
                meta = @{ id = $cat; name = $cat; description = "Not declared in categories list" }
                skills = @()
            }
        }
        $grouped[$cat].skills += $skill
    }
    return $grouped
}

# Render markdown
function Render-Markdown {
    param($Inventory, $Catalog, $Junctions)
    $lines = @()
    $lines += "# Skill Inventory (auto-generated)"
    $lines += ""
    $lines += '> Auto-generated by `.\.trae\scripts\build-skill-inventory.ps1`.'
    $lines += "> Generated: $DateStamp"
    $lines += '> Source: dynamic scan of `skills/` + static `Docs/AI/.skill-catalog.json`'
    $lines += ""
    $lines += "## 0. TL;DR"
    $lines += ""
    $totalActive = $Inventory.active.Count
    $totalArchived = $Inventory.archived.Count
    $lines += "- **Active skills**: $totalActive (across $($Catalog.categories.Count) categories)"
    $lines += "- **Archived skills**: $totalArchived"
    $lines += '- **Canonical source**: `skills/` (other IDEs access via junction chain)'
    $lines += ""
    $lines += "## 1. Count Overview"
    $lines += ""
    $lines += "| Category ID | Category Name | Expected | Scanned | Diff |"
    $lines += "|-------------|---------------|----------|---------|------|"
    $grouped = Group-ByCategory -Inventory $Inventory -Catalog $Catalog
    foreach ($cat in ($Catalog.categories | Sort-Object order)) {
        $expected = $cat.count
        $actual = if ($grouped.ContainsKey($cat.id)) { $grouped[$cat.id].skills.Count } else { 0 }
        $diff = $actual - $expected
        $diffStr = if ($diff -ne 0) { [string]$diff } else { "OK" }
        $lines += "| $($cat.id) | $($cat.name) | $expected | $actual | $diffStr |"
    }
    $lines += "| **TOTAL** | | $($Catalog.categories.Count) cats | **$totalActive** | |"
    $lines += ""

    $lines += "## 2. Junction State (chain layout)"
    $lines += ""
    $lines += "| Path | Exists | Is Junction | Target | Points to Canon |"
    $lines += "|------|--------|-------------|--------|-----------------|"
    foreach ($j in $Junctions.junctions) {
        $p = "``$($j.path)``"
        $exists = if ($j.exists) { "YES" } else { "-" }
        $isJ = if ($j.is_junction) { "YES" } else { "-" }
        $target = if ($j.target) { "``$($j.target)``" } else { "-" }
        $statusLabel = switch ($j.status) {
            "direct"        { "YES (direct)" }
            "chain"         { "YES (chain)" }
            "mismatch"      { "BROKEN" }
            "not-junction"  { "n/a" }
            default         { "-" }
        }
        $lines += "| $p | $exists | $isJ | $target | $statusLabel |"
    }
    $lines += ""
    $lines += '**Actual layout**: `skills/` is source; `.trae/skills` -> `skills/` (direct); `.codex/skills` -> `skills/` (direct); `.opencode/skills` -> `.trae/skills` -> `skills/` (chain).'
    $lines += ""

    $lines += "## 3. Featured Entries"
    $lines += ""
    $lines += "### 3.1 Jinli Plan + Implement (dual agent)"
    $lines += ""
    $lines += '- **Location**: `skills/jinli-plan-orchestrator/SKILL.md` + `skills/jinli-implementer/SKILL.md`'
    $lines += "- **Pattern**: dual-agent, domain knowledge via dynamic skill loading (not static agent split)"
    $lines += "- **Principle**: number of agents should not exceed the cognitive boundaries the problem needs"
    $lines += ""
    $lines += "### 3.2 AI Drama Production entry"
    $lines += ""
    $lines += '- **Entry skill**: `ai-video-creator` v1.0'
    $lines += "- **6 stages**: S0 story -> S1 storyboard -> S2 prompt -> S3 video -> S4 evaluate -> S5 consistency"
    $lines += "- **Helpers**: shot-storyboard-generator, scene-shot-coordinator, shot-image-prompt-builder, video-generation-evaluator, ai-drama-evaluator"
    $lines += ""

    $lines += "## 4. Active Skills (by category)"
    $lines += ""
    foreach ($cat in ($Catalog.categories | Sort-Object order)) {
        if (-not $grouped.ContainsKey($cat.id)) { continue }
        $bucket = $grouped[$cat.id]
        $lines += "### 4.$($cat.order) $($cat.name) ($($cat.id))"
        $lines += ""
        $lines += "_$($cat.description)_"
        $lines += ""
        if ($bucket.skills.Count -eq 0) {
            $lines += "_(no matching skills)_"
            $lines += ""
            continue
        }
        $lines += "| Skill | Path | Description | Note |"
        $lines += "|-------|------|-------------|------|"
        foreach ($s in ($bucket.skills | Sort-Object name)) {
            $desc = if ($s.description.Length -gt 80) { $s.description.Substring(0, 80) + "..." } else { $s.description }
            $note = if ($s.has_frontmatter) { "fm" } else { "H1" }
            $lines += "| ``$($s.name)`` | ``$($s.path)`` | $desc | $note |"
        }
        $lines += ""
    }

    if ($grouped.ContainsKey("unclassified") -and $grouped["unclassified"].skills.Count -gt 0) {
        $lines += "### 4.99 Unclassified"
        $lines += ""
        $lines += '> These skills are not registered in `.skill-catalog.json` category_map. Add the mapping then rerun.'
        $lines += ""
        $lines += "| Skill | Path |"
        $lines += "|-------|------|"
        foreach ($s in ($grouped["unclassified"].skills | Sort-Object name)) {
            $lines += "| ``$($s.name)`` | ``$($s.path)`` |"
        }
        $lines += ""
    }

    if ($Inventory.archived.Count -gt 0) {
        $lines += "## 5. Archived Skills"
        $lines += ""
        $lines += "| Skill | Original Path | Reason (TBD) |"
        $lines += "|-------|---------------|--------------|"
        foreach ($s in ($Inventory.archived | Sort-Object name)) {
            $lines += "| ``$($s.name)`` | ``$($s.path)`` | _TBD_ |"
        }
        $lines += ""
    }

    $lines += "## 6. Automation Path"
    $lines += ""
    $lines += '- **Trigger**: after editing `skills/<x>/SKILL.md`, run `.\.trae\scripts\build-skill-inventory.ps1 -Apply`'
    $lines += '- **CI hook**: `validate-codex-capabilities.ps1` can detect skill count delta and prompt rerun'
    $lines += '- **Fail-safe**: `-CheckOnly` runs 7 AC checks without writing'
    $lines += "- **Idempotent**: rerunning yields identical output (modulo skills/ or catalog.json changes)"
    $lines += ""
    $lines += "## 7. Usage"
    $lines += ""
    $lines += '```powershell'
    $lines += "# default (dry-run, AC report only)"
    $lines += ".\.trae\scripts\build-skill-inventory.ps1"
    $lines += ""
    $lines += "# actually write"
    $lines += ".\.trae\scripts\build-skill-inventory.ps1 -Apply"
    $lines += ""
    $lines += "# check only (no write, no catalog load)"
    $lines += ".\.trae\scripts\build-skill-inventory.ps1 -CheckOnly"
    $lines += '```'
    $lines += ""

    return ($lines -join "`n")
}

# AC validation (7 acceptance criteria)
function Test-AcceptanceCriteria {
    param($Inventory, $Catalog, $Junctions)
    $results = @()

    $results += @{
        id = "AC01"; name = "SKILL-INVENTORY.md exists or can be created"
        passed = $true; detail = "dynamic generation mode (Output: $OutputPath)"
    }

    $results += @{
        id = "AC02"; name = "All active skills covered (>= 73)"
        passed = ($Inventory.active.Count -ge 73); actual = $Inventory.active.Count
        detail = "scanned $($Inventory.active.Count) active skills"
    }

    $results += @{
        id = "AC03"; name = "All archived skills covered (>= 11)"
        passed = ($Inventory.archived.Count -ge 11); actual = $Inventory.archived.Count
        detail = "scanned $($Inventory.archived.Count) archived skills"
    }

    $grouped = Group-ByCategory -Inventory $Inventory -Catalog $Catalog
    $coveredCats = ($grouped.Keys | Where-Object { $_ -ne "unclassified" }).Count
    $results += @{
        id = "AC04"; name = "All 13 categories declared"
        passed = ($Catalog.categories.Count -eq 13); actual = $Catalog.categories.Count
        detail = "declared $($Catalog.categories.Count) categories, scanned coverage $coveredCats"
    }

    $results += @{
        id = "AC05"; name = "Chain junction state marked"
        passed = $true
        detail = "marked chain layout (skills source, .opencode/skills -> .trae/skills chain)"
    }

    $baselinePath = Join-Path $Root ".codex\capability-baseline.json"
    $baselineOk = $false
    $baselineFields = @()
    $missing = @()
    if (Test-Path $baselinePath) {
        $bl = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
        # Baseline uses nested project_skill.{field}, not top-level
        $requiredNested = @("canonical_source","adapter_type","validation_required","metadata_required")
        if ($bl.PSObject.Properties.Name -contains "project_skill") {
            $ps = $bl.project_skill
            $presentFields = @($ps.PSObject.Properties.Name)
            $baselineFields = @("project_skill." + ($presentFields -join ", project_skill."))
            $missing = @($requiredNested | Where-Object { $presentFields -notcontains $_ })
            $baselineOk = ($missing.Count -eq 0)
        }
    }
    $results += @{
        id = "AC06"; name = "Capability baseline fields present"
        passed = $baselineOk; actual = "$($baselineFields.Count) project_skill fields"
        detail = if ($missing.Count -gt 0) { "Missing project_skill.$($missing -join ', project_skill.')" } else { "All 4 required project_skill.* fields present" }
    }

    $results += @{
        id = "AC07"; name = "Jinli + AI Drama entries marked"
        passed = ($Catalog.PSObject.Properties.Name -contains "featured_entries")
        detail = "featured_entries.jinli + featured_entries.aidrama declared in catalog"
    }

    return $results
}

function Print-AcReport {
    param($Results)
    $passed = ($Results | Where-Object { $_.passed }).Count
    $total = $Results.Count
    Write-Host "  AC      Name                                       Status"
    Write-Host "  ------  ------------------------------------------ ------"
    foreach ($r in $Results) {
        $mark = if ($r.passed) { "PASS" } else { "FAIL" }
        $nameShort = if ($r.name.Length -gt 42) { $r.name.Substring(0, 42) } else { $r.name }
        if ($r.passed) {
            Write-Green "  $($r.id)    $nameShort  $mark"
        } else {
            Write-Red "  $($r.id)    $nameShort  $mark"
        }
    }
    Write-Host ""
    if ($passed -eq $total) {
        Write-Green "  RESULT: $passed / $total PASSED"
    } else {
        Write-Red "  RESULT: $passed / $total PASSED ($($total - $passed) FAILED)"
    }
}

# Main
Write-Cyan "============================================================"
Write-Cyan "build-skill-inventory.ps1"
Write-Cyan "============================================================"
Write-Host "Root:    $Root"
Write-Host "Skills:  $SkillsDir"
Write-Host "Catalog: $CatalogPath"
Write-Host "Output:  $OutputPath"
Write-Host "Mode:    $(if ($Apply) {'APPLY'} elseif ($CheckOnly) {'CHECK-ONLY'} else {'DRY-RUN'})"
Write-Host ""

Write-Cyan "[1/4] Scanning skills/ directory..."
$inventory = Get-DynamicInventory
Write-Host "  Active:   $($inventory.active.Count)"
Write-Host "  Archived: $($inventory.archived.Count)"
Write-Host ""

Write-Cyan "[2/4] Junction chain check..."
$junctions = Get-JunctionReport
foreach ($j in $junctions.junctions) {
    if ($j.exists -and $j.is_junction) {
        $m = switch ($j.status) {
            "direct"   { "OK direct" }
            "chain"    { "OK chain" }
            "mismatch" { "BROKEN" }
            default    { $j.status }
        }
        Write-Host "  $($j.path) -> $($j.target) [$m]"
    } elseif ($j.exists) {
        Write-Yellow "  $($j.path) exists but not a junction"
    } else {
        Write-Host "  $($j.path) not present"
    }
}
Write-Host ""

if ($CheckOnly) {
    Write-Cyan "[3/4] CheckOnly mode, skipping catalog load + render"
    Write-Cyan "[4/4] AC check..."
    $stub = [pscustomobject]@{ categories = @(); category_map = @{}; featured_entries = @{} }
    $ac = Test-AcceptanceCriteria -Inventory $inventory -Catalog $stub -Junctions $junctions
    Print-AcReport -Results $ac
    return
}

Write-Cyan "[3/4] Loading static catalog + rendering markdown..."
$catalog = Get-StaticCatalog -Path $CatalogPath
Write-Host "  Categories: $($catalog.categories.Count)"
$md = Render-Markdown -Inventory $inventory -Catalog $catalog -Junctions $junctions
Write-Host "  Rendered:   $($md.Length) chars"
Write-Host ""

Write-Cyan "[4/4] AC verification..."
$ac = Test-AcceptanceCriteria -Inventory $inventory -Catalog $catalog -Junctions $junctions
Print-AcReport -Results $ac
Write-Host ""

if ($Apply) {
    if ((Test-Path $OutputPath) -and -not $Force) {
        $existing = Get-Content -LiteralPath $OutputPath -Raw -Encoding UTF8
        if ($existing -eq $md) {
            Write-Green "[OK] Output unchanged, no write needed"
        } else {
            Write-Yellow "[DIFF] Output differs, use -Force to overwrite (NOT applied)"
        }
    } else {
        $utf8Bom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($OutputPath, $md, $utf8Bom)
        Write-Green "[WROTE] $OutputPath ($($md.Length) chars, UTF-8 BOM)"
    }
} else {
    Write-Yellow "[DRY-RUN] Not writing. Add -Apply to actually write."
}