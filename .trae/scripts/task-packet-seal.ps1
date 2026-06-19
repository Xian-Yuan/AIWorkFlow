param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("seal","verify")]
    [string]$Command,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskName,
    [string]$KeyName,
    [string]$TaskRoot
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

try {
    $task = Resolve-AuthorityTask $TaskName $TaskRoot
    if (-not (Test-Path -LiteralPath $task.Yaml)) { throw ".task.yaml missing" }
    $issuerDir = Join-Path $task.Dir "issuer"
    $manifestPath = Join-Path $issuerDir "packet-manifest.json"
    $signaturePath = Join-Path $issuerDir "packet-manifest.sig.json"
    $publicPath = Join-Path $issuerDir "public-key.json"

    if ($Command -eq "verify") {
        $manifest = Test-AuthorityPacketSeal $task
        $manifest | ConvertTo-Json -Depth 12
        exit 0
    }

    if (-not $KeyName) { throw "KeyName is required for seal" }
    $metadata = New-AuthorityIssuerKey $KeyName
    $existingIssuerSid = Get-AuthorityYamlField $task.Yaml "issuer_sid"
    $existingKeyId = Get-AuthorityYamlField $task.Yaml "issuer_key_id"
    if ($existingIssuerSid -and $existingIssuerSid -ne $metadata.issuer_sid) { throw "Task already belongs to another issuer SID" }
    if ($existingKeyId -and $existingKeyId -ne $metadata.issuer_key_id) { throw "Task already belongs to another issuer key" }

    $currentVersion = Get-AuthorityYamlField $task.Yaml "packet_version"
    $version = if ($currentVersion) { [int]$currentVersion + 1 } else { 1 }
    $coreRows = @()
    foreach ($relative in Get-AuthorityPacketCoreFiles $task) {
        $full = Join-Path $task.Dir ($relative -replace "/", "\")
        $coreRows += [ordered]@{ path=$relative; sha256=(Get-AuthorityFileDigest $full) }
    }
    $base = [ordered]@{
        schema_version = 1
        task_name = (Split-Path -Leaf $task.Dir)
        packet_version = $version
        authority_profile = "issuer-worker-v1"
        issuer_key_id = $metadata.issuer_key_id
        issuer_sid = $metadata.issuer_sid
        issued_at = (Get-Date).ToString("o")
        core_files = $coreRows
    }
    $digest = Get-AuthorityCanonicalDigest $base
    $manifest = [ordered]@{}
    foreach ($key in $base.Keys) { $manifest[$key] = $base[$key] }
    $manifest.packet_digest = $digest
    $signature = New-AuthoritySignatureRecord $KeyName $digest
    $versionedManifestPath = Join-Path $issuerDir ("packet-manifest-v{0:D3}.json" -f $version)
    $versionedSignaturePath = Join-Path $issuerDir ("packet-manifest-v{0:D3}.sig.json" -f $version)
    if (Test-Path -LiteralPath $versionedManifestPath) { throw "Packet manifest version already exists: $version" }

    Write-AuthorityJson $publicPath $metadata
    Write-AuthorityJson $versionedManifestPath $manifest
    Write-AuthorityJson $versionedSignaturePath $signature
    Write-AuthorityJson $manifestPath $manifest
    Write-AuthorityJson $signaturePath $signature
    Set-AuthorityYamlFields $task.Yaml ([ordered]@{
        authority_profile = "issuer-worker-v1"
        authority_status = "issued"
        issuer_key_id = $metadata.issuer_key_id
        issuer_sid = $metadata.issuer_sid
        packet_version = $version
        packet_digest = $digest
        legacy_trust = "not_applicable"
    })
    Test-AuthorityPacketSeal $task | ConvertTo-Json -Depth 12
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
