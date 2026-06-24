---
domain: ue
domain_path: ue/gas-lyra
kg_node_id: node.doc-ai-ai-18-validation-checklist-5a16
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.18-validation-checklist.5a16

---

﻿# Validation Checklist (鏍￠獙娓呭崟)

鐢ㄩ€旓細涓烘枃妗ｄ笌鏁版嵁琛ㄥ悓姝ユ彁渚涗竴鑷存€ф牎楠岄」锛岀‘淇?UE5.7 鍗曟満椤圭洰瑙勮寖涓庢€ц兘绾︽潫婊¤冻銆?
閫氱敤锛圙eneral锛夛細
- [ ] 鏈缁熶竴锛氭棤 Magic Resist/Magic Penetration锛涗娇鐢?ResistPoints/ResistNormalized 涓庡崟鍏冪礌鍛藉悕銆?- [ ] 閫熷害绫诲瀷锛氱墿鐞嗘鍣ㄤ粎 AttackSpeed锛涜秴鍑℃鍣ㄤ粎 CastSpeed锛涙墜閮?楗板搧鍏佽瀵瑰簲閫熷害璇嶇紑銆?- [ ] 鍗曟満闄愬埗锛氭湭浣跨敤缃戠粶澶嶅埗/RPC锛涘叏閮ㄦ暟鎹┍鍔ㄤ负鏈湴瀛樺偍銆?- [ ] Blueprint 鍙嬪ソ锛氭墍鏈夊叕寮€灞炴€?鍑芥暟璁炬湁涓嫳鏂囨敞閲婂苟鏀寔钃濆浘璇诲彇銆?
鏁板€间笌鍏紡锛圢umbers & Formulas锛夛細
- [ ] Armor DR锛欴R_phys = min(0.95, 1 - exp(-Armor/C_phys))锛汣_phys鈮?80銆?- [ ] Resist 褰掍竴鍖栵細ResistNormalized = ResistPoints / (ResistPoints + K_element)锛孠_element鈮?00锛涙笚閫忓湪 Points 绔敓鏁堛€?- [ ] Level 1 榛樿鍊硷細2.x 绔犺妭瀹屾暣涓旀棤鍐茬獊锛圡axHealth/AttackSpeed/CastSpeed/Crit/LifeSteal 绛夛級銆?- [ ] 涓烩啋娆℃槧灏勶細2.1 鍏紡榻愬叏锛堝惈 Perception鈫扖astRangeRadius +5%/鐐癸級銆?
瑁呭锛圗quipment锛夛細
- [ ] 瑁呭鍒嗙被锛?.1 姝﹀櫒/闃插叿/楗板搧鍒嗙被涓庡熀纭€闈㈡澘锛圔aseAttackSpeed/BaseCastSpeed锛孊aseResistPoints锛変竴鑷淬€?- [ ] 璇嶆潯鍛藉悕锛?.4 涓姉鎬ц瘝鏉′娇鐢?ResistPoints锛堝崟鍏冪礌锛夛紱娓楅€忎负 Penetration(Armor/Elemental)銆?- [ ] 閮ㄤ綅鐧藉悕鍗曪細3.5 鍩虹闈㈡澘鍋忓悜璇存槑瀛樺湪锛涙帀钀戒慨姝ｄ粎楗板搧鍙嚭鐜般€?
闅愯棌灞炴€э紙Hidden Stats锛夛細
- [ ] 2.6 鍒楀嚭 Projectile/Beam/Explosion 榛樿鍙傛暟锛堝崐寰?瀹藉害/琛板噺绛夛級銆?- [ ] 姝﹀櫒鏍囩涓庢寔鎻¤鍒欙細3.1 鎻愪緵 Category/DamageNature/Delivery 涓?OffHand/TWO-Handed 瑙勫垯銆?
缂栬瘧涓庢€ц兘锛圔uild & Performance锛夛細
- [ ] 涓嶅紩鍏ュ惊鐜緷璧栵紱澶存枃浠跺寘鍚鍚?UE5.7 瑙勮寖锛涘墠鍚戝０鏄庡悎鐞嗐€?- [ ] 鏁版嵁琛ㄥ瓧娈电鍚?CSV 妯℃澘锛涜川閲忓€嶇巼 DataTable 瀛樺湪銆?- [ ] 鎸囨暟鍑忎激涓庡綊涓€鍖栬绠椾綆寮€閿€锛堟棤鏄傝吹鍔ㄦ€佸垎閰嶏級銆
