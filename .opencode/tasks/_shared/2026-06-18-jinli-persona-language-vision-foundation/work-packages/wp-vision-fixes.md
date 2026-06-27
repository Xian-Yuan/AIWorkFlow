# Work Package: Vision Python 修复 — 21 个测试失败

> **范围限制（Ba Ba 指定）**:
> - `Project/Jinli/services/vision/contracts.py`
> - `Project/Jinli/services/vision/memory.py`
> - `Project/Jinli/services/vision/redact.py`
> - `Project/Jinli/services/vision/service.py`
> - `Project/Jinli/services/vision/tests/test_service.py`
> - 两个活跃任务包（更新 tasks.md / verification-report.md）
>
> **不得修改或删除测试来获得通过**

---

## 修复 1: TTL=0 立即过期（6 个失败）

**文件**: `contracts.py` 第 72 行

```python
# 当前（有 bug）:
return self.age_seconds > self.ttl_seconds

# 修复后:
return self.age_seconds >= self.ttl_seconds
```

ttl=0 的语义是"立刻过期"。当 `age_seconds=0.0001, ttl_seconds=0` 时，`0.0001 >= 0` → True ✅

**影响**: `memory.py` 中 `get_observation()`、`get_active_observations()`、`cleanup_expired()`、`get_stats()` 都依赖 `obs.is_expired` → 一修全好。

---

## 修复 2: PASSWORD_PATTERNS 识别 `api_key=sk-abc123def456`（1 个失败）

**文件**: `redact.py` `PASSWORD_PATTERNS` 列表

**当前**: 有 `api[_-]?key` 的 JSON 格式 `"api_key":"..."`，但没有无引号 query 格式 `api_key=...`

**修复**: 在 `PASSWORD_PATTERNS` 末尾添加：

```python
re.compile(rb'api[_-]?key\s*=\s*\S+', re.IGNORECASE),
```

---

## 修复 3: redact_frame 使用 config.preset_regions（1 个失败）

**文件**: `redact.py` 第 132-135 行

**当前**:
```python
if redaction_rules is None:
    redaction_rules = []
if config is None:
    config = RedactionConfig(preset_regions=redaction_rules)
```

当调用了 `redact_frame(img, config=config)` 且 `config.preset_regions` 有值时，`redaction_rules` 被设为 `[]` → 预设区域被忽略。

**修复**:
```python
if redaction_rules is None:
    redaction_rules = config.preset_regions if config else []
if config is None:
    config = RedactionConfig(preset_regions=redaction_rules)
```

---

## 修复 4: 服务测试 mock capture + inference（13 个 BitBlt 失败）

**文件**: `test_service.py`

**根因**: `service.start_service()` 第 69 行调用 `capture.capture_all_displays()` 做真实截图。在非交互环境（CI/SSH/无桌面会话）中，`mss` 调用 `BitBlt` 失败。

**修复**: 在 `test_service.py` 中通过 `monkeypatch` 注入 mock：

```python
# 在重置 fixture 中注入 mock
@pytest.fixture(autouse=True)
def reset_service(monkeypatch):
    """每个测试前后重置服务状态，并 mock 外部依赖。"""
    # Mock screenshot capture 防止 BitBlt 错误
    def mock_capture_all():
        return ["mock_display_1"]

    def mock_capture_primary():
        from PIL import Image
        return Image.new("RGB", (1920, 1080), (0, 0, 0))

    def mock_init_inference(**kwargs):
        return True

    monkeypatch.setattr("vision.capture.capture_all_displays", mock_capture_all)
    monkeypatch.setattr("vision.capture.capture_primary", mock_capture_primary)
    monkeypatch.setattr("vision.inference.init_inference", mock_init_inference)

    # 测试前：确保服务已停止
    try:
        service.stop_service()
    except Exception:
        pass
    memory.clear_all()

    yield

    # 测试后：清理
    try:
        service.stop_service()
    except Exception:
        pass
    memory.clear_all()
```

---

## 修复 5: memory.py `cleanup_expired`、`get_active`、`get_stats` 的一致过期语义

**文件**: `memory.py`

**检查**: `memory.py` 中的所有函数依赖 `obs.is_expired`（来自 contracts.py 的 property）。Fix 1 修复 `is_expired` 后，这些函数自动使用一致的过期语义。**memory.py 本身无需修改**。

---

## 验证

修复后运行：

```powershell
$env:PYTHONPATH = (Resolve-Path Project/Jinli/services).Path
python -m pytest Project/Jinli/services/vision/tests -v --tb=short 2>&1
```

预期: **72/72 pass**（零失败）

然后运行 Node 测试确认不退化：

```powershell
$tests = Get-ChildItem Project/Jinli/tests -Filter *.test.mjs | Select-Object -ExpandProperty FullName
node --test $tests
```

预期: **198/198 pass**（不变）

---

## 任务包更新

修复后更新两个任务包：

1. 撤回过早的 `verify_result: pass`（已经完成 ✅）
2. 更新两个任务的 `verification-report.md`（保留本次失败证据，新增修复记录）
3. `tasks.md` 中未勾选项保持未勾选
4. **不得设置 `verify_result: pass` 或 `review_result: pass`**

---

## 不得做的事情

- ❌ 不得修改或删除测试来获得通过
- ❌ 不得提前设置 verify_result / review_result 为 pass
- ❌ 不得修改 tasks.md 标记未完成项为完成
- ❌ 不得修改 vision_start/stop 做真实截图
