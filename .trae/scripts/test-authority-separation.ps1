param()

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$PowerShellExe = Join-Path $PSHOME "powershell.exe"
$Results = @()
$Failed = $false
$Created = @()
$KeyNames = @()

$Tools = [ordered]@{
    Identity = Join-Path $PSScriptRoot "issuer-identity.ps1"
    Seal = Join-Path $PSScriptRoot "task-packet-seal.ps1"
    Capability = Join-Path $PSScriptRoot "worker-capability.ps1"
    Submit = Join-Path $PSScriptRoot "worker-submit.ps1"
    Sandbox = Join-Path $PSScriptRoot "worker-sandbox.ps1"
    Review = Join-Path $PSScriptRoot "issuer-review.ps1"
    Archive = Join-Path $PSScriptRoot "issuer-archive.ps1"
    Migrate = Join-Path $PSScriptRoot "migrate-task-authority.ps1"
    Repair = Join-Path $PSScriptRoot "worker-repair-loop.ps1"
    State = Join-Path $PSScriptRoot "task-state.ps1"
    Guard = Join-Path $PSScriptRoot "task-guard.ps1"
}

function Add-Result {
    param([string]$Scenario, [string]$Name, [bool]$Passed, [string]$Actual)
    if ($Passed) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $Name - $Actual" -ForegroundColor Red
        $script:Failed = $true
    }
    $script:Results += [pscustomobject]@{
        Scenario = $Scenario
        Name = $Name
        Result = if ($Passed) { "PASS" } else { "FAIL" }
        Actual = $Actual
    }
}

function Invoke-Tool {
    param([string]$Path, [string[]]$Arguments)
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ ExitCode=127; Output="missing tool: $Path" }
    }
    $output = & $PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments 2>&1 | Out-String
    return [pscustomobject]@{ ExitCode=$LASTEXITCODE; Output=$output.Trim() }
}

function Remove-PathSafe {
    param([string]$Path)
    if ($Path -and (Test-Path -LiteralPath $Path)) {
        $full = [System.IO.Path]::GetFullPath($Path)
        $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd("\") + "\"
        if (-not $full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove outside workspace: $full"
        }
        Remove-Item -LiteralPath $full -Recurse -Force
    }
}

function Set-TestSid {
    param([string]$Sid)
    $env:JINLI_AUTH_TEST_MODE = "1"
    $env:JINLI_AUTH_TEST_SID = $Sid
}

function New-AuthorityFixture {
    param(
        [string]$Name,
        [string]$RootName = ".trae\tasks",
        [bool]$Contradictory = $false,
        [string]$AuthorityProfile = "issuer-worker-v1"
    )
    $dir = Join-Path $Root "$RootName\_shared\$Name"
    Remove-PathSafe $dir
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir "work-packages") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir "src") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir "evidence") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $dir ".hidden") -Force | Out-Null
    $script:Created += $dir

    $phase = if ($Contradictory) { "plan" } else { "implement" }
    $archived = if ($Contradictory) { "true" } else { "false" }
    Set-Content -LiteralPath (Join-Path $dir ".task.yaml") -Encoding UTF8 -Value @"
task_name: $Name
workflow: full
phase: $phase
project_type: other
implement_mode: subagent
isolation: branch
clarification_status: answered
user_confirmed_plan: true
router_skill_loaded: true
review_result: pending
verify_result: pending
verification_report: null
archived: $archived
base_ref: null
fix_attempts: 0
worker_profile: ds4-flash
lead_verifier: codex
repair_loop_status: idle
active_root_cause: null
active_repair_package: null
authority_profile: $AuthorityProfile
authority_status: draft
issuer_key_id: null
issuer_sid: null
packet_version: 0
packet_digest: null
legacy_trust: not_applicable
"@
    Set-Content -LiteralPath (Join-Path $dir "routing.md") -Encoding UTF8 -Value "# Routing`n`n## Authority Policy`n- Issuer only"
    Set-Content -LiteralPath (Join-Path $dir "analysis.md") -Encoding UTF8 -Value "# Analysis`n`n## Acceptance Criteria`n- AC01: authority enforced"
    Set-Content -LiteralPath (Join-Path $dir "spec.md") -Encoding UTF8 -Value "# Spec`n`n### S01`n**Status**: [x]"
    Set-Content -LiteralPath (Join-Path $dir "tasks.md") -Encoding UTF8 -Value "- [x] Implement fixture`n- [x] Run automated verification and record command output in verification-report.md.`n- [x] Map implementation result to Acceptance Criteria in verification-report.md."
    Set-Content -LiteralPath (Join-Path $dir "doc-impact.md") -Encoding UTF8 -Value "## Project Document Scope`n- Project: _shared`n- System: fixture`n- Owner: test`n`n## No Code Changes`nReason: fixture"
    Set-Content -LiteralPath (Join-Path $dir "work-packages\WP01-fixture.md") -Encoding UTF8 -Value @"
# WP01: Fixture

Owner model: deepseek-v4-flash
Status: unclaimed
Target model: deepseek-v4-flash
Fresh context required: yes

## Allowed Paths
- src/a.ps1

## Read First
- spec.md

## Required Verification
- Command: fixture-command
- Expected: pass

## Return Report
- Path: reports/WP01-A001/result.json
"@
    Set-Content -LiteralPath (Join-Path $dir "src\a.ps1") -Encoding UTF8 -Value "'v1'"
    Set-Content -LiteralPath (Join-Path $dir "evidence\test.log") -Encoding UTF8 -Value "fixture pass"
    Set-Content -LiteralPath (Join-Path $dir ".hidden\fixture.txt") -Encoding UTF8 -Value "hidden fixture"
    return $dir
}

function Read-Field {
    param([string]$Path, [string]$Field)
    $match = Select-String -LiteralPath $Path -Pattern "^$([regex]::Escape($Field)):" | Select-Object -First 1
    if (-not $match) { return $null }
    return ($match.Line -replace "^$([regex]::Escape($Field)):\s*", "").Trim()
}

function Write-Payload {
    param([string]$Path, [hashtable]$Data)
    $Data | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}

$IssuerSid = "S-1-5-21-1000-1000-1000-1001"
$WorkerSid = "S-1-5-21-2000-2000-2000-2002"
$TaskName = "__authority_main"
$TaskRef = "_shared/$TaskName"
$TaskDir = $null
$KeyName = "JinliAuthorityTest-$([guid]::NewGuid().ToString('N'))"
$WrongKeyName = "JinliAuthorityWrong-$([guid]::NewGuid().ToString('N'))"
$KeyNames += $KeyName
$KeyNames += $WrongKeyName

Push-Location $Root
try {
    $missing = @($Tools.GetEnumerator() | Where-Object { -not (Test-Path -LiteralPath $_.Value) })
    Add-Result "S00" "authority-tools-exist" ($missing.Count -eq 0) (($missing | ForEach-Object { $_.Key }) -join ",")

    $TaskDir = New-AuthorityFixture -Name $TaskName
    Set-TestSid $IssuerSid

    $identityPath = Join-Path $TaskDir "issuer\public-key.json"
    $identity = Invoke-Tool $Tools.Identity @("init","-KeyName",$KeyName,"-OutputPath",$identityPath)
    $identityJson = if (Test-Path -LiteralPath $identityPath) { Get-Content -LiteralPath $identityPath -Raw | ConvertFrom-Json } else { $null }
    Add-Result "S01" "non-exportable-issuer-key-created" (($identity.ExitCode -eq 0) -and $identityJson -and $identityJson.issuer_sid -eq $IssuerSid -and $identityJson.private_exportable -eq $false) "exit=$($identity.ExitCode) output=$($identity.Output)"

    $seal = Invoke-Tool $Tools.Seal @("seal",$TaskRef,"-KeyName",$KeyName)
    $verifySeal = Invoke-Tool $Tools.Seal @("verify",$TaskRef)
    $packetVersion = Read-Field (Join-Path $TaskDir ".task.yaml") "packet_version"
    Add-Result "S02" "packet-seal-signs-core-files" (($seal.ExitCode -eq 0) -and ($verifySeal.ExitCode -eq 0) -and $packetVersion -eq "1") "seal=$($seal.ExitCode) verify=$($verifySeal.ExitCode) version=$packetVersion"

    $sameSid = Invoke-Tool $Tools.Capability @("issue",$TaskRef,"-KeyName",$KeyName,"-WorkPackage","work-packages/WP01-fixture.md","-AttemptId","A000","-WorkerSid",$IssuerSid,"-AllowedPaths","src/a.ps1","-SourceRoot","task")
    Add-Result "S03" "same-sid-strong-mode-capability-blocks" ($sameSid.ExitCode -ne 0) "exit=$($sameSid.ExitCode)"

    $broaderCapability = Invoke-Tool $Tools.Capability @("issue",$TaskRef,"-KeyName",$KeyName,"-WorkPackage","work-packages/WP01-fixture.md","-AttemptId","A099","-WorkerSid",$WorkerSid,"-AllowedPaths","src/outside.ps1","-SourceRoot","task")
    Add-Result "S03B" "capability-cannot-exceed-work-package-allowed-paths" ($broaderCapability.ExitCode -ne 0) "exit=$($broaderCapability.ExitCode)"

    $capability = Invoke-Tool $Tools.Capability @("issue",$TaskRef,"-KeyName",$KeyName,"-WorkPackage","work-packages/WP01-fixture.md","-AttemptId","A001","-WorkerSid",$WorkerSid,"-AllowedPaths","src/a.ps1","-SourceRoot","task")
    $capabilityPath = Join-Path $TaskDir "capabilities\WP01-A001.capability.json"
    Add-Result "S04" "signed-worker-capability-issued" (($capability.ExitCode -eq 0) -and (Test-Path -LiteralPath $capabilityPath)) "exit=$($capability.ExitCode)"

    $sandbox = Invoke-Tool $Tools.Sandbox @("protect",$TaskRef,"-Capability",$capabilityPath,"-KeyName",$KeyName)
    $taskAcl = Get-Acl -LiteralPath (Join-Path $TaskDir ".task.yaml")
    $denyRule = @($taskAcl.Access | Where-Object {
        $_.IdentityReference.Value -eq $WorkerSid -and
        $_.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny
    })
    Add-Result "S04B" "worker-task-core-write-denied-by-acl" (($sandbox.ExitCode -eq 0) -and ($denyRule.Count -gt 0)) "exit=$($sandbox.ExitCode) denyRules=$($denyRule.Count)"

    Set-TestSid $WorkerSid
    $progressPayload = Join-Path $TaskDir ".test-progress.json"
    Write-Payload $progressPayload @{
        event_id = "EVT001"
        status = "working"
        context_id = "worker-context-001"
        message = "fixture progress"
    }
    $progressOne = Invoke-Tool $Tools.Submit @("progress",$TaskRef,"-Capability",$capabilityPath,"-PayloadPath",$progressPayload)
    $progressTwo = Invoke-Tool $Tools.Submit @("progress",$TaskRef,"-Capability",$capabilityPath,"-PayloadPath",$progressPayload)
    Add-Result "S05" "worker-progress-is-append-only" (($progressOne.ExitCode -eq 0) -and ($progressTwo.ExitCode -ne 0)) "first=$($progressOne.ExitCode) duplicate=$($progressTwo.ExitCode)"

    $authorityPayload = Join-Path $TaskDir ".test-authority-claim.json"
    Write-Payload $authorityPayload @{
        status = "implementation_done"
        context_id = "worker-context-001"
        review_result = "pass"
    }
    $authorityClaim = Invoke-Tool $Tools.Submit @("result",$TaskRef,"-Capability",$capabilityPath,"-PayloadPath",$authorityPayload)
    Add-Result "S06" "worker-acceptance-claim-blocks" ($authorityClaim.ExitCode -ne 0) "exit=$($authorityClaim.ExitCode)"

    $extraScopePayload = Join-Path $TaskDir ".test-extra-scope.json"
    Write-Payload $extraScopePayload @{
        status = "implementation_done"
        context_id = "worker-context-001"
        changed_files = @("src/outside.ps1")
        commands = @(@{ command="fixture-command"; result="pass" })
        extra_scope_taken = $false
    }
    $extraScope = Invoke-Tool $Tools.Submit @("result",$TaskRef,"-Capability",$capabilityPath,"-PayloadPath",$extraScopePayload)
    Add-Result "S06B" "worker-result-changed-files-must-stay-in-capability" ($extraScope.ExitCode -ne 0) "exit=$($extraScope.ExitCode)"

    $nestedAuthorityPayload = Join-Path $TaskDir ".test-nested-authority.json"
    Write-Payload $nestedAuthorityPayload @{
        status = "implementation_done"
        context_id = "worker-context-001"
        changed_files = @("src/a.ps1")
        metadata = @{ verify_result = "pass" }
        extra_scope_taken = $false
    }
    $nestedAuthority = Invoke-Tool $Tools.Submit @("result",$TaskRef,"-Capability",$capabilityPath,"-PayloadPath",$nestedAuthorityPayload)
    Add-Result "S06C" "nested-worker-authority-claim-blocks" ($nestedAuthority.ExitCode -ne 0) "exit=$($nestedAuthority.ExitCode)"

    $resultPayload = Join-Path $TaskDir ".test-result.json"
    Write-Payload $resultPayload @{
        status = "implementation_done"
        context_id = "worker-context-001"
        changed_files = @("src/a.ps1")
        commands = @(@{ command="fixture-command"; result="pass" })
        extra_scope_taken = $false
    }
    $resultOne = Invoke-Tool $Tools.Submit @("result",$TaskRef,"-Capability",$capabilityPath,"-PayloadPath",$resultPayload)
    $resultTwo = Invoke-Tool $Tools.Submit @("result",$TaskRef,"-Capability",$capabilityPath,"-PayloadPath",$resultPayload)
    $resultPath = Join-Path $TaskDir "reports\WP01-A001\result.json"
    Add-Result "S07" "worker-result-is-single-create" (($resultOne.ExitCode -eq 0) -and ($resultTwo.ExitCode -ne 0) -and (Test-Path -LiteralPath $resultPath)) "first=$($resultOne.ExitCode) duplicate=$($resultTwo.ExitCode)"

    $spoofState = Invoke-Tool $Tools.State @("set",$TaskRef,"review_result","pass")
    Add-Result "S08" "generic-state-acceptance-mutation-blocks" ($spoofState.ExitCode -ne 0) "exit=$($spoofState.ExitCode)"

    $spoofDigest = Invoke-Tool $Tools.State @("set",$TaskRef,"packet_digest","forged")
    Add-Result "S08B" "generic-state-authority-metadata-mutation-blocks" ($spoofDigest.ExitCode -ne 0) "exit=$($spoofDigest.ExitCode)"

    $spoofReview = Invoke-Tool $Tools.Review @("approve",$TaskRef,"-KeyName",$KeyName,"-Capability",$capabilityPath,"-Result",$resultPath,"-ReviewContextId","worker-context-002","-SourcePaths","src/a.ps1","-EvidencePaths","evidence/test.log","-Actor","issuer","-Model","codex")
    Add-Result "S09" "role-and-model-spoofing-do-not-grant-authority" ($spoofReview.ExitCode -ne 0) "exit=$($spoofReview.ExitCode)"

    $mutatedSpec = Join-Path $TaskDir "spec.md"
    Add-Content -LiteralPath $mutatedSpec -Value "`npacket mutation"
    $staleCapability = Invoke-Tool $Tools.Capability @("verify",$TaskRef,"-Capability",$capabilityPath)
    Add-Result "S10" "packet-mutation-invalidates-capability" ($staleCapability.ExitCode -ne 0) "exit=$($staleCapability.ExitCode)"

    Set-TestSid $IssuerSid
    $reseal = Invoke-Tool $Tools.Seal @("seal",$TaskRef,"-KeyName",$KeyName)
    $versionOneManifest = Join-Path $TaskDir "issuer\packet-manifest-v001.json"
    $versionTwoManifest = Join-Path $TaskDir "issuer\packet-manifest-v002.json"
    Add-Result "S10B" "packet-reseal-preserves-version-history" (($reseal.ExitCode -eq 0) -and (Test-Path -LiteralPath $versionOneManifest) -and (Test-Path -LiteralPath $versionTwoManifest)) "exit=$($reseal.ExitCode) v1=$(Test-Path -LiteralPath $versionOneManifest) v2=$(Test-Path -LiteralPath $versionTwoManifest)"
    $capabilityTwo = Invoke-Tool $Tools.Capability @("issue",$TaskRef,"-KeyName",$KeyName,"-WorkPackage","work-packages/WP01-fixture.md","-AttemptId","A002","-WorkerSid",$WorkerSid,"-AllowedPaths","src/a.ps1","-SourceRoot","task")
    $capabilityTwoPath = Join-Path $TaskDir "capabilities\WP01-A002.capability.json"
    Set-TestSid $WorkerSid
    $resultPayloadTwo = Join-Path $TaskDir ".test-result-two.json"
    Write-Payload $resultPayloadTwo @{
        status = "implementation_done"
        context_id = "worker-context-002"
        changed_files = @("src/a.ps1")
        commands = @(@{ command="fixture-command"; result="pass" })
        extra_scope_taken = $false
    }
    $resultSubmitTwo = Invoke-Tool $Tools.Submit @("result",$TaskRef,"-Capability",$capabilityTwoPath,"-PayloadPath",$resultPayloadTwo)
    $resultTwoPath = Join-Path $TaskDir "reports\WP01-A002\result.json"

    Set-TestSid $IssuerSid
    $wrongIdentityPath = Join-Path $TaskDir ".wrong-public-key.json"
    $null = Invoke-Tool $Tools.Identity @("init","-KeyName",$WrongKeyName,"-OutputPath",$wrongIdentityPath)
    $wrongKeyReview = Invoke-Tool $Tools.Review @("approve",$TaskRef,"-KeyName",$WrongKeyName,"-Capability",$capabilityTwoPath,"-Result",$resultTwoPath,"-ReviewContextId","review-context-wrong","-SourcePaths","src/a.ps1","-EvidencePaths","evidence/test.log")
    Add-Result "S11" "non-issuer-key-cannot-approve" ($wrongKeyReview.ExitCode -ne 0) "exit=$($wrongKeyReview.ExitCode)"

    $review = Invoke-Tool $Tools.Review @("approve",$TaskRef,"-KeyName",$KeyName,"-Capability",$capabilityTwoPath,"-Result",$resultTwoPath,"-ReviewContextId","review-context-001","-SourcePaths","src/a.ps1","-EvidencePaths","evidence/test.log")
    $approvalPath = Join-Path $TaskDir "approvals\review-v002.json"
    Add-Result "S12" "issuer-signs-bound-review-approval" (($review.ExitCode -eq 0) -and (Test-Path -LiteralPath $approvalPath)) "exit=$($review.ExitCode) output=$($review.Output)"

    $verifyApply = Invoke-Tool $Tools.Guard @($TaskRef,"verify","-Apply")
    $archivedAfterVerify = Read-Field (Join-Path $TaskDir ".task.yaml") "archived"
    Add-Result "S13" "verify-does-not-auto-archive" (($verifyApply.ExitCode -eq 0) -and $archivedAfterVerify -eq "false") "exit=$($verifyApply.ExitCode) archived=$archivedAfterVerify"

    Set-Content -LiteralPath (Join-Path $TaskDir "src\a.ps1") -Encoding UTF8 -Value "'tampered'"
    $tamperedArchive = Invoke-Tool $Tools.Archive @("archive",$TaskRef,"-KeyName",$KeyName,"-Approval",$approvalPath)
    Add-Result "S14" "source-mutation-invalidates-approval" ($tamperedArchive.ExitCode -ne 0) "exit=$($tamperedArchive.ExitCode)"

    Set-Content -LiteralPath (Join-Path $TaskDir "src\a.ps1") -Encoding UTF8 -Value "'v1'"
    $archive = Invoke-Tool $Tools.Archive @("archive",$TaskRef,"-KeyName",$KeyName,"-Approval",$approvalPath)
    $archived = Read-Field (Join-Path $TaskDir ".task.yaml") "archived"
    Add-Result "S15" "only-explicit-issuer-archive-completes-task" (($archive.ExitCode -eq 0) -and $archived -eq "true") "exit=$($archive.ExitCode) archived=$archived"

    $repairFixture = New-AuthorityFixture -Name "__authority_repair"
    Set-TestSid $IssuerSid
    $repairIdentity = Join-Path $repairFixture "issuer\public-key.json"
    $null = Invoke-Tool $Tools.Identity @("init","-KeyName",$KeyName,"-OutputPath",$repairIdentity)
    $null = Invoke-Tool $Tools.Seal @("seal","_shared/__authority_repair","-KeyName",$KeyName)
    Set-TestSid $WorkerSid
    $workerRepair = Invoke-Tool $Tools.Repair @("record-failure","_shared/__authority_repair","-Stage","review","-RootCauseId","RC01","-Summary","fixture","-FailedCommand","fixture-command","-Expected","pass","-Actual","fail","-AllowedPaths","src/a.ps1","-ReadFirst","spec.md","-KeyName",$KeyName)
    Add-Result "S16" "worker-cannot-publish-repair-package" ($workerRepair.ExitCode -ne 0) "exit=$($workerRepair.ExitCode)"

    $rejectFixture = New-AuthorityFixture -Name "__authority_reject"
    Set-TestSid $IssuerSid
    $null = Invoke-Tool $Tools.Identity @("init","-KeyName",$KeyName,"-OutputPath",(Join-Path $rejectFixture "issuer\public-key.json"))
    $null = Invoke-Tool $Tools.Seal @("seal","_shared/__authority_reject","-KeyName",$KeyName)
    $null = Invoke-Tool $Tools.Capability @("issue","_shared/__authority_reject","-KeyName",$KeyName,"-WorkPackage","work-packages/WP01-fixture.md","-AttemptId","A001","-WorkerSid",$WorkerSid,"-AllowedPaths","src/a.ps1","-SourceRoot","task")
    $rejectCapability = Join-Path $rejectFixture "capabilities\WP01-A001.capability.json"
    $rejectPayload = Join-Path $rejectFixture ".test-reject-result.json"
    Write-Payload $rejectPayload @{
        status = "partial"
        context_id = "worker-reject-context"
        changed_files = @("src/a.ps1")
        commands = @(@{ command="fixture-command"; result="fail" })
        extra_scope_taken = $false
    }
    Set-TestSid $WorkerSid
    $null = Invoke-Tool $Tools.Submit @("result","_shared/__authority_reject","-Capability",$rejectCapability,"-PayloadPath",$rejectPayload)
    $rejectResult = Join-Path $rejectFixture "reports\WP01-A001\result.json"
    Set-TestSid $IssuerSid
    $issuerReject = Invoke-Tool $Tools.Review @(
        "reject","_shared/__authority_reject",
        "-KeyName",$KeyName,
        "-Capability",$rejectCapability,
        "-Result",$rejectResult,
        "-ReviewContextId","review-reject-context",
        "-SourcePaths","src/a.ps1",
        "-EvidencePaths","evidence/test.log",
        "-Summary","fixture failure",
        "-RootCauseId","RC01",
        "-FailedCommand","fixture-command",
        "-Expected","pass",
        "-Actual","fail",
        "-AllowedPaths","src/a.ps1",
        "-ReadFirst","spec.md"
    )
    $repairPackages = @(Get-ChildItem -LiteralPath (Join-Path $rejectFixture "work-packages") -Filter "WP*-fix-rc01-a1.md" -File -ErrorAction SilentlyContinue)
    $rejectPacketVersion = Read-Field (Join-Path $rejectFixture ".task.yaml") "packet_version"
    Add-Result "S16B" "issuer-rejection-publishes-and-reseals-repair-package" (($issuerReject.ExitCode -eq 0) -and ($repairPackages.Count -eq 1) -and $rejectPacketVersion -eq "2") "exit=$($issuerReject.ExitCode) packages=$($repairPackages.Count) packet=$rejectPacketVersion"

    $directFixture = New-AuthorityFixture -Name "__authority_direct"
    Set-TestSid $IssuerSid
    $null = Invoke-Tool $Tools.Identity @("init","-KeyName",$KeyName,"-OutputPath",(Join-Path $directFixture "issuer\public-key.json"))
    $null = Invoke-Tool $Tools.Seal @("seal","_shared/__authority_direct","-KeyName",$KeyName)
    $directReview = Invoke-Tool $Tools.Review @(
        "approve","_shared/__authority_direct",
        "-KeyName",$KeyName,
        "-Direct",
        "-ReviewContextId","issuer-direct-review-context",
        "-SourceRoot","task",
        "-SourcePaths","src/a.ps1;.hidden/fixture.txt",
        "-EvidencePaths","evidence/test.log",
        "-Summary","issuer direct implementation independently verified"
    )
    $directApproval = Join-Path $directFixture "approvals\review-v001.json"
    $directArchive = Invoke-Tool $Tools.Archive @("archive","_shared/__authority_direct","-KeyName",$KeyName,"-Approval",$directApproval)
    Add-Result "S16C" "issuer-direct-work-can-be-reviewed-and-explicitly-archived" (($directReview.ExitCode -eq 0) -and ($directArchive.ExitCode -eq 0)) "review=$($directReview.ExitCode) archive=$($directArchive.ExitCode)"
    $directApprovalJson = if (Test-Path -LiteralPath $directApproval) { Get-Content -LiteralPath $directApproval -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null }
    Add-Result "S16C2" "hidden-directory-source-path-retains-leading-dot" ($directApprovalJson -and ".hidden/fixture.txt" -in @($directApprovalJson.source_paths)) "review=$($directReview.ExitCode)"

    $planFixture = New-AuthorityFixture -Name "__authority_plan_transition"
    $planYaml = Join-Path $planFixture ".task.yaml"
    (Get-Content -LiteralPath $planYaml -Raw -Encoding UTF8) -replace "(?m)^phase:\s*implement\s*$","phase: plan" |
        Set-Content -LiteralPath $planYaml -Encoding UTF8
    $planTransition = Invoke-Tool $Tools.State @("transition","_shared/__authority_plan_transition","plan-complete")
    $planPhase = Read-Field $planYaml "phase"
    Add-Result "S16D" "authority-plan-may-enter-implement-before-seal" (($planTransition.ExitCode -eq 0) -and $planPhase -eq "implement") "exit=$($planTransition.ExitCode) phase=$planPhase"

    $legacy = New-AuthorityFixture -Name "__authority_legacy" -AuthorityProfile "none"
    $contradictory = New-AuthorityFixture -Name "__authority_contradictory" -Contradictory $true -AuthorityProfile "none"
    $migrationReport = Join-Path $Root ".trae\tasks\_shared\__authority-migration-report.json"
    $script:Created += $migrationReport
    Set-TestSid $IssuerSid
    $migration = Invoke-Tool $Tools.Migrate @("scan","-RootPath",(Join-Path $Root ".trae\tasks\_shared"),"-ReportPath",$migrationReport,"-KeyName",$KeyName,"-Apply","-NameFilter","__authority_legacy;__authority_contradictory")
    $legacyTrust = Read-Field (Join-Path $legacy ".task.yaml") "legacy_trust"
    $contradictoryTrust = Read-Field (Join-Path $contradictory ".task.yaml") "legacy_trust"
    $migrationVerify = Invoke-Tool $Tools.Migrate @("verify","-ReportPath",$migrationReport,"-PublicKeyPath",$identityPath)
    Add-Result "S17" "legacy-tasks-classified-without-fabricated-trust" (($migration.ExitCode -eq 0) -and ($migrationVerify.ExitCode -eq 0) -and $legacyTrust -eq "legacy_untrusted" -and $contradictoryTrust -eq "migration_required") "scan=$($migration.ExitCode) verify=$($migrationVerify.ExitCode) legacy=$legacyTrust contradictory=$contradictoryTrust"

    $openCodeFixture = New-AuthorityFixture -Name "__authority_opencode" -RootName ".opencode\tasks"
    Set-TestSid $IssuerSid
    $openCodeSeal = Invoke-Tool $Tools.Seal @("seal","_shared/__authority_opencode","-KeyName",$KeyName,"-TaskRoot",".opencode\tasks")
    $openCodeVerify = Invoke-Tool $Tools.Seal @("verify","_shared/__authority_opencode","-TaskRoot",".opencode\tasks")
    Add-Result "S18" "opencode-and-codex-use-shared-authority-protocol" (($openCodeSeal.ExitCode -eq 0) -and ($openCodeVerify.ExitCode -eq 0)) "seal=$($openCodeSeal.ExitCode) verify=$($openCodeVerify.ExitCode)"
}
catch {
    Add-Result "S99" "authority-suite-completes" $false $_.Exception.Message
}
finally {
    Set-TestSid $IssuerSid
    foreach ($keyName in $KeyNames) {
        if (Test-Path -LiteralPath $Tools.Identity) {
            $null = Invoke-Tool $Tools.Identity @("delete","-KeyName",$keyName)
        }
        else {
            try {
                $key = [System.Security.Cryptography.CngKey]::Open($keyName)
                $key.Delete()
            }
            catch {}
        }
    }
    foreach ($path in $Created) {
        Remove-PathSafe $path
    }
    Remove-Item Env:JINLI_AUTH_TEST_MODE -ErrorAction SilentlyContinue
    Remove-Item Env:JINLI_AUTH_TEST_SID -ErrorAction SilentlyContinue
    Pop-Location
}

if ($Failed) { exit 1 }
exit 0
