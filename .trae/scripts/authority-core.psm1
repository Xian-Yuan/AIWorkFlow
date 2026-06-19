Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Get-AuthorityWorkspaceRoot {
    return (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

function Get-AuthorityCurrentSid {
    if ($env:JINLI_AUTH_TEST_MODE -eq "1" -and $env:JINLI_AUTH_TEST_SID) {
        return $env:JINLI_AUTH_TEST_SID
    }
    return [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
}

function Test-AuthorityPathWithinRoot {
    param([string]$Path, [string]$Root)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd("\","/") + [System.IO.Path]::DirectorySeparatorChar
    return $fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-AuthorityTask {
    param(
        [Parameter(Mandatory=$true)][string]$TaskName,
        [string]$TaskRoot
    )
    $workspace = Get-AuthorityWorkspaceRoot
    $roots = if ($TaskRoot) { @($TaskRoot) } else { @(".trae\tasks",".opencode\tasks",".codex\tasks") }
    $relativeName = $TaskName -replace "/", "\"
    if ($relativeName -match "(^|\\)\.\.(\\|$)") { throw "Task name cannot contain '..': $TaskName" }

    foreach ($rootName in $roots) {
        $root = if ([System.IO.Path]::IsPathRooted($rootName)) { $rootName } else { Join-Path $workspace $rootName }
        $candidates = @()
        if ($TaskName -match "^.+?/.+$") {
            $candidates += Join-Path $root $relativeName
        }
        else {
            $candidates += Join-Path $root $relativeName
            foreach ($scope in @("_shared","airpgweb","characterdesigntool","rts","ai-drama")) {
                $candidates += Join-Path $root "$scope\$relativeName"
            }
        }
        foreach ($candidate in $candidates) {
            if ((Test-AuthorityPathWithinRoot $candidate $root) -and (Test-Path -LiteralPath $candidate)) {
                $full = [System.IO.Path]::GetFullPath($candidate)
                return [pscustomobject]@{
                    Dir = $full
                    Yaml = Join-Path $full ".task.yaml"
                    Root = [System.IO.Path]::GetFullPath($root)
                    RootName = $rootName
                    TaskName = $TaskName
                }
            }
        }
    }
    throw "Task not found: $TaskName"
}

function Normalize-AuthorityRelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)
    $value = $Path.Trim() -replace "\\","/"
    while ($value.StartsWith("./", [System.StringComparison]::Ordinal)) {
        $value = $value.Substring(2)
    }
    if (-not $value) { throw "Relative path is empty" }
    if ([System.IO.Path]::IsPathRooted($Path) -or $Path -match "^[\\/]") { throw "Path must be relative: $Path" }
    if ($value -match "(^|/)\.\.(/|$)") { throw "Path cannot contain '..': $Path" }
    if ($value -match "[*?\[\]]") { throw "Path must be exact, not a wildcard: $Path" }
    return $value
}

function Write-AuthorityAtomicText {
    param([string]$Path, [string]$Content)
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $temp = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
    [System.IO.File]::WriteAllText(
        $temp,
        $Content,
        (New-Object System.Text.UTF8Encoding($false))
    )
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Read-AuthorityJson {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "JSON file not found: $Path" }
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Write-AuthorityJson {
    param([string]$Path, [object]$Value)
    Write-AuthorityAtomicText $Path ($Value | ConvertTo-Json -Depth 20)
}

function ConvertTo-AuthorityCanonicalJson {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return "null" }
    if ($Value -is [bool]) { return $(if ($Value) { "true" } else { "false" }) }
    if ($Value -is [string] -or $Value -is [char]) {
        return (ConvertTo-Json -InputObject ([string]$Value) -Compress)
    }
    if ($Value -is [datetime]) {
        return (ConvertTo-Json -InputObject $Value.ToUniversalTime().ToString("o") -Compress)
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $parts = @()
        foreach ($key in @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)) {
            $parts += "$(ConvertTo-AuthorityCanonicalJson $key):$(ConvertTo-AuthorityCanonicalJson $Value[$key])"
        }
        return "{" + ($parts -join ",") + "}"
    }
    if ($Value -is [pscustomobject]) {
        $parts = @()
        foreach ($property in @($Value.PSObject.Properties | Sort-Object Name)) {
            $parts += "$(ConvertTo-AuthorityCanonicalJson $property.Name):$(ConvertTo-AuthorityCanonicalJson $property.Value)"
        }
        return "{" + ($parts -join ",") + "}"
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [byte[]])) {
        $parts = @()
        foreach ($item in $Value) { $parts += ConvertTo-AuthorityCanonicalJson $item }
        return "[" + ($parts -join ",") + "]"
    }
    if ($Value -is [System.IFormattable]) {
        return $Value.ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
    }
    return (ConvertTo-Json -InputObject ([string]$Value) -Compress)
}

function Get-AuthoritySha256Bytes {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return $sha.ComputeHash($Bytes) } finally { $sha.Dispose() }
}

function ConvertTo-AuthorityHex {
    param([byte[]]$Bytes)
    return (($Bytes | ForEach-Object { $_.ToString("x2") }) -join "")
}

function ConvertFrom-AuthorityHex {
    param([string]$Hex)
    if ($Hex.Length % 2 -ne 0) { throw "Invalid hex string length" }
    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i=0; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = [Convert]::ToByte($Hex.Substring($i * 2, 2), 16)
    }
    return $bytes
}

function Get-AuthorityTextDigest {
    param([string]$Text)
    return ConvertTo-AuthorityHex (Get-AuthoritySha256Bytes ([Text.Encoding]::UTF8.GetBytes($Text)))
}

function Get-AuthorityCanonicalDigest {
    param([object]$Value)
    return Get-AuthorityTextDigest (ConvertTo-AuthorityCanonicalJson $Value)
}

function Get-AuthorityFileDigest {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "File not found: $Path" }
    $stream = [System.IO.File]::OpenRead($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ConvertTo-AuthorityHex ($sha.ComputeHash($stream)) }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function Get-AuthorityYamlField {
    param([string]$Path, [string]$Field)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $match = Select-String -LiteralPath $Path -Pattern "^$([regex]::Escape($Field)):" | Select-Object -First 1
    if (-not $match) { return $null }
    $value = ($match.Line -replace "^$([regex]::Escape($Field)):\s*", "").Trim()
    $value = $value -replace '^["'']|["'']$',''
    if ($value -eq "null") { return $null }
    return $value
}

function Set-AuthorityYamlFields {
    param([string]$Path, [hashtable]$Fields)
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    foreach ($field in $Fields.Keys) {
        $value = [string]$Fields[$field]
        $pattern = "(?m)^$([regex]::Escape([string]$field)):.*$"
        if ($content -match $pattern) {
            $content = $content -replace $pattern, "${field}: ${value}"
        }
        else {
            $content = $content.TrimEnd() + "`r`n${field}: ${value}`r`n"
        }
    }
    Write-AuthorityAtomicText $Path ($content.TrimEnd() + "`r`n")
}

function Test-AuthorityKeyExists {
    param([string]$KeyName)
    try {
        $key = [System.Security.Cryptography.CngKey]::Open($KeyName)
        $key.Dispose()
        return $true
    }
    catch { return $false }
}

function Get-AuthorityPublicMetadataFromKey {
    param([string]$KeyName)
    $key = [System.Security.Cryptography.CngKey]::Open($KeyName)
    try {
        $publicBlob = $key.Export([System.Security.Cryptography.CngKeyBlobFormat]::EccPublicBlob)
        $keyId = ConvertTo-AuthorityHex (Get-AuthoritySha256Bytes $publicBlob)
        $privateExportable = $true
        try { $null = $key.Export([System.Security.Cryptography.CngKeyBlobFormat]::EccPrivateBlob) }
        catch { $privateExportable = $false }
        return [ordered]@{
            schema_version = 1
            algorithm = "ECDSA_P256_SHA256"
            key_name = $KeyName
            issuer_key_id = $keyId
            issuer_sid = Get-AuthorityCurrentSid
            public_blob_base64 = [Convert]::ToBase64String($publicBlob)
            private_exportable = $privateExportable
        }
    }
    finally { $key.Dispose() }
}

function New-AuthorityIssuerKey {
    param([string]$KeyName)
    if (-not (Test-AuthorityKeyExists $KeyName)) {
        $parameters = New-Object System.Security.Cryptography.CngKeyCreationParameters
        $parameters.ExportPolicy = [System.Security.Cryptography.CngExportPolicies]::None
        $parameters.KeyUsage = [System.Security.Cryptography.CngKeyUsages]::Signing
        $key = [System.Security.Cryptography.CngKey]::Create(
            [System.Security.Cryptography.CngAlgorithm]::ECDsaP256,
            $KeyName,
            $parameters
        )
        $key.Dispose()
    }
    $metadata = Get-AuthorityPublicMetadataFromKey $KeyName
    if ($metadata.private_exportable) { throw "Issuer private key is exportable; refusing key" }
    return $metadata
}

function Remove-AuthorityIssuerKey {
    param([string]$KeyName)
    if (Test-AuthorityKeyExists $KeyName) {
        $key = [System.Security.Cryptography.CngKey]::Open($KeyName)
        $key.Delete()
    }
}

function Sign-AuthorityDigest {
    param([string]$KeyName, [string]$Digest)
    $key = [System.Security.Cryptography.CngKey]::Open($KeyName)
    try {
        $ecdsa = New-Object System.Security.Cryptography.ECDsaCng($key)
        try { return [Convert]::ToBase64String($ecdsa.SignHash((ConvertFrom-AuthorityHex $Digest))) }
        finally { $ecdsa.Dispose() }
    }
    finally { $key.Dispose() }
}

function Test-AuthorityDigestSignature {
    param([string]$Digest, [string]$SignatureBase64, [string]$PublicBlobBase64)
    try {
        $publicKey = [System.Security.Cryptography.CngKey]::Import(
            [Convert]::FromBase64String($PublicBlobBase64),
            [System.Security.Cryptography.CngKeyBlobFormat]::EccPublicBlob
        )
        try {
            $ecdsa = New-Object System.Security.Cryptography.ECDsaCng($publicKey)
            try {
                return $ecdsa.VerifyHash(
                    (ConvertFrom-AuthorityHex $Digest),
                    [Convert]::FromBase64String($SignatureBase64)
                )
            }
            finally { $ecdsa.Dispose() }
        }
        finally { $publicKey.Dispose() }
    }
    catch { return $false }
}

function New-AuthoritySignatureRecord {
    param([string]$KeyName, [string]$Digest)
    $metadata = Get-AuthorityPublicMetadataFromKey $KeyName
    return [ordered]@{
        schema_version = 1
        algorithm = "ECDSA_P256_SHA256"
        issuer_key_id = $metadata.issuer_key_id
        issuer_sid = Get-AuthorityCurrentSid
        digest = $Digest
        signature_base64 = Sign-AuthorityDigest $KeyName $Digest
    }
}

function Test-AuthoritySignedArtifact {
    param(
        [string]$ArtifactPath,
        [string]$SignaturePath,
        [string]$PublicMetadataPath,
        [string]$DigestField
    )
    $artifact = Read-AuthorityJson $ArtifactPath
    $signature = Read-AuthorityJson $SignaturePath
    $public = Read-AuthorityJson $PublicMetadataPath
    $base = [ordered]@{}
    foreach ($property in $artifact.PSObject.Properties) {
        if ($property.Name -ne $DigestField) { $base[$property.Name] = $property.Value }
    }
    $actualDigest = Get-AuthorityCanonicalDigest $base
    $declaredDigest = [string]$artifact.$DigestField
    if ($actualDigest -ne $declaredDigest) { throw "Artifact digest mismatch: $ArtifactPath" }
    if ($signature.digest -ne $declaredDigest) { throw "Signature digest mismatch: $SignaturePath" }
    if ($signature.issuer_key_id -ne $public.issuer_key_id) { throw "Signature key does not match public metadata" }
    if ($signature.issuer_sid -ne $public.issuer_sid) { throw "Signature SID does not match public metadata" }
    if (-not (Test-AuthorityDigestSignature $declaredDigest $signature.signature_base64 $public.public_blob_base64)) {
        throw "Signature verification failed: $SignaturePath"
    }
    return $artifact
}

function Resolve-AuthorityArtifactPath {
    param([object]$Task, [string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
    $full = Join-Path $Task.Dir ($Path -replace "/", "\")
    if (-not (Test-AuthorityPathWithinRoot $full $Task.Dir)) { throw "Artifact path escapes task: $Path" }
    return [System.IO.Path]::GetFullPath($full)
}

function Get-AuthorityRelativeTaskPath {
    param([object]$Task, [string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetFullPath($Task.Dir).TrimEnd("\") + "\"
    if (-not $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside task directory: $Path"
    }
    return ($full.Substring($root.Length) -replace "\\","/")
}

function Test-AuthorityCapability {
    param([object]$Task, [string]$CapabilityPath)
    $path = Resolve-AuthorityArtifactPath $Task $CapabilityPath
    $artifact = Test-AuthoritySignedArtifact $path "$path.sig.json" (Join-Path $Task.Dir "issuer\public-key.json") "capability_digest"
    $packet = Test-AuthorityPacketSeal $Task
    if ($artifact.packet_digest -ne $packet.packet_digest) { throw "Capability packet digest is stale" }
    if ([datetimeoffset]::Parse($artifact.expires_at) -lt [datetimeoffset]::Now) { throw "Capability expired" }
    $workPackagePath = Join-Path $Task.Dir ($artifact.work_package_path -replace "/", "\")
    if ((Get-AuthorityFileDigest $workPackagePath) -ne $artifact.work_package_digest) { throw "Capability work-package digest is stale" }
    return $artifact
}

function Test-AuthorityReviewApproval {
    param([object]$Task, [string]$ApprovalPath)
    $path = Resolve-AuthorityArtifactPath $Task $ApprovalPath
    $approval = Test-AuthoritySignedArtifact $path "$path.sig.json" (Join-Path $Task.Dir "issuer\public-key.json") "approval_digest"
    $packet = Test-AuthorityPacketSeal $Task
    if ($approval.packet_digest -ne $packet.packet_digest) { throw "Approval packet digest is stale" }
    if ($approval.decision -ne "accepted") { throw "Approval decision is not accepted" }
    if ($approval.execution_mode -eq "worker") {
        $capability = Test-AuthorityCapability $Task $approval.capability_path
        if ($capability.capability_digest -ne $approval.capability_digest) { throw "Approval capability digest is stale" }
        $resultPath = Resolve-AuthorityArtifactPath $Task $approval.result_path
        if ((Get-AuthorityFileDigest $resultPath) -ne $approval.result_digest) { throw "Worker result changed after approval" }
        $workPackagePath = Join-Path $Task.Dir ($approval.work_package_path -replace "/", "\")
        if ((Get-AuthorityFileDigest $workPackagePath) -ne $approval.work_package_digest) { throw "Work package changed after approval" }
    }
    elseif ($approval.execution_mode -ne "issuer_direct") {
        throw "Unsupported approval execution mode: $($approval.execution_mode)"
    }
    $sourceRows = Get-AuthorityPathManifest $Task @($approval.source_paths) $approval.source_root
    if ((Get-AuthorityCanonicalDigest $sourceRows) -ne $approval.source_diff_digest) { throw "Source state changed after approval" }
    $evidenceRows = Get-AuthorityPathManifest $Task @($approval.evidence_paths) "task"
    if ((Get-AuthorityCanonicalDigest $evidenceRows) -ne $approval.evidence_manifest_digest) { throw "Evidence changed after approval" }
    if ((Get-AuthorityAcceptanceDigest $Task) -ne $approval.acceptance_criteria_digest) { throw "Acceptance criteria changed after approval" }
    return $approval
}

function Assert-AuthorityIssuer {
    param([object]$Task, [string]$KeyName)
    $issuerSid = Get-AuthorityYamlField $Task.Yaml "issuer_sid"
    $issuerKeyId = Get-AuthorityYamlField $Task.Yaml "issuer_key_id"
    $currentSid = Get-AuthorityCurrentSid
    if (-not $issuerSid -or $issuerSid -ne $currentSid) {
        throw "Issuer SID mismatch. Required=$issuerSid Current=$currentSid"
    }
    if (-not (Test-AuthorityKeyExists $KeyName)) { throw "Issuer key not available: $KeyName" }
    $metadata = Get-AuthorityPublicMetadataFromKey $KeyName
    if (-not $issuerKeyId -or $metadata.issuer_key_id -ne $issuerKeyId) {
        throw "Issuer key mismatch"
    }
    return $metadata
}

function Get-AuthorityPacketCoreFiles {
    param([object]$Task)
    $required = @("routing.md","analysis.md","spec.md","tasks.md","doc-impact.md")
    $paths = @()
    foreach ($relative in $required) {
        $full = Join-Path $Task.Dir $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Required packet file missing: $relative" }
        $paths += $relative
    }
    $workPackageDir = Join-Path $Task.Dir "work-packages"
    if (Test-Path -LiteralPath $workPackageDir) {
        foreach ($file in Get-ChildItem -LiteralPath $workPackageDir -Filter "*.md" -File | Sort-Object Name) {
            $paths += "work-packages/$($file.Name)"
        }
    }
    return @($paths | Sort-Object -Unique)
}

function Get-AuthorityMarkdownList {
    param([string]$Path, [string]$Section)
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $match = [regex]::Match(
        $content,
        "(?ms)^##\s+$([regex]::Escape($Section))\s*\r?\n(?<body>.*?)(?=^##\s+|\z)"
    )
    if (-not $match.Success) { return @() }
    $items = @()
    foreach ($line in ($match.Groups["body"].Value -split "\r?\n")) {
        if ($line -match "^\s*-\s+(?<item>.+?)\s*$") {
            $value = ($matches["item"].Trim() -replace "^``|``$","")
            if ($value) { $items += Normalize-AuthorityRelativePath $value }
        }
    }
    return @($items)
}

function Get-AuthorityPathManifest {
    param(
        [object]$Task,
        [string[]]$Paths,
        [ValidateSet("workspace","task")][string]$SourceRoot = "workspace"
    )
    $base = if ($SourceRoot -eq "task") { $Task.Dir } else { Get-AuthorityWorkspaceRoot }
    $rows = @()
    foreach ($item in $Paths) {
        $relative = Normalize-AuthorityRelativePath $item
        $full = Join-Path $base ($relative -replace "/", "\")
        if (-not (Test-AuthorityPathWithinRoot $full $base)) { throw "Path escapes source root: $item" }
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Authorized file not found: $relative" }
        $rows += [ordered]@{ path=$relative; sha256=(Get-AuthorityFileDigest $full) }
    }
    return @($rows | Sort-Object { $_.path })
}

function Get-AuthorityAcceptanceDigest {
    param([object]$Task)
    $rows = Get-AuthorityPathManifest $Task @("analysis.md","spec.md") "task"
    return Get-AuthorityCanonicalDigest $rows
}

function Test-AuthorityPacketSeal {
    param([object]$Task)
    $issuerDir = Join-Path $Task.Dir "issuer"
    $manifestPath = Join-Path $issuerDir "packet-manifest.json"
    $signaturePath = Join-Path $issuerDir "packet-manifest.sig.json"
    $publicPath = Join-Path $issuerDir "public-key.json"
    $manifest = Test-AuthoritySignedArtifact $manifestPath $signaturePath $publicPath "packet_digest"
    $currentPaths = @(Get-AuthorityPacketCoreFiles $Task)
    $manifestPaths = @($manifest.core_files | ForEach-Object { $_.path })
    if (($currentPaths -join "`n") -ne ($manifestPaths -join "`n")) { throw "Packet core-file set changed" }
    foreach ($file in $manifest.core_files) {
        $full = Join-Path $Task.Dir ($file.path -replace "/", "\")
        if ((Get-AuthorityFileDigest $full) -ne $file.sha256) { throw "Packet file changed: $($file.path)" }
    }
    $yamlDigest = Get-AuthorityYamlField $Task.Yaml "packet_digest"
    if ($yamlDigest -ne $manifest.packet_digest) { throw "Task packet_digest does not match signed manifest" }
    return $manifest
}

Export-ModuleMember -Function @(
    "Get-AuthorityWorkspaceRoot",
    "Get-AuthorityCurrentSid",
    "Test-AuthorityPathWithinRoot",
    "Resolve-AuthorityTask",
    "Normalize-AuthorityRelativePath",
    "Write-AuthorityAtomicText",
    "Read-AuthorityJson",
    "Write-AuthorityJson",
    "ConvertTo-AuthorityCanonicalJson",
    "Get-AuthorityCanonicalDigest",
    "Get-AuthorityFileDigest",
    "Get-AuthorityYamlField",
    "Set-AuthorityYamlFields",
    "Test-AuthorityKeyExists",
    "Get-AuthorityPublicMetadataFromKey",
    "New-AuthorityIssuerKey",
    "Remove-AuthorityIssuerKey",
    "Sign-AuthorityDigest",
    "Test-AuthorityDigestSignature",
    "New-AuthoritySignatureRecord",
    "Test-AuthoritySignedArtifact",
    "Resolve-AuthorityArtifactPath",
    "Get-AuthorityRelativeTaskPath",
    "Test-AuthorityCapability",
    "Test-AuthorityReviewApproval",
    "Assert-AuthorityIssuer",
    "Get-AuthorityPacketCoreFiles",
    "Get-AuthorityMarkdownList",
    "Get-AuthorityPathManifest",
    "Get-AuthorityAcceptanceDigest",
    "Test-AuthorityPacketSeal"
)
