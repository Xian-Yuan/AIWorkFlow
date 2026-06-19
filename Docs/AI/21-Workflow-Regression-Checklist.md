# Workflow Regression Checklist

## Run This Checklist When

- router agent changes
- router skill changes
- implementer or reviewer rules change
- `task-state.ps1` changes
- `task-guard.ps1` changes
- `spec-living.ps1` changes
- `doc-guard.ps1` or `update-docs-tree.ps1` changes
- `Docs/AI/27-AI-Workflow-Refactor-Manifest.md` changes
- `Docs/AI/28-Documentation-Governance-Workflow.md` changes
- `Docs/AI/16-DeepSeek4Pro-Workflow-Profile.md` changes

## Checklist

- [ ] Run S01 and confirm blocked plan behavior
- [ ] Run S02 and confirm unconfirmed plan remains blocked
- [ ] Run S03 and confirm missing router proof remains blocked
- [ ] Run S04 and confirm valid implementation is allowed
- [ ] Run S05 and confirm review remains fail-closed
- [ ] Run S06 and confirm documentation governance is enforced
- [ ] Run S07 and confirm `spec-living` initializes a Living Spec
- [ ] Run S08 and confirm router uses `spec-living`, not `spec-tracker`
- [ ] Run S09 and confirm `Docs/AI` index/cache include current workflow docs
- [ ] Run S10 and confirm all project `DOCS_TREE.md` files exist
- [ ] Record results in `.trae/tasks/regression-results/deepseek4pro-workflow-regression.md`
- [ ] For any FAIL, assess whether a `Docs/Memory/candidates/` entry should be created

## Pass/Fail Policy

- Any unexpected authorization to edit is a FAIL
- Any blocked valid implementation in S04 is a FAIL
- Any review PASS without evidence in S05 is a FAIL
- Missing `doc-impact.md`, missing same-project docs, or missing `DOCS_TREE.md` evidence is a FAIL
- Router active docs pointing new tasks to `spec-tracker` is a FAIL
- Missing `Docs/AI` index/cache entries for active workflow docs is a FAIL
- FAIL blocks workflow rule changes until fixed or explicitly accepted

## Execution Order

1. Run the scriptable gate scenarios first: `S01` to `S04`
2. Record the script output in the regression results file
3. Run documentation governance and taxonomy scenarios: `S06` to `S10`
4. Run the review fail-closed check for `S05`
5. Record whether the workflow change is accepted or blocked
