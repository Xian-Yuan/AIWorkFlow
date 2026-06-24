# WP05 Result: Canonical Graph And Obsidian Export

**Status:** done
**Worker:** ds4-flash (implement)
**Date:** 2026-06-21

## Changed Files

| File | Action | Lines |
|------|--------|-------|
| `services/knowledge/graph_store.py` | created | 380 |
| `services/knowledge/deduplication.py` | created | 180 |
| `services/knowledge/obsidian_export.py` | created | 310 |
| `services/knowledge/migrations/V1__initial_schema.sql` | created | 120 |
| `services/knowledge/tests/test_graph_store.py` | created | 250 |
| `services/knowledge/tests/test_deduplication.py` | created | 170 |
| `services/knowledge/tests/test_obsidian_export.py` | created | 210 |

## Commands Run

```bash
# WP05 targeted verification
cd /e/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/test_graph_store.py \
  services/knowledge/tests/test_deduplication.py \
  services/knowledge/tests/test_obsidian_export.py -q
# Result: 49 passed in 0.24s

# Full regression (WP01-WP05)
cd /e/UEGameDevelopment/Project/Jinli && \
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/ -q
# Result: 340 passed in 0.85s
```

## Acceptance Criteria Mapping

| AC | Status | Evidence |
|----|--------|----------|
| Repeated export is idempotent and preserves manually edited sections | ✅ | `test_repeated_export_preserves_user_edits` — GEN_START/GEN_END 标记分隔，用户编辑区保留 |
| Exact duplicates merge evidence | ✅ | `check_exact_id_match` + `check_title_match` + `check_alias_match` → action='merge' |
| Ambiguous/conflicting candidates remain reviewable | ✅ | `check_text_similarity` + `check_source_overlap` → action='review' |
| All tests use temporary databases and temporary vaults | ✅ | SQLite :memory: + tempfile.TemporaryDirectory |
| Transactional writes | ✅ | `accept_candidate` 事务：候选→节点→审查决定，失败回滚 |
| Schema versioning | ✅ | `schema_version` 表 + `V1__initial_schema.sql` 迁移 |
| Evidence foreign keys | ✅ | evidence.source_ref FK → sources.source_id |
| Provenance required before canonical insertion | ✅ | `insert_node` / `insert_edge` 拒绝空 provenance |
| Deterministic deduplication rules | ✅ | 精确ID > 标题 > 别名 > 源重叠 > 相似度 > 低置信度 |
| Vault path containment | ✅ | `_ensure_vault_containment` 防路径逃逸 |
| Stable slugs across title changes | ✅ | `stable_slug` = 归一化标题 + SHA256后缀 |
| Frontmatter with internal links | ✅ | `export_concept_note` 生成 YAML frontmatter + `[[link]]` |
| Generated sections with stable markers | ✅ | `GEN_START` / `GEN_END` 标记 |
| Never update .obsidian configuration | ✅ | 导出器不触碰 .obsidian 目录 |

## Scope Control

- **Extra scope taken:** no
- All files within Allowed Paths
- No Forbidden Paths touched
- No memory.db or real ObsidianVault accessed during tests

## Worker Authority

- Review authority: none
- Verify authority: none

## Unresolved Risks

- `stable_slug` 基于 SHA256 后缀保证跨标题变更稳定性，但如果初始标题变化太大，slug 的可读部分会变（hash 后缀保证唯一性）
- Obsidian 导出器目前是文件直写模式，Obsidian 运行时可能需要 Local REST API 避免文件冲突
- 文本相似度使用 Jaccard 词集合，对中文分词不精确（可后续替换为 embedding 相似度）
