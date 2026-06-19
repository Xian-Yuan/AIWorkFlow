param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("issue","verify")]
    [string]$Command,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskName,
    [string]$KeyName,
    [string]$WorkPackage,
    [string]$AttemptId,
    [string]$WorkerSid,
    [string[]]$AllowedPaths,
    [ValidateSet("workspace","task")]
    [string]$SourceRoot = "workspace",
    [string]$ExpiresAt,
    [string]$Capability,
    [string]$TaskRoot
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

function Get-CapabilityPaths {
    param([object]$Task, [string]$Relative)
    $path = if ([System.IO.Path]::IsPathRooted($Relative)) { $Relative } else { Join-Path $Task.Dir ($Relative -replace "/", "\") }
    return [pscustomobject]@{
        Artifact = $path
        Signature = "$path.sig.json"
        Public = Join-Path $Task.Dir "issuer\public-key.json"
    }
}

try {
    $task = Resolve-AuthorityTask $TaskName $TaskRoot
    $packet = Test-AuthorityPacketSeal $task
    if ($Command -eq "verify") {
        if (-not $Capability) { throw "Capability is required for verify" }
        $paths = Get-CapabilityPaths $task $Capability
        $artifact = Test-AuthoritySignedArtifact $paths.Artifact $paths.Signature $paths.Public "capability_digest"
        if ($artifact.packet_digest -ne $packet.packet_digest) { throw "Capability packet digest is stale" }
        if ([datetimeoffset]::Parse($artifact.expires_at) -lt [datetimeoffset]::Now) { throw "Capability expired" }
        $artifact | ConvertTo-Json -Depth 15
        exit 0
    }

    foreach ($required in @("KeyName","WorkPackage","AttemptId","WorkerSid")) {
        if (-not (Get-Variable -Name $required -ValueOnly)) { throw "$required is required for issue" }
    }
    if (-not $AllowedPaths -or $AllowedPaths.Count -eq 0) { throw "AllowedPaths is required" }
    $metadata = Assert-AuthorityIssuer $task $KeyName
    if ($WorkerSid -eq $metadata.issuer_sid) { throw "Strong-mode worker SID must differ from issuer SID" }

    $workPackageRelative = Normalize-AuthorityRelativePath $WorkPackage
    $workPackagePath = Join-Path $task.Dir ($workPackageRelative -replace "/", "\")
    if (-not (Test-Path -LiteralPath $workPackagePath -PathType Leaf)) { throw "Work package not found: $workPackageRelative" }
    if ($AttemptId -notmatch "^A\d{3,}$") { throw "AttemptId must match A001 or higher" }
    if ([System.IO.Path]::GetFileName($workPackageRelative) -notmatch "^(WP\d+)") { throw "Work package name must start with WPxx" }
    $workPackageId = $matches[1]
    $normalizedAllowed = @($AllowedPaths | ForEach-Object { $_ -split ";" } | Where-Object { $_ } | ForEach-Object { Normalize-AuthorityRelativePath $_ } | Sort-Object -Unique)
    $packageAllowed = @(Get-AuthorityMarkdownList $workPackagePath "Allowed Paths")
    if ($packageAllowed.Count -eq 0) { throw "Work package has no Allowed Paths section" }
    foreach ($path in $normalizedAllowed) {
        if ($path -notin $packageAllowed) { throw "Capability path exceeds work package Allowed Paths: $path" }
    }
    $expiry = if ($ExpiresAt) { [datetimeoffset]::Parse($ExpiresAt) } else { [datetimeoffset]::Now.AddHours(24) }
    $relative = "capabilities/$workPackageId-$AttemptId.capability.json"
    $artifactPath = Join-Path $task.Dir ($relative -replace "/", "\")
    if (Test-Path -LiteralPath $artifactPath) { throw "Capability already exists: $relative" }
    $base = [ordered]@{
        schema_version = 1
        task_name = (Split-Path -Leaf $task.Dir)
        packet_version = $packet.packet_version
        packet_digest = $packet.packet_digest
        work_package_id = $workPackageId
        work_package_path = $workPackageRelative
        work_package_digest = Get-AuthorityFileDigest $workPackagePath
        attempt_id = $AttemptId
        worker_sid = $WorkerSid
        source_root = $SourceRoot
        allowed_paths = $normalizedAllowed
        progress_directory = "progress/$workPackageId-$AttemptId"
        result_path = "reports/$workPackageId-$AttemptId/result.json"
        issued_at = [datetimeoffset]::Now.ToString("o")
        expires_at = $expiry.ToString("o")
        nonce = [guid]::NewGuid().ToString("N")
        issuer_key_id = $metadata.issuer_key_id
        issuer_sid = $metadata.issuer_sid
    }
    $digest = Get-AuthorityCanonicalDigest $base
    $artifact = [ordered]@{}
    foreach ($key in $base.Keys) { $artifact[$key] = $base[$key] }
    $artifact.capability_digest = $digest
    $signature = New-AuthoritySignatureRecord $KeyName $digest
    Write-AuthorityJson $artifactPath $artifact
    Write-AuthorityJson "$artifactPath.sig.json" $signature
    Set-AuthorityYamlFields $task.Yaml ([ordered]@{ authority_status="worker_active" })
    $artifact | ConvertTo-Json -Depth 15
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
