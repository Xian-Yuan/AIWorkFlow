param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("archive","verify")]
    [string]$Command,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskName,
    [string]$KeyName,
    [string]$Approval,
    [string]$ArchiveCertificate,
    [string]$TaskRoot
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

try {
    $task = Resolve-AuthorityTask $TaskName $TaskRoot
    if ($Command -eq "verify") {
        if (-not $ArchiveCertificate) { throw "ArchiveCertificate is required for verify" }
        $path = Resolve-AuthorityArtifactPath $task $ArchiveCertificate
        $certificate = Test-AuthoritySignedArtifact $path "$path.sig.json" (Join-Path $task.Dir "issuer\public-key.json") "archive_digest"
        $approvalArtifact = Test-AuthorityReviewApproval $task $certificate.review_approval_path
        if ($certificate.review_approval_digest -ne $approvalArtifact.approval_digest) { throw "Archive approval digest is stale" }
        if ((Get-AuthorityYamlField $task.Yaml "archived") -ne "true") { throw "Task is not marked archived" }
        $certificate | ConvertTo-Json -Depth 20
        exit 0
    }

    if (-not $KeyName -or -not $Approval) { throw "KeyName and Approval are required for archive" }
    $metadata = Assert-AuthorityIssuer $task $KeyName
    $approvalArtifact = Test-AuthorityReviewApproval $task $Approval
    $tasksContent = Get-Content -LiteralPath (Join-Path $task.Dir "tasks.md") -Raw -Encoding UTF8
    if ($tasksContent -match "(?m)^\s*-\s+\[\s\]") { throw "tasks.md contains incomplete tasks" }
    $specContent = Get-Content -LiteralPath (Join-Path $task.Dir "spec.md") -Raw -Encoding UTF8
    if ($specContent -match "\*\*Status\*\*:\s*\[(\s|/)\]") { throw "spec.md contains incomplete scenarios" }
    $repairStatus = Get-AuthorityYamlField $task.Yaml "repair_loop_status"
    if ($repairStatus -and $repairStatus -notin @("idle","resolved")) { throw "Repair loop is unresolved: $repairStatus" }
    if ((Get-AuthorityYamlField $task.Yaml "authority_status") -ne "verified") { throw "Task authority status is not verified" }

    $version = [int]$approvalArtifact.packet_version
    $relative = "approvals/archive-v{0:D3}.json" -f $version
    $path = Join-Path $task.Dir ($relative -replace "/", "\")
    if (Test-Path -LiteralPath $path) { throw "Archive certificate already exists" }
    $base = [ordered]@{
        schema_version = 1
        task_name = (Split-Path -Leaf $task.Dir)
        packet_version = $approvalArtifact.packet_version
        packet_digest = $approvalArtifact.packet_digest
        review_approval_path = Get-AuthorityRelativeTaskPath $task (Resolve-AuthorityArtifactPath $task $Approval)
        review_approval_digest = $approvalArtifact.approval_digest
        source_diff_digest = $approvalArtifact.source_diff_digest
        evidence_manifest_digest = $approvalArtifact.evidence_manifest_digest
        acceptance_criteria_digest = $approvalArtifact.acceptance_criteria_digest
        issuer_key_id = $metadata.issuer_key_id
        issuer_sid = $metadata.issuer_sid
        archived_at = [datetimeoffset]::Now.ToString("o")
        decision = "archived"
    }
    $digest = Get-AuthorityCanonicalDigest $base
    $certificate = [ordered]@{}
    foreach ($key in $base.Keys) { $certificate[$key] = $base[$key] }
    $certificate.archive_digest = $digest
    Write-AuthorityJson $path $certificate
    Write-AuthorityJson "$path.sig.json" (New-AuthoritySignatureRecord $KeyName $digest)
    Set-AuthorityYamlFields $task.Yaml ([ordered]@{
        phase = "archive"
        archived = "true"
        authority_status = "archived"
        archive_certificate = $relative
        verified_at = (Get-Date -Format "yyyy-MM-dd")
    })
    $certificate | ConvertTo-Json -Depth 20
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
