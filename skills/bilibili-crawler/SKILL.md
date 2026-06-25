# Bilibili Crawler + Distillation Skill (bilibili-crawler) v1.0

> **B站视频爬取 + 博主风格蒸馏 + style_injection 生成**
> 上游: 用户指定博主/关键词
> 下游: ai-video-creator pipeline (style_injection.json 注入)

## Skill Identity

- **名称**: bilibili-crawler
- **版本**: v1.0
- **角色**: B站内容采集 + 创作风格蒸馏引擎
- **触发条件**: 用户说"爬B站"/"分析博主"/"蒸馏风格"/"scan博主"/"distill"等
- **代码位置**: Project/Jinli/services/bilibili-crawler/crawler.py

## 核心能力

### 1. 搜索 + 获取视频列表
`ash
python crawler.py search "逗比的雀巢" --limit 10
`
- WBI签名的B站API访问
- 获取视频标题/描述/标签/评论/字幕

### 2. 批量扫描博主
`ash
python crawler.py scan "逗比的雀巢" --limit 10 --distill
`
- 一次扫描多个视频
- --distill 自动触发蒸馏

### 3. 单视频蒸馏
`ash
python crawler.py distill BV1K3Gz6pEoo
`
- 使用 MiniMax-M3 结构化分析
- 提取 creator_dna、signature_moves、hook_patterns、emotion_formula、narrative_templates、viral_mechanics

### 4. 输出 style_injection.json
`json
{
  "creator_dna": ["absurdist meta-humor", "gaming/anime IP parody", ...],
  "signature_moves": ["Fictional nation world-building", ...],
  "hook_patterns": ["Premise inversion hook", ...],
  "style_injection": {
    "tone": "...",
    "pacing": "...",
    "language_register": "...",
    "title_formula": "...",
    "narrative_density": "...",
    "visual_style": "..."
  }
}
`

## 与 ai-video-creator 的集成

`
用户指定博主 → crawler scan + distill → style_injection.json
                                                      ↓
                                          ai-video-creator S0~S2 注入
                                                      ↓
                                          整个管线被博主风格覆盖
`

## 已验证的测试数据

- **逗比的雀巢**: 10 个视频蒸馏完成，完整的 creator_dna + style_injection 已生成
- 输出位置: Project/Jinli/services/bilibili-crawler/output/quench_distillation.json

## 限制

- yt-dlp 下载B站视频会被 412 拦截，音频下载不稳定
- B站字幕不一定有，无字幕时需 MiniMax ASR 转录
- 评论只获取前 20 条热评