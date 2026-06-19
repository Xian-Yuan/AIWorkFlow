# 约束别名映射表

> 当用户输入的值与约束文件名不完全匹配时，通过本表找到正确的约束文件。
> 格式：`用户可能的输入 → 约束文件名（不含.md）`

## 渲染风格
- 像素 / 像素风 / pixel art / 点阵 / 8bit → pixel
- 厚涂 / 写实 / realistic / 油画 / oil paint → thick_paint
- 赛璐璐 / cel / cel shading / 动画 / anime style / 二次元 → cel_shading
- 水彩 / watercolor → watercolor（待创建）
- 韩式 / 半厚涂 / manhwa style → semi_thick_paint（待创建）
- 美式卡通 / cartoon / western cartoon → western_cartoon（待创建）
- 剪影 / silhouette / 平面 → silhouette（待创建）

## 体型
- 3头身 / chibi / 萌系 / SD → realistic_3head
- 5头身 / 标准 / normal proportion → realistic_5head
- 7头身 / 模特 / fashion / model → realistic_7head
- 8头身 / 英雄 / heroic → realistic_8head
- 风格化 / stylized → stylized（需追问方向）
- 上半身夸张 / 宽肩窄腰 / 倒三角 → stylized_upper
- 下半身夸张 / 大长腿 / 长腿 → stylized_lower
- 曲线夸张 / 沙漏 / 美式 / hourglass → stylized_curve

## 职业（待创建完约束后补充）
- 战士 / warrior / fighter → warrior
- 法师 / mage / wizard / sorcerer → mage
- 刺客 / assassin / rogue / 潜行 / 盗贼 → assassin
- 射手 / archer / ranger / 弓箭手 → archer
- 坦克 / 重装 / tank / guardian → tank
- 牧师 / priest / healer / 治疗 → priest

## 种族（待创建完约束后补充）
- 人类 / human → human
- 半精灵 / half-elf → half_elf
- 精灵 / elf → elf
- 矮人 / dwarf → dwarf
- 兽人 / orc / ork → orc

## 设计流派（待创建完约束后补充）
- 新艺术 / art nouveau → art_nouveau
- 装饰艺术 / art deco → art_deco
- 赛博朋克 / cyberpunk → cyberpunk
- 蒸汽朋克 / steampunk → steampunk
- 哥特 / gothic → gothic
- 极简 / minimalism → minimalism
- 巴洛克 / baroque → baroque

## 战斗风格（待创建完约束后补充）
- 近战 / melee → melee
- 远程 / ranged → ranged
- 法术 / magic → magic_combat
- 潜行 / stealth → stealth

## 武器（待创建完约束后补充）
- 单手剑 / sword → sword
- 匕首 / dagger → dagger
- 法杖 / staff → staff
- 弓 / bow → bow

## 配色（待创建完约束后补充）
- 暖色系 / warm → warm_color
- 冷色系 / cool → cool_color
- 暗色系 / dark → dark_color
- 高对比 / high_contrast → high_contrast

> AI 在对话中遇到不在本表的新输入时，联网搜索后同时更新本表。

---

## 模糊输入 → 维度猜测

> 当用户使用模糊形容词时，AI 拆解为具体设计维度组合，列出 2-3 个示例方案供用户选择。
> 不直接问"你是什么意思"，而是提供可选的具象方案。

| 模糊词 | 可能涉及维度 | 示例方案 |
|--------|------------|---------|
| 暗黑系 / 黑暗 | 配色(dark_color) + 力量(shadow) + 性格(cold/mysterious) + 流派(gothic) | 暗色刺客 / 哥特暗影法师 / 暗黑重装战士 |
| 仙气 / 飘逸 | 服装(robe) + 元素(wind) + 性格(elegant) + 发型(long_straight) | 风系飘逸法师 / 仙侠剑客(长袍+单手剑+风纹) |
| 帅气 / 酷 / 拉风 | 体型(7/8head) + 性格(cold/wild) + 武器(sword) + 服装(tactical/asymmetric_cape) | 冷峻剑士 / 战术刺客 / 风衣枪手 |
| 可爱 / 萌 | 体型(3/5head) + 配色(warm) + 性格(passionate) + 头发(short/twin) | 萌系火法 / 治愈牧师(暖色+圆润) |
| 硬核 / 硬派 | 体型(8head) + 服装(heavy_armor) + 战斗(melee) + 武器(axe/shield) | 重装战士 / 盾斧守卫 |
| 华丽 / 花哨 | 流派(baroque/art_nouveau) + 配色(warm) + 武器(装饰性) + 服装(多层) | 巴洛克贵族 / 新艺术金边法师 |
| 简洁 / 干净 | 流派(minimalism) + 配色(≤3色) + 服装(线条利落) + 渲染(cel_shading) | 极简剑士 / 扁平风射手 |
| 诡异 / 怪诞 | 流派(gothic) + 元素(nature扭曲) + 力量(shadow) + 配色(dark+点缀亮色) | 哥特异形 / 暗影藤蔓术士 |
| 科技感 | 流派(cyberpunk) + 力量(technology) + 服装(tactical) + 配色(金属色) | 赛博战士 / 科技特工 |

### 模糊输入处理流程

```
用户说"我想要{模糊词}的角色"
  │
  ▼
查本表 → 找到 → 拆解为涉及维度
  │              │
  │              ├─ 如果已有已选特征 → 排除冲突方案，推荐最优1-2个
  │              └─ 如果尚未选择任何特征 → 列出2-3个方案，让用户选方向
  │
  未找到 → AI 自己拆解（哪些设计维度可能相关）→ 联网搜索参考 → 追加入本表
```
