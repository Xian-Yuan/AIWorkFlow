# WP04: 验收文档 + Verify 门禁

Owner model: 金璃好帮手
Difficulty: medium
Status: pending
Depends on: WP01, WP02, WP03

## Goal
- 3 个 task packet 的 tasks.md 勾选完成
- 3 个 verification-report.md 重写（含实际命令输出）
- Review + Verify 门禁通过
- .task.yaml `archived: true`

## Steps

### T4.1: 勾选 task
对 3 个 task packet 的 tasks.md 逐项检查，已实现的项目 `[ ]` → `[x]`，未实现的项目 `[ ]` 并追加注释 `(未实现: 原因)`

### T4.2: .task.yaml 更新
3 个 task packet 各自更新:
```yaml
review_result: passed
verify_result: passed
archived: true
```

### T4.3: Verification Report 重写
每个报告包含:
1. **实际命令输出** — 不写"自我验证通过"
2. **AC 映射表** — 每条 AC 对应一个可复现的验证命令
3. **已知限制** — 如果有未修复的问题，诚实记录

示例格式:
```markdown
## AC Mapping

| AC# | Description | Status | Command & Output |
|-----|-------------|:------:|------------------|
| AC01 | 输入→输出 .mp4+.srt | ✅ | `python -m ai_drama_orchestrator --dry-run --input test.txt` → exit 0 |

## Command Evidence

### Pipeline dry-run
```
$ python -m ai_drama_orchestrator --dry-run --input test.txt --output test_out
<actual output>
```

### Test results
```
$ python -m pytest ai_drama_scriptwriter/tests/ -v
<actual output>
```
```

### T4.4: Verify 门禁
```powershell
& .\.trae\scripts\task-guard.ps1 ai-drama/2026-06-18-pipeline-architecture verify
& .\.trae\scripts\task-guard.ps1 ai-drama/2026-06-18-scriptwriter-skill verify
& .\.trae\scripts\task-guard.ps1 ai-drama/2026-06-18-viral-analyzer-skill verify
```
所有返回 exit 0。

## Verification
```powershell
# 确认 3 个 task packet 的 verify 门禁通过
# 确认 verification-report.md 包含实际命令输出（非空自检）
```
