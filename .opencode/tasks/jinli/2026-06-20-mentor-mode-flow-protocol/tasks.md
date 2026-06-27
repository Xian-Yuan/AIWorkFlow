# Tasks: Jinli Mentor Mode Flow Protocol

## Dependency Graph

```text
T1 packet design -> T2 Ba Ba confirmation -> T3 implementation -> T4 verification
```

---

## Plan

- [x] T1.1: Decide whether Mentor Mode and KG/video infrastructure should be one packet or two.
- [x] T1.2: Create standalone Mentor Mode task packet.
- [x] T1.3: Define Mentor Mode boundaries, scenarios, and acceptance criteria.
- [x] T1.4: Ba Ba reviews whether Mentor Mode should be implemented as docs-only, persona config, runtime routing, or staged adoption.

## Implementation

- [x] T2.1: Write the Jinli design doc for Mentor Mode Flow Protocol → `Project/Jinli/docs/02-Design/General/mentor-mode-flow-protocol.md`
- [x] T2.2: Update `Project/Jinli/docs/DOCS_TREE.md` with new doc entry and recent update record.
- [x] T2.3: Add guidance section for presenting graph/video retrieval as evidence rather than decisions → §4 of design doc.
- [~] T2.4: Decide whether to update `Project/Jinli/config/persona.json`. → Deferred: persona.json update is a future implementation face per §7, not in current docs-only scope.
- [~] T2.5: Decide whether runtime scene routing should detect Mentor Mode. → Deferred: runtime detection is a future implementation face per §7, not in current docs-only scope.

## Final Verification

- [x] T3.1: Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] T3.2: Run automated verification and record command output in `verification-report.md`.
- [x] T3.3: Map implementation result to Acceptance Criteria in `verification-report.md`.
