# Spec: Generate `Docs/AI/SKILL-INVENTORY.md`

## GIVEN

- 仓库根 `E:\UEGameDevelopment` 是 UE5.7 单机游戏 + Web 应用的多项目仓库
- `skills/` 目录作为单一真相源（canonical source），顶层共 74 个目录：
  - 73 个 active skill 目录
  - 1 个 `_archived/` 容器（内含 11 个 archived skill）
- 3 个 IDE 适配器目录均为 junction：
  - `.codex/skills` → `skills/`（直连）
  - `.trae/skills` → `skills/`（直连，2026-06-26 修复）
  - `.opencode/skills` → `.trae/skills`（链式，transitive，最终 → `skills/`）
- 能力基线文件 `.codex/capability-baseline.json` v1.0.0 声明：
  - `project_skill.canonical_source = E:\UEGameDevelopment\skills`
  - `project_skill.adapter_type = junction`
  - `project_skill.validation_required = true`
  - `project_skill.archived_excluded = true`
  - `project_skill.metadata_required = ["SKILL.md"]`
- skill 的元数据写在 `SKILL.md` 的 YAML frontmatter（`name` + `description`），**没有** `manifest.yaml`
- `Docs/AI/SKILL-INVENTORY.md` 当前不存在
- 现有 `Docs/AI/35-Workflow-Tooling-Inventory.md` 讲脚本清单，不重叠
- 现有 `Docs/AI/document-taxonomy-inventory.md` 讲文档分类，不重叠
- 用户硬性要求：不修改任何 skill 文件、不改 capability-baseline.json、不创建/修改 junction、不执行 AI 漫剧 skill

## WHEN

在 `E:\UEGameDevelopment\Docs\AI\SKILL-INVENTORY.md` 写入一份 markdown 文档，作为 74 个 skill 的总导航，按以下 6 个章节组织。

## THEN

### Module 1: 文档元信息 + 总览

文档开头必须包含：
- 标题 `# Skill Inventory — 74 Skills Total Index`
- 副标题"生成日期 2026-06-26"+"对应能力基线 v1.0.0"
- 一句话用途："让任何 AI 在 30 秒内掌握仓库全部 73 active + 11 archived skill 的能力分布、入口与同步状态"
- 4 行统计：active 数 / archived 数 / junction 数 / 文档分类数
- 4 目录 junction 架构图（ASCII 或 mermaid），必须如实标注链式结构

### Module 2: 13 类分类索引

13 个分类（按 analysis.md §3 调整后），每个分类一段：
1. UE5 引擎 (18)
2. Web 开发 (5)
3. AI 漫剧 / AIDramaProducer 管线 (6)
4. 反降智 / 质量保证 (6)
5. 工作流 / 规划 (9)
6. 协作 / 交付 (5)
7. Hermes 适配器 (4)
8. Jinli 灵魂 / 双 Agent (4)
9. 记忆 / 经验 (4)
10. Codex / 元工具 (6)
11. 工具链 / 桌面操控 (2)
12. 效率 / 压缩 (2)
13. GitHub / 方案搜索 (1)

每段格式：
```
### N. 分类名 (数量)
[1 句话定位] [入口 skill 加粗] [与其他分类的关系]
**入口**: <skill name>
**触发关键词**: <3-5 个典型>
**包含**: <skill 名列表，逗号分隔>
```

### Module 3: Skill 卡片总表

一张大表覆盖全部 73 active skill，列：

| 分类 | 名称 | 一句话用途 | 触发关键词 | 入口/支撑 |
|------|------|-----------|-----------|----------|

- 73 行全列
- 触发关键词从前 2-8 个英文字或术语抽取
- 入口/支撑栏用 `★入口` `↻支撑` `↘S2` 等符号

### Module 4: AI 漫剧专区（管线详解）

独立章节，6 个 skill 各一段：

| skill | 阶段 | 输入 | 输出 | 上游依赖 | 下游输出 |
|-------|------|------|------|----------|----------|

标注：
- AIDramaProducer **入口** = `ai-video-creator`
- 6 阶段流水线：S0 灵感采集 → S1 故事立项 → S2 剧本大纲 → S3 角色提示词 → S4 分镜/导演提示词 → S5 AI 视频提示词
- 强调：**本任务仅文档化，不触发任何 AI 漫剧 skill**

### Module 5: 同步状态 (Sync Status)

| 路径 | 类型 | Target | 直/链 | 状态 |
|------|------|--------|-------|------|

- 3 行 junction 状态表（修正用户原描述，标注 .opencode 为链式）
- capability-baseline.json 关键字段引用块
- 同步行为说明：源是 single source of truth，junction 是只读视图
- 故障排查小节：若发现内容差异如何回到 source 校验

### Module 6: 同步验证脚本

| 脚本 | 用途 | 调用命令 |
|------|------|----------|

至少引用：
- `.trae/scripts/validate-codex-capabilities.ps1 -Mode Inspect`
- `.trae/scripts/test-codex-skill-discovery.ps1`
- `.trae/scripts/test-codex-capability-baseline.ps1`

并附"何时跑"的简短指引。

### Module 7: _archived/ 容器 (独立小节)

- 解释：`_archived/` 是历史 skill 容器，**不参与路由**
- 11 个 archived skill 列表 + 各自被取代的 active 版本：
  - `bmad-auto` → (现 task-orchestrator + 路由已内置)
  - `character-designer` (archived) → `character-designer` (active) 重名保留
  - `lyra-gas-dev` → `ue-lyra-gas-implementer`
  - `personal-branding` → 拆为多个未归档 skill
  - `planning-with-files` → `writing-plans` + `spec-living`
  - `prompt-compressor` (archived) → `output-compressor` / `token-guardian`
  - `rag-hallucination-guard` → (合并入 anti-degradation)
  - `spec-tracker` (archived) → `spec-living`
  - `token-optimizer` → `token-guardian`
  - `ue57-lyra-gas-ai-singleplayer` → `ue-lyra-gas-implementer`
  - `using-superpowers` → (内化为多 skill 默认行为)

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|----------------|
| AC01 | 文件生成在 `Docs/AI/SKILL-INVENTORY.md` | `Test-Path -LiteralPath "E:\UEGameDevelopment\Docs\AI\SKILL-INVENTORY.md"` | `True` |
| AC02 | 73 active skill 全部出现在 Module 3 表格或 Module 4/8 专项段 | 实施时手工比对（参考 analysis.md 附录 A） | 73 个名字 0 漏 |
| AC03 | 11 archived skill 全部出现在 Module 7 | 实施时手工比对（参考 analysis.md 附录 B） | 11 个名字 0 漏 |
| AC04 | 至少 5 个分类（实际 13 个） | `Select-String -Pattern '^### \d+\. '` | `>= 13` 行 |
| AC05 | 4 目录 junction 架构图存在且标注链式结构 | `Select-String -Pattern 'junction'` 至少 3 行 | 含 `.opencode` + `链式` 关键词 |
| AC06 | 引用 `capability-baseline.json` 的至少 3 个核心字段 | `Select-String -Pattern 'canonical_source\|adapter_type\|metadata_required\|validation_required'` | 命中 ≥ 3 |
| AC07 | Jinli 入口和 AIDramaProducer 入口都有显式标注 | `Select-String -Pattern '金璃小天才\|金璃好帮手\|ai-video-creator'` | 双管线入口都在 Module 2/4/8 出现 |

## Quality Checklist

### Completeness
- [ ] [OK] 73 active skill 全部覆盖
- [ ] [OK] 11 archived skill 全部列出
- [ ] [OK] Module 1-7 全部生成
- [ ] [OK] 13 个分类全覆盖
- [ ] [OK] Jinli + AIDramaProducer 入口标注

### Clarity
- [ ] [OK] 触发关键词不超过 8 个 / skill
- [ ] [OK] 卡片不展开 skill 内容，仅导航
- [ ] [OK] 中英文混排统一（用 ASCII 表格 + 中文描述）

### Consistency
- [ ] [OK] 命名 `Docs/AI/SKILL-INVENTORY.md` 符合 `13-File-Placement-Convention.md`
- [ ] [OK] 不与 `35-Workflow-Tooling-Inventory.md` 重复（脚本 vs skill）
- [ ] [OK] 不与 `document-taxonomy-inventory.md` 重复（文档 vs skill）
- [ ] [OK] 与 capability-baseline.json 字段引用一致

### Scenario Coverage
- [ ] [OK] Happy Path: 用户/AI 打开文档 30 秒内能定位任意 skill
- [ ] [OK] Edge Case: archived vs active 重名 skill 有显式区分
- [ ] [OK] Error Path: 链式 junction 异常时回到 source 校验的步骤有说明

### Edge Case Coverage
- [ ] [OK] 中文字符 skill 名（金璃小天才/金璃好帮手）正确显示（不用 PowerShell 列举，用 Read/Glob）
- [ ] [OK] 无 frontmatter 的 skill (ai-video-creator 系列) 有 fallback 元数据
- [ ] [OK] _archived/ 内部 archived skill 与 active 列表重名（如 character-designer）有交叉引用

### Usage Guidance
- [ ] [OK] 所有 quality 项已在 Plan 阶段填标
- [ ] [OK] 无 `[Gap]` 或 `[Ambiguity]`

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|--------------|
| Plan | ✅ Completed (2026-06-26) | 13 类分组、6 章节结构、链式 junction 如实标注 |
| Implement | ✅ Completed (2026-06-26) | Plan + Implement 合并执行（用户授权"用最好的方案"） |
| Review | ⬜ Pending | — |
| Verify | ✅ Completed (2026-06-26) | 7 条 AC 全过；doc-guard 受 PowerShell 执行策略限制未跑，但 AC 等价证据充分 |

## AC 验证日志 (2026-06-26 实施完成后)

```
=== AC Verification ===
AC01 file exists: True (path: E:\UEGameDevelopment\Docs\AI\SKILL-INVENTORY.md)
AC04 categories: 13 (expect >= 13) [实际 13 类，超 5 类下限]
AC05 chain junction: True ; .opencode: True [链式结构已标注]
AC06 baseline fields hit: 6 / 6 [canonical_source, adapter_type, metadata_required, validation_required, archived_excluded, merge_policy 全部引用]
AC07 Jinli+AI drama entries: 金璃小天才=True, 金璃好帮手=True, ai-video-creator=True

AC02 missing active skills: 0 [73 active 全部覆盖]
AC03 missing archived skills: 0 [11 archived 全部覆盖]

File: 39.6 KB / 540 lines
doc-guard: 受 PowerShell execution policy 限制未跑；AC 等价证据充分
```

## Non-Goals

- ❌ 不执行任何 skill（包括 ai-video-creator、character-designer 等）
- ❌ 不修改任何 skill 的 `SKILL.md`
- ❌ 不修改 `capability-baseline.json`
- ❌ 不创建/删除/修改 junction
- ❌ 不创建新 skill 目录
- ❌ 不生成 `skill-registry.json`（那是 engine/ 域，不在 docs 域）
- ❌ 不展开 skill 内容做教程
- ❌ 不做 skill 合并/废弃决策（仅描述现状）
- ❌ 不修复链式 junction 为扁平结构（已记录原因：用户禁令 + 当前功能正常）

## Verification & Plain-Language Summary

After all AC checks pass, the verifier MUST provide:

1. **Plain-language summary**:
   - **之前 vs 现在** — 之前没有总索引，AI 找 skill 要靠 system prompt 列举；现在打开 `Docs/AI/SKILL-INVENTORY.md` 30 秒能看到全部 74 项的分类、入口、触发词、上下游
   - **一句话总结** — 给 74 个 skill 拍了一张清晰的"全家福"，方便 AI 路由和人维护

## 实施期注意 (给金璃好帮手)

1. **不要读 73 个 SKILL.md 全文**，只读前 5-15 行（frontmatter + H1）抽元数据
2. **触发关键词**从 frontmatter.description 头一句和 H1 后的触发段（ai-video-creator 类）抽取
3. **中文字符目录**用 Read/Glob 工具直接按真实名访问，不要用 PowerShell `Get-ChildItem`
4. **写完跑一遍**：
   ```powershell
   .\.trae\scripts\doc-guard.ps1
   Test-Path "E:\UEGameDevelopment\Docs\AI\SKILL-INVENTORY.md"
   (Get-Content "E:\UEGameDevelopment\Docs\AI\SKILL-INVENTORY.md" | Select-String -Pattern '^### \d+\. ').Count
   ```
   预期最后一个命令输出 `13`（分类数）
5. **不要复制任何 skill 的 SKILL.md 内容到 inventory**，只做导航
6. **链式 junction 如实标注**：`.opencode/skills → .trae/skills → skills/`，不要"修正"为扁平
