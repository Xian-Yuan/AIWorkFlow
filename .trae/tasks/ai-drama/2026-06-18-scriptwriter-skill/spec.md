# Spec: AI 漫剧编剧 Skill (ai-drama-scriptwriter) v2.1

> v2.1 更新: 新增 ViralAnalysis 风格注入接口
> 调研文档: `Project/AIDramaProducer/docs/01-Planning/ViralAnalysis/01-viral-analysis-ecosystem-research.md`

## GIVEN
- 用户提供了一段故事文本 (小说原文 / 创意大纲 / 故事梗概，500-50000字)
- 用户选择了一种视觉风格 (日漫/韩漫/美漫/写实/国风/像素/水彩/赛博朋克/胶片/极简)
- 用户指定了目标时长 (默认 180 秒 / 3 分钟)
- 系统可访问至少一个 LLM API (Claude/GPT/DeepSeek/GLM)
- 风格预设文件 `styles/presets.yaml` 已加载
- (可选) 用户提供了风格注入数据: `style_injection.json`, `character_archetypes.json`, `shot_pacing_reference.json`, `voice_style_reference.json`
- 对于 >5000 字文本，章节事件图谱已由 Phase 1 生成

## WHEN
用户触发编剧流程:
1. 提供故事文本 + 风格选择 + 目标时长 + (可选) 风格注入数据
2. 编剧 Skill 按 3 步生成结构化剧本
3. 风格注入数据优先级高于风格预设默认值
4. 每步输出中间结果，允许用户审查和调整
5. 最终输出完整剧本 JSON

## THEN

### 风格注入接口 (v2.1 新增)

编剧 Skill 新增 4 个可选输入参数，接收来自 Phase 0 (ViralAnalysis Skill) 的分析结果:

| 参数 | 文件 | 注入目标 | 优先级规则 |
|------|------|---------|-----------|
| `--style-injection` | `style_injection.json` | styles/presets.yaml 的风格参数 | 注入值 > 预设默认值 |
| `--character-archetypes` | `character_archetypes.json` | Step 1 角色提取的 archetype/description | 注入值作为 LLM 提示词参考 |
| `--shot-pacing` | `shot_pacing_reference.json` | Step 3 分镜设计的镜头类型分布/时长分布 | 注入值作为约束规则权重调整 |
| `--voice-style` | `voice_style_reference.json` | Step 1 角色提取的 voice_profile | 注入值 > 风格预设 voice_style_params |

**注入数据格式示例**:

`style_injection.json`:
```json
{
  "source": "viral-analysis",
  "reference_urls": ["https://...", "https://..."],
  "injected_params": {
    "character_keywords_override": ["sharp jawline", "trench coat", "cyberpunk neon trim"],
    "shot_keywords_override": ["dutch angle", "high contrast lighting", "speed lines"],
    "dialogue_style_override": "快节奏对话，每句不超过15字，高频使用反问句",
    "pacing_profile": {
      "hook_duration_sec": 3,
      "avg_shot_duration_sec": 3.5,
      "climax_shot_density": "high"
    }
  }
}
```

`character_archetypes.json`:
```json
{
  "source": "viral-analysis",
  "archetypes": [
    {
      "name": "反英雄主角",
      "big_five_profile": {"openness": 0.7, "conscientiousness": 0.3, "extraversion": 0.5, "agreeableness": 0.2, "neuroticism": 0.8},
      "common_traits": ["孤僻", "机智", "道德灰色"],
      "visual_patterns": ["深色服装", "伤疤", "冷色调"],
      "voice_patterns": {"timbre": "husky", "pace": "slow", "pitch": "low"}
    }
  ]
}
```

### Step 1-3: 同 v2.0

(Step 1: 故事分析与角色提取 — 新增: 注入 character_archetypes 作为 LLM 提示词参考)
(Step 2: 场景拆分)
(Step 3: 分镜设计 — 新增: 注入 shot_pacing 调整约束规则权重)

### 约束规则 (v2.1 更新)

规则 1-15 同 v2.0。v2.1 新增规则权重动态调整机制:

当 `shot_pacing_reference.json` 注入时，以下规则的 SHOULD/MUST 级别不变，但阈值参数可动态调整:
- 规则 3 (对话镜头 3-5 秒): 阈值可调整为参考数据的实际分布
- 规则 4 (动作镜头 4-6 秒): 同上
- 规则 7 (连续 3 个同类型→插入变化): 阈值可调整为参考数据的实际模式

## Acceptance Criteria (v2.1 新增 AC14-AC15)

| AC# | Description |
|-----|-------------|
| AC01-AC13 | 同 v2.0 |
| **AC14** | **新增**: 提供 style_injection.json → 剧本风格关键词使用注入值而非预设默认值 |
| **AC15** | **新增**: 提供 character_archetypes.json → 角色 archetype 和 voice_profile 参考注入数据 |

## Non-Goals

- 同 v2.0
- 不实现爆款分析功能本身 (那是 ViralAnalysis Skill 的事)
- 不实现注入数据的自动采集 (编剧 Skill 只消费，不生产)

## Implementation Status (2026-06-18)

| Phase | Status | Detail |
|-------|--------|--------|
| Plan | ✅ Completed v2.1 | 3 步生成 + 15 条规则 + 15 AC + 注入接口 |
| Implement | 🚧 In Progress | 核心 3 步模块、Schema、验证器和 CLI 已落地；交互输出与 v2.1 注入仍缺失 |
| Verify | ❌ Failed | 单元测试通过，但 AC14/AC15 与真实 LLM E2E 无证据 |

## Current Progress Audit (2026-06-19)

- **Current Phase**: Implement
- **Verified AC**: 10/15（以 19 个本地测试覆盖的 Schema、引用、时长和字段校验为主）。
- **Completed foundation**: 3 步模块、10 风格预设、JSON Schema、9 个验证器、CLI 包入口。
- **Open behavior**: 增量修改、`script_summary.md`、`feasibility_report.md`、`tts_plan.json`。
- **v2.1 blocker**: CLI 与生成链路没有 `style_injection.json`、`character_archetypes.json` 输入参数，AC14/AC15 未实现。
- **E2E blocker**: 尚无真实 LLM Quick/Review Mode 端到端证据。
- **Next Step**: 补齐 WP07 输出、AC14/AC15 注入与真实生成验证。
