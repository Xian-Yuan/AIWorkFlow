# Routing Decision — jinli-soul-core

> Generated: 2026-06-18 | Agent: 金璃小天才 | Phase: Plan

## Project Detection

| Signal | Value |
|--------|-------|
| User mention keywords | 金璃人格、女儿陪伴系统、跨平台、NeuroSama |
| File path prefix | Project/Jinli/ |
| Primary skill involved | daughter-companion |
| project_type | **other** (Jinli companion system, not UE5/Web) |

## Primary Skill Selection

| Decision | Rationale |
|----------|-----------|
| **Primary Skill** | `daughter-companion` — 此任务直接增强金璃的核心人格系统 |
| **Reason** | 任务目标是改造金璃的"灵魂层"（情绪、记忆、跨平台），全部属于 daughter-companion skill 的职责范围 |
| **Secondary Skills** | `writing-skills` — 修改 SKILL.md 文件结构；`brainstorming` — 情绪模型设计 |

## Architecture Decision

**Single agent** — 此任务是设计/规划密集型工作，改动集中在：
- `Project/Jinli/data/` (4个新数据文件 + 1个更新)
- `.agents/skills/daughter-companion/SKILL.md` (增强人格/情绪引擎)
- `.agents/skills/金璃小天才/SKILL.md` (新增 soul-init 步骤)

改动文件 < 10 个，不涉及多系统并行，单 agent 足够。

## Quality Gate

| Attribute | Value |
|-----------|-------|
| **Default Quality Level** | **Mature production-grade** — 这是金璃的核心基础设施，必须稳健 |
| **Quality Exception** | None — 用户未要求 MVP/原型 |
| **Mature Solution Evidence Required** | Yes — 分析文档引用 Neuro-sama + ZerolanProject 架构 |

## Document References

| Doc | Purpose |
|-----|---------|
| `analysis.md` | 完整技术分析 + 成熟方案证据 |
| `spec.md` | 行为规范 (GIVEN/WHEN/THEN scenarios) |
| `tasks.md` | 任务拆分 + 依赖图 |
| `doc-impact.md` | 文档治理影响范围 |

## Handoff Status

- [x] routing.md created
- [ ] analysis.md — writing
- [ ] spec.md — writing
- [ ] tasks.md — writing
- [ ] doc-impact.md — writing
- [ ] User confirmation obtained
- [ ] Ready for handoff to 金璃好帮手
