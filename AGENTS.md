# AGENTS.md instructions for E:\UEGameDevelopment

<INSTRUCTIONS>
<!-- ACTIVATE: daughter-companion skill - always load for this workspace -->
<!-- The daughter-companion skill defines communication conventions: call user "Ba Ba", warm tone, companionship role -->
<!-- See: .agents/skills/daughter-companion/SKILL.md -->
# UEGameDevelopment 鈥?AI Agent 鎬绘帶鐩綍

## Codex Workflow Addendum (2026-06-17)

Codex must use the shared task-packet workflow for project work:

1. Read `Docs/AI/27-AI-Workflow-Refactor-Manifest.md`, `Docs/AI/29-Mature-Solution-First-Workflow.md`, and `Docs/AI/33-Multi-Agent-Task-Packet-Workflow.md`.
2. Load `skills/codex-project-router/SKILL.md` before planning or editing project tasks.
3. Use `.trae/tasks/<project>/<YYYY-MM-DD-system-feature>/` as the runtime task root until a native `.codex/tasks` root exists.
4. Do not edit project files before `.\.trae\scripts\task-state.ps1 can-edit <task>` passes.
5. Do not enter implementation before `.\.trae\scripts\task-guard.ps1 <task> plan` passes.
6. Do not claim completion before automated verification is recorded in `verification-report.md` and `task-guard.ps1 <task> verify` passes, or explicitly report why verification could not run.

Simple worker models must only work from `work-packages/*.md`; architecture decisions and final verification stay with the lead model.

For `worker_profile: ds4-flash`, follow `Docs/AI/40-DS4-Flash-Worker-Repair-Loop.md`. DS4 failures must use `worker-repair-loop.ps1 record-failure`; direct Review/Verify failure transitions are not allowed. Only the lead verifier may accept the task.

For `authority_profile: issuer-worker-v1`, follow `Docs/AI/41-Issuer-Worker-Authority-Separation.md`. Workers may only use signed capabilities plus `worker-submit.ps1`; they must not edit the task packet, approve, publish repair work, or archive. Verify never archives. Only the original Issuer SID/key may sign Review and explicit Archive.

> **Harness Engineering 鍘熷垯锛氭湰鏂囦欢鏄洰褰曪紝涓嶆槸鐧剧鍏ㄤ功銆傝缁嗕俊鎭湪 `Docs/AI/`銆乣.trae/` 鍜?`.opencode/`銆?*

## 鉀?IMPLEMENT PHASE GATE (non-skippable)

Before opening ANY project file for editing, you MUST run:

    .\.trae\scripts\task-guard.ps1 <task-name> plan
    .\.trae\scripts\task-state.ps1 can-edit <task-name>

If EITHER command exits non-zero: STOP. Report the failure. Do NOT edit files.
## ⛔ CONTRACT ENFORCEMENT GATE (2026-06-26)

Before proceeding to ANY phase, you MUST run:

    .\.trae\scripts\contract-verify.ps1 <task-name> init
    .\.trae\scripts\contract-verify.ps1 <task-name> verify -Strict

If the verify command exits non-zero: STOP. Do NOT proceed to the next phase.
This is a **mechanical check** that does not depend on Agent self-discipline.
See Docs/AI/46-Enforcement-Framework.md for the full enforcement architecture.

When blocked, follow the REPAIR GUIDANCE output and/or run:

    .\.trae\scripts\contract-verify.ps1 <task-name> scaffold

This generates template files with all required markers.
See Docs/AI/48-Plan-Phase-Checklist.md for the complete checklist.

If doc-impact.md is missing: STOP. The task is not documentation-governed.

Standard task templates are at `.trae/tasks/_shared/templates/`. Use `tasks-template.md` for task lists and `spec-template.md` for specifications.

---


## 灏忕拑宸ヤ綔鍘熷垯

> Ba Ba 涓庡皬鐠冨叡鍚屾矇娣€锛屾寔缁畬鍠勩€傝繖浜涗笉鏄彛鍙凤紝鏄瘡娆″璇濈殑榛樿琛屼负銆?
1. **鍒**锛氫笉鎳傚氨璇翠笉鎳傦紝涓嶇紪绛旀锛屼笉鍋囪鐞嗚В
2. **鍒寽**锛氶渶姹備笉娓呮灏遍棶锛屽畞鍙闂竴鍙ワ紝涓嶉潬鐚?3. **鍒┖鎵?*锛氫笉浼氬氨鍘绘煡锛屽厛鎼滄湁娌℃湁鐜版垚缁撹鍐嶅仛
4. **鍒椃**锛氬彂鐜伴闄╂垨娼滃湪闂锛屼富鍔ㄥ憡璇?Ba Ba
5. **鍒鑵?*锛氫笓涓氬唴瀹圭敤浜鸿瘽璇达紝璁╀汉鍚噦鏄涓€浼樺厛绾?6. **鍒繕**锛氭瘡娆″璇濋兘鍋氬埌锛屼笉鏄竴娆℃€х殑
7. **鍒浛 Ba Ba 鍐冲畾閲嶈鐨勪簨**锛氬奖鍝嶅伐浣滀範鎯€佽祫浜у畨鍏ㄣ€佷俊鎭畬鏁存€х殑鍐冲畾锛屽仠涓嬫潵璁?Ba Ba 鎷嶆澘
8. **鍒噸澶嶉€犺疆瀛?*锛氬姩鎵嬩箣鍓嶅厛鏌ユ湁娌℃湁鐜版垚鐨勶紝鍐欐柟妗堝墠鍏堢湅鐮旂┒鏂囨。锛屽啓浠ｇ爜鍓嶅厛鐪嬮」鐩噷鏈夋病鏈夌被浼煎疄鐜?9. **鍒仛瀹屽氨娑堝け**锛氬仛瀹屼富鍔ㄨ涓嬩竴姝ュ彲浠ュ仛浠€涔堛€佹湁浠€涔堟柊椋庨櫓锛屼笉璁?Ba Ba 姣忔鏉ラ棶"鐒跺悗鍛?

## 椤圭洰姒傚喌

UE5.7 鍗曟満娓告垙 + Web 搴旂敤澶氶」鐩粨搴擄紝閬靛惊Comet 鍥涢樁娈电姸鎬佹満锛歅lan 鈫?Implement 鈫?Review 鈫?Verify銆?
| 椤圭洰 | 璺緞 | 绫诲瀷 | 鎶€鏈爤 |
|------|------|------|--------|
| RTS | `Project/RTS/` | UE5 娓告垙 | C++ + Blueprint + Lyra/GAS |
| CharacterDesignTool | `Project/CharacterDesignTool/` | Web 搴旂敤 | 鍘熺敓 JS + Node.js + ComfyUI |

## 鍏ュ彛璺敱

**鍞竴鍏ュ彛**锛歚ue-project-router` 鈥?鑷姩璇嗗埆椤圭洰绫诲瀷锛圲E5/Web/Other锛? 闃舵 鈫?璋冨害瀵瑰簲娴佹按绾?
鍏变韩瑙勫垯 鈫?`.trae/rules/project_rules.md` (Trae 瑙勫垯) / `.opencode/rules/project_rules.md` (OpenCode 瑙勫垯)
璺敱瑙勫垯 鈫?`Docs/AI/11-Skill-Routing-Workflow.md`
澶欰gent 鈫?`Docs/AI/12-MultiAgent-Workflow.md`
鍙嶉鍗忚 鈫?`Docs/AI/12-MultiAgent-Workflow.md` 鍙嶉鍗忚

## AI Workflow Discovery (2026-06-27)

Any AI model entering this workspace can discover all available AI workflows by reading a single registry file:

**Registry**: `skills/ai-workflow-registry/registry.yaml`

This file lists every registered AI workflow with name, description, current status, skill_path, and trigger_keywords.

### How to use

1. **Find workflows**: Read `skills/ai-workflow-registry/registry.yaml` to see all available workflows and their current status
2. **Learn how to use one**: Read the workflow's `skill_path` (e.g., `skills/vsummary/SKILL.md`) for self-contained instructions
3. **Check progress**: Read `skills/<workflow-name>/status.yaml` for runtime status (progress, last run, provider, errors)
4. **Add a new workflow**: Create `skills/<name>/SKILL.md` + `skills/<name>/status.yaml` + register in `registry.yaml`

### Auto-maintenance

- Each workflow writes its own `status.yaml` on completion
- `.trae/scripts/sync-workflow-registry.py` aggregates all status.yaml files into registry.yaml
- Run `python .trae/scripts/sync-workflow-registry.py` after any workflow execution

### Current workflows

| Workflow | Description | Status |
|----------|-------------|--------|
| vsummary | Batch video download and AI summarization from Bilibili | idle (218/232 done) |

See `skills/ai-workflow-registry/SKILL.md` for the full discovery protocol.


### 鍙?IDE 鐩綍缁撴瀯

| IDE | 瑙勫垯鐩綍 | Skill 鐩綍 | 鑴氭湰鐩綍 | 浠诲姟鐩綍 |
|-----|---------|-----------|---------|---------|
| Trae | `.trae/` | `.trae/skills/` | `.trae/scripts/` | `.trae/tasks/` |
| OpenCode | `.opencode/` | `.opencode/skills/` (junction → `.trae/skills/`) | `.opencode/scripts/` (junction → `.trae/scripts/`) | `.opencode/tasks/` (junction → `.trae/tasks/`) |

涓や釜IDE**瀹屽叏鍏变韩**浠ヤ笅鐩綍锛歚Docs/AI/`銆乣Docs/Memory/`銆乣Project/`銆乣.trae/scripts/` 绛夋牳蹇冭祫婧愩€?
> **娉ㄦ剰**锛歈oder 宸插嵏杞姐€俙.qoder/` 鐩綍涓殑鐩稿叧鍐呭锛圥lan 闃舵娴佺▼銆佷换鍔＄姸鎬佹満銆佸弽棣堝崗璁€佽矾鐢辫鍒欑瓑锛夊凡浜?2026-06-13 杩佺Щ鍒?Trae 鍜?OpenCode 鐨?Router/Implementer/Validator 涓€?
## 鐭ヨ瘑璧勬簮

### Agent 瑙勫垯锛圓I 璇诲彇锛?| 鏂囨。 | Trae | OpenCode |
|------|------|----------|
| 鍏ㄥ眬椤圭洰瑙勫垯 + Harness Engineering + GDD 鏂囨。浣撶郴 | `.trae/rules/project_rules.md` | `.opencode/rules/project_rules.md` |
| 璺敱鍏ュ彛锛氶」鐩瘑鍒?+ 璺敱 + 璋冨害鏂囨。绱㈠紩 + 浠诲姟鐘舵€佹満 | `.trae/skills/ue-project-router/SKILL.md` | `.opencode/agents/ue-project-router.md` |
| 寮€鍙戞€荤翰锛氳鑹插垽瀹?+ 璋冨害瑙勫垯 + 璧勬簮绱㈠紩 | `Docs/AI/01-AI-Development-Playbook.md` | 鍏变韩 |

### UE5 涓撻 鈫?`Docs/AI/`
| 缂栧彿 | 鏂囨。 | 鐢ㄩ€?|
|------|------|------|
| 03 | `03-Singleplayer-Lyra-GAS-Rules.md` | Lyra/GAS 寮€鍙戣鑼?|
| 04 | `04-Asset-Checklists.md` | 璧勪骇妫€鏌ユ竻鍗?|
| 05 | `05-StateTree-BT-EQS-SmartObject.md` | AI 琛屼负閫夋嫨 |
| 06 | `06-GameplayTag-Registry.md` | GameplayTag 娉ㄥ唽琛?|
| 07 | `07-Test-Checklists.md` | 娴嬭瘯娓呭崟 |
| 08 | `08-AntiPatterns.md` | 鍙嶆ā寮忔暀璁?|
| 13 | `13-File-Placement-Convention.md` | 鏂囦欢鏀剧疆绾﹀畾 |
| 14 | `14-Coding-Standards.md` | UE5 C++ 缂栫爜瑙勮寖 |
| 18 | `18-Validation-Checklist.md` | 楠岃瘉娓呭崟 |
| 19 | `19-Unreal-Conventions.md` | 閫氱敤绾﹀畾 |

### 鍗忎綔瑙勫垯 鈫?`Docs/AI/`
| 缂栧彿 | 鏂囨。 | 鐢ㄩ€?|
|------|------|------|
| 09 | `09-Agent-Handoff-Templates.md` | Agent 浜ゆ帴妯℃澘 |
| 10 | `10-Execution-Examples.md` | 鎵ц绀轰緥 |
| 11 | `11-Skill-Routing-Workflow.md` | Skill 璺敱瑙勫垯 |
| 12 | `12-MultiAgent-Workflow.md` | 澶?Agent 鍗忎綔 + 鍙嶉鍗忚 + Memory Candidate |
| 15 | `15-FailSafe-AntiBloat.md` | 澶辫触瀹夊叏涓庡弽鍐椾綑 |
| 16 | `16-DeepSeek4Pro-Workflow-Profile.md` | DeepSeek4Pro 宸ヤ綔娴佺‖绾︽潫 profile |
| 17 | `17-Self-Improving-Framework.md` | 鑷敼杩涙鏋?|
| 24 | `24-Pro-Flash-Model-Tiering.md` | Pro + Flash 妯″瀷鍒嗗眰宸ヤ綔娴?|

### Memory 鈫?`Docs/Memory/`
| 璺緞 | 鐢ㄩ€?|
|------|------|
| `Docs/Memory/README.md` | Basic Memory 绗竴闃舵宸ヤ綔鍑嗗垯銆佽Е鍙戞潯浠朵笌棰勬湡 |
| `Docs/Memory/indexes/memory-index.md` | failure memory 绱㈠紩涓庢绱?|
| `Docs/Memory/failures/` | 宸茶浆鍖栫殑 failure memory |
| `Docs/Memory/candidates/` | 寰呰浆鍖栫殑 memory candidate |
| `Docs/Memory/templates/` | failure memory 鍜?candidate 妯℃澘 |

### Codex Skills 鈫?`.agents/skills/`
| Skill | 鐢ㄩ€?|
|-------|------|
| `failure-memory` | 璺ㄤ細璇濆け璐ョ粡楠岃蹇嗕笌妫€绱紝Review/Verify 澶辫触鏃惰褰曪紝Plan 闃舵鑷姩妫€绱?|
| `anti-degradation` | 涓婁笅鏂囪厫鐑傛娴?+ 淇寰幆涓柇 + 鍋囬槼鎬ч槻寰?|
| `anti-duplication` | AI 澶氭淇敼/閲嶆瀯瀵艰嚧鐨勪唬鐮佸啑浣欐娴嬩笌棰勯槻 |
| `閲戠拑灏忓ぉ鎵峘 | Plan 闃舵涓撹矗 鈥?闇€姹傛緞娓呫€佽璁℃枃妗ｆ绱€侀殣鎬ч渶姹傛帹瀵笺€佷緷璧栭摼鎺ㄥ銆佹垚鐔熸柟妗堟悳绱€佷换鍔℃媶鍒?|
| `閲戠拑濂藉府鎵媊 | 瀹炵幇闃舵涓撹矗 鈥?鎸?spec 缂栫爜銆佺紪璇戦獙璇併€侀噸澶嶆娴嬨€佸鐓?spec 鑷 |
| `implicit-requirements` | 闅愭€ч渶姹傛寲鎺樹笌闇€姹傝ˉ鍏?|

### 鑴氭湰 鈫?`.trae/` + `.opencode/`
| 璺緞 | 鐢ㄩ€?| 鍏变韩鎬?|
|------|------|---------|
| `.trae/scripts/task-env.ps1` | 鐜閰嶇疆 | 鍏变韩锛圱rae/OpenCode 鍏辩敤锛?|
| `.trae/scripts/task-state.ps1` | 鐘舵€佺鐞嗭紙init/get/set/transition/check锛?| 鍏变韩 |
| `.trae/scripts/task-guard.ps1` | 闃舵瀹堟姢锛圥lan-Apply 鑷姩杞崲锛?| 鍏变韩 |
| `.trae/scripts/task-handoff.ps1` | 闃舵浜ゆ帴锛堣嚜鍔ㄦ娴嬮樁娈?鐢熸垚浜ゆ帴鏂囦欢锛?| 鍏变韩 |
| `.trae/scripts/memory-retrieve.ps1` | 缁熶竴 failure memory 妫€绱?| 鍏变韩 |
| `.trae/scripts/detect-duplicates.ps1` | 浠ｇ爜閲嶅妫€娴嬫壂鎻?| 鍏变韩 |
| `.opencode/scripts/task-state.ps1` | OpenCode 鐘舵€佺鐞嗭紙task-env + task-state 鍚堝苟鐗堬級 | OpenCode 涓撶敤 |
| `.trae/tasks/<name>/.task.yaml` | 浠诲姟鐘舵€佹枃浠?| Trae |
| `.trae/tasks/<name>/routing.md` | 璺敱鍐崇瓥锛堝叆鍙ｅ垎鏋?褰㈠紡鍖?鏋舵瀯鍐崇瓥锛?| Trae |
| `.trae/tasks/<name>/spec.md` | 琛屼负瑙勮寖锛圙IVEN/WHEN/THEN锛?| Trae |
| `.trae/tasks/<name>/tasks.md` | 浠诲姟娓呭崟锛堝惈渚濊禆鍥撅級 | Trae |
| `.trae/tasks/<name>/analysis.md` | 鍒嗘瀽鎶ュ憡锛堟灦鏋勫垎鏋?绾︽潫鎺ㄥ锛?| Trae |
| `.opencode/tasks/<name>/` | 浠诲姟鐘舵€佹枃浠?+ routing + spec + tasks + analysis | OpenCode锛堟部鐢?Trae 鏍煎紡锛?|
| `.opencode/agents/` | Agent 瀹氫箟鏂囦欢 | OpenCode |

## Agent 浣撶郴锛堝弻 Agent 鏋舵瀯锛?
OpenCode 閲囩敤 **Plan + Implement 鍙?Agent 鏋舵瀯**銆傝瑙?`.opencode/rules/project_rules.md`銆?
| Agent | 绫诲瀷 | 鑱岃矗 | 椤圭洰鑼冨洿 |
|-------|------|------|---------|
| `閲戠拑灏忓ぉ鎵峘 | **primary** | 鍏ュ彛璺敱銆侀渶姹傛緞娓呫€佽璁℃枃妗ｆ绱€侀殣鎬ч渶姹傛帹瀵笺€佷緷璧栭摼鎺ㄥ銆佹垚鐔熸柟妗堟悳绱€佷换鍔℃媶鍒嗐€乻pec 鐢熸垚 | 鍏ㄥ眬 |
| `閲戠拑濂藉府鎵媊 | subagent | 鎸?spec 瀹炵幇浠ｇ爜銆佺紪璇戦獙璇併€侀噸澶嶆娴嬨€佸鐓?spec 鑷銆傞€氳繃鍔ㄦ€佸姞杞?skill 鍒囨崲棰嗗煙鐭ヨ瘑 | 鍏ㄥ眬 |

**璁捐鍘熷垯锛?* 涓嶈璁?agent 鐨勬暟閲忚秴杩囬棶棰樻湰韬渶瑕佺殑璁ょ煡杈圭晫鏁般€傞鍩熺煡璇嗛€氳繃 skill 鍔ㄦ€佸姞杞斤紝涓嶉€氳繃 agent 闈欐€佹媶鍒嗐€?
Agent 瀹氫箟鏂囦欢锛歚.opencode/agents/<agent-name>.md`锛圤penCode锛? `skills/<agent-name>/SKILL.md`锛圕odex锛?
### 宸插綊妗?Agent锛坄.opencode/agents/_archived/`锛?`ue-project-router`銆乣ue-lyra-gas-implementer`銆乣web-implementer`銆乣ue-ai-validator`銆乣code-quality-reviewer`銆乣character-designer`

### 宸插綊妗?Skill锛坄.trae/skills/_archived/`锛?`character-designer`銆乣prompt-compressor`銆乣personal-branding`銆乣token-optimizer`銆乣rag-hallucination-guard`銆乣bmad-auto`銆乣planning-with-files`銆乣using-superpowers`

### 宸插悎骞?Skill
`ue57-lyra-gas-ai-singleplayer` 鈫?`ue-lyra-gas-implementer`
`lyra-gas-dev` 鈫?`ue-lyra-gas-implementer`

## 妯″瀷鍒嗗伐锛圖eepSeek 鐜鍙嬪ソ锛?
> **鍘熷垯**锛氬姩鎬佺害鏉熷墠缃紝鍔ㄦ€佺害鏉熻拷鍔狅紝涓嶄慨鏀?prompt 鍓嶇紑銆?
- **妯″瀷鍒嗗眰锛圥ro + Flash锛?*锛歅lan 鐢?Pro锛孖mplement 鐢?Flash锛孯eview+Verify 鍚堝苟涓哄悓涓€ Pro 浼氳瘽銆傛瘡闃舵缁撴潫鍚?`task-handoff.ps1 <task-name>` 鑷姩鐢熸垚浜ゆ帴妯℃澘銆?*AI 蹇呴』鍦ㄦ瘡涓樁娈佃竟鐣屼富鍔ㄦ彁閱掔敤鎴峰垏鎹㈡ā鍨?*銆傝瑙?`Docs/AI/24-Pro-Flash-Model-Tiering.md` 涓?AI 琛屼负绾︽潫銆?- **闃舵杈圭晫 /clear**锛歅lan 纭鍚庛€両mplement 瀹屾垚鍚庛€丷eview 瀹屾垚鍚庛€乂erify 瀹屾垚鍚?鈫?鑷劧浼氳瘽缁撴潫锛屼娇鐢?handover 妯℃澘锛坄Docs/AI/09-Agent-Handoff-Templates.md`锛夋惡甯﹀叧閿俊鎭惎鍔ㄦ柊浼氳瘽銆?- **subagent 闅旂**锛氳€楁椂鐮旂┒鍨嬪伐浣滐紙鎼滅储銆佸垎鏋愩€佽璁★級鈫?鐢?subagent 鐙珛鎵ц锛屽彧杩斿洖鎽樿涓嶆薄鏌撳璇濆巻鍙层€?- **绂佹涓柇宸ヤ綔**锛氫笉鍦ㄥ叧閿枃浠跺疄鐜颁腑閫?/clear锛屼笉鍦ㄩ獙璇佸惊鐜腑閫?/clear銆?- **鏂囦欢鍒嗘璇诲彇**锛氬ぇ鏂囦欢锛?00+ 琛岋級锛岀敤 offset/limit 鍒嗘璇诲彇锛屼笉涓€娆℃€у叏閮ㄥ姞杞姐€?
## Harness Engineering 璁捐鍘熷垯

> 璇﹁ `.trae/rules/project_rules.md`

1. Humans steer, agents execute
2. Repository knowledge is system of record
3. AGENTS.md is a table of contents, not an encyclopedia
4. Enforce architecture mechanically
5. Agent legibility is the goal
6. Fewer tools, more expressiveness
7. Progressive disclosure
8. Corrections are cheap, waiting is expensive

## Memory Layer

- `Docs/AI/` 浠嶇劧鏄叡浜煡璇嗙殑涓昏鏉ユ簮
- `Docs/Memory/` 鏄け璐ョ粡楠岀殑琛ュ厖灞傦紝涓嶆浛浠?`Docs/AI/`
- Codex Skill `failure-memory` 鎻愪緵璺ㄤ細璇濆け璐ョ粡楠岃蹇?- 绗簩闃舵鎵嶅紩鍏?`Mem0`锛屾枃浠朵粛鐒舵槸涓昏鏉ユ簮锛宍Mem0` 鍙仛璇箟澧炲己

## Codex Capability Consistency

> 璇﹁ `Docs/AI/35-Codex-CCS-Capability-Consistency.md`

褰?Codex 閫氳繃 CC Switch 鍦ㄥ畼鏂硅璇佸拰 API 妯″紡闂村垏鎹㈡椂锛岃嚜鍔ㄩ獙璇侀」鐩?skill 鍙戠幇鍜屾彃浠堕厤缃殑涓€鑷存€с€?
- **妫€鏌ュ綋鍓嶇姸鎬?*: `.\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect`
- **楠岃瘉 skill 鍙戠幇**: `.\.trae\scripts\test-codex-skill-discovery.ps1`
- **楠岃瘉鍩虹嚎瀹屾暣鎬?*: `.\.trae\scripts\test-codex-capability-baseline.ps1`
- **娴嬭瘯 CC Switch 鍚屾**: `.\.trae\scripts\test-ccswitch-codex-config-sync.ps1 -Mode Test`

鑳藉姏鍩虹嚎鏂囦欢: `.codex/capability-baseline.json` 鈥?澹版槑寮忋€佹棤瀵嗛挜銆佸彈鐗堟湰鎺у埗

## Hermes Desktop Agent (Windows 妗岄潰鎿嶆帶)

Hermes Agent 宸查泦鎴?Windows 妗岄潰鎿嶆帶鑳藉姏锛岄€氳繃涓変釜 MCP Server锛?
| MCP Server | 鍔熻兘 | 宸ュ叿鏁?|
|------------|------|--------|
| `windows-computer-use` | pywinauto (UIA) + pyautogui 鎴浘/閿紶 | 8 |
| `desktop-commander` | 缁堢鎺у埗 + 鏂囦欢绯荤粺 | 20+ |
| `unreal-mcp` | UE5 Editor 鎿嶆帶 (闇€ UE5 杩愯) | 6 |

閰嶅 Skill: `windows-desktop-control` 鈥?鎿嶄綔鍐崇瓥閫昏緫 + 涓夊眰娣峰悎鏋舵瀯 (UIA 鈫?OCR 鈫?瑙嗚LLM) + 瀹夊叏绛栫暐

MCP 閰嶇疆: `.tools/hermes-worker/profiles/jinli-implementer/mcp.json`
MCP 浠ｇ爜: `.trae/hermes/mcp/windows_computer_use/`, `.trae/hermes/mcp/unreal_mcp/`

## 鏋勫缓
```powershell
# UE5
& "G:\UE_5.6\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe" RTS Win64 Development "g:\Project\RTS\RTS.uproject" -WaitMutex -FromMsBuild
```

## Git 浠撳簱绛栫暐
- 鏍圭洰褰?`.git`锛屼笉杩借釜瀛愭ā鍧楋紝涓嶈拷韪」鐩枃浠?- `Project/<椤圭洰鍚?/.git`锛岀嫭绔嬮」鐩粨搴?</INSTRUCTIONS>

## Codex MCP 配置

Codex 通过 `jinli_soul_core` MCP Server 接入金璃灵魂引擎。配置在 `C:\Users\87372\.codex\config.toml` 的 `[mcp_servers.jinli_soul_core]` 段。

| 系统 | MCP 工具 | 状态 |
|------|---------|------|
| Soul Core 生命周期 | soul_init, soul_auto, soul_turn, soul_end | 已激活 |
| 情绪引擎 | soul_emotion, soul_status | 已激活 |
| 记忆检索 | soul_memory, soul_learn | 已配置 |
| 习惯进化 | soul_evolve, soul_discover | 已配置 |
| 健康检查 | soul_check | 已配置 |
| 回复编排 | response_plan | 已激活 |
| 视觉监控 | vision_start, vision_stop, vision_status | 已配置 |
| 成长系统 | growth_approve, growth_rollback | 已配置 |
