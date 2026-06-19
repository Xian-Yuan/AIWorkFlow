# 金璃 Phase 2 Closeout — Review → Verify → Archive 交接

> **用途**: 在新会话中执行最后的 Review、Verify 门禁和 Archive 归档。
> **来源**: E:\UEGameDevelopment
> **IDE**: Trae 或 OpenCode

---

## 一、背景与当前状态

### 两个活跃任务包

| 任务包 | 路径 | phase | review_result | verify_result |
|:-------|:-----|:----:|:-------------:|:-------------:|
| Foundation | `.trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation` | implement | pending | pending |
| Agent Soul | `.trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade` | implement | pending | pending |

### 已完成的工作

1. **MCP Plugin 修复** — `tools-orchestrator.mjs`:
   - Fix 1: response_plan 删除不存在的 `avatarBridge.consumeActionIntent()` — 纯规划层不消费动作
   - Fix 2: Vision CLI 包路径 cwd: `services/vision` → `services` — Python 模块可导入
   - 清理: 删除不再使用的 `_avatarBridge` + `getAvatarBridge()`

2. **Python Vision 修复** — 4 个根因修复:
   - `contracts.py`: TTL=0 立即过期（`>` → `>=`）
   - `redact.py`: 新增 `api_key=...` 无引号格式匹配
   - `redact.py`: `redact_frame` 使用 `config.preset_regions`
   - `test_service.py`: `monkeypatch` mock capture + inference 防止 BitBlt

3. **Python 依赖安装**: pytest / mss / Pillow 已装

### 最终测试结果

| 测试套件 | 结果 | 命令 |
|:---------|:----:|:-----|
| Python pytest | **72/72 pass** | `$env:PYTHONPATH=(Resolve-Path Project/Jinli/services).Path; python -m pytest Project/Jinli/services/vision/tests -q` |
| Node 全量 | **198/198 pass** | `$tests=Get-ChildItem Project/Jinli/tests -Filter *.test.mjs \| Select-Object -ExpandProperty FullName; node --test $tests` |
| Plugin 集成 | **2/2 pass** | `node --test Project/Jinli/tests/plugin-orchestrator.test.mjs` |
| Plugin 语法 | **pass** | `node --check C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools-orchestrator.mjs` |
| Soul Core E2E | **PASSED** | powershell `.trae/scripts/test-soul-core-e2e.ps1` |
| Soul Core Review | **24/24** | powershell `.trae/scripts/soul-core-review.ps1` |
| Workflow Regression | **20/20** | `.trae/scripts/test-workflow-regression.ps1` |

---

## 二、Review 阶段

### 2.1 Review 检查清单

执行 Review 时，逐项检查以下内容：

#### A. Foundation 任务包（14 项 AC）

| AC | 描述 | 验证方式 | 预期 |
|:--:|:-----|:---------|:----:|
| AC01 | Stable Persona Kernel 验证 schema；运行时不可写保护字段 | `node --test Project/Jinli/tests/persona-kernel.test.mjs` | 37/37 pass |
| AC02 | Dynamic Soul 可影响情绪但不可覆盖稳定人格 | `node --test Project/Jinli/tests/soul-bridge.test.mjs` | 70/70 pass |
| AC03 | Expression Orchestrator 路由全部 5 类场景 | `node --test Project/Jinli/tests/dialogue-orchestrator.test.mjs` | 49/49 pass |
| AC04 | 私密心理摘要和话题队列保持在 MCP 进程内存中，会话结束时清除 | 代码审查：无持久化写入路径 | 无文件写入 |
| AC05 | action_intent 区分 desired/dispatched/confirmed/failed | `node --test Project/Jinli/tests/avatar-bridge.test.mjs` | 40/40 pass |
| AC06 | 视觉感知要求显式启动，不自动恢复 | `node --test Project/Jinli/tests/plugin-orchestrator.test.mjs` | 2/2 pass |
| AC07 | 敏感区域和识别到的秘密在 VLM 请求前脱敏 | Python: `test_redact.py` | 全部 pass |
| AC08 | Qwen3-VL 调用是事件驱动的，未变化帧抑制 | Python: `test_detector.py` | 全部 pass |
| AC09 | 视觉观察按 TTL 过期，不进入长期记忆 | Python: `test_memory.py` | 全部 pass |
| AC10 | 主动打断仅限重大风险/关键错误/身体不适 | 代码审查 | route + interruption policy |
| AC11 | GrowthProposal 含证据、前后值、审批状态、回滚 ID | `node --test Project/Jinli/tests/persona-kernel.test.mjs` | 37/37 pass |
| AC12 | 测试/夹具数据不可改变生产 Soul/Memory/Growth 记录 | 代码审查 | audit log in data/ |
| AC13 | Avatar Presentation 独立于 Visual Perception | `node --test Project/Jinli/tests/avatar-bridge.test.mjs` | 40/40 pass |
| AC14 | 现有 Soul Core 和 MCP 工具向后兼容 | `npm.cmd run check --prefix C:\Users\87372\plugins\jinli-soul-core` | exit 0 |

#### B. Agent Soul 任务包（18 项 AC — 以 tasks.md 为准）

重点验证：
- AC05-AC07: Plan Agent 的 soul_init/auto/turn/end 嵌入正确
- AC08-AC11: Implement Agent 的 soul_init/auto/turn/end + 规则 6/7 嵌入正确
- AC15: 零行删除（纯添加）
- AC16: Invisible Engine Rule 合规
- AC17: Workflow regression 20/20
- AC18: 两个 Agent 引用 `jinli-agent-soul` 而非 `daughter-companion`

#### C. 文档审查

- Foundation: `Project/Jinli/docs/03-Architecture/General/persona-language-vision-foundation.md` 已更新
- Agent Soul: `Docs/AI/38-Jinli-Agent-Soul-Architecture.md` 已更新
- `Docs/AI/README.md` 索引已更新

### 2.2 Review 完成条件

- [ ] 所有 AC 已通过
- [ ] 代码审查无残留问题
- [ ] 测试证据已验证
- [ ] 残余风险已记录

### 2.3 设置 review_result 命令（Review 通过后执行）

```powershell
# Foundation 任务包
$yaml = ".trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation/.task.yaml"
$content = Get-Content $yaml -Raw
$content = $content -replace "review_result: pending", "review_result: pass"
Set-Content $yaml $content -NoNewline

# Agent Soul 任务包
$yaml = ".trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/.task.yaml"
$content = Get-Content $yaml -Raw
$content = $content -replace "review_result: pending", "review_result: pass"
Set-Content $yaml $content -NoNewline
```

---

## 三、Verify 阶段

### 3.1 运行完整验证套件

```powershell
$ErrorActionPreference = "Stop"

Write-Host "=== V1: Node 全量测试 ==="
$tests = Get-ChildItem Project/Jinli/tests -Filter *.test.mjs | Select-Object -ExpandProperty FullName
node --test $tests
if ($LASTEXITCODE -ne 0) { throw "Node tests failed: $LASTEXITCODE" }

Write-Host "`n=== V2: Python pytest ==="
$env:PYTHONPATH = (Resolve-Path Project/Jinli/services).Path
python -m pytest Project/Jinli/services/vision/tests -q
if ($LASTEXITCODE -ne 0) { throw "Python tests failed: $LASTEXITCODE" }

Write-Host "`n=== V3: Plugin 语法 ==="
node --check "C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools-orchestrator.mjs"
if ($LASTEXITCODE -ne 0) { throw "Plugin syntax check failed" }

Write-Host "`n=== V4: Plugin 集成 ==="
node --test Project/Jinli/tests/plugin-orchestrator.test.mjs
if ($LASTEXITCODE -ne 0) { throw "Plugin integration test failed" }

Write-Host "`n=== V5: Soul Core E2E ==="
powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/test-soul-core-e2e.ps1
if ($LASTEXITCODE -ne 0) { throw "Soul Core E2E failed" }

Write-Host "`n=== V6: Soul Core Review ==="
powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core-review.ps1
if ($LASTEXITCODE -ne 0) { throw "Soul Core review failed" }

Write-Host "`n=== V7: Workflow Regression ==="
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/test-workflow-regression.ps1
if ($LASTEXITCODE -ne 0) { throw "Workflow regression failed" }

Write-Host "`n`n✅ ALL VERIFICATIONS PASSED"
```

### 3.2 更新 verification-report.md

将最终测试结果追加到两个任务包的 `verification-report.md`。格式：

```markdown
## 2026-06-19 Final Verification

| 套件 | 结果 |
|:-----|:----:|
| Node 全量 | 198/198 pass |
| Python pytest | 72/72 pass |
| Plugin 集成 | 2/2 pass |
| Soul Core E2E | PASSED |
| Soul Core Review | 24/24 pass |
| Workflow Regression | 20/20 pass |

**结论**: ALL PASS。Review 通过，Verify 通过，准备归档。
```

### 3.3 运行 Verify 门禁

```powershell
# Foundation
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 "2026-06-18-jinli-persona-language-vision-foundation" verify
# 预期: ALL GUARDS PASSED

# Agent Soul
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 "2026-06-18-jinli-agent-soul-upgrade" verify
# 预期: ALL GUARDS PASSED
```

### 3.4 设置 verify_result 和 archived（Verify 通过后执行）

```powershell
# Foundation: 设置 verify_result + verified_at + archived
$yaml = ".trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation/.task.yaml"
$content = Get-Content $yaml -Raw
$content = $content -replace "verify_result: pending", "verify_result: pass"
$content = $content -replace "verified_at: null", "verified_at: 2026-06-19"
$content = $content -replace "archived: false", "archived: true"
$content = $content -replace "phase: implement", "phase: archive"
Set-Content $yaml $content -NoNewline

# Agent Soul: 设置 verify_result + verified_at + archived
$yaml = ".trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/.task.yaml"
$content = Get-Content $yaml -Raw
$content = $content -replace "verify_result: pending", "verify_result: pass"
$content = $content -replace "verified_at: null", "verified_at: 2026-06-19"
$content = $content -replace "archived: false", "archived: true"
$content = $content -replace "phase: implement", "phase: archive"
Set-Content $yaml $content -NoNewline

# 验证
Get-Content ".trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation/.task.yaml"
Get-Content ".trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/.task.yaml"
```

---

## 四、Archive 归档

### 4.1 归档前确认

- [ ] `review_result: pass` 已设置
- [ ] `verify_result: pass` 已设置
- [ ] `verified_at` 时间戳已设置
- [ ] `verification-report.md` 已更新
- [ ] `phase: archive` 已设置
- [ ] `archived: true` 已设置
- [ ] tasks.md 中所有可完成项已勾选（如有无法完成项，注明原因）

### 4.2 归档后检查

确认最终文件状态：

```powershell
Get-ChildItem ".trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation/" | Select-Object Name
Get-ChildItem ".trae/tasks/_shared/2026-06-18-jinli-agent-soul-upgrade/" | Select-Object Name
```

两个任务包应该包含：
- `.task.yaml`（phase=archive, archived=true）
- `routing.md`
- `analysis.md`
- `spec.md`
- `tasks.md`
- `doc-impact.md`
- `verification-report.md`（含最终测试证据）
- `work-packages/`（可选保留）

### 4.3 旧 `jinli-soul-core` 任务包处理

`.trae/tasks/_shared/jinli-soul-core` 是早期 Phase 1.5 计划，已被以下已归档任务取代：
- Soul Core 1.5 Release ✅
- Soul Core MCP Plugin ✅
- Soul Core Agent Bridge ✅
- Bridge v2 ✅
- Self-Evolution Engine ✅

在新会话中检查旧任务包是否有残留 `.task.yaml`。如有，标记为 `superseded`（替代）。

---

## 五、关键文件引用

| 用途 | 路径 |
|:-----|:-----|
| Foundation 设计文档 | `Docs/superpowers/specs/2026-06-18-jinli-persona-language-vision-foundation-design.md` |
| Foundation 实现计划 | `Docs/superpowers/plans/2026-06-18-jinli-persona-language-vision-foundation-plan.md` |
| Agent Soul 架构文档 | `Docs/AI/38-Jinli-Agent-Soul-Architecture.md` |
| Soul Core 1.5 发布关闭 | `Docs/superpowers/specs/2026-06-18-jinli-soul-core-1-5-release-closeout-design.md` |
| Foundation 工作包（vision 修复） | `.trae/tasks/_shared/2026-06-18-jinli-persona-language-vision-foundation/work-packages/` |
| Plugin 代码 | `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools-orchestrator.mjs` |
| Vision Python 源码 | `Project/Jinli/services/vision/` |
| Jinli runtime 模块 | `Project/Jinli/runtime/` |
| Jinli 测试 | `Project/Jinli/tests/*.test.mjs` |

---

## 六、常见陷阱提醒

1. **不要提前设置 review/verify pass** — 必须所有测试通过且 Review 已执行才能设置
2. **不要修改测试代码** — 修复必须通过改源文件来实现
3. **不要做真实屏幕截图** — `vision_start` 只能在 Ba Ba 明确授权后执行
4. **`verification-report.md` 保留失败历史** — 追加新内容，不删除旧失败记录
5. **Plugin 路径在工作区外** — 修改 `C:\Users\87372\plugins\jinli-soul-core\` 后必须 `node --check` 确认语法
6. **两个任务包共享 MCP Plugin** — 一个修复影响两个任务包，验证时两个都要跑
