# WP06 — Compat Docs Verification Report

**Task**: jinli/2026-06-27-runtime-daemon-unified-ide
**Phase**: verify (WP06)
**Verifier role**: lead (Plan Agent / Issuer — `金璃小天才`)
**Verifier model**: minimax-cn/MiniMax-M3 (jīng-lí)
**Date**: 2026-06-29
**Spec section**: `WP06-compat-docs-verification.md` §"Done definition"

---

## 1. Document changes inventory

All file mutations follow the WP06 contract `allowed paths` table.
Forbidden paths (`tasks.md`, `.task.yaml`, `requirements.md`, etc.)
were **not** modified.

### 1.1 New files (2)

| File | Bytes | Purpose |
|------|------:|---------|
| `Project/Jinli/docs/06-Operations/General/runtime-daemon-runbook.md` | ~7,400 | Operator runbook for daemon lifecycle, MCP smoke, IDE sync, failure modes |
| `verification-report.md` (canonical path: `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide/verification-report.md`) | ~13,200 | Lead-signed verification report with 5 markers + AC mapping |

### 1.2 Extended files (3)

| File | Before → After | Sections added |
|------|----------------|----------------|
| `Project/Jinli/docs/03-Architecture/runtime-enforcement-layer.md` | 118 → 224 lines | Authority Layers (4-level table), Source-of-Truth Policy (8 rows), Service Registry (WP02) 11 services, Runtime API (WP03) 8 endpoints, MCP Adapter (WP04) 17 tools distribution, IDE Registry Sync (WP05) 3 modes, Spec Scenarios Mapping (S01-S09), 旧 MIRP 1-11 场景对应 |
| `Project/Jinli/docs/04-Implementation/runtime-protocol.md` | 130 → 281 lines | File Layout (159 pytest + 19 node test + WP01-WP05 新 modules), Public API (Daemon + Service Registry + Runtime Emotion + Daemon HTTP Client), Scripts (WP01-WP05 commands), Test Run (159/19/0), MCP Adapter Adapter Notes, IDE Registry Sync Notes, Boundary Rules §4-6, Known Limitations §4-6 |
| `Project/Jinli/docs/DOCS_TREE.md` | 89 → 91 lines | 2026-06-29 WP06 row + `runtime-daemon-runbook.md` categorized entry |

### 1.3 Verified unchanged but still correct

- `Project/Jinli/config/ide-registry.json` (WP05, 3,552 B) — single
  source of truth for IDE sync.
- `.trae/scripts/jinli-system.ps1`, `jinli-runtime-turn.ps1`,
  `jinli-mcp-smoke.ps1`, `jinli-ide-sync.ps1`, `validate-codex-capabilities.ps1` — all
  WP05-final, no further mutation needed.
- `.codex/capability-baseline.json` (WP05, 15,292 B) — correct.

### 1.4 AGENTS.md

**Not modified.** WP06 changes are scoped to Jinli project
internals (skills + runtime + docs). AGENTS.md describes the
workspace-level IDE agent flow and is unaffected. Documented as
explicit decision in verification-report.md §"Document Manifest".

---

## 2. Verification status

| Command | Result | Notes |
|---------|:------:|-------|
| V1 — `jinli-system.ps1 doctor` | PASS | After start; 11/11 services online, 391 memories |
| V2 — `jinli-mcp-smoke.ps1` | PASS | 5/5 steps green (daemon up + Python client 200 + Node plugin reads endpoint + stop fallback + summary) |
| V3 — `validate-codex-capabilities.ps1 -Mode Inspect` | PASS | 5/5 groups; 75 active skills; 11 archived; 8 required plugins; 3 marketplaces; jinli-soul-core-runtime-readiness 7/7 sub-checks |
| V4 — `task-guard.ps1 verify` | **FAIL** | `tasks.md` 全 `[ ]` + verification_report 字段 missing + verify_result=pending + report markers 缺失 — **explicit gap G1** |
| Python pytest | PASS | 159/159 |
| Node tests | PASS | 19/19 (14 pass + 5 skip) |
| Runtime turn end-to-end | PASS | gate.passed=true, 7 evidence records |

**Net assessment**: 6/7 verifications pass. V4 fails on
**governance**, not technical correctness — see §"Failed checks".

---

## 3. Failed checks

### F1 — `task-guard.ps1 verify` BLOCKED (4 sub-failures)

```text
[FAIL] all tasks checked              # tasks.md 全 [ ]
[FAIL] verification_report exists     # .task.yaml.verification_report = null
[FAIL] verify_result is pass          # .task.yaml.verify_result = pending
[FAIL] verification report contains required automated acceptance evidence
```

**Root cause analysis**:

- `tasks.md` is on the WP06 forbidden paths list (line 32 of
  `WP06-compat-docs-verification.md`). Per
  `Docs/AI/41-Issuer-Worker-Authority-Separation.md` §"Worker",
  Workers (subagent) **may not** edit `tasks.md`. The original
  Issuer (`金璃小天才` / Plan Agent) does have theoretical authority
  per the same document §"Issuer", but:
  - The packet's authority profile is `authority_status: legacy`,
    `legacy_trust: legacy_untrusted`, with
    `packet_digest: null` and `issuer_key_id: null`. There is no
    cryptographic seal to invoke Issuer authority under strong mode.
  - The WP06 contract literally forbids `tasks.md`. Strictly
    following the contract is the conservative action.
  - Honest practice: surface the gap, request Ba Ba decision.

**Options for Ba Ba** (full text in
`verification-report.md` §"Explicit Gaps" G1):

- **A (recommended)**: Ba Ba explicitly grants Issuer exemption for
  WP06; I mark T1.1-T8.9 as `[x]` with evidence links; re-run
  `task-guard verify` → expected pass.
- **B**: Ba Ba accepts the explicit gap as sufficient evidence per
  WP06 done definition ("maps AC01-AC15 to evidence or explicit
  gaps"); proceed to archive under
  `41-Issuer-Worker-Authority-Separation.md` §"Verify And Archive"
  with `verify_result=blocked` and Issuer-signed approval.
- **C**: Ba Ba adds an Issuer-exception clause to WP06 packet and
  reseals.

### F2 — Codex `jinli-soul-core@personal` not installed (V3 WARN)

Documented as explicit gap G2. Expected because Codex's TOML is in
the forbidden path. `jinli-ide-sync.ps1 doctor -Ide codex` provides
the manual TOML diff. **Not a failure** — V3 marked this PASS with a
WARN banner.

---

## 4. Unresolved risks

### R1 — `tasks.md` governance gap (severity: governance)

See F1 above. Resolvable only by Ba Ba's explicit decision
(Option A / B / C).

### R2 — Codex MCP manual install (severity: low, known limitation)

6 of 8 IDE configurations are auto-sync-able. Codex requires manual
TOML edit because `C:\Users\87372\.codex\config.toml` is governed by
the host-level workspace rules (forbidden path). Documented in
`ide-registry-sync.md`. **Not a defect — by design**.

### R3 — 6 MCP tools remain on PowerShell (severity: medium)

`soul_visual_memory_query`, `soul_conversation_context`,
`soul_proactive_history_query`, `soul_proactive_facet_update`,
`soul_growth_log_query`, `soul_response_plan` (and the
`vision_*`/`growth_*` families) are not yet backed by daemon
endpoints. They continue to serve via PowerShell fallback.
Documented in `runtime-protocol.md` §"Known Limitations" and
verification-report.md G3. **Estimated remediation**: 3-4 days of
follow-on WP.

### R4 — Daemon stop-between-tests UX (severity: low)

During V2 step 4, the daemon is intentionally stopped to verify
fallback behavior. This caused the runtime turn test to fail the
first time because the daemon was offline. I re-ran `jinli-system
start` before the runtime turn test. **Not a defect** — fallback
verification is a design feature. Documented in
`runtime-daemon-runbook.md` §七.

---

## 5. Recommended final lead decision

> **Accept WP06 with explicit gap G1; defer G2/G3 to follow-on
> maintenance.**

**Rationale**:

1. **V1, V2, V3 all PASS** — runtime is functional, MCP adapter
   works, IDE sync works, capability inspection passes.
2. **V4 FAILS** only on `tasks.md` governance — the implementation
   itself is verified (159 pytest + 14 node pass + runtime turn
   end-to-end succeeds).
3. **G2 (Codex MCP) and G3 (6 deferred MCP tools)** are documented
   known limitations, accepted by WP04/WP05 design.
4. **No new technical risk introduced** — all architecture
   boundary disciplines (6/6) are respected.

**Next action for Ba Ba**:

- Pick Option A, B, or C from §3 F1 above.
- If A: I'll update `tasks.md` immediately (single-line edits per
  task with evidence link to its claim/report) and re-run
  `task-guard.ps1 verify`. Expected: `verify_result=pass`.
- If B: I'll prepare the archive submission under
  `issuer-archive.ps1` with `verify_result=blocked` and
  Issuer-signed approval.
- If C: I'll reseal the packet under
  `task-packet-seal.ps1 seal` with the new exception clause.

---

## 6. Open issues for follow-on WPs

| Issue | Severity | Owner | Estimated effort |
|-------|----------|-------|------------------|
| 6 MCP tools need daemon endpoints (`response_plan`, `vision_*`, `growth_*`) | medium | subagent (future WP) | 3-4 days |
| Codex MCP manual install procedure | low | Ba Ba / operator | 5 min TOML paste |
| `tasks.md` governance — permanent fix | low | Ba Ba decision | 0 (policy) |
| Memory candidate: claim/report UTF-8 BOM by default | low | Jinli-Plan Agent | patch `Write-Claim.ps1` |

---

## 7. Artifacts

- `verification-report.md` (canonical):
  `E:\UEGameDevelopment\.trae\tasks\jinli\2026-06-27-runtime-daemon-unified-ide\verification-report.md`
- This report (report):
  `E:\UEGameDevelopment\.trae\tasks\jinli\2026-06-27-runtime-daemon-unified-ide\reports\WP06-compat-docs-verification.md`
- Claim (BOM-encoded):
  `E:\UEGameDevelopment\.trae\tasks\jinli\2026-06-27-runtime-daemon-unified-ide\claims\WP06-compat-docs-verification.claim.json`

---

**End of WP06-compat-docs-verification report.**