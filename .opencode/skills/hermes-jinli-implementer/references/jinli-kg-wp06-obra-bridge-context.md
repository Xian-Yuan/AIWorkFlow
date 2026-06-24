# WP06: Obra Index & MCP Bridge — Implementation Context

> Session: 2026-06-22 kg-runtime-wp06-discovery
> Task: 2026-06-21-knowledge-graph-runtime-implementation
> Work Package: work-packages/WP06-obra-index-mcp-bridge.md

## WP06 Goal

Reuse pinned `obra/knowledge-graph` for indexing, search, path, neighbors, node lookup, and MCP startup through a safe Jinli wrapper.

## Allowed Paths

- `Project/Jinli/services/knowledge/obra_bridge.py`
- `Project/Jinli/services/knowledge/tests/fixtures/obsidian_vault/`
- `Project/Jinli/services/knowledge/tests/test_obra_bridge.py`
- `Project/Jinli/scripts/knowledge-tools.ps1`

## Forbidden Paths

- `.trae/tasks/`
- obra/knowledge-graph source code
- Global npm configuration
- Real vault writes during tests
- Any file outside Allowed Paths

## Pinned Revision

`obra_revision = "1d2481ece87807f2f695b8853a790b8c8aa62b29"`

Already defined in `KnowledgeConfig.obra_revision` (config.py). The bridge wrapper must reuse this value, not hardcode a second copy.

## Existing Fixture Vault

The fixture vault at `tests/fixtures/obsidian_vault/` already satisfies WP06 step 6 ("at least one source note, three concept notes, and internal links"):

```
tests/fixtures/obsidian_vault/
  __init__.py
  Sources/Videos/
    ue5-lyra-gas-deep-dive-a1b2c3.md    # Source note (video)
  Concepts/
    gameplay-ability-system-d4e5f6.md    # Concept note 1
    ability-system-component-g7h8i9.md   # Concept note 2
    gameplay-effect-j0k1l2.md            # Concept note 3
```

### Fixture Note Format (from existing files)

**Source note** (`ue5-lyra-gas-deep-dive-a1b2c3.md`):
- YAML frontmatter: `kg_id`, `type: video`, `aliases`, `confidence`, `status`, `source_count`, `created`, `updated`, `canonical_store`, `provider_chain`
- `<!-- kg-gen-start -->` / `<!-- kg-gen-end -->` markers wrapping generated content
- Internal links: `[[Gameplay Ability System]]`, `[[Ability System Component]]`
- Chapter links: `[[00-00-00]]`, `[[00-05-30]]`
- Segment links: `[[Segments/BV1UF7m68E1K/00-00-00|00-00-00]]`

**Concept note** (`gameplay-ability-system-d4e5f6.md`):
- YAML frontmatter: `kg_id: concept.gameplay-ability-system`, `type: concept`, `aliases: [GAS, Gameplay Ability System]`
- Evidence links: `[[Sources/Videos/ue5-lyra-gas-deep-dive-a1b2c3|UE5 Lyra GAS 深入解析]]`
- Related links: `[[Ability System Component]]`, `[[Gameplay Effect]]`

## WP06 Steps (from work package)

1. Write failing tests with injected process runner for: missing tool, wrong revision, index success, JSON parse failure, timeout, search result normalization, path traversal
2. Implement wrapper configuration pinned to revision `1d2481e`
3. Add PowerShell inspect/install/update/index/search/mcp commands using `npm.cmd` (never change global npm state)
4. Require `KG_VAULT_PATH` to resolve to configured vault; reject path mismatch
5. Normalize CLI JSON into compact records with: node ID, title, path, score, links, evidence excerpt
6. Add fixture vault with at least 1 source note + 3 concept notes + internal links (**already exists**)
7. Keep install/network actions explicit; focused tests use fake process runner

## Done Definition

- Fixture-vault wrapper tests pass without network
- Live wrapper can prove the pinned revision before indexing
- MCP startup command is exposed but not automatically launched

## AC10 Mapping

obra/knowledge-graph can index the generated fixture vault and return keyword/semantic or graph traversal results through a wrapper.

## Key Design Constraints

1. **Do not implement graph algorithms or a custom MCP server** — reuse obra for all graph operations
2. **Do not modify global npm state** — all npm operations must be local/project-scoped
3. **KG_VAULT_PATH must match** — reject if resolved vault differs from configured vault
4. **Process runner injection** — tests use a fake process runner; real subprocess calls only for install/index/search
5. **MCP startup exposed but not auto-launched** — the command exists but must be explicitly invoked
6. **JSON normalization** — obra CLI output is verbose; wrapper normalizes to compact records

## Integration with Existing Code

- `KnowledgeConfig.obra_revision` — already has the pinned revision
- `KnowledgeConfig.vault_root` / `jinli_kg_vault_dir` — vault path for KG_VAULT_PATH check
- `KnowledgeConfig.path_contained()` — reuse for path traversal protection
- `obsidian_export.py` — generates the vault notes that obra indexes
- `ExportConfig` — vault root configuration shared with bridge

## Verification Command

```bash
cd E:/UEGameDevelopment/Project/Jinli
PYTHONPATH="E:/UEGameDevelopment/Project/Jinli/services:$PYTHONPATH" \
python -m pytest services/knowledge/tests/test_obra_bridge.py -q
```

Expected: all WP06 tests pass offline.

## Task Packet Location

`.trae/tasks/jinli/2026-06-21-knowledge-graph-runtime-implementation/`

## Current Task State

- Phase: implement
- review_result: fail (RC01 repair in progress via WP10)
- WP06 status: unclaimed
- WP01-WP05 + Pipeline: done (340+ tests passing)
- WP06 is independent of RC01 repair and can be claimed in parallel
