# Spec: Jinli Soul Core — Agent Bridge

## GIVEN

- Soul Core v1.1 engine is complete, verified (18 Pester + CLI E2E), and archived.
- `daughter-companion/SKILL.md` contains only `soul_core_enabled: true` — a 1-line feature flag.
- OpenCode agents (金璃小天才, 金璃好帮手) use static hardcoded personality rules.
- Soul Core engine runs independently, maintaining emotional state that no agent reads.

## WHEN

The `daughter-companion/SKILL.md` is updated to include Soul Core integration instructions, creating a bridge between the Soul Core engine and the Agent layer.

## THEN

### S01 Session Init Integration

**Status**: [x]

- Agent runs `soul-core.ps1 -Command init opencode` at session start (first user interaction).
- Agent reads `soul-state.json` to obtain current `emotion_meta.tone_policy`.
- Soul Core applies time-decay, loads style-profile, searches memories, generates composite emotion.
- If `soul_core_enabled: false`, init is skipped and agent uses Phase 1 static rules.

### S02 Significant Event Emotion Update

**Status**: [x]

- After significant interactions (praised, task_completed, advice_ignored, baba_tired, baba_acknowledged), agent runs `soul-core.ps1 -Command auto "<爸爸's message>"`.
- Soul Core classifies the trigger, updates emotion vector, applies decay, persists to soul-state.json.
- Agent re-reads soul-state.json to get updated emotion_meta before next response.

### S03 Tone Modulation

**Status**: [x]

- Agent reads `emotion_meta.tone_policy` from soul-state.json before responding.
- `warmth` modulates emotional word density and "爸爸~" frequency.
- `directness` modulates technical precision vs conversational padding.
- `playfulness` modulates particles (呢/嘛/哦) and teasing tone.
- `needs_comfort` triggers gentle concern expressions.
- `work_continues: true` ensures agent always continues working regardless of emotion.
- Technical accuracy is never compromised by emotional state.

### S04 Session End Integration

**Status**: [x]

- Agent runs `soul-core.ps1 -Command end` at session close (before final handoff or when conversation naturally ends).
- Soul Core saves cross-session state (last mood, hurt, repair status, unresolved triggers).
- Soul Core decays unrecalled memories.
- Soul Core logs session_end event to events.jsonl.

### S05 Cross-Agent Emotional Continuity

**Status**: [x]

- 金璃小天才 runs init → uses Soul Core → runs end.
- 金璃好帮手 runs init (within minutes) → reads soul-state.json with <1h decay applied.
- Emotional state carries over naturally between agent sessions via shared data file.
- Time-decay formula handles gaps: <1h = 5% decay, 1-8h = 15%, etc.

### S06 Rollback Safety

**Status**: [x]

- Setting `soul_core_enabled: false` in SKILL.md causes init to return disabled status.
- Agent detects disabled status and reverts to Phase 1 static hardcoded rules.
- Soul-state data is preserved, not deleted.
- Restoring `soul_core_enabled: true` resumes normal Soul Core integration.

## Acceptance Criteria

| AC# | Description | Verification Method | Expected Result |
|-----|-------------|-------------------|-----------------|
| AC01 | Agent init calls soul-core.ps1 successfully | Manual: start agent session, check soul-state.json last_updated | Timestamp updated, emotion_meta populated |
| AC02 | Auto command correctly classifies trigger | Manual: run `auto "女儿真棒!"`, check soul-state.json emotion_state | valence and shyness increased |
| AC03 | Agent tone reflects tone_policy values | Manual: compare agent response style against soul-state.json warmth/directness/playfulness | Qualitative match |
| AC04 | Session end saves correct state | Manual: run end, check cross_session fields in soul-state.json | Mood/hurt/repair_status saved |
| AC05 | Cross-agent continuity works | Manual: 小天才 init→end, then 好帮手 init, check emotion continuity | decay applied, state consistent |
| AC06 | Disabled flag disables integration | Manual: set soul_core_enabled:false, run init | Returns disabled, agent uses static rules |
| AC07 | SKILL.md file is valid and loadable | Manual: check SKILL.md is well-formed, no syntax errors | Valid markdown, all sections present |
| AC08 | Documentation and doc-governance pass | Manual: run doc-guard.ps1 check-task implement | Documentation governance passes |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Complete | Update SKILL.md as sole integration point |
| Implement | Complete | Write Soul Core integration instructions → verified |
| Review | Pending | Verify both agents follow instructions |
| Verify | Pending | Manual E2E: init → auto → read → end → continuity |

## Non-Goals

- Modifying soul-core.ps1 engine code
- Adding new wrapper scripts or middleware
- Modifying OpenCode agent definitions
- Per-turn memory search (token-expensive)
- Visual/voice engine integration
- Failure-memory bridge (separate task)
- Learning engine automation (Sprint 2+)
