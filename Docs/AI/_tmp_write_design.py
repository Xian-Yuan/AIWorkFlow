import sys
from pathlib import Path

content = Path(r"E:\UEGameDevelopment\Docs\AI\_tmp_design_content.txt").read_text(encoding="utf-8")
path = Path(r"E:\UEGameDevelopment\Docs\AI\ai-shortdrama-kb-workflow-integration-design.md")
path.write_text(content, encoding="utf-8")
print(f"Written {len(content)} chars to {path}")
