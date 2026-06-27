# Tasks: <Task Name>

## Dependency Graph

```
<!-- ASCII art or bullet list of task dependencies -->
```

---

## <Module 1>

- [ ] T1.1: <description>
- [ ] T1.2: <description>
- [ ] T1.{N}: Verify <specific AC#>

## <Module 2>

...

## Final Verification

- [ ] T{N-2}: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [ ] T{N-1}: Run automated verification (`.\.trae\scripts\verify.ps1`) and record output in `verification-report.md`.
- [ ] T{N}: Map implementation result to Acceptance Criteria in `verification-report.md`.
