param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("init","status","delete")]
    [string]$Command,
    [Parameter(Mandatory=$true)]
    [string]$KeyName,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "authority-core.psm1") -Force -DisableNameChecking

try {
    switch ($Command) {
        "init" {
            if (-not $OutputPath) { throw "OutputPath is required for init" }
            $metadata = New-AuthorityIssuerKey $KeyName
            Write-AuthorityJson $OutputPath $metadata
            $metadata | ConvertTo-Json -Depth 8
        }
        "status" {
            if (-not (Test-AuthorityKeyExists $KeyName)) { throw "Issuer key not found: $KeyName" }
            Get-AuthorityPublicMetadataFromKey $KeyName | ConvertTo-Json -Depth 8
        }
        "delete" {
            Remove-AuthorityIssuerKey $KeyName
            Write-Host "Deleted issuer key: $KeyName"
        }
    }
    exit 0
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
