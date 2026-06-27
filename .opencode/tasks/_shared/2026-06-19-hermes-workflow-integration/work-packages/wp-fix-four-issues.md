# Work Package: 修复 Hermes Workflow 四个问题

> **优先级**: P0（立即修复）→ P1（随修复）
> **关联任务包**: `2026-06-19-hermes-workflow-integration`
> **四个问题互不依赖，可并行执行**

---

## Fix 0 — [P0] 明文 API Key 泄露

**文件**: `E:\UEGameDevelopment\opencode.json` 第 18 行

**问题**: 明文存储了讯飞星辰 API Key

```json
"apiKey": "<REDACTED-REVOKE-OLD-KEY>"
```

**修复方案**:
1. 将明文密钥替换为环境变量引用
2. 通知爸爸立即在讯飞星辰控制台撤销此密钥并轮换

```json
"apiKey": "${ASTRON_API_KEY}"
```

或（如果 opencode 不支持环境变量插值）：

```json
"apiKey": ""
```

并在旁边添加注释说明需要设置环境变量。

**注意**: 爸爸需要在**讯飞星辰控制台**手动撤销此密钥。代码层面只能移除明文。

---

## Fix 1 — [P1] MCP cwd 路径

**文件**: `E:\UEGameDevelopment\.trae\hermes\profiles\jinli-planner\mcp.json`
**同等文件**: `E:\UEGameDevelopment\.trae\hermes\profiles\jinli-implementer\mcp.json`（如有）

**问题**: cwd 指向包目录本身（`jinli_workflow/`），但 `python -m jinli_workflow` 需要父目录在 sys.path 上

```json
{
  "command": "python",
  "args": ["-m", "jinli_workflow"],
  "cwd": "E:/UEGameDevelopment/.trae/hermes/mcp/jinli_workflow"
}
```

**修复**: cwd 应为包所在的父目录

```json
{
  "cwd": "E:/UEGameDevelopment/.trae/hermes/mcp"
}
```

**同时确认 jinli-implementer profile** 是否有相同问题，一并修复。

---

## Fix 2 — [P1] .gitignore 白名单

**文件**: `E:\UEGameDevelopment\.gitignore`

**问题**: `/.trae/*` 第 44 行拒绝所有 `.trae/` 子目录，但后面 `!/.trae/memory/`、`!/.trae/scripts/` 等用白名单开了例外。hermes 相关目录没有被白名单覆盖：

- `.trae/hermes/profiles/**`
- `.trae/hermes/mcp/**`
- `.trae/hermes/plugins/**`

**修复**: 在 `/.trae/*` 之后、已有白名单条目之前（或之后），添加 hermes 的白名单：

```gitignore
# Hermes MCP workflow runtime
!/.trae/hermes/
!/.trae/hermes/**
```

放在第 44 行 `/.trae/*` 之后即可。gitignore 的规则是：后面的 `!` 模式可以取消前面 `*` 或 `*` 模式的排除。

---

## Fix 3 — [P1] 任务状态互相矛盾

**文件**: `E:\UEGameDevelopment\.trae\tasks\_shared\2026-06-19-hermes-workflow-integration\.task.yaml`

**问题**: `phase: review` 但 `verify_result: pass` 且 `verified_at: null`。这是矛盾状态。

**修复**: 使状态一致。根据爸爸的验收结论 "链路主体已经很接近完成，但现在还不能归档或签收"：

```yaml
phase: review
review_result: pass     # Review 已通过
verify_result: pending  # Verify 等待最终确认
verification_report: .trae/tasks/_shared/2026-06-19-hermes-workflow-integration/verification-report.md
```

**注意**: 不要设置 `verify_result: pass`。爸爸明确说还不能归档。

---

## 验证

### 1. Python MCP 模块可启动

```powershell
cd E:/UEGameDevelopment/.trae/hermes/mcp
python -m jinli_workflow --help
# 预期: 正常输出帮助信息，不报 No module named jinli_workflow
```

### 2. Git 追踪验证

```powershell
git check-ignore .trae/hermes/profiles/jinli-planner/mcp.json
# 预期: 无输出（文件未被忽略）
git check-ignore .trae/hermes/mcp/jinli_workflow/__main__.py
# 预期: 无输出（文件未被忽略）
```

### 3. 任务状态一致

```powershell
Get-Content .trae/tasks/_shared/2026-06-19-hermes-workflow-integration/.task.yaml
# 预期: phase=review, review_result=pass, verify_result=pending
```

### 4. opencode.json 无明文密钥

```powershell
Select-String -Path opencode.json -Pattern "apiKey" | Select-Object -First 1
# 预期: 显示 ${ASTRON_API_KEY} 或空字符串，不是 32 位哈希格式
```

---

## 不得做的事情

- ❌ 不得设置 `verify_result: pass`（爸爸说不能归档）
- ❌ 不得删除或覆盖已有历史报告
- ❌ 不得尝试用已泄露的密钥做任何 API 调用
- ❌ 密钥撤销必须由爸爸在讯飞星辰控制台手动执行
