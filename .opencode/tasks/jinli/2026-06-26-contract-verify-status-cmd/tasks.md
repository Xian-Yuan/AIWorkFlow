# Tasks: contract-verify status Command

## Task 1: Implement status command
- [ ] Add status action handler in contract-verify.ps1
- [ ] Parse contract.yaml, count contracts per phase and status
- [ ] Handle missing contract.yaml gracefully
- Basis: spec.md AC1, AC2

## Task 2: Syntax verification
- [ ] PowerShell parser zero errors
- Basis: spec.md AC3

## Task 3: Functional verification — automated verification
- [ ] Test with existing task (2026-06-26-runtime-enforcement-layer) that has contract.yaml
- [ ] Test with uninitialized task (no contract.yaml)
- [ ] Verify init/verify/report still work
- Basis: spec.md AC4

## Task 4: Acceptance Criteria mapping
- [ ] AC1: status outputs summary table with Phase/Total/Pass/Fail/Blocking columns
- [ ] AC2: status handles missing contract.yaml gracefully
- [ ] AC3: PowerShell parser zero errors
- [ ] AC4: existing commands unaffected
- Basis: analysis.md Acceptance Criteria

## Task 5: Mature-path verification
- [ ] Verify the selected mature path is followed: status added to contract-verify.ps1 directly
- [ ] Verify rejected shortcuts are not taken: no separate script, no report flag extension
- Basis: analysis.md Selected mature path and Rejected shortcuts
