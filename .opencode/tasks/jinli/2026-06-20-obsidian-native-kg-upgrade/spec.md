# Spec: Jinli Obsidian-Native Knowledge Graph Upgrade

## GIVEN
Ba Ba confirmed the desired knowledge graph should use Obsidian's native graph style: visible nodes, linked knowledge, clickable notes, automatic enrichment from video links, local model workers for repetitive extraction, optional visual model support, and external API extension points.

## WHEN
The Phase 2.5 design is upgraded.

## THEN
The design must make Obsidian-native graph output the first-class target instead of treating Obsidian as a generic Markdown export.

### S1 Obsidian Native Visual Graph
**Status**: [x] done

GIVEN accepted knowledge records exist
WHEN Jinli exports them
THEN each accepted knowledge node is a Markdown note
AND each accepted relationship is represented as an Obsidian internal link.

### S2 Clickable Knowledge Node
**Status**: [x] done

GIVEN Ba Ba clicks a node in Obsidian Graph View
WHEN the note opens
THEN it includes summary, provenance, aliases, related notes, source video links, and timestamped evidence.

### S3 Video To Knowledge Graph
**Status**: [x] done

GIVEN Ba Ba provides a supported video URL
WHEN captions or transcript text are available
THEN Jinli extracts candidate knowledge nodes and edges, checks them against existing graph notes, and adds only validated new or updated notes.

### S4 Deduplication Before Creation
**Status**: [x] done

GIVEN a candidate concept resembles an existing node
WHEN title, alias, id, or summary similarity matches an existing note
THEN Jinli merges evidence into the existing note or queues review instead of creating duplicate nodes.

### S5 Local Model Default
**Status**: [x] done

GIVEN repetitive extraction, summarization, or relation-building work is needed
WHEN local Ollama models are available
THEN Local Worker Gateway uses the local provider by default.

### S6 External API Extension
**Status**: [x] done

GIVEN local models are insufficient or Ba Ba requests higher-quality extraction
WHEN an external provider is configured
THEN the same job schema and validation envelope can route to external APIs without changing the graph pipeline.

### S7 Visual Model Enhancement Path
**Status**: [x] done

GIVEN video content contains visual-only information
WHEN visual processing is enabled in a future packet
THEN local visual models produce candidate observations linked to video/keyframe notes, not direct canonical graph mutations.

## Acceptance Criteria
| AC# | Description | Verification Command | Expected Output |
|---|---|---|---|
| AC01 | Obsidian Graph View is primary visual graph | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "Obsidian native Graph View"` | Match |
| AC02 | Note-as-node and internal-link-as-edge rules exist | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "note-as-node","internal-link-as-edge"` | Matches |
| AC03 | Vault layout and frontmatter schema exist | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "Vault layout","frontmatter"` | Matches |
| AC04 | Deduplication/merge policy exists | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "Deduplication","merge"` | Matches |
| AC05 | Provider routing supports local and external models | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "provider","ollama","external_api"` | Matches |
| AC06 | Visual model support is bounded | `Select-String -Path Project/Jinli/docs/02-Design/General/soul-core-phase2.5-knowledge-evolution-spec.md -Pattern "visual model enhancement"` | Match |
| AC07 | Documentation governance is updated | `Test-Path .trae/tasks/jinli/2026-06-20-obsidian-native-kg-upgrade/doc-impact.md` | True |

## Progress Summary
| Phase | Status | Key Decision |
|---|---|---|
| Plan | Complete | Ba Ba confirmed Obsidian-native Graph View + local model default + external API extension |
| Implement | Complete | Design doc upgraded to v2.2 |
| Review | Complete | Design covers visible graph UX, provider routing, and visual model boundary |
| Verify | Complete | Guards and AC checks recorded in verification-report.md |

## Non-Goals
- Do not implement runtime code in this packet.
- Do not create an Obsidian plugin in this packet.
- Do not make external APIs mandatory.
- Do not enable visual model processing in the first text-first implementation slice.
- Do not treat generated Obsidian notes as canonical until accepted through validation/review policy.
