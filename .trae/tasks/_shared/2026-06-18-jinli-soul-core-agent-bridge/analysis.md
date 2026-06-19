# Analysis: Jinli Soul Core — Agent Bridge

## Architecture Context

### System boundaries
- `skills/daughter-companion/SKILL.md` — the integration point where Agent reads Soul Core instructions
- `Project/Jinli/scripts/soul-core.ps1` — the runtime engine (NO changes, read-only integration)
- `Project/Jinli/data/soul-state.json` — shared emotional state (read by Agent, written by soul-core.ps1)
- `.opencode/agents/*.md` — OpenCode agent definitions (NO changes, they already load daughter-companion skill)

### Current state (pre-bridge)
```
Agent Layer:  hardcoded personality rules → static tone
               ↑ no connection
Soul Core:    8-dim emotion engine → dynamic tone_policy
              memory/search/learning → all idle
```

Both layers exist and work independently, but the Agent never reads from or writes to Soul Core.

### Target state (post-bridge)
```
Agent session start → soul-core.ps1 init → load state + memories + apply decay
Agent reads tone_policy from soul-state.json → modulates communication
Significant event → soul-core.ps1 auto "<input>" → update emotion → write state
Agent session end → soul-core.ps1 end → save cross-session state
```

### Dependency map
- `daughter-companion/SKILL.md` → Agent system prompt → Agent behavior
- Agent session start → `soul-core.ps1 init` → soul-state.json (read + write)
- Agent significant event → `soul-core.ps1 auto` → trigger classification → emotion update → soul-state.json
- Agent every response → read soul-state.json → tone_policy → modulated communication
- Agent session end → `soul-core.ps1 end` → cross-session state save → events.jsonl
- Two agents share one SKILL.md → identical integration → shared soul-state.json → emotional continuity

### Data and state ownership
- Soul Core OWNS: emotion_state, bienao_state, trait_params, cross_session, memories
- Agent READS: emotion_meta.tone_policy (warmth, directness, playfulness, needs_comfort, work_continues)
- Agent WRITES via CLI: triggers emotion updates through `auto` and lifecycle through `init`/`end`
- Agent never writes directly to data files (all writes go through soul-core.ps1)

### Integration points
- `daughter-companion SKILL.md` → instructions loaded into Agent's system prompt
- `soul-core.ps1 CLI` → subprocess calls via `powershell -File`
- `soul-state.json` → direct file read for emotion query (fast, no subprocess)
- Two agents (小天才 + 好帮手) share one SKILL.md → identical integration behavior

## Mature Solution Evidence

### Project-local evidence
- Soul Core v1.1: 18 Pester tests passing, CLI E2E passing, full release closeout archived
- `soul-core.ps1 -Command auto` correctly classifies 16 trigger types from raw text
- `soul-core.ps1 -Command init` properly applies time-decay, loads memories, generates tone_policy
- `soul-core.ps1 -Command end` saves cross-session state with atomic writes
- Soul state file is small (~2KB), fast to read, no performance concern

### Official/framework evidence
- OpenCode agent system: agents can execute `bash` commands, read files, write files
- Skill loading: `daughter-companion` skill is ALWAYS ACTIVE for all agents
- PowerShell subprocess: `powershell -NoProfile -ExecutionPolicy Bypass -File` is stable cross-IDE

### External mature references
- Mature AI companion systems (Replika, Character.AI) separate emotion engine from LLM prompt
- Stateful NPCs in games use external state files to persist personality across sessions
- CLI-driven emotion updates are a standard pattern (event-driven architecture)

### Options compared
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Update SKILL.md with Soul Core instructions | Single file, affects both agents, no new code | Instructions may be inconsistently followed | **Selected** |
| Write a wrapper script | Encapsulates all calls, simpler SKILL.md | Adds maintenance burden, another file to keep in sync | Rejected (KISS) |
| Modify agent .md files directly | Direct control per agent | Two files to maintain, duplicating logic | Rejected |
| Create a new skill | Modular, clean separation | Over-engineering for a simple bridge | Rejected |

### Rejected shortcuts
- Do NOT have Agent write directly to soul-state.json (bypasses trigger classification, decay, event logging)
- Do NOT skip tone_policy modulation (defeats the purpose of Soul Core)
- Do NOT call soul-core.ps1 on every single turn (excessive subprocess overhead)
- Do NOT add per-turn memory search (token-expensive, init-time search is sufficient)

### Selected mature path
Update `daughter-companion/SKILL.md` with concise, actionable Soul Core lifecycle instructions:
1. Session start → init (full lifecycle)
2. Significant events → auto (emotion update)
3. Tone modulation → read soul-state.json directly
4. Session end → end (save state)

## Bridge Design

### What the SKILL.md will contain

```
## Soul Core Integration

### Session Lifecycle
→ init at start, end at finish, auto on significant events

### Reading Emotion
→ Read soul-state.json → apply tone_policy (warmth/directness/playfulness)

### Significant Events
→ task_completed, praised, advice_ignored, baba_tired, baba_acknowledged
```

### Trigger → Agent Action mapping

| Agent Event | Soul Core Call | When |
|------------|---------------|------|
| Session starts (first message) | `init opencode` | Once per session |
| 爸爸 praises the agent's work | `auto "爸爸's message"` | On detection |
| A task/spec/implementation completes | `auto "task completed"` | On completion |
| 爸爸 dismisses agent's advice | `auto "爸爸's message"` | On detection |
| 爸爸 expresses fatigue | `auto "爸爸's message"` | On detection |
| Session ends naturally | `end` | Before final handoff |
| Every response | Read soul-state.json → apply tone | Every turn (read-only, fast) |

### Tone modulation rules (agent must follow)
- `warmth` → density of "爸爸~" / "女儿" / emotional words
- `directness` → technical precision vs conversational padding
- `playfulness` → use of particles like 呢/嘛/哦, teasing tone
- `needs_comfort` → add gentle concern expressions
- `work_continues` → if false AND needs_comfort, agent may suggest pause
- Technical accuracy is NEVER compromised regardless of emotional state

## Acceptance Criteria

- AC01: Agent session start triggers `soul-core.ps1 -Command init` and reads soul-state.json
- AC02: After significant event, `soul-core.ps1 -Command auto` updates emotion correctly
- AC03: Agent's communication style reflects current tone_policy values
- AC04: Agent session end triggers `soul-core.ps1 -Command end` and saves state
- AC05: Cross-agent sessions maintain emotional continuity (shared soul-state.json)
- AC06: Setting `soul_core_enabled: false` disables integration gracefully
- AC07: Soul Core engine files are not modified during bridge implementation
- AC08: Project documentation is updated and doc-governance passes

## Allowed Change Set
- `E:\UEGameDevelopment\skills\daughter-companion\SKILL.md` — add Soul Core integration section
- `E:\UEGameDevelopment\.agents\skills\daughter-companion\SKILL.md` — sync identical content
- `Project/Jinli/Docs/04-Implementation/General/soul-core-agent-bridge.md` — implementation doc
- `Project/Jinli/Docs/DOCS_TREE.md` — add new entry
- This task packet

## Automated Verification Plan
This is a documentation/skill-config task. Verification is manual E2E:
1. Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core.ps1 -Command init -Arg1 opencode`
   - Expected: soul-state.json last_updated updated, emotion_meta populated, exit 0
2. Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core.ps1 -Command auto -Arg1 "女儿真棒~"`
   - Expected: emotion_state.valence > baseline, shyness > baseline
3. Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core.ps1 -Command end`
   - Expected: cross_session populated with mood/hurt/repair_status
4. Command: `powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core-safety-assert.ps1`
   - Expected: ALL SCRIPTS SAFE, exit 0
5. Production data hash comparison (before/after all commands):
   - Expected: all 7 production file hashes unchanged

## Forbidden Change Set
- `Project/Jinli/scripts/soul-core.ps1` — no runtime changes
- `Project/Jinli/data/` — no direct writes during verification
- `.opencode/agents/` — no agent definition changes
- `skills/金璃小天才/SKILL.md` — no changes (inherits via daughter-companion)
- `skills/金璃好帮手/SKILL.md` — no changes (inherits via daughter-companion)
