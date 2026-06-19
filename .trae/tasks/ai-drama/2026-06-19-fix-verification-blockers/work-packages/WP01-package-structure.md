# WP01: 包结构修复

Owner model: 金璃好帮手
Difficulty: medium（涉及 9 个目录重命名 + import 路径调整）
Status: pending

## Goal
让 9 个 Skill 成为合法 Python 包，`python -m ai_drama_*` 可执行。

## Steps

### T1.1: 重命名 9 个 Skill 目录
```powershell
# 对 Project/AIDramaProducer/skills/ 下的每个 ai-drama-* 目录执行重命名
Rename-Item -Path "skills/ai-drama-orchestrator" -NewName "ai_drama_orchestrator"
Rename-Item -Path "skills/ai-drama-scriptwriter" -NewName "ai_drama_scriptwriter"
Rename-Item -Path "skills/ai-drama-text-preprocessor" -NewName "ai_drama_text_preprocessor"
Rename-Item -Path "skills/ai-drama-asset-generator" -NewName "ai_drama_asset_generator"
Rename-Item -Path "skills/ai-drama-keyframe-generator" -NewName "ai_drama_keyframe_generator"
Rename-Item -Path "skills/ai-drama-tts-generator" -NewName "ai_drama_tts_generator"
Rename-Item -Path "skills/ai-drama-video-generator" -NewName "ai_drama_video_generator"
Rename-Item -Path "skills/ai-drama-compositor" -NewName "ai_drama_compositor"
Rename-Item -Path "skills/ai-drama-viral-analyzer" -NewName "ai_drama_viral_analyzer"
```

### T1.2: 更新 __init__.py
每个包导出主类和入口函数。参考格式：
```python
# ai_drama_orchestrator/__init__.py
from .orchestrator import PipelineOrchestrator, PipelineState, main
__all__ = ["PipelineOrchestrator", "PipelineState", "main"]
```

### T1.3: 修复 import 路径
```powershell
# 搜索所有 .py 文件中引用旧包名的地方
# 使用 grep 搜索连字符导入
# 替换 ai-drama-xxx → ai_drama_xxx
```

### T1.4: 验证可执行
```powershell
# 每个 Skill 的 --help 应返回 exit 0
python -m ai_drama_orchestrator --help
python -m ai_drama_scriptwriter --help
# ...等
```

### T1.5: 更新 SKILL.md
检查每个 SKILL.md 中是否有指向 `skills/ai-drama-*` 的路径引用，更新为 `skills/ai_drama_*`

## Verification
```powershell
# 确认所有 --help 可执行
$exitCodes = @()
$mods = @("ai_drama_orchestrator","ai_drama_scriptwriter","ai_drama_text_preprocessor","ai_drama_asset_generator","ai_drama_keyframe_generator","ai_drama_tts_generator","ai_drama_video_generator","ai_drama_compositor","ai_drama_viral_analyzer")
foreach ($m in $mods) { python -m $m --help; $exitCodes += $LASTEXITCODE }
if ($exitCodes -contains 1) { Write-Host "FAIL: some modules cannot be run" } else { Write-Host "PASS: all 9 modules executable" }
```
