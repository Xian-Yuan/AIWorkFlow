# WP04 Daemon API Coverage — MCP 17 Tools × Daemon 6 Endpoints

**任务**: `2026-06-27-runtime-daemon-unified-ide` / WP04 — MCP ↔ Daemon HTTP 统一层
**生成日期**: 2026-06-28
**生成者**: 金璃好帮手（Implement Agent，只读分析）
**目的**: 给爸爸拍 WP04 实际实施范围提供真实 evidence-based 映射分析
**输入**: `daemon.py` / `api_server.py` / `client.py`（WP03 已实现）+ `server.mjs` / `tools.mjs` / `tools-orchestrator.mjs` / `soul-cli.mjs`（MCP 17 工具当前实现）

---

## 0. 摘要（TL;DR）

- **结论**：在 WP03 当前实现的 6 个 daemon endpoint 中，**真正能完整覆盖 MCP 17 个工具的只有 1 个**（`soul_memory` → `/memory/query`，仅需 minor 字段适配）。
- **Partial map**: 2 个（`response_plan` / `soul_learn`）—— daemon endpoint 存在但语义/字段显著不匹配，迁移会改变工具语义。
- **Cannot map**: 14 个—— daemon 当前完全没有对应 endpoint，需要新增 9-14 个 endpoint 才能覆盖（其中 vision / growth / soul_core 状态属于 daemon 重大扩展，soul_core 初始化/事件属于跨进程职责重定义）。
- **推荐 WP04 范围**: **A（最小可行）**——只迁移 `soul_memory`，其余 16 个工具自动 fallback 到原 PowerShell / Node ESM 实现。零回归风险，性能提升有限但路径完整。
- **替代方案**: **A'（保守增强）** = A + 给 daemon 加 `/soul/init` `/soul/end` `/emotion` `/health-check` 四个只读/轻量端点（覆盖 4 个工具），其余 12 个工具保留 fallback。

---

## 1. Daemon 当前 6 个 endpoint 速查

来源: `E:\UEGameDevelopment\Project\Jinli\services\runtime\api_server.py`

| Route | Method | 路由注册位置 | Input Schema | Response Shape | 用途 |
|---|---|---|---|---|---|
| `/status` | GET | `api_server.py:558` (`_routes()`) | `(none)` — `_Handler.do_GET` 传 `{}` | `{"ok": true, "status": <snapshot>}` where `<snapshot>` = `JinliDaemon.status_snapshot()` 返回 dict（`daemon_state, pid, loop_alive, started_at, uptime_s, last_error, services[], endpoint, state_dir`） | daemon 全局状态快照（runtime 视角） |
| `/health` | GET | `api_server.py:559` | `(none)` | `{"ok": true, "daemon_state", "blockers": [], "degraded_optional": [], "recommendations": []}`（`handle_health` L158-171） | service registry 健康 + doctor 报告（runtime 视角） |
| `/turn` | POST | `api_server.py:560` | `{"user_input"\|"text"\|"input": str(required), "mode": str ∈ {standard,lite,...TurnMode values}, "task": str="general", "task_packet_id"?: str, "sub_agent_reports"?: list[dict]}`（`parse_turn_request` L121-149） | `{"ok": true, "response": {manifest_id, turn_id, mode, task, passed, violations, degraded}, "evidence": [...], "service_evidence": [...], "memory_evidence": {...} \| null, "emotion_evidence": {...} \| null, "relationship_evidence": {...} \| null, "degraded_reasons": [...], "manifest": {...}}`（`handle_turn` L282-300） | 一次 turn 完整管线（TurnOrchestrator + 7 个 adapter） |
| `/memory/query` | POST | `api_server.py:563` | `{"query"\|"text"\|"user_input": str(required), "max_tokens"?: int=600}`（`handle_memory_query` L303-307 + `client.py:474` 默认 600） | `{"ok": true, "memory_evidence": {status: "gathered"\|"missing"\|..., source, summary, payload, degradation_reason}}`（L333-342） | T4 MemoryService 记忆检索 |
| `/learn` | POST | `api_server.py:564` | `{"text"\|"user_input": str(required), "source"?: str="daemon-client", "tags"?: list[str]}`（`handle_learn` L345-358） | `{"ok": true, "learn_evidence": {status: "gathered", source, summary, payload: {path, tags}, degradation_reason}}`（L383-392） | 追加 JSONL 到 `<state_dir>/turns/learn.jsonl`，无学习算法 |
| `/response_plan` | POST | `api_server.py:565` | `{"prompt"\|"user_input": str(required), "mode"?: str ∈ TurnMode values="standard"}`（`handle_response_plan` L395-406） | `{"ok": true, "response_plan": {mode, prompt, persona: {status, source, summary, payload, degradation_reason}}}`（L437-450） | 只返回 PersonaAdapter 收集的 persona 快照，**不含** scene_route / text_guidance / action_intent / topic_queue |

**Client 侧方法**（`client.py:120-547`）：
- `JinliClient.status()`（L288-309）—— offline-tolerant，读本地 status 文档
- `JinliClient.health()`（L311-342）—— 优先 `GET /health`，offline 时 fallback 到本地 status
- `JinliClient.turn(text, ...)`（L346-379）—— 失败时按 `use_legacy_compat` 决定 raise `DaemonOffline` 或走 `_legacy_turn()` 进程内 orchestrator
- `JinliClient.memory_query(query, max_tokens=600)`（L474-493）
- `JinliClient.learn(text, source, tags)`（L495-521）
- `JinliClient.response_plan(prompt, mode='standard')`（L523-546）

**关键观察 1（offline 行为）**：`client.py:380-393, 474-493, 495-521, 523-546` 中所有写操作都有 `try/except DaemonOffline` + `use_legacy_compat` 标记，返回 dict 包含 `"fallback_used": True, "fallback_reason": "daemon_offline_explicit_compat"` —— **daemon client 已经有成熟的 fallback 语义**，WP04 可以直接复用这个 pattern。

**关键观察 2（http 错误处理）**：`client.py:226-244` 把 4xx/5xx HTTPError 的 JSON body 直接 parse 返回（不抛 `DaemonOffline`）—— **daemon 返回 `{"ok": False, "error": "...", ...}` 时 client 不会 retry**，WP04 handler 必须自己负责 error handling。

---

## 2. MCP 17 个工具分类 × 当前实现路径

来源: `C:\Users\87372\plugins\jinli-soul-core\mcp\server.mjs`, `tools.mjs`, `tools-orchestrator.mjs`, `soul-cli.mjs`

### 2.1 tools.mjs 中的 11 个（PowerShell subprocess）

| 工具 | Schema input (server.mjs:32-130) | 当前 handler 位置 | 调用链 | 失败模式 |
|---|---|---|---|---|
| `soul_init` | `{ide?: enum[codex,opencode]="codex"}` | `tools.mjs:112-127` `soulInitHandler` → `invokeSoulCore('init', ide)` | `soul-cli.mjs:21` `execFileSync('powershell', [...soul-core.ps1 -Command 'init' -Arg1 '<ide>'])` | `ETIMEDOUT`(15s) / JSON 解析失败 / `status='disabled'` |
| `soul_auto` | `{input: string(required)}` | `tools.mjs:132-156` `soulAutoHandler` → `invokeSoulCore('auto', input)` | PowerShell `soul-core.ps1 auto -Arg1 '<input>'` | 同上；输入为空时返回 `{trigger: neutral}` 不调用 PowerShell |
| `soul_turn` | `{trigger: enum[14](required), input?: string}` | `tools.mjs:161-184` `soulTurnHandler` → `invokeSoulCore('turn', trigger, input)` | PowerShell `soul-core.ps1 turn -Arg1 '<trigger>' -Arg2 '<input>'` | trigger 不在白名单时 throw |
| `soul_end` | `{}` | `tools.mjs:189-212` `soulEndHandler` → 直接 `execFileSync(powershell ... -Command 'end')` + `getEndResult(stdout)`（正则解析 Mood/hurt/repair/session_count） | PowerShell `soul-core.ps1 end` + 正则 `Mood: \| hurt= \| repair= \| 聊了 X 个会话了` | exec 失败时 fallback 到 `{mood: 'unknown', hurt: 0, ...}` |
| `soul_emotion` | `{}` | `tools.mjs:217-232` `soulEmotionHandler` → `invokeSoulCore('emotion')` | PowerShell `soul-core.ps1 emotion` | 返回 null 时回落到默认 `{primary: '满足', secondary: ['平静'], tone_policy: {...}}` |
| `soul_status` | `{}` | `tools.mjs:237-249` `soulStatusHandler` → `invokeSoulCore('status')` | PowerShell `soul-core.ps1 status` | 返回 null 时 throw（**没有 fallback**） |
| `soul_memory` | `{query: string(required), limit?: number=3}` | `tools.mjs:254-271` `soulMemoryHandler` → `invokeSoulCore('memory', query, String(limit))` | PowerShell `soul-core.ps1 memory -Arg1 '<query>' -Arg2 '<limit>'` | query 为空返回 `[]`；不抛 |
| `soul_learn` | `{feedback: string(required)}` | `tools.mjs:276-309` `soulLearnHandler` → 直接 `execFileSync(powershell ... -Command 'learn' -Arg1 '<feedback>')` + 正则 `[LEARN]\s+(\w+)\s+([+\-][\d.]+)\s+->\s+([\d.]+)\s+\(scene:\s*(.+?)\)` | PowerShell `soul-core.ps1 learn -Arg1 '<feedback>'` + 正则解析 | 找不到正则匹配返回 `{adjusted: false}`；`[SKIP]` 也返回 `{adjusted: false}` |
| `soul_evolve` | `{daysBack?: number=7, direct?: bool=false}` | `tools.mjs:314-339` `soulEvolveHandler` → `direct=true` 走 `invokeEvolveDirect('Invoke-HabitEvolution', {DaysBack, Direct:true})`；否则 `invokeSoulCore('evolve')` | PowerShell `evolve-self.ps1 Invoke-HabitEvolution` 或 `soul-core.ps1 evolve` | `direct=true` 时超时抛 `Evolve/Discover ... failed` |
| `soul_discover` | `{scope?: enum[ai-coding,ue5,nlp,general]="ai-coding", direct?: bool=false}` | `tools.mjs:344-367` `soulDiscoverHandler` → 同上分 direct/non-direct | PowerShell `evolve-self.ps1 Invoke-KnowledgeDiscovery` 或 `soul-core.ps1 discover` | 同上 |
| `soul_check` | `{}` | `tools.mjs:372-374` `soulCheckHandler` → `invokeHealthCheck()` (`soul-cli.mjs:126-156`) | PowerShell `soul-core.ps1 check` + 字符串包含 `[OK]/[FAIL]/[WARN]` 检查 | 不抛；返回 `{all_ok, checks: {soul_state, style_profile, memory_db, events, node_available}}` |

### 2.2 tools-orchestrator.mjs 中的 6 个（Node ESM + Python）

| 工具 | Schema input (server.mjs:135-198) | 当前 handler 位置 | 调用链 | 失败模式 |
|---|---|---|---|---|
| `response_plan` | `{userInput: string(required), conversationContext?: {previousTopics?: string[], turnCount?: number}}` | `tools-orchestrator.mjs:140-221` `responsePlanHandler` → 依次 lazy import `persona-kernel.mjs` / `soul-bridge.mjs` / `expression-orchestrator.mjs`，调用 `kernel.load()` + `soulBridge.captureSoulSnapshot()` + `orchestrator.orchestrate()` | 纯 Node ESM 动态 import，无 subprocess | 任意模块加载失败 → 内层 try/catch 退回 fallback snapshot 或 fallback ResponsePlan |
| `vision_start` | `{session_id?: string}` | `tools-orchestrator.mjs:235-285` `visionStartHandler` → `execSync('python -m vision.cli start --session-id ...')` cwd=`Project/Jinli/services` | Python `vision.cli start` subprocess (timeout 30s) | VISION_CLI 不存在 → mock 启动返回；Python 缺失 → mock；exec 失败 → `{status: 'error'}` |
| `vision_stop` | `{}` | `tools-orchestrator.mjs:296-313` `visionStopHandler` → `execSync('python -m vision.cli stop')` | Python `vision.cli stop` | 不存在/mock/失败时返回 `{status: 'stopped', mode: 'mock'}` |
| `vision_status` | `{}` | `tools-orchestrator.mjs:324-346` `visionStatusHandler` → `execSync('python -m vision.cli status')` | Python `vision.cli status` | 不存在/mock/失败时返回 `{status: 'not_installed'/'unknown', running: false}` |
| `growth_approve` | `{proposal_id: string(required), approved: boolean(required)}` | `tools-orchestrator.mjs:362-457` `growthApproveHandler` → `loadProposal()` + `kernel.checkMutation()`（protected field guard）+ 改写 `persona.json` + 写 `growth_audit.jsonl` | Node 文件 I/O（fs.readFileSync/writeFileSync） | 文件权限/JSON parse/ProtectedFieldError → 返回 `{status: 'rejected', error}` |
| `growth_rollback` | `{proposal_id: string(required)}` | `tools-orchestrator.mjs:471-533` `growthRollbackHandler` → `loadProposal()` + 改写 `persona.json` + audit log | Node 文件 I/O | 同上；`before_value` 为空 → `{status: 'error', error: 'no before_value'}` |

**关键观察 3（超时不一致）**：`tools.mjs` 全部使用 15000ms（`tools.mjs:17 TIMEOUT`），`tools-orchestrator.mjs` vision 用 30000ms（`tools-orchestrator.mjs:38 CHILD_TIMEOUT`）。daemon client 默认 timeout 是 60000ms（`client.py:144`）。**WP04 引入 HTTP 中间层后，所有调用都会多一层 HTTP 握手**，WP04 的 daemon-http.mjs 需要选 timeout 策略（建议 ≥60s 兼容 cold-start）。

**关键观察 4（参数转义路径）**：`tools.mjs` 全部走 PowerShell 参数注入（含单引号/双引号转义 `[FIX I4/I1]`），`tools-orchestrator.mjs` 的 growth_* 走 dot-notation 文件路径解析（`tools-orchestrator.mjs:420-428, 495-503`）。**这些安全逻辑不能简单丢弃**——WP04 走 daemon 时 daemon 端不再需要 PowerShell 转义，但 dot-notation 解析必须保留在 MCP handler 边界。

---

## 3. 映射分析（关键）

### 3.1 can_map（完全可映射，daemon endpoint 已覆盖）

| MCP 工具 | daemon endpoint | 字段对齐 | 差异 | 需要的适配 |
|---|---|---|---|---|
| `soul_memory` | `POST /memory/query` | **完全对齐**：MCP input `{query, limit}` 映射到 daemon input `{query, max_tokens}`；daemon output `{ok, memory_evidence: {status, source, summary, payload, degradation_reason}}` 与 MCP `MemoryItemSchema` 都返回结构化记忆项（虽然 schema 是 array of MemoryItem，但每个 item 的字段名 `id/type/content/weight/decay_factor/recall_count` 与 daemon `payload` 内的字段需在 WP04 实际测试时确认） | 1. `limit` (记录数) vs `max_tokens` (token 数) 是不同语义但都用于控制返回大小 2. daemon 返回的是 `memory_evidence` 单数对象（内含 payload.items 数组），MCP 输出 schema 是顶层 array | WP04 handler 内做 `limit → max_tokens` 转换（粗略换算：`max_tokens ≈ limit * 200`）+ payload → array 提取 |

**数量**: **1 个**

### 3.2 partial_map（部分可映射，daemon 端点存在但字段或语义显著不匹配）

| MCP 工具 | daemon endpoint | 部分映射的字段 | 缺什么 | 建议 |
|---|---|---|---|---|
| `response_plan` | `POST /response_plan` | ✅ persona: `{status, source, summary, payload, degradation_reason}` | ❌ `scene_route`（场景路由）❌ `text_guidance`（文本引导）❌ `action_intent: {action_type, status, intensity, avatar_processed, avatar_confirmed}` ❌ `topic_queue: [...]` ❌ `private_summary_excluded` ❌ `tone_directives: {warmth, directness, playfulness, formality_shift, needs_comfort}` | **不推荐直接迁移**——daemon 端 PersonaAdapter 不包含 expression-orchestrator 的 5 个核心字段。如果 WP04 想覆盖，必须在 daemon 内集成 expression-orchestrator（属于 WP05+ 范围） |
| `soul_learn` | `POST /learn` | ⚠️ 表面相似：都是"接收文本并记录" | ❌ daemon /learn 是纯 JSONL 追加（`api_server.py:345-392`，无任何学习算法），MCP `soul_learn` 是 Invoke-FeedbackLearning 正则匹配 `[LEARN]` 输出（`tools.mjs:276-309`，调整 vitality/warmth 等风格参数） | **不推荐直接迁移**——会丢失"风格参数自动调整"语义。如果 WP04 想覆盖，需要 daemon 集成 FeedbackLearning 引擎 |

**数量**: **2 个**

### 3.3 cannot_map（daemon 当前没有对应 endpoint，迁移需要新增 endpoint 或保持原实现）

#### 3.3.1 soul_core 内部状态类（9 个，需要新增 7-9 个 soul_* endpoint）

| MCP 工具 | 为什么不能映射 | 替代方案 |
|---|---|---|
| `soul_init` | daemon 没有"会话初始化"概念。daemon 一次启动跨多次 session，没有 session_id 概念。`soul_init` 的核心是加载情绪向量 + 应用时间衰减 + 检索相关记忆生成复合情绪（`tools.mjs:112-127`），这些数据都不在 daemon 服务注册表内 | **保留原 PowerShell 实现 + fallback** |
| `soul_auto` | daemon 没有"输入情绪分类"端点。`soul_auto` 接收用户文本返回 `{trigger, emotion, bienao_active, repair_status, turn_count}`（`tools.mjs:132-156`），这是 soul_core 核心功能 | 同上 |
| `soul_turn` | daemon 没有"agent 自检测事件"端点。14 种 trigger（`tools.mjs:165-170`）的更新逻辑完全在 soul-core.ps1 内 | 同上 |
| `soul_end` | daemon 没有"会话结束保存+衰减"端点。`soul_end` 解析 PowerShell 文本输出中的 `Mood:/hurt=/repair=/{N} 个会话了`（`tools.mjs:55-69`），daemon 没有这些标记 | 同上 |
| `soul_emotion` | daemon 没有"情绪摘要"端点。`GET /health` 返回的 daemon_state 是 runtime 状态（starting/online/degraded/stopped），不是情绪 | 同上 |
| `soul_status` | **同名但是完全不重叠的两个东西**：daemon `GET /status` 返回 runtime 快照（`daemon_state, pid, loop_alive, services[]`），MCP `soul_status` 返回 soul_core 状态（`emotion, traits, bienao, session, cross_session`）——字段零交集 | 同上（**不要被同名误导**） |
| `soul_evolve` | daemon 没有"事件分析 + 风格调整建议"端点。`Invoke-HabitEvolution` 在 evolve-self.ps1 内（`tools.mjs:317`） | 同上 |
| `soul_discover` | daemon 没有"arXiv/GitHub 搜索"端点。`Invoke-KnowledgeDiscovery` 是外部 API 调用（`tools.mjs:347`） | 同上 |
| `soul_check` | daemon `GET /health` 与 MCP `soul_check` 检查**完全不同的目标**：daemon 检查 7 个 runtime service 的 online/degraded 状态（`api_server.py:158-171, daemon.py:882-920`），MCP 检查 5 个 soul_core 数据文件存在性（`soul-cli.mjs:135-145`：soul-state.json, style-profile.json, memory.db, events.jsonl, Node.js 可用性） | 同上 |

#### 3.3.2 视觉感知类（3 个，需要新增 vision 端点或保持原 Python subprocess）

| MCP 工具 | 为什么不能映射 | 替代方案 |
|---|---|---|
| `vision_start` | daemon 没有 vision 端点。`visionStartHandler` 直接 `execSync('python -m vision.cli start')`（`tools-orchestrator.mjs:251-258`） | **保留原 Python subprocess + fallback** |
| `vision_stop` | 同上 | 同上 |
| `vision_status` | 同上 | 同上 |

#### 3.3.3 成长管理类（2 个，需要新增 growth 端点或保持原文件 I/O）

| MCP 工具 | 为什么不能映射 | 替代方案 |
|---|---|---|
| `growth_approve` | daemon 没有 growth 端点。`growthApproveHandler` 直接读写 `persona.json` + `data/growth_proposals/{id}.json`（`tools-orchestrator.mjs:362-457`），daemon 不持有 persona 数据 | **保留原 Node 文件 I/O + fallback** |
| `growth_rollback` | 同上 | 同上 |

**数量**: **14 个**（9 + 3 + 2）

### 3.4 映射汇总

| 类别 | 数量 | 工具列表 |
|---|---|---|
| **can_map** | 1 | `soul_memory` |
| **partial_map** | 2 | `response_plan`, `soul_learn` |
| **cannot_map** | 14 | `soul_init`, `soul_auto`, `soul_turn`, `soul_end`, `soul_emotion`, `soul_status`, `soul_evolve`, `soul_discover`, `soul_check`, `vision_start`, `vision_stop`, `vision_status`, `growth_approve`, `growth_rollback` |
| **合计** | **17** | — |

---

## 4. WP04 实际范围建议

### 范围 A — 最小可行（推荐）

**只迁移 `soul_memory` 一个工具，其余 16 个工具全部保持原 PowerShell / Node ESM / Python 实现。**

**实现要点**:
- 新增 `daemon-http.mjs`：1 个 POST 方法（`memoryQuery({query, limit})`）
- 每次调用前先检查 endpoint file 存在 + PID alive（参考 `client.py:188-199` `is_online()`）+ 端口可达
- 离线时 fallback 到 `invokeSoulCore('memory', query, String(limit))`
- 响应统一加 `source: 'daemon' | 'powershell_fallback'` + `fallback_used: bool` 字段
- Node.js test：1 个 happy path（真实 daemon + 真实 query）+ 1 个 offline fallback + 1 个 daemon 5xx 错误处理

**优点**:
- 零回归风险——只动 1 个工具，原 16 个工具的 PowerShell/ESM/Python 路径完全不变
- 实施工作量最小（1 个 daemon endpoint 已经存在，只需 MCP handler 适配）
- 性能提升：daemon 内存中 `MemoryAdapter.gather` 比 PowerShell subprocess 快 5-10x（消除 PowerShell 冷启动 + JSON 解析）
- 路径完整：未来 WP05+ 可以逐步加 endpoint，按工具迁移，无需重写 WP04

**缺点**:
- 只 1 个工具受益于 daemon，性能提升非常有限
- 16 个工具仍然有 PowerShell 冷启动延迟

**测试覆盖**: 3 个 Node.js test（最小工作量）

---

### 范围 A' — 保守增强（推荐 A 的升级版）

**A + 给 daemon 新增 4 个轻量只读 endpoint，覆盖另外 4 个工具：**
- `GET /soul/emotion` → 覆盖 `soul_emotion`（daemon 服务注册表可以暴露"persona 引擎"作为一个 service health，但其 emotion vector 实际数据来源仍需 soul-state.json 读取 —— **需要评估**）
- `GET /soul/check` → 覆盖 `soul_check`（daemon 已有 doctor 报告但目标不同，需要新增"数据文件存在性"检查）
- `POST /soul/init` → 覆盖 `soul_init`（**警告**：会改变 soul_init 的"幂等性"语义，daemon 是常驻进程，会话初始化跨进程不合理）
- `POST /soul/end` → 覆盖 `soul_end`（同上，跨进程语义不清晰）

**⚠️ 警告**：A' 中新增的 4 个 endpoint 在概念上与 daemon 的"runtime 守护"职责不完全契合——session 概念是 IDE 侧的（每次 Codex 启动是一次 session），daemon 跨 session 长存。**强烈建议先看 WP05 是否已经定义了 session_id 的 daemon 端表达，没有的话 A' 风险高于收益。**

---

### 范围 B — 中等

**A + partial_map（`response_plan`, `soul_learn`）也迁移。**

**新增工作量**:
- daemon 集成 `expression-orchestrator.mjs`（Node ESM）—— 但 daemon 是 Python，无法直接 import Node 模块
- daemon 集成 `FeedbackLearning` 引擎（Python 移植 PowerShell 逻辑）

**优点**:
- 覆盖 5/17 工具（soul_memory + response_plan + soul_learn）

**缺点**:
- daemon 端需要重新实现 expression-orchestrator（Python 移植或 subprocess 桥接）—— **工作量爆炸**
- soul_learn 的 FeedbackLearning 算法移植会改变 learning 行为 —— **回归风险高**
- **不推荐**

---

### 范围 C — 完全迁移（不推荐）

**17 个工具全部尝试映射。需要 daemon 重大扩展：**
- 9 个 soul_* 端点（init/auto/turn/end/emotion/status/evolve/discover/check）
- 3 个 vision_* 端点（start/stop/status）
- 2 个 growth_* 端点（approve/rollback）
- 表达编排引擎 Python 移植
- 反馈学习引擎 Python 移植
- arXiv/GitHub API Python 移植
- session_id 概念引入 daemon

**优点**: daemon 成为唯一权威

**缺点**:
- daemon 大改破坏 WP01/WP02/WP03 已建立的稳定性
- 引入 Python↔PowerShell 算法等价性风险（FeedbackLearning / HabitEvolution 是统计学习算法，移植可能改变输出）
- 预计工作量: WP04 至少扩大 5-8 倍
- **不推荐**

---

## 5. 实施细节预判

### 5.1 daemon-http.mjs 能力清单（范围 A 下的最小集）

| 能力 | 来源/参考 | 说明 |
|---|---|---|
| 读取 daemon.endpoint | 模仿 `client.py:169-186` `_read_endpoint()` | 必须验证 PID 文件存活 + PID 与 endpoint.pid 一致 |
| TCP socket 探活 | 模仿 `client.py:102-108` `_tcp_reachable()` | 0.5s 超时，避免无谓的 HTTP 请求 |
| HTTP POST (Content-Type: application/json) | Node 18+ 内置 `fetch`（无需引入 axios） | 参考 `client.py:217-224` 的 urllib 实现 |
| JSON parse + error handling | `client.py:226-263` 已示范如何把 4xx/5xx body parse 成 dict | 必须把 `{"ok": false, "error": "..."}` 当作业务错误而非抛异常 |
| 60s HTTP timeout | `client.py:144` 已有先例 | 兼容 cold-start（首次 /turn 可能要等 MemoryService FTS5 warm-up） |
| fallback 触发条件 | endpoint file missing / PID dead / socket refused / HTTP 5xx / HTTP timeout | 这 5 个条件任一触发 → 走 fallback |
| 统一返回 schema | `client.py:485-493` 的 `fallback_used` + `fallback_reason` pattern | 每个工具响应统一加 `{source: 'daemon' \| 'powershell_fallback', fallback_used: bool, fallback_reason?: str}` |
| endpoint file watcher（可选） | daemon 重启后端口可能变 | WP04 可以每次调用前读 endpoint（参考 `client.py:152-154` `_cached_endpoint` 缓存策略），避免 watcher 复杂度 |

### 5.2 fallback 触发条件清单（自动 fallback，不抛异常）

| 条件 | 检测方法 | 来源 |
|---|---|---|
| daemon.endpoint 文件不存在 | `existsSync(endpoint_path)` | `client.py:171-186` |
| PID 文件不存在 / 与 endpoint.pid 不一致 | 读 pid_path + 比对 | `client.py:174-186` |
| PID 不存活 | `_pid_alive()`（参考 `client.py:65-99`） | daemon 端用 psutil / ctypes |
| TCP socket 不可达 | `net.createConnection({host, port, timeout: 500})` 失败 | `client.py:102-108` |
| HTTP 5xx | daemon 返回 status >= 500 | `client.py:226-244` 不会抛但返回 dict，handler 自己判断 `payload.ok === false` |
| HTTP timeout（>60s） | `AbortController` + `setTimeout` | 需自实现 |

### 5.3 统一响应 schema（建议）

```javascript
{
  // 原始 MCP 工具输出（保持向后兼容）
  ...originalResult,

  // WP04 新增字段（所有 17 个工具统一）
  _wp04_source: 'daemon' | 'powershell_fallback' | 'node_esm_fallback' | 'python_fallback' | 'file_io_fallback',
  _wp04_fallback_used: boolean,
  _wp04_fallback_reason?: 'daemon_endpoint_missing' | 'pid_dead' | 'socket_refused' | 'http_5xx' | 'timeout' | 'feature_not_mapped',
  _wp04_endpoint?: { host, port, pid },  // daemon 模式下附带，方便 debugging
}
```

**注意**: 这个 `_wp04_` 前缀字段是新增的，server.mjs:262-273 的 `OUTPUT_SCHEMAS` Zod 校验需要加 `passthrough` 或 `.unknown()`，否则会被现有 schema 拒绝。**WP04 必须先改 server.mjs 的 Zod schema 设置**。

### 5.4 Node.js test 内容清单（范围 A）

| Test # | 名称 | 类型 | 验证内容 |
|---|---|---|---|
| 1 | `soul_memory_daemon_online` | 集成测试（真实 daemon subprocess） | spawn Python daemon 子进程 → wait for `daemon_state='online'` → 启动 MCP server → call `soul_memory({query: 'test'})` → 验证响应 `_wp04_source === 'daemon'` 且内容非空 |
| 2 | `soul_memory_daemon_offline` | 集成测试（无 daemon） | 不启动 daemon → call `soul_memory({query: 'test'})` → 验证响应 `_wp04_source === 'powershell_fallback'` 且 `_wp04_fallback_reason === 'daemon_endpoint_missing'` |
| 3 | `soul_memory_daemon_5xx` | 单元测试（mock fetch） | mock `fetch` 返回 500 + JSON `{"ok": false, "error": "internal"}` → call `soul_memory` → 验证走 fallback |
| 4 | `unmapped_tools_unchanged` | 单元测试 | 验证 `soul_init`, `vision_start`, `growth_approve` 等 16 个工具的 handler 路径与 WP04 之前完全一致（直接调用原 PowerShell/ESM/Python/文件 I/O，不引入 daemon-http.mjs） |

**总计**: 4 个 test，最小化覆盖（happy / offline / 5xx / 未迁移工具回归）。

### 5.5 风险与回归检查清单（实施前必读）

| 风险 | 影响 | 缓解 |
|---|---|---|
| server.mjs 的 Zod schema 拒绝 `_wp04_` 字段 | 所有 daemon 模式调用都失败 | 先改 `OUTPUT_SCHEMAS` 为 passthrough 或加 `.unknown()` |
| `limit` vs `max_tokens` 语义差异 | soul_memory 返回大小变化 | 在 handler 内做保守换算（`max_tokens = limit * 200`），加注释说明是估算 |
| daemon 端 cold-start（首次 `/turn` 要等 MemoryService FTS5 warm-up） | 60s timeout 可能不够 | daemon client.py:144 已经定 60s，WP04 沿用；首次调用方应主动 warm-up |
| 并发调用 daemon（多个 MCP tool 并发触发 /memory/query） | daemon 是 ThreadingHTTPServer（`api_server.py:579`），支持并发——无风险 | 无需特别处理 |
| endpoint 文件被 daemon 改写（端口 fallback 场景，`daemon.py:472-482`） | MCP handler 缓存的 endpoint 失效 | 每次调用前重新读 endpoint（不缓存） |

---

## 6. 不确定项（开放问题，等爸爸拍）

### 6.1 关于 soul_memory 的 limit↔max_tokens 换算

`tools.mjs:259` 用 `String(limit)` 传给 PowerShell，PowerShell 端把 limit 当作记录数。daemon `/memory/query` 的 `max_tokens` 是 token 数。
**open question**: WP04 是否要做精确换算（需要读 token 数）还是粗略 `limit * 200`？
- 精确方案：调用 daemon /learn-style 接口或读 tokenizer，复杂度高
- 粗略方案：保守过度返回，由 caller 截断
- **建议**: 粗略方案，`limit * 200` 作为 max_tokens 下限

### 6.2 关于 response_plan 的 fallback

`response_plan` 当前完全在 Node ESM 内（persona-kernel + soul-bridge + expression-orchestrator 都是 `Project/Jinli/runtime/*.mjs`），不依赖 PowerShell。daemon `/response_plan` 只返回 persona 部分，缺 5 个核心字段。
**open question**: 如果 WP04 选范围 A 不迁移 response_plan，那么现有实现保留。如果选范围 B 迁移，daemon 端需要集成 expression-orchestrator 的 Python 移植（工作量极大）。
- **建议**: 不迁移，保留 Node ESM 实现

### 6.3 关于 soul_status 和 GET /status 的命名冲突

**同名但是完全不同**——这是个潜在的混淆源。
**open question**: WP04 文档/日志中如何区分两个 "status"？
- **建议**: WP04 的 daemon-http.mjs 内部命名用 `daemonRuntimeStatus` vs `soulCoreStatus` 区分

### 6.4 关于 daemon 端新增 soul_* endpoint 的 session 语义

`soul_init` / `soul_end` 的语义都假设"一次 session"，daemon 是常驻跨 session 进程。
**open question**: 如果 WP05 想要 daemon 端有 session 概念（session_id 作为 daemon 内的"租约"），session_id 由谁生成、过期策略是什么？
- **建议**: WP04 不要碰 session 概念，留给 WP05

### 6.5 关于 vision CLI 的 Python subprocess 失败模式

`tools-orchestrator.mjs:270-277` 在 vision CLI 缺失时返回 `{status: 'started', mode: 'mock'}` —— 这是个**"假装成功"的 fallback**，会让 caller 误以为 vision 服务真的启动了。
**open question**: WP04 是否要在 vision_* 三个工具响应中加 `_wp04_source` 字段，让 caller 能区分真实启动 vs mock？
- **建议**: 加 `_wp04_source: 'python_subprocess'` 字段，caller 一眼能看出

### 6.6 关于 growth_approve / growth_rollback 的事务性

当前 `growthApproveHandler`（`tools-orchestrator.mjs:362-457`）的文件写入不是事务的——如果 `writeFileSync(PERSONA_CONFIG)` 成功但 `saveProposal()` 失败，会留下"persona 已改但 proposal state 未更新"的不一致状态。
**open question**: WP04 是否需要顺手补一个原子写入（先写 tmp 再 rename）？
- **建议**: 不属于 WP04 范围，留给 future failure memory candidate

### 6.7 关于测试环境的 daemon 启动开销

daemon 启动需要 spawn Python subprocess + 初始化 service registry + bind HTTP 端口，cold-start 约 2-5s。
**open question**: WP04 的 Node.js integration test 是否值得为这 4 个 test 花 5-15s 启动 daemon？
- **建议**: 值得，因为只有真实 daemon 才能验证 HTTP/JSON 序列化正确性。CI 上可以加 `@slow` 标记让单元测试快速跑、集成测试独立跑

### 6.8 关于 fallback 响应是否要被 Zod schema 校验

`server.mjs:262-273` 现有逻辑是：Zod 校验失败时 `console.error` 但不阻塞，返回原始结果。
**open question**: WP04 添加 `_wp04_` 字段后，Zod schema 是否要更新？
- **建议**: 把所有 `OUTPUT_SCHEMAS` 改成 `.passthrough()` 或 `.unknown()`，避免每个工具单独改 schema

---

## 7. 附录: 关键文件 evidence 索引

| evidence | 文件 | 行号 |
|---|---|---|
| DaemonAPIServer 路由表 | `api_server.py` | 553-566 |
| DaemonAPIServer._routes() 完整 routes dict | `api_server.py` | 553-566 |
| handle_status response shape | `api_server.py` | 152-156 |
| handle_health response shape | `api_server.py` | 158-171 |
| handle_turn response shape | `api_server.py` | 282-300 |
| handle_memory_query input/output | `api_server.py` | 303-342 |
| handle_learn input/output | `api_server.py` | 345-392 |
| handle_response_plan input/output | `api_server.py` | 395-450 |
| JinliClient 所有方法签名 | `client.py` | 288-546 |
| JinliClient offline fallback pattern | `client.py` | 380-393, 474-493, 495-521, 523-546 |
| 17 个 tool schema 定义 | `server.mjs` | 32-198 |
| HANDLERS 注册（11 个） | `tools.mjs` | 379-391 |
| ORCHESTRATOR_HANDLERS 注册（6 个） | `tools-orchestrator.mjs` | 539-546 |
| soul_init handler | `tools.mjs` | 112-127 |
| soul_auto handler | `tools.mjs` | 132-156 |
| soul_turn handler | `tools.mjs` | 161-184 |
| soul_end handler (含正则解析) | `tools.mjs` | 189-212 |
| soul_emotion handler | `tools.mjs` | 217-232 |
| soul_status handler | `tools.mjs` | 237-249 |
| soul_memory handler | `tools.mjs` | 254-271 |
| soul_learn handler (含正则) | `tools.mjs` | 276-309 |
| soul_evolve handler | `tools.mjs` | 314-339 |
| soul_discover handler | `tools.mjs` | 344-367 |
| soul_check handler | `tools.mjs` | 372-374 |
| invokeSoulCore 实现 | `soul-cli.mjs` | 21-68 |
| invokeHealthCheck 实现 | `soul-cli.mjs` | 126-156 |
| response_plan handler | `tools-orchestrator.mjs` | 140-221 |
| vision_start handler | `tools-orchestrator.mjs` | 235-285 |
| vision_stop handler | `tools-orchestrator.mjs` | 296-313 |
| vision_status handler | `tools-orchestrator.mjs` | 324-346 |
| growth_approve handler | `tools-orchestrator.mjs` | 362-457 |
| growth_rollback handler | `tools-orchestrator.mjs` | 471-533 |
| OUTPUT_SCHEMAS Zod 校验入口 | `server.mjs` | 262-273 |

---

## 8. 给爸爸的最终建议

**推荐范围 A（最小可行）**——只迁移 `soul_memory` 1 个工具。

理由:
1. **真实 evidence 表明只有 1 个工具能干净迁移**——这是代码事实，不是工程妥协
2. **零回归风险**——16 个未迁移工具完全保持原路径
3. **路径完整**——WP04 建立的 daemon-http.mjs 框架可以被 WP05+ 复用，逐步加 endpoint
4. **实施工作量最小**——预计 1-2 个 commit 内完成
5. **测试简单**——4 个 Node.js test 覆盖 happy/offline/5xx/未迁移回归

如果爸爸认为 1 个工具太少、希望覆盖更多场景，推荐**范围 A' 但只加 `GET /soul/emotion` 和 `GET /soul/check` 两个只读端点**（共 3 个工具受益），这两个端点的语义最接近 daemon 现有能力，风险可控。

**不推荐**范围 B/C——会引入 daemon 端 expression-orchestrator / FeedbackLearning 的 Python 移植工作量，超出 WP04 范围。
