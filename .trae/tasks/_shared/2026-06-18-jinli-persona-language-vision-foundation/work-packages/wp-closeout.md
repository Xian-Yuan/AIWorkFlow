# Work Package: Phase 2 Closeout — Fix, Test, Verify, Archive

> **关联任务包 A**: `2026-06-18-jinli-persona-language-vision-foundation`  
> **关联任务包 B**: `2026-06-18-jinli-agent-soul-upgrade`  
> **共有阻塞点**: MCP Plugin `tools-orchestrator.mjs` 的 2 个修复  
> **执行者**: 金璃好帮手  
> **预估**: 1-2h

---

## 修复 1 — response_plan handler（必要）

**文件**: `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools-orchestrator.mjs`

**问题**: 第 208 行调用 `avatarBridge.consumeActionIntent(responsePlan.action_intent)`，但 `avatar-bridge.mjs` 的模块级导出没有 `consumeActionIntent`（这是 `PresentationState` 类的方法）。

**修复方案**:
- 删除 Step 4 中 `consumeActionIntent` 的调用
- response_plan 只是规划层，没有真实 Avatar adapter 时不应执行或确认动作
- 保留 `action_intent.status = 'desired'`、`avatar_processed = false`、`avatar_confirmed = false`
- 由 SKILL.md 的 Invisible Engine Rule 保证输出时用愿望语气（"小璃想..."），不用已完成语气

```js
// 修改前 (L205-216):
if (responsePlan.action_intent && responsePlan.action_intent.action_type !== 'none') {
  const avatarBridge = await getAvatarBridge();
  avatarBridge.consumeActionIntent(responsePlan.action_intent);
  responsePlan.action_intent = {
    ...responsePlan.action_intent,
    status: 'desired',
    avatar_processed: false,
    avatar_confirmed: false,
  };
}

// 修改后:
// response_plan 是纯规划层 — 不消费、不执行 action_intent
// action_intent 保持 desired 状态，由 expression-orchestrator 生成
// 真实 Avatar adapter 上线后由消费方处理
```

---

## 修复 2 — Vision CLI 包路径（必要）

**文件**: `C:\Users\87372\plugins\jinli-soul-core\mcp\lib\tools-orchestrator.mjs`

**问题**: `visionStartHandler`（L261）、`visionStopHandler`（L311）、`visionStatusHandler`（L339）调用 `python -m vision.cli` 时 cwd 设为 `services/vision`。Python 的 `-m` 需要包根目录在 sys.path 上，但 `services/vision` 是包目录本身，不是包含包的目录。正确路径是 `services/`。

**修复方案**:
- 所有 3 个 handler 将 cwd 从 `join(PROJECT_JINLI, 'services', 'vision')` 改为 `join(PROJECT_JINLI, 'services')`

```js
// 修改前:
cwd: join(PROJECT_JINLI, 'services', 'vision')

// 修改后:
cwd: join(PROJECT_JINLI, 'services')
```

同时第 35 行 `VISION_CLI` 路径是 `.py` 文件路径，`python -m` 不需要这个。保持为存在性检查即可。

---

## 修复 3 — 安装 Python 依赖（必要）

```powershell
python -m pip install -r Project/Jinli/services/vision/requirements.txt
```

**依赖**: pytest>=8, mss>=9, Pillow>=10

如网络或权限失败，记录错误并申请授权。

---

## 验证步骤

### V1: Node 测试（198/198）

```powershell
$tests = Get-ChildItem Project/Jinli/tests -Filter *.test.mjs | Select-Object -ExpandProperty FullName
node --test $tests
```

预期: 198/198 pass。包含修复后 plugin-orchestrator.test.mjs 的 2 个测试。

### V2: Python 测试

```powershell
$env:PYTHONPATH = (Resolve-Path Project/Jinli/services).Path
python -m pytest Project/Jinli/services/vision/tests -q
```

### V3: Plugin 语法检查

```powershell
npm.cmd run check --prefix C:\Users\87372\plugins\jinli-soul-core
```

### V4: Soul Core 回归

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/test-soul-core-e2e.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Project/Jinli/scripts/soul-core-review.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/test-workflow-regression.ps1
```

### V5: Vision status 功能验证（只查询不截图）

```powershell
node --test Project/Jinli/tests/plugin-orchestrator.test.mjs
```

预期: 2/2 pass，不再返回 `unknown` / `error fallback`。

---

## Acceptance Criteria

| AC | 任务包 | 验证方式 |
|:--:|:------:|----------|
| AC01 | Foundation | `response_plan` 返回 live plan，无 `error fallback` |
| AC02 | Foundation | `vision_status` 返回非 `unknown`（不报模块找不到） |
| AC03 | Foundation | Node 测试 198/198 pass |
| AC04 | Foundation | Python pytest 套件通过 |
| AC05 | Foundation | Soul Core E2E + Review 24/24 通过 |
| AC06 | Foundation | Workflow regression 20/20 通过 |
| AC07 | Agent Soul | `response_plan` 修复后重新验证 AC01-AC18 |
| AC08 | Both | 更新 verification-report.md |
| AC09 | Both | task-guard verify 通过 |
| AC10 | Both | 归档完成 |

---

## 残余风险

- **Python 依赖安装**: 如果网络/权限失败，vision 部分保持 mock 模式，不影响其他模块
- **MCP Plugin 外部路径**: `C:\Users\87372\plugins\jinli-soul-core` 不在工作区内，修改后确保运行 `npm.cmd run check` 验证语法
- **屏幕截图**: 不做真实截图，仅验证 `vision_status` 接口正常
