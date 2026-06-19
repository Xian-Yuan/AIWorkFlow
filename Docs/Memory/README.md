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

## Prohibited

- do not write ordinary success notes here
- do not dump full chat logs
- do not let implementers write final memory entries directly
- do not treat external memory systems as the source of truth
