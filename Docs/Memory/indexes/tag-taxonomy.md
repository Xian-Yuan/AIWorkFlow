<!--
  Tag Taxonomy for Memory Index
  Purpose: Standardized tag system for precise failure memory retrieval.
  Every failure memory MUST use tags from this taxonomy.
  Tags are organized by category. A memory entry should have at least
  one tag from each relevant category.

  Usage in retrieval:
    1. Match task's project_type against Domain tags
    2. Match task's phase against Phase tags
    3. Match task keywords against Pattern and System tags
    4. Score by number of matching tags across categories
    5. Return top 2 (or top 3 for high-risk tasks)
-->

# Tag Taxonomy

## Category 1: Phase (when the failure was discovered)

| Tag | Description |
|-----|-------------|
| `phase:plan` | Failure discovered during planning/routing |
| `phase:implement` | Failure discovered during implementation |
| `phase:review` | Failure discovered during code review |
| `phase:verify` | Failure discovered during verification |

## Category 2: Module (which agent/component failed)

| Tag | Description |
|-----|-------------|
| `mod:router` | Router/Orchestrator failure |
| `mod:implementer` | Implementer agent failure |
| `mod:validator` | Validator agent failure |
| `mod:reviewer` | Code reviewer failure |
| `mod:skill` | Skill definition/configuration failure |
| `mod:script` | Automation script failure |
| `mod:cc-switch` | CC Switch configuration/usage |

## Category 3: Domain (project/technology area)

| Tag | Description |
|-----|-------------|
| `dom:ue5` | Unreal Engine 5 specific |
| `dom:web` | Web application (JS/Node/HTML) |
| `dom:python` | Python tooling/scripts |
| `dom:gas` | Gameplay Ability System |
| `dom:lyra` | Lyra framework |
| `dom:ai` | AI/Behavior (StateTree/BT/EQS) |
| `dom:ui` | UMG/Slate/Widget |
| `dom:animation` | Animation/AnimBP |
| `dom:input` | Enhanced Input/InputConfig |
| `dom:save` | SaveGame/Serialization |
| `dom:network` | Replication/RPC (singleplayer: should not appear) |
| `dom:build` | Compilation/Build.cs/Modules |
| `dom:asset` | DataAsset/Blueprint/Content |
| `dom:performance` | Performance/Optimization |
| `dom:pcg` | Procedural Content Generation |
| `dom:mass` | Mass Entity |

## Category 4: Pattern (type of mistake)

| Tag | Description |
|-----|-------------|
| `pat:implicit-requirement` | Missed implicit/hidden requirement |
| `pat:anti-pattern` | Used known anti-pattern |
| `pat:architecture` | Architecture/module boundary violation |
| `pat:dependency` | Missing or wrong dependency |
| `pat:configuration` | Config/DataAsset wiring error |
| `pat:compilation` | Compilation error pattern |
| `pat:runtime` | Runtime error/crash pattern |
| `pat:regression` | Regression from previous fix |
| `pat:context-rot` | Context degradation caused error |
| `pat:over-engineering` | Built more than needed |
| `pat:under-engineering` | Built less than needed |
| `pat:wrong-skill` | Wrong skill selected for task |
| `pat:wrong-agent` | Wrong agent assigned to task |
| `pat:api-misuse` | Used API incorrectly |
| `pat:type-error` | Type system violation |
| `pat:null-deref` | Null/empty value not handled |
| `pat:boundary` | Edge case/boundary condition missed |

## Category 5: System (affected subsystem)

| Tag | Description |
|-----|-------------|
| `sys:experience` | GameFeature/Experience |
| `sys:pawn-data` | PawnData/Character |
| `sys:ability-set` | AbilitySet/Ability |
| `sys:attribute` | AttributeSet/Attribute |
| `sys:gameplay-effect` | GameplayEffect |
| `sys:gameplay-cue` | GameplayCue |
| `sys:ability-task` | AbilityTask |
| `sys:input-config` | InputConfig/Mapping |
| `sys:camera` | Camera/View |
| `sys:movement` | CharacterMovement |
| `sys:equipment` | Equipment/Weapon/Inventory |
| `sys:combat` | Combat/Damage/Health |
| `sys:interaction` | World Interaction |
| `sys:hud` | HUD/Overlay |
| `sys:menu` | Menu/UI Panel |
| `sys:save-game` | SaveGame system |
| `sys:state-tree` | StateTree |
| `sys:behavior-tree` | Behavior Tree |
| `sys:eqs` | EQS queries |
| `sys:smart-object` | SmartObject |
| `sys:cc-switch` | CC Switch desktop app |
| `sys:opencode` | OpenCode IDE (cli + agents) |
| `sys:codex` | Codex Desktop App |

## Retrieval Scoring

When searching for relevant failure memories:

```
Score = 0
For each tag in query:
  If exact match in memory tags: Score += 3
  If same category match: Score += 1
If memory.severity == "high": Score += 1
If memory.severity == "critical": Score += 2
Sort by Score DESC, take top 2 (or top 3 for high-risk)
```

## Tag Application Rules

1. Every failure memory MUST have at least: 1 Phase tag + 1 Module tag + 1 Domain tag + 1 Pattern tag
2. System tags are optional but recommended when applicable
3. Maximum 8 tags per memory entry (avoid tag bloat)
4. Do not invent new tags without updating this taxonomy first
5. Tags are lowercase, hyphen-separated, with category prefix
