# Spec: <Task Name>

## GIVEN
<Describe preconditions and current state.>

## WHEN
<Describe the action or change being applied.>

## THEN
<Describe expected outcomes per module.>

### <Module 1>
...

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | ... | `...` | ... |
| AC02 | ... | `...` | ... |

## Quality Checklist

> 本小节遵循"需求质量测试"（Unit Tests for Requirements）理念。每个检查项测试需求规格的质量，而非实现行为。在 Plan 阶段完成后由创建者填写，Implement 阶段开始前必须通过所有项。

### Completeness
- [ ] 所有功能需求都在 spec 中覆盖，无遗漏的"已知问题"
- [ ] 每个 Module/Scenario 有明确的输入条件和预期输出
- [ ] Acceptance Criteria 覆盖所有主要场景（至少与 Scenario 数量一致）

### Clarity
- [ ] GIVEN/WHEN/THEN 中没有歧义表述（如"合理的""适当的"需替换为具体指标）
- [ ] 技术术语已定义或链接到项目术语表
- [ ] 第三方依赖/外部系统交互已明确标注

### Consistency
- [ ] spec 中的术语与项目已有术语保持一致（参考 `Docs/AI/` 和 `Docs/Memory/`）
- [ ] 模块划分与项目的文件放置约定一致（`Docs/AI/13-File-Placement-Convention.md`）
- [ ] 与已有类似功能的 spec 对比，没有模式冲突

### Scenario Coverage
- [ ] 所有模块有对应的验收场景
- [ ] 主路径场景至少 1 个（Happy Path）
- [ ] 边界条件场景至少 1 个（Edge Case）
- [ ] 错误路径场景至少 1 个（Error/Failure Path）

### Edge Case Coverage
- [ ] 空值/零值/缺省值场景已考虑
- [ ] 并发/时序竞争场景已考虑（如有）
- [ ] 资源不足（内存/磁盘/网络）场景已考虑
- [ ] 取消/中断/超时场景已考虑（如涉及长时间操作）

### Usage Guidance

填写方式：
- 在每个 checkbox 后标注 `[Gap]`（未覆盖）、`[Ambiguity]`（有歧义）、`[OK]`（已满足）
- 标注 `[Gap]` 或 `[Ambiguity]` 的项必须在 Implement 阶段前补充或澄清
- 示例：`- [ ] [OK] 所有功能需求在 spec 中覆盖`
- 示例：`- [ ] [Gap] 缺少模块 A 在低电量模式下的行为描述`

## Progress Summary

| Phase | Status | Key Decision |
|-------|--------|-------------|
| Plan | ⬜ Pending | — |
| Implement | ⬜ Pending | — |
| Review | ⬜ Pending | — |
| Verify | ⬜ Pending | — |

## Non-Goals

- <List what is explicitly out of scope.>

## Verification & Plain-Language Summary

After all AC checks pass, the verifier MUST provide:

1. **Plain-language summary** (通俗易懂总结):
   - **之前 vs 现在** — 用大白话对比，不用技术术语
   - **一句话总结** — 用日常语言概括核心变化
   - Focus on *what the user can now do that they couldn't before*
   - This summary goes into verification-report.md under `## Plain-Language Summary`
2. **No completion claim without fresh verification evidence** (see verification-before-completion skill)