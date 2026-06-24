# obra/knowledge-graph CLI Commands Reference

> Pinned revision: `1d2481ece87807f2f695b8853a790b8c8aa62b29`
> Package name: `knowledge-graph`, Binary: `kg` → `dist/cli/index.js`
> Source: https://github.com/obra/knowledge-graph

## CLI Commands

### `kg index`
Parse vault and build/update the knowledge graph.
```bash
kg index --vault-path <path> [--resolution 1.0] [--force]
```
- `--resolution`: Louvain community detection parameter (default 1.0)
- `--force`: Force full re-index (ignore sync state)
- Output: JSON stats `{indexed: N, errors: N, ...}`
- **First run downloads embedding model** (~100MB) — requires network

### `kg node <name>`
Get a node with its content and connections.
```bash
kg node <name> --vault-path <path> [--full] [--max-content 2000]
```
- Brief mode (default): metadata + connection summaries
- Full mode (`--full`): content + edge context (truncated to `--max-content`)
- Name resolution: fuzzy matched, disambiguates if ambiguous

### `kg neighbors <name>`
Get connected nodes at N-hop depth.
```bash
kg neighbors <name> --vault-path <path> [--depth 1]
```

### `kg search <query>`
Search the knowledge graph.
```bash
kg search <query> --vault-path <path> [--fulltext] [--limit 20]
```
- Default: semantic search (requires embedding model)
- `--fulltext`: keyword-only search (no embedding model needed)
- Output: JSON array of results with id, title, path, score, content

### `kg paths <from> <to>`
Find connecting paths between two nodes.
```bash
kg paths <from> <to> --vault-path <path> [--max-depth 3]
```

### `kg subgraph <name>`
Extract a local neighborhood subgraph.
```bash
kg subgraph <name> --vault-path <path> [--depth 1]
```

### `kg communities`
List detected communities (Louvain algorithm).
```bash
kg communities --vault-path <path>
```

### `kg community <id>`
Get a specific community with member nodes.

### `kg bridges`
Find bridge nodes (high betweenness centrality).
```bash
kg bridges --vault-path <path> [--limit 20]
```

### `kg central`
Find central nodes (PageRank).
```bash
kg central --vault-path <path> [--community ID] [--limit 20]
```

## MCP Server

The MCP server is at `dist/mcp/index.js` and uses `@modelcontextprotocol/sdk`.

### Start command
```bash
node dist/mcp/index.js
```
Reads vault path from config (env vars or `.env`).

### MCP Tools exposed
- `kg_index` — Parse vault and build/update graph
- `kg_node` — Get node details (brief or full)
- `kg_neighbors` — Get connected nodes
- `kg_search` — Semantic or fulltext search
- `kg_paths` — Find paths between nodes
- `kg_write` — Write/edit vault notes (VaultWriter)

## Installation (pinned)

```bash
npm.cmd install "obra/knowledge-graph#1d2481ece87807f2f695b8853a790b8c8aa62b29" --prefix <install-dir> --no-save
```

**Important**: Use `npm.cmd` on Windows (not `npm`). Never use `-g` or `--global`.
