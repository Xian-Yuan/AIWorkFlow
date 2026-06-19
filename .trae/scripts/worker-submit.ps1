param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("progress","result")]
    [string]$Command,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskName,
    [Parameter(Mandatory=$true)]
    [string]$Capability,
    [Parameter(Mandatory=$true)]
    [string]$PayloadPath,
    [string]$TaskRoot
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

function Test-ForbiddenAuthorityClaims {
    param([object]$Payload)
    $forbidden = @(
        "review_result","verify_result","verification_result","archived","phase",
        "authority_status","approval","decision","packet_digest","issuer_key_id",
        "archive","review_pass","verify_pass"
    )
    function Test-Node {
        param([AllowNull()][object]$Node)
        if ($null -eq $Node -or $Node -is [string] -or $Node -is [ValueType]) { return }
        if ($Node -is [System.Collections.IDictionary]) {
            foreach ($key in $Node.Keys) {
                if ([string]$key -and ([string]$key).ToLowerInvariant() -in $forbidden) {
                    throw "Worker payload contains forbidden authority field: $key"
                }
                Test-Node $Node[$key]
            }
            return
        }
        if ($Node -is [System.Collections.IEnumerable]) {
            foreach ($item in $Node) { Test-Node $item }
            return
        }
        foreach ($property in $Node.PSObject.Properties) {
            if ($property.Name.ToLowerInvariant() -in $forbidden) {
                throw "Worker payload contains forbidden authority field: $($property.Name)"
            }
            Test-Node $property.Value
        }
    }
    Test-Node $Payload
}

try {
    $task = Resolve-AuthorityTask $TaskName $TaskRoot
    $capabilityPath = if ([System.IO.Path]::IsPathRooted($Capability)) { $Capability } else { Join-Path $task.Dir ($Capability -replace "/", "\") }
    $capabilityArtifact = Test-AuthoritySignedArtifact $capabilityPath "$capabilityPath.sig.json" (Join-Path $task.Dir "issuer\public-key.json") "capability_digest"
    $packet = Test-AuthorityPacketSeal $task
    if ($capabilityArtifact.packet_digest -ne $packet.packet_digest) { throw "Capability packet digest is stale" }
    if ($capabilityArtifact.worker_sid -ne (Get-AuthorityCurrentSid)) { throw "Worker SID does not match capability" }
    if ([datetimeoffset]::Parse($capabilityArtifact.expires_at) -lt [datetimeoffset]::Now) { throw "Capability expired" }

    $payload = Read-AuthorityJson $PayloadPath
    Test-ForbiddenAuthorityClaims $payload
    $allowedStatuses = @("working","partial","blocked","implementation_done")
    if ($payload.status -notin $allowedStatuses) { throw "Unsupported worker status: $($payload.status)" }
    if (-not $payload.context_id) { throw "Worker payload requires context_id" }

    if ($Command -eq "progress") {
        if (-not $payload.event_id -or $payload.event_id -notmatch "^[A-Za-z0-9._-]+$") { throw "Progress payload requires a safe event_id" }
        $directory = Join-Path $task.Dir ($capabilityArtifact.progress_directory -replace "/", "\")
        $target = Join-Path $directory "$($payload.event_id).json"
        if (Test-Path -LiteralPath $target) { throw "Progress event already exists: $($payload.event_id)" }
        Write-AuthorityJson $target $payload
        Write-Host "Progress appended: $target"
        exit 0
    }

    if ($payload.status -notin @("partial","blocked","implementation_done")) {
        throw "Result status must be partial, blocked, or implementation_done"
    }
    if ($null -eq $payload.extra_scope_taken -or [bool]$payload.extra_scope_taken) {
        throw "Result must declare extra_scope_taken=false"
    }
    foreach ($changedFile in @($payload.changed_files)) {
        $normalized = Normalize-AuthorityRelativePath ([string]$changedFile)
        if ($normalized -notin @($capabilityArtifact.allowed_paths)) {
            throw "Worker changed file is outside capability: $normalized"
        }
    }
    $target = Join-Path $task.Dir ($capabilityArtifact.result_path -replace "/", "\")
    if (Test-Path -LiteralPath $target) { throw "Worker result already exists" }
    Write-AuthorityJson $target $payload
    Write-Host "Worker result created: $target"
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
