# Living Spec: Jinli Runtime Daemon Unified IDE

## Quick Status

- Phase: plan
- Task packet: `.trae/tasks/jinli/2026-06-27-runtime-daemon-unified-ide`
- Selected path: Python Runtime Daemon as single authority; MCP as IDE adapter
- Current blocker: Ba Ba must explicitly confirm the full plan before implementation gates may pass

## Progress Summary

| Scenario | Status | Notes |
|---|---|---|
| S01 | [ ] | Daemon lifecycle |
| S02 | [ ] | Service registry and health |
| S03 | [ ] | Runtime turn API |
| S04 | [ ] | MCP daemon-backed tools |
| S05 | [ ] | IDE registry and sync |
| S06 | [ ] | Legacy compatibility |
| S07 | [ ] | Diagnostics and degraded states |
| S08 | [ ] | Documentation and extension contract |
| S09 | [ ] | Verification and acceptance evidence |

## Scenarios

### S01 Daemon Lifecycle

**Status**: [ ]

GIVEN no Jinli daemon is running  
WHEN Ba Ba runs `.trae/scripts/jinli-system.ps1 start`  
THEN exactly one daemon process starts  
AND a PID file, endpoint file, and log file are written  
AND a second start command reuses or reports the existing daemon instead of starting a duplicate.

### S02 Service Registry And Health

**Status**: [ ]

GIVEN the daemon is running  
WHEN Ba Ba runs `.trae/scripts/jinli-system.ps1 status -Json`  
THEN the output lists every registered service  
AND each service is reported as `online`, `degraded`, `offline`, or `disabled`  
AND required service failures are blocking in `doctor` output  
AND optional service degradation is visible, not silent.

### S03 Runtime Turn API

**Status**: [ ]

GIVEN the daemon is running and core services are online  
WHEN a caller submits a standard turn request  
THEN the daemon runs the request through TurnOrchestrator  
AND returns a TurnManifest with evidence records and gate result  
AND records missing or degraded services explicitly.

### S04 MCP Daemon-Backed Tools

**Status**: [ ]

GIVEN an IDE connects to the Jinli MCP adapter  
WHEN it lists tools  
THEN the existing Soul Core tool names are still present  
AND calls to core tools go through the daemon client  
AND direct PowerShell business logic is not the authoritative path for new runtime behavior.

### S05 IDE Registry And Sync

**Status**: [ ]

GIVEN Codex, OpenCode, Trae, or a generic MCP client needs Jinli  
WHEN Ba Ba runs `.trae/scripts/jinli-ide-sync.ps1 apply -Ide all`  
THEN each IDE config is generated or updated from a shared registry  
AND `check` detects drift  
AND repair guidance names the exact config surface that is stale.

### S06 Legacy Compatibility

**Status**: [ ]

GIVEN existing scripts or skills still call `soul-core.ps1` or read JSON state  
WHEN the daemon-backed runtime is active  
THEN compatibility calls continue to work  
AND JSON files are preserved  
AND authority labels identify Python daemon state as the selected source of truth.

### S07 Diagnostics And Degraded States

**Status**: [ ]

GIVEN a required or optional service fails to start  
WHEN Ba Ba runs `doctor` or a runtime turn  
THEN the output names the service, reason, and recovery guidance  
AND no tool reports success without evidence.

### S08 Documentation And Extension Contract

**Status**: [ ]

GIVEN future systems such as voice, avatar, vision, local LLM routing, mobile, or UE editor control are added later  
WHEN a developer reads the runtime docs  
THEN they can see where to register a service, how to declare health, how to expose MCP tools, and how to sync IDE config  
AND no new system needs to become an IDE-specific runtime owner.

### S09 Verification And Acceptance Evidence

**Status**: [ ]

GIVEN implementation is complete  
WHEN verification runs  
THEN every acceptance criterion in `analysis.md` is mapped to command output  
AND `verification-report.md` includes Automated Verification, Acceptance Criteria, Architecture Compliance, Test Evidence, and Residual Risk.

## Key Decisions

| Decision | Rationale | Impact |
|---|---|---|
| Python daemon is the single authority | Avoids split-engine drift and makes services actually online | MCP and scripts become clients |
| MCP tools keep existing names | Existing skills and prompts already depend on them | Lower migration risk |
| Legacy PowerShell/JSON is compatibility, not authority | Prevents data loss and preserves existing workflows | Requires clear mirror policy |
| IDE config comes from one registry | Supports Codex/OpenCode/Trae/future IDEs without drift | Requires sync and doctor scripts |
| Service degradation is explicit | Matches MIRP design and avoids false health claims | Health output and manifests must include reasons |

## Constraints

- Do not edit project implementation files before Plan gate and can-edit pass.
- Do not remove legacy data files.
- Do not create per-IDE runtime owners.
- Do not hide degraded service states behind default success.
- Do not weaken existing workflow gates.

## Verification State

- Verification not run yet.
- Plan gate intentionally blocked until Ba Ba confirms the selected mature plan.

## Changelog

- 2026-06-27: Initial task packet created.
