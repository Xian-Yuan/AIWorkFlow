# Execution Prompt: contract-verify status Command

## Role
Implement Agent — implementing a bounded additive feature to an existing PowerShell script.

## Goal
Add a status command to contract-verify.ps1 that provides a quick contract summary without running full verification.

## Task Packet Truth Sources
- spec.md — behavioral specification (GIVEN/WHEN/THEN)
- analysis.md — architecture context and mature solution evidence
- routing.md — skill routing and work package policy
- tasks.md — task breakdown and acceptance criteria mapping

## Confirmed Decisions
- fast-track classification: bounded single-file change, no architecture impact
- Single Agent mode: no sub-agents needed
- Option A selected: add status command directly to contract-verify.ps1

## Accepted Architecture
- status command reuses existing YAML parsing from init/verify commands
- Read-only: no file modifications during status execution
- Plain text table output, no markdown

## Allowed Paths
- .trae/scripts/contract-verify.ps1

## Forbidden Paths
- Any file under Project/
- Any file under Docs/ (except task packet artifacts)
- Any other .ps1 scripts

## Non-Goals
- Not adding status to other scripts
- Not changing existing init/verify/report behavior
- Not adding new dependencies
- Not modifying contract.yaml format

## Acceptance Criteria
- AC1: status command outputs summary table with Phase/Total/Pass/Fail/Blocking columns
- AC2: status command works with and without contract.yaml
- AC3: PowerShell parser zero errors
- AC4: Existing init/verify/report commands unaffected

## Verification Commands
Run contract-verify with the status action on the test task, then verify and report.

## Stop Conditions
- All 4 AC pass
- PowerShell parser zero errors
- No regressions in existing commands

## Evidence Rule
Every AC must have script output as evidence. Verbal claims without output are not accepted.
