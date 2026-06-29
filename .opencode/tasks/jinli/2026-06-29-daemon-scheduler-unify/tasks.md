# Tasks — DaemonScheduler 统一调度重构

> Generated: 2026-06-29 | Agent: 金璃小天才 | Phase: Plan
> Total Tasks: 8 | Scenarios: 13 | Work Packages: 8 (WP08 由 D4=β 拍板新增)

---

## Dependency Graph

```
WP01 (Scheduler Core)
   ├─→ WP02 (6 Jobs Register)
   ├─→ WP03 (3 Sink Adapters)
   │      └─→ WP06 (Tests) ←──── WP04 (EventBus Subs)
   │                              └─→ WP05 (Sync Wrapper)
   │                                     └─→ WP06 (Tests)
   ├─→ WP04 (EventBus Subs)
   ├─→ WP05 (Sync Wrapper)
   │      └─→ WP06 (Tests)
   ├─→ WP08 (Scheduler Config YAML) ←── Ba Ba 拍板 D4=β
   │      └─→ WP06 (Tests) ──→ WP07 (Docs + API Endpoint Update)
   └─→ WP06 (Tests) ←──── WP02 (6 Jobs Register)
WP06 (Tests) ──→ WP07 (Docs + API Endpoint Update)

Sequential dependency:
WP01 → {WP02, WP03, WP04, WP05, WP08} → WP06 → WP07
```

详细依赖：
- WP02, WP03, WP04, WP05, WP08 都可以在 WP01 完成后并行（但建议顺序）
- WP06 必须等 WP02-WP05 + WP08 全部完成
- WP07 必须等 WP06 完成（WP06 通过后才写文档）

---

## WP01 — Scheduler Core [P0] 🔧 Foundation

**Covering Scenarios**: S01, S02, S03
**Covering ACs**: AC01, AC02, AC03

**Description**: 创建 `services/runtime/scheduler.py`（新文件），定义 `DaemonScheduler` 类 + `JobSpec` dataclass + 6 个 job 默认配置常量。在 `services/runtime/daemon.py` 中：
- 替换 `_run_loop` 中 5s 健康检查块为 `scheduler.add_job(refresh_all, IntervalTrigger(seconds=5), id='health_check')`
- 保留 `_run_loop` 主线程（管 EventBus + scheduler 生命周期）
- 在 `JinliDaemon.start()` 中实例化 `DaemonScheduler` 并启动
- 在 `JinliDaemon.stop()` 中先 `scheduler.stop(timeout=30.0)` 再走原 stop 流程

**Subtasks**:
1. 创建 `services/runtime/scheduler.py`：
   - `JobSpec` dataclass：`id, name, func, trigger, kwargs, max_instances=1, coalesce=True, replace_existing=True`
   - `DaemonScheduler` 类：
     - `__init__(timezone='Asia/Shanghai', executor_workers=3)`
     - `start() -> None` — 启动 BackgroundScheduler
     - `stop(timeout: float = 30.0) -> None` — 优雅停
     - `add_job(spec: JobSpec) -> None` — 注册单 job
     - `register_default_jobs(dreamer, evolution, idle_trigger) -> None` — 一次性注册 6 jobs
     - `status_snapshot() -> Dict[str, Any]` — 返回 jobs / state / thread_count
     - 6 个 job 默认配置常量：`HEALTH_CHECK_JOB` / `DREAMER_IDLE_CHECK_JOB` / `DREAMER_SCHEDULED_JOB` / `EVOLUTION_CHECK_JOB` / `EVOLUTION_AUTO_APPLY_JOB` / `PROACTIVE_IDLE_TICK_JOB`
2. 修改 `services/runtime/daemon.py`：
   - `_run_loop`：5s 块替换为 `if self._scheduler: self._scheduler._scheduler.print_jobs()  # debug only` 然后 `time.sleep(60)`（主线程长轮询调度状态，scheduler 自己处理 5s 健康检查）
   - `start()`：在最后 `self._scheduler.start(); self._scheduler.register_default_jobs(...)`
   - `stop()`：在开始 `if self._scheduler: self._scheduler.stop(timeout=30.0)`
3. 创建 `services/runtime/tests/test_scheduler.py`：
   - `test_scheduler_class_creates_and_starts`（覆盖 AC01）
   - `test_health_check_replaces_5s_loop`（覆盖 AC02/AC03）
   - `test_register_default_jobs_adds_six`（覆盖 AC03）

**Files**:
- `services/runtime/scheduler.py` (NEW)
- `services/runtime/daemon.py` (MODIFY — _run_loop + start + stop)
- `services/runtime/tests/test_scheduler.py` (NEW)

**Out of scope**:
- 6 个 job 的具体实现（WP02）
- EventBus 订阅（WP04）
- 3 sink enqueue（WP03）
- sync/async 桥接（WP05）

**Dependencies**: None

**Verification**:
```powershell
pytest services/runtime/tests/test_scheduler.py -v
```
预期：3 个测试全部通过；scheduler.status_snapshot() 返回 6 个 jobs。

---

## WP02 — 6 Timed Jobs 注册 [P0] 🔧 Core

**Covering Scenarios**: S03
**Covering ACs**: AC02, AC03, AC04, AC05

**Description**: 在 `DaemonScheduler.register_default_jobs()` 中实现 6 个 job 的实际触发逻辑。Dreamer/Evolution 直接 sync；Proactive idle tick 用 sync wrapper（WP05 桥接）。

**Subtasks**:
1. `HEALTH_CHECK_JOB` — `func = registry.refresh_all`, `trigger = IntervalTrigger(seconds=5)`
2. `DREAMER_IDLE_CHECK_JOB` — `func = lambda: dreamer_service.idle_check()`, `trigger = IntervalTrigger(seconds=60)`
   - 新增 `DreamerService.idle_check()` 方法（在 `services/memory/dreamer/triggers.py`）：
     - 读取 `last_user_input_ts`（同步）
     - 如果 `now - last_user_input_ts > 30min`，调用 `self.run_cycle("idle_timeout")`
3. `DREAMER_SCHEDULED_JOB` — `func = lambda: dreamer_service.run_cycle("scheduled_dream", 50000)`, `trigger = CronTrigger(hour=3, minute=0)`
4. `EVOLUTION_CHECK_JOB` — `func = lambda: evolution_service.run_evolution_check()`, `trigger = IntervalTrigger(seconds=1800)` (30 min)
5. `EVOLUTION_AUTO_APPLY_JOB` — `func = lambda: evolution_service.auto_apply_low_risk()`, `trigger = IntervalTrigger(seconds=7200)` (2 hour)
6. `PROACTIVE_IDLE_TICK_JOB` — `func = lambda: idle_trigger.tick_via_scheduler()`, `trigger = IntervalTrigger(seconds=300)` (5 min)
   - `idle_trigger.tick_via_scheduler()` = sync 方法（WP05 详细设计）：
     - `idle_s = self.get_idle_seconds()`（sync pure）
     - 如果 `idle_s >= self._idle_threshold`：`asyncio.run_coroutine_threadsafe(self._async_dispatch(idle_s), self._daemon_loop)`
     - `_async_dispatch(idle_s)` = `await self._manager.process_event(self.TICK_TOPIC, payload, source_event=None)`
7. 加测试：mock clock 验证 4 个 interval job 的 `next_run_time` 正确，cron job 在 `2026-06-30T03:00:00+08:00` 触发

**Files**:
- `services/runtime/scheduler.py` (MODIFY — register_default_jobs 实现)
- `services/memory/dreamer/triggers.py` (MODIFY — 新增 `DreamerService.idle_check()`)
- `services/proactive/p1/triggers.py` (MODIFY — 新增 `tick_via_scheduler()` + `_async_dispatch()`)
- `services/runtime/tests/test_scheduler.py` (MODIFY — 加 interval / cron 测试)

**Out of scope**:
- sink adapter（WP03）
- EventBus 订阅（WP04）
- bridge 实现（WP05）

**Dependencies**: WP01

**Verification**:
```powershell
pytest services/runtime/tests/test_scheduler.py -v -k "interval or cron or six_jobs"
```
预期：6 个 jobs 全部触发；trigger 类型正确；next_run_time 符合预期。

---

## WP03 — 3 Sink Adapters [P0] 🔧 Core

**Covering Scenarios**: S04, S05, S06
**Covering ACs**: AC06, AC07, AC08, AC09

**Description**: 给 `services/runtime/adapters/dreamer_adapter.py` / `proactive_adapter.py` / `evolution_adapter.py` 三个 adapter 真正实现 `enqueue(payload) -> bool` 方法，解决 turn-end 信号 dropped 问题。

**Subtasks**:
1. `DreamerAdapter.enqueue(payload)`：
   - try/except 包裹
   - payload 内部提取：`kind` / `manifest_id` / `mode`
   - 调用 `DreamerService.run_cycle(trigger_type="turn_end", base_token_budget=2000)`
   - 成功返回 True，异常返回 False（log warning）
2. `ProactiveAdapter.enqueue(payload)`：
   - try/except
   - payload 提取 `kind` / `subject`
   - 如果 EventBus 可用且 payload 含 `subject`：通过 `SchedulerBridge.run_async(bus.publish("session.ended", payload))` 发布
   - 否则写 proactive_messages.jsonl 一条 deferred 信号
3. `EvolutionAdapter.enqueue(payload)`：
   - try/except
   - payload 提取 `kind` / `manifest_id` / `violations`
   - 调用 `EvolutionService.propose_self_improvement(reason=violations[0] if violations else "unknown", target_layer="principles", risk_class="low", diff_summary=..., expected_effect=...)`
   - 成功返回 True
4. 测试：3 个 sink 各自 unit test；turn-end 全流程 test（gate_failure → evolution sink → evolution proposal）

**Files**:
- `services/runtime/adapters/dreamer_adapter.py` (MODIFY — 加 enqueue)
- `services/runtime/adapters/proactive_adapter.py` (MODIFY — 加 enqueue)
- `services/runtime/adapters/evolution_adapter.py` (MODIFY — 加 enqueue)
- `services/runtime/tests/test_after_turn_commit.py` (MODIFY — 加 3 sink 测试 + 全流程)
- `services/runtime/adapters/tests/test_dreamer_adapter.py` (NEW)
- `services/runtime/adapters/tests/test_proactive_adapter.py` (NEW)
- `services/runtime/adapters/tests/test_evolution_adapter.py` (NEW)

**Out of scope**:
- SchedulerBridge（WP05）
- EventBus 订阅（WP04）
- API endpoint（WP07）

**Dependencies**: WP01

**Verification**:
```powershell
pytest services/runtime/tests/test_after_turn_commit.py -v
```
预期：所有测试通过；notes 不再出现 `*_sink_unavailable`。

---

## WP04 — 4 EventBus Subscriptions [P0] 🔧 Core

**Covering Scenarios**: S07, S08, S09
**Covering ACs**: AC10

**Description**: 在 `JinliDaemon.start()` 中注册 4 个 EventBus 订阅 handler，把这些事件桥接到对应业务（dreamer/proactive/evolution）。

**Subtasks**:
1. 在 `services/runtime/daemon.py:JinliDaemon.start()` 中加：
   ```python
   if self._event_bus is not None:
       await self._event_bus.subscribe("session.ended", self._on_session_ended)
       await self._event_bus.subscribe("task.verify.passed", self._on_task_verify_passed)
       await self._event_bus.subscribe("task.verify.failed", self._on_task_verify_failed)
       await self._event_bus.subscribe("dream.insight.generated", self._on_dream_insight)
   ```
   注：`JinliDaemon.start()` 当前是 sync，要先检查；如果 start 是 sync，则改成在 `start_async` 或单独 `_register_event_subscriptions()` 方法中调。
2. 实现 4 个 handler（async）：
   - `_on_session_ended(payload)` — 调 proactive sink (via SchedulerBridge) 或 memory recall bridge
   - `_on_task_verify_passed(payload)` — 调 proactive sink
   - `_on_task_verify_failed(payload)` — 调 proactive sink P0 + evolution sink
   - `_on_dream_insight(payload)` — 调 proactive sink dream_insight_share
3. 测试：4 个 handler 都能被正确触发；payload 正确传递；handler 异常不导致 daemon crash

**Files**:
- `services/runtime/daemon.py` (MODIFY — 加 4 个 handler + 注册逻辑)
- `services/nervous/tests/test_event_bus.py` (MODIFY — 加 subscription test)

**Out of scope**:
- handler 内部调用 proactive sink 的具体逻辑（WP03 sink 已实现）
- bridge（WP05）

**Dependencies**: WP01

**Verification**:
```powershell
pytest services/nervous/tests/test_event_bus.py -v -k "subscription"
```
预期：4 个订阅测试通过。

---

## WP05 — Phase 1 sync-to-async Bridge [P1] 🔧 Core

**Covering Scenarios**: S10, S11
**Covering ACs**: AC11, AC12

**Description**: 新建 `services/runtime/scheduler_bridge.py`，实现 `SchedulerBridge` 类封装 `asyncio.run_coroutine_threadsafe`。同时把 `IdleTrigger._on_tick` 拆为 sync/async 两部分。

**Subtasks**:
1. 创建 `services/runtime/scheduler_bridge.py`：
   ```python
   class SchedulerBridge:
       """Phase 1 sync-to-async bridge.
       
       在 BackgroundScheduler worker thread（sync 上下文）和 daemon 主 asyncio loop 之间桥接。
       """
       
       def __init__(self, daemon_loop: asyncio.AbstractEventLoop, *, default_timeout: float = 30.0):
           self._daemon_loop = daemon_loop
           self._default_timeout = default_timeout
       
       def run_async(self, coro: Coroutine, *, timeout: Optional[float] = None) -> Any:
           future = asyncio.run_coroutine_threadsafe(coro, self._daemon_loop)
           t = timeout if timeout is not None else self._default_timeout
           try:
               return future.result(timeout=t)
           except concurrent.futures.TimeoutError:
               future.cancel()
               raise SchedulerBridgeTimeout(f"coro timeout after {t}s")
       
       def schedule_async(self, coro: Coroutine) -> None:
           asyncio.run_coroutine_threadsafe(coro, self._daemon_loop)
       
       # Phase 2 placeholder (do not implement in Phase 1)
       # PHASE_2_ASYNCIO_LOOP:
       # - 改用 AsyncIOScheduler
       # - 移除 SchedulerBridge
   ```
2. 修改 `services/proactive/p1/triggers.py:IdleTrigger`：
   - 保留 `get_idle_seconds()`（sync pure）
   - 保留 `_on_tick()` 兼容（内部转发到 `evaluate_idle()` + `process_idle_async()`）
   - 新增 `evaluate_idle() -> float` — sync pure
   - 新增 `process_idle_async(idle_s: float) -> None` — async, 调 manager.process_event
   - 新增 `tick_via_scheduler(bridge: SchedulerBridge) -> None` — sync 包装
   - 在 `__init__` 加 `self._scheduler_owned: bool = True`，`start()` 时若 DaemonScheduler 已接管 idle_tick，设为 False（不启 AsyncIOScheduler）
3. 在 `JinliDaemon.start()` 中：
   - 检测 EventBus loop：`self._daemon_loop = asyncio.new_event_loop(); self._daemon_loop_thread = threading.Thread(target=self._daemon_loop.run_forever, daemon=True); self._daemon_loop_thread.start()`
   - 实例化 `self._scheduler_bridge = SchedulerBridge(self._daemon_loop)`
   - 传给 IdleTrigger：`self._idle_trigger.tick_via_scheduler(self._scheduler_bridge)`
4. 测试：
   - `test_scheduler_bridge_no_deadlock_50_calls`（AC11）
   - `test_idle_trigger_compatibility`（AC12 — 确保旧 API 没破坏）

**Files**:
- `services/runtime/scheduler_bridge.py` (NEW)
- `services/proactive/p1/triggers.py` (MODIFY — 拆 sync/async)
- `services/runtime/daemon.py` (MODIFY — 启 daemon loop thread + 实例化 bridge)
- `services/runtime/tests/test_scheduler_bridge.py` (NEW)
- `services/proactive/p1/tests/test_integration.py` (MODIFY — 加 compatibility test)

**Out of scope**:
- 改 daemon 主线程为 async（Phase 2 独立 task）
- scheduler 类型改 AsyncIOScheduler（Phase 2）

**Dependencies**: WP02 (scheduler 已注册 proactive.idle_tick)

**Verification**:
```powershell
pytest services/runtime/tests/test_scheduler_bridge.py services/proactive/p1/tests/test_integration.py -v
```
预期：bridge 50 次调用无 deadlock；IdleTrigger 旧测试全部通过。

---

## WP06 — Tests [P0] 🔧 Quality

**Covering ACs**: AC01-AC15（全部）

**Description**: 汇总所有测试 + 验证覆盖率 + 集成测试。

**Subtasks**:
1. 跑全部 runtime 测试：
   ```powershell
   pytest services/runtime/tests/ -v --tb=short --cov=services/runtime --cov-report=term-missing
   ```
   预期：159+ 测试全部通过（原有 159 个 + 新增 ~30 个）
2. 跑 3 个子服务（dreamer/evolution/proactive）相关测试：
   ```powershell
   pytest services/memory/dreamer/tests/ services/evolution/tests/ services/proactive/p1/tests/ -v
   ```
3. 跑 nervous event_bus 测试：
   ```powershell
   pytest services/nervous/tests/ -v
   ```
4. 集成测试（手动 + 自动化）：
   - 启 daemon → 检查 `/status` → 看到 scheduler 6 jobs
   - 等 10 秒 → 检查 health_check job `last_run_time` 更新
   - 模拟 gate failure → 检查 evolution sink → 看到 evolution proposal
   - publish `session.ended` → 检查 handler 被调用
5. 覆盖率报告：scheduler.py / scheduler_bridge.py / 3 adapters → 覆盖率 ≥ 80%

**Files**:
- 无新增文件，仅跑现有 + WP01-WP05 新增测试

**Out of scope**:
- 文档更新（WP07）
- 退役 legacy daemon

**Dependencies**: WP02, WP03, WP04, WP05

**Verification**:
```powershell
pytest services/ -v --tb=short -x --ignore=services/jinli_daemon.py
```
预期：所有测试通过；scheduler / bridge / 3 adapters 覆盖率 ≥ 80%。

---

## WP07 — 文档 + API Endpoint [P0] 🔧 Quality

**Covering Scenarios**: S12
**Covering ACs**: AC15

**Description**: 更新 `runtime-protocol.md` / `runtime-daemon-runbook.md` 文档 + 给 `/status` 端点加 scheduler 字段。

**Subtasks**:
1. 修改 `services/runtime/api_server.py:DaemonAPIServer` 的 `/status` 端点：
   - 在响应 JSON 中加 `scheduler` 字段
   - 调用 `daemon._scheduler.status_snapshot()` 获取状态
2. 修改 `Project/Jinli/docs/04-Implementation/runtime-protocol.md`：
   - 加 §Scheduler 章节（位置：runtime-protocol.md:38-54 之前）
   - 内容：6 jobs / 4 subscriptions / 3 sinks / Phase 1 bridge
3. 修改 `Project/Jinli/docs/06-Operations/General/runtime-daemon-runbook.md`：
   - 加 scheduler 运维说明：如何看 jobs、stop / start、监控指标
   - 加常见故障排查（job hang / sink dropped）
4. 更新 `Project/Jinli/services/runtime/daemon.py` 的 docstring，说明 `_run_loop` 现在是调度器管理线程，不是健康检查线程
5. 更新 `docs/03-Architecture/KnowledgeGraph/runtime-architecture.md`（如果存在）：把 `JinliDaemon` 章节里加 scheduler 引用

**Files**:
- `services/runtime/api_server.py` (MODIFY — /status endpoint)
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md` (MODIFY — §Scheduler)
- `Project/Jinli/docs/06-Operations/General/runtime-daemon-runbook.md` (MODIFY — scheduler 运维)
- `services/runtime/daemon.py` (MODIFY — docstring)
- `docs/03-Architecture/KnowledgeGraph/runtime-architecture.md` (MODIFY — 如存在)

**Out of scope**:
- 退役 legacy `services/jinli_daemon.py`（决策 D2-A 不在本任务）
- 修改 `services/jinli_daemon.py` 任何代码

**Dependencies**: WP06

**Verification**:
```powershell
# API endpoint
python -c "import requests; r = requests.get('http://127.0.0.1:PORT/status'); print(r.json()['scheduler']['jobs'][0])"

# Doc placement
python .trae/scripts/check-doc-placement.py
```
预期：API 返回 scheduler.jobs 非空；doc-placement 检查通过。

---

## WP08 — Scheduler Config YAML [P0] 🔧 Foundation (D4=β)

**Covering Scenarios**: S13
**Covering ACs**: AC16

**Description**: 由 Ba Ba 拍板 D4=β 新增。创建 `services/runtime/scheduler_config.yaml`（6 个 jobs 的 trigger 参数可配置化）+ `SchedulerConfig` dataclass + loader 函数。在 `DaemonScheduler.__init__()` 接受 `config_path: Optional[Path] = None` 参数，缺省时用内置默认值（WP01 的硬编码值）。

**Sub-tasks**:
- [ ] S8.1: 创建 `services/runtime/scheduler_config.yaml`，包含 6 个 jobs 的 trigger 参数 + 时区 + executor_workers
  ```yaml
  # scheduler_config.yaml
  scheduler:
    timezone: Asia/Shanghai
    executor_workers: 3
    misfire_grace_time_seconds: 60
  jobs:
    health_check:
      id: health_check
      trigger: interval
      seconds: 5
      max_instances: 1
      coalesce: true
      replace_existing: true
    dreamer.idle_check:
      id: dreamer.idle_check
      trigger: interval
      seconds: 60
      max_instances: 1
      coalesce: true
      replace_existing: true
    dreamer.scheduled:
      id: dreamer.scheduled
      trigger: cron
      hour: 3
      minute: 0
      max_instances: 1
      coalesce: true
    evolution.check:
      id: evolution.check
      trigger: interval
      seconds: 1800
    evolution.auto_apply:
      id: evolution.auto_apply
      trigger: interval
      seconds: 7200
    proactive.idle_tick:
      id: proactive.idle_tick
      trigger: interval
      seconds: 300
  ```
- [ ] S8.2: 创建 `services/runtime/scheduler_config.py`，定义 `SchedulerConfig` dataclass + `load_from_yaml(path: Path) -> SchedulerConfig` + `default_config()` 工厂函数
- [ ] S8.3: 修改 `services/runtime/scheduler.py` 的 `DaemonScheduler.__init__()`，增加 `config_path: Optional[Path] = None` 参数；`load_from_yaml()` 缺失则降级到 `default_config()`
- [ ] S8.4: 在 `services/runtime/daemon.py` 的 `JinliDaemon.start()` 中读 `scheduler_config.yaml`（如存在）；缺失则走默认
- [ ] S8.5: 在 `services/runtime/api_server.py` `/status` 端点增加 `scheduler.source` 字段（`yaml: <path>` 或 `hardcoded: defaults`）
- [ ] S8.6: 写测试 `services/runtime/tests/test_scheduler_config.py` 覆盖：yaml 加载 / 缺省值 / 文件不存在降级 / 字段验证（cron 必填 `hour+minute`，interval 必填 `seconds`）

**Out of scope**:
- 热重载（reload）— Ba Ba 改 yaml 后需重启 daemon（Phase 2 task）
- 跨 daemon 实例共享配置（NoOp）

**Dependencies**: WP01

**Verification**:
```powershell
# yaml 加载
python -c "from services.runtime.scheduler_config import load_from_yaml; c = load_from_yaml('services/runtime/scheduler_config.yaml'); print(c.jobs[0].id)"

# 缺省降级
python -c "from services.runtime.scheduler_config import default_config; c = default_config(); print(len(c.jobs))"
# 预期：6

# 字段验证（错误 yaml 抛 ValidationError）
python -c "from services.runtime.scheduler_config import load_from_yaml; load_from_yaml('/tmp/bad.yaml')" 2>&1 | grep ValidationError

# 测试覆盖
pytest services/runtime/tests/test_scheduler_config.py -v
```
预期：6 jobs 加载；缺省 6 jobs；坏 yaml 报错；测试 100% 通过。

---

## Final Verification

- [ ] F1: Verify mature path was implemented and no rejected shortcut was introduced（APScheduler BackgroundScheduler 完整使用，没用 schedule/Celery 替代）
- [ ] F2: Run automated verification (`pytest services/ -v --ignore=services/jinli_daemon.py`) and record output in `verification-report.md`
- [ ] F3: Map implementation result to Acceptance Criteria in `verification-report.md`（16 ACs 全部 pass — 含 WP08 的 AC16）
- [ ] F4: Verify scheduler_config.yaml 加载/缺省降级/字段验证 100% 测试覆盖（WP08）

---

## Work Package Timeline (estimate)

| WP | Estimate | Parallelizable With |
|----|----------|---------------------|
| WP01 Scheduler Core | 4-6 hours | — |
| WP02 6 Jobs Register | 3-4 hours | WP03, WP04, WP05, WP08 |
| WP03 3 Sink Adapters | 3-4 hours | WP02, WP04, WP05, WP08 |
| WP04 4 EventBus Subs | 2-3 hours | WP02, WP03, WP05, WP08 |
| WP05 Sync Wrapper | 4-6 hours | WP02, WP03, WP04, WP08 |
| WP06 Tests | 2-3 hours | (must wait WP02-WP05, WP08) |
| WP07 Docs + Endpoint | 2-3 hours | (must wait WP06) |
| WP08 Scheduler Config YAML (D4=β) | 2-3 hours | WP02, WP03, WP04, WP05 |
| **Total** | **22-32 hours** | |

**Note**: WP02 / WP03 / WP04 / WP05 可以并行（不同文件不同 sub-agent），但 Implement 阶段建议金璃好帮手按 WP01 → {WP02, WP03, WP04, WP05} → WP06 → WP07 顺序做，方便定位回归。

---

## Critical Constraints (DO NOT VIOLATE)

1. **不删 `services/jinli_daemon.py`** — 决策 D2-A：本次只动 `runtime/daemon.py`
2. **不引入新依赖** — 用 stdlib `asyncio.run_coroutine_threadsafe`
3. **不拆 `services/runtime/daemon.py`** — 改动局限于 `_run_loop` + `start()` + `stop()`
4. **Phase 1 标志清晰** — `services/runtime/scheduler_bridge.py` 含 `# PHASE_1_SYNC_WRAPPER` / `# PHASE_2_ASYNCIO_LOOP` 注释分段
5. **每个 WP 必带 pytest** — 不允许"等 WP06 再统一测试"
6. **不绕过 5 层门控** — `services/evolution/evolution_service.py` 的 gates.py 不能被跳过

---

## Key References (Footnotes)

- F1: `services/runtime/daemon.py:693` — `_run_loop` 定义
- F2: `services/runtime/service_registry.py:188` — `refresh_all` 方法
- F3: `services/memory/dreamer/triggers.py:493` — `DreamerService.run_cycle` sync
- F4: `services/evolution/evolution_service.py:155` — `EvolutionService.run_evolution_check`
- F5: `services/evolution/evolution_service.py:195` — `EvolutionService.auto_apply_low_risk`
- F6: `services/proactive/p1/triggers.py:229` — `IdleTrigger.get_idle_seconds` sync pure
- F7: `services/proactive/p1/triggers.py:270` — `IdleTrigger._on_tick` async（要拆）
- F8: `services/nervous/event_bus.py:211` — `EventBus.publish` async
- F9: `services/runtime/after_turn_commit.py:27-33` — 5 sink 字段定义
- F10: `services/runtime/after_turn_commit.py:62-79` — dropped 路径
- F11: `Project/Jinli/docs/04-Implementation/runtime-protocol.md:25-37` — adapters/ 列表
- F12: `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md` — MIRP + AfterTurnCommit 契约权威文档
- F13: `Project/Jinli/services/runtime/service_registry_builder.py` — build_default_registry 注册点