# Routing: Jinli Knowledge Graph + Video Implementation Plan

## Router Decision
- Project: Jinli
- Project type: other
- Main skill: codex-project-router
- Secondary skill: doc-governance
- Collaboration mode: lead-only planning, possible future worker packages for implementation slices.
- Task packet root: .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan
- Existing design document: Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md
- Related Mentor packet: .trae/tasks/jinli/2026-06-20-mentor-mode-flow-protocol
- Optimization scope: local-worker token reduction for knowledge/video ingestion and retrieval.
- Explicit user-facing capability: video URL -> transcript-backed text summary -> timestamped searchable evidence.
- Local worker interface: `Local Worker Gateway` job JSON -> Ollama -> schema-checked derived output.

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes

## Work Package Policy
- External workers: no
- Task packet root: .trae/tasks/jinli/2026-06-20-kg-video-implementation-plan
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

## Phase Policy
- This packet is a Plan packet only until Ba Ba confirms the build slice.
- It must not start implementation automatically.
- It must keep Mentor Mode as a cross-cutting interaction boundary, not merge it into the infrastructure acceptance criteria.
- It may include token-saving/local-model optimization only where that optimization is part of the knowledge graph/video pipeline.
- Broader AI workflow changes such as Hook gates, skill memory evolution, or global task-packet automation should become separate workflow packets if Ba Ba chooses to pursue them later.
- Non-KG daily task, coding, and broad Jinli workflow uses of local models are captured as future expansion candidates only.

## Documentation Scope
- Affected project: Project/Jinli
- Target design doc: Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md
- Possible future implementation paths: Project/Jinli/scripts, Project/Jinli/services, Project/Jinli/data.
