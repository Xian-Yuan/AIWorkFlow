# Analysis: Issuer-Worker Authority Separation

## Architecture Context

### System boundaries

- Owns shared task-packet authority under `.trae/scripts` and task metadata.
- Does not own project feature implementation or remote model transport.
- Does not create Windows accounts or persist passwords.

### Dependency map

```text
Windows SID + CNG key
  -> authority-core
  -> packet seal
  -> worker capability
  -> worker submission
  -> issuer review
  -> explicit archive

task-state/task-guard/repair-loop
  -> authority checks
  -> no generic acceptance or archive
```

### Data and state ownership

- Issuer owns packet core, formal state, capabilities, approvals, evidence, and archive.
- Worker owns only append-only progress and one result artifact.
- Source edits are authorized by signed exact paths and checked against the resulting diff.
- Public-key metadata is repository-visible; private key remains non-exportable in the issuer user key store.

### Integration points

- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/worker-repair-loop.ps1`
- `.trae/scripts/task-handoff.ps1`
- Codex/OpenCode shared task roots
- NTFS ACL and Windows CNG

## Mature Solution Evidence

### Project-local evidence

- Current scripts accept self-declared verifier identity.
- Generic state commands can set acceptance and archive fields.
- `verify -Apply` currently archives.
- All 27 audited task packets lack issuer identity and packet hash.
- Three legacy tasks have contradictory archived/phase state.

### Official/framework evidence

- NIST SP 800-53 AC-5 requires separation of duties.
- NIST SP 800-53 AC-6 requires least privilege.
- GitHub protected-branch rules invalidate stale approvals and bind acceptance to a reviewed revision.
- Windows CNG supports user-owned, non-exportable signing keys.

### External mature references

- Anthropic orchestrator-workers and evaluator-optimizer patterns.
- OpenAI Agents SDK manager orchestration.
- in-toto signed supply-chain step metadata.
- MetaGPT and ChatDev role/SOP separation.

### Options compared

| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Text role fields | Current workflow | Simple | Forgeable, no authority boundary | Rejected |
| One-time plaintext token | Capability systems | Moderate effort | Token can be copied by same user/process | Rejected |
| CNG key + SID + signed capability | NIST/GitHub/in-toto-inspired | Strong local proof, auditable, stale approval invalidation | Requires separate worker SID | Selected |

### Rejected shortcuts

- Trusting `issuer_model: codex`.
- Trusting `-Actor issuer`.
- Letting Worker update `tasks.md` progress.
- Letting Verify archive.
- Retroactively signing old tasks.
- Storing a private key file in the repository.

### Selected mature path

Implement a local cryptographic authority protocol backed by Windows identity and non-exportable CNG keys, with explicit issuer-only review and archive commands.

## Acceptance Criteria

- AC01: Worker cannot mutate task core or formal state.
- AC02: Worker cannot approve or archive.
- AC03: Role/model spoofing grants no authority.
- AC04: Packet mutation invalidates capability and approval.
- AC05: Source/evidence mutation invalidates approval.
- AC06: Only the original issuer key/SID can approve.
- AC07: Verify never archives automatically.
- AC08: Archive requires complete signed evidence.
- AC09: Progress is append-only and result is single-create.
- AC10: Same-SID strong-mode issuance fails.
- AC11: Repair publication and resolution are issuer-only.
- AC12: Legacy tasks are classified without fabricated trust.
- AC13: Codex/OpenCode share one protocol.
- AC14: Existing non-authority workflow regression remains usable until migrated.

## Automated Verification Plan

- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-authority-separation.ps1`
- Expected: all authority and tamper scenarios pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-worker-repair-loop.ps1`
- Expected: repair-loop regressions pass with issuer authority.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-workflow-regression.ps1`
- Expected: shared workflow regression passes.
- Command: parser checks and doc-guard/docs-tree checks.
- Expected: all exit 0.
