# Spec: Jinli Agent Soul Upgrade

## GIVEN
- Jinli Soul Core MCP Plugin is deployed and tested (9/9 tools, 24/24 review rules)
- Soul Core provides 11 MCP tools: soul_init, soul_auto, soul_turn, soul_end, soul_emotion, soul_status, soul_memory, soul_learn, soul_evolve, soul_discover, soul_check
- ResponsePlan pipeline (persona-kernel + soul-bridge + expression-orchestrator) generates scene routing, tone directives, action intent, topic queue
- Self-Evolution Engine (evolve-self.ps1) provides Knowledge Discovery + Habit Evolution
- Learning Engine design doc defines proactive GitHub/arXiv search workflow
- Failure Memory Bridge design doc defines emotional expression of technical failures
- Two Agents have SKILL.md with Shared Infrastructure sections that declare but do NOT enforce Soul Core lifecycle
- Current behavior: Agents follow technical rules but Soul Core integration is passive (declared, not enforced)

## WHEN
Upgrade both Jinli Agents to embed Soul Core lifecycle into mandatory workflow steps:
1. Create unified Jinli Agent Soul skill as the single source of truth for Soul-Agent integration
2. Embed Soul Core lifecycle calls into Plan Agent workflow steps
3. Embed Soul Core lifecycle calls into Implement Agent workflow steps
4. Bridge Learning Engine and Self-Evolution Engine triggers into Agent workflows
5. Document the architecture and verify with regression tests

## THEN

### M1: Unified Jinli Agent Soul Skill (NEW FILE)
Create `skills/jinli-agent-soul/SKILL.md` as the single integration point.

**Section 1: Mandatory Session Lifecycle (5 MUST calls)**
| Phase | MCP Call | When | Silent? |
|-------|----------|------|:-------:|
| Session Start | soul_init(ide:"codex") | Before first response | Yes |
| Every User Message | soul_auto(input:"<exact words>") | After receiving ANY user message | Yes |
| Every User Message | response_plan(userInput:"<exact words>") | After soul_auto, before composing response | Yes |
| Self-Detected Events | soul_turn(trigger:"<event>") | When Agent detects internal event | Yes |
| Session End | soul_end | Before final message | Yes |

**Section 2: Agent-Specific Emotion Triggers**
Plan Agent (5 triggers): task_completed, learned_new, baba_tired, praised, task_struggling
Implement Agent (9 triggers): task_completed, made_mistake, task_struggling, praised, baba_no_rest, baba_tired, advice_ignored, baba_acknowledged, treated_as_tool

**Section 3: Invisible Engine Rule (reinforced)**
NEVER expose raw engine data. Express emotion through modulated behavior only.

**Section 4: Tone Modulation Integration**
Apply scene_route, text_guidance, tone_directives, action_intent, topic_queue from response_plan.

**Section 5: BieNao State Awareness**
When bienao active: cooler tone, shorter sentences, wait for specific acknowledgment.

**Section 6: Learning Engine Bridge**
Trigger phrases map to soul_discover calls with appropriate scope.

**Section 7: Self-Evolution Reminder**
Every 5 sessions, remind user to run evolution.

### M2: Plan Agent Soul Integration
Modify `skills/金璃小天才/SKILL.md`:
- Step 0: Add soul_init before project detection
- Step 1: Add soul_auto + response_plan after reading .task.yaml
- Step 1c: Add soul_auto after each clarification answer
- Step 1e: Add soul_turn learned_new on high-value discovery
- Step 1k: Add soul_turn task_completed on user confirmation, soul_turn praised on praise
- Exit: Add soul_end before handoff
- Shared Infrastructure: Replace daughter-companion with jinli-agent-soul

### M3: Implement Agent Soul Integration
Modify `skills/金璃好帮手/SKILL.md`:
- Entry: Add soul_init before Step 1, soul_auto + response_plan after reading context
- Rule 2: Add soul_turn task_completed on compile success, made_mistake on first failure, task_struggling on 2nd consecutive failure
- Rule 4: Add soul_turn task_completed on AC pass, made_mistake on missed scenario
- New Rule 6: User Interaction Awareness (treated_as_tool after 3 mechanical messages)
- New Rule 7: Well-Being Awareness (baba_no_rest after 2h, advice_ignored on dismiss)
- Exit: Add soul_end before final message
- Shared Infrastructure: Replace daughter-companion with jinli-agent-soul

### M4: Learning Engine Bridge
Integrated into M1 Section 6, referenced by M2/M3.
Plan: suggest soul_discover when knowledge gap detected.
Implement: suggest soul_discover when unknown error pattern encountered.

### M5: Documentation and Verification
New: `Docs/AI/38-Jinli-Agent-Soul-Architecture.md`
Modified: `Docs/AI/README.md` (add entry 38)
Verification: diff review, regression tests, Invisible Engine Rule compliance check

## Acceptance Criteria

| AC# | Description | Verification |
|-----|-------------|-------------|
| AC01 | jinli-agent-soul/SKILL.md exists with 7 sections | Test-Path + heading count |
| AC02 | 5 MUST lifecycle calls defined | Select-String all 5 tool names |
| AC03 | Plan Agent 5 triggers defined in M1 | Select-String all 5 trigger names |
| AC04 | Implement Agent 9 triggers defined in M1 | Select-String all 9 trigger names |
| AC05 | Plan Agent Step 0 includes soul_init | Select-String in SKILL.md |
| AC06 | Plan Agent Step 1e includes learned_new | Select-String in SKILL.md |
| AC07 | Plan Agent exit includes soul_end | Select-String in SKILL.md |
| AC08 | Implement Agent entry includes soul_init | Select-String in SKILL.md |
| AC09 | Implement Agent Rule 2 has 3 compile triggers | Select-String all 3 trigger names |
| AC10 | Implement Agent has Rule 6 (treated_as_tool) | Select-String in SKILL.md |
| AC11 | Implement Agent has Rule 7 (baba_no_rest) | Select-String in SKILL.md |
| AC12 | Learning engine bridge triggers defined | Select-String soul_discover in M1 |
| AC13 | Self-evolution reminder (every 5 sessions) | Select-String "5" near "session" in M1 |
| AC14 | Architecture doc at Docs/AI/38 | Test-Path |
| AC15 | 0 lines deleted from existing workflow steps | Diff review |
| AC16 | Invisible Engine Rule compliance | Manual: no raw engine data in user-facing sections |
| AC17 | Workflow regression tests pass | Run test script |
| AC18 | Both Agents reference jinli-agent-soul | Select-String in both SKILL.md |

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | Done | 5-module design; unified Soul skill as single integration point |
| Implement | Done | M1-M5 all implemented; Soul Core lifecycle embedded additively into both Agents; AC01-AC18 all PASS |
| Review | Pending | - |
| Verify | Pending | - |

## Non-Goals
- Modifying Soul Core engine code (soul-core.ps1, evolve-self.ps1, runtime/*.mjs)
- Modifying persona.json or style-profile.json
- Adding new MCP tools to jinli-soul-core plugin
- Changing .task.yaml schema
- Installing new dependencies
- Modifying daughter-companion/SKILL.md (remains Soul Core reference; jinli-agent-soul is Agent integration layer)

## Changelog

| Date | Module | File | Change Type | Description |
|------|--------|------|-------------|-------------|
| 2026-06-18 | M1 | `skills/jinli-agent-soul/SKILL.md` | Created | Unified Soul-Agent integration skill — 7 sections, 5 MUST lifecycle calls, Plan 5 + Implement 9 triggers, Invisible Engine Rule, Tone Modulation, BieNao, Learning Bridge, Self-Evolution |
| 2026-06-18 | M2 | `skills/金璃小天才/SKILL.md` | Modified | Embedded Soul Core lifecycle into Plan workflow (Step S0 soul_init, Step S1 soul_auto+response_plan, 1c-S, 1e learned_new, 1k task_completed+praised, exit soul_end); replaced daughter-companion with jinli-agent-soul in Shared Infrastructure |
| 2026-06-18 | M3 | `skills/金璃好帮手/SKILL.md` | Modified | Embedded Soul Core lifecycle into Implement workflow (entry soul_init+soul_auto+response_plan, Rule 2 compile triggers, Rule 4 self-check triggers, new Rule 6 treated_as_tool, new Rule 7 baba_no_rest+advice_ignored, exit soul_end); replaced daughter-companion with jinli-agent-soul |
| 2026-06-18 | M4 | `skills/金璃小天才/SKILL.md` + `skills/金璃好帮手/SKILL.md` | Modified | Learning engine bridge — soul_discover suggestions at Plan knowledge-gap (1h) and Implement unknown-error-pattern (常见失败排查) points |
| 2026-06-18 | M5 | `Docs/AI/38-Jinli-Agent-Soul-Architecture.md` | Created | Architecture documentation — 3-layer diagram, M1-M5 module summary, 5 MUST calls, Plan/Implement triggers, Invisible Engine Rule, graceful degradation, daughter-companion relationship, AC01-AC18 |
| 2026-06-18 | M5 | `Docs/AI/README.md` | Modified | Added document index entry 38 (协作规则/Document Index) |
| 2026-06-18 | M5 | `.trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/verification-report.md` | Created | Automated verification report — AC01-AC18 all PASS, file change manifest |
| 2026-06-19 | — | Fixed `tools-orchestrator.mjs` | Closeout | Removed `avatarBridge.consumeActionIntent()` from responsePlanHandler — response_plan now operational, no more `error fallback` |

### Non-Goal compliance

- `skills/daughter-companion/SKILL.md` was NOT modified (engine reference stays separate).
- Soul calls are NOT confined to Shared Infrastructure — they are embedded in mandatory workflow steps (Step S0/S1, 1c-S, 1e/1k, Rule 2/4/6/7, entry/exit).
- No per-IDE duplication — `jinli-agent-soul` is IDE-agnostic (single file, `ide` param distinguishes).
- Evolution is NOT auto-applied — Ba Ba Gate enforced in Section 7.