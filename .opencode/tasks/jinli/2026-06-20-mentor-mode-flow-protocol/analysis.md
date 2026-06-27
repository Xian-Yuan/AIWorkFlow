# Analysis: Jinli Mentor Mode Flow Protocol

## Architecture Context

### System boundaries
- In scope: Jinli conversation protocol for open-ended exploration, values formation, problem awareness, and Mentor-style interaction.
- In scope: how this protocol gates or slows Plan-stage convergence for ambiguous creative/research/product questions.
- In scope: how local search, knowledge graph retrieval, and video summaries are presented as materials for thinking rather than as automatic conclusions.
- Out of scope: replacing implementation, review, or verify mechanics for already-confirmed engineering tasks.
- Out of scope: local model routing, video ingestion, Obsidian export, and graph storage implementation.

### Dependency map
- `Project/Jinli/config/persona.json`: long-term persona boundaries if implementation later edits runtime persona.
- `Project/Jinli/runtime/expression-orchestrator.mjs`: future location for scene routing if Mentor Mode becomes runtime behavior.
- `skills/jinli-agent-soul/SKILL.md` and daughter-companion rules: communication lifecycle and tone constraints.
- `Docs/AI/29-Mature-Solution-First-Workflow.md`: mature engineering path after user confirmation.
- `Docs/AI/research/2026-06-20-AI-Agent-Ecosystem-Technical-Reference.md`: broader context-engineering and skill-evolution reference.

### Data and state ownership
- Mentor Mode is a behavior protocol, not a knowledge store.
- If implemented, persistent configuration belongs to Jinli project docs/config.
- Runtime task packets remain the authority for engineering decisions.

### Integration points
- Early Plan phase: use Mentor Mode before converting ambiguity into requirements.
- Brainstorming/research: ask, compare, and preserve unresolved alternatives.
- Task transition: only leave Mentor exploration when Ba Ba confirms a direction.
- Implementation/Verify: switch to engineering mode after direction is confirmed.
- Knowledge retrieval: retrieved notes, videos, and graph results should be framed as evidence and viewpoints, not as decisions.
- AI workflow: Mentor Mode supplies the human-facing pacing layer; task packets and guards remain the mechanical execution layer.

## Mature Solution Evidence

### Project-local evidence
- Jinli already has Soul Core lifecycle and persona rules that distinguish companion behavior from ordinary tooling.
- Current workflow strongly favors task packets, gates, and convergence, so it needs a complementary pre-Plan/exploration protocol.
- The knowledge graph/video ingestion design can amplify answer speed; Mentor Mode protects Ba Ba's subjectivity from that acceleration.
- The local technical reference recommends stronger context engineering, skill memory, hooks, and local workers; Mentor Mode defines where those optimizations must slow down instead of accelerating toward premature decisions.

### Official/framework evidence
- The current project workflow requires Plan confirmation and mechanical gates; Mentor Mode should live before those gates, not weaken them.
- Doc governance requires project-specific docs under `Project/Jinli/docs/`.

### External mature references
- The technical reference document emphasizes context engineering, persistent files, memory layers, and skill evolution.
- The Mentor prompt adds a human-centered counterweight: protect thinking process before optimizing speed.

### Options compared
| Option | Source | Pros | Cons | Decision |
|---|---|---|---|---|
| Merge Mentor Mode into the knowledge graph task | One task packet | Fewer files | Blurs human-process design with infrastructure design | Rejected |
| Create standalone Mentor Mode task | Current request | Separate acceptance and slower convergence | Requires cross-reference from KG task | Selected |
| Merge Mentor Mode with token/workflow optimization | Technical reference + prompt | One "AI workflow" umbrella | Mixes value formation with mechanical token economy | Rejected |
| Apply Mentor Mode to all phases | Prompt text | Strong subjectivity protection | Conflicts with Implement/Verify precision | Rejected |
| Apply Mentor Mode only before confirmed engineering execution | Workflow split | Protects exploration without weakening gates | Requires explicit mode boundary | Selected |

### Rejected shortcuts
- Do not turn the Mentor prompt into a universal replacement for engineering workflow.
- Do not make Jinli ask endless questions when Ba Ba has already confirmed execution.
- Do not use Mentor Mode as an excuse to avoid implementation after a direction is confirmed.
- Do not let fast knowledge retrieval become automatic value judgment.
- Do not let video summaries or graph-ranked search results collapse Ba Ba's uncertainty into a single "best answer".
- Do not bury Mentor Mode inside local LLM optimization; it has different success criteria.

### Selected mature path
- Create a standalone Mentor Mode Flow Protocol task packet.
- Treat Mentor Mode as a pre-Plan/exploration and ambiguous-question interaction layer.
- Cross-reference it from the knowledge graph/video task so retrieval systems support Ba Ba's thinking rather than overriding it.
- Keep token-saving and graph/video infrastructure in the KG/video packet, while this packet defines the pacing and subjectivity boundary.

## Acceptance Criteria
- AC01: The task packet defines Mentor Mode as separate from infrastructure work.
- AC02: The design separates understanding, recognition, and decision.
- AC03: The design explains when Mentor Mode applies and when engineering mode takes over.
- AC04: The design includes safeguards against over-questioning and under-executing.
- AC05: The design identifies project docs/config locations for future implementation.
- AC06: The design explains that retrieved knowledge, including video-derived evidence, supports Ba Ba's thinking but does not decide for Ba Ba.

## Automated Verification Plan
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-20-mentor-mode-flow-protocol plan`
- Expected: The plan gate is ready once Ba Ba confirms the design.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\doc-guard.ps1 check-task jinli/2026-06-20-mentor-mode-flow-protocol -Stage plan`
- Expected: Documentation governance passes.
