# Negative Prompt 生成规则表

> 确定性映射规则：FORBID 项 → English Negative Prompt。
> **不依赖 AI 即兴翻译**。每条 FORBID 对应固定英文标签。

---

## 使用方式

1. 生成提示词时，扫描已加载约束文件的 FORBID 段
2. 查本表 → 提取对应英文标签
3. 去重合并（多个文件重复的只保留一次）
4. 按类别排序输出

---

## 通用规则（_public.md + 跨域通用）

| 中文 FORBID | English Negative |
|------------|------------------|
| 禁止元素均分 | symmetrical composition, equal proportion |
| 过度装饰 | cluttered, overdesigned, messy details |
| 装饰阻碍动作 | impractical armor, restricted movement |

---

## 体型 (body/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| realistic_3head | 禁止长腿细腰 | long legs, narrow waist, realistic proportions |
| realistic_3head | 禁止写实肌肉 | defined muscles, realistic anatomy |
| realistic_3head | 禁止复杂服装层次 | layered clothing, complex outfit |
| realistic_5head | 禁止极端头身比(<4 或 >6) | chibi, deformed proportions, 8 head body |
| realistic_5head | 禁止夸张肌肉或曲线 | extremely muscular, exaggerated curves |
| realistic_7head | 禁止粗短四肢 | short limbs, stubby arms |
| realistic_7head | 禁止头身比 < 6 | chibi, child proportions, short body |
| realistic_8head | 禁止缩头缩脑站姿 | hunched posture, small head |
| realistic_8head | 禁止头身比 < 7 | short body, normal proportions |
| stylized | 禁止半夸张（保守） | realistic anatomy, normal proportion |
| stylized | 禁止写实解剖+风格化混用 | mixed proportions, inconsistent style |
| stylized_upper | 禁止收腰设计 | narrow waist, fitted silhouette |
| stylized_upper | 禁止下半身复杂装饰 | detailed lower body, decorated legs |
| stylized_lower | 禁止上半身复杂装饰 | detailed upper body, decorated torso |
| stylized_lower | 禁止粗腿或短腿 | thick legs, short legs |
| stylized_curve | 禁止宽松直筒服装 | loose clothing, straight silhouette |
| stylized_curve | 禁止弱化腰线 | undefined waist, boxy figure |

---

## 职业 (profession/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| archer | 禁止全身重甲 | full plate armor, heavy armor |
| assassin | 禁止重甲 | plate armor, metal armor, heavy armor, chainmail, bulky armor |
| assassin | 禁止亮色系主色（红/金/白） | bright colors, red, gold, white, vibrant palette |
| assassin | 禁止大型武器 | oversized weapon, greatsword, large weapon |
| mage | 禁止重甲(>10%金属) | plate armor, heavy armor, metal armor |
| mage | 禁止大型物理武器 | greatsword, greataxe, polearm, heavy weapon |
| warrior | 禁止轻飘飘布料 | flowing fabric, silk, light cloth, robe |
| warrior | 禁止裸露大面积皮肤(>30%) | exposed skin, bare chest, revealing clothing |

---

## 种族 (race/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| dwarf | 禁止纤细体型 | slim, slender, thin build, frail |
| dwarf | 禁止7头身以上 | tall, long legs, 7 head, 8 head |
| elf | 禁止粗壮肌肉 | muscular, bulky, thick build, stocky |
| elf | 禁止短耳 | short ears, human ears, round ears |
| half_elf | 禁止长尖耳 | long pointed ears |
| half_elf | 禁止矮壮体型 | dwarf build, stocky, short and thick |
| human | 禁止非人类特征 | elf ears, animal ears, horns, tail, non-human |

---

## 战斗风格 (combat_style/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| magic_combat | 禁止双手空闲无施法感 | empty hands, idle pose, no magic effects |
| magic_combat | 禁止大块金属护甲 | full metal armor, heavy plating |
| melee | 禁止后仰休闲站姿 | relaxed posture, leaning back, casual stance |
| melee | 禁止武器未进入战斗状态 | weapon sheathed, weapon on back, idle weapon |
| ranged | 禁止正面朝向 | facing forward, frontal pose |
| ranged | 禁止武器下垂 | weapon lowered, bow lowered |
| stealth | 禁止飘动物件 | flowing cape, long dress, ribbons, fluttering fabric |
| stealth | 禁止亮色反光材质 | shiny, reflective, glossy, metallic sheen |

---

## 武器 (weapon/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| axe | 禁止纤细斧刃 | thin blade, narrow edge, slim axe |
| axe | 禁止无重量感 | lightweight, floating, weightless |
| bow | 禁止无弓弦 | no bowstring, stringless bow |
| bow | 禁止弓臂直线 | straight bow, crossbow |
| dagger | 禁止刃长超过前臂 | long blade, sword-length, extended blade |
| dagger | 禁止双手握持大型匕首 | two-handed, oversized dagger |
| shield | 禁止盾太小 | small shield, buckler |
| shield | 禁止盾在背后 | shield on back, stored shield |
| staff | 禁止无聚焦物光杆 | plain stick, featureless staff, wooden pole |
| staff | 禁止过短(<身高80%) | short staff, wand, baton |
| sword | 禁止弯曲剑身 | curved blade, scimitar, katana |
| sword | 禁止无护手 | no crossguard, guardless |

---

## 配色 (color/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| cool_color | 禁止主色为暖色 | warm colors, reds, oranges, yellows |
| dark_color | 禁止大面积亮色 | bright, light palette, pastel |
| dark_color | 禁止暗色中缺乏点缀亮点 | muddy, flat dark, no contrast, indistinguishable |
| warm_color | 禁止主色为冷色 | cool colors, blues, cyans, cold tones |

---

## 设计流派 (design_movement/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| art_nouveau | 禁止尖锐直角 | sharp angles, geometric, rectangular |
| art_nouveau | 禁止完全对称 | perfect symmetry, mirrored composition |
| art_nouveau | 禁止机械/齿轮 | gears, mechanical, industrial |
| cyberpunk | 禁止全天然材质 | organic materials, cotton, leather, natural fibers |
| cyberpunk | 禁止中世纪古典 | medieval, renaissance, classical, ancient |
| gothic | 禁止明亮活泼色系 | bright colors, cheerful palette, vibrant |
| gothic | 禁止现代科技元素 | modern technology, sci-fi, futuristic |
| minimalism | 禁止多层装饰 | frills, lace, ornate, decorative patterns |
| minimalism | 禁止复杂图案 | complex pattern, intricate design, detailed ornament |
| minimalism | 禁止华丽材质反光 | shiny, glossy, reflective, luxurious materials |
| steampunk | 禁止光滑高科技材质 | sleek, smooth plastic, futuristic, glossy tech |
| steampunk | 禁止纯魔法能量 | pure magic, arcane energy, mystical glow |

---

## 力量来源 (power_source/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| fire | 禁止冷色火焰主体 | blue fire, cold fire, ice fire, frozen flame |
| fire | 禁止火焰静止感 | static fire, still flame, frozen fire |
| holy | 禁止暗色能量核心 | dark energy, black core, shadow energy |
| holy | 禁止血色/腐化元素 | blood, corruption, decay, dark magic |
| ice | 禁止圆润形状 | round, smooth curves, soft shapes, organic |
| ice | 禁止暖色能量 | warm glow, fire energy, orange, red |
| shadow | 禁止发光效果 | glowing, bright light, luminous, radiant |
| shadow | 禁止暖色能量 | fire glow, warm light, orange, yellow flame |
| technology | 禁止魔法符文 | magic runes, arcane symbols, mystical glyphs |
| technology | 禁止纯生物变异 | organic mutation, biological, flesh, alien flesh |

---

## 性格 (personality/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| cold | 禁止大笑容或开放身体语言 | big smile, laughing, open arms, welcoming pose |
| cold | 禁止过度装饰 | overly decorated, ornate, frilly |
| elegant | 禁止粗壮短促线条 | thick, stubby, bulky, coarse features |
| elegant | 禁止邋遢随意街头感 | messy, sloppy, unkempt, streetwear, casual |
| mysterious | 禁止全脸暴露+直视 | full face visible, direct eye contact, open expression |
| mysterious | 禁止过度暴露服装 | revealing, exposed skin, skimpy outfit |
| passionate | 禁止封闭/防御性站姿 | closed posture, arms crossed, defensive stance |
| passionate | 禁止冷漠面部表情 | cold face, emotionless, blank stare, indifferent |
| wild | 禁止精致整洁 | neat, tidy, polished, refined, elegant |
| wild | 禁止对称和谐 | symmetrical, balanced, harmonious |

---

## 发型 (hair/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| braided | 禁止松散无结构 | loose hair, messy hair, unstructured |
| bun | 禁止发包松散 | messy bun, loose updo, strands falling |
| bun | 禁止发包有长发垂下 | half-up hairstyle, long strands hanging |
| long_straight | 禁止卷曲波浪 | curly, wavy, permed |
| long_straight | 禁止蓬松炸开 | afro, puffy, voluminous, teased |
| ponytail | 禁止松散披散 | loose hair, down hair, flowing freely |
| short | 禁止长度过肩 | shoulder-length, long hair |
| short | 禁止遮挡面部轮廓线 | hair covering face, bangs over eyes |

---

## 元素 (element/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| fire_elem | 禁止蓝色火焰主体 | blue fire, cold fire, ice flame |
| ice_elem | 禁止圆润水滴形 | water droplet, round ice, organic curves |
| ice_elem | 禁止暖色渐变 | warm gradient, red-adjacent, sunset colors |
| lightning | 禁止曲线表达 | curved lines, wavy, flowing lines |
| nature | 禁止几何对称排列 | geometric pattern, symmetrical layout, artificial |
| nature | 禁止塑料/金属质感 | plastic, metallic, synthetic, artificial material |
| wind | 禁止静止感 | still, motionless, static air, no movement |
| wind | 禁止厚重实体表达 | solid, heavy, opaque, dense |

---

## 服装 (costume/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| asymmetric_cape | 禁止对称双肩披风 | symmetrical cape, royal cape, even cloak |
| asymmetric_cape | 禁止无固定点悬浮披风 | floating cape, unattached cloak, physics-defying |
| heavy_armor | 禁止轻飘飘布料 | flowing fabric, silk, soft cloth, light material |
| heavy_armor | 禁止暴露关节 | exposed joints, unarmored joints, gaps at joints |
| light_armor | 禁止全身板甲 | full plate armor, heavy armor, full metal |
| light_armor | 禁止无护甲(布衣) | no armor, unarmored, civilian clothes |
| robe | 禁止紧身设计 | tight, form-fitting, bodysuit, skinny fit |
| robe | 禁止金属护甲大块覆盖 | large metal plates, heavy armor coverage |
| tactical | 禁止纯装饰 | purely decorative, non-functional, ornamental |
| tactical | 禁止飘逸长袍 | flowing robe, long dress, draping fabric |

---

## 画质 (quality/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| 4k | 禁止模糊边缘 | blurry, soft edges, unfocused |
| 4k | 禁止大面积纯色块 | large flat colors, void areas, empty space |
| 4k | 禁止省略细节 | low detail, simplified, missing details |
| hd | 禁止大面积噪点 | noise, grain, artifacts, pixelation |
| hd | 禁止轮廓模糊 | blurry outline, soft focus, undefined edges |
| standard | 禁止过度简化到失去辨识度 | oversimplified, unrecognizable, abstract |

---

## 渲染风格 (rendering/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| pixel | 禁止半透明/模糊边缘 | transparency, blur, soft edges, anti-aliasing |
| pixel | 禁止细线装饰 | thin lines, fine detail, hair-thin strokes |
| pixel | 禁止多层叠加材质 | texture layers, compositing, overlapping materials |
| cel_shading | 禁止厚涂式柔光过渡 | soft shading, smooth gradient, realistic lighting |
| cel_shading | 禁止写实材质纹理 | realistic texture, photo-real, detailed surface |
| thick_paint | 禁止平面化处理 | flat colors, cel shading, vector art, cartoon shading |
| thick_paint | 禁止纯色块无过渡 | solid color, no shading, flat rendering, anime style |

---

## 展示模版 (template/)

| 文件 | 中文 FORBID | English Negative |
|------|-----------|------------------|
| character_display | 禁止裁切角色身体 | cropped body, cut off, partial figure |
| character_display | 禁止复杂背景 | complex background, busy scene, detailed backdrop |
| character_display | 禁止三视图/武器拆分 | turnaround, multiple views, weapon breakdown |
| detail_closeup | 禁止特写模糊 | blurry, out of focus, low resolution, pixelated |
| detail_closeup | 禁止不标注 | not labeled, unidentified, unmarked |
| full_design_sheet | 禁止模块重叠 | overlapping modules, cramped, congested layout |
| full_design_sheet | 禁止省去三视图 | no turnaround, single view only, missing views |
| full_design_sheet | 单模块 < 8% | tiny elements, too small details, thumbnail size |
| three_view | 禁止比例不一致 | inconsistent proportions, different sizes per view |
| three_view | 禁止细节不同 | inconsistent details, mismatched features |
| weapon_display | 禁止角色大过武器 | character larger than weapon, character dominant |
| weapon_display | 禁止武器模糊 | blurry weapon, out of focus, low detail weapon |

---

## 输出格式

```
🚫 Negative Prompt (英文, 逗号分隔)
{按类别排序的去重英文标签}
```

### 排序优先级

1. 渲染风格/画质 (rendering/quality) — 全局效果, 放最前
2. 配色 (color) — 全局色调
3. 服装 (costume) + 流派 (design_movement) — 中景
4. 体型 (body) + 种族 (race) — 人体
5. 职业 (profession) + 武器 (weapon) + 战斗风格 (combat_style) — 战斗相关
6. 性格 (personality) + 发型 (hair)
7. 元素 (element) + 力量来源 (power_source)
8. 模版 (template) — 构图相关
