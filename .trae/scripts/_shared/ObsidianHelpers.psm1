# ObsidianHelpers.psm1
# Shared PowerShell helpers for Obsidian Knowledge Autopoiesis scripts
# PowerShell 5.1 compatible - no external modules required

$script:DefaultVaultPath = "E:\ObsidianVault"

function Get-VaultPath {
    param([string]$VaultPath = $script:DefaultVaultPath)
    if (-not (Test-Path $VaultPath)) { Write-Error "Vault path not found: $VaultPath"; return $null }
    return (Resolve-Path $VaultPath).Path
}

function Read-FrontMatter {
    param([Parameter(Mandatory=$true)][string]$FilePath)
    if (-not (Test-Path $FilePath)) { Write-Warning "File not found: $FilePath"; return @{} }
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    if ($null -eq $content) { return @{} }
    $fmMatch = [regex]::Match($content, '(?s)^---\r?\n(.*?)\r?\n---')
    if (-not $fmMatch.Success) { return @{} }
    $fmText = $fmMatch.Groups[1].Value
    $result = @{}
    $lines = $fmText -split "`n"
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i].TrimEnd()
        if ($line -match '^\s*([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*(.+)$') {
            $key = $Matches[1]; $val = $Matches[2].Trim()
            if ($val -match '^\[(.+)\]$') {
                $items = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim("'").Trim('"') } | Where-Object { $_ -ne '' }
                $result[$key] = @($items)
            } elseif ($val -match '^"(.*)"$') { $result[$key] = $Matches[1] }
            elseif ($val -match "^'(.*)'$") { $result[$key] = $Matches[1] }
            elseif ($val -eq 'true' -or $val -eq 'True') { $result[$key] = $true }
            elseif ($val -eq 'false' -or $val -eq 'False') { $result[$key] = $false }
            elseif ($val -eq 'null') { $result[$key] = $null }
            else { $result[$key] = $val }
        } elseif ($line -match '^\s*([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*$') {
            $key = $Matches[1]; $arr = @(); $j = $i + 1
            while ($j -lt $lines.Count -and $lines[$j] -match '^\s*-\s+(.+)$') {
                $item = $Matches[1].Trim().Trim("'").Trim('"'); $arr += $item; $j++
            }
            if ($arr.Count -gt 0) { $result[$key] = @($arr); $i = $j - 1 } else { $result[$key] = $null }
        }
        $i++
    }
    return $result
}

function Get-BodyText {
    param([Parameter(Mandatory=$true)][string]$FilePath)
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    if ($null -eq $content) { return "" }
    $fmMatch = [regex]::Match($content, '(?s)^---\r?\n.*?\r?\n---\r?\n?(.*)')
    if ($fmMatch.Success) { return $fmMatch.Groups[1].Value }
    return $content
}

function Get-FirstH1 {
    param([string]$Body)
    $m = [regex]::Match($Body, '^#\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ""
}

function Get-FirstParagraph {
    param([string]$Body)
    $lines = $Body -split "`n"; $started = $false; $para = @()
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -and $started) { break }
        if ($trimmed -ne '' -and $trimmed -notmatch '^#' -and $trimmed -notmatch '^<!--') {
            $started = $true; $para += $trimmed
        }
    }
    $text = $para -join ' '
    if ($text.Length -gt 200) { $text = $text.Substring(0, 200) }
    return $text
}

function Parse-ClassificationRules {
    param([Parameter(Mandatory=$true)][string]$RulesPath)
    if (-not (Test-Path $RulesPath)) { Write-Error "Classification rules not found: $RulesPath"; return $null }
    $lines = Get-Content $RulesPath -Encoding UTF8
    $result = @{ rules = @(); fallback = $null; aliases = @{} }
    $inRules = $false; $inFallback = $false
    $currentRule = $null; $currentFallback = @{}
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq 'rules:') { $inRules = $true; $inFallback = $false; continue }
        if ($trimmed -eq 'fallback:') { $inFallback = $true; $inRules = $false; continue }
        # Section boundary: unindented line (0 leading spaces) that is a key or comment, not a list item
        if ($inRules -and $line.Length -gt 0 -and $line[0] -ne ' ' -and $line[0] -ne "`t" -and $trimmed -notmatch '^#' -and $trimmed -ne '') {
            $inRules = $false
        }
        if ($inFallback) {
            if ($trimmed -match 'strategy:\s*(\S+)') { $currentFallback['strategy'] = $Matches[1] }
            elseif ($trimmed -match 'pattern_template:\s*"([^"]+)"') { $currentFallback['pattern_template'] = $Matches[1] }
            elseif ($trimmed -match 'default_subdomain:\s*"([^"]+)"') { $currentFallback['default_subdomain'] = $Matches[1] }
            elseif ($trimmed -match 'unclassified_queue:\s*"([^"]+)"') { $currentFallback['unclassified_queue'] = $Matches[1] }
        }
        if ($inRules) {
            # Rule entries start with "  - tag:" (2-space indent + dash)
            if ($trimmed -match '^- tag:\s*(\S+)') {
                if ($null -ne $currentRule -and $currentRule.ContainsKey('tag') -and $currentRule.ContainsKey('target')) {
                    $result.rules += $currentRule
                    foreach ($a in $currentRule.aliases) { $result.aliases[$a] = $currentRule.tag }
                }
                $currentRule = @{ tag = $Matches[1]; aliases = @() }
            }
            elseif ($null -ne $currentRule) {
                if ($trimmed -match 'target:\s*"([^"]+)"') { $currentRule['target'] = $Matches[1] }
                elseif ($trimmed -match 'priority:\s*(\d+)') { $currentRule['priority'] = [int]$Matches[1] }
                elseif ($trimmed -match 'aliases:\s*\[([^\]]+)\]') {
                    $currentRule.aliases = $Matches[1] -split ',' | ForEach-Object { $_.Trim().Trim("'").Trim('"') } | Where-Object { $_ -ne '' }
                }
            }
        }
    }
    if ($null -ne $currentRule -and $currentRule.ContainsKey('tag') -and $currentRule.ContainsKey('target')) {
        $result.rules += $currentRule
        foreach ($a in $currentRule.aliases) { $result.aliases[$a] = $currentRule.tag }
    }
    if ($currentFallback.Count -gt 0) { $result.fallback = $currentFallback }
    # Sort by priority
    $result.rules = @($result.rules | Sort-Object { if ($_.ContainsKey('priority')) { $_['priority'] } else { 999 } })
    return $result
}

function Find-TargetPath {
    param(
        [hashtable]$FrontMatter,
        [hashtable]$ParsedRules,
        [string]$VaultPath
    )
    $tags = @()
    if ($FrontMatter.ContainsKey('tags')) { $tags += @($FrontMatter['tags']) }
    if ($FrontMatter.ContainsKey('tag') -and $FrontMatter['tag']) { $tags += @($FrontMatter['tag']) }
    foreach ($t in $tags) {
        $normalizedTag = $t.ToString().ToLower().Trim()
        if ($ParsedRules.aliases.ContainsKey($normalizedTag)) { $normalizedTag = $ParsedRules.aliases[$normalizedTag] }
        foreach ($rule in $ParsedRules.rules) {
            if ($rule.tag -eq $normalizedTag) {
                $target = $rule.target
                return Join-Path $VaultPath $target
            }
        }
    }
    # Fallback: use domain_path
    if ($FrontMatter.ContainsKey('domain_path') -and $FrontMatter['domain_path']) {
        $dp = $FrontMatter['domain_path'].ToString()
        $parts = $dp -split '/'
        if ($parts.Count -ge 1) {
            $domain = $parts[0]
            $subdomain = if ($parts.Count -ge 2) { $parts[1] } else { '其他' }
            $domainMap = @{ 'ai' = 'AI'; 'ue' = 'UE'; 'game' = '游戏开发'; 'dev' = '通用开发'; 'infra' = '通用开发/基础设施'; 'search' = '搜索引擎'; 'data' = '数据工程' }
            $mappedDomain = if ($domainMap.ContainsKey($domain)) { $domainMap[$domain] } else { $domain }
            $mappedSub = $subdomain.Substring(0,1).ToUpper() + $subdomain.Substring(1)
            return Join-Path $VaultPath "知识/$mappedDomain/$mappedSub/"
        }
    }
    return $null
}

function Add-ToUnclassifiedQueue {
    param([string]$FilePath, [string]$QueuePath, [string[]]$Tags)
    $dir = Split-Path $QueuePath -Parent
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    $entry = "- file: `"$FilePath`"`n  tags: [$($Tags -join ', ')]`n  queued_at: `"$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')`"`n"
    if (Test-Path $QueuePath) { Add-Content -Path $QueuePath -Value $entry -Encoding UTF8 }
    else { "# Unclassified file queue`n# Auto-generated by obsidian-classify.ps1`n`n$entry" | Out-File -FilePath $QueuePath -Encoding UTF8 }
}

function Write-RedirectStub {
    param([string]$StubPath, [string]$TargetWikiLink)
    $content = "移至 [[$TargetWikiLink]]"
    Set-Content -Path $StubPath -Value $content -Encoding UTF8 -NoNewline
}

function New-Timestamp { return Get-Date -Format 'yyyyMMdd-HHmmss' }
function New-DateStamp { return Get-Date -Format 'yyyy-MM-dd' }

function Write-JsonReport {
    param([hashtable]$Data, [string]$ReportDir, [string]$Prefix)
    if (-not (Test-Path $ReportDir)) { New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null }
    $ts = New-Timestamp; $filename = "${Prefix}-${ts}.json"; $path = Join-Path $ReportDir $filename
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("{")
    $keys = @($Data.Keys); $idx = 0
    foreach ($k in $keys) {
        $v = $Data[$k]; $comma = if ($idx -lt $keys.Count - 1) { "," } else { "" }
        if ($v -is [int] -or $v -is [long] -or $v -is [double]) { [void]$sb.AppendLine("  `"$k`": $v$comma") }
        elseif ($v -is [bool]) { [void]$sb.AppendLine("  `"$k`": $($v.ToString().ToLower())$comma") }
        elseif ($v -is [array]) { $arrStr = ($v | ForEach-Object { "`"$_`"" }) -join ", "; [void]$sb.AppendLine("  `"$k`": [$arrStr]$comma") }
        else { $escaped = ($v.ToString() -replace '\\', '\\' -replace '"', '\"'); [void]$sb.AppendLine("  `"$k`": `"$escaped`"$comma") }
        $idx++
    }
    [void]$sb.AppendLine("}")
    $sb.ToString() | Out-File -FilePath $path -Encoding UTF8
    return $path
}

function Get-Sha1Short {
    param([string]$InputString)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hash = $sha1.ComputeHash($bytes)
    $hex = [BitConverter]::ToString($hash) -replace '-', ''
    return $hex.Substring(0, 8).ToLower()
}

function Estimate-TokenCount {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $cjk = [regex]::Matches($Text, '[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff]')
    $cjkCount = $cjk.Count; $otherLen = $Text.Length - $cjkCount
    return [int]($cjkCount / 2 + $otherLen / 4)
}

function Test-KgIdExists {
    param([string]$KgId, [string]$SearchDir)
    if ([string]::IsNullOrEmpty($KgId)) { return $false }
    if (-not (Test-Path $SearchDir)) { return $false }
    $found = Get-ChildItem -Path $SearchDir -Recurse -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object {
        $fm = Read-FrontMatter $_.FullName
        $fm.ContainsKey('kg_id') -and $fm['kg_id'] -eq $KgId
    } | Select-Object -First 1
    return ($null -ne $found)
}

function Parse-EvolutionRubric {
    param([Parameter(Mandatory=$true)][string]$RubricPath)
    if (-not (Test-Path $RubricPath)) { Write-Error "Evolution rubric not found: $RubricPath"; return $null }
    $lines = Get-Content $RubricPath -Encoding UTF8
    $result = @{ threshold = 0.6; tokens_min = 300; tokens_max = 2000; dimensions = @{} }
    $currentDim = $null; $currentLevel = $null
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match 'gene_extraction_threshold:\s*([\d.]+)') { $result.threshold = [double]$Matches[1] }
        elseif ($trimmed -match 'gene_size_tokens_min:\s*(\d+)') { $result.tokens_min = [int]$Matches[1] }
        elseif ($trimmed -match 'gene_size_tokens_max:\s*(\d+)') { $result.tokens_max = [int]$Matches[1] }
        # Detect dimension header at 2-space indent
        elseif ($line -match '^\s{2}([\w-]+):\s*$' -and $Matches[1] -in @('system-enhance','code-quality','automation','self-evolve')) {
            $currentDim = $Matches[1]; $currentLevel = $null
            $result.dimensions[$currentDim] = @{ name = $currentDim; weight = 0.25; keywords_high = @(); keywords_mid = @(); keywords_low = @() }
        }
        elseif ($null -ne $currentDim) {
            if ($trimmed -match 'weight:\s*([\d.]+)') { $result.dimensions[$currentDim].weight = [double]$Matches[1] }
            elseif ($trimmed -match 'keywords_(high|mid|low):\s*$') { $currentLevel = $Matches[1] }
            elseif ($null -ne $currentLevel -and $trimmed -match '^\s*-\s*"([^"]+)"') {
                $kw = $Matches[1]
                $arr = $result.dimensions[$currentDim]["keywords_$currentLevel"]
                $arr += $kw
                $result.dimensions[$currentDim]["keywords_$currentLevel"] = $arr
            }
        }
    }
    return $result
}

Export-ModuleMember -Function @(
    'Get-VaultPath','Read-FrontMatter','Get-BodyText','Get-FirstH1','Get-FirstParagraph',
    'Parse-ClassificationRules','Find-TargetPath','Add-ToUnclassifiedQueue','Write-RedirectStub',
    'New-Timestamp','New-DateStamp','Write-JsonReport','Get-Sha1Short','Estimate-TokenCount',
    'Test-KgIdExists','Parse-EvolutionRubric'
)
