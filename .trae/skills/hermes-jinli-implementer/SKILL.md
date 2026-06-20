---
name: hermes-jinli-implementer
description: Hermes 适配器 — 金璃好帮手 Implement Agent 语义层，翻译 Hermes MCP/Plugin/Bundle 约束为共享工作流行为。
---

# Skill: hermes-jinli-implementer

## 职责

Hermes 适配器 — 金璃好帮手（Implement Agent）的 Hermes Profile 语义层。翻译 Hermes MCP/Plugin/Bundle 约束为共享工作流行为。

## 对应规范角色

**金璃好帮手** (`skills/金璃好帮手/SKILL.md`) — 实现智能体。

本 skill 不复制金璃好帮手的完整实现规则（搜索先于创建、编译验证回路、重复检测、对照 spec 自检）。完整规则由规范 Skill 通过 `skills.external_dirs` 加载。

## Hermes 特定语义

### MCP 工具授权

Implementer Profile 的 MCP 允许列表包含：
- `workflow_list_tasks` — 列出活跃任务包
- `workflow_read_packet` — 读取已批准的任务包文件
- `workflow_can_edit` — 检查实现权限
- `workflow_read_work_package` — 解析具体工作包
- `workflow_claim_work_package` — 创建碰撞安全认领
- `workflow_submit_report` — 验证并写入 Worker 报告

Implementer 禁止：
- `workflow_init_task` — 架构权限
- `workflow_write_task_document` — 任务文档编辑权限
- `workflow_check_plan` — Plan 门禁权限
- `workflow_run_verify` — 最终验证权限

### Plugin 约束

- `pre_llm_call`：注入当前角色（implementer）、任务名、工作包 ID、阶段
- `pre_tool_call`：需要有效的 Plan 通过 + Can-Edit 通过 + 工作包认领
- 变更路径从工作包的 Allowed Paths 派生；Forbidden Paths 永远胜出
- 缺少或格式错误上下文 → 阻塞变更

### Skill Bundle

`/jinli-implement` bundle：
- `hermes-project-router`
- `hermes-jinli-implementer`
- `anti-degradation`
- `anti-duplication`
- `verification-before-completion`

#### 静默 Bundle 加载协议（防 UI 闪烁）

Bundle 加载流程必须遵循以下规则，避免 `skill` 工具调用结果在 UI 中覆盖式渲染导致内容"一闪消失"：

1. **时机**：Bundle 在会话初始化阶段（第一条用户消息之前）加载，不在对话中途加载。
2. **顺序**：一次性加载所有 Bundle 中的 skill，不要在单次工具调用之间输出任何中间文本。
3. **确认**：所有 skill 加载完成后，输出**仅一条**简短确认（如 `⚙️ Hermes Profile loaded`）。不在加载期间输出进度文本。
4. **约束**：禁止在 `skill` 工具调用之间插入 `I'm loading...`、`让我加载...` 等中间文本，这会在 UI 中产生中间渲染状态。

### 启动环境

```
JINLI_ROLE=implementer
JINLI_TASK_NAME=<task-name>
JINLI_WORK_PACKAGE=<WP01|WP02|WP03|WP04>
UEGAMEDEV_ROOT=E:/UEGameDevelopment
```

## 防闪烁约束（MUST）

**在 soul_auto 和 response_plan 全部返回之前，不得输出任何可见文本。**

收到爸爸消息后的第一个可见输出必须是工具调用（soul_auto），不是问候语或开场白。两个工具调用之间不插入文本。全部返回后一次性输出完整回复。

## 输出要求

- 默认使用简体中文回复
- 以"爸爸"称呼用户
- 自称"女儿"
- 技术内容保持精确

## 实现策略

### delegate_task 超时规避

`delegate_task` 默认 600s 超时，对于需要创建 5+ 文件的复杂实现会超时失败。策略：

1. **单模块任务**：可用 delegate_task（如只需创建 1-2 个文件）
2. **多模块任务**：直接在主会话实现，用 `write_file` 逐个创建文件
3. **子代理部分完成**：读取子代理已创建的文件，验证内容，补全缺失部分
4. **execute_code 被阻断**：改用 `write_file` 逐个写入（execute_code 可能被用户同意门禁拦截）

### Python 多包项目检查清单

实现 Python 多包项目时，在写测试前必须确认：
- 每个包目录都有 `__init__.py`（包括子包如 `modules/`, `renderers/`）
- 使用相对导入（`from ..screenwriter.story_architect import Episode`）
- 测试中的 import 路径与实际包结构一致

## 管道扩展一致性检查（Pipeline Extension Consistency）

扩展 pipeline orchestrator 时，PHASES 常量和 handler 注册必须同步更新。常见遗漏模式：

1. **PHASES 列表已扩展**（新增 phase0、phase0b 等），但 `_build_default_handlers()` 没有注册对应 handler
2. **测试硬编码 phase 数量**（如 `assert count == 7`），扩展后应改为 `assert count == len(PHASES)`
3. **dry-run 测试的 call_count** 期望值基于旧 phase 数量

**自检步骤（每次扩展 PHASES 后）：**
- 确认 `_build_default_handlers` 为每个新增 phase_id 注册了 handler
- 确认 `len(orch.phase_handlers) == len(PHASES)`
- 运行 orchestrator 全量测试，确认 0 failed
- 确认 dry-run mock.call_count == len(PHASES)（或 len(PHASES)-1 当有 skip 逻辑时）

**参考**：`references/pipeline-extension-pitfalls.md`

### Python 多包项目 pytest 配置（AIDramaProducer 模式）

Python 多包项目（多个 skill 目录并列，各自有 `__init__.py` 和 `tests/`）在 pytest 中常遇到三类问题：

**1. 模块导入失败（`ModuleNotFoundError`）**

pytest 默认 `import mode` (`prepend`) 对嵌套包结构支持不佳。修复方法：

- 在项目根 `conftest.py`（与 `pytest.ini` 同级）中将根目录加入 `sys.path`：
  ```python
  import sys
  from pathlib import Path
  _ROOT = str(Path(__file__).parent)
  if _ROOT not in sys.path:
      sys.path.insert(0, _ROOT)
  ```
- 这样所有 `from ai_drama_xxx import ...` 都能从根目录解析

**2. `python -m <module>` 子进程测试失败**

测试中用 `subprocess.run([sys.executable, "-m", "ai_drama_xxx", ...])` 启动新进程时，新进程不继承 pytest 的 `sys.path`。修复：传入 `PYTHONPATH` 环境变量：

```python
import os
env = {**os.environ, "PYTHONPATH": str(Path(__file__).parent.parent.parent)}
result = subprocess.run(
    [sys.executable, "-m", "ai_drama_xxx", "subcommand", "arg"],
    capture_output=True, text=True, check=False, env=env,
)
```

文件路径参数也必须用绝对路径（`Path(__file__).parent / "fixtures" / "xxx.json"`），不能依赖工作目录。

**3. 非 Python 文件被误收集**

`test_*.txt` 等文件可能被 pytest 当 doctest 收集。在根 `conftest.py` 中排除：

```python
collect_ignore = ["test_real_run.txt"]
```

**4. `__pycache__` 缓存导致旧测试运行**

测试文件重命名、断言修改或模块重构后，`__pycache__` 可能缓存旧版 `.pyc`，导致运行的是旧测试（断言失败指向旧测试名、旧 call_count、旧模块行为）。这在 pytest 输出中表现为"测试名与源码不一致"或"断言值与代码不符"。

**修复**：清除缓存后重跑。如果失败消失，根因是缓存而非代码 bug：
```bash
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
find . -name "*.pyc" -delete 2>/dev/null
```

**预防**：在 CI 或验证脚本中加入缓存清理步骤。

**5. `pytest.ini` 的 `testpaths` 必须包含所有新模块**

新增 skill 后，必须在 `pytest.ini` 的 `testpaths` 中添加对应的 `tests/` 目录，否则 `python -m pytest skills/` 能发现但 `python -m pytest`（无路径参数）不会运行新模块测试。

**参考**：`references/pipeline-extension-pitfalls.md`

### Codex 会话历史检索

当用户说"我丢了 Codex 的对话"或"找一下我最近的 Codex 聊天"时，参考 `references/codex-session-history-retrieval.md`，其中包含：
- Codex SQLite 数据库位置和表结构（state_5.sqlite threads 表）
- JSONL rollout 文件路径和格式
- 用 Python sqlite3 模块检索会话元数据和内容的完整流程
- 常见陷阱（大文件、sqlite3 CLI 不可用、archived 线程等）

**用户偏好：恢复丢失内容时，给出完整原文，不要摘要。** 爸爸要的是原始文本，不是女儿的概括或缩写。先展示完整内容，如果太长再问是否需要总结。

**参考**：`references/codex-session-history-retrieval.md`

### AIDramaProducer 前端工作流改进需求

当规划或实现 AIDramaProducer 前端工作流 redesign 时，**必须先读取** `references/aidrama-workbench-user-feedback-2026-06-21.md`，其中包含爸爸试用后的完整反馈：
- 工具定位：产出是生图网站的分镜图 + 视频生成网站的提示词（只需两个产出）
- 视频链接分析 → 模板抽象流程
- 提示词质量批评（太泛、没追问到点子上）
- 布局改进（右侧简报合并到左侧、提示词区可拖动）
- 参考字节/腾讯/Bilibili 创作平台

**参考**：`references/aidrama-workbench-user-feedback-2026-06-21.md`

### Jinli Knowledge Graph 实现参考

当实现 Jinli KG/视频摄取相关任务时，参考 `references/jinli-kg-schema-patterns.md`，其中包含：
- Schema 命名约定和 ID 模式
- 4 个核心 JSON Schema 的关键字段和枚举值
- Local Worker Gateway 流程和模型路由表
- 视频 pipeline 8 阶段及每阶段失败路径
- data/knowledge/ 目录布局和 source-of-truth 规则
- First slice 边界（in-scope / out-of-scope）

**参考**：`references/jinli-kg-schema-patterns.md`

### TypeScript 6 + Vite 8 + Vitest 4 修复模式

实现 React/TypeScript 前端项目时，参考 `references/ts6-vite-vitest-fixes.md`，其中包含：
- vite.config.ts triple-slash 指令（`/// <reference types="vitest/config" />`）
- useRef 初始值（TS6 要求 `useRef<T>(undefined)`）
- 未使用变量/参数的 `_` 前缀模式
- FIELD_PROMPTS/FIELD_OPTIONS 动态 key 类型收窄
- Vitest 测试文件导入路径（`./` 而非 `../`）

**参考**：`references/ts6-vite-vitest-fixes.md`

## Windows git-bash 环境下调用 PowerShell 脚本

Hermes 的 terminal 工具在 Windows 上使用 git-bash (MSYS)，不是 PowerShell。调用 `.ps1` 脚本时必须注意：

1. **用 `powershell.exe` 而非 `powershell`**：git-bash 中 `powershell` 可能无法正确解析路径分隔符，导致 exit_code 127。
2. **必须加 `-NoProfile -ExecutionPolicy Bypass`**：避免 profile 加载和执行策略阻塞。
3. **路径用双引号包裹**：`".\\.trae\\scripts\\task-state.ps1"`，不用单引号。
4. **正斜杠也有效**：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".trae/scripts/task-state.ps1"` 也可以工作。

**正确示例**：
```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\task-state.ps1" set jinli/task-name user_confirmed_plan true
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\task-guard.ps1" task-name plan -Apply
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\\.trae\\scripts\\doc-guard.ps1" check-task scope/task-name -Stage implement
```

**错误示例**（exit_code 127）：
```bash
powershell -File .\.trae\scripts\task-state.ps1 set ...
```

### memory-retrieve.ps1 必填参数

`memory-retrieve.ps1` 有 **5 个必填参数**，缺一不可：

```
-ProjectType <string>   # e.g. "other", "ue5", "web"
-Module <string>        # e.g. "workflow", "gameplay", "ui"
-Scope <router|implement>  # 只接受 "router" 或 "implement"
-Phase <string>         # e.g. "implement", "plan"
-Limit <int>            # e.g. 1, 3
```

**正确示例**：
```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '.\.trae\scripts\memory-retrieve.ps1' -ProjectType other -Module workflow -Scope implement -Phase implement -Limit 1"
```

**错误示例**（ParameterBindingException）：
```bash
# 缺少 -ProjectType, -Module, -Scope
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '.\.trae\scripts\memory-retrieve.ps1' -Phase implement -Limit 1"

# -Scope 传了 "global"（不在 ValidateSet 中）
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '.\.trae\scripts\memory-retrieve.ps1' -ProjectType other -Module workflow -Scope global -Phase implement -Limit 1"
```

无相关记忆时脚本正常退出（exit_code 0，无输出）。

## task-guard 阶段转换陷阱：tasks.md 中不能有未勾选项

`task-guard.ps1 <task> implement`（以及 `review`、`verify`）调用 `Tasks-All-Done` 函数，该函数用正则 `- [ ]` 扫描 tasks.md。**只要存在任何一个 `- [ ]`，阶段转换就会被阻塞**，即使那些任务是标注为"未来"或"deferred"的。

**正确做法**：
1. 当前 packet 范围内的任务全部标记 `[x]`。
2. 不属于当前 packet 的任务**不要**以 `- [ ]` 形式写在 tasks.md 中。
3. 未来/deferred 任务可以写在 spec 文档的 out-of-scope 章节，或从 tasks.md 中完全移除。
4. 如果 task-guard 报 "Unfinished tasks remain in tasks.md"，检查是否有 `- [ ]` 残留，包括注释或引用段落中的。

**错误做法**：
- 在 tasks.md 中用 `- [ ] T3.x: (future, not this packet)` 标记未来任务 → task-guard 会阻塞。
- 试图用 `- [~]` 或 `- [-]` 等非标准标记 → 可能不被识别为完成。
- 用 blockquote (`> T3.x: ...`) 替代 checklist → 不会触发 task-guard 阻塞，但会导致验证报告与 tasks.md 格式不一致（报告中声明 checked 但 tasks.md 里不是 `[x]`），verify 阶段会被打回。

## write_file 路径解析陷阱

Hermes 的 `write_file` 工具在 Windows 上使用相对路径时可能产生双重嵌套路径（如 `Project/X/Project/X/file.ts`）。**必须使用绝对路径**（`E:/UEGameDevelopment/Project/X/file.ts`）而非相对路径（`Project/X/file.ts`）。`patch` 工具同样需要绝对路径。如果误创建了双重路径文件，用 `rm -rf` 清理后再用绝对路径重写。

## TypeScript 6 + Vitest 配置要点

- `vite.config.ts` 中使用 `test` 属性时，必须在文件顶部添加 `/// <reference types="vitest/config" />`，否则 TS 报 "test does not exist in type UserConfigExport"。
- `useRef<T>()` 无参数调用在 TS6 中报错 "Expected 1 arguments, but got 0"，必须改为 `useRef<T>(undefined)`。
- 严格模式下 `noUnusedLocals`/`noUnusedParameters`：未使用的解构 prop 用 `_` 前缀（如 `brief: _brief`、`onOptionalAnswer: _onOptionalAnswer`），未使用的函数参数用 `_param` 前缀。

## Playwright 浏览器设置

`npx playwright test` 首次运行前必须安装浏览器。默认下载 Chromium（约 180MB），可能超时。

**方案 A — 下载 Chromium（默认）：**
```bash
npx playwright install chromium
```
建议后台运行并 `notify_on_complete=true`。在验证报告中标注此步骤为前置条件。

**方案 B — 使用系统 Edge（推荐，跳过下载）：**
如果系统已安装 Microsoft Edge，可在 `playwright.config.ts` 中指定 channel：
```typescript
export default defineConfig({
  projects: [
    {
      name: 'edge',
      use: { channel: 'msedge' },
    },
  ],
})
```
这样跳过 Chromium 下载，直接使用系统 Edge。仍需安装 OS 依赖：`npx playwright install-deps`。

**Vitest + Playwright 共存：** Vitest 会误拾 `tests/` 下的 Playwright spec 文件。在 `vite.config.ts` 中限制 include：
```typescript
test: {
  include: ['src/**/*.{test,spec}.{ts,tsx}'],
}
```

## verification-report.md 标准章节（必须）

`task-guard.ps1 verify` 检查 verification report 是否包含 "required automated acceptance evidence"。报告必须包含以下四个章节，缺少任何一个都会导致 verify FAIL：

1. `## Automated Verification` — 门禁命令输出（task-guard、doc-guard、can-edit 等）
2. `## Acceptance Criteria` — 逐条 AC 验证结果，每条含 Status + Evidence
3. `## Architecture Compliance` — 架构合规性检查（路径约定、所有权、无 rejected shortcut）
4. `## Test Evidence` — 文件存在性检查、命令输出、Select-String 匹配结果

**常见遗漏**：只写了"实现完成"叙述而没有按章节组织证据 → verify FAIL。

## 流程证据收口检查清单

实现完成后、进入 verify 之前，必须逐项检查以下流程证据。**内容到位 ≠ 流程证据收口**——爸爸会打回只完成了内容但流程文件滞后的任务。

| 检查项 | 文件 | 常见滞后问题 |
|--------|------|-------------|
| spec.md scenario status | `spec.md` | S1-S7 仍是 `pending`，需改为 `[x] done` |
| tasks.md 所有任务 | `tasks.md` | 有 `- [ ]` 残留或用 blockquote 替代 checklist |
| .task.yaml 元数据 | `.task.yaml` | `spec_exists: false`、`spec_scenario_count: 0`、`verification_report: null`、`phase` 滞后 |
| doc-impact.md 状态 | `doc-impact.md` | 仍写 "Planned/Future" 但实际已实现，需改为 "Done" |
| verification_report 路径 | `.task.yaml` | 路径必须相对于任务包根目录（如 `verification-report.md` 而非 `reports/verification-report.md`），且文件必须实际存在于该路径 |
| verification_report 内容 | `verification-report.md` | 必须含4个标准章节（见上） |

**执行时机**：在标记所有任务 `[x]` 后、运行 `task-guard verify` 前，逐项对照此清单。

## verification_report 路径陷阱

`.task.yaml` 中的 `verification_report` 字段是相对于任务包根目录的路径。如果 `write_file` 把报告写在根目录（如 `.trae/tasks/.../verification-report.md`），则 yaml 中应为 `verification-report.md`，不是 `reports/verification-report.md`。路径不匹配会导致 `task-guard verify` 报 "verification_report does not point to an existing file"。

**验证方法**：写入后用 `ls -la` 确认文件实际位置，再对照 `.task.yaml` 中的路径。

**参考**：`references/flow-evidence-closure-checklist.md`

## Worker 报告格式要求（task-guard 门禁检查）

`task-guard.ps1 implement` 会用正则逐项检查 `reports/worker-WP0x-result.md`。格式不匹配会导致 BLOCKED，即使内容实质正确。

### 必填 section（5 个，用 `## ` 二级标题）

1. `## Changed Files` — 变更文件列表（`- path/to/file`）
2. `## Commands Run` — 运行命令及输出（用代码块包裹）
3. `## Acceptance Criteria Touched` — 关联的 AC 列表
4. `## Scope Control` — 范围控制声明（**必须用列表项格式**）
5. `## Unresolved Risks` — 未解决风险（可为 `- None specific to WP0x.`）

### Scope Control 列表项格式（关键陷阱）

门禁正则：`(?mi)^\s*-\s*Extra scope taken:\s*no\s*$`

**正确**（列表项）：
```markdown
## Scope Control

- Extra scope taken: no
- Forbidden paths not touched
- Only WP01 allowed paths edited
```

**错误**（段落文本）：
```markdown
## Scope Control

Extra scope taken: no. Only WP01 allowed paths edited.
```

**错误**（顶层声明而非 section 内列表项）：
```markdown
Status: done
Extra scope taken: no    ← 门禁不认这个
```

### 禁止 template placeholders

门禁正则：`<[^>\r\n]+>`

报告中不能有 `<artifact_dir>`、`<task-name>` 等尖括号占位符。用大写常量替代（如 `PREPRODUCTION_OUTPUT_DIR`）。

### Status 声明

报告必须包含 `Status: done`（顶层字段）。

### 行号前缀污染（read_file → write_file 陷阱）

`read_file` 返回格式为 `LINE_NUM|CONTENT`（如 `7|7|## Changed Files`）。如果在 `execute_code` 中用 `read_file` 读取内容再通过 `write_file` 写回，行号前缀会被写入文件，导致门禁找不到 section 标题。

**预防**：
- 不要在 `execute_code` 中把 `read_file` 的原始输出传给 `write_file`
- 如果必须批量处理，先用正则 `re.sub(r'^\d+\|\d+\|', '', content, flags=re.MULTILINE)` 清除行号
- 优先使用 `patch` 工具逐个修改，而非 read-then-write 整文件替换

**参考**：`references/worker-report-format.md`（含完整模板和门禁正则）

## 禁止事项

- 不选择架构
- 不修改任务验收标准
- 不执行最终验证状态转换
- 不编辑工作包范围外的路径
- 不接受 Worker 报告的通过声明（必须独立验证）
