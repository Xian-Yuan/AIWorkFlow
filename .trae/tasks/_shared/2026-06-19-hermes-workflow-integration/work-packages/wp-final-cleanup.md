# Hermes Workflow Integration — 最终修复 + 一致性清理

> **用途**: 在新会话中执行剩余 5 项修复，然后 Review → Verify → Archive
> **来源**: E:\UEGameDevelopment | **IDE**: Trae 或 OpenCode

---

## 一、背景

### 当前已通过项

| 项目 | 结果 |
|:-----|:----:|
| API Key 泄露 | ✅ 已移除（旧密钥仓库无匹配） |
| MCP stdio 启动 | ✅ `initialize` 握手通过 |
| Git 白名单 | ✅ Hermes 源码不再被忽略 |
| Skill 兼容性 | ✅ 27/27 |
| Python 测试 | ✅ 18/18 |
| 集成测试 | ✅ 14/14 |
| 两个 Profile doctor | ✅ 退出码 0 |
| Review gate | ✅ 通过 |
| Verify gate | ⏸ 按预期因 `verify_result: pending` 阻断 |

### 任务包路径

`.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/`

---

## 二、剩余 5 项修复

### 修复 1 — review_result 恢复 pending

**文件**: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/.task.yaml`

**原因**: 当前的 `review_result: pass` 是由无独立性的同一会话签署的。需要恢复 pending，由新会话做独立 Review。

**操作**:
```yaml
# 第 10 行
review_result: pending   # 恢复 pending，等待独立 Review
```

### 修复 2 — spec.md 同步到真实状态

**文件**: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/spec.md`

**问题**: 第 5 行仍显示 Plan、0/13、全部场景 pending，实际已经 Implement 完成、Review 待重新执行。

**操作**: 找到文件中的状态行（通常在顶部或末尾的 Progress Summary），更新为：

```markdown
> **状态**: Implement ✅ | Review ⏳ | Verify ⏳
```

同时更新每个 scenario 的状态。先读 `spec.md`，找到正确的章节修改。

### 修复 3 — verification-report.md 清理矛盾声明

**文件**: `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/verification-report.md`

**问题**: 第 6 行宣称 "Verify Complete"、"13/13"，但 verify 因 `pending` 被阻断。

**操作**: 在文件顶部添加 Addendum，标注当前真实状态：

```markdown
## 2026-06-19 最终状态修正

> 本附注取代以下历史结论中的矛盾声明。
> 
> **当前真实状态**:
> - review_result: pending（等待独立 Review）
> - verify_result: pending
> - phase: review
> - 不可归档

历史报告保留以供审计参考。
```

### 修复 4 — Docs/AI/39 文档同步

**文件**: `E:\UEGameDevelopment\Docs/AI/39-Hermes-Workflow-Integration.md`

**问题**: 第 100 行附近仍声称 Profiles 使用 `${API_KEY}`，与"移除 model 段并继承主配置"的最终实现不符。

**操作**: 读文件找到相关章节（约第 95-110 行），将 `${API_KEY}` 的引用更新为描述"继承主 opencode.json 配置，不再内联 model/apiKey"。

### 修复 5 — 固化 stdio initialize 测试

**原因**: 集成测试只检查 MCP 文件存在，没有 stdio 启动测试。本次 cwd 问题修复后，需要固化回归测试防止复发。

**检查现有测试**: 找到集成测试文件（可能在 `.trae/hermes/` 下或任务包的测试文件中），看看现有 14/14 测试覆盖了什么。

**添加测试**: 在适当的测试文件中添加一个 stdio initialize 握手测试，验证 MCP server 能正常启动并响应 `initialize` 请求。测试思路：

```python
# 或 PowerShell 版本
# 1. 启动子进程: python -m jinli_workflow --role planner
# 2. 发送 JSON-RPC initialize 请求
# 3. 读取响应，验证 result.serverInfo.name 包含 "jinli-workflow"
# 4. 发送 shutdown/exit 清理
```

如果现有测试框架不适合加这个测试，**至少**在 `verification-report.md` 中记录手动验证命令：

```powershell
# stdio initialize 回归验证
$echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | python -m jinli_workflow --role planner
# 预期: 输出包含 "jinli-workflow" 的 JSON-RPC 响应
```

---

## 三、执行顺序

```
Step 1: 修复 1 — review_result → pending
Step 2: 修复 2 — spec.md 状态同步
Step 3: 修复 4 — Docs/AI/39 文档更新
Step 4: 修复 3 — verification-report.md Addendum
Step 5: 修复 5 — 固化 stdio 测试
     │
     ▼
Step 6: 通过 Review gate
Step 7: 通过 Verify gate（此时 verify_result 自动转为 pass）
Step 8: phase → archive
Step 9: 报告完成
```

---

## 四、门禁命令

### Review gate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 "2026-06-19-hermes-workflow-integration" verify
```

> 注意：这个命令名是 `verify` 但它是 Verify gate，不是 Review gate。
> Review 不需要跑 gate，只需要人工检查后设置 review_result: pass。

Review 完成后设置：
```powershell
$yaml = ".trae/tasks/_shared/2026-06-19-hermes-workflow-integration/.task.yaml"
$content = Get-Content $yaml -Raw
$content = $content -replace "review_result: pending", "review_result: pass"
Set-Content $yaml $content -NoNewline
```

### Verify gate

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .trae/scripts/task-guard.ps1 "2026-06-19-hermes-workflow-integration" verify
# 预期: ALL GUARDS PASSED
```

### Archive

Verify 通过后：
```powershell
$yaml = ".trae/tasks/_shared/2026-06-19-hermes-workflow-integration/.task.yaml"
$content = Get-Content $yaml -Raw
$content = $content -replace "verify_result: pending", "verify_result: pass"
$content = $content -replace "phase: review", "phase: archive"
$content = $content -replace "archived: false", "archived: true"
$content = $content -replace "verified_at: null", "verified_at: 2026-06-19"
Set-Content $yaml $content -NoNewline
```

---

## 五、关键文件引用

| 用途 | 路径 |
|:-----|:-----|
| 任务包 | `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/` |
| 任务状态 | `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/.task.yaml` |
| spec | `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/spec.md` |
| 验证报告 | `.trae/tasks/_shared/2026-06-19-hermes-workflow-integration/verification-report.md` |
| 设计文档 | `Docs/superpowers/specs/2026-06-19-hermes-workflow-integration-design.md` |
| 架构文档 | `Docs/AI/39-Hermes-Workflow-Integration.md` |
| MCP 代码 | `.trae/hermes/mcp/jinli_workflow/` |
| Planner profile | `.trae/hermes/profiles/jinli-planner/mcp.json` |
| Implementer profile | `.trae/hermes/profiles/jinli-implementer/mcp.json` |
| 测试 | `.trae/hermes/tests/`（如有） |

---

## 六、常见陷阱

1. **`review_result` 不要提前签** — 必须在新会话中独立 Review 后设置
2. **spec.md 和 verification-report.md 不要覆盖** — 始终追加，保留历史
3. **先改 .task.yaml，再跑 gate** — gate 会读取 task.yaml 的状态
4. **`task-guard verify` 通过后**才能设 `verify_result: pass`，不能提前
5. **Docs/AI/39 的 `${API_KEY}`** 一定要改为"继承主配置"，不要留下矛盾描述
6. **stdio initialize 测试** 如果无法自动化，至少要记录手动验证方式到 `verification-report.md`
