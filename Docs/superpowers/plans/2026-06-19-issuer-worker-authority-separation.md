# Issuer-Worker Authority Separation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce issuer-only task publication, review, verification, repair publication, and archive using a non-exportable Windows CNG key, signed packet/capability/approval artifacts, SID checks, and explicit archive.

**Architecture:** A shared PowerShell authority module provides canonical hashing, CNG signing, signature verification, identity checks, safe writes, and task-root resolution. Issuer scripts seal packets, issue worker capabilities, approve or reject results, and archive explicitly; the worker receives only a signed capability and append-only submission commands. Existing state and guard scripts lose generic Review/Verify/Archive mutation paths.

**Tech Stack:** Windows PowerShell 5.1, .NET CNG/ECDSA P-256, SHA-256, NTFS ACL inspection/application, JSON artifacts, existing Comet task packet scripts.

---

## File Map

| File | Responsibility |
|---|---|
| `.trae/scripts/authority-core.psm1` | Canonical JSON, hashing, CNG signing, signature verification, SID checks, task resolution |
| `.trae/scripts/issuer-identity.ps1` | Initialize and inspect the issuer key |
| `.trae/scripts/task-packet-seal.ps1` | Build and sign immutable packet manifests |
| `.trae/scripts/worker-capability.ps1` | Issue and inspect signed worker capabilities |
| `.trae/scripts/worker-submit.ps1` | Append worker progress and create one result |
| `.trae/scripts/worker-sandbox.ps1` | Inspect/apply task-packet ACL rules for a worker SID |
| `.trae/scripts/issuer-review.ps1` | Validate submission, sign accept/reject approval, publish issuer-owned rejection evidence |
| `.trae/scripts/issuer-archive.ps1` | Validate accepted approval and explicitly archive |
| `.trae/scripts/migrate-task-authority.ps1` | Classify legacy tasks without fabricating trust |
| `.trae/scripts/test-authority-separation.ps1` | Focused security and lifecycle regression |
| `.trae/scripts/task-state.ps1` | Remove generic acceptance/archive mutation |
| `.trae/scripts/task-guard.ps1` | Verify signatures/hashes and remove Verify-to-Archive Apply |
| `.trae/scripts/worker-repair-loop.ps1` | Require issuer authority for failure publication and resolution |
| `Docs/AI/41-Issuer-Worker-Authority-Separation.md` | Operational authority workflow |

### Task 1: Security Regression Fixtures

**Files:**
- Create: `.trae/scripts/test-authority-separation.ps1`

- [ ] Write fixtures for separate issuer/worker SID simulation, packet sealing, capability issuance, append-only progress, result submission, approval, and archive.
- [ ] Add negative scenarios for role spoofing, packet mutation, stale approval, duplicate result, same-SID strong mode, generic state mutation, and Verify auto-archive.
- [ ] Run the suite before implementation.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-authority-separation.ps1
```

Expected: failures because authority scripts do not exist and old state paths remain open.

### Task 2: Authority Core And Issuer Identity

**Files:**
- Create: `.trae/scripts/authority-core.psm1`
- Create: `.trae/scripts/issuer-identity.ps1`

- [ ] Implement task-root resolution with traversal rejection.
- [ ] Implement stable UTF-8 file hashing and deterministic manifest digest generation.
- [ ] Implement current SID retrieval; test-only SID injection is allowed only when `JINLI_AUTH_TEST_MODE=1`.
- [ ] Create a named ECDSA P-256 CNG key with `ExportPolicy=None` and signing-only usage.
- [ ] Export only the ECC public blob and derive `issuer_key_id=SHA256(public_blob)`.
- [ ] Implement `Sign-AuthorityDigest` and `Test-AuthoritySignature`.
- [ ] Verify that exporting the private key fails.

Run parser checks and the identity subset of the focused suite.

### Task 3: Packet Seal

**Files:**
- Create: `.trae/scripts/task-packet-seal.ps1`
- Create: `.trae/tasks/_shared/templates/packet-manifest-template.json`

- [ ] Enumerate the exact core-file set: routing, analysis, spec, tasks, doc-impact, and all work packages.
- [ ] Reject missing files, unresolved placeholders, absolute paths, traversal, and duplicate normalized paths.
- [ ] Write `issuer/packet-manifest.json`, signature, and public-key metadata atomically.
- [ ] Add authority fields to `.task.yaml`: profile, issuer key/SID, packet version/digest, status.
- [ ] Verify a sealed packet without private-key access.

### Task 4: Worker Capability And Submission

**Files:**
- Create: `.trae/scripts/worker-capability.ps1`
- Create: `.trae/scripts/worker-submit.ps1`
- Create: `.trae/scripts/worker-sandbox.ps1`
- Create: `.trae/tasks/_shared/templates/worker-capability-template.json`

- [ ] Issue a signed capability bound to worker SID, packet/work-package hashes, attempt, exact paths, expiry, and nonce.
- [ ] Reject strong-mode capability issuance when worker SID equals issuer SID.
- [ ] Implement capability verification without private-key access.
- [ ] Implement append-only progress event creation.
- [ ] Implement single-create result submission.
- [ ] Reject authority claims and statuses outside `working|partial|blocked|implementation_done`.
- [ ] Inspect/apply NTFS rules that deny Worker writes to core files and allow only exact progress/result locations.

### Task 5: Issuer Review And Repair Ownership

**Files:**
- Create: `.trae/scripts/issuer-review.ps1`
- Modify: `.trae/scripts/worker-repair-loop.ps1`
- Modify: `.trae/scripts/verification-report-template.md`

- [ ] Compute packet, work-package, source-diff, evidence, and acceptance digests.
- [ ] Require issuer SID/private-key access and a fresh review context ID.
- [ ] Sign accept/reject approvals.
- [ ] On reject, append immutable evidence and invoke repair publication only through issuer authority.
- [ ] Prevent Worker from resolving repair state.
- [ ] Invalidate approvals when any bound digest changes.

### Task 6: Explicit Archive And State Lockdown

**Files:**
- Create: `.trae/scripts/issuer-archive.ps1`
- Modify: `.trae/scripts/task-state.ps1`
- Modify: `.trae/scripts/task-guard.ps1`

- [ ] Remove `review_result`, `verify_result`, `verification_report`, `phase`, and `archived` from generic `set`.
- [ ] Block generic `review-pass`, `verify-pass`, and `archived` transitions.
- [ ] Make `task-guard verify -Apply` run checks without changing state.
- [ ] Verify accepted approval signature and all current digests.
- [ ] Require no unresolved repair state and all AC complete.
- [ ] Sign an Archive certificate before setting `phase: archive` and `archived: true`.

### Task 7: Legacy Migration

**Files:**
- Create: `.trae/scripts/migrate-task-authority.ps1`
- Create: `.trae/tasks/_shared/authority-migration-report.md`

- [ ] Scan every `.task.yaml` under shared task roots.
- [ ] Mark unsigned legacy tasks `legacy_untrusted`.
- [ ] Mark contradictory phase/archive tasks `migration_required`.
- [ ] Preserve all prior files and report every classification.
- [ ] Do not issue signatures or trust historical approvals.

### Task 8: Documentation And Adapters

**Files:**
- Create: `Docs/AI/41-Issuer-Worker-Authority-Separation.md`
- Modify: `Docs/AI/24-Pro-Flash-Model-Tiering.md`
- Modify: `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`
- Modify: `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`
- Modify: `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md`
- Modify: `Docs/AI/README.md`
- Modify: `Docs/AI/.cache-manifest.md`
- Modify: `AGENTS.md`
- Modify: `skills/codex-project-router/SKILL.md`

- [ ] Document issuer-only packet mutation and archive.
- [ ] Replace model-name authority with SID/signature authority.
- [ ] Document worker-account prerequisite and same-SID fail-closed behavior.
- [ ] Update Codex/OpenCode adapter rules.

### Task 9: Full Verification

**Files:**
- Modify: `.trae/scripts/test-workflow-regression.ps1`
- Modify: task-local `verification-report.md`

- [ ] Run parser checks for every modified PowerShell file.
- [ ] Run `test-authority-separation.ps1`.
- [ ] Run `test-worker-repair-loop.ps1`.
- [ ] Run `test-workflow-regression.ps1`.
- [ ] Run `test-doc-guard.ps1`.
- [ ] Run docs-tree check.
- [ ] Seal this task, approve it from an issuer review context, and explicitly archive it.

Expected: every command exits 0; Verify does not archive; only `issuer-archive.ps1` produces trusted Archive.
