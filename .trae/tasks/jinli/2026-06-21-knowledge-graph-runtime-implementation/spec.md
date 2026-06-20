# Spec: Jinli Knowledge Graph Runtime Implementation

## GIVEN
The Jinli Phase 2.5 v2.2 design defines video ingestion, a Local Worker Gateway, accepted/candidate graph records, Obsidian-native graph output, local model routing, visual enhancement, and retrieval, but no production runtime implements those contracts.

## WHEN
The runtime implementation task is executed through its ordered work packages.

## THEN
Jinli can turn an accessible video URL or vsummary workspace artifact into timestamped, provenance-backed, searchable knowledge and an Obsidian-visible graph while preserving local-first authority and graceful degradation.

### S1 Runtime Configuration
**Status**: [ ]

GIVEN the intended vault is `E:\ObsidianVault`
WHEN configuration is inspected
THEN the service reports the active vault, tool root, Ollama endpoint, and external tool revisions
AND reports the current D-drive environment drift without changing user variables unless an explicit apply command is used.

### S2 Contract Validation
**Status**: [ ]

GIVEN malformed or incomplete source, segment, job, output, candidate, or accepted-record JSON
WHEN it reaches a state boundary
THEN validation fails with field-level errors
AND no canonical state is written.

### S3 Local Worker Gateway
**Status**: [ ]

GIVEN a bounded summarization or extraction job
WHEN the gateway invokes Ollama or another configured provider
THEN it records hashes, provider/model, timing, status, retries, token usage when available, and schema validation
AND returns only a validated envelope to the caller.

### S4 Public Video Ingestion
**Status**: [ ]

GIVEN a supported public YouTube or Bilibili URL
WHEN captions and metadata are accessible
THEN the pipeline writes source metadata, timestamped transcript entries, normalized segments, and source hashes
AND never attempts to bypass login, DRM, paywalls, or access restrictions.

### S5 vsummary Fallback
**Status**: [ ]

GIVEN captions are unavailable but a vsummary workspace export exists
WHEN the vsummary adapter imports it
THEN Jinli normalizes the transcript, chapters, notes, and provenance into the same source contracts
AND keeps vsummary as a pinned external dependency rather than copied project code.

### S6 Enrichment Degradation
**Status**: [ ]

GIVEN Ollama or a requested model is unavailable
WHEN transcript ingestion succeeds
THEN raw segments remain searchable
AND enrichment status is pending or failed with an actionable reason instead of losing source data.

### S7 Candidate Acceptance
**Status**: [ ]

GIVEN extracted concepts and relationships
WHEN they pass schema validation
THEN they remain candidates until confidence, provenance, deduplication, and acceptance policy pass
AND ambiguous or conflicting candidates enter a review queue.

### S8 Obsidian Native Graph
**Status**: [ ]

GIVEN accepted source, concept, segment, and relationship records
WHEN export runs
THEN it creates frontmatter-rich notes and `[[internal links]]` under `JinliKG`
AND preserves user-maintained sections on repeated export.

### S9 Graph Retrieval And MCP
**Status**: [ ]

GIVEN the generated vault has been indexed
WHEN Jinli or an AI client performs search, path, neighbor, or node lookup
THEN the obra bridge returns compact JSON with note IDs and evidence paths
AND the index remains rebuildable from the vault.

### S10 Visual Enhancement
**Status**: [ ]

GIVEN visual extraction is explicitly enabled
WHEN keyframes are sampled and analyzed
THEN observations are stored as candidate evidence linked to source timestamps
AND visual output cannot directly alter accepted graph notes or canonical records.

### S11 Soul Core Integration
**Status**: [ ]

GIVEN knowledge runtime is healthy
WHEN `soul_discover`, `soul_init`, or `soul_end` uses it
THEN only bounded ingest, retrieval, or reviewed promotion calls are made
AND existing Soul Core behavior remains compatible when knowledge runtime is unavailable.

### S12 End-To-End Verification
**Status**: [ ]

GIVEN offline fixtures and one explicitly supplied public live URL
WHEN final verification runs
THEN offline tests prove deterministic behavior
AND live evidence proves URL-to-transcript-to-graph-to-search on the configured machine.

## Acceptance Criteria
| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Contracts and state boundaries validate | `python -m pytest Project/Jinli/services/knowledge/tests/test_contracts.py -q` | Pass |
| AC02 | Vault drift is detected safely | `python -m pytest Project/Jinli/services/knowledge/tests/test_config.py -q` | Pass |
| AC03 | Worker Gateway is durable and schema checked | `python -m pytest Project/Jinli/services/knowledge/tests/test_worker_gateway.py -q` | Pass |
| AC04 | YouTube/Bilibili adapter behavior is covered | `python -m pytest Project/Jinli/services/knowledge/tests/test_video_sources.py -q` | Pass |
| AC05 | vsummary import uses the common source contract | `python -m pytest Project/Jinli/services/knowledge/tests/test_vsummary_adapter.py -q` | Pass |
| AC06 | Raw ingestion survives model outage | `python -m pytest Project/Jinli/services/knowledge/tests/test_enrichment.py -q` | Pass |
| AC07 | Provenance and acceptance policy are enforced | `python -m pytest Project/Jinli/services/knowledge/tests/test_graph_store.py -q` | Pass |
| AC08 | Deduplication and review queue are enforced | `python -m pytest Project/Jinli/services/knowledge/tests/test_deduplication.py -q` | Pass |
| AC09 | Obsidian export preserves manual content | `python -m pytest Project/Jinli/services/knowledge/tests/test_obsidian_export.py -q` | Pass |
| AC10 | obra bridge indexes and queries fixture vault | `python -m pytest Project/Jinli/services/knowledge/tests/test_obra_bridge.py -q` | Pass |
| AC11 | Visual output remains candidate-only | `python -m pytest Project/Jinli/services/knowledge/tests/test_visual_enrichment.py -q` | Pass |
| AC12 | Soul Core integration remains compatible | `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core.tests.ps1` | Pass |
| AC13 | Existing Node runtime remains compatible | `npm.cmd test --prefix Project/Jinli` | Pass |
| AC14 | Full offline and live flows produce evidence | `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/knowledge-runtime.ps1 test-offline` and `test-live` | Pass |
| AC15 | Documentation governance is synchronized | `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task jinli/2026-06-21-knowledge-graph-runtime-implementation -Stage implement` | Pass |

## Quality Checklist

### Completeness
- [x] [OK] Every previously deferred runtime subsystem has a scenario and work package.
- [x] [OK] Main path, fallback path, access-denied path, model outage, duplicate, conflict, and manual-note preservation are specified.
- [x] [OK] Acceptance Criteria map to focused tests and end-to-end evidence.

### Clarity
- [x] [OK] Canonical, candidate, derived, and human-visible state are separated.
- [x] [OK] External tools have pinned revisions and adapter boundaries.
- [x] [OK] Live-network verification is explicit and separate from deterministic tests.

### Consistency
- [x] [OK] The implementation follows Phase 2.5 v2.2 terminology and file ownership.
- [x] [OK] Project documentation remains under `Project/Jinli/Docs`.

### Scenario Coverage
- [x] [OK] Happy path, edge cases, failures, retries, cancellation, and unavailable dependencies are covered.

## Progress Summary
| Phase | Status | Key Decision |
|---|---|---|
| Plan | Complete | Full runtime split into nine bounded packages |
| Implement | Pending | DS4 packages execute in order |
| Review | Pending | Codex reviews reports and reruns checks |
| Verify | Pending | Offline plus explicit live URL evidence required |

## Non-Goals
- Do not build a custom graph UI.
- Do not replace Obsidian native Graph View.
- Do not implement DRM/login/paywall bypass.
- Do not copy or fork vsummary source into Jinli.
- Do not make cloud providers mandatory.
- Do not turn every discovered candidate into accepted knowledge automatically.
