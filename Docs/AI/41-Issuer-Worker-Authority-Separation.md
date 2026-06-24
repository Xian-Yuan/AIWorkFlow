---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-41-issuer-worker-authority-separation-91b1
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.41-issuer-worker-authority-separation.91b1

---

# Issuer-Worker Authority Separation

Date: 2026-06-19
Status: Active

## Rule

The model that executes a work package cannot mutate the task packet, approve its own work, publish repair packages, or archive the task.

Authority is proven by the current Windows SID, access to the original issuer's non-exportable CNG signing key, valid signatures, and current packet/source/evidence/acceptance hashes. Model names, prompt roles, and `-Actor issuer` are not identities.

## Roles

### Issuer

The original high-capability model:

- creates and seals the task packet;
- issues bounded worker capabilities;
- updates task/spec/checklist files;
- independently reviews results;
- publishes repair packages after rejection;
- signs approval;
- explicitly archives.

### Worker

The implementation model:

- reads one work package and signed capability;
- edits only capability Allowed Paths;
- appends progress;
- submits one result;
- reports only `working`, `partial`, `blocked`, or `implementation_done`.

The Worker never writes `.task.yaml`, `tasks.md`, `spec.md`, `routing.md`, `analysis.md`, `work-packages/`, approvals, evidence, Review/Verify results, or Archive state.

## Strong Isolation

Strong mode requires different Windows SIDs for Worker and Issuer.

The Issuer key is ECDSA P-256 in the Windows CNG user key store with private export disabled. If both models use the same SID, the system cannot prove which model invoked an issuer command, so strong-mode capability issuance fails.

## Bootstrap

```powershell
.\.trae\scripts\issuer-identity.ps1 init `
  -KeyName "JinliIssuer" `
  -OutputPath ".trae\authority\issuer-public.json"
```

The output contains no private key.

## Seal And Delegate

```powershell
.\.trae\scripts\task-packet-seal.ps1 seal <task> -KeyName "JinliIssuer"

.\.trae\scripts\worker-capability.ps1 issue <task> `
  -KeyName "JinliIssuer" `
  -WorkPackage "work-packages/WP01-example.md" `
  -AttemptId A001 `
  -WorkerSid "S-1-5-..." `
  -AllowedPaths "Project/Example/src/file.ps1"
```

The seal covers routing, analysis, spec, tasks, doc-impact, and all work packages. Changing any covered file invalidates current capabilities and approvals until the Issuer reseals a new packet version.

Apply task-packet ACL protection:

```powershell
.\.trae\scripts\worker-sandbox.ps1 protect <task> `
  -Capability <capability> `
  -KeyName "JinliIssuer"
```

## Worker Submission

```powershell
.\.trae\scripts\worker-submit.ps1 progress <task> `
  -Capability <capability> `
  -PayloadPath <progress-json>

.\.trae\scripts\worker-submit.ps1 result <task> `
  -Capability <capability> `
  -PayloadPath <result-json>
```

Progress is append-only. The result is single-create.

## Issuer Review

Worker execution:

```powershell
.\.trae\scripts\issuer-review.ps1 approve <task> `
  -KeyName "JinliIssuer" `
  -Capability <capability> `
  -Result <result-json> `
  -ReviewContextId <fresh-context-id> `
  -SourcePaths <allowed-source-paths> `
  -EvidencePaths <evidence-files>
```

Issuer-direct execution:

```powershell
.\.trae\scripts\issuer-review.ps1 approve <task> `
  -KeyName "JinliIssuer" `
  -Direct `
  -ReviewContextId <fresh-context-id> `
  -SourceRoot workspace `
  -SourcePaths <changed-files> `
  -EvidencePaths <evidence-files>
```

The approval binds packet, work package/capability/result when applicable, source state, evidence, acceptance criteria, issuer SID/key, and review context.

## Rejection And Repair

Only the Issuer may reject and publish repair work:

```powershell
.\.trae\scripts\issuer-review.ps1 reject <task> `
  -KeyName "JinliIssuer" `
  -Capability <capability> `
  -Result <result-json> `
  -ReviewContextId <fresh-context-id> `
  -SourcePaths <paths> `
  -EvidencePaths <evidence> `
  -RootCauseId RC01 `
  -Summary <summary> `
  -FailedCommand <command> `
  -Expected <expected> `
  -Actual <actual> `
  -AllowedPaths <narrower-paths> `
  -ReadFirst <files>
```

The command records immutable evidence, publishes a narrower repair package, and reseals the packet.

## Verify And Archive

`task-guard.ps1 <task> verify` validates the signed approval. `-Apply` does not archive.

Archive is separate:

```powershell
.\.trae\scripts\issuer-archive.ps1 archive <task> `
  -KeyName "JinliIssuer" `
  -Approval <accepted-review-json>
```

Archive recomputes every bound hash, requires complete tasks/spec and resolved repair state, writes a signed Archive certificate, and only then sets `archived: true`.

## Legacy Migration

```powershell
.\.trae\scripts\migrate-task-authority.ps1 scan `
  -RootPath ".trae\tasks" `
  -ReportPath ".trae\tasks\_shared\authority-migration-report.json" `
  -KeyName "JinliIssuer" `
  -Apply

.\.trae\scripts\migrate-task-authority.ps1 verify `
  -ReportPath ".trae\tasks\_shared\authority-migration-report.json" `
  -PublicKeyPath ".trae\authority\issuer-public.json"
```

- unsigned legacy task: `legacy_untrusted`;
- contradictory phase/archive state: `migration_required`;
- active authority task: `not_applicable`;
- no historical trust is fabricated.

## Regression

```powershell
.\.trae\scripts\test-authority-separation.ps1
.\.trae\scripts\test-worker-repair-loop.ps1
.\.trae\scripts\test-workflow-regression.ps1
```
