# WP02: 剧本生成器 (Script Generator)

Owner model: unclaimed
Difficulty: medium
Status: unclaimed

## Task Packet
- Root: `.trae/tasks/_shared/2026-06-18-ai-drama-workflow-research/`
- Parent task: `2026-06-18-ai-drama-workflow-research`

## Allowed Paths
- `skills/ai-drama-producer/modules/script_generator/` (新建)
- `skills/ai-drama-producer/schemas/` (新建)
- `skills/ai-drama-producer/utils/llm_client.py` (新建)

## Forbidden Paths
- `Project/RTS/`
- `Project/CharacterDesignTool/`
- `Project/Jinli/`

## Read First
- `routing.md`
- `analysis.md`
- `spec.md` (Module 2 + 剧本 JSON Schema)
- `tasks.md` (WP02 section)

## Goal
实现剧本生成器模块：从小说/创意文本生成结构化剧本 JSON，含角色、场景、镜头定义，通过 JSON Schema 校验。

## Steps
- [ ] 创建 `schemas/script_schema.json` — 剧本 JSON Schema (characters, scenes, shots 的完整 schema，含 enum 约束)
- [ ] 实现 `utils/llm_client.py` — LLM 调用抽象层 (支持 Claude/GPT/DeepSeek/GLM 多后端，统一接口)
- [ ] 实现 `modules/script_generator/generator.py` — 小说→剧本 Prompt 模板 + LLM 调用 + 结构化输出
- [ ] 实现 `modules/script_generator/validator.py` — 剧本验证器 (引用完整性: character_id 和 scene_id 交叉校验)
- [ ] 编写单元测试: 验证器对有效/无效剧本的正确判断

## Done Definition
- `script_schema.json` 定义完整，覆盖 spec.md 中所有字段
- `llm_client.py` 支持至少 2 种 LLM 后端 (Claude + 任一其他)
- `generator.py` 输入小说文本 → 输出符合 schema 的 JSON
- `validator.py` 正确检测缺失引用、无效枚举值
- 单元测试通过

## Required Verification
- Command: `python -m pytest skills/ai-drama-producer/modules/script_generator/ -v`
- Expected: all tests pass
- Command: `python -c "import json; schema=json.load(open('skills/ai-drama-producer/schemas/script_schema.json')); print('schema OK, fields:', list(schema.get(''properties'',{}).keys()))"`
- Expected: `schema OK, fields: ['title', 'style', 'characters', 'scenes', 'shots']`

## Return Report
- Path: `reports/<agent-name>-WP02-result.md`
- Required status for merge: `done`
- Must include changed files, commands run, results, acceptance criteria touched, scope control, and unresolved risks.
- Must declare `Extra scope taken: no`.

## Failure Reporting
- If blocked, write the same report path with `Status: blocked`.
- Include the blocker, commands already run, and the smallest question needed from the lead agent.
- Do not edit outside Allowed Paths while blocked.

## Publisher Checklist
- [x] No `<placeholder>` text remains in this work package.
- [x] Allowed Paths and Forbidden Paths are concrete.
- [x] Required Verification has a real command and expected result.
- [x] Return Report path is concrete.
