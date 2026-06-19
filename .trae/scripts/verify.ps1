<#
.SYNOPSIS
One-click verification script for verification-before-completion workflow.
Auto-detects project type (UE5/Web) and runs appropriate checks.

.DESCRIPTION
Usage:
  verify.ps1                    Auto-detect project and run all checks
  verify.ps1 -Project ue5       Force UE5 verification (compile only)
  verify.ps1 -Project web       Force Web verification (tests only)
  verify.ps1 -Quick             Skip compilation, run fast checks only
  verify.ps1 -Json              Output results as JSON for automation

Exit codes:
  0 = All checks passed
  1 = One or more checks failed
  2 = Verification could not run (missing tools, config error)
#>

param(
    [ValidateSet("auto", "ue5", "web")]
    [string]$Project = "auto",

    [switch]$Quick,

    [switch]$Json
)

$ErrorActionPreference = "Continue"
$script:Results = @{
    Project = ""
    EngineVersion = ""
    Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Checks = @()
    Passed = 0
    Failed = 0
    Skipped = 0
    Overall = "UNKNOWN"
}

function Write-Color($Text, $Color = "White") {
    if (-not $Json) { Write-Host $Text -ForegroundColor $Color }
}

function Add-CheckResult($Name, $Status, $Detail) {
    $check = @{
        Name = $Name
        Status = $Status
        Detail = $Detail
    }
    $script:Results.Checks += $check
    switch ($Status) {
        "PASS" {
            $script:Results.Passed++
            if (-not $Json) { Write-Color "  [PASS] $Name" "Green" }
        }
        "FAIL" {
            $script:Results.Failed++
            if (-not $Json) {
                Write-Color "  [FAIL] $Name" "Red"
                if ($Detail) { Write-Color "         $Detail" "DarkRed" }
            }
        }
        "SKIP" {
            $script:Results.Skipped++
            if (-not $Json) { Write-Color "  [SKIP] $Name - $Detail" "Yellow" }
        }
    }
}

# ============================================================
# Auto-detect project type
# ============================================================
function Detect-Project {
    $cwd = Get-Location

    # Check if we're in a UE project directory
    $uprojectFiles = Get-ChildItem -Path $cwd -Filter "*.uproject" -ErrorAction SilentlyContinue
    if (-not $uprojectFiles) {
        $uprojectFiles = Get-ChildItem -Path $cwd -Recurse -Filter "*.uproject" -Depth 2 -ErrorAction SilentlyContinue
    }

    if ($uprojectFiles) {
        $script:Results.Project = "ue5"
        $uproject = Get-Content $uprojectFiles[0].FullName | ConvertFrom-Json
        $script:Results.EngineVersion = $uproject.EngineAssociation
        return @{
            Type = "ue5"
            ProjectFile = $uprojectFiles[0].FullName
            ProjectName = $uprojectFiles[0].BaseName
            EngineVersion = $uproject.EngineAssociation
        }
    }

    # Check if we're in a Web project directory
    $packageJson = Get-ChildItem -Path $cwd -Filter "package.json" -ErrorAction SilentlyContinue
    if ($packageJson) {
        $script:Results.Project = "web"
        return @{
            Type = "web"
            PackageFile = $packageJson.FullName
        }
    }

    # Check parent directories
    $parent = Split-Path $cwd -Parent
    if ($parent) {
        Push-Location $parent
        $result = Detect-Project
        Pop-Location
        return $result
    }

    return $null
}

# ============================================================
# UE5 Verification
# ============================================================
function Invoke-UE5Verify($ProjectInfo) {
    if (-not $Json) {
        Write-Color "========================================" "Cyan"
        Write-Color " UE5 Verification" "Cyan"
        Write-Color " Project: $($ProjectInfo.ProjectName)" "Cyan"
        Write-Color " Engine:  $($ProjectInfo.EngineVersion)" "Cyan"
        Write-Color "========================================" "Cyan"
    }

    # Check 1: Project file exists and is valid JSON
    if (Test-Path $ProjectInfo.ProjectFile) {
        try {
            $json = Get-Content $ProjectInfo.ProjectFile -Raw | ConvertFrom-Json
            Add-CheckResult "Project file valid" "PASS" $ProjectInfo.ProjectFile
        } catch {
            Add-CheckResult "Project file valid" "FAIL" "Invalid JSON: $_"
        }
    } else {
        Add-CheckResult "Project file valid" "FAIL" "File not found: $($ProjectInfo.ProjectFile)"
    }

    # Check 2: Find UnrealBuildTool
    $enginePath = "G:\UE_$($ProjectInfo.EngineVersion)"
    $ubtPath = Join-Path $enginePath "Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"

    if (-not (Test-Path $ubtPath)) {
        # Try without version suffix
        $enginePath = "G:\UE_$($ProjectInfo.EngineVersion -replace '\.','')"
        $ubtPath = Join-Path $enginePath "Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
    }

    if (Test-Path $ubtPath) {
        Add-CheckResult "UnrealBuildTool found" "PASS" $ubtPath
    } else {
        Add-CheckResult "UnrealBuildTool found" "FAIL" "UBT not found at $ubtPath"
        return
    }

    # Check 3: Git status (are there uncommitted changes?)
    $gitStatus = git status --porcelain 2>$null
    if ($gitStatus) {
        $changedFiles = ($gitStatus -split "`n").Count
        Add-CheckResult "Git working tree" "PASS" "$changedFiles uncommitted file(s) - snapshot before verify recommended"
    } else {
        Add-CheckResult "Git working tree" "PASS" "Clean working tree"
    }

    if ($Quick) {
        Add-CheckResult "UE5 Compilation" "SKIP" "Quick mode: compilation skipped"
        return
    }

    # Check 4: Compilation
    if (-not $Json) { Write-Color "`nCompiling..." "Yellow" }

    $buildArgs = @(
        $ProjectInfo.ProjectName,
        "Win64",
        "Development",
        $ProjectInfo.ProjectFile,
        "-WaitMutex",
        "-FromMsBuild"
    )

    $buildOutput = & $ubtPath $buildArgs 2>&1
    $buildExitCode = $LASTEXITCODE

    # Parse build output for errors
    $errorLines = $buildOutput | Where-Object { $_ -match "error C\d+:|error LNK\d+:|Error:|fatal error" }
    $warningLines = $buildOutput | Where-Object { $_ -match "warning C\d+:" }

    if ($buildExitCode -eq 0 -and -not $errorLines) {
        Add-CheckResult "UE5 Compilation" "PASS" "Build succeeded with $($warningLines.Count) warning(s)"
    } else {
        $errorSummary = ($errorLines | Select-Object -First 3) -join "; "
        Add-CheckResult "UE5 Compilation" "FAIL" "Build failed (exit $buildExitCode): $errorSummary"
    }

    # Check 5: Warning count (warn if > 0)
    if ($warningLines.Count -gt 0) {
        Add-CheckResult "Compilation warnings" "PASS" "$($warningLines.Count) warning(s) - review if new"
    } else {
        Add-CheckResult "Compilation warnings" "PASS" "0 warnings"
    }
}

# ============================================================
# Web Verification
# ============================================================
function Invoke-WebVerify($ProjectInfo) {
    if (-not $Json) {
        Write-Color "========================================" "Cyan"
        Write-Color " Web Verification" "Cyan"
        Write-Color "========================================" "Cyan"
    }

    # Check 1: package.json exists
    if (Test-Path $ProjectInfo.PackageFile) {
        Add-CheckResult "package.json exists" "PASS" $ProjectInfo.PackageFile
    } else {
        Add-CheckResult "package.json exists" "FAIL" "Not found"
        return
    }

    # Check 2: Node.js available
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Add-CheckResult "Node.js available" "PASS" $nodeVersion
    } else {
        Add-CheckResult "Node.js available" "FAIL" "Node.js not found in PATH"
        return
    }

    # Check 3: node_modules exist
    $cwd = Split-Path $ProjectInfo.PackageFile -Parent
    if (Test-Path (Join-Path $cwd "node_modules")) {
        Add-CheckResult "Dependencies installed" "PASS" "node_modules exists"
    } else {
        Add-CheckResult "Dependencies installed" "FAIL" "Run npm install first"
    }

    if ($Quick) {
        Add-CheckResult "Web tests" "SKIP" "Quick mode: tests skipped"
        return
    }

    # Check 4: Run tests if test script exists
    $packageJson = Get-Content $ProjectInfo.PackageFile | ConvertFrom-Json
    if ($packageJson.scripts -and $packageJson.scripts.test) {
        if (-not $Json) { Write-Color "`nRunning tests..." "Yellow" }
        Push-Location $cwd
        $testOutput = npm test 2>&1
        $testExitCode = $LASTEXITCODE
        Pop-Location

        if ($testExitCode -eq 0) {
            Add-CheckResult "Web tests" "PASS" "All tests passed"
        } else {
            Add-CheckResult "Web tests" "FAIL" "Tests failed (exit $testExitCode)"
        }
    } else {
        Add-CheckResult "Web tests" "SKIP" "No test script in package.json"
    }

    # Check 5: Lint if available
    if ($packageJson.scripts -and $packageJson.scripts.lint) {
        Push-Location $cwd
        $lintOutput = npm run lint 2>&1
        $lintExitCode = $LASTEXITCODE
        Pop-Location

        if ($lintExitCode -eq 0) {
            Add-CheckResult "Linter" "PASS" "No lint errors"
        } else {
            Add-CheckResult "Linter" "FAIL" "Lint errors found"
        }
    }
}

# ============================================================
# Main
# ============================================================
function Main {
    if (-not $Json) {
        Write-Color "`n=== VERIFY.PS1 ===" "Cyan"
        Write-Color "Timestamp: $($script:Results.Timestamp)`n" "Gray"
    }

    # Determine project
    $projectInfo = $null
    if ($Project -eq "auto") {
        $projectInfo = Detect-Project
        if (-not $projectInfo) {
            Add-CheckResult "Project detection" "FAIL" "Could not detect project type. Use -Project ue5 or -Project web"
            return
        }
        Add-CheckResult "Project detection" "PASS" "Detected: $($projectInfo.Type)"
    } else {
        $script:Results.Project = $Project
        $projectInfo = @{ Type = $Project }
        Add-CheckResult "Project selection" "PASS" "Manual: $Project"
    }

    # Run verification
    switch ($projectInfo.Type) {
        "ue5" { Invoke-UE5Verify $projectInfo }
        "web" { Invoke-WebVerify $projectInfo }
        default {
            Add-CheckResult "Verification" "FAIL" "Unknown project type: $($projectInfo.Type)"
        }
    }

    # Summary
    $script:Results.Overall = if ($script:Results.Failed -eq 0) { "PASS" } else { "FAIL" }

    if ($Json) {
        $script:Results | ConvertTo-Json -Depth 3
    } else {
        Write-Color "`n========================================" "Cyan"
        Write-Color " VERIFICATION COMPLETE" "Cyan"
        Write-Color " Passed:  $($script:Results.Passed)" "Green"
        if ($script:Results.Failed -gt 0) {
            Write-Color " Failed:  $($script:Results.Failed)" "Red"
        } else {
            Write-Color " Failed:  0" "Green"
        }
        if ($script:Results.Skipped -gt 0) {
            Write-Color " Skipped: $($script:Results.Skipped)" "Yellow"
        }
        Write-Color " Overall: $($script:Results.Overall)" $(if ($script:Results.Overall -eq "PASS") { "Green" } else { "Red" })
        Write-Color "========================================" "Cyan"
    }

    exit $(if ($script:Results.Overall -eq "PASS") { 0 } else { 1 })
}

Main
