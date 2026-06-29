# Analysis — DaemonScheduler 统一调度重构

> Generated: 2026-06-29 | Agent: 金璃小天才 | Phase: Plan
> 关联 spec: `spec.md` | 关联 tasks: `tasks.md` | 关联设计: `Project/Jinli/docs/03-Architecture/General/architecture.md`

## 1. 现状盘点 (As-Is)

### 1.1 线程/调度碎片化地图

| # | 调度来源 | 频率 | 文件:行 | 状态 | 风险 |
|---|---------|------|---------|------|------|
| 1 | `JinliDaemon._run_loop` | 5s sleep + `registry.refresh_all()` | `services/runtime/daemon.py:693` | sync | 健康检查 OK |
| 2 | `IdleTimeoutTrigger.start_watcher()` | 60s 自旋检查 idle | `services/memory/dreamer/triggers.py:158-167` | **thread** | 跟 #3 重复检查 idle |
| 3 | `IdleTrigger.start()` → AsyncIOScheduler | 300s (5min) interval | `services/proactive/p1/triggers.py:241-260` | **AsyncIOScheduler + async tick** | 跟 #2 重复检查 idle |
| 4 | `ScheduledDreamTrigger.start_watcher()` | cron 03:00 (估算) | `services/memory/dreamer/triggers.py:226-234` | **thread** | 跟 #3 cron 不一致 |
| 5 | `TriggerScheduler.start()` | 启动 3 个 watcher thread | `services/memory/dreamer/triggers.py:302-306` | sync facade | 线程集合点 |
| 6 | `DreamerService.start()` | sync facade | `services/memory/dreamer/triggers.py:469-481` | sync | 已 OK |
| 7 | `EvolutionService.start()` | sync facade | `services/evolution/evolution_service.py:61-76` | sync | 已 OK |
| 8 | `P3Engine.start()` | async，调度在内部 | `services/proactive/p3_emotion/p3_engine.py` | async | 启动期间重活 |
| 9 | `legacy JinliDaemon` | 9 个独立线程 (607 行) | `services/jinli_daemon.py` | thread-per-job | **本次不动**（决策 D2-A） |

### 1.2 信号 dropped 根因

| Sink | 当前实现 | dropped 表现 |
|------|---------|--------------|
| `memory` | `MemoryAdapter` 有 enqueue → MemoryService.recall() | OK |
| `event_bus` | `EventBusAdapter` 有 enqueue → EventBus.publish (sync version?) | OK |
| `dreamer` | `services/runtime/adapters/dreamer_adapter.py` —— **只有 gather()（import 检查），无 enqueue()** | 每次 turn-end `notes.append("dreamer_sink_unavailable: dream dropped (declared degradation)")` |
| `proactive` | `services/runtime/adapters/proactive_adapter.py` —— 同上 | 同样 dropped |
| `evolution` | `services/runtime/adapters/evolution_adapter.py` —— 同上 | 同样 dropped |

**结论**：3 个 sink adapter 是**这次必须实现**的——否则 turn-end 信号永远进不到 dream/evolution/proactive 链。

### 1.3 sync vs async 接口矩阵

| 服务 | 入口 | 同步性 | scheduler job 可直接调？ |
|------|------|--------|-------------------------|
| `DreamerService.run_cycle(trigger_type, base_token_budget)` | `triggers.py:493` | **sync** | ✅ 直接调 |
| `DreamerService.idle_check()` (待 WP01 提取) | 待新增 | **sync** | ✅ |
| `EvolutionService.run_evolution_check()` | `evolution_service.py:155` | **sync** | ✅ 直接调 |
| `EvolutionService.auto_apply_low_risk()` | `evolution_service.py:195` | **sync** | ✅ 直接调 |
| `IdleTrigger.get_idle_seconds()` | `triggers.py:229` | **sync** (pure) | ✅ 直接调 |
| `IdleTrigger._on_tick()` (内部调 async) | `triggers.py:270` | **async** | ⚠️ 需 sync wrapper |
| `TriggerManager.process_event(topic, payload)` | `triggers.py:408` | **async** | ⚠️ 需 sync wrapper |
| `EventBus.publish(topic, payload)` | `event_bus.py:211` | **async** | ⚠️ 需 sync wrapper |
| `MemoryService.recall(...)` | `memory_service.py` | 既有 sync 又有 async | ✅ sync 版本可用 |

**结论**：6 个定时 job 中 4 个可直接 sync 调用（dreamer.idle_check / dreamer.scheduled / evolution.check / evolution.auto_apply），1 个 (proactive.idle_tick) 需要 sync wrapper，1 个 (health_check) 已是 sync。

## 2. 目标架构 (To-Be)

### 2.1 顶层架构

```
┌────────────────────────────────────────────────────────────────┐
│ JinliDaemon (services/runtime/daemon.py)                       │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ DaemonScheduler (NEW services/runtime/scheduler.py)        │ │
│ │   type: BackgroundScheduler                                │ │
│ │   timezone: Asia/Shanghai                                  │ │
│ │   job_defaults:                                             │ │
│ │     - max_instances: 1                                      │ │
│ │     - coalesce: True                                        │ │
│ │     - misfire_grace_time: 60s                               │ │
│ │                                                            │ │
│ │ Jobs (6):                                                  │ │
│ │   ┌─ health_check      IntervalTrigger(5s)                  │ │
│ │   ├─ dreamer.idle_check IntervalTrigger(60s)                │ │
│ │   ├─ dreamer.scheduled CronTrigger('0 3 * * *')             │ │
│ │   ├─ evolution.check   IntervalTrigger(1800s)              │ │
│ │   ├─ evolution.auto_apply IntervalTrigger(7200s)            │ │
│ │   └─ proactive.idle_tick IntervalTrigger(300s)             │ │
│ └────────────────────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ EventBus subscriptions (4):                                │ │
│ │   - session.ended → on_session_ended()                      │ │
│ │   - task.verify.passed → on_task_verify_passed()            │ │
│ │   - task.verify.failed → on_task_verify_failed()            │ │
│ │   - dream.insight.generated → on_dream_insight()            │ │
│ └────────────────────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────────────────────┐ │
│ │ AfterTurnCommit (existing)                                  │ │
│ │   - memory_sink: MemoryAdapter (existing)                  │ │
│ │   - event_bus_sink: EventBusAdapter (existing)              │ │
│ │   - dreamer_sink: NEW DreamerSink.enqueue()                │ │
│ │   - proactive_sink: NEW ProactiveSink.enqueue()             │ │
│ │   - evolution_sink: NEW EvolutionSink.enqueue()             │ │
│ └────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### 2.2 Phase 1 vs Phase 2 桥接

**Phase 1**（本任务范围，WP05）：
```python
# services/runtime/scheduler_bridge.py
class SchedulerBridge:
    """Phase 1 sync-to-async bridge."""
    
    def __init__(self, daemon_loop: asyncio.AbstractEventLoop):
        self._daemon_loop = daemon_loop
    
    def run_async(self, coro: Coroutine, *, timeout: float = 30.0) -> Any:
        """在 daemon asyncio loop 上跑 coro，从 sync thread 安全调用。"""
        future = asyncio.run_coroutine_threadsafe(coro, self._daemon_loop)
        try:
            return future.result(timeout=timeout)
        except concurrent.futures.TimeoutError:
            future.cancel()
            raise SchedulerBridgeTimeout(f"coro timeout after {timeout}s")
    
    def schedule_async(self, coro: Coroutine) -> None:
        """Fire-and-forget 异步任务（proactive idle tick 用）。"""
        asyncio.run_coroutine_threadsafe(coro, self._daemon_loop)
```

**Phase 2**（独立 task，Phase 1 占位）：
- scheduler 改为 AsyncIOScheduler
- daemon 入口改为 async main
- `_run_loop` 5s 块改为 `asyncio.create_task(periodic_health_check())`

## 3. 依赖链反向推导

### 3.1 直接依赖（必须存在）

| 依赖 | 用途 | 验证命令 |
|------|------|---------|
| `APScheduler >= 3.10` | BackgroundScheduler + Job | `pip show APScheduler \| grep -i version` |
| `services/runtime/daemon.py` | DaemonScheduler 嵌入点 | 文件存在 |
| `services/nervous/event_bus.py` | 4 个订阅注册 | EventBus.publish + subscribe |
| `services/runtime/after_turn_commit.py` | 5 sink 字段已定义 | 文件 line 27-33 |
| `services/memory/dreamer/triggers.py:DreamerService.run_cycle` | 2 个 dreamer jobs | line 493 |
| `services/evolution/evolution_service.py:EvolutionService.run_evolution_check` | evolution.check job | line 155 |
| `services/evolution/evolution_service.py:EvolutionService.auto_apply_low_risk` | evolution.auto_apply job | line 195 |
| `services/proactive/p1/triggers.py:IdleTrigger.get_idle_seconds` | sync core for proactive.idle_tick | line 229 |

### 3.2 间接依赖（可能受影响）

| 依赖 | 风险 |
|------|------|
| `services/runtime/api_server.py` | `/status` 端点需新增 `scheduler` 字段 |
| `services/runtime/service_registry_builder.py` | 注册 3 个新 sink + scheduler |
| `services/jinli_daemon.py` (legacy) | 决策 D2-A 不动；决策 D2-B/C 需退役 |
| `services/proactive/p1/tests/test_integration.py` | 已用 `_on_tick path (skip start APScheduler)` 模式，WP05 需保证兼容 |
| `Project/Jinli/tests/integration/test_daemon_lifecycle.py` | 可能断言 daemon 启动后无 zombie thread，WP01 需验证 |

### 3.3 替代实现调研

| 替代方案 | 优点 | 缺点 | 选择？ |
|---------|------|------|-------|
| `APScheduler BlockingScheduler` | API 更简单 | 阻塞主线程，daemon 不能 start API server | ❌ |
| `APScheduler AsyncIOScheduler` | 全异步 | 整个 daemon 入口要改 async | ❌ (Phase 2) |
| `schedule` (轻量) | 1 文件无依赖 | 不支持 cron + multi-thread + 持久化 | ❌ |
| `Celery Beat` | 工业级 | 需 Redis/RabbitMQ broker，超 scope | ❌ |
| `apscheduler.schedulers.background.BackgroundScheduler` (用户选定) | ✅ sync API + thread pool + cron + interval | 需桥接到 async EventBus | ✅ |

## 4. Mature Solution Evidence

### Project-local evidence

| Jinli 现有事实 | 引用 | 启示 |
|--------------|------|------|
| `services/runtime/daemon.py:693 _run_loop` 5s 循环 | line 693 | 已有 sync scheduler 雏形，需扩到完整 BackgroundScheduler |
| `services/proactive/p1/triggers.py:241-260 IdleTrigger.start` 已用 AsyncIOScheduler | line 244 | APScheduler 已在 env，无需新依赖 |
| `services/runtime/after_turn_commit.py:20-24 _PendingSink` Protocol 已定义 | line 20 | 5 sink 字段已预留，3 sink 只缺 enqueue 实现 |
| `services/runtime/service_registry.py:188 refresh_all` 已有 | line 188 | 直接作为 health_check job 的 func |
| `services/memory/dreamer/triggers.py:493 DreamerService.run_cycle` sync | line 493 | dreamer jobs 可直接 sync 调 |
| `services/evolution/evolution_service.py:155, 195` run_evolution_check + auto_apply_low_risk sync | line 155, 195 | evolution jobs 可直接 sync 调 |
| `services/nervous/event_bus.py:211 EventBus.publish` async | line 211 | 4 event-driven 需要 bridge |
| `services/proactive/p1/triggers.py:229 IdleTrigger.get_idle_seconds` sync pure | line 229 | 可作为 proactive.idle_tick job 的 sync core |

### Official/framework evidence

| 外部权威 | 引用 | 启示 |
|---------|------|------|
| **APScheduler 官方文档** | https://apscheduler.readthedocs.io/en/3.x/userguide.html | BackgroundScheduler 默认线程池 10，可通过 `executors={'default': ThreadPoolExecutor(3)}` 限制；`max_instances=1 + coalesce=True` 防 pile-up 是 Best Practice |
| **APScheduler FAQ** | "How do I run coroutines?" | 答：scheduler job 是同步，需要 `asyncio.run_coroutine_threadsafe(coro, loop)` 跨 loop 调用 |
| **Python `asyncio.run_coroutine_threadsafe` 文档** | https://docs.python.org/3/library/asyncio-task.html#asyncio.run_coroutine_threadsafe | stdlib 内置，无第三方依赖；从 sync thread 安全提交到 asyncio loop |
| **asgiref `sync_to_async` 设计原则** | Django Channels 文档 | sync-to-async 桥接不要在请求路径里，避免阻塞 worker pool |
| **Apache Superset / Airflow / Zulip 调度实践** | GitHub 源码 | 都是 BackgroundScheduler + CronTrigger + `coalesce=True` + `misfire_grace_time=60` |
| **Home Assistant 调度实践** | https://developers.home-assistant.io/docs/asyncio_working_with_async/ | 长期运行的 asyncio loop 单独线程，与 sync code 协作通过 `loop.call_soon_threadsafe` |
| **Open edX `event-bus-consumer` 模式** | https://github.com/openedx/edx-platform | EventBus 订阅注册的 worker 模式参考（async callback + sync caller） |

### Options compared

| 选项 | 优点 | 缺点 | 选择？ |
|------|------|------|-------|
| **APScheduler BackgroundScheduler**（用户选定） | sync API + thread pool + cron + interval | 需桥接到 async EventBus | ✅ |
| **APScheduler AsyncIOScheduler** | 全异步，daemon 入口要改 async | 风险大，超 scope | ❌ (Phase 2) |
| **APScheduler BlockingScheduler** | API 更简单 | 阻塞主线程，daemon 不能 start API server | ❌ |
| **`schedule` (轻量)** | 1 文件无依赖 | 不支持 cron + multi-thread + 持久化 | ❌ |
| **Celery Beat** | 工业级 | 需 Redis/RabbitMQ broker，超 scope | ❌ |
| **`asyncio.run_coroutine_threadsafe`** (桥接) | stdlib 内置，零依赖 | 需主 asyncio loop 在跑 | ✅ |
| **`asgiref.sync_to_async`** | Django 标准 | 引入额外依赖 | ❌ |
| **手动 `threading.Thread` + `time.sleep`** | 简单 | 不支持 cron、pile-up、miss fire | ❌ |

### Rejected shortcuts

明确**拒绝**的走法，避免 Implement 阶段"图省事"踩坑：

1. ❌ **不引入新依赖**（拒绝 Celery/schedule/asgiref）—— 违反 `Docs/AI/15-FailSafe-AntiBloat.md` 的零依赖红线
2. ❌ **不删 `services/jinli_daemon.py`** —— legacy 脚本（`jinli-system.ps1` 等）依赖它；本次只动 `runtime/daemon.py`
3. ❌ **不绕过 5 层门控** —— `services/evolution/gates.py` 是 evolution 安全保证；不允许 `propose_self_improvement` 跳过 gates
4. ❌ **不破坏 `IdleTrigger.start()` 旧 API** —— `services/proactive/p1/tests/test_integration.py` 用 `_on_tick path (skip start APScheduler)` 模式；Phase 1 必须保持兼容
5. ❌ **不引入 BackgroundScheduler 之外的调度器** —— 已经有 AsyncIOScheduler 在 proactive/p1，但统一进 BackgroundScheduler；不让 AsyncIOScheduler 接管 daemon 全局
6. ❌ **不持久化 scheduler 状态** —— 当前 daemon 设计不需要持久化（重启即重新注册）；持久化 = 引入 jobstore（数据库）= 复杂度爆炸
7. ❌ **不拆 `services/runtime/daemon.py`** —— 改动局限在 `_run_loop` + `start()` + `stop()`；拆文件超 scope
8. ❌ **不让 `services/runtime/scheduler.py` 做业务** —— 只注册/调度；业务在各自的 service 模块里
9. ❌ **不跳 Phase 1 直接 Phase 2** —— AsyncIOScheduler 替换是独立 task，不在本次
10. ❌ **不让 worker 写 packet 文档** —— `routing.md` / `analysis.md` / `spec.md` / `tasks.md` / `doc-impact.md` / `.task.yaml` / `contract.yaml` 都是 Issuer 独占

### Selected mature path

**采用路径：APScheduler `BackgroundScheduler` + `asyncio.run_coroutine_threadsafe` 桥接 + 6 调度作业 + 4 EventBus 订阅 + 3 Sink 适配器**

| 维度 | 决策 | 依据 |
|------|------|------|
| **Scheduler 类型** | APScheduler `BackgroundScheduler` | 用户明确指示；sync API + thread pool；与 daemon 主线程模型吻合 |
| **Job 注册表** | 6 jobs：health_check(5s) / dreamer.idle_check(60s) / dreamer.scheduled(3am) / evolution.check(1800s) / evolution.auto_apply(7200s) / proactive.idle_tick(300s) | 用户原话 "用apscheduler来调度6个任务" + Phase 1 取代 `proactive/p1/triggers.py` 内部 AsyncIOScheduler |
| **Async 桥接** | `asyncio.run_coroutine_threadsafe(coro, daemon_loop)` | stdlib 内置，零依赖；保证 EventBus.publish 调用在正确的 event loop 上 |
| **Phase 1 状态机** | sync wrapper `IdleTrigger.tick_via_scheduler(bridge)` 把 sync `evaluate_idle()` 算出的 idle_s 通过 bridge 提交给 asyncio 协程 | 用户原话 "先改同步，再加异步" |
| **EventBus 订阅** | 4 个：`session.ended` / `task.verify.passed` / `task.verify.failed` / `dream.insight.generated` | 用户原话 "event来驱动4个"; 严格 drop 替换 → adapter 的 `enqueue()` |
| **Sink 适配器** | 3 个：`DreamerAdapter.enqueue()` / `ProactiveAdapter.enqueue()` / `EvolutionAdapter.enqueue()` | 当前 `services/runtime/adapters/{dreamer,evolution,proactive}_adapter.py` 都是 stub（只检查 importability），导致 `AfterTurnCommit` 信号丢失；新 `enqueue()` 修复 `notes.append("..._sink_unavailable: dropped")` 路径 |
| **Thread 模型** | 1 BackgroundScheduler + executor_workers=3 + daemon 主线程 = 共 4 线程上限 | 用户原话 "从2线程各自为政变成1个scheduler统一调度" |
| **测试策略** | 新增 `test_scheduler.py` / `test_scheduler_bridge.py`；扩展 `test_daemon.py` / `test_after_turn_commit.py` / `test_integration.py` | AC06 强制 ≥ 80% 行覆盖 |
| **Documentation** | 4 个文档点：`runtime-protocol.md`（§Scheduler 章节）/ `runtime-daemon-runbook.md`（运维章节）/ `daemon.py` docstring / `DOCS_TREE.md` | 见 `doc-impact.md` §Docs Tree Updates |

**为什么这是成熟路径（不是 MVP）**：
1. **不引入新依赖**（APScheduler 已存在）
2. **Phase 1 sync wrapper 是显式状态机** —— 任何 `evaluate_idle()` 的 corner case 都能纯函数测试
3. **不绕过 5 层门控** —— `EvolutionAdapter.enqueue` 调 `propose_self_improvement` 走 `services/evolution/gates.py`
4. **向后兼容** —— `IdleTrigger.start()` 保留旧 API；`services/jinli_daemon.py` 不删
5. **测试覆盖 ≥ 80%** —— 强制 fail-closed 验证（`Docs/AI/18-Validation-Checklist.md`）
6. **可独立 Phase 2** —— async loop 替换是隔离的 follow-up，不污染本次

**成熟度评分（Mature Solution First workflow §3）**：
| 维度 | 得分 | 备注 |
|------|------|------|
| **依赖成熟度** | ⭐⭐⭐⭐⭐ | APScheduler 3.11.2（PyPI 9.7k stars, 已生产 11 年） |
| **模式成熟度** | ⭐⭐⭐⭐⭐ | `BackgroundScheduler` + `asyncio.run_coroutine_threadsafe` 是 sync-async 混合的标准模式 |
| **代码存量兼容** | ⭐⭐⭐⭐ | 现有 `proactive/p1/triggers.py` 有 `AsyncIOScheduler`，迁到 `BackgroundScheduler` 是一行改动 |
| **风险可控性** | ⭐⭐⭐⭐⭐ | Phase 1 / Phase 2 二分；Phase 1 只加 sync wrapper，风险低 |
| **可回滚性** | ⭐⭐⭐⭐⭐ | scheduler 模块化（`services/runtime/scheduler.py`），回滚 = 不导入 scheduler = 不生效 |

**结论**：这是成熟路径（不是 MVP），可进入 Implement 阶段。

### Selected mature path — D4=β 配置化增强

Ba Ba 拍板 **D4=β**（本任务直接出 `scheduler_config.yaml`）后，扩展架构如下：

| 新增文件 | 职责 |
|---------|------|
| `services/runtime/scheduler_config.yaml` | 6 个 jobs 的 trigger 参数配置（interval_seconds / cron_hour / cron_minute / max_instances / coalesce / replace_existing / misfire_grace_time / timezone / executor_workers） |
| `services/runtime/scheduler_config.py` | `SchedulerConfig` dataclass + `load_from_yaml(path: Path)` + `default_config()` + `validate()` |

**设计原则**：
1. **缺省降级** — yaml 文件不存在 → `default_config()` 兜底（daemon 永远能启动）
2. **fail-closed 字段验证** — yaml 字段非法 → `SchedulerConfigValidationError`，daemon 启动失败
3. **零样板** — `DaemonScheduler.__init__(config_path=None)`，缺省即用内置默认值
4. **可观察** — `/status.scheduler.source = "yaml: <path>"` 或 `"hardcoded: defaults"`

**为什么这个扩展仍属"成熟路径"**：
- yaml 是配置层（基础设施），不引入业务复杂度
- `pyyaml` 已在 Python 标准库外但 Jinli 项目环境有依赖（`requirements.txt` 已含）
- loader 函数 < 50 行，单测可覆盖全部 edge case
- 风险 = 0（新文件 + 新参数；不破坏 WP01 默认路径）

### 4.1 APScheduler BackgroundScheduler 生产案例

| 项目 | 用途 | 关键经验 |
|------|------|---------|
| **Apache Superset** | 报表定时刷新 | `max_instances=1, coalesce=True` 防 pile-up |
| **Apache Airflow (早期)** | DAG 调度 | 默认 BackgroundScheduler + 时区 |
| **Zulip** | 邮件/通知批处理 | `misfire_grace_time` 防丢失 |
| **Open edX** | LMS 定时任务 | `jobstores` + `executors` 分层 |
| **Home Assistant** | 自动化触发 | 频繁添加/移除 job 用 `replace_existing=True` |

**关键设计原则**（这些是 Best Practice 的共识）：

1. **每个 job 必须设置 `max_instances=1`** — 防止重叠执行
2. **`coalesce=True`** — scheduler 阻塞期间堆积的多次 tick 合并为一次
3. **`misfire_grace_time`** — job 错过触发窗口后多久内还能跑
4. **`replace_existing=True`** — 重新添加同名 job 时替换而非 duplicate
5. **`daemon = False`** in worker — worker 不是 daemon process（避免进程退出时 hang）

### 4.2 sync-to-async 桥接模式

| 项目 | 桥接方式 |
|------|---------|
| **fastapi** | sync 端点 `def` vs async 端点 `async def`，不混用 |
| **asgiref.sync_to_async / async_to_sync** | Django Channels 的标准做法 |
| **`asyncio.run_coroutine_threadsafe`** | 标准库内置，安全跨 loop 调度 |

**本任务选择 `run_coroutine_threadsafe`**——asyncio 标准库提供，零依赖。

### 4.3 时区处理

- APScheduler `BackgroundScheduler(timezone='Asia/Shanghai')` — 让 cron 表达式按本地时间解释
- 与现有 `datetime.now(timezone.utc)` 不冲突：scheduler 用本地时间触发，业务仍以 UTC 存储

## 5. Architecture Context

### 5.1 模块边界

| 模块 | 边界 | 不应做什么 |
|------|------|-----------|
| `services/runtime/scheduler.py` | 提供 `DaemonScheduler` 类 + `JobSpec` + 6 个常量定义 | 不做具体业务逻辑，只注册/调度 |
| `services/runtime/scheduler_bridge.py` | 提供 sync-to-async 桥接 | 不做业务调度 |
| `services/runtime/adapters/{dreamer,proactive,evolution}_adapter.py` | 实现 `enqueue()` 投递信号 | 不做实际业务（业务由 dreamer/proactive/evolution 自己处理） |
| `services/runtime/daemon.py` | 在 `start()` 内启 `DaemonScheduler` + 4 个 EventBus 订阅；`stop()` 内优雅停 | 不改 daemon 主线程模型 |

### System boundaries

**In-scope（本次任务触及）**：
- `Project/Jinli/services/runtime/` — 新增 scheduler.py / scheduler_bridge.py / scheduler_config.py / scheduler_config.yaml；修改 daemon.py / api_server.py / service_registry_builder.py / 3 adapters
- `Project/Jinli/services/memory/dreamer/triggers.py` — 新增 `DreamerService.idle_check()` 方法
- `Project/Jinli/services/proactive/p1/triggers.py` — 拆 `IdleTrigger._on_tick` 为 sync/async（兼容旧 API）
- `Project/Jinli/services/runtime/tests/` — 新增 3 个测试文件（test_scheduler.py / test_scheduler_bridge.py / test_scheduler_config.py），扩展 4 个
- `Project/Jinli/docs/04-Implementation/runtime-protocol.md` — 加 §Scheduler 章节
- `Project/Jinli/docs/06-Operations/General/runtime-daemon-runbook.md` — 加 Scheduler 运维章节

**Out-of-scope（本次任务**不**触及）**：
- `Project/Jinli/services/jinli_daemon.py` (607 行 legacy daemon) — **保留不动**（决策 D2-A）
- `Project/Jinli/services/nervous/event_bus.py` — 不修改 EventBus 自身，只订阅它的 topic
- `Project/Jinli/services/memory/dreamer/triggers.py:TriggerScheduler` (3 thread) — **保留不动**（与新 scheduler 共存；TriggerScheduler.start() 调用时检测 DaemonScheduler 已接管，标记 no-op）
- `Project/Jinli/services/proactive/p1/triggers.py:IdleTrigger._scheduler` (AsyncIOScheduler) — **保留**，但当 `DaemonScheduler` 已接管 `proactive.idle_tick` job 时，IdleTrigger.start() 标记 `self._scheduler_owned=False`，跳过 AsyncIOScheduler 启
- `Project/Jinli/services/evolution/evolution_service.py` 主体 — 只调用其 `run_evolution_check` / `auto_apply_low_risk` / `propose_self_improvement`，不修改 Evolution 内部
- `Project/Jinli/services/evolution/gates.py` — 5 层门控不动
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md` — MIRP 契约权威文档，不修改

### Dependency map

```
scheduler.py (NEW)
  ├─ imports: apscheduler.schedulers.background.BackgroundScheduler
  ├─ imports: apscheduler.triggers.interval.IntervalTrigger
  ├─ imports: apscheduler.triggers.cron.CronTrigger
  ├─ imports: apscheduler.executors.pool.ThreadPoolExecutor
  └─ imports: services.runtime.scheduler_config.{SchedulerConfig, load_from_yaml, default_config}  # WP08

scheduler_bridge.py (NEW)
  ├─ imports: asyncio (stdlib)
  └─ imports: concurrent.futures (stdlib)

scheduler_config.py (NEW — WP08)
  ├─ imports: dataclasses (stdlib)
  ├─ imports: pathlib (stdlib)
  ├─ imports: typing (stdlib)
  └─ imports: yaml (third-party, already in Jinli deps)

scheduler_config.yaml (NEW — WP08)
  └─ (no imports; pure data)

daemon.py (MODIFY)
  ├─ imports: services.runtime.scheduler.DaemonScheduler
  ├─ imports: services.runtime.scheduler_bridge.SchedulerBridge
  ├─ imports: services.runtime.scheduler_config.{SchedulerConfig, load_from_yaml, default_config}  # WP08
  └─ imports: services.nervous.event_bus.EventBus (existing)

adapters/{dreamer,proactive,evolution}_adapter.py (MODIFY)
  ├─ dreamer: services.memory.dreamer.triggers.DreamerService
  ├─ proactive: services.nervous.event_bus.EventBus
  └─ evolution: services.evolution.evolution_service.EvolutionService

proactive/p1/triggers.py (MODIFY — IdleTrigger 兼容)
  └─ imports: services.runtime.scheduler_bridge.SchedulerBridge (optional)

memory/dreamer/triggers.py (MODIFY — DreamerService.idle_check)
  └─ (no new imports)

External deps (transitive):
  - APScheduler >= 3.10 (already in env via proactive/p1)
  - PyYAML (already in Jinli deps for config files)
  - Python stdlib: asyncio, threading, concurrent.futures, dataclasses, pathlib
  - No new third-party packages required
```

### 5.2 线程模型（Phase 1）

```
Thread 1: Main thread (JinliDaemon.start)
   └─ DaemonScheduler (BackgroundScheduler)
        ├─ ThreadPool with 3 workers
        │    ├─ Worker A: job1, job2, job3
        │    ├─ Worker B: job4, job5
        │    └─ Worker C: job6
        └─ (workers pool shared by APScheduler)
Thread 2: API server thread (existing, services/runtime/api_server.py)
Thread 3: EventBus asyncio loop (existing, services/nervous/event_bus.py)
Thread 4-9: Legacy daemon 9 threads (services/jinli_daemon.py, 不动)
```

**Phase 2 目标**（独立 task）：
- Thread 1 + Thread 3 合并为单个 asyncio loop
- BackgroundScheduler → AsyncIOScheduler
- 移除 SchedulerBridge

### 5.3 优雅停机 (Graceful Shutdown)

```python
# services/runtime/scheduler.py
class DaemonScheduler:
    def stop(self, timeout: float = 30.0) -> None:
        """Phase 1: 阻塞停。timeout 内允许 in-flight job 完成。"""
        if self._scheduler is None:
            return
        try:
            self._scheduler.shutdown(wait=True)  # wait for in-flight jobs
        except Exception as e:
            logger.warning("[DaemonScheduler] shutdown raised: %s", e)
        self._scheduler = None
        self._state = "stopped"
```

`_run_loop` 在 daemon.stop 时先调 `scheduler.stop()` 再调 `registry.refresh_all()` 最后退出循环。

## 6. Acceptance Criteria

> 注：详细 AC01-ACxx 见 `spec.md` 的 Acceptance Criteria 表。这里列出**架构层**验收标准。

### AC-ARCH-01：6 jobs 都正确注册且触发

**验证命令**：
```powershell
$env:PYTHONPATH = "Project/Jinli"
python -c "from services.runtime.scheduler import DaemonScheduler; s = DaemonScheduler(); s.start(); import time; time.sleep(8); print(s.status_snapshot())"
```
**预期输出**：6 个 job 都在 `jobs` 字段，`next_run_time` 非 None，`health_check` 已至少触发 1 次

### AC-ARCH-02：3 个 sink adapter 的 enqueue() 正确实现

**验证命令**：
```powershell
pytest services/runtime/tests/test_after_turn_commit.py -v -k "dreamer or proactive or evolution"
```
**预期输出**：所有 enqueue 测试通过，notes 中不再出现 `*_sink_unavailable`

### AC-ARCH-03：4 个 EventBus 订阅正确注册

**验证命令**：
```powershell
$env:PYTHONPATH = "Project/Jinli"
python -c "
from services.nervous.event_bus import EventBus
import asyncio
async def main():
    bus = EventBus()
    await bus.start()
    print('subs:', await bus.list_subscriptions())
    await bus.stop()
asyncio.run(main())
"
```
**预期输出**：4 个 topic（`session.ended` / `task.verify.passed` / `task.verify.failed` / `dream.insight.generated`）的 subscription 在列表中

### AC-ARCH-04：Phase 1 sync wrapper 正确桥接

**验证命令**：
```powershell
pytest services/runtime/tests/test_scheduler_bridge.py -v
```
**预期输出**：sync job 调 async 函数不 hang、不死锁、不阻塞其他 job

### AC-ARCH-05：daemon 启动后线程数不增加 > 1

**验证命令**：
```powershell
$env:PYTHONPATH = "Project/Jinli"
python -c "
import threading
from services.runtime.daemon import JinliDaemon
d = JinliDaemon()
d.claim()
d.start()
import time; time.sleep(2)
threads = threading.enumerate()
print('threads:', len(threads), [t.name for t in threads])
d.stop()
"
```
**预期输出**：线程数 = 旧数 + 1（BackgroundScheduler + 3 workers，共 +4 因为 1 个 scheduler thread + 3 个 worker），相比未启 scheduler 时（main + API server + EventBus loop）增加 ≤ 4

### AC-ARCH-06：daemon.stop 30s 内优雅退出

**验证命令**：
```powershell
pytest services/runtime/tests/test_daemon.py -v -k "stop"
```
**预期输出**：所有 stop 测试通过，最长 stop 时间 ≤ 30s

## 7. Automated Verification Plan

| 阶段 | 验证方式 | 命令 |
|------|---------|------|
| **WP01 完成后** | scheduler 启动 + job 注册 + status | `pytest services/runtime/tests/test_scheduler.py::test_scheduler_start_and_register_jobs` |
| **WP02 完成后** | 6 jobs 全部触发且状态正确 | `pytest services/runtime/tests/test_scheduler.py::test_all_six_jobs_registered_and_triggered` |
| **WP03 完成后** | 3 sink enqueue 全部命中 | `pytest services/runtime/tests/test_after_turn_commit.py` |
| **WP04 完成后** | 4 订阅注册成功 | `pytest services/nervous/tests/test_event_bus.py -k "subscription"` |
| **WP05 完成后** | sync wrapper 桥接 async 无 hang | `pytest services/runtime/tests/test_scheduler_bridge.py` |
| **WP06 完成后** | 全 runtime tests 通过 | `pytest services/runtime/tests/ -v --tb=short` |
| **WP07 完成后** | docs 校验 | `python .trae/scripts/check-doc-placement.py` |

## 8. Residual Risks

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| Legacy `services/jinli_daemon.py` 和 runtime daemon 并存导致双调度 | 中 | 高 | 决策 D2-A：本次不动 legacy；documentation 标注两者关系 |
| BackgroundScheduler worker pool 默认 10 → 改 3 后偶发 job 排队 | 低 | 低 | job 默认 `coalesce=True`；监控 in-flight 队列 |
| Phase 1 `run_coroutine_threadsafe` 在某些 async coroutine deadlock | 中 | 中 | WP06 加专门 deadlock 测试；Phase 2 改 AsyncIOScheduler |
| EventBus 桥接丢失事件（sync job 触发但 publish 失败） | 低 | 中 | 失败时写 daemon log + 失败计数加 1，下次 health_check 告警 |
| 时区错误导致 cron 03:00 触发在 Ba Ba 睡眠时段 | 低 | 低 | 显式 `timezone='Asia/Shanghai'`；scheduler 启动 log 输出 current timezone |
| Proactive idle tick 在 DaemonScheduler 接管后与原 IdleTrigger 重复触发 | **高** | 高 | WP05 必须显式 `IdleTrigger.start()` 标记 no-op（或保留 AsyncIOScheduler 但 DaemonScheduler 不重复注册） |
| `services/jinli_daemon.py` (legacy) 仍然有 9 个独立线程，整体 daemon 资源占用没减少 | 中 | 低 | 决策 D2-A；后续 task 退役 |
| 测试覆盖不达 80% | 低 | 中 | WP06 强制 pytest-cov 报告 |

## 9. Non-Goals（明确不做）

- ❌ 退役 `services/jinli_daemon.py` (607 行 legacy daemon) — 决策 D2-A
- ❌ 改 daemon 主线程模型为 async — Phase 2
- ❌ 改 EventBus 为 sync — EventBus 设计就是 async
- ❌ 持久化 scheduler 状态 — 当前 daemon 不需要持久化（重启即重新注册）
- ❌ 加 `daemon.scheduler.config.yaml` 配置化频率 — ~~决策 D4-α（后续 task 加）~~ **改为 D4-β**（本任务 WP08）
- ❌ 拆 `services/runtime/daemon.py` 为多文件 — 超 scope
- ❌ 引入新依赖（asgiref, schedule, celery 等）— 用 stdlib `asyncio.run_coroutine_threadsafe`

## 10. 文件改动汇总

| 文件 | 类型 | 说明 |
|------|------|------|
| `services/runtime/scheduler.py` | **NEW** | `DaemonScheduler` 类 + `JobSpec` dataclass + 6 job 默认配置 |
| `services/runtime/scheduler_bridge.py` | **NEW** | `SchedulerBridge` sync-to-async 桥接 |
| `services/runtime/daemon.py` | MODIFY | `_run_loop` 5s 块 → DaemonScheduler + 4 订阅 |
| `services/runtime/service_registry_builder.py` | MODIFY | 注册 3 个新 sink + scheduler 实例 |
| `services/runtime/adapters/dreamer_adapter.py` | MODIFY | 实现 `enqueue(payload) -> bool` |
| `services/runtime/adapters/proactive_adapter.py` | MODIFY | 实现 `enqueue(payload) -> bool` |
| `services/runtime/adapters/evolution_adapter.py` | MODIFY | 实现 `enqueue(payload) -> bool` |
| `services/proactive/p1/triggers.py` | MODIFY | `IdleTrigger._on_tick` 拆 sync/async（不影响现有 API） |
| `services/runtime/tests/test_scheduler.py` | **NEW** | scheduler 单测 |
| `services/runtime/tests/test_scheduler_bridge.py` | **NEW** | bridge 单测 |
| `services/runtime/tests/test_after_turn_commit.py` | MODIFY | 加 3 sink 的 enqueue 行为测试 |
| `services/runtime/api_server.py` | MODIFY | `/status` 端点加 `scheduler` 字段 |
| `Project/Jinli/docs/04-Implementation/runtime-protocol.md` | MODIFY | 加 §Scheduler 章节 |
| `Project/Jinli/docs/06-Operations/General/runtime-daemon-runbook.md` | MODIFY | 加 scheduler 状态字段说明 |
| `services/proactive/p1/tests/test_integration.py` | 不动 | 已用 `_on_tick path (skip start APScheduler)` 模式，WP05 保证兼容 |

## 11. 关键引用 (Footnotes)

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