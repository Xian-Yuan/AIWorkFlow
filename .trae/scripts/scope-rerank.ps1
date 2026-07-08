# scope-rerank.ps1 -- Relevance Ranking and Re-Ranking for Scope Recall (Jinli)
#
# Ninth layer of the Scope Recall pattern: relevance scoring and result ranking.
# Implements the hybrid retrieval concept from Scope Recall (BV19EE16aEn7):
#   - Lexical weight 0.45: keyword match quality (exact > prefix > partial)
#   - Semantic weight 0.55: access frequency + recency + scope priority
#   - Multi-factor relevance score: lexical + semantic + decay + context boost
#   - Artifact Anchor extraction: GitHub issues, PRs, commits, file paths from values
#   - Re-rank: take unranked or loosely ranked results and apply relevance scoring
#
# Design principles:
#   1. Non-destructive: reads from scope-store and scope-index, never modifies them
#   2. Composable: can be called after any recall/search/prefetch operation
#   3. Transparent: every score component is visible in the ranking output
#   4. PS5.1 compatible: no -Raw, no PS7 syntax, ASCII identifiers
#
# Usage:
#   .\scope-rerank.ps1 -Init
#   .\scope-rerank.ps1 -Rank -Query "rts gas" -Scope project
#   .\scope-rerank.ps1 -Rank -Query "rts gas" -Scope project -Limit 5
#   .\scope-rerank.ps1 -Rerank -EntriesJson '...' -Query "gas"
#   .\scope-rerank.ps1 -ExtractAnchors -Scope project -Key rts-gas
#   .\scope-rerank.ps1 -ExtractAnchors -Text "See GitHub issue #123 and PR #456"
#   .\scope-rerank.ps1 -RankReport -Scope project
#   .\scope-rerank.ps1 -SelfTest
#
# PowerShell 5.1 compatible. No PS7 syntax. No -Raw.
param(
    [switch]$Init,
    [switch]$Rank,
    [switch]$Rerank,
    [switch]$ExtractAnchors,
    [switch]$RankReport,
    [switch]$SelfTest,
    [switch]$Apply,

    [ValidateSet("user", "project", "ops", "memory", "session", "general", "")]
    [string]$Scope = "",

    [string]$Key = "",
    [string]$Query = "",
    [string]$Text = "",
    [string]$EntriesJson = "",
    [int]$Limit = 10,
    [string]$DbPath = "",
    [string]$IndexPath = "",
    [string]$DecayDbPath = ""
)

$ErrorActionPreference = "Stop"

# --- Paths ---
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scopeStoreScript = Join-Path $PSScriptRoot "scope-store.ps1"
$scopeIndexScript = Join-Path $PSScriptRoot "scope-index.ps1"

if (-not $DbPath) {
    $DbPath = Join-Path $repoRoot "Docs\Memory\scope-store.json"
}
if (-not $IndexPath) {
    $IndexPath = Join-Path $repoRoot "Docs\Memory\scope-index.json"
}
if (-not $DecayDbPath) {
    $decayPath = $DbPath -replace 'scope-store\.json$', 'scope-store-decay.json'
    $DecayDbPath = $decayPath
}

# --- Weight Configuration (from Scope Recall hybrid retrieval) ---
$weightLexical = 0.45
$weightSemantic = 0.55

# Scope priority: memory > user > project > ops > session > general
$scopePriority = @{
    memory  = 1.0
    user    = 0.85
    project = 0.75
    ops     = 0.60
    session = 0.35
    general = 0.20
}

$persistentScopes = @("user", "project", "ops", "memory")

# --- JSON I/O (PS5.1 compatible) ---

function Read-StoreData {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ entries = @(); meta = @{ created_at = ""; version = 1 } }
    }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    $parsed = $raw | ConvertFrom-Json
    $entriesArray = @()
    if ($parsed.entries -ne $null) {
        if ($parsed.entries -is [array]) {
            $entriesArray = $parsed.entries
        } else {
            $entriesArray = @($parsed.entries)
        }
    }
    return @{
        entries = $entriesArray
        meta    = @{
            created_at = $parsed.meta.created_at
            version    = $parsed.meta.version
        }
    }
}

# --- Keyword Extraction (matches scope-index logic) ---

function Get-RerankKeywords {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $cleaned = $Text.ToLowerInvariant() -replace '[^\w\s\-\.]', ' '
    $parts = $cleaned -split '[\s\-_\.]+'
    $result = @()
    foreach ($p in $parts) {
        $trimmed = $p.Trim()
        if ($trimmed.Length -ge 2) {
            $result += $trimmed
        }
    }
    return $result | Select-Object -Unique
}

# --- Artifact Anchor Extraction ---

function Extract-AnchorPatterns {
    param([string]$TextStr)

    if ([string]::IsNullOrWhiteSpace($TextStr)) { return @() }

    $anchors = @()

    # GitHub issue/PR references: #123, #4567
    # Note: # is not a word char, so \b# won't match after whitespace. Use (?:^|\s|#) instead.
    $issuePattern = '(?i)(?:^|\s)#(\d{1,10})\b'
    $issueMatches = [regex]::Matches($TextStr, $issuePattern)
    foreach ($m in $issueMatches) {
        $anchors += @{ type = "issue"; ref = $m.Groups[1].Value; raw = $m.Value }
    }

    # GitHub PR references: PR #123, pull request #456
    $prPattern = '(?i)(?:PR|pull\s*request)\s*#?(\d{1,10})'
    $prMatches = [regex]::Matches($TextStr, $prPattern)
    foreach ($m in $prMatches) {
        $anchors += @{ type = "pr"; ref = $m.Groups[1].Value; raw = $m.Value }
    }

    # Commit hashes: abc1234 (7-40 hex chars, must contain at least one letter)
    $commitPattern = '\b([0-9a-f]{7,40})\b'
    $commitMatches = [regex]::Matches($TextStr, $commitPattern)
    foreach ($m in $commitMatches) {
        $val = $m.Groups[1].Value
        if ($val -match '[a-f]') {
            $anchors += @{ type = "commit"; ref = $val; raw = $m.Value }
        }
    }

    # File paths: C:\path\to\file or /path/to/file or ./relative/path.ext
    $pathPattern = '(?:(?:[A-Za-z]:\\|/\w+/|\./)[^\s<>"|*?]+)'
    $pathMatches = [regex]::Matches($TextStr, $pathPattern)
    foreach ($m in $pathMatches) {
        $val = $m.Value.TrimEnd('.,;:')
        if ($val.Length -ge 5) {
            $anchors += @{ type = "file"; ref = $val; raw = $m.Value }
        }
    }

    # URLs: https://...
    $urlPattern = 'https?://[^\s<>"|*?]+'
    $urlMatches = [regex]::Matches($TextStr, $urlPattern)
    foreach ($m in $urlMatches) {
        $val = $m.Value.TrimEnd('.,;:')
        $anchors += @{ type = "url"; ref = $val; raw = $m.Value }
    }

    # BV video IDs: BV followed by alphanumerics
    $bvPattern = '\b(BV[0-9A-Za-z]{6,12})\b'
    $bvMatches = [regex]::Matches($TextStr, $bvPattern)
    foreach ($m in $bvMatches) {
        $anchors += @{ type = "video"; ref = $m.Groups[1].Value; raw = $m.Value }
    }

    # PS5.1: caller wraps with @() to handle single-element unwrapping
    return @($anchors)
}

# --- Lexical Scoring ---

function Get-LexicalScore {
    param(
        [string]$EntryKey,
        [string]$EntryValue,
        [array]$QueryKeywords
    )

    if ($QueryKeywords.Count -eq 0) { return 0.5 }

    $keyLower = $EntryKey.ToLowerInvariant()
    $valueLower = ""
    if (-not [string]::IsNullOrEmpty($EntryValue)) {
        $valueLower = $EntryValue.ToLowerInvariant()
    }

    $exactMatches = 0
    $prefixMatches = 0
    $partialMatches = 0
    $totalKeywords = $QueryKeywords.Count

    foreach ($qkw in $QueryKeywords) {
        # Exact keyword in key (word boundary via delimiters)
        if ($keyLower -match "(^|[-_])$qkw([-_]|$)") {
            $exactMatches++
            continue
        }
        # Exact keyword in value (word boundary)
        if ($valueLower -match "\b$qkw\b") {
            $exactMatches++
            continue
        }
        # Prefix match in key
        if ($keyLower.StartsWith($qkw) -or $keyLower -match "-$qkw") {
            $prefixMatches++
            continue
        }
        # Partial match anywhere
        if ($keyLower.Contains($qkw) -or $valueLower.Contains($qkw)) {
            $partialMatches++
            continue
        }
    }

    # Weight: exact=1.0, prefix=0.6, partial=0.3
    $score = ($exactMatches * 1.0 + $prefixMatches * 0.6 + $partialMatches * 0.3) / $totalKeywords
    return [math]::Round($score, 4)
}

# --- Semantic Scoring (access + recency + scope priority) ---

function Get-SemanticScore {
    param(
        [string]$EntryScope,
        [int]$AccessCount,
        [string]$UpdatedAt,
        [string]$CreatedAt
    )

    # Scope priority component (0.0 - 1.0)
    $scopeScore = 0.20
    if ($scopePriority.ContainsKey($EntryScope)) {
        $scopeScore = $scopePriority[$EntryScope]
    }

    # Access frequency component (logarithmic scaling, cap at 1.0)
    $accessScore = 0.0
    if ($AccessCount -gt 0) {
        $accessScore = [math]::Log10($AccessCount + 1) / [math]::Log10(20)
        if ($accessScore -gt 1.0) { $accessScore = 1.0 }
    }

    # Recency component (exponential decay, half-life of 15 days)
    $recencyScore = 0.0
    $refDate = Get-Date
    $entryDate = [datetime]::MinValue
    if (-not [string]::IsNullOrEmpty($UpdatedAt)) {
        try { $entryDate = [datetime]::Parse($UpdatedAt) } catch {
            try { $entryDate = [datetime]::Parse($CreatedAt) } catch {}
        }
    } elseif (-not [string]::IsNullOrEmpty($CreatedAt)) {
        try { $entryDate = [datetime]::Parse($CreatedAt) } catch {}
    }
    if ($entryDate -gt [datetime]::MinValue) {
        $daysOld = ($refDate - $entryDate).TotalDays
        if ($daysOld -lt 0) { $daysOld = 0 }
        $recencyScore = [math]::Pow(0.5, ($daysOld / 15.0))
    }

    # Weighted combination: scope 0.30 + access 0.35 + recency 0.35
    $score = $scopeScore * 0.30 + $accessScore * 0.35 + $recencyScore * 0.35
    return [math]::Round($score, 4)
}

# --- Decay Score Integration ---

function Get-DecayAdjustment {
    param(
        [string]$EntryScope,
        [int]$AccessCount,
        [string]$UpdatedAt,
        [string]$DecayPath
    )

    if (-not (Test-Path -LiteralPath $DecayPath)) { return 0.0 }

    try {
        $raw = [System.IO.File]::ReadAllText($DecayPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        $protectedEntries = @()
        if ($parsed.protected -ne $null) {
            if ($parsed.protected -is [array]) {
                $protectedEntries = $parsed.protected
            } else {
                $protectedEntries = @($parsed.protected)
            }
        }
        # Scope-level boost: if any entry in same scope is protected, boost
        foreach ($p in $protectedEntries) {
            $pScope = ""
            if ($p.scope -ne $null) { $pScope = [string]$p.scope }
            if ($pScope -eq $EntryScope) { return 0.1 }
        }
    } catch {}

    return 0.0
}

# --- Core: Rank Entries ---

function Invoke-RankEntries {
    param(
        [array]$Entries,
        [string]$QueryStr,
        [string]$ScopeName,
        [string]$DecayPath
    )

    $queryKeywords = Get-RerankKeywords -Text $QueryStr

    $ranked = @()
    foreach ($entry in $Entries) {
        $entryScope = [string]$entry.scope
        $entryKey = [string]$entry.key
        $entryValue = ""
        if ($entry.value -ne $null) { $entryValue = [string]$entry.value }
        $entryAccess = 0
        if ($entry.access_count -ne $null) { $entryAccess = [int]$entry.access_count }
        $entryUpdated = ""
        if ($entry.updated_at -ne $null) { $entryUpdated = [string]$entry.updated_at }
        $entryCreated = ""
        if ($entry.created_at -ne $null) { $entryCreated = [string]$entry.created_at }
        $entryId = ""
        if ($entry.id -ne $null) { $entryId = [string]$entry.id }

        $lexScore = Get-LexicalScore -EntryKey $entryKey -EntryValue $entryValue -QueryKeywords $queryKeywords
        $semScore = Get-SemanticScore -EntryScope $entryScope -AccessCount $entryAccess -UpdatedAt $entryUpdated -CreatedAt $entryCreated
        $decayAdj = Get-DecayAdjustment -EntryScope $entryScope -AccessCount $entryAccess -UpdatedAt $entryUpdated -DecayPath $DecayPath

        $hybridScore = ($lexScore * $weightLexical) + ($semScore * $weightSemantic) + $decayAdj
        $hybridScore = [math]::Round($hybridScore, 4)

    $anchors = @(Extract-AnchorPatterns -TextStr $entryValue)

        $ranked += @{
            id             = $entryId
            scope          = $entryScope
            key            = $entryKey
            value          = $entryValue
            access_count   = $entryAccess
            lexical_score  = $lexScore
            semantic_score = $semScore
            decay_boost    = $decayAdj
            hybrid_score   = $hybridScore
            anchors        = $anchors
            updated_at     = $entryUpdated
        }
    }

    # PS5.1: -Property on hashtables sorts by string representation.
    # Use script block to access numeric value for correct descending sort.
    $sorted = @($ranked | Sort-Object { [double]$_.hybrid_score } -Descending)
    return ,$sorted
}

# --- Get Visible Scopes ---

function Get-RerankVisibleScopes {
    param([string]$ScopeName)
    if ([string]::IsNullOrEmpty($ScopeName)) {
        return @("user", "project", "ops", "memory", "session", "general")
    }
    if ($persistentScopes -contains $ScopeName) {
        return $persistentScopes
    }
    return $persistentScopes + $ScopeName
}

# --- Init ---

function Initialize-Rerank {
    Write-Host "[INIT] Re-ranker initialized. No separate state file needed."
    Write-Host "  Store path:  $DbPath"
    Write-Host "  Index path:  $IndexPath"
    Write-Host "  Decay path:  $DecayDbPath"
    Write-Host "  Lexical weight:  $weightLexical"
    Write-Host "  Semantic weight: $weightSemantic"
    return $true
}

# --- Rank: search store entries and rank by relevance ---

function Invoke-Rank {
    param(
        [string]$QueryStr,
        [string]$ScopeName,
        [int]$LimitVal
    )

    $storeData = Read-StoreData -Path $DbPath
    if ($storeData.entries.Count -eq 0) {
        Write-Host "[RANK] No entries in store."
        return @()
    }

    $visibleScopes = Get-RerankVisibleScopes -ScopeName $ScopeName
    $visibleEntries = @()
    foreach ($e in $storeData.entries) {
        if ($visibleScopes -contains [string]$e.scope) {
            $visibleEntries += $e
        }
    }

    if ($visibleEntries.Count -eq 0) {
        Write-Host "[RANK] No visible entries for scope '$ScopeName'."
        return @()
    }

    Write-Host "[RANK] Ranking $($visibleEntries.Count) entries for query '$QueryStr' (scope=$ScopeName)"

    $ranked = Invoke-RankEntries -Entries $visibleEntries -QueryStr $QueryStr -ScopeName $ScopeName -DecayPath $DecayDbPath

    if ($ranked.Count -eq 0) {
        Write-Host "[RANK] No results."
        return @()
    }

    if ($LimitVal -gt 0 -and $ranked.Count -gt $LimitVal) {
        $ranked = $ranked | Select-Object -First $LimitVal
    }

    Write-Host ""
    Write-Host "=== Relevance Ranking Results ==="
    $scopeDisplay = $ScopeName
    if ([string]::IsNullOrEmpty($scopeDisplay)) { $scopeDisplay = "all" }
    Write-Host ("Query: {0} | Scope: {1} | Results: {2}" -f $QueryStr, $scopeDisplay, $ranked.Count)
    Write-Host ""

    $i = 1
    foreach ($r in $ranked) {
        $anchorStr = ""
        if ($r.anchors.Count -gt 0) {
            $anchorStr = " | anchors: " + (($r.anchors | ForEach-Object { $_.type + ":" + $_.ref }) -join ", ")
        }
        $valDisplay = $r.value
        if ($valDisplay.Length -gt 60) { $valDisplay = $valDisplay.Substring(0, 60) + "..." }
        Write-Host ("  [{0}] score={1} (lex={2} sem={3} decay={4}) [{5}] {6} = {7}{8}" -f `
            $i, $r.hybrid_score, $r.lexical_score, $r.semantic_score, $r.decay_boost, `
            $r.scope, $r.key, $valDisplay, $anchorStr)
        $i++
    }
    Write-Host ""
    Write-Host "=== End Ranking ==="

    return $ranked
}

# --- Rerank: take pre-fetched entries (JSON) and rank them ---

function Invoke-Rerank {
    param(
        [string]$JsonStr,
        [string]$QueryStr,
        [int]$LimitVal
    )

    if ([string]::IsNullOrEmpty($JsonStr)) {
        Write-Host "[RERANK] No entries JSON provided."
        return @()
    }

    try {
        $parsed = $JsonStr | ConvertFrom-Json
    } catch {
        Write-Host "[RERANK] Failed to parse JSON."
        return @()
    }

    $entriesArray = @()
    if ($parsed -is [array]) {
        $entriesArray = $parsed
    } else {
        $entriesArray = @($parsed)
    }

    if ($entriesArray.Count -eq 0) {
        Write-Host "[RERANK] No entries to rank."
        return @()
    }

    Write-Host "[RERANK] Ranking $($entriesArray.Count) pre-fetched entries for query '$QueryStr'"

    $ranked = Invoke-RankEntries -Entries $entriesArray -QueryStr $QueryStr -ScopeName "" -DecayPath $DecayDbPath

    if ($LimitVal -gt 0 -and $ranked.Count -gt $LimitVal) {
        $ranked = $ranked | Select-Object -First $LimitVal
    }

    Write-Host ""
    Write-Host "=== Re-Ranking Results ==="
    Write-Host ("Query: {0} | Input: {1} | Results: {2}" -f $QueryStr, $entriesArray.Count, $ranked.Count)
    Write-Host ""

    $i = 1
    foreach ($r in $ranked) {
        $anchorStr = ""
        if ($r.anchors.Count -gt 0) {
            $anchorStr = " | anchors: " + (($r.anchors | ForEach-Object { $_.type + ":" + $_.ref }) -join ", ")
        }
        $valDisplay = $r.value
        if ($valDisplay.Length -gt 60) { $valDisplay = $valDisplay.Substring(0, 60) + "..." }
        Write-Host ("  [{0}] score={1} (lex={2} sem={3} decay={4}) [{5}] {6} = {7}{8}" -f `
            $i, $r.hybrid_score, $r.lexical_score, $r.semantic_score, $r.decay_boost, `
            $r.scope, $r.key, $valDisplay, $anchorStr)
        $i++
    }
    Write-Host ""

    Write-Host "=== End Re-Ranking ==="

    return ,@($ranked)
}

# --- ExtractAnchors ---

function Invoke-ExtractAnchors {
    param(
        [string]$TextStr,
        [string]$ScopeName,
        [string]$KeyName
    )

    if (-not [string]::IsNullOrEmpty($TextStr)) {
        $anchors = Extract-AnchorPatterns -TextStr $TextStr
        Write-Host ""
        Write-Host "=== Artifact Anchors ==="
        Write-Host "Source: direct text"
        Write-Host "Anchors found: $($anchors.Count)"
        Write-Host ""
        foreach ($a in $anchors) {
            Write-Host ("  [{0}] {1} (raw: {2})" -f $a.type, $a.ref, $a.raw)
        }
        Write-Host ""
        Write-Host "=== End Anchors ==="
        return $anchors
    }

    if ([string]::IsNullOrEmpty($ScopeName) -or [string]::IsNullOrEmpty($KeyName)) {
        Write-Host "[ANCHOR] Provide -Text, or -Scope and -Key together."
        return @()
    }

    $storeData = Read-StoreData -Path $DbPath
    foreach ($e in $storeData.entries) {
        if ([string]$e.scope -eq $ScopeName -and [string]$e.key -eq $KeyName) {
            $val = ""
            if ($e.value -ne $null) { $val = [string]$e.value }
            $anchors = Extract-AnchorPatterns -TextStr $val
            Write-Host ""
            Write-Host "=== Artifact Anchors ==="
            Write-Host "Source: $ScopeName/$KeyName"
            Write-Host "Anchors found: $($anchors.Count)"
            Write-Host ""
            foreach ($a in $anchors) {
                Write-Host ("  [{0}] {1} (raw: {2})" -f $a.type, $a.ref, $a.raw)
            }
            Write-Host ""
            Write-Host "=== End Anchors ==="
            return $anchors
        }
    }

    Write-Host "[ANCHOR] Entry not found: $ScopeName/$KeyName"
    return @()
}

# --- RankReport: show ranking for all entries ---

function Invoke-RankReport {
    param([string]$ScopeName)

    $storeData = Read-StoreData -Path $DbPath
    if ($storeData.entries.Count -eq 0) {
        Write-Host "[REPORT] No entries in store."
        return
    }

    $visibleScopes = Get-RerankVisibleScopes -ScopeName $ScopeName
    $visibleEntries = @()
    foreach ($e in $storeData.entries) {
        if ($visibleScopes -contains [string]$e.scope) {
            $visibleEntries += $e
        }
    }

    if ($visibleEntries.Count -eq 0) {
        Write-Host "[REPORT] No visible entries."
        return
    }

    $ranked = Invoke-RankEntries -Entries $visibleEntries -QueryStr "" -ScopeName $ScopeName -DecayPath $DecayDbPath

    Write-Host ""
    Write-Host "=== Relevance Report (no query, baseline scores) ==="
    $scopeDisplay = $ScopeName
    if ([string]::IsNullOrEmpty($scopeDisplay)) { $scopeDisplay = "all" }
    Write-Host "Scope: $scopeDisplay | Entries: $($ranked.Count)"
    Write-Host ""

    $i = 1
    foreach ($r in $ranked) {
        $anchorCount = $r.anchors.Count
        Write-Host ("  [{0}] score={1} (lex={2} sem={3} decay={4}) [{5}] {6} (access={7}, anchors={8})" -f `
            $i, $r.hybrid_score, $r.lexical_score, $r.semantic_score, $r.decay_boost, `
            $r.scope, $r.key, $r.access_count, $anchorCount)
        $i++
    }
    Write-Host ""
    Write-Host "=== End Report ==="
}

# --- SelfTest ---

function Invoke-SelfTest {
    Write-Host ""
    Write-Host "=== scope-rerank.ps1 SelfTest ==="
    Write-Host ""

    $script:passCount = 0
    $script:failCount = 0

    function Assert-Test {
        param([string]$Name, [bool]$Condition)
        if ($Condition) {
            Write-Host "  [PASS] $Name"
            $script:passCount++
        } else {
            Write-Host "  [FAIL] $Name"
            $script:failCount++
        }
    }

    # --- Test 1: Keyword Extraction ---
    Write-Host "--- Test 1: Keyword Extraction ---"
    $kw = Get-RerankKeywords -Text "rts-gas-setup"
    Assert-Test "Hyphen split: rts-gas-setup -> 3 keywords" ($kw.Count -ge 3)
    Assert-Test "Has 'rts'" ($kw -contains "rts")
    Assert-Test "Has 'gas'" ($kw -contains "gas")
    Assert-Test "Has 'setup'" ($kw -contains "setup")

    $kw2 = Get-RerankKeywords -Text "Lyra GAS for RTS"
    Assert-Test "Space split: 3 keywords" ($kw2.Count -ge 3)
    Assert-Test "Has 'lyra'" ($kw2 -contains "lyra")

    $kw3 = Get-RerankKeywords -Text ""
    Assert-Test "Empty text: 0 keywords" ($kw3.Count -eq 0)

    $kw4 = Get-RerankKeywords -Text "a"
    Assert-Test "Single char: 0 keywords" ($kw4.Count -eq 0)

    # --- Test 2: Artifact Anchor Extraction ---
    Write-Host "--- Test 2: Artifact Anchor Extraction ---"
    $anchors = Extract-AnchorPatterns -TextStr "See issue #123 and PR #456 for details"
    $issueFound = $false
    $prFound = $false
    foreach ($a in $anchors) {
        if ($a.type -eq "issue" -and $a.ref -eq "123") { $issueFound = $true }
        if ($a.type -eq "pr" -and $a.ref -eq "456") { $prFound = $true }
    }
    Assert-Test "Finds issue #123" $issueFound
    Assert-Test "Finds PR #456" $prFound

    $anchors2 = Extract-AnchorPatterns -TextStr "Commit abc1234 fixes the bug"
    $hasCommit = $false
    foreach ($a in $anchors2) { if ($a.type -eq "commit" -and $a.ref -eq "abc1234") { $hasCommit = $true } }
    Assert-Test "Finds commit hash abc1234" $hasCommit

    $anchors3 = Extract-AnchorPatterns -TextStr "File at C:\Project\src\main.ps1 was modified"
    $hasFile = $false
    foreach ($a in $anchors3) { if ($a.type -eq "file") { $hasFile = $true } }
    Assert-Test "Finds Windows file path" $hasFile

    $anchors4 = Extract-AnchorPatterns -TextStr "See https://github.com/repo/pull/789"
    $hasUrl = $false
    foreach ($a in $anchors4) { if ($a.type -eq "url") { $hasUrl = $true } }
    Assert-Test "Finds URL" $hasUrl

    $anchors5 = Extract-AnchorPatterns -TextStr "Video BV19EE16aEn7 explains it"
    $hasVideo = $false
    foreach ($a in $anchors5) { if ($a.type -eq "video" -and $a.ref -eq "BV19EE16aEn7") { $hasVideo = $true } }
    Assert-Test "Finds BV video ID" $hasVideo

    $anchors6 = Extract-AnchorPatterns -TextStr "No anchors here, just plain text"
    Assert-Test "No anchors in plain text" ($anchors6.Count -eq 0)

    $anchors7 = Extract-AnchorPatterns -TextStr ""
    Assert-Test "Empty text: 0 anchors" ($anchors7.Count -eq 0)

    # --- Test 3: Lexical Scoring ---
    Write-Host "--- Test 3: Lexical Scoring ---"
    $lexKw = @(Get-RerankKeywords -Text "rts gas")
    $lexExact = Get-LexicalScore -EntryKey "rts-gas-setup" -EntryValue "Use Lyra GAS" -QueryKeywords $lexKw
    Assert-Test "Exact match score > 0.5" ($lexExact -gt 0.5)

    $lexPartial = Get-LexicalScore -EntryKey "unrelated-key" -EntryValue "some value" -QueryKeywords $lexKw
    Assert-Test "No match score = 0" ($lexPartial -eq 0)

    $lexEmpty = Get-LexicalScore -EntryKey "any-key" -EntryValue "any value" -QueryKeywords @()
    Assert-Test "Empty query: default 0.5" ($lexEmpty -eq 0.5)

    # --- Test 4: Semantic Scoring ---
    Write-Host "--- Test 4: Semantic Scoring ---"
    $semHigh = Get-SemanticScore -EntryScope "memory" -AccessCount 10 -UpdatedAt ((Get-Date).ToString("o")) -CreatedAt ""
    Assert-Test "High-access fresh memory score > 0.5" ($semHigh -gt 0.5)

    $semLow = Get-SemanticScore -EntryScope "general" -AccessCount 0 -UpdatedAt "2026-01-01T00:00:00" -CreatedAt "2026-01-01T00:00:00"
    Assert-Test "Low-access stale general score < 0.3" ($semLow -lt 0.3)

    $semScopeMemory = Get-SemanticScore -EntryScope "memory" -AccessCount 0 -UpdatedAt "" -CreatedAt ""
    $semScopeGeneral = Get-SemanticScore -EntryScope "general" -AccessCount 0 -UpdatedAt "" -CreatedAt ""
    Assert-Test "Memory scope > general scope (same access/date)" ($semScopeMemory -gt $semScopeGeneral)

    # --- Test 5: Hybrid Score Integration ---
    Write-Host "--- Test 5: Hybrid Score Integration ---"
    $testEntries = @(
        @{ id = "t1"; scope = "project"; key = "rts-gas-ref"; value = "Use Lyra GAS for RTS ability system"; access_count = 5; updated_at = (Get-Date).ToString("o"); created_at = (Get-Date).ToString("o") }
        @{ id = "t2"; scope = "session"; key = "temp-draft"; value = "Draft note about GAS"; access_count = 0; updated_at = "2026-01-01T00:00:00"; created_at = "2026-01-01T00:00:00" }
        @{ id = "t3"; scope = "memory"; key = "rts-gas-concept"; value = "GAS is Gameplay Ability System"; access_count = 8; updated_at = (Get-Date).ToString("o"); created_at = (Get-Date).ToString("o") }
    )

    $tempDecay = Join-Path $env:TEMP ("scope-rerank-test-decay-" + [Guid]::NewGuid().ToString("N") + ".json")
    $decayInit = @{ protected = @(); meta = @{ created_at = (Get-Date).ToString("o"); version = 1 } }
    $decayJson = $decayInit | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($tempDecay, $decayJson, [System.Text.Encoding]::UTF8)

    $ranked = Invoke-RankEntries -Entries $testEntries -QueryStr "rts gas" -ScopeName "project" -DecayPath $tempDecay
    Assert-Test "Ranked 3 entries" ($ranked.Count -eq 3)

    $topEntry = $ranked[0]
    Assert-Test "Top entry is rts-gas-concept (memory)" ($topEntry.key -eq "rts-gas-concept")
    Assert-Test "Top entry score > 0.3" ($topEntry.hybrid_score -gt 0.3)
    Assert-Test "Top entry has lexical score" ($topEntry.lexical_score -gt 0)
    Assert-Test "Top entry has semantic score" ($topEntry.semantic_score -gt 0)

    $bottomEntry = $ranked[2]
    Assert-Test "Bottom entry is temp-draft (session)" ($bottomEntry.key -eq "temp-draft")
    Assert-Test "Bottom score < top score" ($bottomEntry.hybrid_score -lt $topEntry.hybrid_score)

    # --- Test 6: Anchor in Ranked Results ---
    Write-Host "--- Test 6: Anchor in Ranked Results ---"
    $anchorEntry = @{ id = "a1"; scope = "project"; key = "rts-refs"; value = "See issue #42 and commit a1b2c3d4 for context"; access_count = 2; updated_at = (Get-Date).ToString("o"); created_at = (Get-Date).ToString("o") }
    $anchorRanked = Invoke-RankEntries -Entries @($anchorEntry) -QueryStr "refs" -ScopeName "project" -DecayPath $tempDecay
    Assert-Test "Anchor entry ranked" ($anchorRanked.Count -eq 1)
    $aEntry = $anchorRanked[0]
    Assert-Test "Anchors extracted from ranked entry" ($aEntry.anchors.Count -ge 2)
    $hasIssueAnchor = $false
    $hasCommitAnchor = $false
    foreach ($a in $aEntry.anchors) {
        if ($a.type -eq "issue" -and $a.ref -eq "42") { $hasIssueAnchor = $true }
        if ($a.type -eq "commit" -and $a.ref -eq "a1b2c3d4") { $hasCommitAnchor = $true }
    }
    Assert-Test "Issue anchor in ranked result" $hasIssueAnchor
    Assert-Test "Commit anchor in ranked result" $hasCommitAnchor

    # --- Test 7: Scope Visibility Filtering ---
    Write-Host "--- Test 7: Scope Visibility Filtering ---"
    $visibleProject = Get-RerankVisibleScopes -ScopeName "project"
    Assert-Test "Project sees persistent scopes" ($visibleProject -contains "project" -and $visibleProject -contains "memory")
    Assert-Test "Project does not see session" (-not ($visibleProject -contains "session"))

    $visibleSession = Get-RerankVisibleScopes -ScopeName "session"
    Assert-Test "Session sees persistent + session" ($visibleSession -contains "session" -and $visibleSession -contains "memory")
    Assert-Test "Session does not see general" (-not ($visibleSession -contains "general"))

    $visibleAll = Get-RerankVisibleScopes -ScopeName ""
    Assert-Test "Empty scope sees all 6" ($visibleAll.Count -eq 6)

    # --- Test 8: Rerank from JSON ---
    Write-Host "--- Test 8: Rerank from JSON ---"
    $jsonEntries = '[{"scope":"project","key":"rts-gas","value":"Use Lyra GAS","access_count":3,"updated_at":"2026-07-08T10:00:00","created_at":"2026-07-08T10:00:00"},{"scope":"session","key":"temp-note","value":"temp note","access_count":0,"updated_at":"2026-01-01T00:00:00","created_at":"2026-01-01T00:00:00"}]'
    $reranked = Invoke-Rerank -JsonStr $jsonEntries -QueryStr "gas" -LimitVal 5
    Assert-Test "Reranked 2 entries" ($reranked.Count -eq 2)
    Assert-Test "Top reranked is rts-gas" ($reranked[0].key -eq "rts-gas")

    # --- Test 9: Decay Boost ---
    Write-Host "--- Test 9: Decay Boost ---"
    $protectedDecay = @{ protected = @(@{ scope = "memory"; key = "rts-protected" }); meta = @{ created_at = (Get-Date).ToString("o"); version = 1 } }
    $protectedJson = $protectedDecay | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($tempDecay, $protectedJson, [System.Text.Encoding]::UTF8)

    $boostProtected = Get-DecayAdjustment -EntryScope "memory" -AccessCount 5 -UpdatedAt "" -DecayPath $tempDecay
    Assert-Test "Protected scope gets boost" ($boostProtected -gt 0)

    $boostUnprotected = Get-DecayAdjustment -EntryScope "session" -AccessCount 0 -UpdatedAt "" -DecayPath $tempDecay
    Assert-Test "Unprotected scope gets no boost" ($boostUnprotected -eq 0)

    $boostNoFile = Get-DecayAdjustment -EntryScope "project" -AccessCount 0 -UpdatedAt "" -DecayPath "C:\nonexistent\path.json"
    Assert-Test "Missing decay file: no boost" ($boostNoFile -eq 0)

    # --- Test 10: Weight Configuration ---
    Write-Host "--- Test 10: Weight Configuration ---"
    Assert-Test "Lexical weight = 0.45" ($weightLexical -eq 0.45)
    Assert-Test "Semantic weight = 0.55" ($weightSemantic -eq 0.55)
    Assert-Test "Weights sum to 1.0" (($weightLexical + $weightSemantic) -eq 1.0)

    $memPriority = $scopePriority["memory"]
    $genPriority = $scopePriority["general"]
    Assert-Test "Memory priority = 1.0" ($memPriority -eq 1.0)
    Assert-Test "General priority = 0.20" ($genPriority -eq 0.20)
    Assert-Test "Memory > project > ops > session > general" ($memPriority -gt $scopePriority["project"] -and $scopePriority["project"] -gt $scopePriority["ops"] -and $scopePriority["ops"] -gt $scopePriority["session"] -and $scopePriority["session"] -gt $genPriority)

    # Cleanup
    if (Test-Path $tempDecay) { Remove-Item $tempDecay -Force }

    Write-Host ""
    Write-Host "=== SelfTest Results: $script:passCount passed, $script:failCount failed ==="
    if ($script:failCount -gt 0) {
        exit 1
    }
}

# --- Main Dispatch ---

if ($SelfTest) {
    Invoke-SelfTest
    exit 0
}

if ($Init) {
    Initialize-Rerank
    exit 0
}

if ($Rank) {
    $results = Invoke-Rank -QueryStr $Query -ScopeName $Scope -LimitVal $Limit
    exit 0
}

if ($Rerank) {
    $results = Invoke-Rerank -JsonStr $EntriesJson -QueryStr $Query -LimitVal $Limit
    exit 0
}

if ($ExtractAnchors) {
    $results = Invoke-ExtractAnchors -TextStr $Text -ScopeName $Scope -KeyName $Key
    exit 0
}

if ($RankReport) {
    Invoke-RankReport -ScopeName $Scope
    exit 0
}

Write-Host "Usage: .\scope-rerank.ps1 -Init | -Rank -Query '...' -Scope project | -Rerank -EntriesJson '...' -Query '...' | -ExtractAnchors -Text '...' | -RankReport -Scope project | -SelfTest"
exit 0
