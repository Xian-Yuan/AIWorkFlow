param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("scan","verify")]
    [string]$Command,
    [string]$RootPath,
    [Parameter(Mandatory=$true)]
    [string]$ReportPath,
    [string]$KeyName,
    [string]$PublicKeyPath,
    [switch]$Apply,
    [string]$NameFilter
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

try {
    if ($Command -eq "verify") {
        if (-not $PublicKeyPath) { throw "PublicKeyPath is required for verify" }
        Test-AuthoritySignedArtifact $ReportPath "$ReportPath.sig.json" $PublicKeyPath "migration_digest" |
            ConvertTo-Json -Depth 20
        exit 0
    }
    if (-not $RootPath) { throw "RootPath is required for scan" }
    if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) { throw "RootPath not found: $RootPath" }
    if ($Apply -and -not $KeyName) { throw "KeyName is required when Apply is used" }
    $metadata = if ($Apply) { New-AuthorityIssuerKey $KeyName } else { $null }
    $filters = @($NameFilter -split ";" | Where-Object { $_ })
    $rows = @()
    foreach ($yaml in Get-ChildItem -LiteralPath $RootPath -Recurse -Filter ".task.yaml" -File) {
        $taskDir = Split-Path -Parent $yaml.FullName
        $name = Split-Path -Leaf $taskDir
        if ($filters.Count -gt 0 -and $name -notin $filters) { continue }
        $phase = Get-AuthorityYamlField $yaml.FullName "phase"
        $archived = Get-AuthorityYamlField $yaml.FullName "archived"
        $profile = Get-AuthorityYamlField $yaml.FullName "authority_profile"
        $authorityStatus = Get-AuthorityYamlField $yaml.FullName "authority_status"
        $classification = if ($profile -eq "issuer-worker-v1" -and $authorityStatus -in @("draft","issued","worker_active","verified","archived","repair_issued")) {
            "not_applicable"
        }
        elseif ($archived -eq "true" -and $phase -notin @("archive","archived")) {
            "migration_required"
        }
        else {
            $manifest = Join-Path $taskDir "issuer\packet-manifest.json"
            $signature = Join-Path $taskDir "issuer\packet-manifest.sig.json"
            if ((Test-Path -LiteralPath $manifest) -and (Test-Path -LiteralPath $signature)) { "signed_existing" } else { "legacy_untrusted" }
        }
        if ($Apply) {
            Set-AuthorityYamlFields $yaml.FullName ([ordered]@{ legacy_trust=$classification })
        }
        $rows += [ordered]@{
            task = $name
            path = $taskDir
            phase = $phase
            archived = $archived
            classification = $classification
        }
    }
    $base = [ordered]@{
        schema_version = 1
        scanned_at = [datetimeoffset]::Now.ToString("o")
        issuer_key_id = $(if ($metadata) { $metadata.issuer_key_id } else { $null })
        issuer_sid = $(if ($metadata) { $metadata.issuer_sid } else { Get-AuthorityCurrentSid })
        applied = [bool]$Apply
        tasks = $rows
    }
    $digest = Get-AuthorityCanonicalDigest $base
    $report = [ordered]@{}
    foreach ($key in $base.Keys) { $report[$key] = $base[$key] }
    $report.migration_digest = $digest
    Write-AuthorityJson $ReportPath $report
    if ($Apply) {
        Write-AuthorityJson "$ReportPath.sig.json" (New-AuthoritySignatureRecord $KeyName $digest)
    }
    $report | ConvertTo-Json -Depth 20
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
