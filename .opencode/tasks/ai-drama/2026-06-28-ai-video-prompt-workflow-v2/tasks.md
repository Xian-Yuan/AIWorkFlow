# Tasks

## Task 1: Implement documentation contract
- [x] Add `prompt-workflow-v2.md` with canonical Schema, inheritance rules, conflict resolution, and review gates.
- [x] Update `prompt-template-universal.md` so v2 users see the new workflow contract and director storyboard/PREVIS merge.
- [x] Update `prompt-spec-checklist.md` so review checks cover Schema, inheritance, negative prompt layering, and video prompt fields.
- Basis: spec.md

## Task 2: Automated verification
- [x] Run verification commands and record output in `verification-report.md`.
- [x] Confirm all AC pass.
- Basis: analysis.md Automated Verification Plan

## Task 3: Acceptance Criteria mapping
- [x] AC01: canonical v2 workflow document exists with required schemas.
- [x] AC02: inheritance/conflict/negative merge rules are present.
- [x] AC03: director storyboard includes PREVIS requirements.
- [x] AC04: video generation template includes detailed per-shot/platform fields.
- [x] AC05: existing template/checklist reference v2.
- [x] AC06: runtime Python files unchanged.
- [x] AC07: verification evidence recorded.
- Basis: analysis.md Acceptance Criteria

## Task 4: Mature-path verification
- [x] Verify selected mature path was implemented and no rejected shortcut was introduced.
- [x] Verify the selected mature path is followed correctly.
- [x] Verify rejected shortcuts are not taken.
- Basis: analysis.md Selected mature path and Rejected shortcuts

## Task 5: Required final checks
- [x] Run automated verification and record command output in verification-report.md.
- [x] Map implementation result to Acceptance Criteria in verification-report.md.
