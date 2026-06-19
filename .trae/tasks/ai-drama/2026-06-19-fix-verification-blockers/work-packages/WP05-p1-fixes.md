# WP05: P1 修复（资产复制 + 占位替换）

Owner model: 金璃好帮手
Difficulty: medium
Status: pending
Depends on: WP01

## Goal
- B07: 跨项目资产复用时复制文件
- B09: 占位字节替换为可解析的模拟数据

## Steps

### T5.1: 全局资产文件复制

在 `AssetLibrary.get_or_create_character()` 的全局缓存命中分支:

```python
# 当前: 全局缓存命中时只存 JSON entry，路径指向原项目
# 修复: 复制文件到项目目录
import shutil
from pathlib import Path

# 在全局命中后
if global_entry.get("hash") == asset_hash:
    logger.info(f"Character {char_id}: cache hit (global)")
    
    # 复制文件到项目目录
    old_ref = Path(global_entry["ref_image"])
    old_bone = Path(global_entry["bone_data"])
    
    new_ref = self.project_dir / "characters" / f"{char_id}_ref.png"
    new_bone = self.project_dir / "characters" / f"{char_id}_bone.json"
    
    new_ref.parent.mkdir(parents=True, exist_ok=True)
    if old_ref.exists():
        shutil.copy2(str(old_ref), str(new_ref))
    if old_bone.exists():
        shutil.copy2(str(old_bone), str(new_bone))
    
    entry = {
        **global_entry,
        "ref_image": str(new_ref),
        "bone_data": str(new_bone),
        "asset_reuse_id": asset_reuse_id,
    }
    # ...
```

### T5.2: 占位字节替换

创建一个 `utils/placeholder_assets.py` 工具，生成最小有效文件：

```python
"""占位资产生成工具 — 生成可被工具解析的最小有效文件"""

import struct
import zlib

def create_minimal_png(path: str):
    """生成 2x2 像素的 PNG（可被 ffprobe、PIL 等解析）"""
    # PNG 签名
    signature = b'\x89PNG\r\n\x1a\n'
    # IHDR: 2x2, 8-bit RGB
    ihdr_data = struct.pack('>IIBBBBB', 2, 2, 8, 2, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
    ihdr = struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    # IDAT: 原始像素数据 (deflated)
    raw = b'\xff\x00\x00\x00\xff\x00\x00\x00\xff\xff\x00\xff'  # RGBA 2x2
    compressed = zlib.compress(raw)
    idat_crc = zlib.crc32(b'IDAT' + compressed)
    idat = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
    # IEND
    iend_crc = zlib.crc32(b'IEND')
    iend = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    with open(path, 'wb') as f:
        f.write(signature + ihdr + idat + iend)

def create_minimal_mp3(path: str):
    """生成最小 MP3（可被 ffprobe 解析时长）"""
    # MP3 frame header: 128kbps, 44100Hz, stereo
    # 用 1 秒静音帧
    frame_header = b'\xff\xfb\x90\x00'  # MPEG1 Layer3, 128kbps, 44100
    frame = frame_header + b'\x00' * 413  # 417 bytes per frame
    with open(path, 'wb') as f:
        for _ in range(38):  # ~1 second
            f.write(frame)

def create_minimal_mp4(path: str):
    """生成最小 MP4（可被 ffprobe 识别）"""
    # 使用 ftyp + moov 最小结构
    # ISO Base Media File Format minimal
    ftyp = b'\x00\x00\x00\x18ftypmp42\x00\x00\x00\x00mp42mp41'
    moov = b'\x00\x00\x00\x08moov'
    with open(path, 'wb') as f:
        f.write(ftyp + moov)
```

在各 Generator 的 fallback 路径中使用这些函数替代 `b"PLACEHOLDER_*"`。

## Verification
```powershell
# 验证全局资产复用会复制文件
python -c "
from ai_drama_asset_generator.asset_generator import AssetLibrary
lib = AssetLibrary('test_project', 'test_global')
# ... 测试复用并检查文件路径
"

# 验证占位文件可被 ffprobe 解析
ffprobe test_minimal.mp3 2>&1 | Select-String "Duration"
ffprobe test_minimal.mp4 2>&1 | Select-String "Duration"
python -c "from PIL import Image; Image.open('test_minimal.png')"
```

---

## Worker Report — 2026-06-19 15:45

**Owner**: 金璃好帮手 (via Plan 金璃小天才)  
**Status**: Completed

### Completed Tasks

| Task | Description | Result |
|------|-------------|--------|
| T5.1 | 全局资产复用复制文件 | ✅ `shutil.copy2()` + fallback `create_minimal_png()` |
| T5.2 | PLACEHOLDER 替换 | ✅ 新包 `ai_drama_placeholder_assets` + 5 模块更新 + 测试更新 |

### Evidence

- `ai_drama_placeholder_assets/` 包: `create_minimal_png`, `create_minimal_mp3`, `create_minimal_mp4`, `create_minimal_keyframe`
- 5 模块已替换: asset_generator, video_generator, compositor, tts_generator, keyframe_generator
- 测试断言已更新: 检查 PNG signature / MP4 ftyp atom 而非 `b"PLACEHOLDER_*"`
- Tests: `95 passed`
