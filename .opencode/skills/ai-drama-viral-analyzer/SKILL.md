# AI 爆款分析与融合创作 Skill (ai-drama-viral-analyzer) v1.0

> 六层架构中的 **Layer 0: 创意研究层**
> 定位: 爆款视频/小说结构分析 + 风格复制 + 融合创作 + 数据注入编剧
> 双引擎: 分析引擎 (Analyzer) + 创作引擎 (Creator)
> 数据契约: 上游 用户输入 → 下游 Phase 2 Scriptwriter Skill (4 个注入文件)

## 双引擎架构

```
分析引擎 (Analyzer)              创作引擎 (Creator)
├── VideoAnalyzer                ├── StyleCopy (复制风格)
├── NovelAnalyzer                ├── FusionCreate (融合创作)
└── ChannelAnalyzer              └── ScriptInject (注入编剧)
        ↓                               ↓
知识库 (hook/情绪/叙事/风格) ←── 每次分析追加
```

## 4 种交互模式

```bash
# 1. 快速分析视频
python viral_analyzer.py analyze <url>

# 2. 批量扫描博主
python viral_analyzer.py scan <creator> --platform youtube --count 50

# 3. 风格注入编剧
python viral_analyzer.py inject --from <analysis_id> --to scriptwriter

# 4. 融合创作
python viral_analyzer.py fusion --sources <id1> <id2> --topic <text>
```

## 8 个分析维度 (VideoAnalyzer)
① 钩子分析 ② 叙事结构 ③ 情绪曲线 ④ 剪辑节奏
⑤ 镜头语言 ⑥ CTA 分析 ⑦ 文案/金句 ⑧ 评论区

## 4 个注入文件 (ScriptInject → Scriptwriter)
- `style_injection.json` — 风格参数
- `character_archetypes.json` — 角色原型
- `shot_pacing_reference.json` — 分镜节奏
- `voice_style_reference.json` — 配音风格
