# AI Development Docs

This folder is the global AI workflow manual for the workspace. It contains cross-project rules, Agent workflow contracts, task gates, memory guidance, model-tiering rules, and documentation governance.

Project-specific docs belong under:

- `Project/<ProjectName>/Docs/`

Formal workflow design specs belong under:

- `Docs/superpowers/specs/`

Implementation plans belong under:

- `Docs/superpowers/plans/`

## Recommended Read Order

1. `01-AI-Development-Playbook.md`
2. `02-Project-Truth-Source.md`
3. `27-AI-Workflow-Refactor-Manifest.md`
4. `28-Documentation-Governance-Workflow.md`
5. `29-Mature-Solution-First-Workflow.md`
6. `33-Multi-Agent-Task-Packet-Workflow.md`
7. Task-local `routing.md`, `spec.md`, `tasks.md`, `analysis.md`, and `doc-impact.md`

## Document Index

| # | Document | Purpose |
|---|---|---|
| 01 | `01-AI-Development-Playbook.md` | Core AI development workflow |
| 02 | `02-Project-Truth-Source.md` | Truth-source hierarchy |
| 03 | `03-Singleplayer-Lyra-GAS-Rules.md` | Lyra/GAS gameplay rules |
| 04 | `04-Asset-Checklists.md` | Asset checklists |
| 05 | `05-StateTree-BT-EQS-SmartObject.md` | AI behavior selection |
| 06 | `06-GameplayTag-Registry.md` | GameplayTag registry |
| 07 | `07-Test-Checklists.md` | Testing checklists |
| 08 | `08-AntiPatterns.md` | Known anti-patterns |
| 09 | `09-Agent-Handoff-Templates.md` | Agent handoff templates |
| 10 | `10-Execution-Examples.md` | Execution examples |
| 11 | `11-Skill-Routing-Workflow.md` | Skill routing workflow |
| 12 | `12-MultiAgent-Workflow.md` | Multi-agent collaboration |
| 13 | `13-File-Placement-Convention.md` | File placement conventions |
| 14 | `14-Coding-Standards.md` | UE C++ coding standards |
| 15 | `15-FailSafe-AntiBloat.md` | Fail-safe and anti-bloat rules |
| 16 | `16-DeepSeek4Pro-Workflow-Profile.md` | DeepSeek4Pro workflow profile |
| 17 | `17-Self-Improving-Framework.md` | Self-improving workflow |
| 18 | `18-Validation-Checklist.md` | Validation checklist |
| 19 | `19-Unreal-Conventions.md` | Unreal conventions |
| 20 | `20-DeepSeek4Pro-Regression-Scenarios.md` | Workflow regression scenarios |
| 21 | `21-Workflow-Regression-Checklist.md` | Workflow regression checklist |
| 22 | `22-Web-Preview-Handoff-And-Verify.md` | Web preview handoff and verify |
| 23 | `23-Web-Subagent-Enforcement.md` | Web subagent enforcement |
| 24 | `24-Pro-Flash-Model-Tiering.md` | Pro + Flash model tiering |
| 25 | `25-Repomix-Workflow.md` | Repomix workflow |
| 26 | `26-Agent-Capability-Enhancement.md` | Agent capability enhancement |
| 27 | `27-AI-Workflow-Refactor-Manifest.md` | Current refactor manifest |
| 28 | `28-Documentation-Governance-Workflow.md` | Documentation governance workflow |
| 29 | `29-Mature-Solution-First-Workflow.md` | Mature solution first quality gate |
| 30 | `30-AI-Workflow-Compatibility-Analysis.md` | Codex/OpenCode workflow compatibility analysis |
| 31 | `31-Architecture-Analysis.md` | Architecture analysis |
| 32 | `32-Refactoring-Spec.md` | Refactoring specification |
| 33 | `33-Multi-Agent-Task-Packet-Workflow.md` | Multi-agent task packets, Codex adapter rules, and automated verification gates |
| 34 | `34-AI-Workflow-Current-Audit.md` | Current Codex/OpenCode usability, redundancy, invalid feature, and architecture audit |
| 35 | `35-Codex-CCS-Capability-Consistency.md` | Codex project-skill discovery and CC Switch provider capability consistency layer |
| 36 | `36-Research-Index.md` | Ecosystem research and survey index |
| 37 | `37-Agent-Reach-Integration.md` | Agent-Reach multi-platform search integration guide |
| 38 | `38-Jinli-Agent-Soul-Architecture.md` | 金璃 Agent 灵魂层架构 |

| 39 | `39-Root-Git-Workspace-Boundary.md` | Cross-IDE root Git boundary, scan protection, line endings, and push safety |
| 40 | `40-DS4-Flash-Worker-Repair-Loop.md` | DS4 Flash bounded delegation, independent Codex acceptance, and automatic repair repackaging |
| 41 | `41-Issuer-Worker-Authority-Separation.md` | Cryptographic issuer authority, bounded worker capabilities, independent approval, and explicit archive |
| 42 | `42-GitHub-SSH-Publish-Workflow.md` | Root repository SSH publication, protected remotes, worktree isolation, and remote SHA verification |

## Generated Inventories

| Document | Purpose |
|---|---|
| `document-taxonomy-inventory.md` | Current workspace document classification inventory |
