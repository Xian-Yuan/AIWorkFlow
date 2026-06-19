# Issuer-Worker Authority Separation Design

Date: 2026-06-19
Status: Approved
Scope: shared task-packet authority, worker submission, review, verification, archive, and legacy migration

## Problem

The current workflow separates roles in documentation but not in authority. A worker can invoke the same scripts as the issuer, edit task-state files, claim Review or Verify pass, and archive a task. Text fields such as `Verifier model: codex` describe an identity but do not prove it.

The new design must make these actions mechanically impossible for a worker:

- modify the authoritative task packet;
- update formal task progress or acceptance state;
- publish or revise a work package;
- approve Review or Verify;
- archive a task;
- impersonate the issuer by passing a command-line role name.

## Selected Architecture

Use an issuer-controlled capability workflow with:

1. a non-exportable Windows CNG signing key owned by the issuer Windows SID;
2. a signed immutable task-packet manifest;
3. signed, single-attempt worker capabilities;
4. append-only worker progress and result submission;
5. issuer-only signed Review approval;
6. a separate issuer-only Archive command;
7. hash invalidation when packet, source diff, acceptance criteria, or evidence changes.

The worker and issuer must use different Windows SIDs for strong isolation. A model name, prompt role, `-Actor` argument, or environment variable is not a trusted identity.

## Trust Boundary

```text
Issuer Windows SID
  -> owns non-exportable CNG private key
  -> seals and revises task packets
  -> issues worker capabilities
  -> reviews evidence in a fresh context
  -> signs acceptance
  -> explicitly archives

Worker Windows SID
  -> receives public task packet and signed capability
  -> edits only project paths named by the capability
  -> appends progress events
  -> submits one result artifact
  -> cannot open issuer private key
  -> cannot write issuer, approval, state, spec, task-list, or work-package files
```

Strong mode requires a separate worker SID and NTFS enforcement. Same-SID execution is compatibility-only and can never satisfy Review, Verify, or Archive authority.

## Task Directory Contract

```text
task/
  .task.yaml
  routing.md
  analysis.md
  spec.md
  tasks.md
  doc-impact.md
  work-packages/
  issuer/
    packet-manifest.json
    packet-manifest.sig
    public-key.json
  capabilities/
    WPxx-Axxx.capability.json
    WPxx-Axxx.capability.sig
  progress/
    WPxx-Axxx/
      <event-id>.json
  reports/
    WPxx-Axxx-result.json
  approvals/
    review-vNNN.json
    review-vNNN.sig
    archive-vNNN.json
    archive-vNNN.sig
  evidence/
    evidence-manifest.json
  verification-history/
```

Ownership:

- Issuer-only: `.task.yaml`, plan/spec/task files, `work-packages/`, `issuer/`, `capabilities/`, `approvals/`, `evidence/`, `verification-history/`.
- Worker append/create only: its assigned `progress/WPxx-Axxx/` directory and exact result path.
- Worker may edit only source paths listed in its signed capability.

## Packet Seal

The immutable packet manifest contains:

```json
{
  "schema_version": 1,
  "task_name": "2026-06-19-system-feature",
  "packet_version": 1,
  "issuer_key_id": "sha256-public-key",
  "issuer_sid": "S-1-5-...",
  "issued_at": "2026-06-19T16:00:00+08:00",
  "core_files": [
    {"path": "routing.md", "sha256": "..."},
    {"path": "analysis.md", "sha256": "..."},
    {"path": "spec.md", "sha256": "..."},
    {"path": "tasks.md", "sha256": "..."},
    {"path": "doc-impact.md", "sha256": "..."},
    {"path": "work-packages/WP01-example.md", "sha256": "..."}
  ],
  "packet_digest": "..."
}
```

`.task.yaml` is mutable issuer state and is not part of `packet_digest`. Approval binds the relevant task-state fields separately.

Any core-file change requires a new packet version and invalidates earlier worker capabilities and approvals.

## Worker Capability

Each capability is signed by the issuer and binds:

- task and packet version;
- packet digest;
- work-package path and digest;
- attempt ID;
- worker SID;
- allowed source paths;
- exact progress directory;
- exact result path;
- issued and expiry times;
- nonce.

The capability is single-attempt and cannot authorize Review, Verify, packet mutation, repair publication, or Archive.

## Worker Submission

Worker actions go through `worker-submit.ps1`:

```powershell
worker-submit.ps1 progress <task> -Capability <path> -Payload <json>
worker-submit.ps1 result <task> -Capability <path> -Payload <json>
```

The command verifies:

- signature;
- current Windows SID equals capability worker SID;
- capability packet digest equals current sealed packet;
- target path exactly matches the capability;
- progress event does not already exist;
- result does not already exist;
- payload status is one of `working`, `partial`, `blocked`, `implementation_done`;
- payload does not claim Review, Verify, Archive, or task-state authority.

Worker output never changes `.task.yaml` or checks tasks in `tasks.md`.

## Issuer Review

`issuer-review.ps1` runs under the issuer SID in a fresh review context.

Approval binds:

```text
packet_digest
work_package_digest
source_diff_digest
evidence_manifest_digest
acceptance_criteria_digest
issuer_key_id
issuer_sid
review_context_id
reviewed_at
decision
```

The command rejects:

- missing or invalid packet seal;
- wrong issuer SID or key;
- unsigned or stale worker capability;
- worker result outside the signed attempt;
- changed packet, source diff, evidence, or acceptance criteria;
- incomplete acceptance criteria;
- reuse of the worker context ID;
- unsupported decision.

On rejection, only the issuer may write immutable failure evidence and publish a narrower repair package. The existing repair-loop script becomes issuer-only.

## Explicit Archive

Review/Verify never archives implicitly.

```powershell
issuer-review.ps1 approve <task> ...
issuer-archive.ps1 archive <task> -ReviewApproval <path>
```

Archive requires:

- accepted issuer-signed review approval;
- current hashes equal the approval hashes;
- all acceptance criteria complete;
- current packet seal valid;
- no unresolved repair state;
- no worker mutation of core files;
- explicit issuer SID and private-key access.

`task-guard.ps1 verify -Apply` is removed as an archive transition. Archive produces its own signed certificate and then updates `.task.yaml`.

## State Model

```text
draft
  -> issued
  -> worker_active
  -> worker_submitted
  -> issuer_review
       -> rejected -> repair_issued
       -> accepted -> verified
  -> archived
```

Only the issuer updates formal state. Worker statuses are report data, not formal task-state transitions.

## Legacy Migration

Existing tasks are not retroactively trusted.

- valid old task without issuer signature: `legacy_untrusted`;
- contradictory phase/archive state: `migration_required`;
- reaccepted task: rerun verification, seal current packet, issue a new signed approval;
- no historical signatures are fabricated.

Migration writes an audit report and does not delete prior evidence.

## Compatibility

Codex, OpenCode, Trae, and DS4 use the same file protocol. The trust decision depends on Windows SID, signature, hash, and ACL, not the IDE or model label.

Tasks without an authority profile may continue as legacy tasks but cannot obtain trusted Archive status after enforcement is enabled.

## Failure Handling

- Missing key: fail closed and instruct issuer initialization.
- Same issuer/worker SID: capability issuance fails in strong mode.
- ACL cannot be applied or verified: task stays issued but cannot enter worker-active.
- Packet mutation: capability and approval become stale.
- Interrupted write: temporary file is not accepted; signed final artifact must exist.
- Third consecutive same-root failure: architecture review, no new repair capability.

## Automated Acceptance

The test suite must prove:

1. Worker cannot edit task core files.
2. Worker cannot invoke Review, Verify, or Archive.
3. `-Actor issuer` and model-name claims do not grant authority.
4. Packet mutation invalidates capabilities and approvals.
5. Source or evidence mutation invalidates approval.
6. A non-issuer key cannot approve.
7. Verify does not archive.
8. Archive fails without every signature and digest.
9. Progress is append-only.
10. Worker cannot overwrite a result.
11. Same-SID strong-mode capability issuance fails.
12. Legacy inconsistent tasks become `migration_required`.
13. Legacy unsigned tasks become `legacy_untrusted`.
14. Codex/OpenCode task roots use the same protocol.

## External Basis

- Anthropic, Building Effective Agents: orchestrator-workers and evaluator-optimizer separation.
- OpenAI Agents SDK: manager orchestration retains control while specialized agents act as tools.
- GitHub protected branches: code-owner review, stale approval invalidation, and status checks bound to a revision.
- NIST SP 800-53 AC-5 and AC-6: separation of duties and least privilege.
- in-toto: signed step metadata and verification of who performed each supply-chain action.
- MetaGPT and ChatDev: role/SOP separation as coordination guidance, supplemented here with cryptographic and OS enforcement.

## Non-Goals

- Building a remote identity service.
- Creating or storing worker passwords in the repository.
- Automatically creating a Windows local account without explicit administrator action.
- Treating model names as identities.
- Retroactively declaring legacy tasks trusted.
