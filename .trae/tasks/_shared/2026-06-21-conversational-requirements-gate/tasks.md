# Tasks: Conversational Requirements Gate

## Dependency Graph

```text
T1 regression RED
  -> T2 state/templates
  -> T3 mechanical gate
  -> T4 planning Skills
  -> T5 workflow docs
  -> T6 verification
```

## Regression First

- [x] T1.1 Add deep/fast requirement-gate regression fixtures.
- [x] T1.2 Run regression and record expected RED failures before implementation.

## State and Templates

- [x] T2.1 Add versioned requirement fields to new task initialization.
- [x] T2.2 Add requirements and execution-prompt templates.
- [x] T2.3 Update task-package prompt template.

## Mechanical Enforcement

- [x] T3.1 Enforce deep requirement evidence.
- [x] T3.2 Enforce fast-track reason and assessment.
- [x] T3.3 Enforce execution-prompt structure.
- [x] T3.4 Preserve legacy packet compatibility.

## Planner Behavior

- [x] T4.1 Upgrade smart-requirements.
- [x] T4.2 Upgrade 金璃小天才.
- [x] T4.3 Upgrade shared UE and Codex routers.

## Documentation

- [x] T5.1 Add authoritative conversational requirements workflow.
- [x] T5.2 Update workflow manifest, packet contract, README, and cache manifest.

## Final Verification

- [x] T6.1 Verify AC01-AC08 with current-session evidence.
- [x] T6.2 Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T6.3 Run automated verification and record command output in verification-report.md.
- [x] T6.4 Map implementation result to Acceptance Criteria in verification-report.md.
