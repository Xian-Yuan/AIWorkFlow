# DeepSeek4Pro Workflow Regression Results

| Scenario | Expected | Actual | Result | Notes |
|---|---|---|---|---|
| S01 | blocked | blocked | PASS | Gate result |
| S02 | blocked | blocked | PASS | Gate result |
| S03 | blocked | blocked | PASS | Gate result |
| S04 | allowed | allowed | PASS | Gate result |
| S06 | doc governance enforced | failed | FAIL | test-doc-guard.ps1 |
| S07 | spec.md created | created | PASS | spec-living primary path |
| S08 | spec-living only | spec-living only | PASS | ue-project-router |
| S09 | 27/28/29 indexed | indexed | PASS | Docs/AI README and cache manifest |
| S11 | valid mature evidence allowed | blocked | FAIL | task-guard plan |
| S12 | placeholder analysis blocked | blocked | PASS | task-guard plan |
| S10 | all project docs trees present | present | PASS | update-docs-tree.ps1 -Mode check |
| S05 | fail-closed review | manual | PENDING | Run checklist-driven reviewer evidence check |
