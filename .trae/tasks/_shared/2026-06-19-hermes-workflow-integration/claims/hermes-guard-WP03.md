# WP03 Claim: Hermes Workflow Guard Plugin

- **Claim ID**: hermes-guard-WP03
- **Task**: _shared/2026-06-19-hermes-workflow-integration
- **Claimed by**: 金璃好帮手 (lead model)
- **Status**: active

## Claim Scope

Implementation of the jinli-workflow-guard Hermes plugin:
1. Core guard logic (guard.py): role validation, mutation blocking, path enforcement
2. Secret-safe audit recording (audit.py): credential redaction, audit records
3. Plugin registration (__init__.py): 5 hooks registered
4. Plugin metadata (plugin.yaml)
5. Unit tests (test_workflow_guard.py): 6 tests

## Allowed Paths
- `.trae/hermes/plugins/jinli-workflow-guard/**`
- `.trae/hermes/tests/test_workflow_guard.py`
