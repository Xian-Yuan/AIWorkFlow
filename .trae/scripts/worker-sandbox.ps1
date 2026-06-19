param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("inspect","protect")]
    [string]$Command,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$TaskName,
    [Parameter(Mandatory=$true)]
    [string]$Capability,
    [string]$KeyName,
    [string]$TaskRoot
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

function Add-WorkerRule {
    param(
        [string]$Path,
        [System.Security.Principal.SecurityIdentifier]$Sid,
        [System.Security.AccessControl.FileSystemRights]$Rights,
        [System.Security.AccessControl.AccessControlType]$Type,
        [bool]$Container
    )
    $acl = Get-Acl -LiteralPath $Path
    $inheritance = if ($Container) {
        [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
    }
    else {
        [System.Security.AccessControl.InheritanceFlags]::None
    }
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Sid,
        $Rights,
        $inheritance,
        [System.Security.AccessControl.PropagationFlags]::None,
        $Type
    )
    $acl.AddAccessRule($rule) | Out-Null
    Set-Acl -LiteralPath $Path -AclObject $acl
}

try {
    $task = Resolve-AuthorityTask $TaskName $TaskRoot
    $capabilityArtifact = Test-AuthorityCapability $task $Capability
    $protected = @(".task.yaml","routing.md","analysis.md","spec.md","tasks.md","doc-impact.md","work-packages","issuer","capabilities","approvals","evidence","verification-history")
    $progress = Join-Path $task.Dir ($capabilityArtifact.progress_directory -replace "/", "\")
    $resultDirectory = Split-Path -Parent (Join-Path $task.Dir ($capabilityArtifact.result_path -replace "/", "\"))
    $inspection = [ordered]@{
        schema_version = 1
        task = $TaskName
        worker_sid = $capabilityArtifact.worker_sid
        protected_paths = $protected
        writable_paths = @(
            Get-AuthorityRelativeTaskPath $task $progress
            Get-AuthorityRelativeTaskPath $task $resultDirectory
        )
        mode = $Command
    }
    if ($Command -eq "inspect") {
        $inspection | ConvertTo-Json -Depth 8
        exit 0
    }

    if (-not $KeyName) { throw "KeyName is required for protect" }
    $null = Assert-AuthorityIssuer $task $KeyName
    $sid = New-Object System.Security.Principal.SecurityIdentifier($capabilityArtifact.worker_sid)
    $denyRights = [System.Security.AccessControl.FileSystemRights]"WriteData, AppendData, CreateFiles, CreateDirectories, Delete, DeleteSubdirectoriesAndFiles, ChangePermissions, TakeOwnership"
    foreach ($relative in $protected) {
        $path = Join-Path $task.Dir ($relative -replace "/", "\")
        if (Test-Path -LiteralPath $path) {
            Add-WorkerRule $path $sid $denyRights ([System.Security.AccessControl.AccessControlType]::Deny) (Test-Path -LiteralPath $path -PathType Container)
        }
    }
    foreach ($path in @($progress,$resultDirectory)) {
        if (-not (Test-Path -LiteralPath $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
        Add-WorkerRule $path $sid ([System.Security.AccessControl.FileSystemRights]::Modify) ([System.Security.AccessControl.AccessControlType]::Allow) $true
    }
    $inspection.applied = $true
    $inspection | ConvertTo-Json -Depth 8
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
