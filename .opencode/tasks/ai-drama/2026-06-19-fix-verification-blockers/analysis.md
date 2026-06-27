# Analysis: AIDramaProducer 验收阻断修复计划

## Architecture Context

### System boundaries
AIDramaProducer 是一个 AI 工具链编排系统，覆盖从创意研究到成片的完整管线。修复范围限定在 9 个 Skill / 91 文件的已有实现，不对架构做重构。

```
修复边界:
  ┌─ 包结构 (9 个目录重命名 + __init__.py)
  ├─ Orchestrator 集成 (lambda → 真实 import)
  ├─ 4 个核心 bug 修复 (角色追踪/TTS-first/音频匹配/资产复制)
  ├─ 测试覆盖 (25+ 新测试)
  └─ 验收文档 (勾选 + verification-report)
```

### Dependency map
```
WP01 (包结构) → WP02 (bug修复) → WP03 (测试) → WP04 (验收)
                                                  └ WP05 (P1) ─ 可与 WP04 并行
```

各 WP 之间无额外共享依赖。所有修改限定在 `Project/AIDramaProducer/skills/ai_drama_*/` 目录内。

### Acceptance Criteria
见 spec.md，共 10 条 AC (AC01-AC10)，覆盖 12 条阻断消除。

### Automated Verification Plan
1. 每个 WP 完成时运行对应 pytest
2. 包结构: `python -m ai_drama_* --help` 全部 exit 0
3. 核心修复: orchestrator --dry-run + 各模块测试
4. 验收: task-guard.ps1 verify 通过

## 验收结论概要

> 来源: 金璃小天才 + 金璃好帮手 交接后的外部验收
> 结论: ❌ 不通过，不能归档

### 12 条阻断项汇总

| # | 阻断项 | 严重级别 | 涉及模块 | 根因 |
|---|--------|:--------:|---------|------|
| B01 | orchestrator 注册空处理器，7 阶段全标记成功 | **P0** | orchestrator | 实现未集成实际 Skill 调用 |
| B02 | 8 个 `python -m ai_drama_*` 入口不可发现 | **P0** | 全部 9 个 Skill | 目录名用连字符，不是合法 Python 包名 |
| B03 | Scriptwriter 测试有 2 failed | P1 | scriptwriter | 测试用例或实现有缺陷 |
| B04 | 其余 7 个 Skill 无自动化测试 | **P0** | 7 个 Skill | 实现时未编写测试 |
| B05 | 长文本角色追踪返回空数组 | **P0** | text-preprocessor | `_detect_characters` 未实现 |
| B06 | 视频生成接受 estimated 时长，未强制 TTS-first | **P0** | video-generator | 未校验 duration_source |
| B07 | 跨项目资产复用引用原文件未复制 | P1 | asset-generator | 全局库仅存 JSON entry，路径指向原项目 |
| B08 | 同角色多句对白重复使用第一段音频时长 | **P0** | compositor | `pop(0)` 只改局部变量，不修改原始列表 |
| B09 | 图片/音频/视频后端是占位字节 | P1 | 各 Generator | 模拟实现缺少真实引擎回调 |
| B10 | 任务包全部未勾选，无 worker reports | **P0** | pipeline-architecture | tasks.md 58 任务全 `[ ]` 未勾选 |
| B11 | Verify 门禁返回 BLOCKED | **P0** | 全部 3 个 task packet | review/verify 均为 pending |
| B12 | SSIM/端到端成片/同步指标无有效证据 | **P0** | verification-report | 全部自检通过，无实际命令输出 |

## 依赖链推导

### 修复优先级矩阵

```
P0（必须修复才能通过验收）
├── 包结构修复（B02）
│   ├── 9 个 Skill 目录重命名: ai-drama-* → ai_drama_*
│   └── __init__.py 添加正确导出
│
├── orchestrator 集成（B01）
│   ├── 注册真实 handler（调用各 Skill 主入口）
│   └── 不再用 lambda 空占位
│
├── text-preprocessor 角色追踪（B05）
│   └── _detect_characters 实现
│
├── video-generator TTS-first 强制（B06）
│   └── duration_source != "tts_measured" 时拒绝执行
│
├── compositor 音频时长（B08）
│   └── 修正同角色多句对白的音频 pop(0) 逻辑
│
├── 测试覆盖（B03 + B04）
│   ├── scriptwriter 修复 2 failed 测试
│   └── 7 个无测试 Skill 加基础测试
│
├── 任务包勾选（B10）
│   └── 逐项勾选，补 worker reports
│
├── Verify 门禁（B11）
│   └── 运行 task-guard.ps1 verify 直至通过
│
└── verification-report（B12）
    └── 重写，附实际命令执行输出
```

```
P1（应该修复但非强制）
├── 跨项目资产复制（B07）
├── 占位字节替换为真实回调（B09）
```

### 执行顺序

```
Step 1: 包结构修复（B02）→ 基础，所有其他修的前提
Step 2: 核心逻辑修复（B01, B05, B06, B08）→ 同时可进行
Step 3: 测试覆盖 + 修复失败测试（B03, B04）
Step 4: 任务勾选 + 验收文档（B10, B11, B12）
Step 5: P1 修复（B07, B09）
```

## Spec v.s. 实现差距分析

### Spec AC 与实际实现映射

| AC# | 描述 | Spec 要求 | 实际实现 | 差距 |
|-----|------|----------|---------|:----:|
| AC01 | 输入小说→输出 .mp4+.srt | 端到端管线 | orchestrator 不调任何 Skill | ❌ |
| AC02 | 角色一致性 SSIM > 0.85 | 骨骼绑定 + 参考图 | 占位 PNG + 骨骼数据结构空 | ❌ |
| AC03 | 分镜 JSON v2.0 Schema | Schema 校验 | schema 存在，但未在管线中校验 | ⚠️ |
| AC04 | 断点续传 | 恢复已完成的阶段 | PipelineState 类实现正确，但 handler 为空 | ❌ |
| AC05 | 单镜头失败重试 | 失败自动重试 | retry 循环实现正确，但 handler 为空 | ❌ |
| AC06 | 工具后端可替换 | 多引擎抽象 | 各 Generator 支持回调注入，但无真实引擎 | ⚠️ |
| AC07 | 视频时长偏差 < 5% | TTS-first 实测时长 | TTS 有 _measure_duration，但 video 不强制 | ❌ |
| AC08 | 字幕与对白一致 | SRT 时间轴基于 TTS 时长 | SRT 生成逻辑实现但有 bug | ❌ |
| AC09 | 音画同步 < 200ms | TTS 先测量→视频用实测值 | TTS 测量实现，video 不强制使用 | ❌ |
| AC10 | 长文本章节事件图谱 | >5000 字触发 | detect_chapters 实现，但角色追踪为空 | ❌ |
| AC11 | 跨项目资产复用 | 全局库 | JSON entry 路径指向原项目不复制文件 | ⚠️ |
| AC12 | 爆款分析注入 | 可选 Phase 0 → scriptwriter | 独立 skill 实现，但 orchestrator 未集成 | ❌ |

**结论**: 6/12 AC 完全未满足，3/12 部分实现但有 bug，仅 3/12 正确实现但未集成到管线

## 现有实现库存

| Skill | 文件数 | 核心文件 | 测试 | 状态 |
|-------|:------:|---------|:----:|:----:|
| ai-drama-scriptwriter | 41 | scriptwriter.py, modules/*, validators/*, rules/*, schemas/* | ✅ 19 tests | **最完整**，2 failed |
| ai-drama-viral-analyzer | 29 | viral_analyzer.py, modules/*/*.py, knowledge/* | ✅ 20 tests | **较完整**，全 pass |
| ai-drama-orchestrator | 3 | orchestrator.py | ❌ 无 | 空壳 |
| ai-drama-text-preprocessor | 3 | text_preprocessor.py | ❌ 无 | 核心逻辑不完整 |
| ai-drama-asset-generator | 3 | asset_generator.py | ❌ 无 | 基础实现 |
| ai-drama-keyframe-generator | 3 | keyframe_generator.py | ❌ 无 | 基础实现 |
| ai-drama-tts-generator | 3 | tts_generator.py | ❌ 无 | 相对完整(有 ffprobe) |
| ai-drama-video-generator | 3 | video_generator.py | ❌ 无 | 基础实现 |
| ai-drama-compositor | 3 | compositor.py | ❌ 无 | 基础实现有 bug |

## Mature Solution Evidence

### Project-local evidence
- `skills/ai_drama_scriptwriter/` — 已有 41 文件 + 19 tests（最完整的 Skill，可复用其模块结构）
- `skills/ai_drama_viral_analyzer/` — 已有 29 文件 + 20 tests（测试风格可参考）

### Official/framework evidence
- Python 包规范: PEP 8 / PEP 423 — 包名必须用下划线，不能用连字符
- pytest 测试框架 — 项目中已有使用

### Options compared
| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|:----:|
| 重命名目录为下划线 | 符合 Python 规范 | 影响 git 历史 | ✅ 采用 |
| 仅改 __init__.py 不重命名目录 | 改动小 | `-m` 仍不可用 | ❌ 拒绝 |
| 重写 orchestrator 架构 | 更干净 | 工作量大 | ❌ 拒绝 |
| 基于现有代码修补 | 最小改动 | 代码不完美 | ✅ 采用 |
| 角色追踪用 LLM | 准确 | 成本高、依赖外部 | ❌ 拒绝 |
| 角色追踪用正则匹配 | 轻量 | 精度有限 | ✅ 采用 |

### Rejected shortcuts
- 保留连字符目录名仅改 `__init__.py` — Python `-m` 仍不可用
- orchestrator 继续用空 handler 等"以后集成" — 管线永远跑不通
- 角色追踪用 LLM 调用 — 不需要，成本高
- 不复制文件用符号链接 — Windows 兼容性问题
- 重写所有模块 — 重复造轮子

### Selected mature path
基于现有 91 文件做最小修补，不重构架构。具体:
1. 包名下划线化（符合 PEP 8）
2. Orchestrator import 各 Skill（标准 Python 集成模式）
3. 角色追踪用轻量文本匹配（避免引入大模型依赖）
4. 合约式 TTS-first（ValueError 阻断，清晰的契约边界）
5. pytest 测试覆盖（复用项目中已有的测试模式）

### 方案选择

| 特性 | 当前实现 | 修复方案 | 理由 |
|------|---------|---------|------|
| 包结构 | `ai-drama-*` 连字符目录 | `ai_drama_*` 下划线目录 + 正确的 `__init__.py` | Python 包规范要求 |
| Orchestrator 集成 | lambda 空占位 | `import ai_drama_<skill>.<module> as skill_x` 方式直接调用 | 最小改动，不做重架构 |
| 角色追踪 | return [] | 基于 char_ids 做文本中角色名匹配 | 文本预处理阶段不需要大模型，字符匹配即可 |
| TTS-first 强制 | 不校验 source | `duration_source != "tts_measured"` → raise ValueError | 合约式设计 |
| 音频 pop 逻辑 | `pop()` 只改局部 | 改用 `del audio_by_shot[sid][idx]` 或迭代器 | 从源头移除已使用的音频 |
| 全局资产复制 | 仅存 JSON 路径 | `shutil.copy2()` 复制文件到项目目录 | 确保项目自包含 |
| 测试覆盖 | 仅 2/9 Skill | 每个 Skill 至少 1 个基础集成测试 | 最低测试门槛 |

### 拒绝的捷径

| 捷径 | 风险 | 替代方案 |
|------|------|---------|
| 保留连字符目录名，仅改 __init__.py | Python -m 仍不可用 | 必须重命名目录 |
| orchestrator 继续用空 handler 等"以后集成" | 管线永远跑不通 | 直接 import 各 Skill 注册真实 handler |
| 角色追踪用 LLM 调用（text-preprocessor 阶段） | 不需要，成本高 | 正则+角色名匹配 |
| 不复制文件，用符号链接 | Windows 兼容性问题 | `shutil.copy2` |
| 重写所有模块 | 工作量大，重复造轮子 | 基于现有实现修补，不重构 |

## 隐性需求

| 用户说了 | 但必然需要 | 优先级 |
|---------|-----------|:------:|
| 修复 orchestrator | 各 Skill 需要能被 orchetrator import — 包结构必须先修 | P0 |
| 修测试 | 需要安装依赖（pip install -r requirements.txt），确认环境 | P1 |
| 验收通过 | 需要执行 `task-guard.ps1 verify` 并记录输出 | P0 |
| 通过验证门禁 | `.task.yaml` 的 review_result/verify_result 需要从 pending → passed | P0 |
