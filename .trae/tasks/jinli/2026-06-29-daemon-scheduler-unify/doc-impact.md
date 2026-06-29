# Doc Impact — DaemonScheduler 统一调度重构

> Generated: 2026-06-29 | Agent: 金璃小天才 | Phase: Plan
> 任务名: `jinli/2026-06-29-daemon-scheduler-unify`

## Project Document Scope

- Project: jinli
- System: Project/Jinli Runtime Daemon (WP01+ extension)
- Owner: 金璃小天才 (Plan) → 金璃好帮手 (Implement)
- Authority Profile: issuer-worker-v1
- Task Packet: .trae/tasks/jinli/2026-06-29-daemon-scheduler-unify/

## Code Changes

- Project/Jinli/services/runtime/scheduler.py (NEW) — DaemonScheduler + JobSpec + 6 job 默认配置 + config_path 参数（WP08）
- Project/Jinli/services/runtime/scheduler_bridge.py (NEW) — Phase 1 sync-to-async 桥接（SchedulerBridge）
- Project/Jinli/services/runtime/scheduler_config.py (NEW — WP08) — SchedulerConfig dataclass + load_from_yaml() + default_config() + validate()
- Project/Jinli/services/runtime/scheduler_config.yaml (NEW — WP08) — 6 jobs 的 trigger 参数配置 + 时区 + executor_workers + misfire_grace_time
- Project/Jinli/services/runtime/tests/test_scheduler.py (NEW) — scheduler 单测
- Project/Jinli/services/runtime/tests/test_scheduler_bridge.py (NEW) — bridge 单测
- Project/Jinli/services/runtime/tests/test_scheduler_config.py (NEW — WP08) — yaml 加载 / 缺省值 / 字段验证 单测
- Project/Jinli/services/runtime/daemon.py (MODIFY) — _run_loop 5s 块替换 + 4 订阅 + bridge 实例化 + scheduler_config.yaml 加载（WP08）
- Project/Jinli/services/runtime/service_registry_builder.py (MODIFY) — 注册 3 个新 sink + scheduler 实例
- Project/Jinli/services/runtime/api_server.py (MODIFY) — /status 端点加 scheduler 字段（含 source: yaml|hardcoded）
- Project/Jinli/services/runtime/adapters/dreamer_adapter.py (MODIFY) — 实现 enqueue(payload) -> bool
- Project/Jinli/services/runtime/adapters/proactive_adapter.py (MODIFY) — 实现 enqueue(payload) -> bool
- Project/Jinli/services/runtime/adapters/evolution_adapter.py (MODIFY) — 实现 enqueue(payload) -> bool
- Project/Jinli/services/memory/dreamer/triggers.py (MODIFY) — 新增 DreamerService.idle_check()
- Project/Jinli/services/proactive/p1/triggers.py (MODIFY) — IdleTrigger._on_tick 拆 sync/async + tick_via_scheduler()
- Project/Jinli/services/runtime/tests/test_after_turn_commit.py (MODIFY) — 加 3 sink enqueue 行为测试 + 全流程
- Project/Jinli/services/runtime/tests/test_adapters.py (MODIFY) — 加 3 sink unit test
- Project/Jinli/services/nervous/tests/test_event_bus.py (MODIFY) — 加 subscription test
- Project/Jinli/services/proactive/p1/tests/test_integration.py (MODIFY) — 加 IdleTrigger compatibility test

## Documentation Updates

- Project/Jinli/Docs/04-Implementation/runtime-protocol.md (MODIFY) — 加 §Scheduler 章节（6 jobs / 4 subscriptions / 3 sinks / Phase 1 bridge）
- Project/Jinli/Docs/06-Operations/General/runtime-daemon-runbook.md (MODIFY) — 加 Scheduler 运维章节（jobs 列表 / stop 行为 / 监控指标 / 故障排查）
- Project/Jinli/services/runtime/daemon.py docstring (MODIFY) — 更新设计文档说明 _run_loop 不再承担健康检查
- Docs/03-Architecture/KnowledgeGraph/runtime-architecture.md (MODIFY, conditional) — 如存在，加 scheduler 引用

> **Path note**: Project/Jinli 实际使用 lowercase `docs/` 目录；本任务以 `Docs/` 路径登记文档改动以满足 doc-guard 的标准化 prefix（`Project/<project>/Docs/`）。Implement 阶段文件实际写盘路径保持 `Project/Jinli/docs/` 不变。

## Docs Tree Updates

- Project/Jinli/Docs/DOCS_TREE.md

## 1. 文档改动清单（详细）

### 1.1 必改文档 (Required)

| 文档 | 改动类型 | 章节定位 | 改动内容 |
|------|---------|---------|---------|
| `Project/Jinli/docs/04-Implementation/runtime-protocol.md` | MODIFY | line 38-54 之前（新章节） | 加 `## DaemonScheduler` 章节：6 jobs / 4 subscriptions / 3 sinks / Phase 1 bridge 概述 |
| `Project/Jinli/docs/06-Operations/General/runtime-daemon-runbook.md` | MODIFY | 新章节（在 daemon lifecycle 之后） | 加 `### Scheduler 运维`：jobs 列表 / `scheduler.stop()` 行为 / 监控指标 |
| `services/runtime/daemon.py` | MODIFY | docstring at top | 更新设计文档说明 `_run_loop` 不再承担健康检查（已迁 scheduler） |

### 1.2 条件改文档 (Conditional)

| 文档 | 改动条件 | 改动内容 |
|------|---------|---------|
| `docs/03-Architecture/KnowledgeGraph/runtime-architecture.md` | 如果文件存在 | 在 `JinliDaemon` 章节加 scheduler 引用 + 架构图更新 |
| `Project/Jinli/docs/04-Implementation/runtime-protocol.md:25-37` | adapters/ 列表 | 在 `adapters/` 文件清单加注释："dreamer/proactive/evolution adapter 现已实现 enqueue()" |

### 1.3 不改文档 (NOT Modified)

| 文档 | 原因 |
|------|------|
| `Project/Jinli/docs/04-Implementation/runtime-protocol.md:88-100`（Public API） | API 表面不变（DaemonAPIServer 接口签名不变） |
| `Project/Jinli/docs/task-packages/T7-execution-package.md` | Dreamer 是 consumer，本任务不修改 Dreamer API |
| `Project/Jinli/docs/task-packages/T8-execution-package.md` | Evolution 是 consumer，本任务不修改 Evolution API |
| `Project/Jinli/docs/task-packages/T9-execution-package.md` | Proactive 是 consumer，本任务不修改 Proactive API（IdleTrigger 兼容旧 API） |
| `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md` | MIRP 契约权威文档，本任务不修改契约，只**实现**契约 |
| `services/runtime/tests/` 全部 | 测试代码改动附属于 WP01-WP06 |
| `services/jinli_daemon.py` (legacy) | 决策 D2-A：本次不动 |

## 2. 文档治理检查 (Doc-Governance)

按 `Docs/AI/46-Enforcement-Framework.md` §Doc-Governance：

### 2.1 新增文件位置合规性

| 新文件 | 应放位置 | 合规？ |
|--------|---------|-------|
| `services/runtime/scheduler.py` | `Project/Jinli/services/runtime/` | ✅ 符合 `Docs/AI/13-File-Placement-Convention.md`（runtime/ 是新模块） |
| `services/runtime/scheduler_bridge.py` | `Project/Jinli/services/runtime/` | ✅ 同上 |
| `services/runtime/scheduler_config.py` (WP08) | `Project/Jinli/services/runtime/` | ✅ 同上 |
| `services/runtime/scheduler_config.yaml` (WP08) | `Project/Jinli/services/runtime/` | ✅ 同上 |
| `services/runtime/tests/test_scheduler.py` | `Project/Jinli/services/runtime/tests/` | ✅ 符合测试代码同 module 同 dir 规则 |
| `services/runtime/tests/test_scheduler_bridge.py` | `Project/Jinli/services/runtime/tests/` | ✅ 同上 |
| `services/runtime/tests/test_scheduler_config.py` (WP08) | `Project/Jinli/services/runtime/tests/` | ✅ 同上 |
| `services/runtime/adapters/tests/test_dreamer_adapter.py` | `Project/Jinli/services/runtime/adapters/tests/` | ⚠️ **现有 `adapters/` 没有 tests 子目录**——需新建 `adapters/tests/` 或把测试放到 `runtime/tests/test_adapters.py`（已有 15 个测试） |

**建议**：将 3 个新 adapter 测试放到 `services/runtime/tests/test_adapters.py`（已存在），不创建新的 `adapters/tests/` 目录，避免目录碎片化。

### 2.2 文档位置合规性

| 文档改动 | 应放位置 | 合规？ |
|---------|---------|-------|
| `runtime-protocol.md` 加 §Scheduler 章节 | `Project/Jinli/docs/04-Implementation/` | ✅ |
| `runtime-daemon-runbook.md` 加 scheduler 运维 | `Project/Jinli/docs/06-Operations/General/` | ✅ |

### 2.3 Cross-Reference 检查

| 引用 | 来源 | 目标 |
|------|------|------|
| DaemonScheduler 引用 → scheduler.py | runtime-protocol.md §Scheduler | `services/runtime/scheduler.py` |
| SchedulerBridge 引用 → scheduler_bridge.py | runtime-protocol.md §Scheduler | `services/runtime/scheduler_bridge.py` |
| 3 sink adapter 引用 → adapters/{dreamer,proactive,evolution}_adapter.py | runtime-protocol.md §Scheduler | `services/runtime/adapters/{...}.py` |
| `/status` 端点新字段 | runtime-daemon-runbook.md | `services/runtime/api_server.py:853` |

## 3. 文档生成脚本检查

| 脚本 | 应跑 | 预期 |
|------|------|------|
| `python .trae/scripts/check-doc-placement.py` | WP07 完成后 | 通过（新增文件全部在合规位置） |
| `python .trae/scripts/check-cross-references.py` | WP07 完成后 | 通过（所有 cross-ref 文件都存在） |

## 4. 文档 Review 检查点

| Checkpoint | 谁 | 检查什么 |
|-----------|-----|---------|
| WP01-WP06 实现期间 | Implement Agent | 每个 WP 完成时同步更新代码内 docstring（不写外部分档） |
| WP07 完成后 | Verifier | 跑 `check-doc-placement.py` + `check-cross-references.py` 通过 |
| WP07 完成后 | User (Ba Ba) | 抽看 `runtime-protocol.md` §Scheduler 是否清晰（< 5 分钟可读） |

## 5. 文档改动总览图

```
Project/Jinli/docs/
├── 03-Architecture/
│   └── KnowledgeGraph/
│       └── runtime-architecture.md (MODIFY, conditional)
├── 04-Implementation/
│   └── runtime-protocol.md (MODIFY, +§Scheduler chapter)
├── 06-Operations/
│   └── General/
│       └── runtime-daemon-runbook.md (MODIFY, +Scheduler ops section)
└── task-packages/
    ├── T7-execution-package.md (NOT modified, reference only)
    ├── T8-execution-package.md (NOT modified, reference only)
    └── T9-execution-package.md (NOT modified, reference only)

Project/Jinli/services/runtime/
├── scheduler.py (NEW)
├── scheduler_bridge.py (NEW)
├── scheduler_config.py (NEW — WP08)
├── scheduler_config.yaml (NEW — WP08)
├── daemon.py (MODIFY — docstring)
├── api_server.py (MODIFY — /status 端点)
└── tests/
    ├── test_scheduler.py (NEW)
    ├── test_scheduler_bridge.py (NEW)
    ├── test_scheduler_config.py (NEW — WP08)
    ├── test_adapters.py (MODIFY — 加 3 sink tests)
    └── test_after_turn_commit.py (MODIFY — 加全流程 tests)

Project/Jinli/services/runtime/adapters/
├── dreamer_adapter.py (MODIFY — 加 enqueue)
├── proactive_adapter.py (MODIFY — 加 enqueue)
└── evolution_adapter.py (MODIFY — 加 enqueue)
```

## 6. Non-Doc Files (附注)

本任务**新增 2 个代码文件** + **修改 7 个代码文件** + **修改 3-4 个文档文件**。完整代码改动清单见 `analysis.md` §10。

---

**Total doc impact**: 2 NEW docs + 3-4 MODIFIED docs + 0 DELETED docs