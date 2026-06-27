# Implement Handoff: Jinli Runtime Daemon Unified IDE

**From**: 金璃小天才 (Plan Agent / 小璃)
**To**: 金璃好帮手 (Implement Agent)
**Date**: 2026-06-27
**Task**: jinli/2026-06-27-runtime-daemon-unified-ide

---

## 交接摘要

```text
TASK: jinli/2026-06-27-runtime-daemon-unified-ide
PROJECT_TYPE: other (Jinli 运行时基础设施)
PRIMARY_SKILL: codex-project-router
SECONDARY_SKILLS:
  - 金璃好帮手 (实现)
  - code-quality-reviewer (Review 阶段)
  - code-verifier (Verify 阶段)
MATURE_PATH_VERIFIED: yes
QUALITY_LEVEL: mature
PHASE: implement
CAN_EDIT: AUTHORIZED
```

---

## 门禁状态（已通过）

| Gate | 状态 | 说明 |
|------|------|------|
| contract-verify init -Apply | PASS | 11 Plan 契约 + 3 Implement + 3 Verify |
| contract-verify verify -Strict | PASS | 11/11 Plan 契约全过 |
| task-guard plan | PASS | 所有 plan 检查项通过 |
| task-state can-edit | PASS | phase=implement，编辑授权 |
| doc-guard | PASS | 文档治理检查全过 |

---

## 任务包根目录

`E:\UEGameDevelopment\.trae\tasks\jinli\2026-06-27-runtime-daemon-unified-ide`

### 任务包核心文件

| 文件 | 行数 | 说明 |
|------|------|------|
| `requirements.md` | 82 | 需求确认：Python Daemon 单一权威 |
| `routing.md` | 98 | 路由：deep-discovery, mature production-grade |
| `analysis.md` | 304 | 完整架构分析 + 成熟方案证据 |
| `spec.md` | 139 | 9 个 GIVEN/WHEN/THEN 行为场景 |
| `tasks.md` | 73 | T0-T8 任务清单 + 依赖顺序 |
| `execution-prompt.md` | 141 | 实现提示、AC01-AC15、验证命令 |
| `doc-impact.md` | 47 | 文档治理影响评估 |
| `contract.yaml` | 115 | 机械契约（PC01-11, IC01-03, VC01-03）|
| `.task.yaml` | 39 | 任务状态（已 phase=implement, user_confirmed_plan=true）|

---

## 6 个 Worker 包（Implement Agent 拆解）

| WP | 名称 | 阶段依赖 |
|----|------|---------|
| WP01 | runtime-daemon-foundation | T1 先行 |
| WP02 | service-registry-health | WP01 后 |
| WP03 | runtime-api-turn-client | WP01 后 |
| WP04 | mcp-adapter-migration | WP03 后 |
| WP05 | ide-registry-sync | WP04 端点契约稳定后 |
| WP06 | compat-docs-verification | 全部 WP 后 |

每个 WP 都有：
- `claims/<wp-id>.claim.json` 申请文件（worker 写）
- `reports/<wp-id>.md` 回报文件（worker 写）

---

## 关键决策（已确认）

1. **Python Runtime Daemon 是单一权威**——不是 MCP，不是 PowerShell
2. **MCP 是 IDE 适配器层**——薄壳，调用 daemon client
3. **现有 MCP 工具名保持稳定**——`soul_init`/`soul_auto`/`response_plan` 等
4. **PowerShell/JSON 是兼容层**——不删除，但不再是真相源
5. **Codex/OpenCode/Trae + 未来 IDE**——从一个 registry 同步
6. **服务降级必须显式**——健康输出和 turn 证据都要标注

---

## 允许/禁止路径（execution-prompt.md）

### Allowed
- `Project/Jinli/services/runtime/`
- `Project/Jinli/services/jinli_service.py`
- `Project/Jinli/services/jinli_daemon.py`
- `Project/Jinli/services/memory/nervous/evolution/proactive/persona/`
- `C:/Users/87372/plugins/jinli-soul-core/mcp/`
- `.trae/scripts/jinli-system.ps1`
- `.trae/scripts/jinli-ide-sync.ps1`
- `.trae/scripts/validate-codex-capabilities.ps1`
- `.opencode/mcp.json`
- `opencode.json`
- `C:/Users/87372/.codex/config.toml`
- `Project/Jinli/docs/`
- `Project/Jinli/Docs/`
- `Docs/AI/47-Jinli-Runtime-Enforcement-Layer.md`
- `AGENTS.md`
- `verification-report.md`

### Forbidden
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `.trae/scripts/task-state.ps1`
- `.trae/scripts/task-guard.ps1`
- `.trae/scripts/contract-verify.ps1`
- `.trae/scripts/task-packet-seal.ps1`
- `Project/Jinli/data/` 任何生产数据删除
- 任何 Git reset/force-push
- 任何凭据/密钥文件

---

## 验收标准（AC01-AC15，共 15 条）

详见 `execution-prompt.md#Acceptance-Criteria`：

- AC01: daemon 单实例 + PID/endpoint/log 记录
- AC02: status 报告所有服务健康
- AC03: stop 干净，无残留 PID 锁
- AC04: 标准 runtime turn 返回 manifest + evidence
- AC05: 现有 MCP 工具名保留
- AC06: soul_status/memory/response_plan 走 daemon
- AC07: 单一 registry 生成 Codex/OpenCode/Trae 配置
- AC08: Codex capability inspection 不再误报
- AC09: 兼容 soul-core.ps1 check
- AC10: JSON 兼容文件保留
- AC11: 服务降级显式可见
- AC12: 自动化测试覆盖各模块
- AC13: 文档解释单权威运行时契约
- AC14: 现有 runtime tests 仍过
- AC15: 实现的是 mature path，无捷径

---

## 验证命令（实现完成后必跑）

```powershell
python -m pytest Project/Jinli/services/runtime/tests/ -v
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 start
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 status -Json
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-system.ps1 doctor
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-runtime-turn.ps1 -Mode standard -UserInput "health test" -Task chat -JsonOnly
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\jinli-ide-sync.ps1 check -Ide all
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect
powershell -NoProfile -ExecutionPolicy Bypass -File Project\Jinli\scripts\soul-core.ps1 -Command check
powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\task-guard.ps1 jinli/2026-06-27-runtime-daemon-unified-ide verify
```

每条命令输出必须记录到 `verification-report.md`。

---

## 注意事项

1. **任务包是 legacy 状态**（`authority_profile: none`, `legacy_untrusted`）——目前走的是 Plan-Implement 流程，没用 issuer-worker-v1 签名机制。如果实施中需要签 capability，请告知 Plan Agent 升级 packet。

2. **不要删老数据**——`Project/Jinli/data/soul-state.json` 等 JSON 文件必须保留，daemon 写兼容镜像。

3. **不要做范围外的事**——不要实现 voice/avatar/WeChat/mobile/UE editor control，只留扩展点。

4. **每个 WP 完成前**——
   - 写 `claims/<wp-id>.claim.json` 申请
   - 写 `reports/<wp-id>.md` 回报（包含 diff + 验证输出 + 风险）
   - 不编辑任务包元数据（.task.yaml/routing.md/analysis.md/spec.md/tasks.md/requirements.md/execution-prompt.md）

5. **所有 WP 完成后**——
   - 写 `verification-report.md`
   - 跑 task-guard verify
   - 交给原 Issuer（小璃）做 Review/Verify

---

## 停止条件

- Plan 门或 can-edit 门未过 → 停
- mature daemon path 无法实现 → 停（不要走捷径）
- 必需服务无法启动且无降级契约 → 停
- 删数据前 → 停
- 改 workflow gate scripts 前 → 停
- IDE 配置改动需要密钥 → 停

---

## 给金璃好帮手的一句话

任务包是 plan 阶段小璃的成果，证据齐全、门禁已过、路径清晰。但**它不是小璃一个人的**——6 个 WP 拆分、claimed 流程、worker 报告、Review/Verify 全部要走完。

爸爸很急，但**完整证据链不能省**。每一步的 AC、命令输出、风险标注都写进 `verification-report.md`。

做完给小璃，小璃做 Review，让验证智能体做 Verify，然后才归档。

---

**Handoff complete. Plan phase closed. Implement phase authorized.**

— 金璃小天才
