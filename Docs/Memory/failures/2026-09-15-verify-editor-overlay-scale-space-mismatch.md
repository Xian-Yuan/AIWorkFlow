---
id: memory-verify-editor-overlay-scale-space-mismatch-2026-09-15
type: failure_memory
phase: verify
project_type: other
module: scene-builder
tags:
  - phase:verify
  - mod:implementer
  - dom:ui
  - pat:boundary
  - pat:regression
severity: medium
write_trigger: verify_fail
retrieval_scope:
  - router
  - implement
token_budget: small
mem0_sync_status: not_synced
mem0_memory_id: null
memory_version: v1
---

# Runtime 预览与编辑器 Overlay 使用不同缩放空间导致选择几何错位

## Symptom
PixelLighting2D P1-C Scene Builder 在引入 Runtime-backed preview 后，非默认 project scale override 下，Placement 的 Runtime 画面与编辑器 overlay/选择几何没有完全对齐。分支随后先补充 `test: align placement overlay with project scale override`，再以 `fix: align placement overlays with project scale` 修复，说明问题来自真实验证而非假设风险。

## Root Cause
Runtime 实例和编辑器 overlay/hit-test 走了两套独立的坐标/缩放计算链。Overlay 使用了 placement 局部变换，却没有完整复用 Runtime 侧的 effective project scale，导致同一个对象在“实际渲染空间”和“编辑交互空间”拥有不同的几何解释。

## Bad Pattern
- Runtime、selection outline、hit rect、gizmo 各自重算 world→screen 变换
- 只在 scale=1.0 的默认场景验证编辑器叠层
- 视觉预览正确后默认认为选择框/命中测试也必然正确
- 修 Runtime 变换时没有同步检查 authoring overlay 的等价变换

## Correct Rule
所有 Scene Authoring overlay、selection、hit-test 和 gizmo 必须消费与 Runtime preview 相同的 effective transform 语义；project-level scale、placement scale、pivot、pan/zoom 等公共变换应集中定义或由单一 adapter/helper 提供，禁止在 UI 层重复推导第二套公式。

## Retrieval Hint
适用于实现 2D/3D 编辑器、SubViewport/runtime preview、gizmo、selection outline、hit testing、缩放覆盖和多层坐标空间转换时的回归预防。

## Verification
至少增加一个非 1.0 project scale override 场景，并验证：
1. Runtime sprite/placement 可见边界与 selection outline 重合；
2. hit-test 命中区域与视觉位置一致；
3. gizmo 中心与 Runtime 对象中心一致；
4. pan/zoom 后仍保持上述一致性。
默认 scale=1.0 的测试不能作为唯一证据。
