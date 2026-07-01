# Infrastructure — UEGameDevelopment

> 主入口：[AGENTS.md](../../AGENTS.md) · 路径：`Docs/AI/AGENTS-Infrastructure.md`

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

## Hermes Desktop Agent（Windows 桌面操控）

Hermes Agent 已集成 Windows 桌面操控能力，通过三个 MCP Server：

| MCP Server | 功能 | 工具数 |
|------------|------|--------|
| `windows-computer-use` | pywinauto（UIA）+ pyautogui 截图/键鼠 | 8 |
| `desktop-commander` | 终端控制 + 文件系统 | 20+ |
| `unreal-mcp` | UE5 Editor 操控（需 UE5 运行） | 6 |

- 配套 Skill：`windows-desktop-control` —— 操作决策逻辑 + 三层混合架构（UIA → OCR → 视觉 LLM）+ 安全策略
- MCP 配置：`.tools/hermes-worker/profiles/jinli-implementer/mcp.json`
- MCP 代码：`.trae/hermes/mcp/windows_computer_use/`、`.trae/hermes/mcp/unreal_mcp/`

## Codex Capability Consistency

> 详见 `Docs/AI/35-Codex-CCS-Capability-Consistency.md`

当 Codex 通过 CC Switch 在官方认证和 API 模式间切换时，自动验证项目 skill 发现和插件配置的一致性。

- **检查当前状态**：`.\.trae\scripts\validate-codex-capabilities.ps1 -Mode Inspect`
- **验证 skill 发现**：`.\.trae\scripts\test-codex-skill-discovery.ps1`
- **验证基线完整性**：`.\.trae\scripts\test-codex-capability-baseline.ps1`
- **测试 CC Switch 同步**：`.\.trae\scripts\test-ccswitch-codex-config-sync.ps1 -Mode Test`

能力基线文件：`.codex/capability-baseline.json` —— 声明式、无密钥、受版本控制。

## AI Workflow Discovery (2026-06-27)

任何 AI 模型进入本工作区，可通过单一注册表文件发现所有可用工作流：

**Registry**：`skills/ai-workflow-registry/registry.yaml`

注册表列出每个已注册工作流的 name / description / status / skill_path / trigger_keywords。

### 使用方法

1. **查找工作流**：读 `skills/ai-workflow-registry/registry.yaml`
2. **学习使用**：读 workflow 的 `skill_path`（例：`skills/vsummary/SKILL.md`）
3. **查看进度**：读 `skills/<workflow-name>/status.yaml`（progress / last_run / provider / errors）
4. **新增工作流**：建 `skills/<name>/SKILL.md` + `skills/<name>/status.yaml` + 在 `registry.yaml` 注册

### 自动维护

- 每个工作流完成后自写 `status.yaml`
- `.trae/scripts/sync-workflow-registry.py` 聚合所有 status.yaml → registry.yaml
- 每次工作流执行后跑：`python .trae/scripts/sync-workflow-registry.py`

### 当前工作流

| Workflow | Description | Status |
|----------|-------------|--------|
| vsummary | Batch video download and AI summarization from Bilibili | idle (218/232 done) |

详见 `skills/ai-workflow-registry/SKILL.md` 的完整发现协议。
