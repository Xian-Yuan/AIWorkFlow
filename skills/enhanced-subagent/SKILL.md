# Enhanced Subagent Skill

> Inspired by: can1357/oh-my-pi (12.7K+ stars) — "AI Coding agent for the terminal — hash-anchored edits, optimized tool harness, LSP, Python, browser, subagents, and more"

## Purpose

Enhance the existing `subagent-driven-development` skill with three patterns from oh-my-pi:
1. **Hash-anchored edits**: Use file content hashes as stable edit anchors instead of fragile line-number-based targeting
2. **Structured subagent dispatch**: Send subagents with validation checklists embedded in their task prompts
3. **Tool call optimization**: Batch independent operations, parallelize reads, sequentialize writes

## When to Activate

- **Implement phase**: Whenever subagents are dispatched, use enhanced dispatch protocol
- **Multi-file edits**: Use hash-anchored targeting to reduce edit failures from context drift
- **Large changes (8+ files)**: Enforce structured subagent dispatch with embedded validation

## Pattern 1: Hash-Anchored Edits

### Problem with current edit tool
The `edit` tool uses exact string matching. When a file changes between Plan and Implement (due to parallel subagent work, git operations, or context truncation), the oldString no longer matches, causing repeated failures.

### Hash-anchored approach
Before editing a file, compute a content hash. Embed this hash in the edit context so the agent can verify the file hasn't changed before attempting the edit.

```yaml
# Structured edit plan
file: "Source/RTS/Private/RTSCharacter.cpp"
expected_hash: "a1b2c3d4e5f6..."  # MD5 of file content
if_hash_mismatch: "re-read-file"   # or "abort" or "force"
edits:
  - target: "void ARTSCharacter::BeginPlay()"
    after: "\n\tbCanTick = true;"
    insert: "\n\tInitializeAbilitySystem();"
```

### Agent instruction
Before every `edit` call:
1. Read the target file
2. Compute hash of content
3. If hash matches expected → proceed with edit
4. If hash mismatches → re-read file and re-plan edit target
5. Never blindly edit a file that changed under you

## Pattern 2: Structured Subagent Dispatch

### Current pattern (from `subagent-driven-development`)
```
task "Implement Feature X" → subagent receives prompt → implements → returns result
```

### Enhanced pattern
```
┌─ Task spec with embedded validation
│  ├─ task_id: "feature-x-part-1"
│  ├─ state: { file_hashes: { "RTSCharacter.cpp": "a1b2...", "RTSGameMode.cpp": "b2c3..." } }
│  ├─ pre_checks: [ "codegraph exists and fresh" ]
│  ├─ edits: [ { file: "...", target: "...", insert: "..." }, ... ]
│  ├─ post_checks: [ "compile pass", "no new warnings", "file hashes updated" ]
│  └─ verification: "run `test.ps1 verify-opencore` after compile"
└─ Subagent receives spec → executes pre_checks → makes edits → runs post_checks → returns structured result
```

### Dispatch protocol
When dispatching subagents:

1. **Pre-flight snapshot**: Record file hashes for all files the subagent will touch
2. **Structured task**: Include pre_checks, edits array, post_checks, verification steps in the prompt
3. **Result contract**: Subagent must return:
   - `status`: "success" | "partial" | "failed"
   - `files_changed`: [list with before/after hashes]
   - `compile_result`: "pass" | "fail" with error summary
   - `verification_result`: "pass" | "fail" with evidence
4. **Post-flight verification**: Dispatch `code-quality-reviewer` to independently verify subagent's claims

## Pattern 3: Tool Call Optimization

### Parallelize independent reads
```yaml
# Batch these together (same tool call block)
- Read Source/RTS/Private/RTSCharacter.cpp
- Read Source/RTS/Private/RTSGameMode.cpp
- Read Source/RTS/Private/RTSAbilitySystem.cpp
- Grep "GAMEPLAYABILITY" in Source/RTS/
```

### Sequentialize dependent writes
```yaml
# Sequential (different tool call blocks)
- Edit RTSCharacter.cpp → compile → verify
- [only after compile passes] Edit RTSGameMode.cpp → compile → verify
```

### Merge query + action
When a task says "find file X and edit it", use grep to find → read to verify → edit to change — all in one logical flow but with mandatory verification between steps.

## Integration Points

### With `subagent-driven-development` skill
Replace plain task prompts with structured dispatch packets containing pre_checks + post_checks.

### With `dispatching-parallel-agents` skill
Add file hash snapshots before parallel dispatch to detect conflicts.

### With `anti-degradation` skill
Track hash verification failures as a degradation signal — if subagent edits fail hash check 2+ times, trigger degradation protocol.

### With `code-knowledge-graph` skill
Use graph to verify that subagent edits don't violate module boundaries before dispatching.
