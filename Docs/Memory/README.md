# Basic Memory

## Goal

`Docs/Memory/` stores high-value failure memories for the workspace. It is the Phase 1 file-based memory layer and remains human-auditable.

## Scope

- Store only failure-driven memory in Phase 1
- Keep files as the source of truth
- Support Router and Implement retrieval
- Prepare for future `Mem0` sync without making `Mem0` the source of truth

## Directory Layout

- `failures/`: promoted failure memories
- `candidates/`: pre-promotion candidate memories
- `indexes/`: lightweight retrieval index
- `templates/`: canonical write templates

## Write Triggers

- `Review FAIL`
- `Verify FAIL`
- workflow regression fail

## Promotion Gate

- observed or reproducible failure
- reusable rule
- clear verification method
- useful for `router` or `implement` retrieval

## Retrieval Rules

- Router reads `top 2`, at most `top 3`
- Implement reads `top 1`, at most `top 2`
- Summaries only; do not inject full memory files into prompts

## Phase 2 Retrieval

- local retrieval is handled by `.trae/scripts/memory-retrieve.ps1`
- Mem0 is optional and must pass `.trae/scripts/mem0-healthcheck.ps1`
- local files remain the source of truth

### Semantic Search Status (2026-06-18)

- `-Semantic` parameter added to `memory-retrieve.ps1` — attempts `ruflo memory search` for semantic retrieval
- **ruflo CLI is not currently available** on this system (executable not found, npm not installed)
- `-Semantic` silently falls back to keyword-only search when ruflo is unavailable
- **Active alternative**: `-UseMem0` flag performs HTTP-based semantic search via Mem0 endpoint
- To enable `-Semantic`: install ruflo CLI and ensure `all-MiniLM-L6-v2` model is cached at `~/.cache/xenova/transformers/Xenova/all-MiniLM-L6-v2/`
- Model files (90MB onnx + configs) are already cached locally but unused without ruflo executable

## Prohibited

- do not write ordinary success notes here
- do not dump full chat logs
- do not let implementers write final memory entries directly
- do not treat external memory systems as the source of truth
