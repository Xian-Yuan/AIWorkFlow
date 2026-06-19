# Code Knowledge Graph Skill

> Inspired by: colbymchenry/codegraph (50K+ stars) — "Pre-indexed code knowledge graph, auto syncs on code changes, fewer tokens, fewer tool calls, 100% local"
> Also draws from: Egonex-AI/Understand-Anything (61K+ stars) — "Turn any code into an interactive knowledge graph"

## Purpose

Build and maintain a pre-indexed dependency graph of the UE5 C++ codebase that agents can query instead of reading files individually. Dramatically reduces token consumption during Plan and Implement phases by providing structural knowledge without file-by-file exploration.

## When to Activate

- **Plan phase**: `ue-project-router` MUST generate or update code graph before creating analysis.md
- **Implement phase**: Before any multi-file change, agent queries the graph to understand dependency boundaries
- **Review phase**: `code-quality-reviewer` uses graph to check if changes respect module boundaries
- **On file change**: Auto-update graph entries for modified files after each implement task

## Architecture

```
E:\UEGameDevelopment\
├── .codex-shared\codegraph\          # Graph storage (shared via junction)
│   ├── graph-index.json              # Master index
│   ├── rts-graph.json                # RTS project graph
│   ├── jìnli-graph.json              # Jìnli project graph
│   └── ctd-graph.json                # CharacterDesignTool graph
├── .trae\scripts\codegraph.ps1       # Graph builder/generator
└── .agents\skills\code-knowledge-graph\
    ├── SKILL.md                      # This file
    └── references\graph-schema.md    # Schema definition
```

## Graph Schema

Each graph file is a JSON object:

```json
{
  "project": "RTS",
  "generated": "2026-06-17T00:00:00Z",
  "commit": "abc1234",
  "modules": {
    "Source/RTS/Private/RTSCharacter.cpp": {
      "name": "RTSCharacter",
      "type": "class",
      "dependencies": ["AbilitySystemComponent", "PawnData"],
      "dependents": ["RTSPlayerController"],
      "tags": ["GAS", "AbilitySystem", "Pawn"],
      "lines": 342,
      "hash": "md5hex",
      "summary": "Main player-controlled character with GAS integration"
    }
  },
  "cross_module_deps": {
    "Source/RTS/Public/RTSCharacter.h": ["Source/RTS/Public/RTSAbilitySystem.h"]
  },
  "file_stats": {
    "total_files": 150,
    "total_lines": 45000,
    "largest_file": "Source/RTS/Private/RTSGameMode.cpp",
    "largest_lines": 1200
  }
}
```

## Script: `codegraph.ps1`

### Build graph

```powershell
.\codegraph.ps1 build -Project RTS -Output .codex-shared\codegraph\rts-graph.json
```

Behavior:
1. Scans `Project/RTS/Source/` for all `.h` and `.cpp` files
2. For each file, extracts:
   - `#include` directives → `dependencies`
   - Class/struct declarations → `type`, `name`
   - GameplayTag references → `tags`
   - Line count → `lines`
   - MD5 hash → `hash` (for change detection)
3. Resolves cross-module dependencies (Build.cs public/private deps)
4. Outputs JSON graph file
5. Updates `graph-index.json`

### Query graph

```powershell
.\codegraph.ps1 query -Project RTS -File "RTSCharacter.cpp" -Format summary
.\codegraph.ps1 query -Project RTS -Tag "GAS" -Format dependency-tree
.\codegraph.ps1 query -Project RTS -Dependency "PawnData" -Format dependents
```

### Check staleness

```powershell
.\codegraph.ps1 check -Project RTS
# Returns: list of files whose hash changed since last graph build
```

## Integration Points

### 1. Plan Phase (ue-project-router)

Before writing `analysis.md`, run:

```
codegraph.ps1 check → if stale files > 5, run build
codegraph.ps1 query -Project RTS -Tag <primary-tag> → context for routing decision
```

Inject graph summary into `analysis.md` under `## Dependency Context` section.

### 2. Implement Phase (ue-lyra-gas-implementer)

Before any file modification:

```
codegraph.ps1 query -File <target-file> -Format dependency-tree → understand impact
```

After each task completion:

```
codegraph.ps1 build -Incremental → update only changed files
```

### 3. Review Phase (code-quality-reviewer)

```
codegraph.ps1 query -Dependency <changed-file> -Format dependents → verify no orphan references
```

### 4. Ongoing: Staleness Threshold

If `check` shows 0-5 stale files → use graph as-is.
If 5-20 stale files → warn agent, suggest incremental rebuild.
If 20+ stale files → block Plan phase until full rebuild.

## Token Savings

Before CodeGraph:
```
Agent reads 15 .cpp files to understand dependency structure
→ ~15 * avg 300 lines * 3 tokens/line = ~13,500 input tokens
```

After CodeGraph:
```
Agent queries graph → gets dependency tree in 200 tokens
Agent reads only the 2-3 files actually being modified
→ ~200 + 3*300*3 = ~2,900 input tokens
```

**Savings: ~78% fewer tokens on dependency analysis.**

## Relationship to Existing Skills

- Builds on `failure-memory` pattern: stale graph = automatic rebuild
- Feeds into `implicit-requirements`: graph exposes hidden dependency constraints
- Complements `anti-degradation`: context rot detection now includes "using stale graph"
