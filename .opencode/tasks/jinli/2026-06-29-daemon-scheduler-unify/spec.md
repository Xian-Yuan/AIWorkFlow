# Spec — DaemonScheduler 统一调度重构

> Generated: 2026-06-29 | Agent: 金璃小天才 | Phase: Plan
> Quick Status: 🟡 Planning | Tasks: 0/7 | Scenarios: 0/12

## GIVEN

**当前状态 (2026-06-29)**：
1. `JinliDaemon` (`services/runtime/daemon.py`) 是 WP01 single-authority daemon，含 `_run_loop` 5s 健康检查循环 + `ServiceRegistry.refresh_all()`
2. `services/memory/dreamer/triggers.py` 有 `TriggerScheduler` 启 3 个独立 thread 跑 `IdleTimeoutTrigger` / `ScheduledDreamTrigger` / `SessionEndTrigger`
3. `services/proactive/p1/triggers.py:IdleTrigger.start()` 内部启 `AsyncIOScheduler` 跑 5min idle tick
4. `services/evolution/evolution_service.py:EvolutionService.start()` 同步启动，但不自动周期性跑 `run_evolution_check()`
5. `services/runtime/after_turn_commit.py` 已定义 5 sink 字段（memory/event_bus/dreamer/proactive/evolution），但**3 个 sink (dreamer/proactive/evolution) 没有 `enqueue()` 实现** → turn-end 信号 dropped
6. `services/nervous/event_bus.py` 是 `asyncio.Queue` 异步事件总线，4 个相关 topic（`session.ended` / `task.verify.passed` / `task.verify.failed` / `dream.insight.generated`）当前无订阅者
7. `services/jinli_daemon.py` (607 行 legacy daemon) 有 9 个独立线程（**本任务不动**，决策 D2-A）
8. APScheduler 3.11.2 已在 env（proactive p1/triggers.py:244 用过）

## WHEN

按 WP01-WP07 顺序实施（详见 `tasks.md`）：
- **WP01**: 新建 `services/runtime/scheduler.py`（DaemonScheduler 类）+ 在 `daemon.py` `_run_loop` 替换 5s 块为 scheduler 健康检查 job
- **WP02**: 注册 6 个 jobs（health_check + dreamer.idle_check + dreamer.scheduled + evolution.check + evolution.auto_apply + proactive.idle_tick）
- **WP03**: 3 个 sink adapter 实现 `enqueue()` 方法
- **WP04**: 4 个 EventBus 订阅注册（session.ended / task.verify.passed / task.verify.failed / dream.insight.generated）
- **WP05**: 新建 `services/runtime/scheduler_bridge.py`（Phase 1 sync-to-async 桥接），拆分 `IdleTrigger._on_tick` 的 sync/async 边界
- **WP06**: 测试覆盖（scheduler 单测 + bridge 单测 + AfterTurnCommit 单测扩展 + 集成测试）
- **WP07**: 文档更新（runtime-protocol.md / daemon-runbook.md）

## THEN

### Module A: DaemonScheduler 核心（WP01）

#### S01 — DaemonScheduler 类存在且可启动
**GIVEN** `services/runtime/scheduler.py` 文件存在
**WHEN** `from services.runtime.scheduler import DaemonScheduler` + `s = DaemonScheduler()` + `s.start()`
**THEN** 返回实例；`s.start()` 不抛异常；`s._scheduler` 是 `apscheduler.schedulers.background.BackgroundScheduler` 实例；`s._scheduler.running == True`
**AND** `s.status_snapshot()` 返回 dict 含 `jobs` 列表（空，因为还没注册）+ `state: "running"` + `thread_count: int`

#### S02 — 健康检查 job 替换 _run_loop 5s 块
**GIVEN** `JinliDaemon.start()` 调用
**WHEN** daemon 启动后运行 8 秒
**THEN** `_run_loop` 不再 `time.sleep(5) + registry.refresh_all()`；改为单次注册 `scheduler.add_job(refresh_all, IntervalTrigger(seconds=5), id='health_check')`
**AND** `health_check` job 在 8 秒内至少触发 1 次（5s ± 调度漂移）
**AND** `_run_loop` 不再承担健康检查责任（仅负责 EventBus / scheduler 生命周期管理）
**AND** 旧行为（5s 内刷新所有 service）保留等价

#### S03 — 6 个 jobs 全部注册
**GIVEN** `DaemonScheduler` 启动
**WHEN** 调用 `s.register_default_jobs(dreamer_service, evolution_service, idle_trigger)`
**THEN** `s.status_snapshot()['jobs']` 含 6 个 entry，每个 entry 含 `id` / `next_run_time` / `trigger` / `func_name`
**AND** 6 个 job ids 分别是：`health_check` / `dreamer.idle_check` / `dreamer.scheduled` / `evolution.check` / `evolution.auto_apply` / `proactive.idle_tick`
**AND** 每个 job 的 `max_instances=1` + `coalesce=True` + `replace_existing=True`

### Module B: 3 个 Sink Adapter（WP03）

#### S04 — DreamerSink.enqueue() 实现
**GIVEN** `AfterTurnCommit.dreamer = DreamerSink()` 且 `dream_sink.enqueue` 可调用
**WHEN** 调用 `dream_sink.enqueue({"kind": "successful_turn", "manifest_id": "m-123", "mode": "strict"})`
**THEN** 返回 `True`（成功）
**AND** DreamerService 收到 enqueue 信号后调用 `DreamerService.run_cycle("turn_end", base_token_budget=2000)` 或类似入口
**AND** enqueue 内部异常被 try/except 捕获，返回 `False`（不让 commit 崩溃）

#### S05 — ProactiveSink.enqueue() 实现
**GIVEN** `AfterTurnCommit.proactive = ProactiveSink()` 已注册
**WHEN** 调用 `proactive_sink.enqueue({"kind": "session.ended", "subject": "..."})`
**THEN** 返回 `True`
**AND** 通过 `EventBus.publish("session.ended", payload)` 发布事件（如果有 session.ended 信号）
**AND** 异常时返回 `False`

#### S06 — EvolutionSink.enqueue() 实现
**GIVEN** `AfterTurnCommit.evolution = EvolutionSink()` 已注册
**WHEN** 调用 `evolution_sink.enqueue({"kind": "gate_failure", "manifest_id": "m-456", "violations": [...]})`
**THEN** 返回 `True`
**AND** EvolutionService 收到 enqueue 后调用 `EvolutionService.propose_self_improvement(reason=violations[0], ...)`
**AND** 异常时返回 `False`

### Module C: 4 个 EventBus 订阅（WP04）

#### S07 — session.ended 订阅
**GIVEN** EventBus 已启动且 `JinliDaemon.start()` 已注册订阅
**WHEN** 外部调用 `await bus.publish("session.ended", {"subject": "..."})`
**THEN** 注册的 handler `_on_session_ended(payload)` 在 < 100ms 内被调用
**AND** handler 内部触发 ProactiveSink 投递（或直调 memory recall bridge）

#### S08 — task.verify.passed / task.verify.failed 订阅
**GIVEN** EventBus 启动 + 订阅注册完成
**WHEN** `bus.publish("task.verify.passed", {"task": "...", "outcome": "passed"})`
**THEN** `_on_task_verify_passed()` 被调用，构造 proactive payload 并投递
**AND** 同理 task.verify.failed 触发 P0 主动关心

#### S09 — dream.insight.generated 订阅
**GIVEN** EventBus 启动 + 订阅注册完成
**WHEN** `bus.publish("dream.insight.generated", {"insight": "..."})`
**THEN** `_on_dream_insight()` 被调用，将 insight 推送给 proactive

### Module D: Phase 1 sync-to-async 桥接（WP05）

#### S10 — SchedulerBridge.run_async() 不 hang 不 deadlock
**GIVEN** daemon 主 asyncio loop 在 thread 3 运行，`SchedulerBridge(daemon_loop)` 实例化
**WHEN** 在 scheduler worker thread 调用 `bridge.run_async(some_coro, timeout=10.0)`
**THEN** coro 在 daemon_loop 上执行，timeout 内返回结果（或 raise TimeoutError）
**AND** 其他 scheduler job 不被阻塞（`bridge.run_async` 是 fire-and-cancel，不占 worker）
**AND** 测试中 50 次连续调用无 deadlock

#### S11 — IdleTrigger 拆 sync/async
**GIVEN** `services/proactive/p1/triggers.py:IdleTrigger`
**WHEN** WP05 完成后
**THEN** 现有 `IdleTrigger._on_tick()` 拆为：
  - `IdleTrigger.evaluate_idle() -> float` (sync pure) — 返回 idle_s
  - `IdleTrigger.process_idle_async(idle_s) -> None` (async) — 调用 manager.process_event
**AND** 现有 API（`IdleTrigger.start() / stop() / update_user_activity() / get_idle_seconds()`）保持兼容
**AND** 当 DaemonScheduler 接管时，`IdleTrigger.start()` 内部检测 `DaemonScheduler` 已注册 `proactive.idle_tick` job，标记 `self._scheduler = None`（不再启 AsyncIOScheduler）

### Module E: 文档与运维（WP07）

#### S12 — /status 端点暴露 scheduler 状态
**GIVEN** daemon 启动 + scheduler 注册了 jobs
**WHEN** 外部调用 `GET http://127.0.0.1:<port>/status`
**THEN** 返回 JSON 含 `scheduler` 字段：
```json
{
  "scheduler": {
    "state": "running",
    "thread_count": 4,
    "jobs": [
      {"id": "health_check", "next_run_time": "2026-06-29T...", "trigger": "interval[0:00:05]"},
      {"id": "dreamer.idle_check", "next_run_time": "...", "trigger": "interval[0:01:00]"},
      ...
    ]
  }
}
```

---

### Module F: Scheduler 配置化（WP08 — 由 D4=β 拍板新增）

#### S13 — scheduler_config.yaml 加载 + 缺省降级 + 字段验证
**GIVEN** daemon 启动 + `services/runtime/scheduler_config.yaml` 存在且字段合法
**WHEN** `DaemonScheduler.__init__(config_path='services/runtime/scheduler_config.yaml')` 被调用
**THEN** scheduler 加载 yaml，6 个 jobs 用 yaml 配置的 trigger 参数；`/status.scheduler.source = "yaml: services/runtime/scheduler_config.yaml"`

**GIVEN** yaml 文件不存在（`/tmp/missing.yaml`）
**WHEN** `DaemonScheduler.__init__(config_path='/tmp/missing.yaml')` 被调用
**THEN** scheduler 降级到 `default_config()`（6 个 jobs 用 WP01 硬编码默认值）；`/status.scheduler.source = "hardcoded: defaults"`；不抛异常

**GIVEN** yaml 文件存在但字段非法（如 cron 缺 `hour+minute`，interval 缺 `seconds`）
**WHEN** `load_from_yaml(path)` 被调用
**THEN** 抛 `SchedulerConfigValidationError` 含具体字段名；daemon 启动失败（fail-closed）

**GIVEN** yaml 文件存在但 jobs 列表为空（`jobs: []`）
**WHEN** `load_from_yaml(path)` 被调用
**THEN** 抛 `SchedulerConfigValidationError("jobs list cannot be empty, expected 6 default jobs")`；daemon 启动失败

---

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | DaemonScheduler 类创建并启动 | `python -c "from services.runtime.scheduler import DaemonScheduler; s=DaemonScheduler(); s.start(); print(s.status_snapshot())"` | dict 含 `state: "running"` + `jobs: []` |
| AC02 | 6 jobs 全部注册 | `python -c "from services.runtime.scheduler import DaemonScheduler; ..."` | jobs list 含 6 个 entry，ids 与 spec S03 一致 |
| AC03 | health_check 5s 内触发 | `pytest services/runtime/tests/test_scheduler.py::test_health_check_triggers_within_5s` | 测试通过 |
| AC04 | dreamer.idle_check 60s 触发 | `pytest services/runtime/tests/test_scheduler.py::test_dreamer_idle_check_interval` | 测试通过（用 mock clock） |
| AC05 | evolution.check 30min 触发 | `pytest services/runtime/tests/test_scheduler.py::test_evolution_check_interval` | 测试通过 |
| AC06 | DreamerSink.enqueue 投递成功 | `pytest services/runtime/tests/test_after_turn_commit.py::test_dreamer_sink_enqueue` | 测试通过，返回 True |
| AC07 | ProactiveSink.enqueue 投递成功 | `pytest services/runtime/tests/test_after_turn_commit.py::test_proactive_sink_enqueue` | 测试通过，返回 True |
| AC08 | EvolutionSink.enqueue 投递成功 | `pytest services/runtime/tests/test_after_turn_commit.py::test_evolution_sink_enqueue` | 测试通过，返回 True |
| AC09 | turn-end 不再 dropped | `pytest services/runtime/tests/test_after_turn_commit.py -v` | 所有测试通过；notes 不含 `*_sink_unavailable` |
| AC10 | 4 个 EventBus 订阅注册 | `pytest services/nervous/tests/test_event_bus.py -k "session.ended or task.verify or dream.insight"` | 4 测试通过 |
| AC11 | SchedulerBridge 不 deadlock | `pytest services/runtime/tests/test_scheduler_bridge.py::test_50_calls_no_deadlock` | 测试通过（50 次 run_async 无 hang） |
| AC12 | IdleTrigger 兼容旧 API | `pytest services/proactive/p1/tests/test_integration.py` | 现有测试全部通过 |
| AC13 | daemon 启动后线程数增量 ≤ 4 | `python .trae/../scripts/check_thread_count.py` | 增量 = 4（scheduler thread + 3 worker） |
| AC14 | daemon.stop 30s 内完成 | `pytest services/runtime/tests/test_daemon.py -k "stop"` | 所有 stop 测试通过 |
| AC15 | /status 端点暴露 scheduler | `curl http://127.0.0.1:$PORT/status \| jq .scheduler.jobs \| length` | 输出 6 |
| AC16 | scheduler_config.yaml 加载 | `pytest services/runtime/tests/test_scheduler_config.py -v` | 全部测试通过；缺省值正确；坏 yaml 抛 ValidationError |

## Quality Checklist

> 在 Plan 阶段完成后由创建者填写，Implement 阶段开始前必须通过所有项。

### Completeness
- [x] [OK] 所有功能需求都在 spec 中覆盖（6 jobs + 4 events + 3 sinks + 1 yaml config）
- [x] [OK] 每个 Module/Scenario 有明确的输入条件和预期输出
- [x] [OK] Acceptance Criteria 覆盖所有主要场景（16 ACs ≥ 13 Scenarios）

### Clarity
- [x] [OK] GIVEN/WHEN/THEN 中没有歧义表述（具体方法签名 + 行号引用见 analysis.md §11）
- [x] [OK] 技术术语已定义或链接到项目术语表（BackgroundScheduler / Coalesce / Misfire 等见 analysis.md §4）
- [x] [OK] 第三方依赖/外部系统交互已明确标注（APScheduler 3.11.2 + EventBus async）

### Consistency
- [x] [OK] spec 中的术语与项目已有术语保持一致（参考 `Project/Jinli/docs/04-Implementation/runtime-protocol.md`）
- [x] [OK] 模块划分与项目的文件放置约定一致（`Docs/AI/13-File-Placement-Convention.md` — runtime/ 加新模块）
- [x] [OK] 与已有类似功能的 spec 对比，没有模式冲突（与 T7/T8/T9 task packages 兼容）

### Scenario Coverage
- [x] [OK] 所有模块有对应的验收场景（5 modules × 2-3 scenarios = 12 scenarios）
- [x] [OK] 主路径场景至少 1 个（S01-S03 Happy Path）
- [x] [OK] 边界条件场景至少 1 个（S04-S06 sink 异常分支）
- [x] [OK] 错误路径场景至少 1 个（S10 bridge timeout）

### Edge Case Coverage
- [x] [OK] 空值/零值场景已考虑（S03 jobs 列表初始空；S04-06 sink 内部 try/except）
- [x] [OK] 并发/时序竞争场景已考虑（S10 50 次连续调用；S02 health_check 与 scheduler 并发）
- [x] [OK] 资源不足（内存/磁盘/网络）场景已考虑（in-flight job 监控 + misfire_grace_time）
- [x] [OK] 取消/中断/超时场景已考虑（S10 bridge timeout；S06 graceful stop）

### Usage Guidance
- [x] [OK] 5 个 Quality Level 全填了状态
- [x] [Resolved] **D2 决策**（legacy daemon 处理）：Ba Ba 拍板 A — 保留
- [x] [Resolved] **D3 决策**（async 桥接）：Ba Ba 拍板 X — 先 sync 再 async
- [x] [Resolved] **D4 决策**（scheduler 频率配置化）：Ba Ba 拍板 β — 本任务加 yaml（WP08）

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | ✅ **Confirmed** (Ba Ba 拍板 D2=A, D3=X, D4=β) | 2026-06-29 |
| Implement | ⬜ Pending | — |
| Review | ⬜ Pending | — |
| Verify | ⬜ Pending | — |

## Non-Goals

- ❌ 退役 legacy `services/jinli_daemon.py` (决策 D2-A 不在本任务)
- ❌ 改 daemon 主线程模型为 async (Phase 2 独立 task)
- ✅ **加 `scheduler_config.yaml`** (决策 D4=β，本任务 WP08)
- ❌ 拆 `services/runtime/daemon.py` 为多文件 (超 scope)
- ❌ 引入新依赖（用 stdlib `asyncio.run_coroutine_threadsafe`）

## Verification & Plain-Language Summary

After all AC checks pass, the verifier MUST provide:

### Plain-language summary

- **之前 vs 现在**：
  - **之前**：金璃的"调度大脑"散在 5 个地方——daemon 自己一个 5s 循环、dreamer 三个独立线程、proactive 自己又启一个 APScheduler……每次加一个新定时任务都得开新线程。turn-end 的时候，dream/evolution/proactive 三个信号因为 sink 没写 enqueue 函数，**直接被丢掉**，Ba Ba 看不到 dream 整合、看不到进化建议、看不到主动关心
  - **现在**：daemon 起一个统一的调度器（APScheduler BackgroundScheduler），所有定时任务（健康检查、dreamer 闲时检查、evolution 周期检查、proactive 闲时 tick）都登记在它名下；turn-end 的信号通过 3 个新的 sink adapter 真正投递到 dream/evolution/proactive；4 个事件（会话结束 / 任务通过 / 任务失败 / dream 洞察）由 EventBus 订阅触发对应行为

- **一句话总结**：把 5 个分散的调度器合并成 1 个 + 接通 3 个掉线的信号通路 + 加 4 个事件订阅，从此 Ba Ba 不会错过金璃的主动关心、dream 整合和进化建议

- Focus on *what the user can now do that they couldn't before*：
  - Ba Ba 关闭会话后，能在金璃下次说话时看到 dream 整合出的洞察（之前被丢了）
  - Ba Ba 任务失败时，金璃会主动发 P0 关心（之前信号丢了）
  - Ba Ba 长时间不动电脑，金璃会主动问候（之前 idle 检查分散在 3 个 trigger）

### No completion claim without fresh verification evidence

详见 `verification-before-completion` skill 与 `verification-report.md`（由 Verifier 在 Verify 阶段产出）