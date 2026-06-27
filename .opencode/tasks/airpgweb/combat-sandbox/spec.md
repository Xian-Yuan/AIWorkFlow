# Spec — combat-sandbox（沙盒战斗测试模式）

## 概述

在开发者模式中新增"沙盒战斗测试模式"。用户可从已发布地图中选一张作为测试场地，按分类生成单位并放置，编辑主角属性与装备，触发**连续回合制战斗**（你一刀我一刀直到一方倒下或手动终止）。

---

## Scenario 1: 进入沙盒模式

**GIVEN** 用户在开发者模式首页  
**WHEN** 用户点击"沙盒战斗测试"按钮  
**THEN** 系统展示沙盒主界面，包含：
  - 左侧：分类面板（NPC / 敌人 / 野兽 / Boss / 精英 / 友方）
  - 中间：地图预览区（Phaser 渲染，初始显示默认空场景）
  - 右侧：操作面板（主角编辑器 / 战斗触发）

---

## Scenario 2: 选择测试地图

**GIVEN** 用户在沙盒主界面  
**WHEN** 用户点击"选择地图"  
**THEN** 弹出地图选择器，列出所有已保存/已发布的地图  
**WHEN** 用户点击某地图  
**THEN** 系统在 Phaser SandboxScene 中渲染该地图（只读模式）
**AND** 地图的 tiles 结构完整显示，但 actor/单位数据不加载

---

## Scenario 3: 按分类生成单位

**GIVEN** 左侧分类面板可见  
**WHEN** 用户展开"敌人"分类  
**THEN** 显示该分类下所有预设单位模板（名称 + 属性摘要）  
**WHEN** 用户点击某单位模板（如"铁锤镇守卫"）  
**THEN** 系统在 Phaser 场景中该单位出现在默认位置（地图中心附近）  
**AND** 右侧面板显示该单位的完整属性

---

## Scenario 4: 放置单位到指定位置

**GIVEN** 地图已渲染，某单位已选中但未放置  
**WHEN** 用户点击地图中某可通行瓦片  
**THEN** 单位移动到该瓦片位置（Phaser sprite 移到该坐标）  
**WHEN** 用户再次点击已放置的单位  
**THEN** 该单位被选中（高亮），可拖拽或删除

---

## Scenario 5: 编辑主角属性模板

**GIVEN** 用户在沙盒主界面  
**WHEN** 用户点击"主角模板"面板  
**THEN** 展示 7 个主属性（strength / agility / perception / vitality / will / luck / charisma）的编辑控件，默认值为 INITIAL_ATTRIBUTES  
**WHEN** 用户修改 vitality 为 10  
**THEN** 衍生属性（hpMax / staminaMax / moveSpeed 等）实时重算（调用 computeDerivedStats）

---

## Scenario 6: 赋予装备

**GIVEN** 主角模板面板打开  
**WHEN** 用户点击"装备武器"  
**THEN** 弹出武器选择器，列出所有可用武器定义（dagger / one_hand_sword / two_hand_axe / spear / hammer / bow）  
**WHEN** 用户选择"铁剑"（one_hand_sword, quality: fine）  
**THEN** 主角装备更新，战斗属性面板同步显示三维伤害（劈/穿/钝）

**GIVEN** 地图上某敌人单位被选中  
**WHEN** 用户点击"赋予防具"  
**THEN** 弹出防具选择器，按槽位分类  
**WHEN** 用户选择"锁子甲"（chain, torso_middle）  
**THEN** 该单位的 armors 数组新增该防具，damageReduction 同步更新

---

## Scenario 7: 开始连续回合战斗

**GIVEN** 地图上有主角 + 至少 1 个敌方单位  
**WHEN** 用户在右侧面板点击"开始战斗"  
**THEN** 系统弹出战斗目标选择（点击敌方单位作为目标）  
**WHEN** 用户选中"铁锤镇守卫"  
**THEN** 战斗开始，回合计数器初始化为 1  
**AND** 系统自动执行玩家回合（调用 `resolveFullAttack`）  
**AND** 右侧战斗日志面板显示第 1 回合玩家攻击的完整 12 步管线结果  

---

## Scenario 8: 回合交替

**GIVEN** 玩家第 1 回合攻击已完成  
**WHEN** 敌人 HP > 0  
**THEN** 系统自动切换为敌人回合  
**AND** 敌人对玩家发起攻击（调用 `resolveFullAttack`，敌人为 attacker，玩家为 defender）  
**AND** 战斗日志显示敌人攻击结果，回合计数器 +1  
**WHEN** 双方均 HP > 0  
**THEN** 下一回合继续交替，直到一方 HP ≤ 0  

---

## Scenario 9: 战斗结束

**GIVEN** 连续回合战斗中  
**WHEN** 敌人 HP ≤ 0  
**THEN** 战斗结束，战斗日志显示 "[单位名] 被击败"  
**AND** "开始战斗"按钮恢复可用（可重新选择目标）  
**WHEN** 主角 HP ≤ 0  
**THEN** 战斗结束，战斗日志显示 "主角倒下"  
**AND** 主角 HP 自动恢复满（沙盒测试便利性），可重新开始  

---

## Scenario 10: 手动终止战斗

**GIVEN** 连续回合战斗进行中  
**WHEN** 用户点击"终止战斗"  
**THEN** 战斗立即停止，双方 HP 恢复初始值  
**AND** 战斗日志保留（不清理），可继续查看  

---

## Scenario 11: 调整数值后再次测试

**GIVEN** 刚完成一轮战斗（结束或终止）  
**WHEN** 用户修改主角 strength 从 5 改为 15  
**AND** 用户将敌人防具从锁子甲改为半身甲  
**WHEN** 用户再次点击"开始战斗"→ 选择同一目标  
**THEN** 新战斗基于新数值重新计算，日志显示不同伤害

---

## Scenario 12: 清除与重置

**GIVEN** 沙盒中有多个已放置单位  
**WHEN** 用户点击"清除全部"  
**THEN** 沙盒中所有单位移除，地图恢复初始状态  
**WHEN** 用户点击"重置主角"  
**THEN** 主角属性恢复为 INITIAL_ATTRIBUTES，装备清空

---

## Scenario 13: 沙盒数据隔离

**GIVEN** 用户在沙盒中进行了任意操作  
**WHEN** 用户点击"返回"离开沙盒  
**THEN** 沙盒完全不写入 `save-repository.ts`，不触发任何存档操作  
**AND** 主线存档数据不受任何影响
