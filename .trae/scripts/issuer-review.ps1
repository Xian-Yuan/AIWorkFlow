param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("approve","reject","verify")]
    [string]$Command,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskName,
    [string]$KeyName,
    [switch]$Direct,
    [string]$Capability,
    [string]$Result,
    [string]$ReviewContextId,
    [string[]]$SourcePaths,
    [ValidateSet("workspace","task")]
    [string]$SourceRoot = "workspace",
    [string[]]$EvidencePaths,
    [string]$Approval,
    [string]$Summary,
    [string]$RootCauseId,
    [string]$FailedCommand,
    [string]$Expected,
    [string]$Actual,
    [string[]]$AllowedPaths,
    [string[]]$ReadFirst,
    [string]$Actor,
    [string]$Model,
    [string]$TaskRoot
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

try {
    $task = Resolve-AuthorityTask $TaskName $TaskRoot
    if ($Command -eq "verify") {
        if (-not $Approval) { throw "Approval is required for verify" }
        Test-AuthorityReviewApproval $task $Approval | ConvertTo-Json -Depth 20
        exit 0
    }

    foreach ($required in @("KeyName","ReviewContextId")) {
        if (-not (Get-Variable -Name $required -ValueOnly)) { throw "$required is required" }
    }
    $metadata = Assert-AuthorityIssuer $task $KeyName
    $packet = Test-AuthorityPacketSeal $task
    $capabilityArtifact = $null
    $resultPath = $null
    $resultArtifact = $null
    $executionMode = if ($Direct) { "issuer_direct" } else { "worker" }
    if ($Direct) {
        if ($Command -ne "approve") { throw "Issuer-direct mode supports approve only" }
    }
    else {
        foreach ($required in @("Capability","Result")) {
            if (-not (Get-Variable -Name $required -ValueOnly)) { throw "$required is required for worker review" }
        }
        $capabilityArtifact = Test-AuthorityCapability $task $Capability
        $resultPath = Resolve-AuthorityArtifactPath $task $Result
        $expectedResultPath = Resolve-AuthorityArtifactPath $task $capabilityArtifact.result_path
        if ($resultPath -ne $expectedResultPath) { throw "Result path does not match capability" }
        $resultArtifact = Read-AuthorityJson $resultPath
        if ($ReviewContextId -eq $resultArtifact.context_id) { throw "Issuer review context must differ from worker context" }
        if ($Command -eq "approve" -and $resultArtifact.status -ne "implementation_done") {
            throw "Only implementation_done results can be approved"
        }
    }

    $normalizedSource = @($SourcePaths | ForEach-Object { $_ -split ";" } | Where-Object { $_ } | ForEach-Object { Normalize-AuthorityRelativePath $_ } | Sort-Object -Unique)
    $normalizedEvidence = @($EvidencePaths | ForEach-Object { $_ -split ";" } | Where-Object { $_ } | ForEach-Object { Normalize-AuthorityRelativePath $_ } | Sort-Object -Unique)
    if ($normalizedSource.Count -eq 0) { throw "SourcePaths is required" }
    if ($normalizedEvidence.Count -eq 0) { throw "EvidencePaths is required" }
    if (-not $Direct) {
        foreach ($path in $normalizedSource) {
            if ($path -notin @($capabilityArtifact.allowed_paths)) { throw "Source path is outside capability: $path" }
        }
    }

    $effectiveSourceRoot = if ($Direct) { $SourceRoot } else { $capabilityArtifact.source_root }
    $sourceRows = Get-AuthorityPathManifest $task $normalizedSource $effectiveSourceRoot
    $evidenceRows = Get-AuthorityPathManifest $task $normalizedEvidence "task"
    $decision = if ($Command -eq "approve") { "accepted" } else { "rejected" }
    $version = [int]$packet.packet_version
    $relative = "approvals/review-v{0:D3}.json" -f $version
    $approvalPath = Join-Path $task.Dir ($relative -replace "/", "\")
    if (Test-Path -LiteralPath $approvalPath) { throw "Review approval already exists for packet version $version" }
    $base = [ordered]@{
        schema_version = 1
        task_name = (Split-Path -Leaf $task.Dir)
        packet_version = $packet.packet_version
        packet_digest = $packet.packet_digest
        execution_mode = $executionMode
        work_package_path = $(if ($Direct) { $null } else { $capabilityArtifact.work_package_path })
        work_package_digest = $(if ($Direct) { $null } else { $capabilityArtifact.work_package_digest })
        capability_path = $(if ($Direct) { $null } else { Get-AuthorityRelativeTaskPath $task (Resolve-AuthorityArtifactPath $task $Capability) })
        capability_digest = $(if ($Direct) { $null } else { $capabilityArtifact.capability_digest })
        result_path = $(if ($Direct) { $null } else { Get-AuthorityRelativeTaskPath $task $resultPath })
        result_digest = $(if ($Direct) { $null } else { Get-AuthorityFileDigest $resultPath })
        source_root = $effectiveSourceRoot
        source_paths = $normalizedSource
        source_diff_digest = Get-AuthorityCanonicalDigest $sourceRows
        evidence_paths = $normalizedEvidence
        evidence_manifest_digest = Get-AuthorityCanonicalDigest $evidenceRows
        acceptance_criteria_digest = Get-AuthorityAcceptanceDigest $task
        issuer_key_id = $metadata.issuer_key_id
        issuer_sid = $metadata.issuer_sid
        review_context_id = $ReviewContextId
        worker_context_id = $(if ($Direct) { $null } else { $resultArtifact.context_id })
        reviewed_at = [datetimeoffset]::Now.ToString("o")
        decision = $decision
        summary = $(if ($Summary) { $Summary } else { $decision })
        root_cause_id = $(if ($RootCauseId) { $RootCauseId } else { $null })
    }
    $digest = Get-AuthorityCanonicalDigest $base
    $artifact = [ordered]@{}
    foreach ($key in $base.Keys) { $artifact[$key] = $base[$key] }
    $artifact.approval_digest = $digest
    Write-AuthorityJson $approvalPath $artifact
    Write-AuthorityJson "$approvalPath.sig.json" (New-AuthoritySignatureRecord $KeyName $digest)

    if ($decision -eq "accepted") {
        Set-AuthorityYamlFields $task.Yaml ([ordered]@{
            phase = "verify"
            review_result = "pass"
            verify_result = "pass"
            verification_report = $relative
            authority_status = "verified"
        })
    }
    else {
        foreach ($required in @("Summary","RootCauseId","FailedCommand","Expected","Actual")) {
            if (-not (Get-Variable -Name $required -ValueOnly)) { throw "$required is required for reject" }
        }
        if (-not $AllowedPaths -or -not $ReadFirst) { throw "AllowedPaths and ReadFirst are required for reject" }
        & (Join-Path $PSScriptRoot "worker-repair-loop.ps1") record-failure $TaskName `
            -Stage review `
            -RootCauseId $RootCauseId `
            -Summary $Summary `
            -FailedCommand $FailedCommand `
            -Expected $Expected `
            -Actual $Actual `
            -AllowedPaths $AllowedPaths `
            -ReadFirst $ReadFirst `
            -Verifier "Issuer" `
            -KeyName $KeyName
        if ($LASTEXITCODE -ne 0) { throw "Issuer repair publication failed" }
        Set-AuthorityYamlFields $task.Yaml ([ordered]@{
            review_result = "fail"
            verify_result = "fail"
            authority_status = "repair_issued"
        })
    }
    $artifact | ConvertTo-Json -Depth 20
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
