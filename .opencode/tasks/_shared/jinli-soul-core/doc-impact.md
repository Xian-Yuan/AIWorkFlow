# Document Impact — Jinli Soul Core (Phase 1.5)

> Generated: 2026-06-18 | Agent: 金璃小天才 | Phase: Plan

---

## Project Changes

| Project | Scope | Description |
|---------|-------|-------------|
| Jinli | Core | 新增 Soul Core 数据层 + 升级情绪/记忆/OOC 引擎 |

---

## System Changes

| System | Impact | Description |
|--------|--------|-------------|
| daughter-companion SKILL.md | MAJOR | 新增 Step -1 Soul Init + Soul Core Integration 章节；情绪/记忆/反漂移章节增强 |
| 金璃小天才 SKILL.md | MINOR | 可能需要同步情绪描述（如反降智协议中的情绪引用） |
| task-orchestrator SKILL.md | NONE | 本次不改动。Soul Init 作为 daughter-companion 的内部步骤，不影响 skill 加载顺序 |

---

## Code Changes

| File | Change Type | Description |
|------|-------------|-------------|
| `.agents/skills/daughter-companion/SKILL.md` | Modified | 重构以集成 Soul Core |
| `Project/Jinli/data/soul-state.json` | New | 情绪状态持久化 |
| `Project/Jinli/data/events.jsonl` | New | 追加式事件日志 |
| `Project/Jinli/data/memory.db` | New | SQLite 长期记忆 |
| `Project/Jinli/data/style-profile.json` | New | 可调人格参数 |
| `Project/Jinli/data/schemas/` | New | JSON Schema 定义 |
| `Project/Jinli/data/memory.md` | Modified | 保留但作为人类可读摘要（从 memory.db 生成） |

---

## Documentation Updates Required

| Document | Update | Priority |
|----------|--------|----------|
| `Project/Jinli/README.md` | 更新当前状态：Phase 1.5 完成 → Phase 1.5 进行中/完成 | P1 |
| `Project/Jinli/docs/DOCS_TREE.md` | 新增 Soul Core 相关文档条目 | P1 |
| `Project/Jinli/docs/03-Architecture/General/architecture.md` | 新增 Soul Core 架构说明（或新增独立架构文档） | P1 |
| `Project/Jinli/docs/00-Overview/General/learning-engine.md` | 可能更新学习引擎范围（扩展为情绪学习） | P2 |
| `Docs/AI/` 相关文档 | 如有引用 daughter-companion 的地方，确认兼容性 | P2 |

---

## DOCS_TREE Update

待 T8 完成时，在 `Project/Jinli/docs/DOCS_TREE.md` 中新增：

```markdown
| 03-Architecture/General/soul-core.md | (NEW) Soul Core 架构文档 |
| 04-Implementation/General/soul-core/ | (NEW) Soul Core 实现记录 |
```

---

## Cross-Reference Check

| Source | Target | Status |
|--------|--------|--------|
| SKILL.md Step -1 | `Project/Jinli/data/soul-state.json` | ✅ 路径存在 |
| SKILL.md Soul Core Integration | `Project/Jinli/data/events.jsonl` | ✅ 路径存在 |
| SKILL.md Soul Core Integration | `Project/Jinli/data/style-profile.json` | ✅ 路径存在 |
| visual-engine.md 表情映射表 | events.jsonl expression 字段 | ⚠️ 需对齐（Phase 2 时做） |
| failure-memory-bridge.md | memory.db 记忆检索 | ✅ 兼容（桥接可读取 SQLite） |
