# 场景 -> SALCSQ 默认参数路由表

> 版本: v1.0 | 日期: 2026-06-29
> 状态: 可用
> 用途: 输入场景类型，输出SALCSQ六模块默认参数，省去每次手动选择
> 融合: ai-shortdrama-workflow-template.md + medieval-fantasy-pattern-library.md + ai-video-tool-prompting.md
> 关联: ai-shortdrama-emotion-route-table.md(情绪路由) / ai-shortdrama-salcsq-template.md(模板)

---

## 0. 使用方法

1. 确定你要拍的**场景类型**(从下面20种中选)
2. 查表得到SALCSQ六模块的默认参数和推荐工具
3. 根据具体剧情微调(替换角色/动作/光线细节)
4. 用SALCSQ模板组装提示词

---

## 1. 战斗与冲突(5种)

| 场景 | S(默认主体) | A(默认动作) | L(默认光影) | C(默认镜头) | 推荐工具 | Seedance模式 | 默认情绪 |
|------|-----------|-----------|-----------|-----------|---------|-------------|---------|
| 骑士冲锋 | 黑甲骑士+战马 | breathing: deep, eye: locked, jaw: clenched, control: suppressing | Jackson+Kaminski, torch+rain, teal-orange desat, 500T | 35mm f/4低角度+慢推->CU, cavalry charge | Kling | Action | 悲壮/崇高 |
| 围城战 | 守城士兵+城墙 | breathing: ragged, eye: darting, scan: frantic, control: failing | Eggers+Blaschke, torch+lightning, desat grey-blue+sole fire, HP5 | 21mm f/8 deep focus+locked+城墙分界 | Kling | Action | 恐惧/渺小 |
| 近身格斗 | 双人格斗者 | breathing: rapid, eye: locked, jaw: grinding, control: masked | Evans+Mendoza, fluorescent flicker, dungeon orange+black, 800T | 28mm f/2.8 handheld+corridor纵深+快速剪辑 | Kling | Action | 愤怒/绝望 |
| 龙焰降临 | 单人面对巨龙 | breathing: holding, eye: wide, delay: frozen, residue: afterglow | Villeneuve+Fraser, overcast->red sky, icefield blue->warfire red, 250D->500T | 14mm f/8 EWS->85mm f/1.4 ECU, locked->tilt up | Kling(钩子)+Seedance(高潮) | Performance | 敬畏/恐惧 |
| 战场沉默 | 单人幸存者 | breathing: deep slow, eye: distant/staring-through, delay: slow, residue: echo | Malick+Deakins, flat overcast, wasteland grey+250D | 50mm f/4 static+hold 5s+wind, 9:16 | Seedance | Atmospheric | 悲伤/虚无 |

---

## 2. 权力与阴谋(5种)

| 场景 | S(默认主体) | A(默认动作) | L(默认光影) | C(默认镜头) | 推荐工具 | Seedance模式 | 默认情绪 |
|------|-----------|-----------|-----------|-----------|---------|-------------|---------|
| 王座加冕 | 新王+主教+人群 | breathing: controlled, eye: locked forward, jaw: set, control: suppressing | Nolan+van Hoytema, divine backlight+crown catchlight, cathedral gold+500T | 24mm f/8 IMAX wide+centered low angle, 9:16 vertical majesty | Seedance | Performance | 权力/庄严 |
| 暗杀密谋 | 两个密谋者+蜡烛 | breathing: whisper/shallow, eye: avoidant+darting, jaw: clenched, scan: sweeping | Fincher+Khondji, sodium orange+no fill, dungeon orange+500T | 50mm f/2.8 selective focus+locked+half-face light, 9:16 narrow | Kling | Narrative | 阴谋/不安 |
| 审判宣判 | 法官(高)+被告(低) | breathing: deep(法官)/ragged(被告), eye: locked down(法官)/staring-through(被告), jaw: clenched | Kubrick+Alcott, cold overhead+sole warm on accused, iron and blood+500T | 35mm f/4 symmetric+locked+two-point perspective, 9:16 corridor | Seedance | Studio | 压迫/宿命 |
| 宫廷宴会 | 贵族+假面 | breathing: controlled, eye: darting, jaw: masked smile, control: performing | Kubrick+Zhao, warm surface+cold undertow, tavern warmth+cursed green shadows, 500T | 28mm f/2.8 Steadicam drift+slow orbit, 9:16 | Kling | Narrative | 虚伪/欲望 |
| 权力交接 | 老王+新王 | breathing: deep+slow(老)/rapid(新), eye: distant(老)/locked(新), delay: slow | Lean+Deakins, light dimming+gold->grey, cathedral gold->wasteland grey, 500T->250D | 35mm f/5.6 slow push+light dims, 9:16 | Seedance | Narrative | 命运/沉重 |

---

## 3. 旅途与探索(5种)

| 场景 | S(默认主体) | A(默认动作) | L(默认光影) | C(默认镜头) | 推荐工具 | Seedance模式 | 默认情绪 |
|------|-----------|-----------|-----------|-----------|---------|-------------|---------|
| 踏上旅途 | 骑士+马+远方 | breathing: deep, eye: distant, jaw: set, residue: afterglow | Jackson+Lubezki, golden hour+natural, elvish silver+250D | 24mm f/8 deep focus+figure on horizon, 9:16 vast vertical | Seedance | Atmospheric | 自由/未知 |
| 进入地下城 | 探险者+入口 | breathing: shallow, eye: darting into dark, jaw: clenched, control: suppressing | Eggers, single candle+darkness ahead, dungeon orange+HP5 | 21mm f/4 slow push into black, 9:16 corridor depth | Kling | Action | 恐惧/不安 |
| 森林迷路 | 旅人+雾 | breathing: shallow, eye: scanning, delay: slow, control: failing | del Toro, fog+volumetric, cursed green+500T | 35mm f/2.8 handheld drift+no clear path, 9:16 fog depth | Seedance | Atmospheric | 神秘/迷失 |
| 攀登高峰 | 攀登者+山 | breathing: ragged, eye: fixed upward, jaw: clenched, residue: wetness | Tarkovsky, overcast+wind, icefield blue+250D | 28mm f/8 long take+slow ascent, 9:16 mountain vertical | Seedance | Atmospheric | 意志/崇高 |
| 废墟发现 | 探险者+废墟 | breathing: holding, eye: wide+glistening, delay: 2-beat, residue: afterglow | Villeneuve+Deakins, fog+Rembrandt, ancient parchment+500T | 35mm f/5.6 slow reveal+emerge from fog, 9:16 vertical ruins | Seedance | Atmospheric | 敬畏/哀伤 |

---

## 4. 超自然与魔法(5种)

| 场景 | S(默认主体) | A(默认动作) | L(默认光影) | C(默认镜头) | 推荐工具 | Seedance模式 | 默认情绪 |
|------|-----------|-----------|-----------|-----------|---------|-------------|---------|
| 魔法觉醒 | 法师+发光手 | breathing: shallow, eye: glistening/color shift, delay: 2-beat, control: failing | del Toro+Navarro, volumetric gold+ethereal, twilight purple+500T | 50mm f/2.0 360 orbit+particles rise, 9:16 magic vertical | Seedance | Performance | 敬畏/神秘 |
| 诅咒显现 | 受诅者+皮肤变化 | breathing: ragged, eye: avoidant, jaw: grinding, control: failing, residue: scar | Eggers+Blaschke, candle-only+darkening, cursed green+HP5 | 50mm f/2.8 handheld+skin close, 9:16 body vertical | Kling | Narrative | 恐惧/腐败 |
| 诅咒发作 | 受诅者+变形 | breathing: ragged/holding, eye: wide/fixed, delay: frozen, control: failing | del Toro+Navarro, impossible light+morph, cursed green+warfire red, 800T | 28mm f/2.8 handheld+distortion, 9:16 | Kling | Action | 恐慌/失控 |
| 精灵魔法 | 精灵+水+光 | breathing: slow/ritual, eye: closed/serene, control: surrender, residue: afterglow | Malick+Miyazaki, natural golden+green+gold, watercolor, 250D | 35mm f/2.8 slow drift+natural light, 9:16 | Seedance | Atmospheric | 敬畏/美丽 |
| 魔法仪式 | 围圈+蜡烛+法师 | breathing: ritual/slow, eye: fixed on flame, jaw: set, control: surrender | Eggers+Refn, symmetric+locked+candles, twilight purple+cathedral gold, 500T | 50mm f/2.8 locked symmetric+geometric, 9:16 ritual vertical | Seedance | Performance | 庄严/不安 |

---

## 5. 场景+工具最优搭配速查

| 场景 | 首选工具 | 备选工具 | 原因 |
|------|---------|---------|------|
| 骑士冲锋 | Kling | Seedance(慢动作帧) | Kling擅长铠甲+雨+动态 |
| 围城战 | Kling | Wan(广角大场景) | Kling擅长雨+火把+城墙 |
| 近身格斗 | Kling | - | Kling擅长手持+快速剪辑 |
| 龙焰降临 | Kling(钩子帧)+Seedance(高潮帧) | Wan(大场景) | 分段生成最优 |
| 战场沉默 | Seedance | - | Seedance擅长微妙情绪+长持 |
| 王座加冕 | Seedance | Kling | Seedance擅长写实质感+光 |
| 暗杀密谋 | Kling | Seedance | Kling擅长暗场景+风格 |
| 审判宣判 | Seedance | - | Seedance擅长锁定+高对比 |
| 宫廷宴会 | Kling | Seedance | Kling擅长多人+运动 |
| 魔法觉醒 | Seedance | - | Seedance擅长环绕+魔法光 |
| 诅咒发作 | Kling | - | Kling擅长变形+高速 |
| 森林漫步 | Seedance | - | Seedance擅长漂浮+氛围 |
| 对话密谋 | Kling(快速)+Seedance(精修) | - | 混合策略 |
| 地牢审讯 | Seedance | Kling | Seedance擅长烛光+锁定 |
| 废墟探索 | Seedance | - | Seedance擅长漂浮+环境 |

---

> v1.0 初版: 20场景路由+工具搭配+Seedance模式速查
