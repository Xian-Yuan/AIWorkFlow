# Routing Decision — jinli/2026-06-29-daemon-scheduler-unify

> Generated: 2026-06-29 | Agent: 金璃小天才 | Phase: Plan
> Related design docs: `Project/Jinli/docs/03-Architecture/General/architecture.md`
> Related task packages: T7 (Dreamer)、T8 (Evolution)、T9 (Proactive) — `Project/Jinli/docs/task-packages/`

## Project Detection

| Signal | Value |
|--------|-------|
| User mention keywords | 统一调度、APScheduler、BackgroundScheduler、dreamer 5s 循环、evolution idle、proactive idle、AfterTurnCommit sink、信号 dropped |
| File path prefix | `Project/Jinli/services/runtime/` + `services/memory/dreamer/` + `services/evolution/` + `services/proactive/p1/` + `services/nervous/` |
| Primary skill involved | `金璃小天才`（Plan 阶段）；Implement 阶段交 `金璃好帮手` |
| project_type | **other**（Jinli Python daemon，不是 UE5 / Web） |
| Mature-solution category | **Mature** — APScheduler 已是生产级标准（PoE/Elasticsearch/Zulip 全部用），3.11.2 已在 env |

## Primary Skill Selection

| Decision | Rationale |
|----------|-----------|
| **Primary Skill** | `金璃好帮手` — Implement 阶段全权负责编码、编译、重复检测、spec 自检 |
| **Plan Skill** | `金璃小天才` — 需求澄清、依赖推导、spec 编写、风险标注 |
| **Companion Skill (Phase 1 必加载)** | `web-engineer` / Python 后端 — APScheduler BackgroundScheduler 集成、async-to-sync 桥接 |
| **Reference Reading** | `daughter-companion` — 知情此任务会改变 turn-end 时序，避免打扰 Ba Ba |
| **NOT Loaded** | UE5 / Web / Mobile skill（与本任务无关） |

## Architecture Decision

**Single-agent (Plan) → Multi-WP (Implement)** — Plan 阶段是设计密集型工作，Implement 阶段拆 7 个 WP（每个 WP 可独立完成 + 验收），由 `金璃好帮手` 顺序执行：

```
WP01 Scheduler Core ─→ WP02 Timed Jobs ─┐
                                       ├─→ WP04 EventBus Subscriptions ─→ WP05 Sync Wrapper ─┐
WP03 Sink Adapters ─────────────────────┘                                                       ├─→ WP06 Tests ─→ WP07 Docs+Retire
                                                                                                │
                                                            (Phase 2: asyncio loop 线程)─────────┘
```

**改动面**（10 个文件）：
- `services/runtime/daemon.py` — `_run_loop` 5s 块替换为 `scheduler` + `health_check` job
- `services/runtime/service_registry_builder.py` — 注册 3 个新 sink + scheduler
- `services/runtime/adapters/dreamer_adapter.py` — 实现 `enqueue()`
- `services/runtime/adapters/proactive_adapter.py` — 实现 `enqueue()`
- `services/runtime/adapters/evolution_adapter.py` — 实现 `enqueue()`
- `services/runtime/scheduler.py` — **NEW** `DaemonScheduler` 类 + `JobSpec` dataclass
- `services/proactive/p1/triggers.py` — `IdleTrigger._on_tick` 拆 sync/async
- `services/runtime/scheduler_bridge.py` — **NEW** async-to-sync 桥接（Phase 1）+ Phase 2 占位
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md` — 加 Scheduler 章节
- `Project/Jinli/docs/06-Operations/General/runtime-daemon-runbook.md` — 加 `/status -Json` scheduler 字段

**Legacy 退役**（不在 WP01-WP07 范围，留作 Phase 2）：
- `services/jinli_daemon.py` (607 行) — 旧 daemon 的 9 个线程保留（不删，避免破坏现存脚本）；本任务只在 `runtime/daemon.py` 上做统一

## Quality Gate

| Attribute | Value |
|-----------|-------|
| **Requirement Classification** | **deep-discovery** — 涉及多模块（daemon + scheduler + 3 services + EventBus）、多 sync/async 边界、多 sink，需求澄清 + 隐性需求推导必做 |
| **Default Quality Level** | **Mature production-grade** — 这是金璃基础设施（监控 + 健康 + 主动触发），失败会无声影响 turn-end 信号 |
| **Quality Exception** | None — 不接受 MVP 路径 |

<!-- Regex markers for task-guard (do not delete) -->

- MVP/prototype requested by user: no
- Quality Exception: None
| **Mature Solution Evidence Required** | Yes — 详见 `analysis.md` §Mature Solution Evidence |
| **Test Coverage Minimum** | 新增 scheduler 代码行覆盖率 ≥ 80%（pytest `services/runtime/tests/test_scheduler.py`） |
| **Backwards Compatibility** | **MUST** — `services/jinli_daemon.py` 不删；`IdleTrigger.start()` API 不变（其内部 AsyncIOScheduler 退化为 no-op） |

## Authority Policy

- Authority profile: issuer-worker-v1
- External workers: no
- Worker capability: standard (Implement phase only)
- Packet mutation authority: issuer only
- Review authority: original issuer only
- Verify authority: original issuer only
- Archive authority: original issuer only
- Verify auto-archive: forbidden
- Issuer SID/key: PENDING_USER_CONFIRMATION

Authority Profile: **issuer-worker-v1** — Plan 阶段由金璃小天才签发，Implement 阶段交金璃好帮手（worker），Verify 阶段回金璃小天才（Issuer re-verifies）。

| Authority | Permissions |
|-----------|-------------|
| **Issuer (金璃小天才)** | 写 spec.md / analysis.md / routing.md / tasks.md / doc-impact.md；签发 packet；Review + Verify 阶段签字 |
| **Worker (金璃好帮手)** | 读 packet；写实现代码；提交 `worker-submit.ps1`；不能修改 packet 自身 |
| **Ba Ba (User)** | 拍板 3 个决策点（D1/D2/D3/D4）；批准 Plan → Implement 转换；final accept |

**Authority Boundary Rules**：
- ❌ Worker 不能修改 `routing.md` / `analysis.md` / `spec.md` / `tasks.md` / `doc-impact.md` / `.task.yaml` / `contract.yaml`
- ❌ Worker 不能声称 "完成" — 必须通过 `worker-submit.ps1 submit` 提交
- ❌ Worker 不能调用 `task-state.ps1 set review_result` / `verify_result`
- ✅ Worker 可以创建/修改实现代码文件（`services/runtime/scheduler.py` 等）
- ✅ Issuer (Plan 阶段) 可以创建/修改所有 packet 文件

## User Confirmation Blockers

本任务的 3 个决策点（详见 `analysis.md` §Mature Solution Evidence 后的 ⚠️ 决策小节）：

| # | 决策 | 默认建议 | Ba Ba 拍板 |
|---|------|---------|-----------|
| D1 | scheduler 类型 | BackgroundScheduler（用户已明确） | ✅ 不需拍板 |
| D2 | legacy `services/jinli_daemon.py` 9 线程处理 | A（保留不动） | ✅ **A — 保留** |
| D3 | Phase 1/2 async 桥接 | X（用户原话）+ Y（Phase 2 独立 task） | ✅ **X — 先 sync 再 async** |
| D4 | scheduler 频率配置化 | α（硬编码，后续 task 加 yaml） | ✅ **β — 本任务加 yaml（WP08）** |

## Work Package Policy

- External workers: no
- Worker profile: standard
- Work packages: WP01-WP08 (8 个 WP，详见 tasks.md — 含 WP08 scheduler_config.yaml 由 D4=β 决定)

每个 WP 必须满足：
1. **可独立运行** — WP-N 完成后 daemon 启动时该功能就位，不依赖未完成的 WP
2. **不引入新 thread pool** — 所有定时任务归 `DaemonScheduler` 一根线程（BackgroundScheduler 默认 10 worker 改 3 worker）
3. **每 WP 必带 pytest** — `services/runtime/tests/` 或 `services/<svc>/tests/`
4. **Phase 1 标志清晰** — `services/runtime/scheduler_bridge.py` 含 `# PHASE_1_SYNC_WRAPPER` / `# PHASE_2_ASYNCIO_LOOP` 注释分段
5. **WP07 前不退役旧代码** — legacy `services/jinli_daemon.py` 在 WP07 才标 deprecated

## Document References

| Doc | Purpose |
|-----|---------|
| `analysis.md` | 完整技术分析 + 成熟方案证据 + 架构约束 + 验收标准 |
| `spec.md` | 行为规范 (GIVEN/WHEN/THEN scenarios) |
| `tasks.md` | 任务清单 + 依赖图 + 验证标准 |
| `doc-impact.md` | 文档治理影响范围 + 治理检查 |

## Handoff Status

- [x] routing.md created
- [x] analysis.md — writing
- [x] spec.md — writing
- [x] tasks.md — writing (WP01-WP08)
- [x] doc-impact.md — writing
- [x] User confirmation obtained (Ba Ba 拍板 D2=A, D3=X, D4=β)
- [x] Ready for handoff to 金璃好帮手

---

## ⚠️ 3 个待 Ba Ba 拍板的决策点

小璃已尽量基于现有事实 + 用户原话推导出方案，但有 3 个决策仍需要 Ba Ba 拍板（否则 Implement 阶段容易走偏）：

### 决策 D1：scheduler 类型 — 用户已明确 ✅
- **用户原话**：`"daemon 起一个统一 APScheduler BackgroundScheduler (已在环境里，3.11.2 版本)"`
- **小璃确认**：选 **BackgroundScheduler**（sync）。无需 Ba Ba 拍板。

### 决策 D2：legacy `services/jinli_daemon.py` 的 9 个旧线程怎么办？🔴 需拍板
- 旧 daemon 有 9 个独立线程：`dreamer_reflection (30min)`、`obsidian_sync (10min)`、`health_check (30s)`、`vault_reindex (30min)`、`evolution_check (30min)`、`embedding_rebuild (24h)`、`knowledge_dedup (24h)`、`skill_curator (1h)`、`knowledge_health (2h)`
- **方案 A（推荐）**：本任务只动 `runtime/daemon.py`（WP01），legacy 9 线程**保留不动**；后续独立 task 退役。**优点**：风险最小，不破坏现存脚本；**缺点**：scheduler 统一性不完整
- **方案 B**：把 9 个旧线程也迁到 DaemonScheduler（总 15 个 jobs）。**优点**：彻底统一；**缺点**：任务范围扩大 50%，需重启 legacy 相关测试
- **方案 C**：把 9 个旧线程整体退役（保留文件但停用）。**优点**：最干净；**缺点**：依赖旧 daemon 的脚本（如 PowerShell `jinli-system.ps1`）可能需要适配

**小璃建议：A**（保留 legacy 不动，本任务聚焦 WP01-WP07 在 `runtime/daemon.py` 上）。Ba Ba 同意 A、B、还是 C？

**✅ Ba Ba 拍板：A — 保留 legacy 不动**。legacy `services/jinli_daemon.py` 文件保留不动；本次 scope 仅限 `services/runtime/daemon.py` + 新模块。

### 决策 D3：Async-to-sync 桥接的 Phase 1 vs Phase 2 边界 🔴 需拍板
- `IdleTrigger` 是 async（用 AsyncIOScheduler），EventBus 是 async（`publish()` awaitable）
- 统一 scheduler 是 sync（BackgroundScheduler）
- **方案 X（用户原话，Phase 1）**：scheduler 是 BackgroundScheduler，sync job 需要 async 时用 `asyncio.run_coroutine_threadsafe(coro, loop)` 桥接到 daemon 主 loop
- **方案 Y（Phase 2）**：scheduler 改成 AsyncIOScheduler，daemon 入口改成 async main
- **小璃建议**：严格按用户原话两阶段实施，**Phase 1 = BackgroundScheduler + sync wrapper（保留 AsyncIOScheduler 在 IdleTrigger 内部）+ `loop.call_soon_threadsafe` 桥接 EventBus**；Phase 2 单独 task 做

**小璃建议**：照此执行。Ba Ba 是否同意？

**✅ Ba Ba 拍板：X — 先 sync wrapper 再 async**。Phase 1 = BackgroundScheduler + `tick_via_scheduler(bridge)` 通过 `asyncio.run_coroutine_threadsafe` 提交；Phase 2 单独 task 做（不在本次 scope）。

### 决策 D4：scheduler 频率从 config 还是硬编码？🟡 建议确认
- 用户原话给的是硬编码值（5s/60s/cron 03:00/30min/2h/5min）
- **方案 α（推荐）**：硬编码默认值在 `services/runtime/scheduler.py` 模块顶部，**未来**让 Ba Ba 后续 task 加 `daemon.scheduler.config.yaml` 覆盖。**优点**：本任务范围最小；**缺点**：Ba Ba 想调频率要改代码
- **方案 β**：本任务就加 `daemon.scheduler.config.yaml`。**优点**：Ba Ba 可调；**缺点**：范围 +20%

**小璃建议：α**（硬编码 + 后续 task 配置化）。Ba Ba 同意 α 还是 β？

**✅ Ba Ba 拍板：β — 本任务加 yaml**（`services/runtime/scheduler_config.yaml` + `SchedulerConfig.load()` loader 函数）。新增 WP08 承载此工作。